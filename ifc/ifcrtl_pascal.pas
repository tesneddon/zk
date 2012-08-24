[inherit('lib$:typedef',
	 'lib$:rtldef',
	 'lib$:ifc$msg_def'),
ident('X01.00-00')]
module ifc$rtl_pascal; (* IFC Run-Time System code in PASCAL *)

(* Edit History                                                             *)
(* 13-Sep-2009  TES  Changed to support conversion from VAX object to	    *)
(*                   MACRO-32 code generation.				    *)
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

	$pointer = [unsafe, long] packed record
			case integer of
			1 : (address : unsigned);
			2 : (byte_ptr : ^$ubyte);
			3 : (word_ptr : ^$uword);
			4 : (long_ptr : ^unsigned);
			5 : (room_ptr : ^$room);
			6 : (object_ptr : ^$object);
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

end.
