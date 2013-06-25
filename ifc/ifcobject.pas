[inherit('lib$:typedef',
	 'lib$:rtldef',
	 'lib$:ifc$def',
	 'lib$:ifc$lex_def')]

module ifc$object(output);

(* Edit History                                                             *)
(* 13-Sep-2009  TES  Converted to generate MACRO-32, not VAX objects.       *)
(*                                                                          *)

const	object_attributes = [detail_keyword, name_keyword, mass_keyword,
			     volume_keyword, capacity_keyword, size_keyword,
			     area_keyword, initial_keyword, static_keyword,
			     strength_keyword, readable_keyword,
			     openable_keyword, lockable_keyword,
			     startable_keyword, cognizant_keyword,
			     machine_keyword, flexible_keyword, room_keyword];
	object_table_size = 150;
	symbol_hash_size = 101;
	tab = chr(9);

type	$object_symbol_ptr = ^$object_symbol;
	$object_symbol = record
			symbol : varying[31] of char;
			number : $ubyte;
			next : $object_symbol_ptr;
		     end;

	$symbol_hash_table = packed array[0..symbol_hash_size-1]
						of $object_symbol_ptr;

	$object_record = record
				symbol : varying[31] of char;
				detail : varying[31] of char;
				initial : varying[31] of char;
				name : varying[31] of char;
				defined : boolean;
				flags : unsigned;
				count : integer;
				info : packed array[1..16] of $ubyte;
			end;

	$object_table = array[1..object_table_size] of $object_record;

	$ast = record
		prefix : varying[31] of char;
		module_version : varying[31] of char;
		number : integer;
		current : integer;
		object_table : $object_table;
		symbol_hash_table : $symbol_hash_table;
		end;

procedure check_ast(var ast : $ast);
var	i : integer;
	flags : unsigned;
	info : packed array[1..16] of $ubyte;
begin
	for i:=1 to ast.number do
	  begin
		if (not ast.object_table[i].defined) then
			writeln('%IFC-W-NOTDEF, Object ',
					ast.object_table[i].symbol,
					' was not explicitly defined');
		flags:=ast.object_table[i].flags;
		info:=ast.object_table[i].info;
		if (uand(flags,513)=0) then (* not stat and not cogn *)
		  begin
			if ( (uand(flags,2)=0) and (info[5]=0) ) then
				writeln('%IFC-W-MAS, Non-static ',
					ast.object_table[i].symbol,
					' has no mass.');
			if ( (uand(flags,2)=0) and (info[6]=0) ) then
				writeln('%IFC-W-VOL, Non-static ',
					ast.object_table[i].symbol,
					' has no volume.');
			if ( (uand(flags,2)=0) and (info[7]=0) ) then
				writeln('%IFC-W-SIZ, Non-static ',
					ast.object_table[i].symbol,
					' has no size.');

			if ( ((info[3]<>0) or (uand(flags,08)<>0)) and
			     ((info[4]<>0) or (uand(flags,16)<>0)) and
				(info[2]=0) and (uand(flags,4)=0) ) then
			  begin
				writeln('%IFC-W-STR, Object ',
					ast.object_table[i].symbol,
					' needs strength - making infinite');
				flags:=uor(flags, 4);
			  end;

			if ( (uand(flags,10)=0) and (info[3]>info[6]) ) then
			  begin
				writeln('%IFC-W-CAP, Object ',
					ast.object_table[i].symbol,
					' capacity exceeds volume - ',
					'setting volume=capacity');
				ast.object_table[i].info[6]:=info[3];
			  end;

			if ( (uand(flags,18)=0) and (info[4]>info[7]) ) then
			  begin
				writeln('%IFC-W-AREA, Object ',
					ast.object_table[i].symbol,
					' area exceeds size - ',
					'setting size=area');
				ast.object_table[i].info[7]:=info[4];
			  end;

			ast.object_table[i].flags:=flags;
		  end;
	  end;
