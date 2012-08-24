[inherit('lib$:rtldef',
	 'lib$:zk$context_def',
	 'lib$:zk$def',
	 'lib$:zk$obj', 'lib$:zk$text',
	 'lib$:zk$action_def', 'lib$:zk$wizard_def', 'lib$:zk$object_def',
	 'lib$:zk$routines_def', 'lib$:zk$init_def',
	 'ifc$library:ifc$rtl_def')]
module zk$ast;

const	vowels = ['A','E','I','O','U','a','e','i','o','u'];
	dark_commands = [go_keyword, start_keyword, turn_keyword,
			 light_keyword, edswbl_keyword, quit_keyword,
			 say_keyword];

[global] function zk$dispatch_command(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var ast : $ast_node_ptr) : boolean;
	forward;

function dispatch_number(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var keyword1, keyword2 : $symbol_token;
	var number : integer) : boolean;
var	error : boolean;
begin
	if (keyword1 = type_keyword) then
		error:=$type_number(context, actor_ptr, actor_name, number)
	else
	  begin
		error:=true;
		$message(zk$text_dont_understand)
	  end;

	dispatch_number:=error;
end;

function dispatch_single_string(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var keyword1, keyword2 : $symbol_token;
	var string : varying[$u2] of char) : boolean;
var	error : boolean;
begin
	error:=false;
	case (keyword1) of
	say_keyword:
		error:=$say_string(context, string);
	save_keyword:
		error:=$save_game(context, string);
	restore_keyword:
		error:=$restore_game(context, string);
	look_keyword:
		error:=$lookup_string(context, actor_ptr, actor_name, string)
	otherwise
	  begin
		error:=true;
		$message(zk$text_dont_understand);
	  end;
	end;

	dispatch_single_string:=error;
end;

function dispatch_single_object(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var keyword1, keyword2 : $symbol_token;
	object_ptr : $object_ptr;
	var description : unsigned;
	var name1 : varying[$u2] of char;
	var list : boolean) : boolean;

var	error : boolean;
	direction : integer;
	detail : unsigned;
	room_name : varying[31] of char;
