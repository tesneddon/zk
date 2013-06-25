[inherit('lib$:zk$def')]
module zk$lex_def;

[external(zk$init_lex)] function $init_lex : unsigned;
	extern;

[external(zk$advance_symbol)] procedure $advance_symbol;
	extern;

[external(zk$get_symbol)] procedure $get_symbol(
	var symbol : $symbol_desc);
	extern;

end.
