[inherit('lib$:zk$context_def')]
module zk$init_def;

[external(zk$initialize)] procedure $initialize(
	var context : $context_block);
	extern;

[external(zk$restart_game)] function $restart_game(
	var context : $context_block) : boolean;
	extern;

[external(zk$save_game)] function $save_game(
	var context : $context_block;
	var filename : varying[$u1] of char) : boolean;
	extern;

[external(zk$restore_game)] function $restore_game(
	var context : $context_block;
	var filename : varying[$u1] of char) : boolean;
	extern;

end.