begin
	case (keyword1) of
	drink_keyword:
		error:=$drink_object(context, actor_ptr, actor_name,
					object_ptr, name1);
	boot_keyword:
		error:=$boot_object(context, actor_ptr, actor_name,
					object_ptr, name1);
	shake_keyword:
		error:=$shake_object(context, actor_ptr, actor_name,
					object_ptr, name1);
	stand_keyword:
		error:=$stand_object(context, actor_ptr, actor_name,
					object_ptr, name1,
					(keyword2=on_keyword));
	examine_keyword:
		error:=$examine_object(context,
					actor_ptr, actor_name,
					object_ptr, name1, 
					list, description);
	inventory_keyword:
		error:=$inventory_object(context, object_ptr, name1);
	look_keyword:
		if (keyword2=at_keyword) then
			error:=$examine_object(context,
						actor_ptr, actor_name,
						object_ptr, name1,
						list, description)
		else
			error:=$look_in_object(context, object_ptr, name1);
	drop_keyword:
	  begin
		$get_object_info(zk$obj_table, zk$obj_current_room,
					detail, room_name);
		error:=$put_object(context, actor_ptr, actor_name,
				object_ptr, name1,
				context.room[context.location].room, room_name,
				true, zk$text_dropped_text);
		if (not error) then
			object_ptr^.flags.shaken:=true;
	  end;
	take_keyword, pick_keyword:
		error:=$put_object(context, actor_ptr, actor_name,
				object_ptr, name1,
				actor_ptr, actor_name,
				true, zk$text_taken_text);
	read_keyword:
		error:=$read_object(context,
					actor_ptr, actor_name,
					object_ptr, name1, description);
	shut_keyword:
		if (keyword2=nil_keyword) then
			error:=$close_object(context,
					actor_ptr, actor_name,
					object_ptr, name1,
					actor_ptr, actor_name)
		else
		if (keyword2=off_keyword) then
			error:=$start_stop_object(context,
						actor_ptr, actor_name,
						object_ptr, name1,
						actor_ptr, actor_name, false);
	turn_keyword:
		if (keyword2=nil_keyword) then
			error:=$move_object(context,
				actor_ptr, actor_name, object_ptr, name1)
		else	error:=$start_stop_object(context,
				actor_ptr, actor_name, object_ptr, name1,
				actor_ptr, actor_name, (keyword2=on_keyword));
	open_keyword:
		error:=$open_object(context,
					actor_ptr, actor_name,
					object_ptr, name1,
					actor_ptr, actor_name);
	close_keyword:
		error:=$close_object(context,
					actor_ptr, actor_name,
					object_ptr, name1,
					actor_ptr, actor_name);
	lock_keyword:
	  begin
		if (actor_ptr^.number=zk$obj_self) then
			$message(zk$text_using_hands);
		error:=$lock_unlock_object(context,
					actor_ptr, actor_name,
					object_ptr, name1,
					actor_ptr, actor_name, true);
	  end;
	unlock_keyword:
	  begin
		if (actor_ptr^.number=zk$obj_self) then
			$message(zk$text_using_hands);
		error:=$lock_unlock_object(context,
					actor_ptr, actor_name,
					object_ptr, name1,
					actor_ptr, actor_name, false);
	  end;
	heal_keyword:
		error:=$heal_kill_object(context,
					actor_ptr, actor_name,
					object_ptr, name1,
					actor_ptr, actor_name, true);
	kill_keyword:
	  begin
		if (actor_ptr^.number=zk$obj_self) then
			$message(zk$text_using_hands);
		error:=$heal_kill_object(context,
					actor_ptr, actor_name,
					object_ptr, name1,
					actor_ptr, actor_name, false);
	  end;
	wear_keyword, put_keyword:
	  begin
		if (keyword2=down_keyword) then
		  begin
			$get_object_info(zk$obj_table, zk$obj_current_room,
					detail, room_name);
			error:=$put_object(context, actor_ptr, actor_name,
				object_ptr, name1,
				context.room[context.location].room, room_name,
				true, zk$text_dropped_text);
		  end
		else	error:=$put_object(context, actor_ptr, actor_name,
					object_ptr, name1,
					actor_ptr, actor_name,
					false, zk$text_done_text);
	  end;
	start_keyword, light_keyword:
		error:=$start_stop_object(context,
					actor_ptr, actor_name,
					object_ptr, name1,
					actor_ptr, actor_name, true);
	stop_keyword:
		error:=$start_stop_object(context,
					actor_ptr, actor_name,
					object_ptr, name1,
					actor_ptr, actor_name, false);
	rub_keyword:
	  begin
		if (actor_ptr^.number=zk$obj_self) then
			$message(zk$text_using_hands);
		error:=$rub_object(context,
					actor_ptr, actor_name,
					object_ptr, name1,
					actor_ptr, actor_name);
	  end;
	play_keyword:
		error:=$rub_object(context,
					actor_ptr, actor_name,
					object_ptr, name1,
					actor_ptr, actor_name);
	move_keyword:
	  begin
		if (keyword2=nil_keyword) then
		  begin
			error:=$move_object(context,
					actor_ptr, actor_name,
					object_ptr, name1);
		  end
		else
		if (list) then
		  begin
			error:=true;
			$message(zk$text_no_multiple);
		  end
		else
		  begin
			direction:=ord(keyword2) - ord(north_keyword) + 1;
			error:=$move_direction(context,
					actor_ptr, actor_name,
					direction,
					object_ptr, name1);
		  end;
	  end;
	otherwise
	  begin
		error:=true;
		$message(zk$text_dont_understand);
	  end;
	end;
	dispatch_single_object:=error;
end;

function semantics_single_object(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var keyword1, keyword2 : $symbol_token;
	object, from : integer) : boolean;

var	list, error : boolean;
	from_ptr, object_ptr, next_ptr : $object_ptr;
	detail : unsigned;
	name : varying[31] of char;
