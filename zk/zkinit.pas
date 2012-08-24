[inherit('lib$:typedef',
	 'lib$:sysdef',
	 'lib$:rtldef',
	 'lib$:zk$context_def',
	 'lib$:zk$routines_def',
	 'lib$:zk$action_def',
	 'lib$:zk$obj', 'lib$:zk$room', 'lib$:zk$text',
	 'ifc$library:ifc$rtl_def')]
module zk$init;

const	max_links = 100;
	number_to_answer = 6;
	zk$k_save_level = 8;
	zk$k_rec_start = 1;
	zk$k_rec_context = 2;
	zk$k_rec_object = 3;
	zk$k_rec_room = 4;

type	$start_record = record
				record_type : $ubyte;
				level : $ubyte;
				room_max : integer;
				obj_max : integer;
				version : unsigned;
				baselevel : unsigned;
				link_time : $uquad;
				time : $uquad;
				hwtype : unsigned;
				sid : unsigned;
				swtype : unsigned;
				swvers : unsigned;
			end;

	$context_record = record
				record_type : $ubyte;
				flags : unsigned;
				location : integer;
				score : integer;
				moves : integer;
				seed : unsigned;
				combination : integer;
				officer_leave_time : integer;
				lamp_remaining : integer;
				card_remaining : integer;
				console_message : integer;
				fs_remaining : integer;
				questions_remaining : integer;
				current_question : integer;
				crew_location : integer;
				crew_last_location : integer;
				badge_issued : $uquad;
				question_asked : unsigned;

				card_location : integer;
				lamp_location : integer;
			end;

	$object_record = record
				record_type : $ubyte;
				number : integer;
				location : integer;
				flags : unsigned;
				contents : integer;
				owner : $ubyte;

				link_number : integer;
				link_location : integer;
			end;

	$room_record = record
				record_type : $ubyte;
				seen : packed array[1..zk$room_max] of boolean;
			end;

const	$start_record_size = size($start_record);
	$context_record_size = size($context_record);
	$object_record_size = size($object_record);
	$room_record_size = size($room_record);
	$save_record_size = max($start_record_size, $context_record_size,
				$object_record_size, $room_record_size);

type	$start_record_buf = packed array[1..$start_record_size] of char;
	$context_record_buf = packed array[1..$context_record_size] of char;
	$object_record_buf = packed array[1..$object_record_size] of char;
	$room_record_buf = packed array[1..$room_record_size] of char;

	$link_record = record
			object_ptr : $object_ptr;
			link_number : integer;
			link_location : integer;
			end;
	$link_info = record
			last : integer;
			link : packed array[1..max_links] of $link_record;
			end;

var	zk$k_baselevel,
	zk$t_version,
	zk$k_link_time_l0,
	zk$k_link_time_l1 : [external, value] unsigned;

