[inherit('lib$:typedef',
	 'lib$:dscdef',
	 'lib$:rtldef',
	 'lib$:sysdef',
	 'lib$:smgdef')]
module ifc$rtl_screen;

const	number_trans = 4;

type	$trans_record = record
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

var	screen,				(* pasteboard *)
	status_line,			(* virtual display *)
	main_display,			(* virtual display *)
	more_indicator,			(* virtual display *)
	terminal,			(* virtual keyboard *)
	key_table:			(* terminal key definition table *)
		[static] unsigned;
	line_count:
		[static] integer := 0;

[external(sys$faol)] function $$faol(
	var desc : $uquad;
	var outlen : $uword;
	%stdescr fao_desc : packed array[$l1..$u1:integer] of char;
	%immed prmlst : unsigned) : unsigned;
	extern;

[global] function ifc$init_screen(
	key_logical_name : varying[$u1] of char;
	[unbound, asynchronous] procedure ast_routine;
	ast_argument : [unsafe] unsigned) : unsigned;

var	return : unsigned;
	item_list : $item_list;
	version : packed array[1..8] of char;
begin
	establish($sig_to_ret);

	return:=$create_pasteboard(screen);
	if (not odd(return)) then $signal(return);

	return:=$create_virtual_keyboard(terminal);
	if (not odd(return)) then $signal(return);

	return:=$create_key_table(key_table);
	if (not odd(return)) then $signal(return);

	return:=$load_key_defs(key_table, key_logical_name, '.COM');
	if ( (not odd(return)) and (return<>rms$_fnf) ) then
		$signal(return);

	return:=$create_virtual_display(1,80,status_line,,smg$m_reverse);
	if (not odd(return)) then $signal(return);

	return:=$create_virtual_display(23,80,main_display);
	if (not odd(return)) then $signal(return);

	return:=$create_virtual_display(1,9,more_indicator,,smg$m_reverse);
	if (not odd(return)) then $signal(return);

	return:=$set_broadcast_trapping(screen, %immed ast_routine,
					ast_argument);
	if (not odd(return)) then $signal(return);

	return:=$put_chars(status_line,'Score:',1,50);
	if (not odd(return)) then $signal(return);
	return:=$put_chars(status_line,'Moves:',1,65);
	if (not odd(return)) then $signal(return);
	return:=$put_chars(more_indicator,'[More...]',1,1);
	if (not odd(return)) then $signal(return);

	return:=$paste_virtual_display(status_line,screen,1,1);
	if (not odd(return)) then $signal(return);

	return:=$paste_virtual_display(main_display,screen,2,1);
	if (not odd(return)) then $signal(return);

	(* KLUDGE FOR V40,V41 SMG BUGS BEGINS HERE *)

	item_list[1].buffer_length:=8;
	item_list[1].item_code:=syi$_version;
	item_list[1].buffer_address:=iaddress(version);
	item_list[1].return_length_address:=0;
	item_list[2].buffer_length:=0;
	item_list[2].item_code:=0;

	return:=$getsyiw(,,,item_list);
	if (not odd(return)) then $signal(return);

	if ( (version[2]='4') and
		( (version[4]='0') or (version[4]='1') ) ) then
	  begin
		return:=$set_cursor_abs(main_display, 23, 1);
		if (not odd(return)) then $signal(return);
	  end;

	ifc$init_screen:=ss$_normal;
end;

[global] function ifc$finish_screen : unsigned;
var	return : unsigned;
begin
	establish($sig_to_ret);

	return:=$set_cursor_abs(main_display, 23, 1);
	if (not odd(return)) then $signal(return);

	return:=$delete_virtual_keyboard(terminal);
	if (not odd(return)) then $signal(return);

	return:=$delete_pasteboard(screen, 0);
	if (not odd(return)) then $signal(return);

	ifc$finish_screen:=ss$_normal;
end;

[global] function ifc$get_string(
	var string : varying[$u1] of char;
	prompt : varying[$u2] of char) : unsigned;
var	return : unsigned;
begin
	ifc$get_string:=$read_string(terminal, string, prompt,,,,,,,
					main_display);
	line_count:=line_count + 1;
end;

[global] function ifc$get_composed_line(
	var string : varying[$u1] of char;
	prompt : varying[$u2] of char) : unsigned;

var	return : unsigned;
begin
	line_count:=1;
	return:=$read_composed_line(terminal, key_table,
			string, prompt,, main_display);
	ifc$get_composed_line:=return;
end;

[global] function put_scroll_dx(
	column_number : (* [truncate] *) integer;
	var string : (* [truncate] *) $uquad;
	new_attributes : (* [truncate] *) unsigned) : unsigned;

var	return : unsigned;
	attributes : unsigned;
	buf : varying[10] of char;
	temp : varying[132] of char;
begin
	if (line_count=23) then
	  begin
		line_count:=0;

		return:=$paste_virtual_display(more_indicator, screen, 24, 1);
		if (not odd(return)) then $signal(return);

		return:=$read_string(terminal, buf,, 1, io$m_noecho);
		if (not odd(return)) then $signal(return);

		return:=$unpaste_virtual_display(more_indicator, screen);
		if (not odd(return)) then $signal(return);
	  end;
	line_count:=line_count + 1;

	attributes:=0;
	(* if (present(new_attributes)) then *) attributes:=new_attributes;

	(* if (not present(column_number)) then
		return:=$put_with_scroll(main_display)
	else *)
	if (column_number=1) then
		return:=$put_with_scroll_dx(main_display,string,,attributes,,1)
	else
	  begin
		return:=$dupl_char(temp, column_number-1, ' ');
		if (not odd(return)) then $signal(return);

		return:=$append_vs_dx(temp, string);
		if (not odd(return)) then $signal(return);

		return:=$put_with_scroll(main_display, temp,, attributes,,1)
	  end;

	put_scroll_dx:=return;
