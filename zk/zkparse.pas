[inherit('lib$:rtldef',
	 'lib$:zk$def',
	 'lib$:zk$lex_def',
	 'lib$:zk$parse_obj_def')]
module zk$parse;

const	directions = [north_keyword, south_keyword, east_keyword,
			west_keyword, north_east_keyword,
			north_west_keyword, south_east_keyword,
			south_west_keyword, up_keyword, down_keyword,
			in_keyword, out_keyword, back_keyword];

function parse_command(
	var ast : $ast_node_ptr;
	followers : $symbol_set) : boolean;
	forward;

function parse_edswbl(
	var ast : $ast_node_ptr;
	var please : boolean;
	followers : $symbol_set) : boolean;

var	error : boolean;
	symbol : $symbol_desc;
begin
	error:=false; $get_symbol(symbol);

	new(ast, command_node);
	ast^.node_type:=command_node; ast^.list:=nil;
	ast^.keyword1:=symbol.token; ast^.keyword2:=nil_keyword;
	ast^.left:=nil; ast^.right:=nil; ast^.please:=please;

	$advance_symbol;
	$get_symbol(symbol); ast^.keyword2:=symbol.token;

	case (symbol.token) of
	go_keyword:
	  begin
		$advance_symbol;
		error:=$test_symbol([integer_constant]);
		if (not error) then
		  begin
			$get_symbol(symbol); $advance_symbol;
			new(ast^.left, number_node);
			ast^.left^.node_type:=number_node;
			ast^.left^.list:=nil;
			ast^.left^.number:=symbol.value;
		  end;
	  end;
	take_keyword:
	  begin
		$advance_symbol;
		error:=$parse_object(ast^.left, followers);
	  end;
	keypad_keyword, wait_keyword, where_keyword,
	nurse_keyword, system_keyword:
		$advance_symbol;
	end;

	parse_edswbl:=error;
end;

function parse_verb_number(
	var ast : $ast_node_ptr;
	var please : boolean;
	followers : $symbol_set) : boolean;

var	error : boolean;
	symbol : $symbol_desc;
begin
	$get_symbol(symbol);

	new(ast, command_node);
	ast^.node_type:=command_node; ast^.list:=nil;
	ast^.keyword1:=symbol.token; ast^.keyword2:=nil_keyword;
	ast^.left:=nil; ast^.right:=nil; ast^.please:=please;

	$advance_symbol;
	error:=$test_symbol([integer_constant]);
	if (not error) then
	  begin
		$get_symbol(symbol); $advance_symbol;
		new(ast^.left, number_node);
		ast^.left^.node_type:=number_node;
		ast^.left^.list:=nil;
		ast^.left^.number:=symbol.value;
	  end;
	parse_verb_number:=error;
end;

function parse_verb_object_phrase(
	var ast : $ast_node_ptr;
	var please : boolean;
	followers : $symbol_set) : boolean;

var	error : boolean;
	symbol : $symbol_desc;
begin
	$get_symbol(symbol);

	new(ast, command_node);
	ast^.node_type:=command_node; ast^.list:=nil;
	ast^.keyword1:=symbol.token; ast^.keyword2:=nil_keyword;
	ast^.left:=nil; ast^.right:=nil; ast^.please:=please;

	$advance_symbol;
	error:=$parse_object_list(ast^.left, symbol.string,
			followers + [comma_symbol]);
	if (not error) then
	  begin
		error:=$test_symbol([comma_symbol]);
		if (not error) then
		  begin
			$advance_symbol;
			error:=parse_command(ast^.right, followers);
		  end;
	  end;

	parse_verb_object_phrase:=error;
end;

function parse_verb(
	var ast : $ast_node_ptr;
	var please : boolean;
	followers : $symbol_set) : boolean;

var	error : boolean;
	symbol : $symbol_desc;
begin
	$get_symbol(symbol);

	new(ast, command_node);
	ast^.node_type:=command_node; ast^.list:=nil;
	ast^.keyword1:=symbol.token; ast^.keyword2:=nil_keyword;
	ast^.left:=nil; ast^.right:=nil; ast^.please:=please;

	$advance_symbol;
	parse_verb:=false;
end;

function parse_direction(
	var keyword : $symbol_token;
	followers : $symbol_set) : boolean;

