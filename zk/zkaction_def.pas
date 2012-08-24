[inherit('lib$:zk$context_def')]
module zk$action_def;

(* Commands with no objects *)

[external(zk$score)] procedure $score(
	var context : $context_block);
	extern;

[external(zk$advance_clock)] function $advance_clock(
	var context : $context_block) : boolean;
	extern;

[external(zk$describe_room)] function $describe_room(
	var context : $context_block;
	room : integer;
	seen_room : boolean;
	brief : boolean) : boolean;
	extern;

[external(zk$version)] function $version : boolean;
	extern;

[external(zk$hello)] function $hello(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var name : varying[$u1] of char) : boolean;
	extern;

[external(zk$wait)] function $wait(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var name : varying[$u1] of char) : boolean;
	extern;

[external(zk$quit)] function $quit(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var name : varying[$u1] of char) : boolean;
	extern;

[external(zk$say_string)] function $say_string(
	var context : $context_block;
	var string : varying[$u1] of char) : boolean;
	extern;

[external(zk$lookup_string)] function $lookup_string(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var string : varying[$u2] of char) : boolean;
	extern;

[external(zk$move_direction)] function $move_direction(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	direction : integer;
	object_ptr : $object_ptr;
	var name : varying[$u2] of char) : boolean;
	extern;

[external(zk$type_number)] function $type_number(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	var number : integer) : boolean;
	extern;

[external(zk$install_object)] function $install_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char) : boolean;
	extern;

end.
