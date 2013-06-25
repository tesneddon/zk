[inherit('lib$:zk$def')]
module zk$parse_obj_def;

[external(zk$test_symbol)] function $test_symbol(
	expected : $symbol_set) : boolean;
	extern;

[external(zk$parse_object)] function $parse_object(
	var ast : $ast_node_ptr;
	followers : $symbol_set) : boolean;
	extern;

[external(zk$parse_object_list)] function $parse_object_list(
	var ast : $ast_node_ptr;
	var verb : varying[$u1] of char;
	followers : $symbol_set) : boolean;
	extern;

end.
