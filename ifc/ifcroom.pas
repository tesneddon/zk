[inherit('lib$:typedef',
	 'lib$:rtldef',
	 'lib$:ifc$lex_def',
	 'lib$:ifc$def')]
module ifc$room(output);

(* Edit History                                                             *)
(* 13-Sep-2009  TES  Converted to generate MACRO-32, not VAX objects.       *)
(* 03-Jul-2013  TES  Output MAX symbol in MACRO too.			    *)
(*                                                                          *)

const	directions = [north_keyword, south_keyword, east_keyword, west_keyword,
		      north_east_keyword, north_west_keyword, up_keyword,
		      south_east_keyword, south_west_keyword, down_keyword,
		      in_keyword, out_keyword];

	symbol_hash_size = 101;
	room_table_size = 100;
	tab = chr(9);

type	$room_symbol_ptr = ^$room_symbol;
	$room_symbol = record
			symbol : varying[31] of char;
			number : $ubyte;
			next : $room_symbol_ptr;
		     end;

	$symbol_hash_table = packed array[0..symbol_hash_size-1]
						of $room_symbol_ptr;
	$room_info = packed record
			symbol : varying[31] of char;
			defined : boolean;
			name : varying[31] of char;
			description : varying[31] of char;
			link : packed array[1..12] of $ubyte;
			door : packed array[1..2] of varying[31] of char;
			class : integer;
		     end;

	$room_table = packed array[1..room_table_size] of $room_info;

	$ast = packed record
			prefix : varying[31] of char;
			module_version : varying[31] of char;
			symbol_hash_table : $symbol_hash_table;
			number : integer;
			room_table : $room_table;
		end;

var	direction_name : packed array[1..12] of
		varying[10] of char :=
			('north', 'south', 'east', 'west', 'north east',
			 'south west', 'south east', 'north west', 'up',
			 'down', 'in', 'out');

procedure check_ast(var ast : $ast);
var	rd, c, d, f, b : integer;
	connections_out : boolean;
begin
	for c:=1 to ast.number do
	  begin
		if (not ast.room_table[c].defined) then
			writeln('%IFC-W-NOTDEF, Room ',
					ast.room_table[c].symbol,
					' was not explicitly defined');
		connections_out:=false;
		for d:=1 to 12 do
		  begin
			f:=ast.room_table[c].link[d];
			if (f<>0) then
			  begin
				connections_out:=true;
				if (odd(d)) then
					b:=ast.room_table[f].link[d+1]
				else	b:=ast.room_table[f].link[d-1];
				if (b<>c) then
					writeln('%IFC-I-NOTSYM, The path ',
						direction_name[d],' from room ',
						ast.room_table[c].symbol,
						' to room ',
						ast.room_table[f].symbol,
						' is not symmetric');
				if (d>10) then
				  begin
					if (d=11) then rd:=2
					else rd:=1;
					if (ast.room_table[b].door[d-10]<>
					     ast.room_table[f].door[rd]) then
					writeln('%IFC-I-DOOR, The door ',
						direction_name[d],' from room ',
						ast.room_table[c].symbol,
						' to room ',
						ast.room_table[f].symbol,
						' is not symmetric');
				  end;			
			  end	
		  end;

		if (not connections_out) then
			writeln('%IFC-I-NOEXIT, Room ',
				ast.room_table[c].symbol,
				' has no exits');
	  end;
end;

procedure write_output_files(
	var macro_filename : varying[$u1] of char;
	var def_filename : varying[$u2] of char;
	var ast : $ast);

var	def_file, macro_file : text;
	i,j : integer;
	comment, door : varying[31] of char;