end;

procedure write_output_files(
	var ast : $ast;
	var macro_filename : varying[$u1] of char;
	var def_filename : varying[$u2] of char);

var	def_file, macro_file : text;
	o, c, i, j, free : integer;
begin
	open(def_file, def_filename, history:=new);
	rewrite(def_file);
	writeln(def_file, 'module ',ast.prefix,'DEF;');
	writeln(def_file);

	open(macro_file, macro_filename, history:=new);
	rewrite(macro_file);
	writeln(macro_file, '.psect ZZZ$IFC$DATA noexe,quad,pic,rel,gbl,shr,rd');

	writeln(def_file,'const',tab,ast.prefix,'MAX = ',ast.number:0,';');

	writeln(macro_file, ast.prefix + 'TABLE::');
	for i:=1 to ast.number do
	  begin
		writeln(def_file,tab,ast.object_table[i].symbol,' = ',i:0,';');
		writeln(macro_file, ast.object_table[i].symbol, '==', i:0);

		if (ast.object_table[i].detail.length<>0) then
		  begin
			write(macro_file, tab, '.address ' +
			      ast.object_table[i].detail);
		  end
		else	write(macro_file, tab, '.address 0');
		writeln(macro_file, tab, '; Detail');


		writeln(macro_file, tab, '.address N$$', i:0, tab,
			'; Name (see below)');

		writeln(macro_file, tab, '.long ^X' +
			hex(ast.object_table[i].flags, 8, 8),
			tab, '; Flags');

		writeln(macro_file, tab, '.long ^X' +
			hex(ast.object_table[i].count, 8, 8),
			tab, '; Count');

		if (ast.object_table[i].initial.length <> 0) then
		  begin
			writeln(macro_file, tab, '.long ',
				ast.object_table[i].initial,
				tab, '; Initial room');
		  end
		else
		  begin
			writeln(macro_file, tab, '.long ^X' +
				hex(ast.object_table[i].info[1], 8, 8),
				tab, '; Info 1');
		  end;

		for j:=2 to upper(ast.object_table[i].info) do
		  begin
			writeln(macro_file, tab, '.long ^X' +
				hex(ast.object_table[i].info[j], 8, 8),
				tab, '; Info ', j:0);
		  end;

		(* do the loop here... *)

(*		with ast.object_table[i] do
		  begin
			writeln(' Symbol "',symbol,'", detail "',detail,'"');
			writeln(tab,'Name "',name,'", initial "',initial,'"');
			writeln(tab,'Flags ',flags:0,', count ',count:0);
		  end;

		if (ast.object_table[i].flags=1) then
			for c:=1 to ast.object_table[i].count do
			  begin
				o:=ast.object_table[i].info[c];
				writeln(tab,'specific ',
					ast.object_table[o].name);
			  end; *)
	  end;

	for i:=1 to ast.number do
	  begin
		writeln(macro_file, tab, '.align quad');
		writeln(macro_file, 'N$$', i:0, ':');
		writeln(macro_file, tab, '.byte ^X' +
			hex(ast.object_table[i].name.length, 2, 2));

		write(macro_file, tab, '.ascii ');
		for j:=1 to ast.object_table[i].name.length do
		  begin
			if ((j mod 10) = 0) then
			  begin
				writeln(macro_file);
				write(macro_file, tab, '.ascii ');
			  end;

			write(macro_file, '<^X' +
			      hex(ast.object_table[i].name[j], 2, 2) + '>');
		  end;
		writeln(macro_file);
	  end;

	writeln(macro_file, tab, '.end');
	close(macro_file);

	writeln(def_file);
	writeln(def_file,'var',tab,ast.prefix,'TABLE : [external] unsigned;');
	writeln(def_file);
	writeln(def_file,'end.');
	close(def_file);
end;

