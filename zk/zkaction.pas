[inherit('lib$:typedef',
	 'lib$:rtldef',
	 'lib$:sysdef',
	 'lib$:zk$context_def',
	 'lib$:zk$routines_def', 'lib$:zk$object_def',
	 'lib$:zk$room', 'lib$:zk$text', 'lib$:zk$obj', 'lib$:zk$desc',
	 'ifc$library:ifc$rtl_def')]
module zk$action;

const	vowels = ['A','E','I','O','U','a','e','i','o','u'];
	max_score = 175;
	number_ranks = 7;
	number_to_answer = 6;
	max_questions = 12;
	max_exit_messages = 6;

type	$char_bits = [byte, unsafe]
			record
				case integer of
				1: (character : char);
				2: (bit : packed array[1..8] of boolean);
				3: (byte : $ubyte);
			end;

var	zk$k_baselevel,
	zk$t_version,
	zk$k_link_time_l0,
	zk$k_link_time_l1 : [external, value] unsigned;

	rank_name : array[0..number_ranks] of varying[31] of char :=
		('Diagnostic Programming Aide',
		 'Software Engineer I',
		 'Software Engineer II',
		 'Senior Software Engineer',
		 'Principal Software Engineer',
		 'Consulting Engineer',
		 'Hacker',
		 'ZK Grand Master');

	exit_message : array[1..max_exit_messages] of varying[15] of char :=
		('Goodbye.', 'See you later.', 'Take it easy.',
		 'Hang in there.', 'So long.', 'Bye.');

[global] function zk$wait(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char) : boolean;

var	error, not_found : boolean;
	system_object : integer;
	system_ptr : $object_ptr;
begin
	error:=false;
	$message(zk$text_time_passes);
	case (context.location) of
	zk$room_dcu:	$message(zk$text_line_not_moving);
	zk$room_pad:
	  begin
		system_object:=zk$obj_system_disk;
		not_found:=$lookup_object_inside(system_object,
				context.self, system_ptr);
		if ( (not not_found) and
			(context.flags.vms_installed) and
			(context.flags.cdd_installed) and
			(context.flags.dtr_installed) ) then
		  begin
			error:=true;
			context.flags.won:=true;
			$message(zk$text_won);
		  end;
	  end;
	otherwise	;
	end;

	zk$wait:=error;
end;

[global] procedure zk$score(var context : $context_block);
var	r : integer;
begin
	r:=context.score div (max_score div number_ranks);
	$message(zk$text_score, 5,
		context.score, max_score, context.moves,
		rank_name[r].length, iaddress(rank_name[r].body));
end;

[global] function zk$version : boolean;
var	version : unsigned;
	link_time : $uquad;
begin
	link_time.l0:=zk$k_link_time_l0;
	link_time.l1:=zk$k_link_time_l1;
	version:=zk$t_version;
	$message(zk$text_version, 4,
			4, iaddress(version),
			zk$k_baselevel, iaddress(link_time));
	zk$version:=false;
end;

[global] function zk$type_number(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var number : integer) : boolean;

var	list, error : boolean;
	object_safe : integer;
	safe_ptr : $object_ptr;
begin
	object_safe:=zk$obj_safe;
	error:=$lookup_object(object_safe, nil, context, safe_ptr, list);
	if (not error) then
	  begin
		if (number<>context.combination) then
			$message(zk$text_nothing_happens)
		else
		if (safe_ptr^.flags.locked) then
		  begin
			safe_ptr^.flags.locked:=false;
			$message(zk$text_click_safe);
			context.score:=context.score + 10;
		  end
		else	$message(zk$text_nothing_happens);
	  end;

	zk$type_number:=false;
end;

[global] function zk$quit(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char) : boolean;
var	error : boolean;
	answer : varying[10] of char;
begin
	error:=false;
	$get_string(answer, 'Do you really want to quit now? ');
	if (answer.length>0) then
	  begin
		if ( (answer[1]='y') or (answer[1]='Y') ) then
		  begin
			context.flags.quit:=true;
			error:=true;
		  end;
	  end;
	zk$quit:=error;
end;

