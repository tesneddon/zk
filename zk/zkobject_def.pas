[inherit('lib$:zk$context_def')]
module zk$object_def;

[external(zk$stand_object)] function $stand_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_ptr : $object_ptr;
	var name : varying[$u2] of char;
	on : boolean) : boolean;
	extern;

[external(zk$move_object)] function $move_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_ptr : $object_ptr;
	var object_name : varying[$u2] of char) : boolean;
	extern;

[external(zk$look_in_object)] function $look_in_object(
	var context : $context_block;
	object_ptr : $object_ptr;
	var name : varying[$u1] of char) : boolean;
	extern;

[external(zk$locate_object)] function $locate_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_number : integer) : boolean;
	extern;

[external(zk$examine_object)] function $examine_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_ptr : $object_ptr;
	var name : varying[$u2] of char;
	var list : boolean;
	var detail : unsigned) : boolean;
	extern;

[external(zk$inventory_object)] function $inventory_object(
	var context : $context_block;
	object_ptr : $object_ptr;
	var name : varying[$u1] of char) : boolean;
	extern;

[external(zk$read_object)] function $read_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_ptr : $object_ptr;
	var name : varying[$u2] of char;
	var detail : unsigned) : boolean;
	extern;

[external(zk$boot_object)] function $boot_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_ptr : $object_ptr;
	var name : varying[$u2] of char) : boolean;
	extern;

[external(zk$shake_object)] function $shake_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_ptr : $object_ptr;
	var name : varying[$u2] of char) : boolean;
	extern;

[external(zk$drink_object)] function $drink_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object_ptr : $object_ptr;
	var name : varying[$u2] of char) : boolean;
	extern;

(* Commands with two objects *)

[external(zk$put_object)] function $put_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char;
	inside : boolean;
	success_message : unsigned) : boolean;
	extern;

[external(zk$give_object)] function $give_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char) : boolean;
	extern;

[external(zk$open_object)] function $open_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char) : boolean;
	extern;

[external(zk$close_object)] function $close_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char) : boolean;
	extern;

[external(zk$lock_unlock_object)] function $lock_unlock_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char;
	lock : boolean) : boolean;
	extern;

[external(zk$start_stop_object)] function $start_stop_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char;
	start : boolean) : boolean;
	extern;

[external(zk$heal_kill_object)] function $heal_kill_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char;
	heal : boolean) : boolean;
	extern;

[external(zk$rub_object)] function $rub_object(
	var context : $context_block;
	actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	object1_ptr : $object_ptr;
	var name1 : varying[$u2] of char;
	object2_ptr : $object_ptr;
	var name2 : varying[$u3] of char) : boolean;
	extern;
end.
