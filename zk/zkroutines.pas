[inherit('lib$:typedef',
	 'lib$:rtldef',
	 'lib$:zk$context_def',
	 'lib$:zk$text', 'lib$:zk$obj', 'lib$:zk$room',
	 'ifc$library:ifc$rtl_def')]
module zk$routines;

const	vowels = ['A','E','I','O','U','a','e','i','o','u'];

[global] procedure zk$dispose_object(var owner_ptr : $object_ptr);
var	object_ptr, next_ptr : $object_ptr;
	detail : unsigned;
	name : varying[31] of char;
begin
	object_ptr:=owner_ptr^.contents;
	while (object_ptr<>nil) do
	  begin
		next_ptr:=object_ptr^.next;
			zk$dispose_object(object_ptr);
		object_ptr:=next_ptr;
	  end;

(*	$get_object_info(zk$obj_table, owner_ptr^.number, detail, name);
	$message(zk$text_save_dispose, 2, name.length, iaddress(name.body));*)

	dispose(owner_ptr);
	owner_ptr:=nil;
end;

[global] function zk$random_integer(
	var seed : unsigned;
	upper : integer) : integer;
begin
	zk$random_integer:=trunc(RANDOM*upper)+1;
end;

[global] function zk$compare_date(
	var start, finish: $uquad) : integer;
begin
	if (start.l1 > finish.l1) then zk$compare_date:=1
	else
	if (start.l1 < finish.l1) then zk$compare_date:=-1
	else
	if (start.l0 > finish.l0) then zk$compare_date:=1
	else
	if (start.l0 < finish.l0) then zk$compare_date:=-1
	else
		zk$compare_date:=0;
end;

[global] function zk$lookup_object_inside(
	var object : integer;
	var constraint : $object_ptr;
	var object_ptr : $object_ptr) : boolean;

var	error : boolean;
	c : $object_ptr;
begin
	error:=true; c:=constraint^.contents;
	while ( (c<>nil) and (error) ) do
	  if (c^.number=object) then
	    begin
		error:=false; object_ptr:=c;
	    end
	  else
	    begin
		if (c^.contents<>nil) then
			error:=zk$lookup_object_inside(object, c, object_ptr);
		c:=c^.next;
	    end;

	zk$lookup_object_inside:=error;
end;

[global] function zk$lookup_object_list(
	var object : integer;
	var constraint : $object_ptr;
	var object_ptr : $object_ptr) : boolean;

var	error : boolean;
	c : $object_ptr;
begin
	error:=true; c:=constraint^.contents;
	while ( (c<>nil) and (error) ) do
		if (c^.number=object) then
		  begin
			if ( (c^.flags.inside) and
				(not constraint^.flags.open) ) then c:=nil
			else
			  begin
				error:=false; object_ptr:=c;
			  end;
		  end
		else
		  begin
			if (c^.contents<>nil) then
			  begin
				error:=zk$lookup_object_list(object, c,
								object_ptr);
				if (not error) then
					error:=( (not c^.flags.open) and
						(object_ptr^.flags.inside));
			  end;
			c:=c^.next;
		  end;

	zk$lookup_object_list:=error;
end;

[global] function zk$lookup_object_specific(
	object : integer;
	var constraint : $object_ptr;
	var context : $context_block;
	var object_ptr : $object_ptr;
	var list : boolean) : boolean;