[global] function zk$hello(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char) : boolean;
begin
	if (actor_ptr^.number=zk$obj_self) then
		$message(zk$text_collapse)
	else
		$message(zk$text_hello_object, 2,
			actor_name.length, iaddress(actor_name.body));

	zk$hello:=false;
end;

[global] function zk$describe_room(
	var context : $context_block;
	room : integer;
	seen_room : boolean;
	brief : boolean) : boolean;

var	safe_object, day_number, i : integer;
	description, description1 : unsigned;
	safe_ptr : $object_ptr;
	name : varying[31] of char;
	now, eight, five : $uquad;
	week_name : [static] array[1..7] of varying[9] of char :=
		('Monday', 'Tuesday', 'Wednesday', 'Thursday',
		 'Friday', 'Saturday', 'Sunday');
begin
	$get_room_info(zk$room_table, room, description, name);
	if (context.location = room) then
	  begin
		$update_status_room(name);
		if (context.flags.standing_on_doc) then
			$message(zk$text_standing_on_doc_paren);
	  end;
		
	if (seen_room or brief) then
		$message(zk$text_room_name, 2, name.length, iaddress(name.body))
	else
	case (room) of
	zk$room_pad:
	  begin
		if (context.flags.start) then
		  begin
			zk$version;
			$gettim(now);
			$day_of_week(now, day_number);
			if (day_number<6) then
			  begin
				$bintim('-- 8:00:00.00', eight);
				$bintim('-- 17:00:00.00', five);
				if ( ($compare_date(now,eight)=1) and
					($compare_date(now,five)=-1) ) then
					$message(0, 0, zk$text_prime_time);
			  end;
			$message(0, 0, zk$text_start, 2,
				week_name[day_number].length,
				iaddress(week_name[day_number].body), 0);
			context.flags.start:=false;
		  end;
		$message(zk$text_room_name, 2, name.length, iaddress(name.body),
			 description);
	  end;
	zk$room_dtr_dev:
	  begin
		if (context.flags.standing_on_doc) then
			description1:=zk$desc_dtr_dev_high
		else	description1:=zk$desc_dtr_dev_low;
		$message(zk$text_room_name, 2, name.length, iaddress(name.body),
			 description, 0,
			 description1);
	  end;
	zk$room_petty_cash:
	  begin
		safe_object:=zk$obj_safe;
		$lookup_object_list(safe_object,
			context.room[room].room, safe_ptr);
		if (safe_ptr^.flags.open) then
			description1:=zk$desc_petty_cash_ransacked
		else	description1:=zk$desc_petty_cash_stocked;
		$message(zk$text_room_name, 2, name.length, iaddress(name.body),
			 description, 0,
			 description1);
	  end;
	otherwise
		$message(zk$text_room_name, 2, name.length, iaddress(name.body),
			 description);
	end;

	$describe_room_contents(context.room[room].room);

	zk$describe_room:=false;
end;

procedure ask_question(var context : $context_block);
var	i : integer;
	message : unsigned;
begin
	repeat
		i:=$random_integer(context.seed, max_questions);
	until	(not context.question_asked[i]);

	context.current_question:=i;
	case (i) of
	1:		message:=zk$text_question_coin_machine;
	2:		message:=zk$text_question_dcu;
	3:		message:=zk$text_question_wall;
	4:		message:=zk$text_question_bill;
	5:		message:=zk$text_question_computers;
	6:		message:=zk$text_question_ambig;
	7:		message:=zk$text_question_enquirer;
	8:		message:=zk$text_question_devo;
	9:		message:=zk$text_question_corridor;
	10:		message:=zk$text_question_sword;
	11:		message:=zk$text_question_button;
	12:		message:=zk$text_question_hacker;
	otherwise	message:=zk$text_bugcheck;
	end;
	$message(0, 0, message);
end;

[global] function zk$say_string(
	var context : $context_block;
	var string : varying[$u1] of char) : boolean;