begin
	if (from=0) then
	  begin
		from_ptr:=nil;
		if ( (object=zk$obj_all) and (keyword1=drop_keyword) ) then
		  begin
			$message(zk$text_contents_self);
			from_ptr:=context.self;
		  end;
		error:=$lookup_object(object,from_ptr,context,object_ptr,list)
	  end
	else
	  begin
		error:=$test_retreival(context, from, from_ptr);
		if (not error) then
			error:=$lookup_object(object, from_ptr,
				context, object_ptr, list);
	  end;

	next_ptr:=nil;
	while ( (not error) and (object_ptr<>nil) ) do
	  begin
		if (list) then next_ptr:=object_ptr^.next;

		$get_object_info(zk$obj_table, object_ptr^.number,
				detail, name);

		error:=$probe_ownership(context, actor_ptr, actor_name,
				object_ptr, name);
		if (not error) then
			error:=dispatch_single_object(context,
				actor_ptr, actor_name,
				keyword1, keyword2,
				object_ptr, detail, name, list);

		object_ptr:=next_ptr;
		if ( (object_ptr<>nil) and
			( (keyword1=read_keyword) or
			  (keyword1=examine_keyword) ) ) then
				$message(0);
	  end;

	semantics_single_object:=error;
end;

function syntax_single_object(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var keyword1, keyword2 : $symbol_token;
	object : $ast_node_ptr) : boolean;

var	error : boolean;
	direction : integer;
begin
	error:=false;
	while ( (object<>nil) and (not error) ) do
	  begin
		if (object^.node_type=string_node) then
			error:=dispatch_single_string(context,
					actor_ptr, actor_name,
					keyword1, keyword2, object^.string)
		else	error:=semantics_single_object(context,
				actor_ptr, actor_name,
				keyword1, keyword2,
				object^.object_code, object^.from);
		if (not error) then
		  begin
			object:=object^.list;
			if (object<>nil) then $message(0);
		  end;
	  end;
	syntax_single_object:=error;
end;

function dispatch_double_object(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var keyword1, keyword2 : $symbol_token;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char) : boolean;

var	error : boolean;
	direction : integer;
begin
	case (keyword1) of
	put_keyword:
		error:=$put_object(context,
					actor_ptr, actor_name,
					object1_ptr, name1,
					object2_ptr, name2,
					(keyword2=in_keyword),
					zk$text_done_text);
	give_keyword:
		error:=$give_object(context,
					actor_ptr, actor_name,
					object1_ptr, name1,
					object2_ptr, name2);
	open_keyword:
		error:=$open_object(context,
					actor_ptr, actor_name,
					object1_ptr, name1,
					object2_ptr, name2);
	close_keyword:
		error:=$close_object(context,
					actor_ptr, actor_name,
					object1_ptr, name1,
					object2_ptr, name2);
	lock_keyword:
		error:=$lock_unlock_object(context,
					actor_ptr, actor_name,
					object1_ptr, name1,
					object2_ptr, name2, true);
	unlock_keyword:
		error:=$lock_unlock_object(context,
					actor_ptr, actor_name,
					object1_ptr, name1,
					object2_ptr, name2, false);
	heal_keyword:
		error:=$heal_kill_object(context,
					actor_ptr, actor_name,
					object1_ptr, name1,
					object2_ptr, name2, true);
	kill_keyword:
		error:=$heal_kill_object(context,
					actor_ptr, actor_name,
					object1_ptr, name1,
					object2_ptr, name2, false);
	start_keyword, light_keyword:
		error:=$start_stop_object(context,
					actor_ptr, actor_name,
					object1_ptr, name1,
					object2_ptr, name2, true);
	stop_keyword:
		error:=$start_stop_object(context,
					actor_ptr, actor_name,
					object1_ptr, name1,
					object2_ptr, name2, false);
	rub_keyword:
		error:=$rub_object(context,
					actor_ptr, actor_name,
					object1_ptr, name1,
					object2_ptr, name2);
	otherwise
	  begin
		error:=true;
		$message(zk$text_dont_understand);
	  end
	end;
	dispatch_double_object:=error;
end;

function semantics_double_object(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var keyword1, keyword2 : $symbol_token;
	object1, from1, object2, from2 : integer) : boolean;

