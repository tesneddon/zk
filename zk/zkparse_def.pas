[inherit('lib$:zk$def')]
module zk$parse_def;

[external(zk$parse_command_line)] function $parse_command_line(
	var ast : $ast_node_ptr;
	folloers : $symbol_set) : boolean;
	extern;

end.