var	found : boolean;
	state : integer;
	p : $object_ptr;
	magic_word : [static] varying[26] of char :=
		'DIGITALSOFTWAREENGINEERING';
	answer : [static] packed array[1..max_questions] of
			varying[7] of char :=
		( 'DARK', 'NOTHING', 'BLACK', 'ED', '4', 'COMP', '1BIT',
		  'BUG', 'YELLOW', 'NOTHING', 'DIE', 'FIND');
		
begin
	if (context.location=zk$room_personnel) then
	  begin
		if (context.current_question<>0) then
		  begin
			if (index(string,
				answer[context.current_question])<>0) then
			  begin
				$message(zk$text_personnel_correct);
				context.questions_remaining:=
					context.questions_remaining-1;
				context.question_asked[
					context.current_question]:=true;
				if (context.questions_remaining>0) then
					ask_question(context)
				else
				  begin
					$message(zk$text_personnel_done);
					context.flags.interview:=true;
					context.score:=context.score + 25;
					context.current_question:=0;
				  end;
			  end
			else
			  begin
				$message(zk$text_personnel_incorrect);
				context.current_question:=0;
			  end;
		  end
		else	$message(zk$text_collapse);
	  end
	else
	if (context.location=zk$room_entrance) then
	  begin
		state:=$compare(string, magic_word);
		if (state<>0) then $message(zk$text_collapse)
		else
		  begin
			p:=context.room[zk$room_entrance].room^.contents;
			found:=false;
			while ((p<>nil) and (not found)) do
				if (p^.number=zk$obj_crystal_door) then
					found:=true
				else	p:=p^.next;
			if (p^.flags.locked) then
			  begin
				p^.flags.locked:=false;
				p^.link^.flags.locked:=false;
				$message(zk$text_click_door);
				context.score:=context.score + 25;
			  end
			else	$message(zk$text_nothing_happens);
		  end;
	  end
	else		$message(zk$text_collapse);

	zk$say_string:=false;
end;

[global] function zk$lookup_string(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var string : varying[$u2] of char) : boolean;

var	list, error : boolean;
	temp : $char_bits;
	object_ptr : $object_ptr;
	object, i, j : integer;
	binary : packed array[1..8] of char;
begin
	object:=zk$obj_ascii_table;
	error:=$lookup_object(object, actor_ptr, context,
				object_ptr, list);
	if (not error) then
	  begin
		if (string.length=0) then
			$message(zk$text_lookup_what)
		else
		  begin
			$message(zk$text_table_start);
			for i:=1 to string.length do
			  begin
				temp.character:=string[i];
				for j:=1 to 8 do
					if (temp.bit[j]) then
						binary[(9-j)]:='1'
					else	binary[(9-j)]:='0';
				$message(zk$text_table_entry, 5,
					1, iaddress(temp),
					8, iaddress(binary), temp.byte);
			  end;
			$message(zk$text_table_end);
		    end;
	  end;
	zk$lookup_string:=error;
end;

procedure entry_messages(var context : $context_block);
begin
	if (context.location=zk$room_lobby) then
	  begin
		if (not context.flags.physical) then
			$message(0, 0, zk$text_guard_see_nurse)
	  end
	else
	if (context.location=zk$room_health_services) then
	  begin
		if (not context.flags.physical) then
			$message(0, 0, zk$text_health_nurse_entry);
	  end
	else
	if (context.location=zk$room_personnel) then
	  begin
		if ( (context.flags.vms_installed) and
			(context.flags.cdd_installed) and
			(context.flags.dtr_installed) and
			(not context.flags.interview) ) then
		  begin
			$message(0,0,zk$text_personnel_entry);
			ask_question(context);
		  end;
	  end;
end;

procedure exit_messages(var context : $context_block);
var	desk_ptr, badge_ptr, p : $object_ptr;
	i, desk_object : integer;
	detail : unsigned;
	name : varying[31] of char;
