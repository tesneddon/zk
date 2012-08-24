[inherit('lib$:ifc$lex_def',
	 'lib$:ifc$def')]
module ifc$message(output);

const	tab = chr(9);

var	prefix : varying[31] of char;
	def_file : text;
	macro_file : text;

procedure parse_qualifier_list(
	followers : $symbol_set;
	var fao_count, attributes : unsigned);

var	symbol : $symbol_desc;
	starters : $symbol_set;
	mask : unsigned;
begin
	fao_count:=0;
	starters:=[fslash_symbol];
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	while (symbol.token in starters) do
	  begin
		$advance_symbol;
		$test_symbol([fao_keyword, bold_keyword, reverse_keyword,
				blink_keyword, underline_keyword], followers);
		$get_symbol(symbol);
		if (symbol.token = fao_keyword) then
		  begin
			$advance_symbol;
			$test_symbol([equal_symbol], followers +
					[integer_constant]);
			$get_symbol(symbol);
			if (symbol.token = equal_symbol) then
			  begin
				$advance_symbol;
			  end;

			$test_symbol([integer_constant], followers);
			$get_symbol(symbol);
			if (symbol.token = integer_constant) then
			  begin
				fao_count:=symbol.value;
				$advance_symbol;
			  end;
		  end
		else
		if (symbol.token in [bold_keyword, reverse_keyword,
			blink_keyword, underline_keyword]) then
		  begin
			mask:=2**(ord(symbol.token)-ord(bold_keyword));
			attributes:=uor(attributes, mask);
			$advance_symbol;
		  end;

		$get_symbol(symbol);
	  end;
	$sync_symbol(followers);
end;

procedure parse_text(
	followers : $symbol_set;
	default_attributes : unsigned);

var	symbol : $symbol_desc;
	starters : $symbol_set;
	attributes, fao_count, i : unsigned;
	message_text : $symbol_string;
begin
	attributes:=default_attributes;
	fao_count:=0;

	message_text.length:=0;
	starters:=[text_string];
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		message_text:=symbol.string;
		$advance_symbol;

		$get_symbol(symbol);
		if (symbol.token = fslash_symbol) then
			parse_qualifier_list(followers, fao_count, attributes);

		writeln(macro_file, tab, '.byte ^X' +
			hex(message_text.length, 2, 2),
			tab, '; Message length');
		writeln(macro_file, tab, '.byte ^X' +
			hex(fao_count, 2, 2),
			tab, '; FAO count');
		writeln(macro_file, tab, '.byte ^X' +
			hex(attributes, 2, 2),
		        tab, '; Attributes');

		write(macro_file, tab, '.ascii ');
		for i:=1 to message_text.length do
		  begin
			if ((i mod 10) = 0) then
			  begin
				writeln(macro_file);
				write(macro_file, tab, '.ascii ');
			  end;

			write(macro_file, '<^X' + hex(message_text[i], 2) + '>');
		  end; 
		writeln(macro_file);

		$sync_symbol(followers);
	  end;
end;

procedure parse_text_seq(
	followers : $symbol_set;
	var attributes : unsigned);

var	symbol : $symbol_desc;
	starters : $symbol_set;
begin
	starters:=[text_string];
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		parse_text(followers + [text_string], attributes);

		$get_symbol(symbol);
		while (symbol.token in starters) do
		  begin
			parse_text(followers + [text_string], attributes);
			$get_symbol(symbol);
		  end;

		$sync_symbol(followers);
	  end;
end;

procedure parse_message(followers : $symbol_set; first : boolean);
var	symbol : $symbol_desc;
	starters : $symbol_set;
	default_attributes, fao_count : unsigned;
begin
	default_attributes:=0;
	starters:=[message_keyword];
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		$advance_symbol;

		$test_symbol([identifier], followers +
				[fslash_symbol, text_string]);
		$get_symbol(symbol);
		if (symbol.token = identifier) then
		  begin
			writeln(macro_file, tab, '.align quad');
			writeln(macro_file, prefix + symbol.string + '::');
			if (first) then
				write(def_file,'var', tab, prefix,
					symbol.string)
			else
			  begin
				writeln(def_file,',');
				write(def_file,tab,prefix,symbol.string);
			  end;
			$advance_symbol;
		  end;

		$get_symbol(symbol);
		if (symbol.token = fslash_symbol) then
			parse_qualifier_list(followers + [text_string],
				fao_count, default_attributes);

		parse_text_seq(followers, default_attributes);

		writeln(macro_file, tab, '.word ^X0000', tab, '; Terminator');

		$sync_symbol(followers);
	  end;
end;

procedure parse_message_seq(followers : $symbol_set);
var	symbol : $symbol_desc;
	starters : $symbol_set;
begin
	starters:=[message_keyword];
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		parse_message(followers + [message_keyword], true);

		$get_symbol(symbol);
		while (symbol.token in starters) do
		  begin
			parse_message(followers + [message_keyword], false);
			$get_symbol(symbol);
		  end;

		$sync_symbol(followers);
	  end;
end;

procedure parse_message_file(followers : $symbol_set);
var	symbol : $symbol_desc;
	starters : $symbol_set;
	module_version : varying[31] of char;
begin
	prefix:='NONAME';
	module_version:='V01.00-00';

	$advance_symbol;
	starters:=[prefix_keyword];
	$test_symbol(starters, followers);
	$get_symbol(symbol);
	if (symbol.token in starters) then
	  begin
		$advance_symbol;

		$test_symbol([identifier], followers +
			[ident_keyword, message_keyword]);
		$get_symbol(symbol);
		if (symbol.token=identifier) then
		  begin
			prefix:=symbol.string;
			$advance_symbol;
		  end;

		$get_symbol(symbol);
		if (symbol.token=ident_keyword) then
		  begin
			$advance_symbol;
			$test_symbol([text_string], followers +
				[message_keyword]);
			$get_symbol(symbol);
			if (symbol.token=text_string) then
			  begin
				module_version:=symbol.string;
				$advance_symbol;
			  end;
		  end;

		writeln(def_file, 'module ',prefix,'DEF;');
		writeln(def_file);

		parse_message_seq(followers + [end_keyword]);

		writeln(def_file,' : [external, value] unsigned;');
		writeln(def_file);
		writeln(def_file,'end.');

		$test_symbol([end_keyword], followers);
		$get_symbol(symbol);
		if (symbol.token = end_keyword) then
		  begin
			$advance_symbol;
		  end;

		$sync_symbol(followers);
	  end;
end;

[global] procedure ifc$compile_messages(
	message_filename : varying[$u1] of char;
	macro_filename : varying[$u2] of char;
	def_filename : varying[$u3] of char);
begin
	$open_lex(message_filename); $reset_lex(true);

	open(def_file, def_filename, history:=new);
	rewrite(def_file);

	open(macro_file, macro_filename, history:=new);
	rewrite(macro_file);

	writeln(macro_file, '.psect ZZZ$IFC$DATA noexe,quad,pic,rel,gbl,shr,rd');

	parse_message_file([end_of_file]);

	$close_lex;
	close(def_file);
	writeln(macro_file, tab, '.end');
	close(macro_file);
end;

end.