procedure init_ast(var ast : $ast);
var	i : integer;
begin
	ast.prefix:='NONAME_';
	ast.module_version:='V01.00-00';

	for i:=0 to symbol_hash_size-1 do
		ast.symbol_hash_table[i]:=nil;

	ast.number:=0;
end;

function hash(var symbol : varying[$u1] of char) : integer;
var	sum, i : integer;
begin
	sum:=0;
	for i:=1 to (symbol.length) do
		sum:=sum + ord(symbol[i]);
	hash:=(sum mod symbol_hash_size);
end;

function lookup_symbol(
	var ast : $ast;
	var symbol : varying[$u1] of char;
	definition : boolean) : integer;

var	o, n, p : $object_symbol_ptr;
	i, state : integer;
	found : boolean;
begin
	o:=nil; i:=hash(symbol); found:=false; state:=-1;
	p:=ast.symbol_hash_table[i];
	while ((p<>nil) and (not found)) do
	  begin
		state:=$compare(symbol, p^.symbol);
		if (state<>1) then found:=true
		else
		  begin
			o:=p; p:=p^.next;
		  end;
	  end;

	if (state=0) then
	  begin
		if (definition) then
		  begin
			if (ast.object_table[p^.number].defined) then
				$defer_error_message(error_muldef,symbol,[],0)
			else
				ast.object_table[p^.number].defined:=true;
		  end;
		lookup_symbol:=p^.number;
	  end
	else
	  begin
		new(n);
		n^.symbol:=symbol;
		ast.number:=ast.number + 1; n^.number:=ast.number;
		n^.next:=p;

		if (o=nil) then ast.symbol_hash_table[i]:=n
		else
			o^.next:=n;

		ast.object_table[ast.number].symbol:=ast.prefix+symbol;
		ast.object_table[ast.number].defined:=definition;
		ast.object_table[ast.number].name:=symbol;
		ast.object_table[ast.number].detail.length:=0;
		ast.object_table[ast.number].initial.length:=0;
		ast.object_table[ast.number].count:=0;
		ast.object_table[ast.number].flags:=0;
		for i:=1 to 16 do
			ast.object_table[ast.number].info[i]:=0;

		lookup_symbol:=ast.number;
	  end;
end;

procedure parse_object_attr(followers : $symbol_set; var ast : $ast);
var	starters : $symbol_set;
	symbol : $symbol_desc;
	c : integer;
	mask : unsigned;