begin
	if (context.location=zk$room_health_services) then
	  begin
		if ( (not context.flags.bp_taken) or
				(not context.flags.weight_taken) ) then
			$message(zk$text_health_not_done)
		else
		if (not context.flags.physical) then
		  begin
			$message(zk$text_health_nurse_exit);
			context.flags.physical:=true;
			context.score:=context.score + 25;

			desk_object:=zk$obj_reception_desk;
			$lookup_object_list(desk_object,
				context.room[zk$room_lobby].room, desk_ptr);
			badge_ptr:=$create_object(zk$obj_badge);
			$connect_object(badge_ptr, desk_ptr, false);
			$gettim(context.badge_issued);
		  end;
	  end
	else
	if (context.location=zk$room_personnel) then
	  begin
		if (context.current_question<>0) then
		  begin
			$message(zk$text_personnel_not_done);
			context.current_question:=0;
		  end;
	  end;

	p:=context.room[context.location].room^.contents;
	while (p<>nil) do
	  begin
		if (p^.flags.cognizant) then
		  begin
			$get_object_info(zk$obj_table, p^.number,
					detail, name);
			i:=$random_integer(context.seed, max_exit_messages);
			$message(zk$text_object_says, 4,
					name.length, iaddress(name.body),
					exit_message[i].length,
					iaddress(exit_message[i].body));
		  end;
		p:=p^.next;
	  end;
end;

function test_exit(
	var context : $context_block;
	var old_location : integer;
	var new_location : integer) : boolean;

var	not_found_system, not_found_keys, not_found_badge,
	not_found_guard, error : boolean;
	object : integer;
	guard_ptr, object_ptr : $object_ptr;
begin
	error:=false;

	if (old_location=zk$room_lobby) then
	  begin
		if ( ( (new_location = zk$room_blue_hall_2) or
			(new_location = zk$room_non_descript_hall_2) ) and
				(not context.flags.physical) ) then
		  begin
			error:=true;
			$message(zk$text_guard_physical);
		  end
		else
		if (new_location = zk$room_anti_chamber) then
		  begin
			object:=zk$obj_system_disk;
			not_found_system:=$lookup_object_list(object,
					context.self, object_ptr);
			object:=zk$obj_guard;
			not_found_guard:=$lookup_object_list(object,
					context.room[zk$room_lobby].room,
					guard_ptr);
			object:=zk$obj_keys;
			not_found_keys:=$lookup_object_list(object,
					guard_ptr, object_ptr);
			object:=zk$obj_badge;
			not_found_badge:=$lookup_object_list(object,
					guard_ptr, object_ptr);
			if (not not_found_system) then
			  begin
				error:=true;
				$message(zk$text_guard_disk);
			  end
			else
			if ( (context.flags.vms_installed) and
				(context.flags.cdd_installed) and
				(context.flags.dtr_installed) and
				(not context.flags.interview) ) then
			  begin
				error:=true;
				$message(zk$text_guard_interview);
			  end
			else
			if (not_found_keys) then
			  begin
				error:=true;
				$message(zk$text_guard_keys);
			  end
			else
			if (not_found_badge and context.flags.physical) then
			  begin
				error:=true;
				$message(zk$text_guard_badge);
			  end;
		  end;
	  end;

	test_exit:=error;
end;

[global] function zk$move_direction(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	direction : integer;
	object_ptr : $object_ptr;
	object_name : varying[$u2] of char) : boolean;

var	is_dark, was_dark, error : boolean;
	door, new_location : integer;
	detail : unsigned;
	door_ptr : $object_ptr;
	door_name, name : varying[31] of char;
	link : packed array[1..14] of $ubyte;