begin
	open(def_file, def_filename, history:=new);
	rewrite(def_file);
	writeln(def_file, 'module ',ast.prefix,'DEF;');
	writeln(def_file);

	open(macro_file, macro_filename, history:=new);
	rewrite(macro_file);
	writeln(macro_file, '.psect ZZZ$IFC$DATA noexe,quad,pic,rel,gbl,shr,rd');

	writeln(def_file,'const',tab,ast.prefix,'MAX = ',ast.number:0,';');
	writeln(macro_file,tab,ast.prefix,'MAX==',ast.number:0);

	writeln(macro_file, ast.prefix + 'TABLE::');
	for i:=1 to ast.number do
	  begin
		writeln(def_file,tab,ast.room_table[i].symbol,' = ',i:0,';');
                writeln(macro_file, ast.room_table[i].symbol, '==', i:0);

		if (ast.room_table[i].description.length<>0) then
		  begin
			write(macro_file, tab, '.address ' +
				ast.room_table[i].description);
		  end
		else	write(macro_file, '.address 0');
		writeln(macro_file, tab, '; Description');

		writeln(macro_file, tab, '.address N$$', i:0, tab,
			'; Name (see below)');
		writeln(macro_file, tab, '.long ^X' +
			hex(ast.room_table[i].class, 8, 8),
			tab, '; Class');

		for j:=1 to upper(ast.room_table[i].link) do
		  begin
			if (ast.room_table[i].link[j] <> 0) then
			  begin
				comment := 'Link to ' 
					 + ast.room_table[ast.room_table[i].link[j]].name;
			  end
			else	comment := 'No link';

			writeln(macro_file, tab, '.long ^X' +
				hex(ast.room_table[i].link[j], 8, 8),
				tab, '; ' + comment);
		  end;
			    
(*		write(i:3,': ');
		for j:=1 to 12 do
			write(ast.room_table[i].link[j]:4);
		writeln; *)

		for j:=1 to 2 do
		  begin
			door:=ast.room_table[i].door[j];
			if (door.length<>0) then
			  begin
				writeln(macro_file, tab, '.long ',
					ast.room_table[i].door[j],
					tab, '; Door');
(*				writeln('Door ',j:0,' ',door); *)
			  end
			else	writeln(macro_file, '.long 0');
		  end;

(*		for j:=1 to 12 do
		  if (ast.room_table[i].link[j]<>0) then
		    begin
			writeln(ast.room_table[i].symbol,' ',
				direction_name[j],' ',
				ast.room_table[
					ast.room_table[i].link[j]].symbol);
		    end;*)

(*		writeln(' Symbol "', ast.room_table[i].symbol,
			'", name "', ast.room_table[i].name,
			'", desc "', ast.room_table[i].description,'"'); *)
	  end;

	for i:=1 to ast.number do
	  begin
		writeln(macro_file, tab, '.align quad');
		writeln(macro_file, 'N$$', i:0, ':');
		writeln(macro_file, tab, '.byte ^X' +
			hex(ast.room_table[i].name.length, 2, 2));

		write(macro_file, tab, '.ascii ');
		for j:=1 to ast.room_table[i].name.length do
		  begin
			if ((j mod 10) = 0) then
			  begin
				writeln(macro_file);
				write(macro_file, tab, '.ascii ');
			  end;

			write(macro_file, '<^X' +
			      hex(ast.room_table[i].name[j], 2, 2) + '>');
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

var	o, n, p : $room_symbol_ptr;
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
			if (ast.room_table[p^.number].defined) then
				$defer_error_message(error_muldef,symbol,[],0)
			else
				ast.room_table[p^.number].defined:=true;
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

		ast.room_table[ast.number].symbol:=ast.prefix+symbol;
		ast.room_table[ast.number].defined:=definition;
		ast.room_table[ast.number].name:=symbol;
		ast.room_table[ast.number].description:='';
		ast.room_table[ast.number].class:=0;
		for i:=1 to 12 do
			ast.room_table[ast.number].link[i]:=0;
		ast.room_table[ast.number].door[1]:='';
		ast.room_table[ast.number].door[2]:='';
		lookup_symbol:=ast.number;
	  end;
end;

procedure parse_room(followers : $symbol_set; var ast : $ast);

var	symbol : $symbol_desc;
	starters : $symbol_set;
	d, i : integer;
