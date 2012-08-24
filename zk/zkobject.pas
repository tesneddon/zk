[inherit('lib$:typedef',
	 'lib$:rtldef',
	 'lib$:sysdef',
	 'lib$:zk$routines_def', 'lib$:zk$action_def',
	 'lib$:zk$context_def',
	 'lib$:zk$room', 'lib$:zk$text', 'lib$:zk$obj',
	 'ifc$library:ifc$rtl_def')]
module zk$object;

const	vowels = ['A','E','I','O','U','a','e','i','o','u'];

[global] function zk$drink_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_ptr : $object_ptr;
	var name : varying[$u2] of char) : boolean;

var	coke_ptr, liquid_ptr : $object_ptr;
begin
	if ( (object_ptr^.number=zk$obj_coke) and
		(not object_ptr^.flags.open) ) then
			$message(zk$text_closed_object, 2,
				name.length, iaddress(name.body))
	else
	if ( (object_ptr^.number<>zk$obj_coke) and
		(object_ptr^.number<>zk$obj_liquid) ) then
			$message(zk$text_cant_drink, 2,
				name.length, iaddress(name.body))
	else
	  begin
		if (object_ptr^.number=zk$obj_coke) then
		  begin
			coke_ptr:=object_ptr; liquid_ptr:=coke_ptr^.contents;
		  end
		else
		  begin
			liquid_ptr:=object_ptr; coke_ptr:=liquid_ptr^.owner;
		  end;
		$disconnect_object(liquid_ptr); $dispose_object(liquid_ptr);
		$disconnect_object(coke_ptr); $dispose_object(coke_ptr);
		coke_ptr:=$create_object(zk$obj_empty_can);
		$connect_object(coke_ptr, context.self, true);
		$message(zk$text_coke_drinking);
	  end;
	
	zk$drink_object:=false;
end;

[global] function zk$shake_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_ptr : $object_ptr;
	var name : varying[$u2] of char) : boolean;
var	coke_ptr, liquid_ptr : $object_ptr;
begin
	if (object_ptr^.flags.cognizant) then
		$message(zk$text_keep_off, 2, name.length, iaddress(name.body))
	else
	if (object_ptr^.flags.static) then
		$message(zk$text_object_fixed, 2,
				name.length, iaddress(name.body))
	else
	if ( (object_ptr^.number=zk$obj_coke) and
		(object_ptr^.flags.open) ) then
	  begin
		coke_ptr:=object_ptr; liquid_ptr:=coke_ptr^.contents;
		$disconnect_object(liquid_ptr); $dispose_object(liquid_ptr);
		$disconnect_object(coke_ptr); $dispose_object(coke_ptr);
		coke_ptr:=$create_object(zk$obj_empty_can);
		$connect_object(coke_ptr, context.self, true);
		$message(zk$text_coke_shake_open);
	  end
	else
	  begin
		object_ptr^.flags.shaken:=true;
		$message(zk$text_object_shaken, 2,
				name.length, iaddress(name.body));
	  end;

	zk$shake_object:=false;
end;

[global] function zk$stand_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_ptr : $object_ptr;
	var name : varying[$u2] of char;
	on : boolean) : boolean;

var	plant_object : integer;
	plant_ptr : $object_ptr;
begin
	if (actor_ptr^.number<>zk$obj_self) then
		$message(zk$text_cant_do_that, 2,
			actor_name.length, iaddress(actor_name.body))
	else
	if (on) then
	  begin
		if (object_ptr^.number = zk$obj_scale) then
		  begin
			if (context.self^.contents<>nil) then
				$message(zk$text_health_drop)
			else
			  begin
				context.flags.weight_taken:=true;
				$message(zk$text_health_scale);
			  end
		  end
		else
		if (object_ptr^.number = zk$obj_doc) then
		  begin
			if (context.flags.standing_on_doc) then
				$message(zk$text_standing_already, 2,
					name.length,
					iaddress(name.body))
			else
			  begin
				if (context.location=zk$room_dtr_dev) then
				  begin
					plant_object:=zk$obj_plant;
					$lookup_object_list(plant_object,
					context.room[zk$room_dtr_dev].room,
						plant_ptr);
					plant_ptr^.flags.open:=true;
					if (not context.flags.awarded_dtr) then
					  begin
						context.score:=context.score+25;
						context.flags.awarded_dtr:=true;
					  end;
				  end;
				context.flags.standing_on_doc:=true;
				$message(zk$text_standing_on_doc);
			  end
		  end
		else	$message(zk$text_stand_failure, 2,
				name.length, iaddress(name.body));
	  end
	else
	  begin
		if (context.flags.standing_on_doc) then
		  begin
			if (context.location=zk$room_dtr_dev) then
			  begin
				plant_object:=zk$obj_plant;
				$lookup_object_list(plant_object,
				context.room[zk$room_dtr_dev].room,
						plant_ptr);
				plant_ptr^.flags.open:=false;
			  end;
			context.flags.standing_on_doc:=false;
			$message(zk$text_stand_get_off);
		  end
		else
			$message(zk$text_stand_not_standing, 2,
				name.length, iaddress(name.body));
	  end;
	zk$stand_object:=false;
end;

procedure transport_objects(
	var source_owner, dest_owner : $object_ptr);
var	s, n : $object_ptr;
begin
	s:=source_owner^.contents;
	while (s<>nil) do
	  begin
		n:=s^.next;
		if ( (not s^.flags.static) and (not s^.flags.cognizant) ) then
		  begin
			$disconnect_object(s);
			$connect_object(s, dest_owner, true);
		  end;
		s:=n;
	  end;