begin
	error:=false;
	$get_room_info(zk$room_table, context.location, detail,
		name, link);

	if (actor_ptr^.number<>zk$obj_self) then
	  begin
		error:=true;
		$message(zk$text_cant_do_that, 2,
				actor_name.length, iaddress(actor_name.body));
	  end
	else
	if (context.flags.standing_on_doc) then
	  begin
		error:=true;
		$message(zk$text_stand_cant_go);
	  end
	else
	if (direction>12) then
	  begin
		error:=true; $message(zk$text_cant_go_back);
	  end
	else
	  begin
		door:=0;
		new_location:=link[direction];
		if (new_location=0) then
		  begin
			error:=true;
			if (direction<11) then 
				$message(zk$text_cant_go_that_way)
			else	$message(zk$text_which_way);
		  end
		else
		if (direction=11) then door:=link[13]
		else
		if (direction=12) then door:=link[14]
		else
		  begin
			if (new_location=link[11]) then door:=link[13]
			else
			if (new_location=link[12]) then door:=link[14];
		  end;
	  end;

	if ( (not error) and (door<>0) ) then
	  begin
		door_ptr:=context.room[context.location].room^.contents;
		error:=true;
		while ( (door_ptr<>nil) and (error) ) do
			if (door_ptr^.number=door) then error:=false
			else
				door_ptr:=door_ptr^.next;
		$get_object_info(zk$obj_table, door, detail, door_name);
		if (not door_ptr^.flags.open) then
		  begin
			$message(zk$text_closed_object, 2, door_name.length,
					iaddress(door_name.body));
			if (direction<11) then error:=true
			else
			  begin
				$message(zk$text_open_object, 2,
					door_name.length,
					iaddress(door_name.body));
				$get_object_info(zk$obj_table, zk$obj_self,
						detail, name);
				error:=$open_object(context,
						actor_ptr, actor_name,
						door_ptr, door_name,
						context.self, name);
			  end;
		  end;

		if (not error) then
		  begin
			$get_object_info(zk$obj_table, zk$obj_self,
						detail, name);
			error:=$test_insertion(context.self, name,
						door_ptr, door_name);
			if (object_ptr<>nil) then
				error:=$test_insertion(object_ptr, object_name,
						door_ptr, door_name);
		  end;
	  end;

	if ( (not error) and (object_ptr<>nil) ) then
	  begin
		error:=$test_disconnect(object_ptr,
			context.room[new_location].room, true);
		if (not error) then
			$connect_object(object_ptr,
				context.room[new_location].room, true);
	  end;

	if (not error) then
		error:=test_exit(context, context.location, new_location);

	if (not error) then
	  begin
		exit_messages(context);
		if (door<>0) then
		  begin
			$message(zk$text_door_closes, 2,
				door_name.length, iaddress(door_name.body));
			door_ptr^.flags.open:=false;
			if (door_ptr^.link<>nil) then
				door_ptr^.link^.flags.open:=false;
		  end;
		was_dark:=$room_dark(context);
		context.location:=new_location;
		context.self^.location:=new_location;
		is_dark:=$room_dark(context);
		if (was_dark) then
		  begin
			if (is_dark) then
			  begin
				$message(zk$text_died_wall);
				error:=true;
				context.flags.died:=true;
			  end
			else
			  begin
				$message(zk$text_dark_exit);
				zk$describe_room(context, new_location,
				context.room[new_location].seen,
				context.flags.brief);
				context.room[new_location].seen:=true;
				entry_messages(context);
			  end;
		  end
		else
		  begin
			if (is_dark) then
			  begin
				$message(zk$text_dark_enter);
				name:='(dark)';
				$update_status_room(name);
			  end
			else
			  begin
				zk$describe_room(context, new_location,
				context.room[new_location].seen,
				context.flags.brief);
				context.room[new_location].seen:=true;
				entry_messages(context);
			  end;
		  end;
	  end;

	zk$move_direction:=error;
end;

procedure shut_off(var context : $context_block; room : integer);
var	detail : unsigned;
	name : varying[31] of char;
begin
	if (context.room[room].class<>2) then
	  begin
		context.room[room].room^.flags.on:=false;
		$get_room_info(zk$room_table, room, detail, name);
(*		$message(zk$text_shut_off_room, 2,
				name.length, iaddress(name.body));*)
		if (context.location=room) then
		  begin
			$message(0,0,zk$text_shut_off);
			if ($room_dark(context)) then
				$message(zk$text_dark_enter);
		  end;
	  end;
end;

procedure move_cleaning_crew(var context : $context_block);
var	room, i, number_choices : integer;
	detail : unsigned;
	room_ptr, object_ptr : $object_ptr;
	choice : packed array[1..10] of integer;
	link : packed array[1..14] of $ubyte;
	name : varying[31] of char;
