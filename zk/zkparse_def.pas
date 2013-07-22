[inherit('lib$:zk$def',
	 'lib$:zk$context_def')]
module zk$parse_def;

[external(zk$parse_command_line)] function $parse_command_line(
        var context : $context_block;
	var ast : $ast_node_ptr;
	followers : $symbol_set) : boolean;
	extern;

end.