end;

procedure unlock_elevator_door(var context : $context_block; room : integer);
var	found : boolean;
	object_ptr : $object_ptr;
begin
	found:=false;
	object_ptr:=context.room[room].room^.contents;
	while ( (object_ptr<>nil) and (not found) ) do
		if (object_ptr^.number=zk$obj_elevator_door) then found:=true
		else
			object_ptr:=object_ptr^.next;
	if (found) then
	  begin
		object_ptr^.flags.locked:=false;
		object_ptr^.link^.flags.locked:=false;
	  end
	else
		$message(zk$text_bugcheck);
end;

[global] function zk$move_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_ptr : $object_ptr;
	var name : varying[$u2] of char) : boolean;

var	error : boolean;
begin
	error:=false;
	if ( ( (context.location=zk$room_elevator_blue) and
		(object_ptr^.number=zk$obj_blue_button) ) or
		( (context.location=zk$room_elevator_yellow) and
		(object_ptr^.number=zk$obj_yellow_button) ) or
		( (context.location=zk$room_elevator_red) and
		(object_ptr^.number=zk$obj_red_button) ) ) then
			$message(zk$text_nothing_happens)
	else
	if (object_ptr^.number=zk$obj_blue_button) then
	  begin
		transport_objects(
			context.room[context.location].room,
			context.room[zk$room_elevator_blue].room);
		context.location:=zk$room_elevator_blue;
		$message(zk$text_movement);
	  end
	else
	if (object_ptr^.number=zk$obj_yellow_button) then
	  begin
		transport_objects(
			context.room[context.location].room,
			context.room[zk$room_elevator_yellow].room);
		context.location:=zk$room_elevator_yellow;
		$message(zk$text_movement);
	  end
	else
	if (object_ptr^.number=zk$obj_red_button) then
	  begin
		transport_objects(
			context.room[context.location].room,
			context.room[zk$room_elevator_red].room);
		context.location:=zk$room_elevator_red;
		$message(zk$text_movement);
	  end
	else
	if (object_ptr^.number=zk$obj_orange_button) then
	  begin
		$message(zk$text_orange_button);
		error:=true;
		context.flags.died:=true;
	  end
	else
	if ( (object_ptr^.number=zk$obj_keys) and
		(object_ptr^.owner^.number=zk$obj_elevator_lock) ) then
	  begin
		if (context.flags.elevator_unlocked) then
			$message(zk$text_nothing_happens)
		else
		  begin
			$message(zk$text_click_elevator);
			context.flags.elevator_unlocked:=true;
			unlock_elevator_door(context,
				zk$room_non_descript_hall_1);
			unlock_elevator_door(context, zk$room_stub_yellow);
			unlock_elevator_door(context, zk$room_stub_red);
		  end;
	  end
	else
	if (object_ptr^.flags.static) then
		$message(zk$text_object_fixed, 2,
			name.length, iaddress(name.body))
	else
		$message(zk$text_nothing_interesting);

	zk$move_object:=error;
end;

procedure locate_stan(
	var context : $context_block;
	object_number : integer;
	var name : varying[$u1] of char);

var	error : boolean;
	r : integer;
	detail : unsigned;
	object_ptr : $object_ptr;
	room_name : varying[31] of char;
begin
	$message(zk$text_stan_non_static);
	r:=0; error:=true;
	while ( (error) and (r<zk$room_max)) do
	  begin
		r:=r+1;
		error:=$lookup_object_list(object_number,context.room[r].room,
						object_ptr);
	  end;
	if (error) then
		$message(zk$text_stan_not_found, 2,
				name.length, iaddress(name.body))
	else
	  begin
		$get_room_info(zk$room_table, r, detail, room_name);
		$message(zk$text_stan_found, 4,
				name.length, iaddress(name.body),
				room_name.length, iaddress(room_name.body));
	  end;
end;

[global] function zk$locate_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_number : integer) : boolean;

var	error : boolean;
	count : integer;
	detail, flags : unsigned;
	object_ptr : $object_ptr;
	room_name, name : varying[31] of char;
	info : packed array[1..16] of $ubyte;
begin
	error:=false;
	$get_object_info(zk$obj_table, object_number, detail, name,
				flags, count, info);

	if (uand(flags,1)<>0) then $message(zk$text_more_specific)
	else
	if ( (object_number=zk$obj_all) or
		(object_number=zk$obj_possessions) or
		(object_number=zk$obj_contents) ) then
			$message(zk$text_no_multiple)
	else
	  begin
		error:=$lookup_object_list(object_number, context.self,
				object_ptr);
		if (error) then
			error:=$lookup_object_list(object_number,
					context.room[context.location].room,
					object_ptr);

		if (actor_ptr^.number<>zk$obj_stan) then
		  begin
			if (error) then
				$message(zk$text_dont_know_where, 2,
					name.length, iaddress(name.body))
			else
				$message(zk$text_right_here, 2,
					name.length, iaddress(name.body));
		  end
		else
		  begin
			if (not error) then
				$message(zk$text_stan_right_here, 2,
					name.length, iaddress(name.body))
			else
			  begin
				if ( (uand(flags, 2)<>0) and (info[1]<>0) ) then
				  begin
					$get_room_info(zk$room_table,
						info[1], detail, room_name);
					$message(zk$text_stan_static, 4,
						name.length,
						iaddress(name.body),
						room_name.length,
						iaddress(room_name.body));
				  end
				else	locate_stan(context,
						object_number, name);
			  end;
		  end;
	  end;

	zk$locate_object:=false;