begin
	number_choices:=0;
	$get_room_info(zk$room_table,context.crew_location,detail,name,link);
	for i:=1 to 10 do
	  if (link[i]<>0) then
	    begin
		if ( (context.room[link[i]].class=1) and
			(link[i]<>context.crew_last_location) and
			(link[i]<>context.location) ) then
		  begin
			number_choices:=number_choices+1;
			choice[number_choices]:=link[i];
		  end;
	    end;
	context.crew_last_location:=context.crew_location;
	if (number_choices>0) then
	  begin
		context.crew_location:=
			choice[$random_integer(context.seed, number_choices)];
(*		$message(zk$text_crew_location, 1, context.crew_location); *)
		object_ptr:=context.room[context.crew_location].room^.contents;
		while (object_ptr<>nil) do
		  begin
			if (not object_ptr^.flags.static) then
			  begin
				$disconnect_object(object_ptr);
				room_ptr:=context.room[context.
						crew_last_location].room;
				$connect_object(object_ptr, room_ptr, true);
				$get_object_info(zk$obj_table,
					object_ptr^.number, detail, name);
				$message(zk$text_crew_moved, 2,
					name.length, iaddress(name.body));
			  end;
			object_ptr:=object_ptr^.next;
		  end;
	  end;
end;

[global] function zk$advance_clock(var context : $context_block) : boolean;
var	i, target_room : integer;
	detail : unsigned;
	name : varying[31] of char;
	link : packed array[1..14] of $ubyte;

var	found, inside, event : boolean;
	officer_object : integer;
	system_ptr, owner, blank_ptr, officer_ptr, p : $object_ptr;
begin
	event:=false;
	context.moves:=context.moves + 1;

	if (context.fs_remaining>0) then
	  begin
		context.fs_remaining:=context.fs_remaining - 1;
		if (context.fs_remaining=0) then
		  begin
			system_ptr:=$create_object(zk$obj_system_disk);
			$connect_object(system_ptr, context.self, true);
			if (context.location=zk$room_vms_lab_2) then
				$message(0, 0, zk$text_fs_returns_lab)
			else	$message(0, 0, zk$text_fs_returns);
		  end;
	  end;

	if (context.flags.lamp_on) then
	  begin
		context.lamp_remaining:=context.lamp_remaining - 1;
		if ( (context.lamp_remaining mod 20)=0 ) then
		  begin
			event:=true;
			owner:=context.lamp_ptr^.owner;
			while (owner^.owner<>nil) do owner:=owner^.owner;
			if (context.lamp_remaining=0) then
			  begin
				context.flags.lamp_on:=false;
				context.lamp_ptr^.flags.on:=false;
				if (owner^.location=context.location) then
				  begin
					$message(0, 0, zk$text_lamp_no_power);
					if (not (context.
						room[context.location].
						room^.flags.on) ) then
					$message(zk$text_dark_enter);
				  end;
			  end
			else
			if (owner^.location=context.location) then
				$message(0,0,zk$text_lamp_dimmer);
		  end;
	  end;

	if (context.card_remaining>0) then
	  begin
		context.card_remaining:=context.card_remaining - 1;
		if (context.card_remaining=0) then
		  begin
			event:=true;
			owner:=context.card_ptr^.owner;
			inside:=context.card_ptr^.flags.inside;
			$disconnect_object(context.card_ptr);
			$dispose_object(context.card_ptr);

			blank_ptr:=$create_object(zk$obj_sdc_card_blank);
			$connect_object(blank_ptr, owner, inside);
		  end;
	  end;

	if (context.moves = context.officer_leave_time) then
	  begin
		event:=true;
		if (context.room[context.location].class<>2) then
		  begin
			if (context.location<>zk$room_petty_cash) then
				$message(0,0,zk$text_officer_leaving)
			else
			  begin
				$message(0,0,zk$text_officer_removes);
				context.location:=zk$room_non_descript_hall_2;
				zk$describe_room(context, context.location,
						true, true);
			  end;
		  end;
	  end;

	if (context.moves = (context.officer_leave_time+5) ) then
	  begin
		event:=true;
		context.room[zk$room_petty_cash].room^.flags.on:=false;
		officer_object:=zk$obj_officer;
		$lookup_object_list(officer_object,
			context.room[zk$room_petty_cash].room,
			officer_ptr);
		$disconnect_object(officer_ptr);
		$dispose_object(officer_ptr);
		if ( (context.room[context.location].class=3) or
			(context.room[context.location].class=2) ) then
				$message(zk$text_officer_departing);
	  end;

	if ($random_integer(context.seed, 20)=1) then
	  begin
		event:=true;
		target_room:=$random_integer(context.seed, zk$room_max);
		shut_off(context, target_room);
		$get_room_info(zk$room_table, target_room,
				detail, name, link);
		for i:=1 to 10 do
			if (link[i]<>0) then shut_off(context, link[i]);
	  end;

	if ( (context.moves>30) and
		($random_integer(context.seed, 75)=33) ) then
	  begin
		if ( (context.room[context.location].class<>2) and
			(context.room[context.location].class<>5) ) then
		  begin
			event:=true;
			p:=context.self^.contents; found:=false;
			while ( (p<>nil) and (not found) ) do
				if (p^.number=zk$obj_badge) then found:=true
				else	p:=p^.next;
			if (found) then found:=not p^.flags.inside;
			if (not found) then
			  begin
				$message(0,0,zk$text_guard_removes);
				context.location:=zk$room_entrance;
				zk$describe_room(context, context.location,
					false, false);
			  end
			else	$message(0,0,zk$text_guard_passes_through);
		  end;
	  end;

	if (context.room[context.location].class=1) then
		move_cleaning_crew(context);

	zk$advance_clock:=event;
