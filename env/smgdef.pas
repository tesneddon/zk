[inherit('lib$:typedef')]
module smgdef;

const	smg$m_reverse = 2;
	smg$m_border = 1;
	smg$k_top = 0;
	smg$k_bottom = 1;
	smg$k_left = 2;
	smg$k_right = 3;

	io$m_noecho = 64;
	io$m_trmnoecho = 4096;

var	smg$_pasalrexi,
	smg$_no_mormsg,
	smg$_eof : [external, value] unsigned;

[external(smg$create_pasteboard)] function $create_pasteboard(
	var new_pasteboard_id : unsigned;
	%stdescr output_device : packed array[$l1..$u1:integer]
					of char := %immed 0;
	var pb_rows : unsigned := %immed 0;
	var pb_columns : unsigned := %immed 0;
	preserve_screen_flag : unsigned := %immed 0) : unsigned;
	extern;

[external(smg$delete_pasteboard)] function $delete_pasteboard(
	pasteboard_id : unsigned;
	clear_screen_flag : unsigned := %immed 0) : unsigned;
	extern;

[external(smg$create_virtual_display)] function $create_virtual_display(
	num_rows : unsigned;
	new_columns : unsigned;
	var new_display_id : unsigned;
	display_attributes : unsigned := %immed 0;
	video_attributes : unsigned := %immed 0;
	char_set : unsigned := %immed 0) : unsigned;
	extern;

[external(smg$delete_virtual_display)] function $delete_virtual_display(
	display_id : unsigned) : unsigned;
	extern;

[external(smg$paste_virtual_display)] function $paste_virtual_display(
	display_id : unsigned;
	pasteboard_id : unsigned;
	pasteboard_row : unsigned;
	pasteboard_column : unsigned) : unsigned;
	extern;

[external(smg$put_chars)] function $put_chars(
	display_id : unsigned;
	text_line : varying[$u1] of char;
	line_number : integer := %immed 0;
	column_number : integer := %immed 0;
	erase_flag : unsigned := %immed 0;
	rendition_set : unsigned := %immed 0;
	complement_set : unsigned := %immed 0;
	char_set : unsigned := %immed 0) : unsigned;
	extern;

[external(smg$put_with_scroll)] function $put_with_scroll(
	display_id : unsigned;
	text_line : varying[$u1] of char := %immed 0;
	direction : unsigned := %immed 0;
	rendition_set : unsigned := %immed 0;
	complement_set : unsigned := %immed 0;
	wrap_flag : unsigned := %immed 0;
	char_set : unsigned := %immed 0) : unsigned;
	extern;

[external(smg$put_with_scroll)] function $put_with_scroll_dx(
	display_id : unsigned;
	var text_line : $uquad := %immed 0;
	direction : unsigned := %immed 0;
	rendition_set : unsigned := %immed 0;
	complement_set : unsigned := %immed 0;
	wrap_flag : unsigned := %immed 0;
	char_set : unsigned := %immed 0) : unsigned;
	extern;

[external(smg$label_border)] function $label_border(
	display_id : unsigned;
	label_text : varying[$u1] of char := %immed 0;
	position : unsigned := %immed 0;
	units : unsigned := %immed 0;
	rendition_set : unsigned := %immed 0;
	complement_set : unsigned := %immed 0;
	char_set : unsigned := %immed 0) : unsigned;
	extern;

[external(smg$begin_pasteboard_update)] function $begin_pasteboard_update(
	pasteboard_id : unsigned) : unsigned;
	extern;

[external(smg$end_pasteboard_update)] function $end_pasteboard_update(
	pasteboard_id : unsigned) : unsigned;
	extern;

[external(smg$begin_display_update)] function $begin_display_update(
	display_id : unsigned) : unsigned;
	extern;

[external(smg$end_display_update)] function $end_display_update(
	display_id : unsigned) : unsigned;
	extern;

[external(smg$unpaste_virtual_display)] function $unpaste_virtual_display(
	display_id : unsigned;
	pasteboard_id : unsigned) : unsigned;
	extern;

[external(smg$change_virtual_display)] function $change_virtual_display(
	display_id : unsigned;
	rows : unsigned;
	columns : unsigned;
	display_attributes : unsigned := %immed 0;
	video_attributes : unsigned := %immed 0;
	char_set : unsigned := %immed 0) : unsigned;
	extern;

[external(smg$return_cursor_pos)] function $return_cursor_pos(
	display_id : unsigned;
	var rows : unsigned;
	var columns : unsigned) : unsigned;
	extern;

[external(smg$set_cursor_abs)] function $set_cursor_abs(
	display_id : unsigned;
	rows : unsigned := %immed 0;
	columns : unsigned := %immed 0) : unsigned;
	extern;

[external(smg$scroll_display_area)] function $scroll_display_area(
	display_id : unsigned;
	starting_row : unsigned := %immed 0;
	starting_column : unsigned := %immed 0;
	height : unsigned := %immed 0;
	width : unsigned := %immed 0;
	direction : unsigned := %immed 0;
	count : unsigned := %immed 0) : unsigned;
	extern;

[external(smg$erase_chars)] function $erase_chars(
	display_id : unsigned;
	number_of_chars : integer;
	row_number : integer;
	column_number : integer) : unsigned;
	extern;

[external(smg$create_virtual_keyboard)] function $create_virtual_keyboard(
	var keyboard_id : unsigned;
	filespec : varying[$u1] of char := %immed 0;
	default_filespec : varying[$u2] of char := %immed 0;
	var result_filespec : varying[$u3] of char := %immed 0) : unsigned;
	extern;

[external(smg$delete_virtual_keyboard)] function $delete_virtual_keyboard(
	var keyboard_id : unsigned) : unsigned;
	extern;

[external(smg$create_key_table)] function $create_key_table(
	var new_key_table_id : unsigned) : unsigned;
	extern;

[external(smg$load_key_defs)] function $load_key_defs(
	var key_table_id : unsigned;
	var filespec : varying[$u1] of char;
	default_filespec : varying[$u2] of char := %immed 0;
	lognam_flag : unsigned := %immed 0) : unsigned;
	extern;

[external(smg$read_composed_line)] function $read_composed_line(
	keyboard_id : unsigned;
	key_table_id : unsigned;
	var received_text : varying[$u1] of char;
	prompt_string : varying[$u2] of char := %immed 0;
	var received_string_length : $uword := %immed 0;
	display_id : unsigned := %immed 0) : unsigned;
	extern;

[external(smg$read_string)] function $read_string(
	keyboard_id : unsigned;
	var received_text : varying[$u1] of char;
	prompt_string : varying[$u2] of char := %immed 0;
	max_length : unsigned := %immed 0;
	modifiers : unsigned := %immed 0;
	timeout : unsigned := %immed 0;
	terminator_set : packed array[$l3..$u3:integer] of char := %immed 0;
	var received_string_length : $uword := %immed 0;
	terminator_code : $uword := %immed 0;
	display_id : unsigned := %immed 0) : unsigned;
	extern;

[external(smg$set_broadcast_trapping)] function $set_broadcast_trapping(
	pasteboard_id : unsigned;
	%immed [unbound, asynchronous] procedure ast_routine := %immed 0;
	%immed ast_argument : [unsafe] unsigned := %immed 0) : unsigned;
	extern;

[external(smg$get_broadcast_message)] function $get_broadcast_message(
	pasteboard_id : unsigned;
	var message : varying[$u1] of char := %immed 0;
	var message_length : $uword := %immed 0) : unsigned;
	extern;
end.
