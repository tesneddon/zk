[inherit('lib$:zk$def','lib$:zk$context_def')]
module zk$ast_def;

[external(zk$print_ast)] procedure $print_ast(
	ast : $ast_node_ptr;
	i : integer);
	extern;

[external(zk$dispose_ast)] procedure $dispose_ast(
	ast : $ast_node_ptr);
	extern;

[external(zk$dispatch_command)] function $dispatch_command(
	var context : $context_block;
	var actor_ptr : $object_ptr;
	var actor_name : varying[$u1] of char;
	ast : $ast_node_ptr) : boolean;
	extern;
end.