var	list1, list2, error : boolean;
	from_ptr, object1_ptr, object2_ptr,
	next1_ptr, next2_ptr : $object_ptr;
	detail : unsigned;
	name1, name2 : varying[31] of char;
begin
	if (from2=0) then
		error:=$lookup_object(object2, nil, context,
				object2_ptr, list2)
	else
	  begin
		error:=$test_retreival(context, from2, from_ptr);
		if (not error) then
			error:=$lookup_object(object2, from_ptr,
					context, object2_ptr, list2);
	  end;

	next2_ptr:=nil;
	while ( (not error) and (object2_ptr<>nil) ) do
	  begin
		if (list2) then next2_ptr:=object2_ptr^.next;

		$get_object_info(zk$obj_table, object2_ptr^.number,
					detail, name2);

		if (from1=0) then
		  begin
			from_ptr:=nil;
			if ( (object1=zk$obj_all) and
				(keyword1 in [put_keyword, give_keyword]) ) then
			  begin
				$message(zk$text_contents_self);
				from_ptr:=context.self;
			  end;
			error:=$lookup_object(object1, from_ptr, context,
				object1_ptr, list1)
		  end
		else
		  begin
			error:=$test_retreival(context, from1, from_ptr);
			if (not error) then
				error:=$lookup_object(object1,
						from_ptr, context,
						object1_ptr, list1);
		  end;

		next1_ptr:=nil;
		while ( (not error) and (object1_ptr<>nil) ) do
		  begin
			if (list1) then next1_ptr:=object1_ptr^.next;

			$get_object_info(zk$obj_table, object1_ptr^.number,
					detail, name1);

			error:=$probe_ownership(context,
					actor_ptr, actor_name,
					object1_ptr, name1);
			if (not error) then
			  begin
				error:=$probe_ownership(context,
						actor_ptr, actor_name,
						object2_ptr, name2);
				if (not error) then
					error:=dispatch_double_object(context,
						actor_ptr, actor_name,
						keyword1, keyword2,
						object1_ptr, name1,
						object2_ptr, name2);
			  end;

			object1_ptr:=next1_ptr;
		  end;

		object2_ptr:=next2_ptr;
	  end;

	semantics_double_object:=error;
end;

function syntax_double_object(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var keyword1, keyword2 : $symbol_token;
	object1, object2 : $ast_node_ptr) : boolean;

var	error : boolean;
begin
	error:=false;
	while ( (object2<>nil) and (not error) ) do
	  begin
		error:=false;
		while ( (object1<>nil) and (not error) ) do
		  begin
			error:=semantics_double_object(context,
				actor_ptr, actor_name,
				keyword1, keyword2,
				object1^.object_code, object1^.from,
				object2^.object_code, object2^.from);
			if (not error) then
			  begin
				object1:=object1^.list;
				if (object1<>nil) then $message(0);
			  end;
		  end;

		if (not error) then
		  begin
			object2:=object2^.list;
			if (object2<>nil) then $message(0);
		  end;
	  end;
	syntax_double_object:=error;
end;

function dispatch_no_object(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var keyword1, keyword2 : $symbol_token;
	var right : $ast_node_ptr) : boolean;

var	error : boolean;
	direction : integer;
	name : varying[31] of char;
begin
	error:=false;
	case (keyword1) of
	restart_keyword:
		error:=$restart_game(context);
	wait_keyword:
		error:=$wait(context, actor_ptr, actor_name);
	install_keyword:
		error:=$install_object(context, actor_ptr, actor_name);
	exit_keyword, quit_keyword:
		error:=$quit(context, actor_ptr, actor_name);
	where_keyword, locate_keyword:
		error:=$locate_object(context,
					actor_ptr, actor_name,
					right^.object_code);
	move_keyword, go_keyword:
	  begin
		direction:=ord(keyword2) - ord(north_keyword) + 1;
		name:='';
		error:=$move_direction(context,
				actor_ptr, actor_name,
				direction, nil, name);
	  end;
	enter_keyword:
	  begin
		name:='';
		error:=$move_direction(context,
					actor_ptr, actor_name,
					11, nil, name);
	  end;
	look_keyword:
		$describe_room(context, context.location, false, false);

	inventory_keyword:
	  begin
		$inventory_object(context, actor_ptr, actor_name);
	  end;
	hello_keyword:
		error:=$hello(context, actor_ptr, actor_name);

	plugh_keyword:		$message(zk$text_plugh);
	xyzzy_keyword:		$message(zk$text_nothing_happens);
	pray_keyword:		$message(zk$text_pray);
	scream_keyword:		$message(zk$text_scream);
	jump_keyword:		$message(zk$text_having_fun);
	version_keyword:	$version;
	score_keyword:		$score(context);
	brief_keyword:
	  begin
		context.flags.brief:=true; $message(zk$text_done);
	  end;
	verbose_keyword:
	  begin
		context.flags.brief:=false; $message(zk$text_done);
	  end;
	otherwise
	  begin
		error:=true; $message(zk$text_dont_understand);
	  end;
	end;
	dispatch_no_object:=error;