var	error : boolean;
	symbol : $symbol_desc;
begin
	error:=false;
	$get_symbol(symbol); keyword:=symbol.token;
	if (symbol.token = north_keyword) then
	  begin
		$advance_symbol; $get_symbol(symbol);
		if (symbol.token = east_keyword) then
		  begin
			keyword:=north_east_keyword; $advance_symbol;
		  end
		else
		if (symbol.token = west_keyword) then
		  begin
			keyword:=north_west_keyword; $advance_symbol;
		  end;
	  end
	else
	if (symbol.token=south_keyword) then
	  begin
		$advance_symbol; $get_symbol(symbol);
		if (symbol.token = east_keyword) then
		  begin
			keyword:=south_east_keyword; $advance_symbol;
		  end
		else
		if (symbol.token = west_keyword) then
		  begin
			keyword:=south_west_keyword; $advance_symbol;
		  end
	  end
	else
	  begin
		error:=$test_symbol(directions);
		if (not error) then $advance_symbol;
	  end;

	parse_direction:=error;
end;

function parse_verb_direction(
	var ast : $ast_node_ptr;
	var please : boolean;
	followers : $symbol_set) : boolean;

var	error : boolean;
	symbol : $symbol_desc;
begin
	error:=false;
	$get_symbol(symbol);

	new(ast, command_node);
	ast^.node_type:=command_node; ast^.list:=nil;
	ast^.keyword1:=go_keyword; ast^.keyword2:=nil_keyword;;
	ast^.left:=nil; ast^.right:=nil; ast^.please:=please;

	if (symbol.token in directions) then
		error:=parse_direction(ast^.keyword2, followers)
	else
	if (symbol.token=go_keyword) then
	  begin
		$advance_symbol;
		error:=parse_direction(ast^.keyword2, followers);
	  end
	else
	if (symbol.token=move_keyword) then
	  begin
		ast^.keyword1:=move_keyword;
		$advance_symbol; $get_symbol(symbol);
		if (not (symbol.token in directions)) then
		  begin
			error:=$parse_object(ast^.left, followers + directions);
			if (not error) then
			  begin
				$get_symbol(symbol);
				if (symbol.token in directions) then
					error:=parse_direction(ast^.keyword2,
								followers);
			  end;
		  end
		else	error:=parse_direction(ast^.keyword2, followers);
	  end;

	parse_verb_direction:=error;
end;

function parse_verb_object(
	var ast : $ast_node_ptr;
	var please : boolean;
	followers : $symbol_set) : boolean;

var	error : boolean;
	symbol : $symbol_desc;
begin
	$get_symbol(symbol); error:=false;

	new(ast, command_node);
	ast^.node_type:=command_node; ast^.list:=nil;
	ast^.keyword1:=symbol.token; ast^.keyword2:=nil_keyword;
	ast^.left:=nil; ast^.right:=nil; ast^.please:=please;

	$advance_symbol;
	if (symbol.token=inventory_keyword) then
	  begin
		$get_symbol(symbol);
		if (not (symbol.token in followers)) then
			error:=$parse_object_list(ast^.left, symbol.string,
					followers);
	  end
	else
	if (symbol.token=locate_keyword) then
		error:=$parse_object(ast^.right, followers)
	else
		error:=$parse_object_list(ast^.left, symbol.string,
				followers);
	parse_verb_object:=error;
end;

function parse_verb_obj_prep_obj_opt(
	var ast : $ast_node_ptr;
	preposition : $symbol_set;
	var please : boolean;
	followers : $symbol_set) : boolean;

var	error : boolean;
	symbol : $symbol_desc;
	verb_string : $symbol_string;
begin
	$get_symbol(symbol);
	verb_string:=symbol.string;

	new(ast, command_node);
	ast^.node_type:=command_node; ast^.list:=nil;
	ast^.keyword1:=symbol.token; ast^.keyword2:=nil_keyword;
	ast^.left:=nil; ast^.right:=nil; ast^.please:=please;

	$advance_symbol;
	error:=$parse_object_list(ast^.left, verb_string,
			followers + preposition);
	if (not error) then
	  begin
		$get_symbol(symbol);
		if (symbol.token in preposition) then
		  begin
			$advance_symbol;
			ast^.keyword2:=symbol.token;
			verb_string:=verb_string+' the object ' +
					symbol.string;
			error:=$parse_object_list(ast^.right, verb_string,
						followers);
		  end;
	  end;
	parse_verb_obj_prep_obj_opt:=error;