procedure initialize_run_time(var context : $context_block);
var	c, d, e : $object_ptr;
begin
	c:=$create_object(zk$obj_lamp);
	$connect_object(c, context.room[zk$room_woods].room, true);
	context.lamp_ptr:=c;

	c:=$create_object(zk$obj_tape_drive);
	$connect_object(c, context.room[zk$room_vms_lab_2].room, true);
	context.tape_drive_ptr:=c;

	c:=$create_object(zk$obj_disk_drive);
	$connect_object(c, context.room[zk$room_vms_lab_2].room, true);
	context.disk_drive_ptr:=c;

	c:=$create_object(zk$obj_rug);
	$connect_object(c, context.room[zk$room_lobby].room, true);
	d:=$create_object(zk$obj_compass); $connect_object(d, c, false);
	e:=$create_object(zk$obj_needle); $connect_object(e, d, false);

	c:=$create_object(zk$obj_sack);
	$connect_object(c, context.room[zk$room_woods].room, true);
	d:=$create_object(zk$obj_ascii_table); $connect_object(d, c, true);

	c:=$create_object(zk$obj_plant);
	c^.flags.open:=false;
	$connect_object(c, context.room[zk$room_dtr_dev].room, true);
	d:=$create_object(zk$obj_dtr_tape); $connect_object(d, c, true);

	c:=$create_object(zk$obj_guard);
	$connect_object(c, context.room[zk$room_lobby].room, true);
	d:=$create_object(zk$obj_keys); $connect_object(d, c, true);

	c:=$create_object(zk$obj_safe);
	$connect_object(c, context.room[zk$room_petty_cash].room, true);
	d:=$create_object(zk$obj_bills); $connect_object(d, c, true);
	d:=$create_object(zk$obj_keypad); $connect_object(d, c, false);

	c:=$create_object(zk$obj_cafe_table);
	$connect_object(c, context.room[zk$room_cafe].room, true);
	d:=$create_object(zk$obj_diet_quiz); $connect_object(d, c, false);

	c:=$create_object(zk$obj_wall);
	$connect_object(c, context.room[zk$room_entrance].room, false);
	d:=$create_object(zk$obj_bars); $connect_object(d, c, false);

	c:=$create_object(zk$obj_mirror);
	$connect_object(c, context.room[zk$room_rest_room].room, false);

	c:=$create_object(zk$obj_tidbit);
	$connect_object(c,context.room[zk$room_health_services].room,false);

	c:=$create_object(zk$obj_neon_ball);
	$connect_object(c, context.room[zk$room_will_office].room, true);
	d:=$create_object(zk$obj_fluorescent_ball);
	$connect_object(d, context.room[zk$room_ed_office].room, true);
	c^.link:=d; d^.link:=c;

	c:=$create_object(zk$obj_elevator_lock);
	$connect_object(c, context.room[zk$room_non_descript_hall_1].room,
				false);

	c:=$create_object(zk$obj_control_panel);
	$connect_object(c, context.room[zk$room_elevator_blue].room, false);
	d:=$create_object(zk$obj_blue_button);
		$connect_object(d, c, false);
	d:=$create_object(zk$obj_yellow_button);
		$connect_object(d, c, false);
	d:=$create_object(zk$obj_red_button);
		$connect_object(d, c, false);
	d:=$create_object(zk$obj_orange_button);
		$connect_object(d, c, false);

	c:=$create_object(zk$obj_control_panel);
	$connect_object(c, context.room[zk$room_elevator_yellow].room, false);
	d:=$create_object(zk$obj_blue_button);
		$connect_object(d, c, false);
	d:=$create_object(zk$obj_yellow_button);
		$connect_object(d, c, false);
	d:=$create_object(zk$obj_red_button);
		$connect_object(d, c, false);
	d:=$create_object(zk$obj_orange_button);
		$connect_object(d, c, false);

	c:=$create_object(zk$obj_control_panel);
	$connect_object(c, context.room[zk$room_elevator_red].room, false);
	d:=$create_object(zk$obj_blue_button);
		$connect_object(d, c, false);
	d:=$create_object(zk$obj_yellow_button);
		$connect_object(d, c, false);
	d:=$create_object(zk$obj_red_button);
		$connect_object(d, c, false);
	d:=$create_object(zk$obj_orange_button);
		$connect_object(d, c, false);
end;

[global] procedure zk$initialize(var context : $context_block);

var	j, i, start, count, class : integer;
	return, description, flags, detail : unsigned;
	c, d, e : $object_ptr;
	now : $uquad;
	info : packed array[1..16] of $ubyte;
	link : packed array[1..14] of $ubyte;
	name : varying[31] of char;
	item_list : $item_list;
