[inherit('lib$:zk$context_def')]
module zk$wizard_def;

[weak_external(zk$edswbl_goto_room)] function $edswbl_goto_room(
	var context : $context_block;
	var room_number : integer) : boolean;
	extern;

[weak_external(zk$edswbl_take_object)] function $edswbl_take_object(
	var context : $context_block;
	var object_number : integer) : boolean;
	extern;

[weak_external(zk$edswbl_wait)] function $edswbl_wait(
	var context : $context_block) : boolean;
	extern;

[weak_external(zk$edswbl_keypad)] function $edswbl_keypad(
	var context : $context_block) : boolean;
	extern;

[weak_external(zk$edswbl_where)] function $edswbl_where(
	var context : $context_block) : boolean;
	extern;

[weak_external(zk$edswbl_nurse)] function $edswbl_nurse(
	var context : $context_block) : boolean;
	extern;

[weak_external(zk$edswbl_system)] function $edswbl_system(
	var context : $context_block) : boolean;
	extern;
end.