end;

function parse_verb_obj_prep_obj(
	var ast : $ast_node_ptr;
	preposition : $symbol_set;
	var please : boolean;
	followers : $symbol_set) : boolean;

var	error : boolean;
	symbol : $symbol_desc;
	verb_string : $symbol_string;
begin
	$get_symbol(symbol);
	verb_string:=symbol.string;

	new(ast, command_node);
	ast^.node_type:=command_node; ast^.list:=nil;
	ast^.keyword1:=symbol.token; ast^.keyword2:=nil_keyword;;
	ast^.left:=nil; ast^.right:=nil; ast^.please:=please;

	$advance_symbol;
	error:=$parse_object_list(ast^.left, verb_string,
			followers + preposition);
	if (not error) then
	  begin
		error:=$test_symbol(preposition);
		if (not error) then
		  begin
			$get_symbol(symbol);
			ast^.keyword2:=symbol.token;
			verb_string:=verb_string+' the object '+symbol.string;

			$advance_symbol;
			error:=$parse_object_list(ast^.right, verb_string,
						followers);
		  end;
	  end;

	parse_verb_obj_prep_obj:=error;
end;

function parse_verb_string(
	var ast : $ast_node_ptr;
	var please : boolean;
	followers : $symbol_set) : boolean;

var	error : boolean;
	i : integer;
	symbol : $symbol_desc;
	string_ast : $ast_node_ptr;
	temp : $symbol_string;
begin
	error:=false;
	$get_symbol(symbol);

	new(ast, command_node);
	ast^.node_type:=command_node; ast^.list:=nil;
	ast^.keyword1:=symbol.token; ast^.keyword2:=nil_keyword;
	ast^.left:=nil; ast^.right:=nil; ast^.please:=please;

	$advance_symbol;
	$get_symbol(symbol);
	if (symbol.token in followers) then
		error:=$test_symbol([])
	else
	  begin
		temp:='';
		while ( (not(symbol.token in followers)) and (not error) ) do
		  begin
			if (symbol.token=invalid) then
				error:=$test_symbol([])
			else
			  begin
				temp:=temp + symbol.string;
				$advance_symbol;
				$get_symbol(symbol);
			  end;
		  end;
		if (not error) then
		  begin
			new(string_ast, string_node);
			string_ast^.node_type:=string_node;
			string_ast^.list:=nil;
			string_ast^.string:=''; ast^.left:=string_ast;
			$upcase(temp, temp);
			for i:=1 to temp.length do
				string_ast^.string:=string_ast^.string +
					temp[i];
		  end;
	  end;

	parse_verb_string:=error;
end;

function parse_verb_prep_obj(
	var ast : $ast_node_ptr;
	var please : boolean;
	followers : $symbol_set) : boolean;

var	error : boolean;
	symbol, symbol1 : $symbol_desc;
	verb_string : $symbol_string;