end;

procedure convert_n_s(
	score : integer;
	var string : varying[$u1] of char);
var	p : integer;
begin
	string:='  0'; p:=3;
	while ( (p>0) and (score>0) ) do
	  begin
		string[p]:=chr((score mod 10)+48);
		score:=score div 10;
		p:=p-1;
	  end;
end;

[global] function ifc$update_status_numbers(
	var score : integer;
	var moves : integer) : unsigned;

var	return : unsigned;
	string : varying[3] of char;
begin
	return:=$begin_display_update(status_line);
	if (not odd(return)) then $signal(return);

	convert_n_s(score, string);
	return:=$put_chars(status_line, string, 1, 57);
	if (not odd(return)) then $signal(return);

	convert_n_s(moves, string);
	return:=$put_chars(status_line, string, 1, 72);
	if (not odd(return)) then $signal(return);

	return:=$end_display_update(status_line);
	if (not odd(return)) then $signal(return);

	ifc$update_status_numbers:=ss$_normal;
end;

[global] function ifc$update_status_room(
	var string : varying[$u1] of char) : unsigned;

var	return : unsigned;
begin
	return:=$begin_display_update(status_line);
	if (not odd(return)) then $signal(return);

	return:=$erase_chars(status_line, 31, 1, 1);
	if (not odd(return)) then $signal(return);

	return:=$put_chars(status_line, string, 1, 1);
	if (not odd(return)) then $signal(return);

	return:=$end_display_update(status_line);
	if (not odd(return)) then $signal(return);

	ifc$update_status_room:=ss$_normal;
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

procedure write_message(
	column : integer;
	var message_ptr : $pointer;
	fao_count : integer;
	fao_block : $pointer);

var	fao_desc, desc : $descriptor;
	attributes, return : unsigned;
	line_fao_count : integer;
	fao_buffer : varying[132] of char;
begin
	desc.dsc$w_length:=0;
	desc.dsc$b_dtype:=dsc$k_dtype_t;
	desc.dsc$b_class:=dsc$k_class_s;
	desc.dsc$a_pointer:=0;

	if (message_ptr.address=0) then
		put_scroll_dx(1, desc, 0)
	else
	while (message_ptr.word_ptr^<>0) do
	  begin
		desc.dsc$w_length:=message_ptr.byte_ptr^;

		message_ptr.address:=message_ptr.address + 1;
		line_fao_count:=message_ptr.byte_ptr^;

		message_ptr.address:=message_ptr.address + 1;
		attributes:=message_ptr.byte_ptr^;

		message_ptr.address:=message_ptr.address + 1;
		desc.dsc$a_pointer:=message_ptr.address;

		message_ptr.address:=message_ptr.address + desc.dsc$w_length;
		if (line_fao_count=0) then
		  begin
			return:=put_scroll_dx(column, desc, attributes);
			if (not odd(return)) then $signal(return);
		  end
		else
		  begin
			return:=$$faol(desc, fao_buffer.length,
				fao_buffer.body, fao_block.address);
			if (not odd(return)) then $signal(return);

			correct_English(fao_buffer);

			fao_desc.dsc$w_length:=fao_buffer.length;
			fao_desc.dsc$b_dtype:=dsc$k_dtype_t;
			fao_desc.dsc$b_class:=dsc$k_class_s;
			fao_desc.dsc$a_pointer:=iaddress(fao_buffer.body);
			return:=put_scroll_dx(column, fao_desc, attributes);
			if (not odd(return)) then $signal(return);
			fao_block.address:=fao_block.address +
				(line_fao_count*4);
		  end;
	  end;
end;

[global] function ifc$message_indent_list(
	ap : $message_args) : unsigned;
var	i, fao_count, column : integer;
	message_code : unsigned;
begin
	establish($sig_to_ret);

(*	$begin_display_update(main_display);*)
	column:=ap[1]; i:=2;
	while (i<=ap[0]) do
	  begin
		message_code:=ap[i]; i:=i+1;
		if (i<=ap[0]) then
		  begin
			fao_count:=ap[i]; i:=i+1;
		  end
		else	fao_count:=0;
		if (fao_count=0) then
			write_message(column, message_code, 0, 0)
		else
		  begin
			write_message(column, message_code,
					fao_count, iaddress(ap[i]));
			i:=i+fao_count;
		  end;
	  end;
(*	$end_display_update(main_display);*)

	ifc$message_indent_list:=1;
end;

[global] function ifc$message_list(
	var ap : $message_args) : unsigned;
var	i, fao_count : integer;
	message_code : unsigned;
begin
	establish($sig_to_ret);

(*	$begin_display_update(main_display);*)

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
			write_message(1, message_code, 0, 0)
		else
		  begin
			write_message(1, message_code, fao_count,
					iaddress(ap[i]));
			i:=i+fao_count;
		  end;
	  end;
(*	$end_display_update(main_display);*)

	ifc$message_list:=1;
end;

[global] function ifc$output_broadcast_messages : unsigned;
var	return : unsigned;
	message : varying[255] of char;
begin
	return:=$get_broadcast_message(screen, message);
	while ( odd(return) and (return<>smg$_no_mormsg) ) do
	  begin
		return:=$put_with_scroll(main_display, message,,
						smg$m_reverse,,1);
		if (odd(return)) then
			return:=$get_broadcast_message(screen, message);
	  end;
	ifc$output_broadcast_messages:=return;
end;

end.