end;

(* Action routines which receive a single object *)

[global] function zk$open_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char) : boolean;

var	empty, error : boolean;
	message : unsigned;
	verb : packed array[1..4] of char;
begin
	error:=false;

	if (not object1_ptr^.flags.openable) then
	  begin
		error:=true; verb:='open';
		if (name1[name1.length]='s') then
			message:=zk$text_doesnt_verb_some
		else
		if (name1[1] in vowels) then
			message:=zk$text_doesnt_verb_an
		else	message:=zk$text_doesnt_verb_a;
		$message(message, 4, 4, iaddress(verb),
				name1.length, iaddress(name1.body));
	  end
	else
	if (object1_ptr^.flags.open) then
	  begin
		error:=true;
		$message(zk$text_already_open, 2,
				name1.length, iaddress(name1.body));
	  end
	else
	if (object1_ptr^.flags.locked) then
	  begin
		error:=true;
		$message(zk$text_locked_object, 2,
				name1.length, iaddress(name1.body));
	  end
	else
	if (object2_ptr^.number<>actor_ptr^.number) then
	  begin
		error:=true;
		$message(zk$text_cant_open, 2,
				name1.length, iaddress(name1.body));
	  end
	else
	if (object1_ptr^.number=zk$obj_petty_cash_door) then
	  begin
		if ( (context.moves>=context.officer_leave_time) and
			(context.moves<(context.officer_leave_time+5) ) ) then
		  begin
			error:=true;
			$message(zk$text_officer_busy);
		  end;
	  end
	else
	if (object1_ptr^.number=zk$obj_cabinet) then
	  begin
		context.flags.died:=true;
		error:=true;
		$message(zk$text_cabinet);
	  end;

	if (not error) then
	  begin
		object1_ptr^.flags.open:=true;
		if (object1_ptr^.link<>nil) then
			object1_ptr^.link^.flags.open:=true;
		empty:=$list_contents(object1_ptr, 1, true, true);
		if (empty) then
			$message(zk$text_opened_text, 2,
				name1.length, iaddress(name1.body));
	  end;

	zk$open_object:=error;
end;

[global] function zk$inventory_object(
	var context : $context_block;
	object_ptr : $object_ptr;
	var name : varying[$u1] of char) : boolean;

var	error : boolean;
	message : unsigned;
begin
	if ( (object_ptr^.flags.no_capacity) and
		(object_ptr^.flags.no_area) ) then
			$message(zk$text_no_capacity, 2,
				name.length, iaddress(name.body))
	else
	if (not object_ptr^.flags.open) then
	  begin
		$message(zk$text_closed_object, 2,
			name.length, iaddress(name.body));
		$list_contents(object_ptr, 1, false, true);
	  end
	else
	if (object_ptr^.contents=nil) then
	  begin
		if (object_ptr^.flags.cognizant) then
			message:=zk$text_nothing_carried
		else	message:=zk$text_not_contained_in;
		$message(message, 2, name.length, iaddress(name.body))
	  end
	else
	  begin
		$list_contents(object_ptr, 1, true, true);
		$list_contents(object_ptr, 1, false, true);
	  end;

	zk$inventory_object:=false;
end;

procedure look_in_ball(
	var context : $context_block;
	var other_ptr : $object_ptr;
	var name : varying[$u1] of char);

var	enclosed : boolean;
	c, p : $object_ptr;
begin
	c:=other_ptr; p:=other_ptr^.owner;
	enclosed:=false;
	while ( (p<>nil) and (not enclosed) ) do
	  begin
		enclosed:=(c^.flags.inside and (not p^.flags.open));
		c:=p; p:=p^.owner;
	  end;
	if (enclosed) then
		$message(zk$text_ball_dark,2,name.length,iaddress(name.body))
	else
	  begin
		$message(zk$text_looking_in, 2,
			name.length, iaddress(name.body));
		$describe_room(context, c^.location, false, false);

		if ( (c^.location=zk$room_petty_cash) and
			(context.moves>=context.officer_leave_time) and
			(context.moves<(context.officer_leave_time+5) ) ) then
		  begin
			if (context.moves = context.officer_leave_time+4) then
				$message(zk$text_officer_safe, 1,
						context.combination)
			else	$message(zk$text_officer_preparing);
		  end
	  end;
end;

[global] function zk$look_in_object(
	var context : $context_block;
	object_ptr : $object_ptr;
	var name : varying[$u1] of char) : boolean;

var	error : boolean;
	other_ptr : $object_ptr;
begin
	error:=false;
	if ( (object_ptr^.number=zk$obj_neon_ball) or
		(object_ptr^.number=zk$obj_fluorescent_ball) ) then
	  begin
		if (not object_ptr^.flags.on) then
			$message(zk$text_ball_dark, 2,
				name.length, iaddress(name.body))
		else
		  begin
			other_ptr:=object_ptr^.link;
			if (not other_ptr^.flags.on) then
				$message(zk$text_ball_dark, 2,
					name.length,
					iaddress(name.body))
			else
				look_in_ball(context, other_ptr, name);
		  end;
	  end
	else
	if (object_ptr^.number=zk$obj_mirror) then
		$message(zk$text_mirror_reflection)
	else
		error:=zk$inventory_object(context, object_ptr, name);
	zk$look_in_object:=error;
end;

