[inherit('lib$:typedef',
	 'lib$:rtldef',
	 'lib$:smgdef',
	 'lib$:sysdef',
	 'lib$:zk$def',
	 'lib$:zk$context_def',
	 'lib$:zk$parse_def', 'lib$:zk$lex_def', 'lib$:zk$ast_def',
	 'lib$:zk$text',
	 'lib$:zk$action_def', 'lib$:zk$init_def',
	 'ifc$library:ifc$rtl_def')]
program zk$main;

[unbound, asynchronous] procedure broadcast_handler(
	var context : $context_block);
begin
	context.flags.messages_pending:=true;
end;

[asynchronous] function message_routine(
	var message : $uquad) : unsigned;
begin
	$message(zk$text_text_error, 1, iaddress(message));
	message_routine:=0;
end;

[asynchronous] function condition_handler(
	var signal : $signal_arg_vector;
	var mech : $mech_arg_vector) : unsigned;
begin
	if (signal[1]<>ss$_unwind) then
	  begin
		signal[0]:=signal[0]-2;
		signal[0]:=uor(signal[0],%x00010000);

		if (uand(signal[1],7)=4) then
		  begin
			$message(zk$text_failure);
			$putmsg(signal, message_routine);
			$unwind;
		  end
		else
		  begin
			$message(zk$text_warning);
			$putmsg(signal, message_routine);
			$message(0);
			condition_handler:=ss$_continue;
		  end;
	  end;
end;

function interact(var context : $context_block) : unsigned;
var	return : unsigned;
	ast : $ast_node_ptr;
	error : boolean;
	self_name : varying[4] of char;
begin
	self_name:='self';

	establish(condition_handler);

	$update_status_numbers(context.score, context.moves);

	return:=$init_lex;
	if (odd(return)) then
	  begin
		error:=$parse_command_line(ast, [end_of_line]);
		if ( (not error) and (ast<>nil) ) then
		  begin
(*			$print_ast(ast, 1); *)
			$dispatch_command(context,context.self,self_name,ast);
		  end;
		$dispose_ast(ast);
		if (context.flags.messages_pending) then
		  begin
			if (context.room[context.location].class=2) then
				$message(0,0,zk$text_broadcast_outside)
			else	$message(0,0,zk$text_broadcast_inside);
			return:=$output_broadcast_messages;
			if (not odd(return)) then $signal(return);
			context.flags.messages_pending:=false;
		  end;
	  end
	else	$quit(context, context.self, self_name);
	interact:=return;
end;

procedure main;
var	context : $context_block;
	return : unsigned;
begin
	return:=$init_screen('ZK$KEY_DEF',broadcast_handler,iaddress(context));
	if (not odd(return)) then $signal(return)
	else
	  begin
		$initialize(context);
		return:=1;
		while ( (not context.flags.won) and
			(not context.flags.died) and
			(not context.flags.quit) ) do interact(context);

		if (context.flags.won) then
			$message(0, 0, zk$text_player_won)
		else
		if (context.flags.died) then
			$message(0, 0, zk$text_player_died);

		$message(0); $score(context); $message(0);

		return:=$finish_screen;
		if (not odd(return)) then $signal(return);
	  end;
end;

begin
	main;
end.