begin
	start:=zk$room_pad;

	context.flags.long:=0;
	context.location:=start;
	context.flags.start:=true;
	context.score:=0;
	context.moves:=0;
	$gettim(now); context.seed:=now.l0;
	context.combination:=$random_integer(context.seed, 8999) + 1000;
	context.officer_leave_time:=$random_integer(context.seed, 20) + 90;
	context.lamp_remaining:=120;
	context.console_message:=1; (* console_initial *)
	context.fs_remaining:=0;
	context.lights_ptr:=$create_object(zk$obj_building_lights);
	context.arm_ptr:=$create_object(zk$obj_arm);
	context.questions_remaining:=number_to_answer;
	context.current_question:=0;
	context.crew_location:=zk$room_top_of_stairs_4;
	context.crew_last_location:=zk$room_top_of_stairs_4;
	context.question_asked::unsigned:=0;

	context.self:=$create_object(zk$obj_self);
	context.self^.location:=start;

	$get_object_info(zk$obj_table, zk$obj_current_room, detail, name,
					flags, count, info);
	flags::$object_flags.on:=true;
	for i:=1 to zk$room_max do
	  begin
		$get_room_info(zk$room_table, i, description,name,link,class);

		context.room[i].seen:=false;
		context.room[i].class:=class;
		c:=$create_object_info(zk$obj_current_room, flags, info);
		c^.location:=i; context.room[i].room:=c;

		for j:=13 to 14 do
		  if ( (link[j]<>0) and (link[j-2]<=i) ) then
		    begin
			c:=$create_object(link[j]);
			$connect_object(c, context.room[i].room, false);
			d:=$create_object(link[j]);
			$connect_object(d, context.room[link[j-2]].room, false);
			c^.link:=d; d^.link:=c;
		    end;
	  end;
	context.room[zk$room_lab_of_implementors].room^.flags.on:=false;
	context.room[zk$room_tape_library].room^.flags.on:=false;

	for i:=1 to zk$obj_max do
	  begin
		$get_object_info(zk$obj_table, i, detail, name, flags,
					count, info);
		if ( (uand(flags,1)=0) and (info[1]<>0) ) then
		  begin
			c:=$create_object_info(i, flags, info);
			$connect_object(c, context.room[info[1]].room, true);
		  end;
	  end;

	initialize_run_time(context);

	item_list[1].buffer_length:=12;
	item_list[1].item_code:=jpi$_username;
	item_list[1].buffer_address:=iaddress(context.username);
	item_list[1].return_length_address:=0;
	item_list[2].buffer_length:=0;
	item_list[2].item_code:=0;

	return:=$getjpiw(,,,item_list);
	if (not odd(return)) then $signal(return);

	$describe_room(context, start, false, false);
	context.room[start].seen:=true;
end;

[global] function zk$restart_game(
	var context : $context_block) : boolean;

var	i : integer;
begin
	for i:=1 to zk$room_max do
		$dispose_object(context.room[i].room);

	$dispose_object(context.self);
	$dispose_object(context.lights_ptr);
	$dispose_object(context.arm_ptr);

	zk$initialize(context);

	zk$restart_game:=false;
end;

procedure write_start_record(var save_file : text);
var	return : unsigned;
	link_time : $uquad;
	item_list : $item_list;
	start_record : $start_record;
begin
	start_record.record_type:=zk$k_rec_start;
	start_record.level:=zk$k_save_level;
	start_record.room_max:=zk$room_max;
	start_record.obj_max:=zk$obj_max;
	start_record.version:=zk$t_version;
	start_record.baselevel:=zk$k_baselevel;
		link_time.l0:=zk$k_link_time_l0;
		link_time.l1:=zk$k_link_time_l1;
	start_record.link_time:=link_time;
	start_record.sid:=0;
	$gettim(start_record.time);

	item_list[1].buffer_length:=4;
	item_list[1].item_code:=syi$_node_hwtype;
	item_list[1].buffer_address:=iaddress(start_record.hwtype);
	item_list[1].return_length_address:=0;

	item_list[2].buffer_length:=4;
	item_list[2].item_code:=syi$_sid;
	item_list[2].buffer_address:=iaddress(start_record.sid);
	item_list[2].return_length_address:=0;

	item_list[3].buffer_length:=4;
	item_list[3].item_code:=syi$_node_swtype;
	item_list[3].buffer_address:=iaddress(start_record.swtype);
	item_list[3].return_length_address:=0;

	item_list[4].buffer_length:=4;
	item_list[4].item_code:=syi$_node_swvers;
	item_list[4].buffer_address:=iaddress(start_record.swvers);
	item_list[4].return_length_address:=0;

 	item_list[5].buffer_length:=0;
	item_list[5].item_code:=0;

	return:=$getsyiw(,,,item_list);
	if (not odd(return)) then $signal(return);

	writeln(save_file, start_record::$start_record_buf);
end;

procedure write_context_record(
	var save_file : text;
	var context : $context_block);

var	context_record : $context_record;
	room_ptr : $object_ptr;