var	error : boolean;
begin
	list:=false; error:=false;
	case (object) of
	zk$obj_all:
	  begin
		list:=true;
		if (constraint<>nil) then object_ptr:=constraint^.contents
		else
		  begin
			$message(zk$text_default_contents);
			object_ptr:=
				context.room[context.location].room^.contents;
		  end;
	  end;
	zk$obj_possessions:
	  begin
		list:=true;
		object_ptr:=context.self^.contents;
	  end;
	zk$obj_contents:
	  begin
		list:=true;
		object_ptr:=context.room[context.location].room^.contents;
	  end;
	zk$obj_self:
		object_ptr:=context.self;
	zk$obj_current_room:
		object_ptr:=context.room[context.location].room;
	zk$obj_building_lights:
		if ( (context.location=zk$room_pad) or
			(context.location=zk$room_woods) or
			(context.location=zk$room_clearing) or
			(context.location=zk$room_entrance) ) then
				error:=true
		else	object_ptr:=context.lights_ptr;
	zk$obj_arm:
		object_ptr:=context.arm_ptr;
	otherwise
	  begin
		if (constraint<>nil) then
			error:=zk$lookup_object_list(object,
					constraint, object_ptr)
		else
		  begin
			error:=zk$lookup_object_list(object, context.self,
					object_ptr);
			if (error) then
				error:=zk$lookup_object_list(object,
					context.room[context.location].room,
					object_ptr);
		  end;
	  end
	end;

	if (object_ptr=nil) then error:=true;

	zk$lookup_object_specific:=error;
end;

[global] function zk$lookup_object(
	var object : integer;
	constraint : $object_ptr;
	var context : $context_block;
	var object_ptr : $object_ptr;
	var list : boolean) : boolean;

var	atleast_one, ambiguous, error : boolean;
	j, i, count : integer;
	flags, detail : unsigned;
	where, name : varying[31] of char;
	info : packed array[1..16] of $ubyte;
	object_name : array[1..16] of varying[31] of char;
	object_found : packed array[1..16] of boolean;
begin
	$get_object_info(zk$obj_table, object, detail, name,
				flags, count, info);

	if (uand(flags,1)=0) then	(* if not generic *)
	  begin
		error:=zk$lookup_object_specific(object, constraint,
				context, object_ptr, list);
		ambiguous:=false; atleast_one:=not error;
	  end
	else
	  begin
		atleast_one:=false; ambiguous:=false;
		for i:=1 to count do
		  begin
			object_found[i]:=false;
			error:=zk$lookup_object_specific(info[i], constraint,
					context, object_ptr, list);
			if (not error) then
			  begin
				object_found[i]:=true;
				if (atleast_one) then ambiguous:=true;
				atleast_one:=true;
				$get_object_info(zk$obj_table,
					object_ptr^.number, detail,
					object_name[i]);
			  end;
		  end;
	  end;

	error:=true;
	if (atleast_one) then
	  begin
		if (ambiguous) then
		  begin
			$message(zk$text_which_mean, 2,
				name.length, iaddress(name.body));
			for i:=1 to count do
				if (object_found[i]) then
					$message_indent(3, zk$text_the_text,
						2, object_name[i].length,
						iaddress(object_name[i].body));
		  end
		else	error:=false;
	  end
	else
	  begin
		if (constraint=nil) then
			$message(zk$text_no_objects_here, 2,
					name.length, iaddress(name.body))
		else
		  begin
			$get_object_info(zk$obj_table,
				constraint^.number, detail, where);
			if (not constraint^.flags.open) then
				$message(zk$text_closed_object, 2,
					where.length, iaddress(where.body))
			else
			if (constraint^.flags.cognizant) then
				$message(zk$text_no_objects_carried, 4,
					where.length, iaddress(where.body),
					name.length, iaddress(name.body))
			else
				$message(zk$text_no_objects_in, 4,
					name.length, iaddress(name.body),
					where.length, iaddress(where.body));
		  end
	  end;

	zk$lookup_object:=error;
end;

[global] function zk$disconnect_object(
	var object_ptr : $object_ptr) : boolean;

var	p, n : $object_ptr;
	actual_volume, i : integer;
	error, done : boolean;
