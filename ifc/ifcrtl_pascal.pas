[inherit('lib$:typedef',
	 'lib$:rtldef',
	 'lib$:ifc$def',
	 'lib$:ifc$msg_def'),
ident('X01.00-00')]
module ifc$rtl_pascal; (* IFC Run-Time System code in PASCAL *)

(* Edit History                                                             *)
(* 13-Sep-2009  TES  Changed to support conversion from VAX object to	    *)
(*                   MACRO-32 code generation.				    *)
(* 02-Jul-2013  TES  Move IFC$DRAW_MAP in here.				    *)
(*                                                                          *)

type	$room = packed record
			message : integer;
			name : integer;
			class : integer;
			link : packed array[1..14] of integer;
		end;

	$object = packed record
			detail : integer;
			name : integer;
			flags : integer;
			count : integer;
			info : packed array[1..16] of integer;
		end;

	$string = packed record
			length : $ubyte;
			buffer : packed array[1..256] of char;
		end;

	$message = packed record
			length : $ubyte;
			count : $ubyte;
			attributes : $ubyte;
			buffer : packed array[1..256] of char;
		end;

	$pointer = [unsafe, long] packed record
			case integer of
			1 : (address : unsigned);
			2 : (byte_ptr : ^$ubyte);
			3 : (word_ptr : ^$uword);
			4 : (long_ptr : ^unsigned);
			5 : (room_ptr : ^$room);
			6 : (object_ptr : ^$object);
			7 : (string_ptr : ^$string);
			8 : (message_ptr : ^$message);
		   end;

[global] function ifc$get_room_info(
	var table : unsigned;
	room_number : integer;
	var description : unsigned;
	var name : $quad;
	var link : [truncate] packed array[$l1..$u1:integer] of $ubyte;
	var class : [truncate] integer) : unsigned;

var	n, p : $pointer;
	return : unsigned;
	i : integer;
begin
	establish($sig_to_ret);
	if (room_number<1) then $signal(ifc$_badroom);

	p.address:=iaddress(table) + (room_number-1)*68;

	description:=p.room_ptr^.message;

	if present(class) then class:=p.room_ptr^.class;
	if present(link) then
		for i:=1 to 14 do link[i]:=p.room_ptr^.link[i];

	n:=p.room_ptr^.name;
	return:=$copy_r_dx(n.byte_ptr^, n.address+1, name);
	if (not odd(return)) then $signal(return);

	ifc$get_room_info:=1;
end;

[global] function ifc$get_object_info(
	var table : unsigned;
	object_number : integer;
	var detail : unsigned;
	var name : varying[$u1] of char;
	var flags : [truncate] unsigned;
	var count : [truncate] integer;
	var info : packed array[$l2..$u2:integer] of $ubyte) : unsigned;

var	n, p : $pointer;
	return : unsigned;
	i : integer;
begin
	establish($sig_to_ret);
	if (object_number<1) then $signal(ifc$_badobj);

	p:=iaddress(table) + (object_number-1)*80;

	detail := p.object_ptr^.detail;

	if present(flags) then
	  begin
		flags:=p.object_ptr^.flags;
		if (present(count)) then
		  begin
			count:=p.object_ptr^.count;
			for i:=1 to count do
				info[i]:=p.object_ptr^.info[i];
		  end;
	  end;

	n:=p.object_ptr^.name;
	return:=$copy_r_vs(n.byte_ptr^, n.address+1, name);
	if (not odd(return)) then $signal(return);

	ifc$get_object_info:=1;
end;

[global] function ifc$draw_map(
	var room_table : unsigned;
	room_max : integer;
	graph_name : [class_s] packed array[$l3..$u3:integer] of char;
	map_filename : [class_s] packed array[$l4..$u4:integer] of char
	) : unsigned;

const	number_directions = 10;
	direction_length = 10;

type	$direction_table = array[1..number_directions] of $symbol_string;

var	map_file : text;
	i,j : integer;
	d, n, p : $pointer;
	direction_table : $direction_table := (
		'north', 'south', 'east', 'west', 'north east',
		'north west', 'south east', 'south west',
		'up', 'down');

procedure writexml(
	buffer : varying[$u] of char;
	length : integer);

var	j : integer;
	chr : char;

begin

	for j:=1 to length do
	  begin
		chr:=buffer[j];
		case (chr) of
		'<':	write(map_file, '&lt;');
		'>':	write(map_file, '&gt;');
		'&':	write(map_file, '&amp;');
		otherwise
		  begin
			if (chr = '"') then
			  write(map_file, '\');
			write(map_file, chr);
		  end;
		end;
	  end;
end; (* writexml *)

begin
	establish($sig_to_ret);

	(* test to null stuff *)

        open(map_file, map_filename, history:=new, record_type:=stream_lf,
		record_length:=32767);
        rewrite(map_file);
        writeln(map_file, 'graph ', graph_name,' {');
	writeln(map_file, 'overlap=scale;');
	writeln(map_file, 'node [shape=box,style=filled];');

        for i:=1 to room_max do
          begin
		p:=iaddress(room_table) + (i-1)*68;
		d:=p.room_ptr^.message;
		n:=p.room_ptr^.name;

		write(map_file, i, ' [');

		write(map_file, 'label="', substr(n.string_ptr^.buffer,1,
						  n.string_ptr^.length),'",');

		write(map_file, 'tooltip="');
		write(map_file, '<h1>', substr(n.string_ptr^.buffer,1,
					       n.string_ptr^.length), '</h1>');
		write(map_file, '<h2>Description</h2>');
		write(map_file, '<p>');
		while (d.word_ptr^ <> 0) do
		  begin
			writexml(d.message_ptr^.buffer, d.message_ptr^.length);
			write(map_file, ' ');
			d:=d.address+d.message_ptr^.length+3;
		  end;
		write(map_file, '</p>');
		write(map_file, '<h2>Objects</h2>');
		write(map_file, '"');

(*

--Try making the rooms and elipse ---

Tooltip=
<h1>room name</h1>
<h2>Description</h2>
<p>
...descirption
</p>
<h2>Objects</h2>
<ul>
  <li>object</li>
</ul>

*)

		writeln(map_file, '];');

		for j:=1 to 10 do
		  if (p.room_ptr^.link[j] <> 0) then
		    begin
		      writeln(map_file, i, ' -- ', p.room_ptr^.link[j],
				' /* ', direction_table[j], '*/');

(*

Check to see if the room we are connecting to is less than us (this means it
has already been described).  It must be less so that paths to ourselves are
not dropped.  This should fix it so that we only get one link between rooms,
rather than two.

Not sure how this will look, so try it out and see.

*)

		    end;
          end;

        writeln(map_file, '};');
        close(map_file);

        ifc$draw_map:=1;
end;

end.