end;

function syntax_object_command(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	keyword1, keyword2 : $symbol_token;
	object, command : $ast_node_ptr) : boolean;

var	list, error : boolean;
	message, detail : unsigned;
	new_actor_ptr : $object_ptr;
	new_actor_name : varying[31] of char;
begin
	error:=$lookup_object(object^.object_code, nil, context,
			new_actor_ptr, list);
	if (not error) then
	  begin
		$get_object_info(zk$obj_table, new_actor_ptr^.number,
					detail, new_actor_name);
		if (list) then
		  begin
			error:=true;
			$message(zk$text_no_multiple);
		  end
		else
		if (not new_actor_ptr^.flags.cognizant) then
		  begin
			error:=true;
			if (new_actor_name[new_actor_name.length]='s') then
				message:=zk$text_doesnt_talk_some
			else
			if (new_actor_name[1] in vowels) then
				message:=zk$text_doesnt_talk_an
			else	message:=zk$text_doesnt_talk_a;
			$message(message, 2,
				new_actor_name.length,
				iaddress(new_actor_name.body));
		  end
		else
		if ( (object^.object_code=zk$obj_guard) and
			(not command^.please) ) then
		  begin
			error:=true;
			$message(zk$text_say_please, 2,
					new_actor_name.length,
					iaddress(new_actor_name.body));
		  end
		else	error:=zk$dispatch_command(context,
				new_actor_ptr, new_actor_name, command);
	  end;

	syntax_object_command:=error;
end;

function dispatch_edswbl(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var keyword2 : $symbol_token;
	var left, right : $ast_node_ptr) : boolean;
var	error : boolean;
begin
	error:=false;
	case (keyword2) of
	go_keyword:
		error:=$edswbl_goto_room(context, left^.number);
	take_keyword:
		error:=$edswbl_take_object(context, left^.object_code);
	wait_keyword:
		error:=$edswbl_wait(context);
	keypad_keyword:
		error:=$edswbl_keypad(context);
	where_keyword:
		error:=$edswbl_where(context);
	nurse_keyword:
		error:=$edswbl_nurse(context);
	system_keyword:
		error:=$edswbl_system(context);
	otherwise
	  begin
		error:=true;
		$message(zk$text_dont_understand);
	  end;
	end;

	dispatch_edswbl:=error;
end;

function syntax_command(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var ast : $ast_node_ptr) : boolean;
var	error : boolean;
begin
	if (ast^.keyword1=tell_keyword) then
		error:=syntax_object_command(context, actor_ptr, actor_name,
			ast^.keyword1, ast^.keyword2, ast^.left, ast^.right)
	else
	if (ast^.keyword1=edswbl_keyword) then
		error:=dispatch_edswbl(context,	actor_ptr, actor_name,
			ast^.keyword2, ast^.left, ast^.right)
	else
	if (ast^.left=nil) then
		error:=dispatch_no_object(context, actor_ptr, actor_name,
			ast^.keyword1, ast^.keyword2, ast^.right)
	else
	if (ast^.left^.node_type=number_node) then
		error:=dispatch_number(context,	actor_ptr, actor_name,
				ast^.keyword1, ast^.keyword2, ast^.left^.number)
	else
	if (ast^.right<>nil) then
		error:=syntax_double_object(context, actor_ptr, actor_name,
				ast^.keyword1, ast^.keyword2,
				ast^.left, ast^.right)
	else	error:=syntax_single_object(context, actor_ptr, actor_name,
				ast^.keyword1, ast^.keyword2, ast^.left);
	syntax_command:=error;