begin
	i:=room_table_size-1;
	starters:=[room_keyword];
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		$advance_symbol;

		$test_symbol([identifier], followers +
			[name_keyword, description_keyword]);
		$get_symbol(symbol);
		if (symbol.token=identifier) then
		  begin
			i:=lookup_symbol(ast, symbol.string, true);
			$advance_symbol;
		  end;

		$get_symbol(symbol);
		if (symbol.token = name_keyword) then
		  begin
			$advance_symbol;

			$test_symbol([text_string], followers);
			$get_symbol(symbol);
			if (symbol.token=text_string) then
			  begin
				ast.room_table[i].name:=symbol.string;
				$advance_symbol;
			  end;
		  end;

		$test_symbol([description_keyword], followers);
		$get_symbol(symbol);
		if (symbol.token = description_keyword) then
		  begin
			$advance_symbol;

			$test_symbol([identifier], followers);
			$get_symbol(symbol);
			if (symbol.token=identifier) then
			  begin
				ast.room_table[i].description:=symbol.string;
				$advance_symbol;
			  end;
		  end;

		$get_symbol(symbol);
		if (symbol.token = class_keyword) then
		  begin
			$advance_symbol;
			$test_symbol([integer_constant], followers);
			$get_symbol(symbol);
			if (symbol.token = integer_constant) then
			  begin
				ast.room_table[i].class:=symbol.value;
				$advance_symbol;
			  end;
		  end;

		$get_symbol(symbol);
		while (symbol.token in directions) do
		  begin
			d:=ord(symbol.token) - ord(north_keyword) + 1;
			$advance_symbol;

			$test_symbol([identifier], followers);
			$get_symbol(symbol);
			if (symbol.token=identifier) then
			  begin
				ast.room_table[i].link[d]:=
					lookup_symbol(ast,symbol.string,false);
				$advance_symbol;
				if (d>10) then
				  begin
					$get_symbol(symbol);
					if (symbol.token=door_keyword) then
					  begin
						$advance_symbol;
						$test_symbol([identifier],
							followers);
						$get_symbol(symbol);
						if (symbol.token=identifier)
						then
						begin
						ast.room_table[i].door[d-10]:=
							symbol.string;
						$advance_symbol;
						end;
					  end;
				  end;
			  end;

			$get_symbol(symbol);
		  end;

		$sync_symbol(followers);
	  end;
end;

procedure parse_room_seq(followers : $symbol_set; var ast : $ast);

var	symbol : $symbol_desc;
	starters : $symbol_set;
begin
	starters:=[room_keyword];
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		parse_room(followers + [room_keyword], ast);

		$get_symbol(symbol);
		while (symbol.token in starters) do
		  begin
			parse_room(followers + [room_keyword], ast);
			$get_symbol(symbol);
		  end;

		$sync_symbol(followers);
	  end;
end;

procedure parse_room_file(followers : $symbol_set; var ast : $ast);

var	symbol : $symbol_desc;
	starters : $symbol_set;
begin
	ast.prefix:='NONAME';
	ast.module_version:='V01.00-00';

	$advance_symbol;
	starters:=[prefix_keyword];
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		$advance_symbol;

		$test_symbol([identifier], followers +
			[ident_keyword, room_keyword]);
		$get_symbol(symbol);
		if (symbol.token=identifier) then
		  begin
			ast.prefix:=symbol.string;
			$advance_symbol;
		  end;

		$get_symbol(symbol);
		if (symbol.token=ident_keyword) then
		  begin
			$advance_symbol;
			$test_symbol([text_string], followers +
				[room_keyword]);
			$get_symbol(symbol);
			if (symbol.token=text_string) then
			  begin
				ast.module_version:=symbol.string;
				$advance_symbol;
			  end;
		  end;

		parse_room_seq(followers+[end_keyword], ast);

		$test_symbol([end_keyword], followers);
		$get_symbol(symbol);
		if (symbol.token = end_keyword) then
		  begin
			$advance_symbol;
		  end;

		$sync_symbol(followers);
	end;
end;

[global] procedure ifc$compile_rooms(
	room_filename : varying[$u1] of char;
	macro_filename : varying[$u2] of char;
	def_filename : varying[$u3] of char);

var	ast : $ast;
begin
	init_ast(ast);

	$open_lex(room_filename); $reset_lex(true);
	parse_room_file([end_of_file], ast);
	$close_lex;

	check_ast(ast);
	write_output_files(macro_filename, def_filename, ast);
end;

end.