begin
	starters:=object_attributes;
	$test_symbol(starters, followers +
			[identifier, integer_constant, text_string]);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		case (symbol.token) of
		detail_keyword:
		  begin
			$advance_symbol;
			$test_symbol([identifier], followers);
			$get_symbol(symbol);
			if (symbol.token = identifier) then
			  begin
				ast.object_table[ast.current].detail:=
					symbol.string;
				$advance_symbol;
			  end;
		  end;
		initial_keyword:
		  begin
			$advance_symbol;
			$test_symbol([identifier], followers);
			$get_symbol(symbol);
			if (symbol.token = identifier) then
			  begin
				ast.object_table[ast.current].initial:=
					symbol.string;
				$advance_symbol;
			  end;
		  end;
		name_keyword:
		  begin
			$advance_symbol;
			$test_symbol([text_string], followers);
			$get_symbol(symbol);
			if (symbol.token = text_string) then
			  begin
				ast.object_table[ast.current].name:=
					symbol.string;
				$advance_symbol;
			  end;
		  end;
		static_keyword:
		  begin
			$advance_symbol;
			ast.object_table[ast.current].flags:=
				uor(ast.object_table[ast.current].flags, 2);
		  end;
		readable_keyword:
		  begin
			$advance_symbol;
			ast.object_table[ast.current].flags:=
				uor(ast.object_table[ast.current].flags, 32);
		  end;
		openable_keyword:
		  begin
			$advance_symbol;
			ast.object_table[ast.current].flags:=
				uor(ast.object_table[ast.current].flags, 64);
		  end;
		lockable_keyword:
		  begin
			$advance_symbol;
			ast.object_table[ast.current].flags:=
				uor(ast.object_table[ast.current].flags, 128);
		  end;
		startable_keyword:
		  begin
			$advance_symbol;
			ast.object_table[ast.current].flags:=
				uor(ast.object_table[ast.current].flags, 256);
		  end;
		cognizant_keyword:
		  begin
			$advance_symbol;
			ast.object_table[ast.current].flags:=
				uor(ast.object_table[ast.current].flags, 512);
		  end;
		machine_keyword:
		  begin
			$advance_symbol;
			ast.object_table[ast.current].flags:=
				uor(ast.object_table[ast.current].flags, 1024);
		  end;
		flexible_keyword:
		  begin
			$advance_symbol;
			ast.object_table[ast.current].flags:=
				uor(ast.object_table[ast.current].flags, 2048);
		  end;
		room_keyword:
		  begin
			$advance_symbol;
			ast.object_table[ast.current].flags:=
				uor(ast.object_table[ast.current].flags, 4096);
		  end;
		mass_keyword,
		volume_keyword,
		size_keyword:
		  begin
			$advance_symbol;
			c:=ord(symbol.token) - ord(strength_keyword) + 2;
			$test_symbol([integer_constant], followers);
			$get_symbol(symbol);
			if (symbol.token = integer_constant) then
			  begin
				ast.object_table[ast.current].info[c]:=
					symbol.value;
				$advance_symbol;
			  end;
		  end;
		strength_keyword,
		capacity_keyword,
		area_keyword:
		  begin
			$advance_symbol;
			c:=ord(symbol.token) - ord(strength_keyword) + 2;
			$test_symbol([integer_constant, infinite_keyword],
					followers);
			$get_symbol(symbol);
			if (symbol.token = infinite_keyword) then
			  begin
				mask:=2**c;
				ast.object_table[ast.current].flags:=uor(
					ast.object_table[ast.current].flags,
					mask);
				$advance_symbol;
			  end
			else
			if (symbol.token = integer_constant) then
			  begin
				ast.object_table[ast.current].info[c]:=
					symbol.value;
				$advance_symbol;
			  end;
		  end;

		otherwise
		end;

		$sync_symbol(followers);
	  end;
end;

procedure parse_object_attr_seq(followers : $symbol_set; var ast : $ast);
var	starters : $symbol_set;
	symbol : $symbol_desc;
begin
	starters:=object_attributes;
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		while (symbol.token in starters) do
		  begin
			parse_object_attr(followers + object_attributes, ast);
			$get_symbol(symbol);
		  end;

		$sync_symbol(followers);
	  end;
end;

procedure parse_object(followers : $symbol_set; var ast : $ast);
var	starters : $symbol_set;
	symbol : $symbol_desc;
begin
	starters:=[object_keyword];
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		$advance_symbol;

		$test_symbol([identifier], followers + object_attributes);
		$get_symbol(symbol);
		if (symbol.token = identifier) then
		  begin
			ast.current:=lookup_symbol(ast, symbol.string, true);
			ast.object_table[ast.current].flags:=0;
			ast.object_table[ast.current].count:=7;
			$advance_symbol;
		  end;

		parse_object_attr_seq(followers, ast);

		$sync_symbol(followers);
	  end;
end;

procedure parse_generic_attr(followers : $symbol_set; var ast : $ast);
var	starters : $symbol_set;
	symbol : $symbol_desc;
	c : integer;
begin
	starters:=[specific_keyword, name_keyword];
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		if (symbol.token = specific_keyword) then
		  begin
			$advance_symbol;

			$test_symbol([identifier], followers);
			$get_symbol(symbol);
			if (symbol.token = identifier) then
			  begin
				c:=ast.object_table[ast.current].count;
				c:=c+1;
				ast.object_table[ast.current].count:=c;
				ast.object_table[ast.current].info[c]:=
					lookup_symbol(ast, symbol.string,
						false);
				$advance_symbol;
			  end;
		  end
		else
		  begin
			$advance_symbol;

			$test_symbol([text_string], followers);
			$get_symbol(symbol);
			if (symbol.token = text_string) then
			  begin
				ast.object_table[ast.current].name:=
					symbol.string;
				$advance_symbol;
			  end;
		  end;

		$sync_symbol(followers);
	  end;