end;

[global] function zk$install_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char) : boolean;

var	list, error : boolean;
	computer_object : integer;
	computer_ptr : $object_ptr;
begin
	computer_object:=zk$obj_computer;
	error:=$lookup_object(computer_object,
			context.room[context.location].room, context,
			computer_ptr, list);

	if (not error) then
	  begin
		if (not context.flags.booted) then
		  begin
			error:=true;
			$message(zk$text_cant_install);
		  end
		else
		if (context.tape_drive_ptr^.contents=nil) then
		  begin
			error:=true;
			$message(zk$text_console_message);
			context.console_message:=5; (* console_tape *)
		  end
		else
		if (context.tape_drive_ptr^.flags.open) then
		  begin
			error:=true;
			$message(zk$text_console_message);
			context.console_message:=5; (* console_tape *)
		  end
		else
		if ( ( (context.flags.vms_installed) and
		(context.tape_drive_ptr^.contents^.number=zk$obj_vms_tape) ) or
			( (context.flags.cdd_installed) and
		(context.tape_drive_ptr^.contents^.number=zk$obj_cdd_tape) ) or
			( (context.flags.dtr_installed) and
		(context.tape_drive_ptr^.contents^.number=zk$obj_dtr_tape) ) )
		then
		  begin
			error:=true;
			$message(zk$text_console_message);
			context.console_message:=7; (* console_already *)
		  end
		else
		if ( ( (not context.flags.vms_installed) and
			( (context.tape_drive_ptr^.contents^.number=
				zk$obj_cdd_tape) or
			  (context.tape_drive_ptr^.contents^.number=
				zk$obj_dtr_tape) ) ) or
		     ( (not context.flags.cdd_installed) and
			(context.tape_drive_ptr^.contents^.number=
				zk$obj_dtr_tape) ) ) then
		  begin
			error:=true;
			$message(zk$text_console_message);
			context.console_message:=6; (* console_prereq *)
		  end
		else
		  begin
			$message(zk$text_console_message);
			context.console_message:=8; (* console_installed *)

			if (context.tape_drive_ptr^.contents^.number=
				zk$obj_vms_tape) then
					context.flags.vms_installed:=true
			else
			if (context.tape_drive_ptr^.contents^.number=
				zk$obj_cdd_tape) then
					context.flags.cdd_installed:=true
			else
			  begin
				context.flags.dtr_installed:=true;
				context.score:=context.score + 25;
			  end;
		  end;
	  end;

	zk$install_object:=error;
end;

end.