begin
	n:=object_ptr^.owner^.contents;

	done:=false; p:=nil;
	while ( (n<>nil) and (not done) ) do
		if (object_ptr^.number<n^.number) then
		  begin
			p:=n; n:=n^.next;
		  end
		else	done:=true;

	if (done) then error:=(n^.number<>object_ptr^.number)
	else
		error:=false;

	if (not error) then
	  begin
		if (p=nil) then
			object_ptr^.owner^.contents:=object_ptr^.next
		else	p^.next:=object_ptr^.next;

		object_ptr^.next:=nil;

		n:=object_ptr^.owner;
		if (not object_ptr^.flags.inside) then
			n^.remaining_area:=n^.remaining_area +
				object_ptr^.fixed_size;
		repeat
		  begin
			n^.total_mass:=n^.total_mass - object_ptr^.total_mass;
			n:=n^.owner;
		  end
		until	n=nil;

		if (object_ptr^.flags.inside) then
		  begin
			if (object_ptr^.flags.flexible) then
				actual_volume:=object_ptr^.fixed_volume -
					object_ptr^.remaining_capacity
			else	actual_volume:=object_ptr^.fixed_volume;

			n:=object_ptr^.owner;
			while (n<>nil) do
			  begin
				n^.remaining_capacity:=n^.remaining_capacity +
						actual_volume;
				if (n^.flags.flexible) then n:=n^.owner
				else	n:=nil;
			  end;
		  end;
	  end
	else	$message(zk$text_bugcheck);

	zk$disconnect_object:=error;
end;

[global] function zk$connect_object(
	var object_ptr : $object_ptr;
	var owner : $object_ptr;
	inside : boolean) : boolean;

var	p, n : $object_ptr;
	actual_volume, i : integer;
	error, done : boolean;
begin
	n:=owner^.contents;

	done:=false; p:=nil;
	while ( (n<>nil) and (not done) ) do
		if (object_ptr^.number<n^.number) then
		  begin
			p:=n; n:=n^.next;
		  end
		else	done:=true;

	if (done) then error:=(n^.number=object_ptr^.number)
	else
		error:=false;

	if (not error) then
	  begin
		object_ptr^.next:=n;
		object_ptr^.owner:=owner;
		object_ptr^.flags.inside:=inside;
		if (p=nil) then
			owner^.contents:=object_ptr
		else	p^.next:=object_ptr;

		n:=owner;
		if (not inside) then
			n^.remaining_area:=n^.remaining_area -
					object_ptr^.fixed_size;
		repeat
		  begin
			n^.total_mass:=n^.total_mass + object_ptr^.total_mass;
			n:=n^.owner;
		  end
		until	n=nil;

		if (inside) then
		  begin
			if (object_ptr^.flags.flexible) then
				actual_volume:=object_ptr^.fixed_volume -
					object_ptr^.remaining_capacity
			else	actual_volume:=object_ptr^.fixed_volume;

			n:=owner;
			while (n<>nil) do
			  begin
				n^.remaining_capacity:=n^.remaining_capacity -
						actual_volume;
				if (n^.flags.flexible) then n:=n^.owner
				else	n:=nil;
			  end;
		  end;
	  end
	else	$message(zk$text_bugcheck);

	zk$connect_object:=error;
end;

function test_strength(
	var object1_ptr : $object_ptr;
	var name1 : varying[$u1] of char;
	var object2_ptr : $object_ptr;
	var name2 : varying[$u2] of char) : boolean;

var	error : boolean;
	n : $object_ptr;
	total : integer;
begin
	error:=false;
	n:=object2_ptr;
	while ( (not error) and (n<>nil) ) do
	  begin
		if (not n^.flags.strength_infinite) then
		  begin
			if (n^.strength=0) then
			  begin
				error:=true;
				$message(zk$text_text_no_strength, 4,
					name1.length, iaddress(name1.body),
					name2.length, iaddress(name2.body));
			  end
			else
			  begin
				total:=n^.total_mass + object1_ptr^.total_mass;
				if ( total > n^.strength) then
				  begin
					error:=true;
					$message(zk$text_too_much_mass, 4,
						name1.length,
						iaddress(name1.body),
						name2.length,
						iaddress(name2.body));
				  end;
			  end;
		  end;
		n:=n^.owner;
	  end;

	test_strength:=error;