begin
	context_record.record_type:=zk$k_rec_context;

	context_record.flags:=context.flags.long;
	context_record.location:=context.location;
	context_record.score:=context.score;
	context_record.moves:=context.moves;
	context_record.seed:=context.seed;
	context_record.combination:=context.combination;
	context_record.officer_leave_time:=context.officer_leave_time;
	context_record.lamp_remaining:=context.lamp_remaining;
	context_record.card_remaining:=context.card_remaining;
	context_record.console_message:=context.console_message;
	context_record.fs_remaining:=context.fs_remaining;
	context_record.questions_remaining:=context.questions_remaining;
	context_record.current_question:=context.current_question;
	context_record.crew_location:=context.crew_location;
	context_record.crew_last_location:=context.crew_last_location;
	context_record.badge_issued:=context.badge_issued;
	context_record.question_asked:=context.question_asked::unsigned;

	room_ptr:=context.card_ptr;
	if (room_ptr<>nil) then
	  begin
		while (room_ptr^.owner<>nil) do room_ptr:=room_ptr^.owner;
		context_record.card_location:=room_ptr^.location;
	  end
	else	context_record.card_location:=0;

	room_ptr:=context.lamp_ptr;
	while (room_ptr^.owner<>nil) do room_ptr:=room_ptr^.owner;
	context_record.lamp_location:=room_ptr^.location;

	writeln(save_file, context_record::$context_record_buf);
end;

procedure write_room_record(
	var save_file : text;
	var context : $context_block);

var	i : integer;
	room_record : $room_record;
begin
	room_record.record_type:=zk$k_rec_room;
	for i:=1 to zk$room_max do
		room_record.seen[i]:=context.room[i].seen;

	writeln(save_file, room_record::$room_record_buf);
end;

procedure write_object_record(
	var save_file : text;
	var owner_ptr : $object_ptr);

var	object_record : $object_record;
	contents : integer;
	detail : unsigned;
	object_ptr, room_ptr : $object_ptr;
	name : varying[31] of char;
begin
(*	$get_object_info(zk$obj_table, owner_ptr^.number, detail, name);
	$message(zk$text_save_write, 2, name.length, iaddress(name.body));*)

	object_record.record_type:=zk$k_rec_object;
	object_record.number:=owner_ptr^.number;
	object_record.location:=owner_ptr^.location;
	object_record.flags:=owner_ptr^.flags.long;

	if (owner_ptr^.owner<>nil) then
		object_record.owner:=owner_ptr^.owner^.number
	else	object_record.owner:=0;

	if (owner_ptr^.link<>nil) then
	  begin
		object_record.link_number:=owner_ptr^.link^.number;
		room_ptr:=owner_ptr^.link;
		while (room_ptr^.owner<>nil) do room_ptr:=room_ptr^.owner;
		object_record.link_location:=room_ptr^.location;
	  end
	else
	  begin
		object_record.link_number:=0; object_record.link_location:=0;
	  end;

	object_record.contents:=0; object_ptr:=owner_ptr^.contents;
	while (object_ptr<>nil) do
	  begin
		object_record.contents:=object_record.contents + 1;
		object_ptr:=object_ptr^.next;
	  end;

	writeln(save_file, object_record::$object_record_buf);

	object_ptr:=owner_ptr^.contents;
	while (object_ptr<>nil) do
	  begin
		write_object_record(save_file, object_ptr);
		object_ptr:=object_ptr^.next;
	  end;
end;

[global] function zk$save_game(
	var context : $context_block;
	var filename : varying[$u1] of char) : boolean;

var	error : boolean;
	i : integer;
	save_file : text;
begin
	error:=false;
	open(save_file, filename, history:=new, carriage_control:=none,
		record_type:=variable, record_length:=$save_record_size,
		default:='.ZKO');
	rewrite(save_file);

	write_start_record(save_file);
	write_room_record(save_file, context);
	for i:=1 to zk$room_max do
		write_object_record(save_file, context.room[i].room);
	write_object_record(save_file, context.self);
	write_context_record(save_file, context);

	close(save_file);

	$message(zk$text_done);
	zk$save_game:=error;
end;

function read_start_record(var save_file : text) : boolean;

var	error : boolean;
	start_record : $start_record;