function get_console_message(var message_number : integer) : unsigned;
begin
	case (message_number) of
	1 :	get_console_message:=zk$text_console_initial;
	2 :	get_console_message:=zk$text_console_disk;
	3 :	get_console_message:=zk$text_console_boot_failure;
	4 :	get_console_message:=zk$text_console_booted;
	5 :	get_console_message:=zk$text_console_tape;
	6 :	get_console_message:=zk$text_console_prereq;
	7 :	get_console_message:=zk$text_console_already;
	8 :	get_console_message:=zk$text_console_installed;
	otherwise
		get_console_message:=zk$text_bugcheck;
	end;
end;

procedure console_message(
	var context : $context_block;
	var name : varying[$u1] of char);

var	message : unsigned;
	fs_ptr : $object_ptr;
begin
	message:=get_console_message(context.console_message);
	$message(zk$text_object_reads, 2,
			name.length, iaddress(name.body),
			0, 0, message);

	if ( (context.console_message=3) and
		(not context.flags.field_service) ) then
	  begin
		$message(0, 0, zk$text_fs_arrives);
		fs_ptr:=$create_object(zk$obj_field_service_rep);
		$connect_object(fs_ptr,
			context.room[context.location].room, true);
		context.flags.field_service:=true;
	  end;
end;

[global] function zk$examine_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_ptr : $object_ptr;
	var name : varying[$u2] of char;
	var list : boolean;
	var detail : unsigned) : boolean;

var	done, error : boolean;
	message, dummy : unsigned;
	child_name, parent_name : varying[31] of char;
begin
	if (object_ptr^.number=zk$obj_badge) then
		$message(zk$text_badge_start, 0,
			 zk$text_badge_middle, 3,
				12, iaddress(context.username),
				iaddress(context.badge_issued),
			 zk$text_badge_end)
	else
	if (object_ptr^.number=zk$obj_console) then
		console_message(context, name)
	else
	if (detail=0) then
		$message(zk$text_nothing_special, 2,
			name.length, iaddress(name.body))
	else
	if (not object_ptr^.flags.readable) then
	  begin
		if (list) then
			$message(zk$text_examining_reveals, 2, 
				name.length, iaddress(name.body),
				0, 0, detail)
		else	$message(detail);
	  end
	else
		$message(zk$text_object_reads, 2, 
			name.length, iaddress(name.body),
			0, 0, detail);

	$list_contents_empty(object_ptr, 1);

	if ( (object_ptr^.flags.openable) and
		(object_ptr^.flags.open) ) then
			$message(zk$text_state_open, 2,
				name.length, iaddress(name.body));

	if (object_ptr^.flags.startable) then
	  begin
		if (object_ptr^.flags.on) then
			$message(zk$text_state_on, 2,
				name.length, iaddress(name.body))
		else	$message(zk$text_state_off, 2,
				name.length, iaddress(name.body));
	  end;

	if ( (object_ptr^.flags.on) and
		( (object_ptr^.number=zk$obj_neon_ball) or
		(object_ptr^.number=zk$obj_fluorescent_ball) ) ) then
			$message(zk$text_glowing, 2,
					name.length, iaddress(name.body));

	if (object_ptr^.flags.irritated) then
		$message(zk$text_state_irritated, 2,
			name.length, iaddress(name.body));

	if ( (object_ptr^.number=zk$obj_doc) and
		(context.flags.standing_on_doc) ) then
			$message(zk$text_standing_on_it);

	done:=(object_ptr^.owner=nil);
	if (not done) then done:=(object_ptr^.owner^.owner=nil);
	while (not done) do
	  begin
		$get_object_info(zk$obj_table, object_ptr^.number,
				dummy, child_name);
		$get_object_info(zk$obj_table, object_ptr^.owner^.number,
				dummy, parent_name);
		if (object_ptr^.flags.inside) then
			message:=zk$text_contained_in_is
		else	message:=zk$text_sitting_on_is;
		$message(message, 4,
			child_name.length, iaddress(child_name.body),
			parent_name.length, iaddress(parent_name.body));

		object_ptr:=object_ptr^.owner;
		done:=(object_ptr^.owner=nil);
		if (not done) then done:=(object_ptr^.owner^.owner=nil);
	  end;

	zk$examine_object:=false;
end;

[global] function zk$read_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_ptr : $object_ptr;
	var name : varying[$u2] of char;
	var detail : unsigned) : boolean;

var	error : boolean;
	message : unsigned;
begin
	if (object_ptr^.number=zk$obj_console) then
		console_message(context, name)
	else
	if (object_ptr^.number=zk$obj_badge) then
		$message(zk$text_badge_start, 0,
			 zk$text_badge_middle, 3,
				12, iaddress(context.username),
				iaddress(context.badge_issued),
			 zk$text_badge_end)
	else
	if (not object_ptr^.flags.readable) then
		$message(zk$text_cant_read, 2,
			name.length, iaddress(name.body))
	else
	if (detail<>0) then
		$message(zk$text_object_reads, 2,
			name.length, iaddress(name.body),
			0, 0, detail)
	else
		$message(zk$text_nothing_special, 2,
			name.length, iaddress(name.body));

	zk$read_object:=false;
end;

[global] function zk$close_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char) : boolean;

var	error : boolean;
	message : unsigned;
	verb : packed array[1..4] of char;