end;

function test_expansion(
	var object1_ptr : $object_ptr;
	var name1 : varying[$u1] of char;
	var actual_volume : integer;
	var object2_ptr : $object_ptr;
	var name2 : varying[$u2] of char) : boolean;

var	error : boolean;
	n : $object_ptr;
	detail : unsigned;
	name3 : varying[31] of char;
begin
	error:=false;
	n:=object2_ptr^.owner;
	while (n<>nil) do
	  begin
		if ( (not n^.flags.capacity_infinite) and
		     (actual_volume > n^.remaining_capacity) ) then
		  begin
			error:=true;
			$get_object_info(zk$obj_table, n^.number,
				detail, name3);
			$message(zk$text_cant_expand, 6,
				   name1.length, iaddress(name1.body),
				   name2.length, iaddress(name2.body),
				   name3.length, iaddress(name3.body));
		  end;
		if (n^.flags.flexible) then n:=n^.owner
		else n:=nil;
	  end;

	test_expansion:=error;
end;

[global] function zk$test_insertion(
	var object1_ptr : $object_ptr;
	var name1 : varying[$u1] of char;
	var object2_ptr : $object_ptr;
	var name2 : varying[$u2] of char) : boolean;

var	error : boolean;
	actual_volume : integer;
	n : $object_ptr;
begin
	error:=false;
	if (not object2_ptr^.flags.capacity_infinite) then
	  begin
		if (object2_ptr^.flags.no_capacity) then
		  begin
			error:=true;
			$message(zk$text_text_no_capacity, 4,
				name1.length, iaddress(name1.body),
				name2.length, iaddress(name2.body))
		  end
		else
		  begin
			if (object1_ptr^.flags.flexible) then
				actual_volume:=object1_ptr^.fixed_volume -
					object1_ptr^.remaining_capacity
			else	actual_volume:=object1_ptr^.fixed_volume;

			if (actual_volume>object2_ptr^.remaining_capacity) then
			  begin
				error:=true;
				if (object2_ptr^.flags.cognizant) then
					$message(zk$text_cant_carry, 4,
					name2.length, iaddress(name2.body),
					name1.length, iaddress(name1.body))
				else
					$message(zk$text_too_much_volume, 4,
					name2.length, iaddress(name2.body),
					name1.length, iaddress(name1.body));
			  end
			else
			if (object2_ptr^.flags.flexible) then
				error:=test_expansion(object1_ptr, name1,
						actual_volume,
						object2_ptr, name2);
		  end;
	  end;
	zk$test_insertion:=error;
end;

[global] function zk$test_disconnect(
	var object1_ptr, object2_ptr : $object_ptr;
	inside : boolean) : boolean;

var	error : boolean;
	message, detail : unsigned;
	n : $object_ptr;
	name1, name2 : varying[31] of char;
