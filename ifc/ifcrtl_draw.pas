[inherit('lib$:typedef',
	 'lib$:rtldef',
	 'lib$:ifc$msg_def',
	 'lib$:ifc$message_def',
	 'lib$:ifc$room_def',
	 'lib$:ifc$object_def'),
ident('X01.00-00')]
module ifc$rtl_draw(output);

(* Edit History                                                             *)
(* 01-Jul-2013  TES  Initial coding.					    *)
(*                                                                          *)

[global] function ifc$draw_map(
	var room_table : unsigned;
	var object_table : unsigned;
	var desc_table : unsigned;
	start_room : integer;
	map_filename : varying[$u1] of char) : unsigned;

var	map_file : text;

begin
	open(map_file, map_filename, history:=new);
	rewrite(map_file);
	writeln(map_file, '<?xml version="1.0" standalone="no"?>');
	writeln(map_file, '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" ');
	writeln(map_file, '  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">');
	writeln(map_file, '<svg width="5cm" height="4cm" version="1.1"');
	writeln(map_file, '     xmlns="http://www.w3.org/2000/svg">');

	writeln('</svg>');
	close(map_file);

	ifc$draw_map:=1;
end;

end.