begin
	error:=false;
	readln(save_file, start_record::$start_record_buf);

	if (start_record.record_type<>zk$k_rec_start) then
	  begin
		error:=true;
		$message(zk$text_save_wrong_record);
	  end
	else
	if (start_record.level<zk$k_save_level) then
	  begin
		error:=true;
		$message(zk$text_save_file_obsolete);
	  end
	else
	if (start_record.level>zk$k_save_level) then
	  begin
		error:=true;
		$message(zk$text_save_file_future);
	  end
	else
	if ( (zk$room_max<>start_record.room_max) or
		(zk$obj_max<>start_record.obj_max) ) then
	  begin
		error:=true;
		$message(zk$text_save_file_obsolete);
	  end
	else
	  begin
		$message(zk$text_save_saving_system, 7,
				4, iaddress(start_record.hwtype),
				start_record.sid,
				4, iaddress(start_record.swtype),
				4, iaddress(start_record.swvers));
		$message(zk$text_save_saving_game, 4,
				4, iaddress(start_record.version),
				start_record.baselevel,
				iaddress(start_record.link_time));
		$message(zk$text_save_saved_at, 1,
				iaddress(start_record.time));
	  end;

	read_start_record:=error;
end;

function find_object(
	var context : $context_block;
	object_number : integer;
	room : integer;
	var object_ptr : $object_ptr) : boolean;

var	error : boolean;
begin
	if (context.location=room) then
	  begin
		error:=$lookup_object_inside(object_number,
				context.self, object_ptr);
		if (error) then
			error:=$lookup_object_inside(object_number,
				context.room[room].room, object_ptr);
	  end
	else	error:=$lookup_object_inside(object_number,
				context.room[room].room, object_ptr);

	find_object:=error;
end;

function read_context_record(
	var save_file : text;
	var context : $context_block) : boolean;

var	error : boolean;
	context_record : $context_record;
begin
	error:=false;
	readln(save_file, context_record::$context_record_buf);

	if (context_record.record_type<>zk$k_rec_context) then
	  begin
		error:=true;
		$message(zk$text_save_wrong_record);
	  end
	else
	  begin
		context.flags.long:=context_record.flags;
		context.location:=context_record.location;
		context.score:=context_record.score;
		context.moves:=context_record.moves;
		context.seed:=context_record.seed;
		context.combination:=context_record.combination;
		context.officer_leave_time:=context_record.officer_leave_time;
		context.lamp_remaining:=context_record.lamp_remaining;
		context.card_remaining:=context_record.card_remaining;
		context.console_message:=context_record.console_message;
		context.fs_remaining:=context_record.fs_remaining;
		context.questions_remaining:=context_record.questions_remaining;
		context.current_question:=context_record.current_question;
		context.crew_location:=context_record.crew_location;
		context.crew_last_location:=context_record.crew_last_location;
		context.badge_issued:=context_record.badge_issued;
		context.question_asked::unsigned:=context_record.question_asked;

		if (context_record.card_location<>0) then
			error:=find_object(context, zk$obj_sdc_card,
					context_record.card_location,
					context.card_ptr)
		else	context.card_ptr:=nil;
		if (not error) then
		  begin
			error:=find_object(context, zk$obj_lamp,
					context_record.lamp_location,
					context.lamp_ptr);
		  end;
		if (not error) then
			error:=find_object(context, zk$obj_disk_drive,
					zk$room_vms_lab_2,
					context.disk_drive_ptr);
		if (not error) then
			error:=find_object(context, zk$obj_tape_drive,
					zk$room_vms_lab_2,
					context.tape_drive_ptr);
	  end;

	if (error) then $message(zk$text_save_bugcheck);
	read_context_record:=error;
end;

function read_room_record(
	var save_file : text;
	var context : $context_block) : boolean;

var	error : boolean;
	room_record : $room_record;
	i : integer;
begin
	error:=false;

	readln(save_file, room_record::$room_record_buf);
	if (room_record.record_type<>zk$k_rec_room) then
	  begin
		error:=true;
		$message(zk$text_save_wrong_record);
	  end
	else
		for i:=1 to zk$room_max do
			context.room[i].seen:=room_record.seen[i];

	read_room_record:=error;
end;

function read_object_record(
	var save_file : text;
	var owner_ptr : $object_ptr;
	expected_owner : $ubyte;
	var link_info : $link_info) : boolean;

