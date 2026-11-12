
[inherit('lib$:typedef',
	 'lib$:dscdef',
	 'lib$:rtldef',
	 'lib$:sysdef',
	 'lib$:qiodef'),
ident('X01.00-00')]
module ifc$rtl_phone; (* IFC Run-Time System telephone screen layer *)

(* Edit History                                                             *)
(* 02-Nov-2026  TES  Original version.  Telephone screen layer: FastAGI     *)
(*                   over SYS$NET, linked in place of IFC$RTL_SCREEN.       *)
(* 09-Nov-2026  TES  ifc$phone_say splits long text into sentences, and     *)
(*                   says a run of three or more symbols as their plural.   *)
(* 09-Nov-2026  TES  A play that cannot be interrupted is played even after *)
(*                   a key, and ifc$phone_say can be uninterruptible.       *)
(* 11-Nov-2026  TES  agi_command skips "100 Trying" lines: GOSUB sends one  *)
(*                   before its 200 reply.                                  *)
(* 11-Nov-2026  TES  An ellipsis is spoken as a pause, not "period period  *)
(*                   period".  Game messages go through ifc$phone_say too.  *)
(* 12-Nov-2026  TES  ifc$phone_get_heard: the caller's words, recorded and  *)
(*                   recognised by the ifc-hear subroutine.                 *)
(*                                                                          *)

const	agi_buffer_size = 512;
	agi_line_size = 1024;
	agi_max_headers = 40;
	lf = ''(10);
	cr = ''(13);
	escape_keys = '"0123456789*#"';
	idle_timeout = 60000;			(* ms *)
	spell_pause = 1500;			(* ms; a pause ends a letter *)
	speech_size = 480;			(* escaped, fits an AGI line *)
	say_size = 4096;			(* ifc$phone_say, before split *)
	number_trans = 4;

type	$agi_line = varying[agi_line_size] of char;
	$keypad_group = varying[5] of char;
	$agi_number = varying[11] of char;
	$speech = varying[speech_size] of char;
	$say_text = varying[say_size] of char;
	$symbol_name = varying[20] of char;
	$trans_record = record
			pattern : varying[10] of char;
			replacement : varying[10] of char;
		end;
	$trans_array = array[1..number_trans] of $trans_record;
	$message_args = array[0..30] of integer;
	$pointer = [unsafe, long] packed record
			case integer of
			1 : (address : unsigned);
			2 : (byte_ptr : ^$ubyte);
			3 : (word_ptr : ^$uword);
			4 : (long_ptr : ^unsigned);
		   end;
	$agi_header = record
			name : varying[32] of char;
			value : varying[256] of char;
		end;

var	agi_channel : [static] $uword := 0;
	in_buffer : [static] packed array[1..agi_buffer_size] of char;
	in_pos : [static] integer := 1;
	in_count : [static] integer := 0;
	header : [static] array[1..agi_max_headers] of $agi_header;
	header_count : [static] integer := 0;
	sound_dir : [static] varying[31] of char := '';
	sound_prefix : [static] varying[32] of char := '';
	held_key : [static] char := ''(0);
	interrupted : [static] boolean := false;
	queued_line : [static] $agi_line;
	line_queued : [static] boolean := false;
	crc_table : [static] array[0..15] of unsigned;
	crc_ready : [static] boolean := false;

	ss$_abort,
	ss$_bufferovf,
	ss$_linkdiscon,
	ss$_timeout:
		[external, value] unsigned;

(* The caller has gone: stop here, as ZK would loop in $quit on an error *)
procedure agi_fail(status : unsigned);
begin
	$exit(status);
end;

procedure agi_open;
var	return : unsigned;
begin
	return:=$assign('SYS$NET', agi_channel);
	if (not odd(return)) then agi_fail(return);
end;

procedure agi_fill_buffer;
var	return : unsigned;
	iosb : $quad;
begin
	return:=$qiow(chan:=agi_channel, func:=io$_readvblk, iosb:=iosb,
			buffer:=iaddress(in_buffer), bufsiz:=agi_buffer_size);
	if (odd(return)) then return:=iosb.l0 mod 65536;
	if (not odd(return)) then agi_fail(return);

	in_count:=iosb.l0 div 65536;
	in_pos:=1;
	if (in_count=0) then agi_fail(ss$_linkdiscon);	(* peer closed *)
end;

procedure agi_read_line(var line : $agi_line);
var	c : char;
	done : boolean;
begin
	line:=''; done:=false;
	repeat
		if (in_pos>in_count) then agi_fill_buffer;
		c:=in_buffer[in_pos]; in_pos:=in_pos+1;
		if (c=lf) then done:=true
		else
		if (c<>cr) then
		  begin
			if (line.length=agi_line_size) then
				agi_fail(ss$_bufferovf);
			line:=line+c;
		  end;
	until done;
end;

procedure agi_write_line(line : varying[$u1] of char);
var	return : unsigned;
	iosb : $quad;
	buffer : $agi_line;
begin
	if (line.length>=agi_line_size) then agi_fail(ss$_bufferovf);
	buffer:=line+lf;

	return:=$qiow(chan:=agi_channel, func:=io$_writevblk, iosb:=iosb,
			buffer:=iaddress(buffer.body), bufsiz:=buffer.length);
	if (odd(return)) then return:=iosb.l0 mod 65536;
	if (not odd(return)) then agi_fail(return);
end;

function agi_parse_integer(
	var line : $agi_line;
	var p : integer) : integer;

var	n : integer;
	negative, done : boolean;
begin
	n:=0; negative:=false;
	if (p<=line.length) then
		if (line[p]='-') then
		  begin
			negative:=true; p:=p+1;
		  end;

	(* No short circuit in Pascal: test the length before line[p] *)
	done:=false;
	repeat
		if (p>line.length) then done:=true
		else
		if ( (line[p]<'0') or (line[p]>'9') ) then done:=true
		else
		  begin
			n:=n*10 + (ord(line[p])-ord('0'));
			p:=p+1;
		  end;
	until done;

	if (negative) then n:=-n;
	agi_parse_integer:=n;
end;

(* An integer as digits, for AGI command arguments *)
function agi_decimal(n : integer) : $agi_number;
var	s : $agi_number;
	negative : boolean;
begin
	s:=''; negative:=(n<0);
	if (negative) then n:=-n;
	repeat
		s:=chr(ord('0') + (n mod 10)) + s;
		n:=n div 10;
	until (n=0);
	if (negative) then s:='-' + s;
	agi_decimal:=s;
end;

(* Reply is "200 result=<n> [<data>]"; returns <n>, data gets the rest *)
function agi_command(
	command : varying[$u1] of char;
	var data : $agi_line) : integer;

var	reply : $agi_line;
	p, code, result : integer;
begin
	agi_write_line(command);
	repeat					(* GOSUB sends "100 Trying" first *)
		agi_read_line(reply);
		if (reply='HANGUP') then agi_fail(ss$_linkdiscon);
		p:=1;
		code:=agi_parse_integer(reply, p);
	until (code<>100);

	if (code=520) then
	  begin
		repeat
			agi_read_line(reply);	(* usage text *)
		until (index(reply, '520 ')=1);
		agi_fail(ss$_abort);
	  end;
	if (code=511) then agi_fail(ss$_linkdiscon);	(* dead channel *)
	if (code<>200) then agi_fail(ss$_abort);

	p:=index(reply, 'result=');
	if (p=0) then agi_fail(ss$_abort);
	p:=p+7;
	result:=agi_parse_integer(reply, p);
	if (result=-1) then agi_fail(ss$_linkdiscon);

	if (p<reply.length) then
		data:=substr(reply, p+1, reply.length-p)
	else	data:='';

	agi_command:=result;
end;

procedure agi_read_headers;
var	line : $agi_line;
	p, n : integer;
begin
	header_count:=0;
	repeat
		agi_read_line(line);
		p:=index(line, ': ');
		if ( (p>1) and (p<=33) and (header_count<agi_max_headers) ) then
		  begin
			header_count:=header_count+1;
			header[header_count].name:=substr(line, 1, p-1);

			n:=line.length-p-1;
			if (n>256) then n:=256;
			if (n>0) then
				header[header_count].value:=substr(line, p+2, n)
			else	header[header_count].value:='';
		  end;
	until (line.length=0);
end;

[global] function ifc$phone_header(
	name : varying[$u1] of char;
	var value : varying[$u2] of char) : boolean;

var	i : integer;
	found : boolean;
begin
	found:=false; i:=1;
	while ( (i<=header_count) and (not found) ) do
		if (header[i].name=name) then found:=true
		else	i:=i+1;

	if (found) then
		if (header[i].value.length>length(value.body)) then
			value:=substr(header[i].value, 1, length(value.body))
		else	value:=header[i].value;

	ifc$phone_header:=found;
end;

(* No reply is read: Asterisk may close the socket first *)
procedure agi_hangup;
begin
	agi_write_line('HANGUP');
end;

(* Play a file; returns the key that cut it short, or NUL.  After a key
 * only plays that cannot be interrupted are played. *)
function agi_play(
	name : varying[$u1] of char;
	interruptible : boolean) : char;

var	data : $agi_line;
	result : integer;
	key : char;
begin
	key:=''(0);
	if ( (not interrupted) or (not interruptible) ) then
	  begin
		if (interruptible) then
			result:=agi_command('STREAM FILE ' + sound_prefix + name +
						' ' + escape_keys, data)
		else	result:=agi_command('STREAM FILE ' + sound_prefix + name +
						' ""', data);
		if (result>0) then
		  begin
			key:=chr(result);
			held_key:=key; interrupted:=true;
		  end;
	  end;
	agi_play:=key;
end;

[global] function ifc$phone_play(
	name : varying[$u1] of char;
	interruptible : boolean := true) : char;
begin
	ifc$phone_play:=agi_play(name, interruptible);
end;

(* Next key, type-ahead first.  timeout 0 means wait for the player,
 * asking once if they are still there, then hanging up. *)
[global] function ifc$phone_get_key(
	timeout : integer := 0) : char;

var	data : $agi_line;
	result, strikes : integer;
	key : char;
begin
	interrupted:=false;
	if (held_key<>''(0)) then
	  begin
		key:=held_key; held_key:=''(0);
	  end
	else
	if (timeout<>0) then
	  begin
		result:=agi_command(
			'WAIT FOR DIGIT ' + agi_decimal(timeout), data);
		key:=chr(result);			(* NUL on timeout *)
	  end
	else
	  begin
		strikes:=0; key:=''(0);
		repeat
			result:=agi_command(
				'WAIT FOR DIGIT ' + agi_decimal(idle_timeout), data);
			if (result>0) then key:=chr(result)
			else
			  begin
				strikes:=strikes+1;
				if (strikes=1) then
					key:=agi_play('sys_still_there', true);
			  end;
			interrupted:=false; held_key:=''(0);
		until ( (key<>''(0)) or (strikes=2) );

		if (key=''(0)) then
		  begin
			result:=ord(agi_play('sys_goodbye', false));
			agi_hangup;
			$exit(ss$_normal);
		  end;
	  end;
	ifc$phone_get_key:=key;
end;

[global] function ifc$phone_interrupted : boolean;
begin
	ifc$phone_interrupted:=interrupted;
end;

(* Passcode or combination.  # ends early, * cancels, max digits ends *)
[global] function ifc$phone_get_digits(
	var s : varying[$u1] of char;
	max : integer;
	timeout : integer := 0) : unsigned;

var	return : unsigned;
	key : char;
	done : boolean;
begin
	if (max>length(s.body)) then max:=length(s.body);
	s:=''; return:=ss$_normal; done:=false;
	repeat
		key:=ifc$phone_get_key(timeout);
		if (key=''(0)) then
		  begin
			return:=ss$_timeout; done:=true;
		  end
		else
		if (key='*') then
		  begin
			return:=ss$_abort; done:=true;
		  end
		else
		if (key='#') then done:=true
		else
		  begin
			s:=s+key;
			if (s.length>=max) then done:=true;
		  end;
	until done;
	ifc$phone_get_digits:=return;
end;

function keypad_letters(key : char) : $keypad_group;
begin
	case key of
	'2':	keypad_letters:='ABC2';
	'3':	keypad_letters:='DEF3';
	'4':	keypad_letters:='GHI4';
	'5':	keypad_letters:='JKL5';
	'6':	keypad_letters:='MNO6';
	'7':	keypad_letters:='PQRS7';
	'8':	keypad_letters:='TUV8';
	'9':	keypad_letters:='WXYZ9';
	otherwise
		keypad_letters:=key;		(* 0 and 1 are themselves *)
	end;
end;

procedure play_letter(c : char);
var	key : char;
begin
	if ( (c>='0') and (c<='9') ) then
		key:=agi_play('key' + c, true)
	else	key:=agi_play('letter_' + chr(ord(c)+32), true);
end;

(* Multi-tap: press 2 once for A, twice for B; a pause or another key
 * moves on.  # finishes, * rubs out, * on nothing cancels. *)
[global] function ifc$phone_get_spelled(
	var s : varying[$u1] of char;
	max : integer) : unsigned;

var	return : unsigned;
	group : $keypad_group;
	key, pending_key, letter : char;
	taps : integer;
	done : boolean;
begin
	if (max>length(s.body)) then max:=length(s.body);
	s:=''; return:=ss$_normal; done:=false;
	pending_key:=''(0); taps:=0;
	repeat
		if (pending_key<>''(0)) then
			key:=ifc$phone_get_key(spell_pause)
		else	key:=ifc$phone_get_key;

		if ( (key<>''(0)) and (key=pending_key) ) then
		  begin
			taps:=taps+1;
			letter:=group[((taps-1) mod group.length)+1];
			play_letter(letter);
		  end
		else
		  begin
			if (pending_key<>''(0)) then
			  begin
				if (key<>'*') then s:=s+letter;
				pending_key:=''(0);
			  end
			else
			if (key='*') then
				if (s.length=0) then
				  begin
					return:=ss$_abort; done:=true;
				  end
				else	s:=substr(s, 1, s.length-1);

			if (key='*') then
			  begin
				if (not done) then
					letter:=agi_play('sys_deleted', true);
			  end
			else
			if (key='#') then done:=true
			else
			if ( (key<>''(0)) and (s.length<max) ) then
			  begin
				pending_key:=key; taps:=1;
				group:=keypad_letters(key);
				letter:=group[1];
				play_letter(letter);
			  end;
		  end;
	until done;
	ifc$phone_get_spelled:=return;
end;

(* What the caller says after the tone, in capitals with one space
 * between words; '' if nothing was understood.  The ifc-hear subroutine
 * records and recognises it on the Asterisk side, so only the words
 * cross the network, in IFC_HEARD: "200 result=1 (WORDS)". *)
[global] function ifc$phone_get_heard(
	var s : varying[$u1] of char) : unsigned;

var	data : $agi_line;
	result, left, right : integer;
begin
	s:='';
	result:=agi_command('GOSUB ifc-hear s 1 ' + sound_dir, data);
	result:=agi_command('GET VARIABLE IFC_HEARD', data);
	left:=index(data, '(');
	right:=index(data, ')');
	if ( (left<>0) and (right>left+1) ) then
		s:=substr(data, left+1, min(right-left-1, length(s.body)));
	ifc$phone_get_heard:=ss$_normal;
end;

(* Free text for the next ifc$get_composed_line *)
[global] procedure ifc$phone_set_line(line : varying[$u1] of char);
begin
	if (line.length>agi_line_size) then
		queued_line:=substr(line, 1, agi_line_size)
	else	queued_line:=line;
	line_queued:=true;
end;

(* The sound directory is the AGI script name; the arguments are unused *)
[global] function ifc$init_screen(
	key_logical_name : varying[$u1] of char;
	[unbound, asynchronous] procedure ast_routine;
	ast_argument : [unsafe] unsigned) : unsigned;

var	key : char;
begin
	agi_open;
	agi_read_headers;

	if (not ifc$phone_header('agi_network_script', sound_dir)) then
		agi_fail(ss$_abort);
	sound_prefix:=sound_dir + '/';

	key:=agi_play('sys_welcome', true);
	ifc$init_screen:=ss$_normal;
end;

[global] function ifc$finish_screen : unsigned;
var	key : char;
begin
	interrupted:=false;
	key:=agi_play('sys_goodbye', false);
	agi_hangup;
	$dassgn(agi_channel);
	ifc$finish_screen:=ss$_normal;
end;

(* Only the quit confirmation asks; the prompt text is not spoken *)
[global] function ifc$get_string(
	var string : varying[$u1] of char;
	prompt : varying[$u2] of char) : unsigned;

var	key : char;
begin
	string:='';
	repeat
		key:=agi_play('sys_confirm', true);
		key:=ifc$phone_get_key;
		if (key='1') then string:='Y'
		else
		if ( (key='2') or (key='*') ) then string:='N';
	until (string.length>0);
	ifc$get_string:=ss$_normal;
end;

(* The driver queues the line with ifc$phone_set_line *)
[global] function ifc$get_composed_line(
	var string : varying[$u1] of char;
	prompt : varying[$u2] of char) : unsigned;
begin
	if (not line_queued) then string:=''
	else
	if (queued_line.length>length(string.body)) then
		string:=substr(queued_line, 1, length(string.body))
	else	string:=queued_line;
	line_queued:=false;
	ifc$get_composed_line:=ss$_normal;
end;

[global] function ifc$update_status_numbers(
	var score : integer;
	var moves : integer) : unsigned;
begin
	ifc$update_status_numbers:=ss$_normal;
end;

[global] function ifc$update_status_room(
	var string : varying[$u1] of char) : unsigned;
begin
	ifc$update_status_room:=ss$_normal;
end;

[global] function ifc$output_broadcast_messages : unsigned;
begin
	ifc$output_broadcast_messages:=ss$_normal;
end;

procedure correct_English(
	var string : varying[$u1] of char);

var	lowered : boolean;
	p, i : integer;
	trans : [static] $trans_array :=
		( ('the self', 'you'),
		  ('you is', 'you are'),
		  ('you does', 'you do'),
		  ('s is', 's are') );
begin
	if (string[1]>='A') and (string[1]<='Z') then
	  begin
		string[1]:=chr(ord(string[1])+32); lowered:=true
	  end
	else	lowered:=false;

	for i:=1 to number_trans do
	  begin
		p:=index(string, trans[i].pattern);
		if (p<>0) then
			$replace(string, string, p,
				p + trans[i].pattern.length - 1,
				trans[i].replacement);
	  end;

	if ( (string[1]>='a') and (string[1]<='z') and (lowered)) then
		string[1]:=chr(ord(string[1])-32);
end;

(* Render the text on the Asterisk side, then play it.  The file name is
 * a CRC of the text; control and 8-bit characters are dropped. *)
procedure speak(
	var text : $speech;
	interruptible : boolean := true);
var	command, data : $agi_line;
	name : varying[9] of char;
	i, result : integer;
	c, key : char;
begin
	if ( ((not interrupted) or (not interruptible)) and
	     (text.length>0) ) then
	  begin
		if (not crc_ready) then
		  begin
			$crc_table(%x'EDB88320', crc_table);
			crc_ready:=true;
		  end;
		name:='t' + hex($crc(crc_table, -1, text), 8, 8);
		for i:=2 to name.length do
			if (name[i]>='A') then name[i]:=chr(ord(name[i])+32);

		command:='SET VARIABLE IFC_TEXT "';
		for i:=1 to text.length do
		  begin
			c:=text[i];
			if (c=''(9)) then c:=' ';
			if ( (c>=' ') and (c<='~') ) then
			  begin
				if ( (c='"') or (c='\') ) then
					command:=command + '\';
				command:=command + c;
			  end;
		  end;
		result:=agi_command(command + '"', data);
		result:=agi_command('GOSUB ifc-say s 1 ' + sound_dir + ',' +
					name, data);
		result:=agi_command('GET VARIABLE SYSTEMSTATUS', data);

		if (index(data, '(SUCCESS)')<>0) then
			key:=agi_play(name, interruptible)
		else	key:=agi_play('sys_error', interruptible);
	  end;
	text:='';
end;

(* What three or more of a symbol in a row are called; '' leaves them be.
 * Prose punctuation is not here: "..." is a pause (see spoken_symbols)
 * and "--" is left alone. *)
function symbol_plural(c : char) : $symbol_name;
begin
	case c of
	'$':	symbol_plural:='dollars';
	'*':	symbol_plural:='stars';
	'#':	symbol_plural:='pound signs';
	'@':	symbol_plural:='at signs';
	'%':	symbol_plural:='percent signs';
	'&':	symbol_plural:='ampersands';
	'+':	symbol_plural:='plus signs';
	'=':	symbol_plural:='equals signs';
	'~':	symbol_plural:='tildes';
	'^':	symbol_plural:='carets';
	'_':	symbol_plural:='underscores';
	'/':	symbol_plural:='slashes';
	'\':	symbol_plural:='backslashes';
	'|':	symbol_plural:='bars';
	otherwise
		symbol_plural:='';
	end;
end;

(* "paying $$$$ for" is said "paying dollars for" *)
function spoken_symbols(line : varying[$u1] of char) : $say_text;
var	text : $say_text;
	piece : $say_text;
	name : $symbol_name;
	i, run : integer;
	done : boolean;
begin
	text:=''; i:=1;
	while (i<=line.length) do
	  begin
		run:=1; done:=false;
		repeat
			if (i+run>line.length) then done:=true
			else
			if (line[i+run]<>line[i]) then done:=true
			else	run:=run+1;
		until done;

		name:=symbol_plural(line[i]);
		if ( (run>=3) and (line[i]='.') ) then
			piece:=','			(* an ellipsis: a pause *)
		else
		if ( (run>=3) and (name.length>0) ) then
			piece:=' ' + name + ' '
		else	piece:=substr(line, i, run);
		if (text.length+piece.length<=say_size) then
			text:=text + piece;
		i:=i+run;
	  end;
	spoken_symbols:=text;
end;

(* Speak text composed by the driver, e.g. a menu prompt.  Text too long
 * for one utterance is split after the last sentence that fits, or else
 * the last word; once the caller presses a key the rest is skipped,
 * unless it cannot be interrupted. *)
[global] procedure ifc$phone_say(
	line : varying[$u1] of char;
	interruptible : boolean := true);
var	whole : $say_text;
	text : $speech;
	start, cut, space, sentence, i : integer;
begin
	whole:=spoken_symbols(line);
	start:=1;
	while (whole.length-start+1>speech_size) do
	  begin
		space:=0; sentence:=0;
		for i:=start+1 to start+speech_size-1 do
			if (whole[i]=' ') then
			  begin
				space:=i;
				if ( (whole[i-1]='.') or (whole[i-1]='!') or
				     (whole[i-1]='?') ) then sentence:=i;
			  end;
		if (sentence<>0) then cut:=sentence
		else
		if (space<>0) then cut:=space
		else	cut:=start+speech_size;

		text:=substr(whole, start, cut-start);
		speak(text, interruptible);
		if (whole[cut]=' ') then cut:=cut+1;
		start:=cut;
	  end;
	if (start<=whole.length) then
	  begin
		text:=substr(whole, start, whole.length-start+1);
		speak(text, interruptible);
	  end;
end;

(* As write_message in IFC$RTL_SCREEN, but the lines of a message are
 * joined into one utterance.  Message code 0 is a short pause. *)
procedure play_message(
	var message_ptr : $pointer;
	fao_block : $pointer);

var	desc : $descriptor;
	p : $pointer;
	line_fao_count, i : integer;
	line : varying[255] of char;		(* length is a byte *)
	text : $speech;
	key : char;

[external(sys$faol)] function $$faol(
        var desc : $uquad;
        var outlen : $uword;
        %stdescr fao_desc : packed array[$l1..$u1:integer] of char;
        %immed prmlst : unsigned) : unsigned;
        extern;

begin
	text:='';
	if (message_ptr.address=0) then
		key:=agi_play('sys_pause', true)
	else
	while (message_ptr.word_ptr^<>0) do
	  begin
		desc.dsc$b_dtype:=dsc$k_dtype_t;
		desc.dsc$b_class:=dsc$k_class_s;
		desc.dsc$w_length:=message_ptr.byte_ptr^;

		message_ptr.address:=message_ptr.address + 1;
		line_fao_count:=message_ptr.byte_ptr^;

		message_ptr.address:=message_ptr.address + 2;	(* skip attributes *)
		desc.dsc$a_pointer:=message_ptr.address;

		message_ptr.address:=message_ptr.address + desc.dsc$w_length;

		if (line_fao_count=0) then
		  begin
			(* Literal line: copy it; $FAOL would act on any "!" *)
			line:=''; p.address:=desc.dsc$a_pointer;
			for i:=1 to desc.dsc$w_length do
			  begin
				line:=line + chr(p.byte_ptr^);
				p.address:=p.address + 1;
			  end;
		  end
		else
		  begin
			if (not odd($$faol(desc, line.length, line.body,
					fao_block.address))) then line:='';
			if (line.length>0) then correct_English(line);
			fao_block.address:=fao_block.address +
						(line_fao_count*4);
		  end;

		if (text.length + line.length + 1>speech_size) then
		  begin
			ifc$phone_say(text); text:='';
		  end;
		if (text.length>0) then text:=text + ' ';
		text:=text + line;
	  end;
	ifc$phone_say(text);
end;

[global] function ifc$message_indent_list(
	ap : $message_args) : unsigned;

var	i, fao_count : integer;
	message_code : unsigned;
begin
	i:=2;					(* ap[1] is the column *)
	while (i<=ap[0]) do
	  begin
		message_code:=ap[i]; i:=i+1;
		if (i<=ap[0]) then
		  begin
			fao_count:=ap[i]; i:=i+1;
		  end
		else	fao_count:=0;
		if (fao_count=0) then
			play_message(message_code, 0)
		else
		  begin
			play_message(message_code, iaddress(ap[i]));
			i:=i+fao_count;
		  end;
	  end;
	ifc$message_indent_list:=1;
end;

[global] function ifc$message_list(
	var ap : $message_args) : unsigned;

var	i, fao_count : integer;
	message_code : unsigned;
begin
	i:=1;
	while (i<=ap[0]) do
	  begin
		message_code:=ap[i]; i:=i+1;
		if (i<=ap[0]) then
		  begin
			fao_count:=ap[i]; i:=i+1;
		  end
		else	fao_count:=0;
		if (fao_count=0) then
			play_message(message_code, 0)
		else
		  begin
			play_message(message_code, iaddress(ap[i]));
			i:=i+fao_count;
		  end;
	  end;
	ifc$message_list:=1;
end;

end.