begin
	error:=false;

	if (not object1_ptr^.flags.openable) then
	  begin
		error:=true; verb:='clos';
		if (name1[name1.length]='s') then
			message:=zk$text_doesnt_verb_some
		else
		if (name1[1] in vowels) then
			message:=zk$text_doesnt_verb_an
		else	message:=zk$text_doesnt_verb_a;
		$message(message, 4, 4, iaddress(verb),
				name1.length, iaddress(name1.body));
	  end
	else
	if (not object1_ptr^.flags.open) then
	  begin
		error:=true;
		$message(zk$text_already_closed, 2,
				name1.length, iaddress(name1.body));
	  end
	else
	if (object2_ptr^.number<>actor_ptr^.number) then
	  begin
		error:=true;
		$message(zk$text_cant_close, 2,
				name1.length, iaddress(name1.body));
	  end
	else
	if (object1_ptr^.number=zk$obj_coke) then
	  begin
		error:=true;
		$message(zk$text_coke_cant_close);
	  end;

	if (not error) then
	  begin
		object1_ptr^.flags.open:=false;
		if (object1_ptr^.link<>nil) then
			object1_ptr^.link^.flags.open:=false;
		$message(zk$text_closed_text, 2,
				name1.length, iaddress(name1.body));

		if ($room_dark(context)) then $message(zk$text_dark_enter);
	  end;

	zk$close_object:=error;
end;

function bills_to_coin_machine(
	var context : $context_block;
	object1_ptr : $object_ptr;
	var name1 : varying[$u1] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u2] of char) : boolean;

var	error : boolean;
	chance : integer;
	coins_ptr : $object_ptr;
begin
	if (object2_ptr^.number=zk$obj_broken_coin_machine) then
		chance:=5
	else	chance:=$random_integer(context.seed, 4);

	if (chance=1) then
	  begin
		$message(zk$text_coin_machine_success);
		$disconnect_object(object1_ptr); $dispose_object(object1_ptr);
		coins_ptr:=$create_object(zk$obj_coins);
		$connect_object(coins_ptr,
			context.room[context.location].room, true);
		context.score:=context.score + 5;
	  end
	else
	  begin
		error:=false;
		$message(zk$text_coin_machine_failure);
	  end;

	bills_to_coin_machine:=error;
end;

function coins_to_coke_machine(
	var context : $context_block;
	object1_ptr : $object_ptr) : boolean;
var	error : boolean;
	liquid_ptr, coke_ptr : $object_ptr;
begin
	error:=false;

	$disconnect_object(object1_ptr); $dispose_object(object1_ptr);
	coke_ptr:=$create_object(zk$obj_coke);
	$connect_object(coke_ptr, context.room[context.location].room, true);
	liquid_ptr:=$create_object(zk$obj_liquid);
	$connect_object(liquid_ptr, coke_ptr, true);

	$message(zk$text_coke_machine_success);
	context.score:=context.score + 5;
	coins_to_coke_machine:=error;
end;

function coke_to_cdd_devo(
	var context : $context_block;
	object1_ptr : $object_ptr;
	object2_ptr : $object_ptr) : boolean;
var	error : boolean;
	tape_ptr : $object_ptr;
begin
	error:=false;
	$disconnect_object(object1_ptr);
	if (object1_ptr^.flags.shaken) then
	  begin
		$message(zk$text_cdd_devo_failure);
		object2_ptr^.flags.irritated:=true;
	  end
	else
	if (object1_ptr^.flags.open) then
	  begin
		$message(zk$text_cdd_devo_open_coke);
		object2_ptr^.flags.irritated:=true;
	  end
	else
	  begin
		tape_ptr:=$create_object(zk$obj_cdd_tape);
		$connect_object(tape_ptr, context.self, true);
		$message(zk$text_cdd_devo_success);
		context.score:=context.score + 5;
	  end;
	$dispose_object(object1_ptr);
	coke_to_cdd_devo:=error;
end;

function card_to_manager(
	var context : $context_block;
	object1_ptr : $object_ptr;
	object2_ptr : $object_ptr) : boolean;
var	error : boolean;
	tape_ptr : $object_ptr;
begin
	error:=false;
	$disconnect_object(object1_ptr); $dispose_object(object1_ptr);
	context.card_ptr:=nil;
	context.card_remaining:=0;

	tape_ptr:=$create_object(zk$obj_vms_tape);
	$connect_object(tape_ptr, context.self, true);
	$message(zk$text_manager_success);
	context.score:=context.score + 25;

	card_to_manager:=error;
end;

function disk_to_rep(
	var context : $context_block;
	object1_ptr : $object_ptr;
	object2_ptr : $object_ptr) : boolean;

var	error : boolean;
begin
	error:=false;

	$disconnect_object(object1_ptr); $dispose_object(object1_ptr);
	$disconnect_object(object2_ptr); $dispose_object(object2_ptr);
	context.fs_remaining:=4;
	$message(zk$text_fs_departs);

	disk_to_rep:=error;
end;

function arm_to_bp_machine(
	var context : $context_block;
	object1_ptr : $object_ptr;
	object2_ptr : $object_ptr) : boolean;

var	error : boolean;
begin
	error:=false;

	context.flags.bp_taken:=true;
	$message(zk$text_health_bp);

	arm_to_bp_machine:=error;
end;

function put_on_reception_desk(
	var context : $context_block;
	var object1_ptr : $object_ptr;
	var name1 : varying[$u1] of char;
	var object2_ptr : $object_ptr) : boolean;

var	error : boolean;
	guard_object : integer;
	guard_ptr : $object_ptr;
begin
	guard_object:=zk$obj_guard;
	$lookup_object_list(guard_object,
		context.room[zk$room_lobby].room, guard_ptr);
	error:=$test_disconnect(object1_ptr, object2_ptr, false);
	if (not error) then
	  begin
		$connect_object(object1_ptr, guard_ptr, true);
		$message(zk$text_done, 0,
			 zk$text_guard_desk, 2,
				name1.length, iaddress(name1.body));
	  end;
	put_on_reception_desk:=error;