begin
	error:=false;
	$get_symbol(symbol);

	new(ast, command_node);
	ast^.node_type:=command_node; ast^.list:=nil;
	ast^.keyword1:=symbol.token; ast^.keyword2:=nil_keyword;
	ast^.left:=nil; ast^.right:=nil; ast^.please:=please;

	verb_string:=symbol.string;
	case (symbol.token) of
	pick_keyword:
	  begin
		$advance_symbol;
		error:=$test_symbol([up_keyword]);
		if (not error) then
		  begin
			$advance_symbol;
			verb_string:='pick up';
			error:=$parse_object_list(ast^.left, verb_string,
					followers);
		  end;
	  end;
	where_keyword:
	  begin
		$advance_symbol;
		error:=$test_symbol([is_keyword]);
		if (not error) then
		  begin
			$advance_symbol;
			verb_string:='locate';
			error:=$parse_object_list(ast^.right, verb_string,
					followers);
		  end;
	  end;
	put_keyword:
	  begin
		$advance_symbol;
		$get_symbol(symbol);
		if (symbol.token in [on_keyword, down_keyword]) then
		  begin
			ast^.keyword2:=symbol.token;
			verb_string:=verb_string+' '+symbol.string;
			$advance_symbol;
			error:=$parse_object_list(ast^.left, verb_string,
							followers);
		  end
		else
		  begin
			error:=$parse_object_list(ast^.left, verb_string,
					followers + [on_keyword, in_keyword,
							down_keyword]);
			if (not error) then
			  begin
				error:=$test_symbol([in_keyword, on_keyword,
							down_keyword]);
				if (not error) then
				  begin
					$get_symbol(symbol);
					ast^.keyword2:=symbol.token;
					verb_string:=verb_string+
							' the object '+
							symbol.string;
					$advance_symbol; $get_symbol(symbol1);
					if (symbol.token=in_keyword) then
						error:=$parse_object_list(
							ast^.right, verb_string,
							followers)
					else
					if (not (symbol1.token in
						 followers) ) then
						error:=$parse_object_list(
							ast^.right, verb_string,
							followers);
				  end;
			  end;
		  end;
	  end;
	look_keyword:
	  begin
		$advance_symbol;
		$get_symbol(symbol);
		if (symbol.token in [at_keyword, in_keyword]) then
		  begin
			ast^.keyword2:=symbol.token;
			verb_string:=verb_string+' '+symbol.string;

			$advance_symbol;
			error:=$parse_object_list(ast^.left, verb_string,
					followers);
		  end
		else
		if (symbol.token=up_keyword) then
		  begin
			ast^.keyword2:=symbol.token;
			$advance_symbol;
			error:=$test_symbol([text_string]);
			if (not error) then
			  begin
				$get_symbol(symbol);
				new(ast^.left, string_node);
				ast^.left^.node_type:=string_node;
				ast^.left^.list:=nil;
				ast^.left^.string:=symbol.string;
				$advance_symbol;
			  end;
		  end;
	  end;
	turn_keyword:
	  begin
		$advance_symbol;
		$get_symbol(symbol);
		if (symbol.token in [on_keyword, off_keyword]) then
		  begin
			ast^.keyword2:=symbol.token;
			verb_string:=verb_string+' '+symbol.string;
			$advance_symbol;
			error:=$parse_object_list(ast^.left, verb_string,
				followers);
		  end
		else
		  begin
			error:=$parse_object_list(ast^.left, verb_string,
				followers + [on_keyword, off_keyword]);
			if (not error) then
			  begin
				$get_symbol(symbol);
				if (symbol.token in
					[on_keyword, off_keyword]) then
				  begin
					$get_symbol(symbol);
					ast^.keyword2:=symbol.token;
					verb_string:=verb_string+' '+
						symbol.string;
					$advance_symbol;
				  end;
			  end;
		  end;
	  end;
	shut_keyword:
	  begin
		$advance_symbol;
		$get_symbol(symbol);
		if (symbol.token in [off_keyword]) then
		  begin
			ast^.keyword2:=symbol.token;
			verb_string:=verb_string+' '+symbol.string;
			$advance_symbol;
			error:=$parse_object_list(ast^.left, verb_string,
				followers);
		  end
		else
		  begin
			error:=$parse_object_list(ast^.left, verb_string,
				followers + [off_keyword]);
			if (not error) then
			  begin
				$get_symbol(symbol);
				if (not (symbol.token in followers)) then
				  begin
					error:=$test_symbol([off_keyword]);
					if (not error) then
					  begin
						$get_symbol(symbol);
						ast^.keyword2:=symbol.token;
						verb_string:=verb_string+' '+
							symbol.string;
						$advance_symbol;
					  end;
				  end;
			  end;
		  end;
	  end;
	get_keyword:
	  begin
		$advance_symbol;
		$get_symbol(symbol);
		if (symbol.token in [on_keyword, off_keyword]) then
		  begin
			$get_symbol(symbol);
			ast^.keyword1:=stand_keyword;
			ast^.keyword2:=symbol.token;
			verb_string:=verb_string+' '+symbol.string;
			$advance_symbol;
		  end
		else	ast^.keyword1:=take_keyword;
		error:=$parse_object_list(ast^.left, verb_string, followers);
	  end;
	stand_keyword:
	  begin
		$advance_symbol;
		error:=$test_symbol([on_keyword, off_keyword]);
		if (not error) then
		  begin
			$get_symbol(symbol);
			ast^.keyword2:=symbol.token;
			verb_string:=verb_string+' '+symbol.string;
			$advance_symbol;
			error:=$parse_object_list(ast^.left, verb_string,
					followers);
		  end;
	  end;
	play_keyword:
	  begin
		$advance_symbol;
		error:=$test_symbol([with_keyword]);
		if (not error) then
		  begin
			$get_symbol(symbol);
			ast^.keyword2:=symbol.token;
			verb_string:=verb_string+' '+symbol.string;
			$advance_symbol;
			error:=$parse_object_list(ast^.left, verb_string,
					followers);
		  end;
	  end;
	otherwise
		error:=$test_symbol([]);
	end;

	parse_verb_prep_obj:=error;
