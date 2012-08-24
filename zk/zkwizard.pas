[inherit('lib$:typedef',
	 'lib$:zk$context_def',
	 'lib$:zk$room', 'lib$:zk$text', 'lib$:zk$obj',
	 'lib$:zk$action_def', 'lib$:zk$routines_def',
	 'ifc$library:ifc$rtl_def')]
module zk$wizard;

[global] function zk$edswbl_take_object(
	var context : $context_block;
	object_number : integer) : boolean;

var	error : boolean;
	object_ptr : $object_ptr;
	flags, detail : unsigned;
	name : varying[31] of char;
begin
	$get_object_info(zk$obj_table, object_number, detail, name, flags);
	if (uand(flags,1)<>0) then
	  begin
		$message(zk$text_more_specific);
		error:=true;
	  end
	else
	  begin
		object_ptr:=$create_object(object_number);
		error:=$connect_object(object_ptr, context.self, true);
		$message(zk$text_done);
	  end;

	zk$edswbl_take_object:=error;
end;

[global] function zk$edswbl_keypad(
	var context : $context_block) : boolean;
begin
	$message(zk$text_combination, 1, context.combination);
	zk$edswbl_keypad:=false;
end;

[global] function zk$edswbl_wait(
	var context : $context_block) : boolean;
begin
	while (not $advance_clock(context)) do ;
	zk$edswbl_wait:=false;
end;

[global] function zk$edswbl_goto_room(
	var context : $context_block;
	var room_number : integer) : boolean;
var	error : boolean;
begin
	error:=false;
	if ( (room_number>0) and (room_number<=zk$room_max) ) then
	  begin
		context.location:=room_number;
		context.self^.location:=room_number;
		$describe_room(context, room_number,
			context.room[room_number].seen,
			context.flags.brief);
		context.room[room_number].seen:=true;
	  end
	else
	  begin
		error:=true;
		$message(zk$text_cant_go_that_way);
	  end;

	zk$edswbl_goto_room:=error;
end;

[global] function zk$edswbl_where(
	var context : $context_block) : boolean;

var	i : integer;
	detail : unsigned;
	name : varying[31] of char;
	link : packed array[1..14] of $ubyte;
	direction : [static] array[1..10] of varying[10] of char :=
		('North', 'South', 'East', 'West',
		 'North east', 'South west', 'South east', 'North west',
		 'Up', 'Down');
begin
	$get_room_info(zk$room_table, context.location, detail, name, link);

	$message(zk$text_here_is, 3, context.location,
			name.length, iaddress(name.body));
	for i:=1 to 10 do
		if (link[i]<>0) then
		  begin
			$get_room_info(zk$room_table, link[i], detail, name);
			$message(zk$text_goes_to, 5,
					direction[i].length,
					iaddress(direction[i].body),
					link[i],
					name.length, iaddress(name.body));
		  end;

	zk$edswbl_where:=false;
end;

[global] function zk$edswbl_nurse(var context : $context_block) : boolean;
begin
	context.flags.physical:=true;
	$message(zk$text_done);
	zk$edswbl_nurse:=false;
end;

[global] function zk$edswbl_system(var context : $context_block) : boolean;
begin
	context.flags.vms_installed:=true;
	context.flags.cdd_installed:=true;
	context.flags.dtr_installed:=true;

	$message(zk$text_done);
	zk$edswbl_system:=false;
end;

end.