begin
	$get_object_info(zk$obj_table, object1_ptr^.number, detail, name1);
	$get_object_info(zk$obj_table, object2_ptr^.number, detail, name2);

	error:=false;
	if (object1_ptr^.flags.cognizant) then
	  begin
		error:=true;
		$message(zk$text_keep_off, 2,
				name1.length, iaddress(name1.body));
	  end
	else
	if (object1_ptr^.flags.static) then
	  begin
		error:=true;
		$message(zk$text_object_fixed, 2,
				name1.length, iaddress(name1.body));
	  end
	else
	if ( (object1_ptr^.owner^.number=object2_ptr^.number) and
		(object1_ptr^.flags.inside=inside) and
		(object2_ptr^.number<>zk$obj_current_room) ) then
	  begin
		error:=true;
		$message(zk$text_already_there);
	  end
	else
	if (inside) then
	  begin
		if (not object2_ptr^.flags.open) then
		  begin
			error:=true;
			$message(zk$text_closed_failure, 4,
					name1.length, iaddress(name1.body),
					name2.length, iaddress(name2.body));
		  end
		else	error:=zk$test_insertion(object1_ptr, name1,
						object2_ptr, name2);
	  end
	else
	  begin
		if ( (object2_ptr^.number=zk$obj_self) and
			(object1_ptr^.number<>zk$obj_badge) ) then
		  begin
			error:=true;
			$message(zk$text_cant_wear_object, 2,
				name1.length, iaddress(name1.body));
		  end
		else
		if (not object2_ptr^.flags.area_infinite) then
		  begin
			if (object2_ptr^.flags.no_area) then
			  begin
				error:=true;
				$message(zk$text_text_no_area, 4,
					name1.length, iaddress(name1.body),
					name2.length, iaddress(name2.body));
			  end
			else
			if (object1_ptr^.fixed_size >
				object2_ptr^.remaining_area) then
			  begin
				error:=true;
				if (object2_ptr^.flags.cognizant) then
					$message(zk$text_cant_wear, 4,
					name2.length, iaddress(name2.body),
					name1.length, iaddress(name1.body))
				else
					$message(zk$text_too_much_size, 4,
					name2.length, iaddress(name2.body),
					name1.length, iaddress(name1.body));
			  end;
		  end;
	  end;

	n:=object2_ptr;
	while ( (n<>nil) and (not error) ) do
		if (object1_ptr^.number=n^.number) then
		  begin
			error:=true;
			if (inside) then
				message:=zk$text_inside_itself
			else	message:=zk$text_on_itself;
			$message(message,2,name1.length,iaddress(name1.body));
		  end
		else	n:=n^.owner;

	if (not error) then
	  begin
		zk$disconnect_object(object1_ptr);

		error:=test_strength(object1_ptr, name1, object2_ptr, name2);

		if (error) then
			zk$connect_object(object1_ptr,
				object1_ptr^.owner, object1_ptr^.flags.inside);
	  end;

	zk$test_disconnect:=error;
end;

[global] function zk$list_contents(
	owner : $object_ptr;
	indent : integer;
	inside : boolean;
	list_static : boolean) : boolean;

var	state_present : boolean;
	object_ptr : $object_ptr;
	message, detail : unsigned;
	owner_name, name : varying[31] of char;
begin
	$get_object_info(zk$obj_table, owner^.number, detail, owner_name);

	state_present:=false;
	if ( (inside) and (not owner^.flags.open) ) then
		object_ptr:=nil
	else	object_ptr:=owner^.contents;

	while ( (object_ptr<>nil) and (not state_present)) do
	  begin
		if ( (object_ptr^.flags.inside=inside) and
		     ( (list_static) or (not object_ptr^.flags.static) ) ) then
			state_present:=true
		else	object_ptr:=object_ptr^.next;
	  end;

	if (state_present) then
	  begin
		if (owner^.flags.cognizant) then
		  begin
			if (inside) then
				message:=zk$text_being_carried
			else	message:=zk$text_being_worn;
		  end
		else
		if (owner^.flags.room) then
		  begin
			if (inside) then
				message:=zk$text_contained_in
			else	message:=zk$text_sitting_on_wall;
		  end
		else
		  begin
			if (inside) then
				message:=zk$text_contained_in
			else	message:=zk$text_sitting_on;
		  end;
		$message_indent(indent, message, 2,
			owner_name.length, iaddress(owner_name.body));
