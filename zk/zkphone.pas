[inherit('lib$:typedef',
	 'lib$:rtldef',
	 'lib$:sysdef',
	 'lib$:zk$def',
	 'lib$:zk$context_def',
	 'lib$:zk$room', 'lib$:zk$obj', 'lib$:zk$routines_def',
	 'lib$:zk$parse_def', 'lib$:zk$lex_def', 'lib$:zk$ast_def',
	 'lib$:zk$text',
	 'lib$:zk$action_def', 'lib$:zk$init_def',
	 'ifc$library:ifc$rtl_def',
	 'ifc$library:ifc$rtl_phone_def'),
ident('X01.00-00')]
program zk$phone; (* ZK main program for the telephone *)

(* Edit History                                                             *)
(* 04-Nov-2026  TES  Original version.  Replaces ZK$MAIN in ZKPHONE.EXE:    *)
(*                   keypad commands instead of a command line.             *)
(* 09-Nov-2026  TES  ZKUAF.DAT record, lookup and dates, for passcodes.     *)
(* 09-Nov-2026  TES  Welcome, passcode prompt and new player menu, with     *)
(*                   ZK$PHONE_WELCOME and ZK$PHONE_INTRO.                   *)
(* 09-Nov-2026  TES  New players: a passcode, a record and a UID.  Each     *)
(*                   player plays in SYS$LOGIN:[.USERS.<uid>], with their   *)
(*                   name in ZK$MULTI_USER; logins are counted.             *)
(* 12-Nov-2026  TES  Passcodes use the RANDOM builtin, not MTH$RANDOM.      *)
(* 12-Nov-2026  TES  The locked safe and its keypad offer "type a number",  *)
(*                   passed to the game as TYPE and the digits.             *)
(* 12-Nov-2026  TES  "Say something" in the action menu, said or spelled on *)
(*                   the keypad, and passed to the game as SAY.             *)
(*                                                                          *)

const	save_name = 'PHONE';			(* one slot per player *)
	max_menu_objects = 32;
	uaf_name = 'SYS$LOGIN:ZKUAF.DAT';
	uaf_user_length = 64;
	phone_prefix = 'PHONE:';
	passcode_length = 6;
	max_passcode_tries = 3;
	max_new_passcode_tries = 10;
	new_player_lock = 'ZK$PHONE_NEW_PLAYER';

type	$menu_objects = record
			count : integer;
			ptr : array[1..max_menu_objects] of $object_ptr;
		end;

	(* ZKUAF.DAT record, as LOGIN.COM.  Key 0 is user+uid (100 bytes);
	 * we look up by user alone, a generic match, as LOGIN.COM does. *)
	$uaf_key = packed array[1..uaf_user_length] of char;
	$uaf_date = packed array[1..22] of char;   (* F$CVTIME comparison *)
	$uaf_record = packed record
			user : $uaf_key;
			uid : packed array[1..36] of char;
			hash : packed array[1..32] of char; (* blank for phone *)
			created : $uaf_date;
			last_login : $uaf_date;
			logins : packed array[1..10] of char; (* !10UL *)
			first_name : packed array[1..32] of char;
			last_name : packed array[1..32] of char;
			spare : packed array[1..262] of char;
		end;
	$uaf_file = file of $uaf_record;

	$login_result = (login_new, login_found, login_failed);
	$text_line = varying[255] of char;

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

(* Build what the parser would have built from a typed command *)
function command(
	keyword1 : $symbol_token;
	keyword2 : $symbol_token := nil_keyword) : $ast_node_ptr;

var	ast : $ast_node_ptr;
begin
	new(ast, command_node);
	ast^.node_type:=command_node; ast^.list:=nil;
	ast^.keyword1:=keyword1; ast^.keyword2:=keyword2;
	ast^.left:=nil; ast^.right:=nil; ast^.please:=false;
	command:=ast;
end;

procedure dispatch(
	var context : $context_block;
	ast : $ast_node_ptr);

var	self_name : varying[4] of char;
begin
	self_name:='self';
	$dispatch_command(context, context.self, self_name, ast);
	$dispose_ast(ast);
