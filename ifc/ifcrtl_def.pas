[inherit('lib$:typedef')]
module ifc$rtl_def;

[asynchronous, external(ifc$message)] function $message(
	%immed message_codes : [list] unsigned) : unsigned;
	extern;

[asynchronous, external(ifc$message_indent)] function $message_indent(
	%immed message_codes : [list] unsigned) : unsigned;
	extern;

[external(ifc$get_room_info)] function $get_room_info(
	var table : unsigned;
	room_number : unsigned;
	var message_code : unsigned;
	var name : varying[$u1] of char;
	var link : [truncate] packed array[$l1..$u2:integer] of $ubyte;
	var class : [truncate] integer) : unsigned;
	extern;

[external(ifc$get_object_info)] function $get_object_info(
	var table : unsigned;
	object_number : integer;
	var detail : unsigned;
	var name : varying[$u1] of char;
	var flags : [truncate] unsigned;
	var count : [truncate] integer;
	var info : packed array[$l2..$u2:integer] of $ubyte) : unsigned;
	extern;

[external(ifc$init_screen)] function $init_screen(
	key_logical_name : varying[$u1] of char;
	[unbound, asynchronous] procedure ast_routine;
	ast_argument : [unsafe] unsigned) : unsigned;
	extern;

[external(ifc$finish_screen)] function $finish_screen : unsigned;
	extern;

[external(ifc$update_status_room)] function $update_status_room(
	var string : varying[$u1] of char) : unsigned;
	extern;

[external(ifc$update_status_numbers)] function $update_status_numbers(
	var score : integer;
	var moves : integer) : unsigned;
	extern;

[external(ifc$get_composed_line)] function $get_composed_line(
	var string : varying[$u1] of char;
	prompt_string : varying[$u2] of char) : unsigned;
	extern;

[external(ifc$get_string)] function $get_string(
	var string : varying[$u1] of char;
	prompt_string : varying[$u2] of char) : unsigned;
	extern;

[external(ifc$output_broadcast_messages)] function
		$output_broadcast_messages : unsigned;
	extern;

[external(ifc$draw_map)] function $draw_map(
        var room_table : unsigned;
        room_max : integer;
	graph_name : [class_s] packed array[$l3..$u3:integer] of char;
        map_filename : [class_s] packed array[$l4..$u4:integer] of char
	) : unsigned;
	extern;

end.