(*		$message(zk$text_attributes, 6,
			owner^.total_mass, owner^.strength,
			owner^.fixed_volume, owner^.remaining_capacity,
			owner^.fixed_size, owner^.remaining_area);*)

		object_ptr:=owner^.contents;
		while (object_ptr<>nil) do
		  begin
			if ( (object_ptr^.flags.inside=inside) and
			     ( (list_static) or
				(not object_ptr^.flags.static) ) ) then
			  begin
				$get_object_info(zk$obj_table,
					object_ptr^.number, detail, name);
				if ( (name[name.length]='s') and
				     (name[name.length-1]<>'s') ) then
					message:=zk$text_some_text
				else
				if (name[1] in vowels) then
					message:=zk$text_an_text
				else	message:=zk$text_a_text;
				$message_indent(indent+4, message, 2,
					name.length, iaddress(name.body));
(*		$message(zk$text_attributes, 6,
			object_ptr^.total_mass, object_ptr^.strength,
			object_ptr^.fixed_volume,object_ptr^.remaining_capacity,
			object_ptr^.fixed_size, object_ptr^.remaining_area); *)

				zk$list_contents(object_ptr, indent+4,
						true, list_static);
				zk$list_contents(object_ptr, indent+4,
						false, list_static);
			  end;
			object_ptr:=object_ptr^.next;
		  end;
	    end;

	zk$list_contents:=not state_present;
end;

[global] procedure zk$list_contents_empty(
	owner : $object_ptr;
	indent : integer);

var	empty : boolean;
	message, detail : unsigned;
	owner_name : varying[31] of char;
begin
	$get_object_info(zk$obj_table, owner^.number, detail, owner_name);

	empty:=zk$list_contents(owner, indent, true, true);
	if (empty) then
	  begin
		if ( (owner^.flags.openable) and (not owner^.flags.open) ) then
			$message_indent(indent, zk$text_closed_object, 2,
				owner_name.length, iaddress(owner_name.body))
		else
		if (not owner^.flags.no_capacity) then
		  begin
			if (owner^.flags.cognizant) then
				message:=zk$text_nothing_carried
			else	message:=zk$text_not_contained_in;
			$message_indent(indent, message, 2,
				owner_name.length, iaddress(owner_name.body));
		  end;
	  end;

	empty:=zk$list_contents(owner, indent, false, true);
	if (empty) then
	  begin
		if (not owner^.flags.no_area) then
		  begin
			if (owner^.flags.cognizant) then
				message:=zk$text_nothing_worn
			else	message:=zk$text_not_sitting_on;
			$message_indent(indent, message, 2,
				owner_name.length, iaddress(owner_name.body));
		  end;
	  end;
end;

[global] procedure zk$describe_room_contents(owner : $object_ptr);
var	message, detail : unsigned;
	name : varying[31] of char;
	object_ptr : $object_ptr;
begin
	object_ptr:=owner^.contents;
	while (object_ptr<>nil) do
	  begin
		if (object_ptr^.flags.static) then
		  begin
			zk$list_contents(object_ptr, 1, true, false);
			zk$list_contents(object_ptr, 1, false, false);
		  end;

		object_ptr:=object_ptr^.next;
	  end;

	object_ptr:=owner^.contents;
	while (object_ptr<>nil) do
	  begin
		$get_object_info(zk$obj_table, object_ptr^.number,
					detail, name);

		if (not object_ptr^.flags.static) then
		  begin
			if ( (name[name.length]='s') and
			     (name[name.length-1]<>'s') ) then
				message:=zk$text_some_objects_here
			else
			if (name[1] in vowels) then
				message:=zk$text_an_object_here
			else	message:=zk$text_a_object_here;

			$message(message, 2, name.length, iaddress(name.body));

			zk$list_contents(object_ptr, 1, true, true);
			zk$list_contents(object_ptr, 1, false, true);
		  end;

		object_ptr:=object_ptr^.next;
	  end;
end;

[global] function zk$create_object_info(
	object_number : integer;
	var flags : unsigned;
	var info : packed array[$l1..$u1:integer] of $ubyte) : $object_ptr;