end;

function parse_command; (* forward *)
var	please, error : boolean;
	symbol : $symbol_desc;
begin
	$get_symbol(symbol);
	please:=false;
	if (symbol.token = please_keyword) then
	  begin
		please:=true; $advance_symbol; $get_symbol(symbol);
	  end;

	case (symbol.token) of

	enter_keyword, exit_keyword, jump_keyword, scream_keyword,
	pray_keyword, quit_keyword, xyzzy_keyword, plugh_keyword,
	version_keyword, wait_keyword, score_keyword, restart_keyword,
	brief_keyword, verbose_keyword, hello_keyword, install_keyword:
		error:=parse_verb(ast, please, followers);

	in_keyword, out_keyword, back_keyword, east_keyword, west_keyword,
	north_east_keyword, north_west_keyword,	north_keyword, south_keyword, 
	south_east_keyword, south_west_keyword, up_keyword, down_keyword,
	go_keyword, move_keyword:
		error:=parse_verb_direction(ast, please, followers);

	examine_keyword, drop_keyword, read_keyword,
	inventory_keyword, follow_keyword, wear_keyword,
	take_keyword, locate_keyword, shake_keyword,
	boot_keyword, drink_keyword:
		error:=parse_verb_object(ast, please, followers);

	kill_keyword, open_keyword, close_keyword, start_keyword,
	stop_keyword, rub_keyword, lock_keyword, unlock_keyword,
	heal_keyword, light_keyword:
		error:=parse_verb_obj_prep_obj_opt(ast, [with_keyword],
						please, followers);
	give_keyword:
		error:=parse_verb_obj_prep_obj(ast, [to_keyword],
						please, followers);

	look_keyword, stand_keyword, turn_keyword,
	shut_keyword, play_keyword, put_keyword, where_keyword,
	pick_keyword, get_keyword:
		error:=parse_verb_prep_obj(ast, please, followers);

	say_keyword, save_keyword, restore_keyword:
		error:=parse_verb_string(ast, please, followers);
	tell_keyword:
		error:=parse_verb_object_phrase(ast, please, followers);
	type_keyword:
		error:=parse_verb_number(ast, please, followers);
	edswbl_keyword:
		error:=parse_edswbl(ast, please, followers);
	end_of_line:
		ast:=nil;
	otherwise
		error:=$parse_object(ast, followers);
	end;
	parse_command:=error;
end;

[global] function zk$parse_command_line(
	var ast : $ast_node_ptr;
	followers : $symbol_set) : boolean;

var	error : boolean;
	symbol : $symbol_desc;
	next_ast : $ast_node_ptr;
begin
	$advance_symbol;

	error:=parse_command(ast, followers+[then_keyword, period_symbol]);
	next_ast:=ast;

	$get_symbol(symbol);
	while ( (symbol.token in [then_keyword, period_symbol]) and
		(not error) ) do
	  begin
		$advance_symbol;
		if (symbol.token=then_keyword) then
			error:=parse_command(next_ast^.list,
				followers + [then_keyword, period_symbol])
		else
		  begin
			$get_symbol(symbol);
			if (symbol.token <> end_of_line) then
				error:=parse_command(next_ast^.list,
				followers + [then_keyword, period_symbol]);
		   end;
		if (not error) then
		  begin
			$get_symbol(symbol);
			next_ast:=next_ast^.list;
		  end;
	  end;

	if (not error) then error:=$test_symbol(followers);

	zk$parse_command_line:=error;
end;

end.
