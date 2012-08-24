[inherit('lib$:typedef',
	 'lib$:zk$context_def')]
module zk$routines_def;

[external(zk$random_integer)] function $random_integer(
	var seed : unsigned;
	upper : integer) : integer;
	extern;

[external(zk$compare_date)] function $compare_date(
	var start, finish : $uquad) : integer;
	extern;

[external(zk$room_dark)] function $room_dark(
	var context : $context_block) : boolean;
	extern;

[external(zk$lookup_object_inside)] function $lookup_object_inside(
	var object : integer;
	var constraint : $object_ptr;
	var object_ptr : $object_ptr) : boolean;
	extern;

[external(zk$lookup_object_list)] function $lookup_object_list(
	var object : integer;
	var constraint : $object_ptr;
	var object_ptr : $object_ptr) : boolean;
	extern;

[external(zk$lookup_object_specific)] function $lookup_object_specific(
	object : integer;
	var constraint : $object_ptr;
	var context : $context_block;
	var object_ptr : $object_ptr;
	var list : boolean) : boolean;
	extern;

[external(zk$lookup_object)] function $lookup_object(
	var object : integer;
	constraint : $object_ptr;
	var context : $context_block;
	var object_ptr : $object_ptr;
	var list : boolean) : boolean;
	extern;

[external(zk$disconnect_object)] function $disconnect_object(
	var object_ptr : $object_ptr) : boolean;
	extern;

[external(zk$connect_object)] function $connect_object(
	var object_ptr : $object_ptr;
	var owner : $object_ptr;
	inside : boolean) : boolean;
	extern;

[external(zk$test_disconnect)] function $test_disconnect(
	var object1_ptr, object2_ptr : $object_ptr;
	inside : boolean) : boolean;
	extern;

[external(zk$test_insertion)] function $test_insertion(
	var object1_ptr : $object_ptr;
	var name1 : varying[$u1] of char;
	var object2_ptr : $object_ptr;
	var name2 : varying[$u2] of char) : boolean;
	extern;

[external(zk$list_contents)] function $list_contents(
	owner : $object_ptr;
	indent : integer;
	inside : boolean;
	list_static : boolean) : boolean;
	extern;

[external(zk$list_contents_empty)] procedure $list_contents_empty(
	owner : $object_ptr;
	indent : integer);
	extern;

[external(zk$describe_room_contents)] procedure $describe_room_contents(
	owner : $object_ptr);
	extern;

[external(zk$create_object_info)] function $create_object_info(
	object_number : integer;
	var flags : unsigned;
	var info : packed array[$l1..$u1:integer] of $ubyte) : $object_ptr;
	extern;

[external(zk$create_object)] function $create_object(
	object_number : integer) : $object_ptr;
	extern;

[external(zk$dispose_object)] procedure $dispose_object(
	var object_ptr : $object_ptr);
	extern;
 
[external(zk$test_retreival)] function $test_retreival(
	var context : $context_block;
	object_name : integer;
	var object_ptr : $object_ptr) : boolean;
	extern;

[external(zk$probe_ownership)] function $probe_ownership(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var object_ptr : $object_ptr;
	var object_name : varying[$u2] of char) : boolean;
	extern;

end.