var	c : $object_ptr;
begin
	new(c);
	c^.number:=object_number;

	c^.flags.long:=flags;
	c^.flags.no_capacity:=(info[3]=0) and (not c^.flags.capacity_infinite);
	c^.flags.no_area:=(info[4]=0) and (not c^.flags.area_infinite);
	c^.flags.open:=not c^.flags.openable;
	c^.flags.locked:=c^.flags.lockable;

	c^.total_mass:=info[5]; c^.strength:=info[2];
	c^.remaining_capacity:=info[3]; c^.fixed_volume:=info[6];
	c^.remaining_area:=info[4]; c^.fixed_size:=info[7];

	c^.contents:=nil;
	c^.link:=nil; c^.owner:=nil; c^.next:=nil;
	zk$create_object_info:=c;
end;

[global] function zk$create_object(object_number : integer) : $object_ptr;
var	detail, flags : unsigned;
	count : integer;
	info : packed array[1..16] of $ubyte;
	name : varying[31] of char;
begin
	$get_object_info(zk$obj_table, object_number, detail,
				name, flags, count, info);

	zk$create_object:=zk$create_object_info(object_number, flags, info);
end;

[global] function zk$test_retreival(
	var context : $context_block;
	object_number : integer;
	var object_ptr : $object_ptr) : boolean;
var	list, error : boolean;
	detail : unsigned;
	name : varying[31] of char;
begin
	error:=zk$lookup_object(object_number, nil, context, object_ptr, list);

	if (not error) then
	  begin
		$get_object_info(zk$obj_table, object_number, detail, name);
		if (not object_ptr^.flags.open) then
		  begin
			error:=true;
			$message(zk$text_closed_object, 2,
				name.length, iaddress(name.body));
		  end
		else
		if (object_ptr^.contents=nil) then
		  begin
			error:=true;
			if ( (object_ptr^.flags.no_capacity) and
				(object_ptr^.flags.no_area) ) then
				$message(zk$text_no_capacity, 2,
					name.length, iaddress(name.body))
			else
			if (object_ptr^.flags.no_area) then
				$message(zk$text_not_contained_in, 2,
					name.length, iaddress(name.body))
			else
				$message(zk$text_not_sitting_on, 2,
					name.length, iaddress(name.body));
		  end;
	  end;

	zk$test_retreival:=error;
end;

[global] function zk$probe_ownership(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var object_ptr : $object_ptr;
	var name : varying[$u2] of char) : boolean;

var	error : boolean;
	detail : unsigned;
	n : $object_ptr;
	owner_name : varying[31] of char;
begin
	n:=object_ptr^.owner; error:=false;
	while ( (not error) and (n<>nil) ) do
	  begin
		if ( (n^.flags.cognizant) and
			(n^.number<>actor_ptr^.number) ) then
		  begin
			error:=true;
			$get_object_info(zk$obj_table, n^.number,
						detail, owner_name);
			$message(zk$text_doesnt_belong, 6,
					owner_name.length,
					iaddress(owner_name.body),
					actor_name.length,
					iaddress(actor_name.body),
					name.length, iaddress(name.body));
		  end
		else	n:=n^.owner;
	  end;

	zk$probe_ownership:=error;
end;

[global] function zk$room_dark(var context : $context_block) : boolean;
var	not_found, is_dark : boolean;
	lamp : integer;
	lamp_ptr, room : $object_ptr;
begin
	is_dark:=false; lamp:=zk$obj_lamp;
	room:=context.room[context.location].room;
	if (not room^.flags.on) then
	  begin
		not_found:=zk$lookup_object_list(lamp, room, lamp_ptr);
		if (not_found) then
			not_found:=zk$lookup_object_list(
					lamp, context.self, lamp_ptr);
		if (not_found) then is_dark:=true
		else
		if ( (not lamp_ptr^.flags.on) or
			(context.lamp_remaining=0) ) then is_dark:=true;
	  end;

	zk$room_dark:=is_dark;
end;

end.