end;


function zk$dispatch_command; (* forward *)

var	list, error : boolean;
	detail : unsigned;
	object_ptr : $object_ptr;
	name : varying[31] of char;
begin
	error:=false;
	if ($room_dark(context) and (not (ast^.keyword1 in dark_commands))) then
	  begin
		$message(zk$text_dark_cant_see);
		error:=true;
	  end;

	while ( (ast<>nil) and (not error) ) do
	  begin
		case (ast^.node_type) of
		command_node:
		  begin
			error:=syntax_command(context,
					actor_ptr, actor_name, ast);
			if (not error) then $advance_clock(context);
		  end;
		object_node:
		  begin
			error:=$lookup_object(ast^.object_code, nil,
						context, object_ptr, list);
			if (not error) then
			  begin
				$get_object_info(zk$obj_table,
					object_ptr^.number, detail, name);
				$message(zk$text_want_to_do, 2,
					name.length, iaddress(name.body));
				error:=true;
			  end;
		  end;
		otherwise
		  begin
			$message(zk$text_dont_understand);
			error:=true;
		  end;
		end;
		if (not error) then
		  begin
			ast:=ast^.list;
			if (ast<>nil) then $message(0);
		  end;
	  end;

	zk$dispatch_command:=error;
end;

[global] procedure zk$print_ast(ast : $ast_node_ptr; i : integer);
var	from_name, name : varying[31] of char;
	message, detail, return : unsigned;
begin
	while (ast<>nil) do
	  begin
		case (ast^.node_type) of
		command_node:
		  begin
			if (ast^.keyword2=nil_keyword) then
			  begin
				if (ast^.please) then
					message:=zk$text_ast_please_keyword1
				else	message:=zk$text_ast_keyword1;
				$message_indent(i,message,1,ord(ast^.keyword1))
			  end
			else
			  begin
				if (ast^.please) then
					message:=zk$text_ast_please_keyword2
				else	message:=zk$text_ast_keyword2;
				$message_indent(i, message, 2,
					ord(ast^.keyword1), ord(ast^.keyword2));
			  end;
			zk$print_ast(ast^.left, i+4);
			zk$print_ast(ast^.right, i+4);
		  end;
		object_node:
		  begin
			$get_object_info(zk$obj_table,
					ast^.object_code, detail, name);
			if (ast^.from=0) then
				$message_indent(i, zk$text_ast_object, 2,
					name.length, iaddress(name.body))
			else
			  begin
				$get_object_info(zk$obj_table,
					ast^.from, detail, from_name);
				$message_indent(i, zk$text_ast_object_from, 4,
					name.length, iaddress(name.body),
						from_name.length,
						iaddress(from_name.body));
			  end;
		  end;
		string_node:
		  begin
			$message_indent(i, zk$text_ast_string, 2,
				ast^.string.length,
				iaddress(ast^.string.body));
		  end;
		number_node:
		  begin
			$message_indent(i, zk$text_ast_number, 1,
				ast^.number);
		  end;
		end;
		ast:=ast^.list;
	  end;
end;

[global] procedure zk$dispose_ast(ast : $ast_node_ptr);
var	next_ast : $ast_node_ptr;
begin
	while (ast<>nil) do
	  begin
		case (ast^.node_type) of
		command_node:
		  begin
			zk$dispose_ast(ast^.left);
			zk$dispose_ast(ast^.right);
			next_ast:=ast^.list; dispose(ast, command_node);
		  end;
		object_node:
		  begin
			next_ast:=ast^.list; dispose(ast, object_node);
		  end;
		string_node:
		  begin
			next_ast:=ast^.list; dispose(ast, string_node);
		  end;
		number_node:
		  begin
			next_ast:=ast^.list; dispose(ast, number_node);
		  end;
		end;
		ast:=next_ast;
	  end;
end;

end.