end;

[global] function zk$put_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char;
	inside : boolean;
	success_message : unsigned) : boolean;

var	error, warning : boolean;
begin
	error:=false;
	if (actor_ptr^.number<>zk$obj_self) then
		$message(zk$text_cant_do_that, 2,
			actor_name.length, iaddress(actor_name.body))
	else
	if ( (object1_ptr^.number=zk$obj_bills) and
		( (object2_ptr^.number=zk$obj_broken_coin_machine) or
		  (object2_ptr^.number=zk$obj_working_coin_machine))) then
		error:=bills_to_coin_machine(context,
				object1_ptr, name1, object2_ptr, name2)
	else
	if ( (object1_ptr^.number=zk$obj_coins) and
		(object2_ptr^.number=zk$obj_coke_machine) ) then
		error:=coins_to_coke_machine(context, object1_ptr)
	else
	if ( (object1_ptr^.number=zk$obj_arm) and
		(object2_ptr^.number=zk$obj_bp_machine) ) then
		error:=arm_to_bp_machine(context, object1_ptr, object2_ptr)
	else
	if ( (object2_ptr^.number=zk$obj_reception_desk) and (not inside) ) then
		error:=put_on_reception_desk(context, object1_ptr, name1,
				object2_ptr)
	else
	if ( (object2_ptr^.flags.cognizant) and
		(object2_ptr^.number<>actor_ptr^.number) ) then
	  begin
		error:=true;
		$message(zk$text_keep_off, 2,
				name2.length, iaddress(name2.body));
	  end
	else
	if (not error) then
	  begin
		warning:=$test_disconnect(object1_ptr, object2_ptr, inside);
		if (not warning) then
		  begin
			$connect_object(object1_ptr, object2_ptr, inside);
			$message(success_message, 2,
				name1.length, iaddress(name1.body));
		  end;
	  end;

	zk$put_object:=error;
end;

[global] function zk$give_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char) : boolean;

var	error, warning : boolean;
	desk_ptr : $object_ptr;
	object_desk : integer;
begin
	error:=false;
	if ( (object1_ptr^.number=zk$obj_bills) and
		( (object2_ptr^.number=zk$obj_broken_coin_machine) or
		  (object2_ptr^.number=zk$obj_working_coin_machine))) then
		error:=bills_to_coin_machine(context,
				object1_ptr, name1, object2_ptr, name2)
	else
	if ( (object1_ptr^.number=zk$obj_coins) and
		(object2_ptr^.number=zk$obj_coke_machine) ) then
		error:=coins_to_coke_machine(context, object1_ptr)
	else
	if ( (object1_ptr^.number=zk$obj_coke) and
		(object2_ptr^.number=zk$obj_cdd_developer) ) then
		error:=coke_to_cdd_devo(context, object1_ptr, object2_ptr)
	else
	if ( (object1_ptr^.number=zk$obj_sdc_card) and
		(object2_ptr^.number=zk$obj_manager) ) then
		error:=card_to_manager(context, object1_ptr, object2_ptr)
	else
	if ( (object1_ptr^.number=zk$obj_scratch_disk) and
		(object2_ptr^.number=zk$obj_field_service_rep) ) then
		error:=disk_to_rep(context, object1_ptr, object2_ptr)
	else
	if ( (object1_ptr^.number=zk$obj_arm) and
		(object2_ptr^.number=zk$obj_bp_machine) ) then
		error:=arm_to_bp_machine(context, object1_ptr, object2_ptr)
	else
	if (not object2_ptr^.flags.cognizant) then
	  begin
		error:=true;
		$message(zk$text_cant_give_to_object, 2,
				name2.length, iaddress(name2.body))
	  end
	else
	if ( (object2_ptr^.number<>zk$obj_officer) and
		(object2_ptr^.number<>zk$obj_guard) and
		(object2_ptr^.number<>zk$obj_self) ) then
	  begin
		error:=true;
		$message(zk$text_refuses, 6,
				name2.length, iaddress(name2.body),
				actor_name.length, iaddress(actor_name.body),
				name1.length, iaddress(name1.body));
	  end
	else
	if (object2_ptr^.number=zk$obj_officer) then
	  begin
		warning:=$test_disconnect(object1_ptr, object2_ptr, true);
		if (not warning) then
		  begin
			object_desk:=zk$obj_desk;
			$lookup_object_list(object_desk,
				context.room[context.location].room,
				desk_ptr);
			$connect_object(object1_ptr, desk_ptr, false);
			$message(zk$text_officer_accepts, 2,
				name1.length, iaddress(name1.body));
		  end;
	  end
	else
	  begin
		warning:=$test_disconnect(object1_ptr, object2_ptr, true);
		if (not warning) then
		  begin
			$connect_object(object1_ptr,object2_ptr,true);
			if (object2_ptr^.number=zk$obj_self) then
				$message(zk$text_accepted_you, 4,
				actor_name.length, iaddress(actor_name.body),
				name1.length, iaddress(name1.body))
			else
			$message(zk$text_accepted, 6,
				name2.length, iaddress(name2.body),
				name1.length, iaddress(name1.body));
		  end;
	  end;

	zk$give_object:=error;
end;

[global] function zk$lock_unlock_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char;
	lock : boolean) : boolean;

var	list, error : boolean;
	detail, message : unsigned;
	lock_object : integer;
	lock_ptr : $object_ptr;
	verb : varying[6] of char;
	lock_name : varying[31] of char;