var	error : boolean;
	l, i : integer;
	detail : unsigned;
	object_ptr : $object_ptr;
	object_record : $object_record;
	name1, name2 : varying[31] of char;
begin
	error:=false;

	readln(save_file, object_record::$object_record_buf);

	if (object_record.record_type<>zk$k_rec_object) then
	  begin
		error:=true;
		$message(zk$text_save_wrong_record);
	  end
	else
	if (object_record.owner<>expected_owner) then
	  begin
		error:=true;
		$message(zk$text_save_bugcheck);
	  end
	else
	  begin
		owner_ptr:=$create_object(object_record.number);
		owner_ptr^.location:=object_record.location;
		owner_ptr^.flags.long:=object_record.flags;

		if (object_record.link_number<>0) then
		  begin
			link_info.last:=link_info.last + 1;
			l:=link_info.last;
			link_info.link[l].object_ptr:=owner_ptr;
			link_info.link[l].link_number:=
				object_record.link_number;
			link_info.link[l].link_location:=
				object_record.link_location;
		  end;

		i:=1;
		while ( (i<=object_record.contents) and (not error) ) do
		  begin
			error:=read_object_record(save_file, object_ptr,
					object_record.number, link_info);
			$connect_object(object_ptr, owner_ptr,
						object_ptr^.flags.inside);
(*		$get_object_info(zk$obj_table, object_ptr^.number,
					detail, name1);
		$get_object_info(zk$obj_table, owner_ptr^.number,
					detail, name2);
		$message(zk$text_save_create, 4,
				name2.length, iaddress(name2.body),
				name1.length, iaddress(name1.body));*)
			i:=i+1;
		  end;
	  end;

	read_object_record:=error;
end;

function establish_links(
	var context : $context_block;
	var link_info : $link_info) : boolean;

var	error : boolean;
	i : integer;
	detail : unsigned;
	link_ptr : $object_ptr;
	name1, name2, name3 : varying[31] of char;
begin
	error:=false; i:=1;
	while ( (i<=link_info.last) and (not error) ) do
	  begin
(*		$get_object_info(zk$obj_table,
				link_info.link[i].object_ptr^.number,
				detail, name1);
		$get_object_info(zk$obj_table,
				link_info.link[i].link_number, detail, name2);
		$get_room_info(zk$room_table,
				link_info.link[i].link_location, detail, name3);
		$message(zk$text_save_link, 6,
				name1.length, iaddress(name1.body),
				name2.length, iaddress(name2.body),
				name3.length, iaddress(name3.body));*)

		error:=find_object(context,
				link_info.link[i].link_number,
				link_info.link[i].link_location, link_ptr);
		if (not error) then
		  begin
			link_info.link[i].object_ptr^.link:=link_ptr;
			i:=i+1;
		  end
		else	$message(zk$text_save_bugcheck);
	  end;
	establish_links:=error;
end;

[global] function zk$restore_game(
	var context : $context_block;
	var filename : varying[$u1] of char) : boolean;

var	error : boolean;
	i : integer;
	save_file : text;
	link_info : $link_info;
begin
	error:=false;
	open(save_file, filename, history:=readonly, carriage_control:=none,
		record_type:=variable, record_length:=$save_record_size,
		default:='.ZKO');
	reset(save_file);

	error:=read_start_record(save_file);
	if (not error) then
		error:=read_room_record(save_file, context);

	i:=1; link_info.last:=0;
	while ( (i<=zk$room_max) and (not error) ) do
	  begin
		$dispose_object(context.room[i].room);
		error:=read_object_record(save_file, context.room[i].room,
				0, link_info);
		i:=i+1;
	  end;

	if (not error) then
	  begin
		$dispose_object(context.self);
		error:=read_object_record(save_file, context.self,
			0, link_info);
	  end;

	if (not error) then
		error:=read_context_record(save_file, context);

	if (not error) then
		error:=establish_links(context, link_info);

	if (error) then
		$message(zk$text_failed)
	else
	  begin
		$message(zk$text_done, 0, 0);
		$describe_room(context, context.location, false, false);
	  end;

	close(save_file);
	zk$restore_game:=error;
end;

end.