end;

procedure parse_generic_attr_seq(followers : $symbol_set; var ast : $ast);
var	starters : $symbol_set;
	symbol : $symbol_desc;
begin
	starters:=[specific_keyword, name_keyword];
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		parse_generic_attr(followers + starters, ast);

		$get_symbol(symbol);
		while (symbol.token in starters) do
		  begin
			parse_generic_attr(followers + starters, ast);
			$get_symbol(symbol);
		  end;

		$sync_symbol(followers);
	  end;
end;

procedure parse_generic(followers : $symbol_set; var ast : $ast);
var	starters : $symbol_set;
	symbol : $symbol_desc;
begin
	starters:=[generic_keyword];
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		$advance_symbol;

		$test_symbol([identifier], followers +
			[specific_keyword, name_keyword]);
		$get_symbol(symbol);
		if (symbol.token = identifier) then
		  begin
			ast.current:=lookup_symbol(ast, symbol.string, true);
			ast.object_table[ast.current].flags:=1;
			$advance_symbol;
		  end;

		parse_generic_attr_seq(followers, ast);

		$sync_symbol(followers);
	  end;
end;

procedure parse_object_seq(followers : $symbol_set; var ast : $ast);
var	starters : $symbol_set;
	symbol : $symbol_desc;
begin
	starters:=[object_keyword, generic_keyword];
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		if (symbol.token = object_keyword) then
			parse_object(followers +
				[object_keyword, generic_keyword], ast)
		else	parse_generic(followers +
				[object_keyword, generic_keyword], ast);

		$get_symbol(symbol);
		while (symbol.token in starters) do
		  begin
			if (symbol.token = object_keyword) then
				parse_object(followers +
					[object_keyword, generic_keyword], ast)
			else	parse_generic(followers +
					[object_keyword, generic_keyword], ast);
			$get_symbol(symbol);
		  end;

		$sync_symbol(followers);
	  end;
end;

procedure parse_object_file(followers : $symbol_set; var ast : $ast);
var	starters : $symbol_set;
	symbol : $symbol_desc;
begin
	$advance_symbol;
	starters:=[prefix_keyword];
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		$advance_symbol;

		$test_symbol([identifier], followers +
			[ident_keyword, object_keyword, generic_keyword]);
		$get_symbol(symbol);
		if (symbol.token = identifier) then
		  begin
			ast.prefix:=symbol.string;
			$advance_symbol;
		  end;
		
		$get_symbol(symbol);
		if (symbol.token = ident_keyword) then
		  begin
			$advance_symbol;

			$test_symbol([text_string], followers +
					[object_keyword, generic_keyword]);
			$get_symbol(symbol);
			if (symbol.token = text_string) then
			  begin
				ast.module_version:=symbol.string;
				$advance_symbol;
			  end;
		  end;

		parse_object_seq(followers + [end_keyword], ast);

		$test_symbol([end_keyword], followers);
		$get_symbol(symbol);
		if (symbol.token = end_keyword) then
		  begin
			$advance_symbol;
		  end;

		$sync_symbol(followers);
	  end;
end;

[global] procedure ifc$compile_objects(
	var source_filename : varying[$u1] of char;
	var macro_filename : varying[$u2] of char;
	var def_filename : varying[$u3] of char);

var	ast : $ast;

begin
	$open_lex(source_filename);
	$reset_lex(true);

	init_ast(ast);
	parse_object_file([end_of_file], ast);

	$close_lex;

	check_ast(ast);
	write_output_files(ast, macro_filename, def_filename);

end;

end.