begin
	error:=false;
	if (lock) then verb:='lock' else verb:='unlock';

	if (not object1_ptr^.flags.lockable) then
	  begin
		error:=true;
		if (object1_ptr^.flags.openable) then
			$message(zk$text_no_lock, 2,
				name1.length, iaddress(name1.body))
		else
		  begin
			if (name1[name1.length]='s') then
				message:=zk$text_doesnt_verb_some
			else
			if (name1[1] in vowels) then
				message:=zk$text_doesnt_verb_an
			else	message:=zk$text_doesnt_verb_a;
			$message(message, 4,
				verb.length, iaddress(verb.body),
				name1.length, iaddress(name1.body));
		  end;
	  end
	else
	if (object2_ptr^.number=zk$obj_self) then
	  begin
		error:=true;
		$message(zk$text_unlock_cant_self, 2,
				name1.length, iaddress(name1.body));
	  end
	else
	  begin
		lock_object:=zk$obj_any_lock;
		error:=$lookup_object(lock_object, nil, context,
					lock_ptr, list);
		if (not error) then
			$get_object_info(zk$obj_table, lock_ptr^.number,
						detail, lock_name);
	  end;

	if (not error) then
	  begin
		if (object2_ptr^.owner^.number<>lock_ptr^.number) then
		  begin
			$message(zk$text_unlock_put_key, 2,
				lock_name.length, iaddress(lock_name.body) );
			error:=zk$put_object(context, actor_ptr, actor_name,
					object2_ptr, name2, lock_ptr,
					lock_name, true, zk$text_done_text);
		  end;
		if (not error) then
		  begin
			$message(zk$text_unlock_turn_key);
			error:=zk$move_object(context, actor_ptr, actor_name,
					object2_ptr, name2);
		  end;
	  end;

	zk$lock_unlock_object:=error;
end;

procedure expose_card(var context : $context_block);

var	inside, not_found : boolean;
	blank_object : integer;
	owner_ptr, blank_ptr : $object_ptr;
begin
	blank_object:=zk$obj_sdc_card_blank;
	not_found:=$lookup_object_list(blank_object, context.self, blank_ptr);
	if (not_found) then
		not_found:=$lookup_object_list(blank_object,
				context.room[context.location].room, blank_ptr);

	if (not not_found) then
	  begin
		owner_ptr:=blank_ptr^.owner; inside:=blank_ptr^.flags.inside;
		$disconnect_object(blank_ptr); $dispose_object(blank_ptr);
		blank_ptr:=$create_object(zk$obj_sdc_card);

		$connect_object(blank_ptr, owner_ptr, inside);

		context.card_remaining:=15;
		context.card_ptr:=blank_ptr;
	  end;

	$message(zk$text_strange_light);
end;

[global] function zk$start_stop_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char;
	start : boolean) : boolean;

var	error : boolean;
	i : integer;
	message : unsigned;
	verb : varying[6] of char;
begin
	error:=false;
	if (start) then verb:='start' else verb:='stopp';

	if ( (actor_ptr^.number=zk$obj_guard) and
		(object1_ptr^.number=zk$obj_building_lights) ) then
	  begin
		if (not start) then
			$message(zk$text_cant_do_that, 2,
					actor_name.length,
					iaddress(actor_name.body))
		else
		  begin
			for i:=1 to zk$room_max do
			  if (context.room[i].class<>4) then
				context.room[i].room^.flags.on:=true;
			$message(zk$text_guard_lights_on);
		  end;
	  end
	else
	if (not object1_ptr^.flags.startable) then
	  begin
		error:=true;
		if (object1_ptr^.flags.machine) then
			$message(zk$text_no_switch, 2,
				name1.length, iaddress(name1.body))
		else
		  begin
			if (name1[name1.length]='s') then
				message:=zk$text_doesnt_verb_some
			else
			if (name1[1] in vowels) then
				message:=zk$text_doesnt_verb_an
			else	message:=zk$text_doesnt_verb_a;
			$message(message, 4,
				verb.length, iaddress(verb.body),
				name1.length, iaddress(name1.body));
		  end;
	  end
	else
	if (object1_ptr^.flags.on=start) then
	  begin
		error:=true;
		$message(zk$text_already_verb, 4,
				name1.length, iaddress(name1.body),
				verb.length, iaddress(verb.body));
	  end
	else
	if (object2_ptr^.number<>zk$obj_self) then
	  begin
		error:=true;
		$message(zk$text_cant_verb_object, 4,
				verb.length, iaddress(verb.body),
				name1.length, iaddress(name1.body));
	  end
	else
	if (object1_ptr^.number=zk$obj_lamp) then
	  begin
		if (context.lamp_remaining=0) then
		  begin
			error:=true; $message(zk$text_lamp_no_power);
		  end
		else
		  begin
			context.flags.lamp_on:=start;
			object1_ptr^.flags.on:=start;
			if (object1_ptr^.link<>nil) then
				object1_ptr^.link^.flags.on:=start;
			$message(zk$text_object_verb, 4,
				name1.length, iaddress(name1.body),
				verb.length, iaddress(verb.body));
			if (not (context.room[context.location].room^.
					flags.on) ) then
			  begin
				if (start) then
					$describe_room(context,
						context.location,
					context.room[context.location].seen,
						context.flags.brief)
				else
				  begin
					$message(zk$text_dark_enter);
					if (context.location =
					    zk$room_tape_library) then
						expose_card(context);
				  end;
			  end;
		  end;
	  end
	else
	  begin
		object1_ptr^.flags.on:=start;
		if (object1_ptr^.link<>nil) then
			object1_ptr^.link^.flags.on:=start;
		$message(zk$text_object_verb, 4,
				name1.length, iaddress(name1.body),
				verb.length, iaddress(verb.body));
		if ( (object1_ptr^.number=zk$obj_computer) and
			(not start) ) then
		  begin
			context.flags.booted:=false;
			context.disk_drive_ptr^.flags.locked:=false;
		  end;
	  end;

	zk$start_stop_object:=error;