end;

(* Free text, for what the menus can't build as nodes: through the
 * lexer as zk$main does it *)
procedure free_text(
	var context : $context_block;
	line : varying[$u1] of char);

var	ast : $ast_node_ptr;
	error : boolean;
begin
	$phone_set_line(line);
	if (odd($init_lex)) then
	  begin
		error:=$parse_command_line(context, ast, [end_of_line]);
		if ( (not error) and (ast<>nil) ) then
			dispatch(context, ast)
		else	$dispose_ast(ast);
	  end;
end;

(* The phone's keypad is the safe's: TYPE and the digits, through the
 * parser as at a terminal, so the check, message and score are the
 * game's own.  Pound ends the number early; star gives up. *)
procedure type_number(var context : $context_block);
var	digits : varying[4] of char;
begin
	$phone_say('Key in the number.');
	if (odd($phone_get_digits(digits, 4))) then
		if (digits.length>0) then free_text(context, 'TYPE ' + digits);
end;

(* SAY, through the parser as at a terminal.  Spoken words are read back
 * first, since the recogniser can be wrong.  The game wants the words
 * run together, as the keypad gives them. *)
procedure say_something(var context : $context_block);
var	heard : varying[80] of char;
	word : varying[40] of char;
	key : char;
	i : integer;
	done : boolean;
begin
	done:=false; word:='';
	repeat
		$phone_say('Press 1 to say it, 2 to spell it, or star to go back.');
		key:=$phone_get_key;
		if (key='1') then
		  begin
			$phone_say('Say it after the tone.');
			$phone_get_heard(heard);
			if (heard.length=0) then
				$phone_say('Sorry, that was not clear.')
			else
			  begin
				$phone_say('I heard: ' + heard + '.  Press 1 to ' +
					   'say it, 2 to try again, or star to ' +
					   'go back.');
				key:=$phone_get_key;
				if (key='1') then
				  begin
					for i:=1 to heard.length do
						if ( (heard[i]<>' ') and
						     (word.length<40) ) then
							word:=word + heard[i];
					done:=true;
				  end
				else
				if (key<>'2') then done:=true;
			  end;
		  end
		else
		if (key='2') then
		  begin
			$phone_say('Spell it on the keypad: 2 once for A, twice ' +
				   'for B.  Pound when you are done, star to ' +
				   'rub out.');
			if (not odd($phone_get_spelled(word, 40))) then word:='';
			done:=true;
		  end
		else
		if (key='*') then done:=true;
	until done;
	if (word.length>0) then free_text(context, 'SAY "' + word + '"');
end;

(* "Exits: north, east and south west."  Nothing in the dark, and
 * nothing in a maze: there the player has to try, as at a terminal. *)
procedure say_exits(var context : $context_block);
var	link : packed array[1..14] of $ubyte;
	detail : unsigned;
	name : varying[31] of char;
	direction : [static] array[1..10] of varying[10] of char :=
		('north', 'south', 'east', 'west',
		 'north east', 'south west', 'south east', 'north west',
		 'up', 'down');
	exits : varying[132] of char;
	i, n, count : integer;
begin
	if ( (not $room_dark(context)) and
	     (context.room[context.location].class<>1) ) then
	  begin
		$get_room_info(zk$room_table, context.location, detail,
				name, link);
		count:=0;
		for i:=1 to 10 do
			if (link[i]<>0) then count:=count+1;

		if (count>0) then
		  begin
			exits:='Exits: '; n:=0;
			for i:=1 to 10 do
				if (link[i]<>0) then
				  begin
					n:=n+1;
					if (n>1) then
						if (n=count) then
							exits:=exits + ' and '
						else	exits:=exits + ', ';
					exits:=exits + direction[i];
				  end;
			$phone_say(exits + '.');
		  end;
	  end;
end;

procedure say_help;
begin
	$phone_say('The keypad is a compass.  2 is north, 8 is south, ' +
		'4 is west and 6 is east; the corner keys are the diagonals.  ' +
		'5 looks around, and pound repeats the exits.  ' +
		'0 opens the menu, and star goes back.');
end;

(* What the player could name, by the rule in zk$lookup_object_list:
 * nothing inside a closed container, nothing another character holds *)
procedure gather(
	owner : $object_ptr;
	skip : $object_ptr;
	var list : $menu_objects);

var	c : $object_ptr;
begin
	c:=owner^.contents;
	while (c<>nil) do
	  begin
		if ( (c<>skip) and
		     (not (c^.flags.inside and (not owner^.flags.open))) ) then
		  begin
			if (list.count<max_menu_objects) then
			  begin
				list.count:=list.count+1;
				list.ptr[list.count]:=c;
			  end;
			if (not c^.flags.cognizant) then gather(c, skip, list);
		  end;
		c:=c^.next;
	  end;
end;

(* An object, or nil on star *)
function choose_object(var list : $menu_objects) : $object_ptr;
var	prompt : varying[400] of char;
	name : varying[31] of char;
	detail : unsigned;
	first, last, i : integer;
	choice : $object_ptr;
	key : char;
	done : boolean;
begin
	first:=1; choice:=nil; done:=false;
	repeat
		last:=first+7;
		if (last>list.count) then last:=list.count;

		prompt:='';
		for i:=first to last do
		  begin
			$get_object_info(zk$obj_table, list.ptr[i]^.number,
						detail, name);
			prompt:=prompt + chr(ord('0')+i-first+1) +
					' for the ' + name + ', ';
		  end;
		if (last<list.count) then prompt:=prompt + '9 for more, ';
		$phone_say(prompt + 'or star to go back.');

		key:=$phone_get_key;
		if ( (key>='1') and (key<=chr(ord('0')+last-first+1)) ) then
		  begin
			choice:=list.ptr[first+ord(key)-ord('1')]; done:=true;
		  end
		else
		if ( (key='9') and (last<list.count) ) then first:=last+1
		else
		if (key='*') then done:=true;
	until done;
	choose_object:=choice;
end;

function verb_object(
	verb : $symbol_token;
	object_number : integer) : $ast_node_ptr;

var	ast : $ast_node_ptr;
begin
	ast:=command(verb);
	new(ast^.left, object_node);
	ast^.left^.node_type:=object_node; ast^.left^.list:=nil;
	ast^.left^.object_code:=object_number; ast^.left^.from:=0;
	verb_object:=ast;
end;

(* Offer only the verbs that fit the object *)
procedure object_menu(
	var context : $context_block;
	object_ptr : $object_ptr;
	carried : boolean);

var	verb : array[1..8] of $symbol_token;
	prompt : varying[255] of char;
	count, i : integer;
	key : char;
	done : boolean;

  procedure offer(v : $symbol_token; word : varying[$u1] of char);
  begin
	count:=count+1; verb[count]:=v;
	prompt:=prompt + chr(ord('0')+count) + ' to ' + word + ', ';
  end;

begin
	count:=0; prompt:='';
	with object_ptr^.flags do
	  begin
		if ( (not carried) and (not static) ) then
			offer(take_keyword, 'take');
		if (carried) then offer(drop_keyword, 'drop');
		offer(examine_keyword, 'examine');
		if (openable) then
			if (open) then offer(close_keyword, 'close')
			else	offer(open_keyword, 'open');
		if (lockable) then
			if (locked) then
			  begin
				if (object_ptr^.number=zk$obj_safe) then
					offer(type_keyword, 'type a number')
				else	offer(unlock_keyword, 'unlock');
			  end
			else	offer(lock_keyword, 'lock');
		if (object_ptr^.number=zk$obj_keypad) then
			offer(type_keyword, 'type a number');
		if (readable) then offer(read_keyword, 'read');
		if (startable) then
			if (on) then offer(stop_keyword, 'stop')
			else	offer(start_keyword, 'start');
	  end;
	prompt:=prompt + 'or star to go back.';

	done:=false;
	repeat
		$phone_say(prompt);
		key:=$phone_get_key;
		i:=ord(key)-ord('0');
		if ( (i>=1) and (i<=count) ) then
		  begin
			if (verb[i]=type_keyword) then
				type_number(context)
			else	dispatch(context, verb_object(verb[i],
							object_ptr^.number));
			done:=true;
		  end
		else
		if (key='*') then done:=true;
	until done;
end;

(* The action menu; returns when an item has been done, or on star.
 * Up and down are offered where they exist, and always in the dark or
 * in a maze, so the menu gives nothing away. *)
procedure action_menu(var context : $context_block);
var	link : packed array[1..14] of $ubyte;
	detail : unsigned;
	name : varying[31] of char;
	prompt : varying[255] of char;
	hidden, up, down, done : boolean;
	key : char;
	list : $menu_objects;
	object_ptr : $object_ptr;
begin
	$get_room_info(zk$room_table, context.location, detail, name, link);
	hidden:=( $room_dark(context) or
		  (context.room[context.location].class=1) );
	up:=( hidden or (link[9]<>0) );
	down:=( hidden or (link[10]<>0) );

	prompt:='1 for objects here, ';
	if (up) then prompt:=prompt + '2 for up, ';
	prompt:=prompt + '3 for inventory, 4 for score, 5 to save, ' +
			 '6 to restore, 7 to quit, ';
	if (down) then prompt:=prompt + '8 for down, ';
	prompt:=prompt + '9 for help, 0 to say something, ' +
			 'or star to go back.';

	done:=false;
	repeat
		$phone_say(prompt);
		key:=$phone_get_key;
		done:=true;
		if ( (key='2') and up ) then
			dispatch(context, command(go_keyword, up_keyword))
		else
		if ( (key='8') and down ) then
			dispatch(context, command(go_keyword, down_keyword))
		else
		case key of
		'1':	if ($room_dark(context)) then
				dispatch(context, command(look_keyword))
			else
			  begin
				list.count:=0;
				gather(context.room[context.location].room,
					context.self, list);
				if (list.count=0) then
					$phone_say('There is nothing here.')
				else
				  begin
					object_ptr:=choose_object(list);
					if (object_ptr<>nil) then
						object_menu(context,
							object_ptr, false);
				  end;
			  end;
		'3':	begin
				list.count:=0;
				gather(context.self, nil, list);
				if (list.count=0) then
					free_text(context, 'INVENTORY')
				else
				  begin
					object_ptr:=choose_object(list);
					if (object_ptr<>nil) then
						object_menu(context,
							object_ptr, true);
				  end;
			end;
		'4':	dispatch(context, command(score_keyword));
		'5':	free_text(context, 'SAVE ' + save_name);
		'6':	free_text(context, 'RESTORE ' + save_name);
		'7':	dispatch(context, command(quit_keyword));
		'9':	say_help;
		'0':	say_something(context);
		'*':	;
		otherwise
			done:=false;		(* say it again *)
		end;
	until done;
end;

procedure turn(var context : $context_block);
var	key : char;
	old_location : integer;
begin
	establish(condition_handler);

	old_location:=context.location;
	key:=$phone_get_key;
	case key of
	'1':	dispatch(context, command(go_keyword, north_west_keyword));
	'2':	dispatch(context, command(go_keyword, north_keyword));
	'3':	dispatch(context, command(go_keyword, north_east_keyword));
	'4':	dispatch(context, command(go_keyword, west_keyword));
	'5':	begin
			dispatch(context, command(look_keyword));
			say_exits(context);
		end;
	'6':	dispatch(context, command(go_keyword, east_keyword));
	'7':	dispatch(context, command(go_keyword, south_west_keyword));
	'8':	dispatch(context, command(go_keyword, south_keyword));
	'9':	dispatch(context, command(go_keyword, south_east_keyword));
	'#':	say_exits(context);
	'0':	action_menu(context);
	otherwise
		;			(* *: nothing in a room *)
	end;

	if (context.location<>old_location) then say_exits(context);
end;

(* Open ZKUAF.DAT shared: LOGIN.COM keeps it open during play *)
function open_uaf(var uaf : $uaf_file) : boolean;
begin
	open(uaf, uaf_name, history:=old, organization:=indexed,
	     access_method:=keyed, sharing:=readwrite, error:=continue);
	open_uaf:=(status(uaf)=0);
end;

(* The key for a passcode: PHONE:nnnnnn, blank padded like !64AS *)
function phone_key(passcode : varying[$u1] of char) : $uaf_key;
begin
	phone_key:=pad(phone_prefix + passcode, ' ', uaf_user_length);
end;

(* Find a record by user; the record lock is dropped straight away *)
function find_user(
	var uaf : $uaf_file;
	key : $uaf_key;
	var rec : $uaf_record) : boolean;
var	found : boolean;
begin
	findk(uaf, 0, key, eql, error:=continue);
	found:=(status(uaf)=0);
	if (found) then found:=not ufb(uaf);
	if (found) then rec:=uaf^;
	unlock(uaf, error:=continue);
	find_user:=found;
end;

(* Now, as F$CVTIME(,"COMPARISON"): yyyy-mm-dd hh:mm:ss.cc *)
function uaf_now : $uaf_date;
var	t : $numeric_time;
begin
	$numtim(t);
	uaf_now:=dec(t[1],4,4) + '-' + dec(t[2],2,2) + '-' +
		 dec(t[3],2,2) + ' ' + dec(t[4],2,2) + ':' +
		 dec(t[5],2,2) + ':' + dec(t[6],2,2) + '.' +
		 dec(t[7],2,2);
end;

(* A line without its leading blanks and tabs *)
function strip(line : $text_line) : $text_line;
var	i : integer;
	done : boolean;
begin
	i:=1; done:=false;
	repeat
		if (i>line.length) then done:=true
		else
		if ( (line[i]<>' ') and (line[i]<>''(9)) ) then done:=true
		else	i:=i+1;
	until done;
	if (i>line.length) then strip:=''
	else	strip:=substr(line, i, line.length-i+1);
end;

(* Speak a logical name's text, or with a leading @, the file it names.
 * In a file the lines are joined, and a blank line ends a paragraph.
 * If there is no logical, or the file will not open, the default. *)
procedure say_logical(
	name : [class_s] packed array[$l1..$u1:integer] of char;
	default_text : varying[$u2] of char);
var	value : packed array[1..255] of char;
	value_length : $uword;
	text_file : text;
	line : $text_line;
	paragraph : varying[4096] of char;
begin
	if (not odd($get_logical(name, value, value_length))) then
		value_length:=0;
	if (value_length=0) then $phone_say(default_text)
	else
	if (value[1]<>'@') then $phone_say(substr(value, 1, value_length))
	else
	  begin
		open(text_file, substr(value, 2, value_length-1),
		     history:=readonly, error:=continue);
		if (status(text_file)<>0) then $phone_say(default_text)
		else
		  begin
			reset(text_file); paragraph:='';
			while (not eof(text_file)) do
			  begin
				readln(text_file, line);
				line:=strip(line);
				if (line.length=0) then
				  begin
					$phone_say(paragraph); paragraph:='';
				  end
				else
				  begin
					if (paragraph.length+line.length+1>4096) then
					  begin
						$phone_say(paragraph); paragraph:='';
					  end;
					if (paragraph.length>0) then
						paragraph:=paragraph + ' ';
					paragraph:=paragraph + line;
				  end;
			  end;
			$phone_say(paragraph);
			close(text_file);
		  end;
	  end;
end;

(* After pound: true to start a new player, false to go back *)
function new_player_menu : boolean;
var	key : char;
	done, create : boolean;
begin
	done:=false; create:=false;
	repeat
		$phone_say('Press 1 to start a new game, 2 to hear about ' +
			   'The Halls of ZK, or star to go back.');
		key:=$phone_get_key;
		if (key='1') then
		  begin
			create:=true; done:=true;
		  end
		else
		if (key='2') then
			say_logical('ZK$PHONE_INTRO', 'Sorry, the introduction ' +
				    'is not available just now.')
		else
		if (key='*') then done:=true;
	until done;
	new_player_menu:=create;
end;

(* Passcode, or pound alone for a new player.  Star starts the entry
 * again and is not counted; three wrong passcodes end the call. *)
function ask_passcode(
	var uaf : $uaf_file;
	var rec : $uaf_record) : $login_result;
var	passcode : varying[passcode_length] of char;
	tries : integer;
	result : $login_result;
begin
	tries:=0; result:=login_failed;
	repeat
		$phone_say('Please enter your passcode, ' +
			   'or press pound if you are a new player.');
		if (odd($phone_get_digits(passcode, passcode_length))) then
			if (passcode.length=0) then
			  begin
				if (new_player_menu) then result:=login_new;
			  end
			else
			  begin
				if (passcode.length=passcode_length) then
					if (find_user(uaf, phone_key(passcode), rec)) then
						result:=login_found;
				if (result=login_failed) then
				  begin
					tries:=tries+1;
					$phone_say('That passcode is not known.');
				  end;
			  end;
	until ( (result<>login_failed) or (tries=max_passcode_tries) );
	ask_passcode:=result;
end;

(* Without its trailing blanks *)
function rtrim(s : varying[$u1] of char) : $text_line;
var	i : integer;
begin
	i:=s.length;
	while (i>0) do
		if (s[i]=' ') then i:=i-1
		else
		  begin
			rtrim:=substr(s, 1, i); i:=-1;
		  end;
	if (i=0) then rtrim:='';
end;

(* Twice, digit by digit; none of it can be cut short by a key *)
procedure say_passcode(passcode : varying[$u1] of char);
var	digits : $text_line;
	i : integer;
begin
	digits:='';
	for i:=1 to passcode.length do
	  begin
		if (i>1) then digits:=digits + ', ';
		digits:=digits + passcode[i];
	  end;
	$phone_say('Your passcode is ' + digits + '.  Again, your ' +
		   'passcode is ' + digits + '.  Please keep it safe: ' +
		   'you will need it to get back to your saved games.', false);
end;

(* A random passcode that no record has; false after ten collisions.
 * Call it holding the new player lock, so no one else can take the
 * passcode before the record is written. *)
function new_passcode(
	var uaf : $uaf_file;
	var passcode : varying[$u1] of char) : boolean;
var	seed : unsigned;
	t : $quad;
	rec : $uaf_record;
	tries : integer;
	found : boolean;
begin
	$gettim(t); seed:=t.l0; tries:=0;
	repeat
		passcode:=dec(trunc(random(seed)*1000000.0) mod 1000000,
			      passcode_length, passcode_length);
		found:=find_user(uaf, phone_key(passcode), rec);
		tries:=tries+1;
	until ( (not found) or (tries=max_new_passcode_tries) );
	new_passcode:=not found;
end;

(* As LOGIN.COM's register: a record with a new UID, "Charlie Matco".
 * Key 0 is user+uid, so RMS would let two records share a passcode;
 * the lock, group wide, makes new players one at a time.  The process
 * going away releases it. *)
function new_player(var uaf : $uaf_file; var rec : $uaf_record) : boolean;
var	passcode : varying[passcode_length] of char;
	bin : $uid;
	ascii : packed array[1..36] of char;	(* not a packed field *)
	lksb : $lock_status;
	locked, ok : boolean;
begin
	ok:=odd($enqw(0, lck$k_exmode, lksb, 0, new_player_lock));
	if (ok) then ok:=odd(lksb.status);
	locked:=ok;
	if (ok) then ok:=new_passcode(uaf, passcode);
	if (ok) then ok:=odd($create_uid(bin));
	if (ok) then ok:=odd($uid_to_ascii(bin, ascii));
	if (ok) then
	  begin
		rec.user:=phone_key(passcode);
		rec.uid:=ascii;
		rec.hash:=pad('', ' ', 32);
		rec.created:=uaf_now; rec.last_login:=rec.created;
		rec.logins:=dec(1, 10, 1);		(* as !10UL *)
		rec.first_name:=pad('Charlie', ' ', 32);
		rec.last_name:=pad('Matco', ' ', 32);
		rec.spare:=pad('', ' ', 262);
		uaf^:=rec; put(uaf, error:=continue);
		ok:=(status(uaf)=0);
	  end;
	if (locked) then $deq(lksb.lock_id);

	if (ok) then say_passcode(passcode)
	else	$phone_say('Sorry, a new game cannot be set up just now.');
	new_player:=ok;
end;

(* One more login, and when.  LOGIN.COM does not do this. *)
procedure count_login(var uaf : $uaf_file; var rec : $uaf_record);
var	count, i : integer;
begin
	findk(uaf, 0, rec.user, eql, error:=continue);
	if (status(uaf)=0) then
		if (not ufb(uaf)) then
		  begin
			rec:=uaf^; count:=0;
			for i:=1 to 10 do
				if (rec.logins[i] in ['0'..'9']) then
					count:=count*10 + ord(rec.logins[i]) -
						ord('0');
			rec.logins:=dec(count+1, 10, 1);
			rec.last_login:=uaf_now;
			uaf^:=rec; update(uaf, error:=continue);
		  end;
	unlock(uaf, error:=continue);
end;

(* SYS$LOGIN:[.USERS.<uid>], made if need be, as LOGIN.COM does.  Only
 * the directory is set: the device is SYS$LOGIN's, from ZKPHONE_RUN.COM.
 * ZK$MULTI_USER gives the badge the record's names. *)
function enter_directory(var rec : $uaf_record) : boolean;
var	value : packed array[1..255] of char;
	value_length : $uword;
	login, dir : $text_line;
	colon : integer;
	ok : boolean;
begin
	ok:=odd($get_logical('SYS$LOGIN', value, value_length));
	if (ok) then
	  begin
		login:=substr(value, 1, value_length);
		ok:=(login.length>0);
		if (ok) then ok:=(login[login.length]=']');
	  end;
	if (ok) then
	  begin
		dir:=substr(login, 1, login.length-1) + '.USERS.' +
		     rec.uid + ']';
		ok:=odd($create_dir(dir));		(* SS$_CREATED or NORMAL *)
	  end;
	if (ok) then
	  begin
		colon:=index(dir, ':');
		ok:=odd($setddir(substr(dir, colon+1, dir.length-colon)));
	  end;
	if (ok) then ok:=odd($set_logical('ZK$MULTI_USER',
			rtrim(rec.first_name) + ' ' + rtrim(rec.last_name)));
	if (not ok) then
		$phone_say('Sorry, your saved games are not available just now.');
	enter_directory:=ok;
end;

procedure main;
var	context : $context_block;
	uaf : $uaf_file;
	rec : $uaf_record;
	login : $login_result;
	return : unsigned;
begin
	return:=$init_screen('', broadcast_handler, iaddress(context));
	if (not odd(return)) then $signal(return)
	else
	  begin
		say_logical('ZK$PHONE_WELCOME', 'Welcome to The Halls of ZK, ' +
			    'the original interactive fiction game written ' +
			    'exclusively for OpenVMS.');

		login:=login_failed;
		if (open_uaf(uaf)) then login:=ask_passcode(uaf, rec)
		else	$phone_say('Sorry, saved games are not available ' +
				   'just now.  Please call again later.');

		if (login=login_new) then
			if (not new_player(uaf, rec)) then login:=login_failed;
		if (login=login_found) then count_login(uaf, rec);
		if (login<>login_failed) then
			if (not enter_directory(rec)) then login:=login_failed;

		if (login<>login_failed) then
		  begin
			$initialize(context);
			say_exits(context);
			while ( (not context.flags.won) and
				(not context.flags.died) and
				(not context.flags.quit) ) do turn(context);

			if (context.flags.won) then
				$message(0, 0, zk$text_player_won)
			else
			if (context.flags.died) then
				$message(0, 0, zk$text_player_died);

			$message(0); $score(context); $message(0);
		  end;

		close(uaf, error:=continue);		(* sys_goodbye follows *)
		return:=$finish_screen;
		if (not odd(return)) then $signal(return);
	  end;
end;

begin
	main;
end.