end;

[global] function zk$heal_kill_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char;
	heal : boolean) : boolean;

var	error : boolean;
	message : unsigned;
begin
	error:=false;

	if (heal) then
	  begin
		if (object2_ptr^.number<>zk$obj_self) then
			$message(zk$text_cant_use_to_heal)
		else
			$message(zk$text_looks_ok, 2,
				name1.length, iaddress(name1.body))
	  end
	else
	if ( (object2_ptr^.number<>zk$obj_sword) and
		(object2_ptr^.number<>zk$obj_self) ) then
			$message(zk$text_cant_use_to_damage)
	else
	if ( (object1_ptr^.number=zk$obj_neon_ball) or
		(object1_ptr^.number=zk$obj_fluorescent_ball) ) then
	  begin
		if (object1_ptr^.flags.on) then
		  begin
			error:=true; context.flags.died:=true;
			$message(zk$text_ball_explodes);
		  end
		else
		  begin
			$message(zk$text_ball_smashed);
			$disconnect_object(object1_ptr);
			$dispose_object(object1_ptr);
		  end;
	  end
	else
	if (object1_ptr^.number=zk$obj_self) then
	  begin
		error:=true; context.flags.died:=true;
		$message(zk$text_kill_self);
	  end
	else
	if (object1_ptr^.flags.cognizant) then
	  begin
		if (object1_ptr^.flags.irritated) then
		  begin
			error:=true; context.flags.died:=true;
			$message(zk$text_kill_cognizant, 2,
					name1.length, iaddress(name1.body));
		  end
		else
		  begin
			object1_ptr^.flags.irritated:=true;
			$message(zk$text_irritated, 2,
					name1.length, iaddress(name1.body));
		  end;
	  end
	else	$message(zk$text_cant_damage, 2,
				name1.length, iaddress(name1.body));

	zk$heal_kill_object:=error;
end;

[global] function zk$rub_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char) : boolean;

var	error : boolean;
	message : unsigned;
begin
	error:=false;

	if (object2_ptr^.number=actor_ptr^.number) then
	  begin
		if ( (object1_ptr^.number=zk$obj_neon_ball) or
			(object1_ptr^.number=zk$obj_fluorescent_ball) ) then
		  begin
			if (object1_ptr^.flags.on) then
				$message(zk$text_rub_ball)
			else
			  begin
				object1_ptr^.flags.on:=true;
				$message(zk$text_glowing_begin, 2,
					name1.length,
					iaddress(name1.body));
			  end;
		  end
		else	$message(zk$text_fondle, 2,
				name1.length, iaddress(name1.body))
	  end
	else
	if (object1_ptr^.flags.cognizant) then
		$message(zk$text_keep_off, 2,
				name1.length, iaddress(name1.body))
	else
	if (object2_ptr^.flags.cognizant) then
		$message(zk$text_keep_off, 2,
				name2.length, iaddress(name2.body))
	else
		$message(zk$text_rub, 4,
			name1.length, iaddress(name1.body),
			name2.length, iaddress(name2.body));

	zk$rub_object:=error;
end;

[global] function zk$boot_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_ptr : $object_ptr;
	var name : varying[$u2] of char) : boolean;

var	error : boolean;
	message : unsigned;
	self_name, verb : varying[10] of char;
begin
	error:=false; verb:='bootstrapp';

	if (object_ptr^.number=zk$obj_computer) then
	  begin
		if (not object_ptr^.flags.on) then
		  begin
			error:=true;
			$message(zk$text_state_off, 2,
				name.length, iaddress(name.body));
		  end
		else
		if (context.disk_drive_ptr^.contents=nil) then
		  begin
			error:=true;
			$message(zk$text_console_message);
			context.console_message:=2; (* console_disk *)
		  end
		else
		if (context.disk_drive_ptr^.flags.open) then
		  begin
			error:=true;
			$message(zk$text_console_message);
			context.console_message:=2; (* console_disk *)
		  end
		else
		if (context.disk_drive_ptr^.contents^.number<>
			zk$obj_system_disk) then
		  begin
			error:=true;
			$message(zk$text_console_message);
			context.console_message:=3; (* console_boot_failure *)
		  end
		else
		  begin
			$message(zk$text_console_message);
			context.console_message:=4; (* console_booted *)
			context.flags.booted:=true;
			context.disk_drive_ptr^.flags.locked:=true;
		  end;
	  end
	else
	if (object_ptr^.flags.startable) then
	  begin
		self_name:='self';
		$message(zk$text_start_object);
		error:=zk$start_stop_object(context,
				actor_ptr, actor_name,
				object_ptr, name,
				context.self, self_name, true);
	  end
	else
	  begin
		error:=true;
		if (name[name.length]='s') then
			message:=zk$text_doesnt_verb_some
		else
		if (name[1] in vowels) then
			message:=zk$text_doesnt_verb_an
		else	message:=zk$text_doesnt_verb_a;
		$message(message, 4,
			verb.length, iaddress(verb.body),
			name.length, iaddress(name.body));
	  end;

	zk$boot_object:=error;
end;

end.
