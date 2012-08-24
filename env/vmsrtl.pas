[inherit('types', 'dscdef')] module vmsrtl;

type	$item = record
			buffer_length : $uword;
			item_code : $uword;
			buffer_address : unsigned;
			return_length_address : unsigned;
		end;

	$item_list = array[1..10] of $item;

	$numeric_time = [word(7)] record
				year,
				month,
				day,
				hour,
				minute,
				second,
				hundredth : $uword;
			end;

	$brk_iosb = [quad] record
				condition : $uword;
				success : $uword;
				failed_timeout : $uword;
				failed_nobroad : $uword;
			   end;

[asynchronous, external(lib$signal)] function $signal(
	%immed condition : unsigned;
	%immed additonal : [list] unsigned) : unsigned;
	extern;

[asynchronous, external(lib$get_foreign)] function $get_foreign(
	var get_str : varying[$u1] of char;
	user_prompt : varying[$u2] of char := %immed 0;
	var out_len : $uword := %immed 0;
	var force_prompt : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(cli$dcl_parse)] function $dcl_parse(
	%stdescr command_string : packed array[$l1..$u1:integer] of char;
	var tables : unsigned) : unsigned;
	extern;

[asynchronous, external(cli$present)] function $present(
	%stdescr name : packed array[$l1..$u1:integer] of char) : unsigned;
	extern;

[asynchronous, external(cli$get_value)] function $get_value(
	%stdescr name : packed array[$l1..$u1:integer] of char;
	var ret_buf : varying[$u2] of char) : unsigned;
	extern;

[asynchronous, external(sys$getjpiw)] function $getjpiw(
	%immed event_flag : $uword := %immed 0;
	var pidadr : unsigned := %immed 0;
	var prcnam : unsigned := %immed 0;
	var itmlst : $item_list;
	var iosb : unsigned := %immed 0;
	var astadr : unsigned := %immed 0;
	var astprm : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(str$pos_extr)] function $extract(
	var dst : varying[$u1] of char;
	scr : varying[$u2] of char;
	%ref start : unsigned;
	%ref end_pos : unsigned) : unsigned;
	extern;

[asynchronous, external(str$position)] function $position(
	src_str : varying[$u1] of char;
	sub_str : varying[$u2] of char;
	start_pos : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(lib$sget1_dd)] function $sget1_dd(
	%ref len : $uword;
	var desc : $descriptor) : unsigned;
	extern;

[asynchronous, external(lbr$output_help)] function $output_help(
	%immed [unbound] function output_routine : unsigned;
	var output_width : unsigned := %immed 0;
	help_keys : [class_s] packed array[$l1..$u1:integer] of char;
	help_file : [class_s] packed array[$l2..$u2:integer] of char;
	%ref flags : unsigned;
	%immed [unbound] function input_routine : unsigned) : unsigned;
	extern;

[asynchronous, external, unbound] function lib$put_output : unsigned;
	extern;

[asynchronous, external, unbound] function lib$get_input : unsigned;
	extern;

[asynchronous, external(lib$get_input)] function $get_input(
	var get_str : varying[$u1] of char;
	prompt : varying[$u2] of char) : unsigned;
	extern;

[asynchronous, external(sys$bintim)] function $bintim(
	%stdescr timbuf : packed array[$l1..$u1:integer] of char;
	var timadr : $uquad) : unsigned;
	extern;

[asynchronous, external(sys$asctim)] function $asctim(
	var timlen : $uword := %immed 0;
	%stdescr timbuf : packed array[$l1..$u1:integer] of char;
	%ref timadr : $uquad;
	%immed cvtflg : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$numtim)] function $numtim(
	var timbuf : $numeric_time;
	var timadr : $uquad := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$gettim)] function $gettim(
	var timadr : $uquad) : unsigned;
	extern;
	
[asynchronous, external(lib$subx)] function $subx(
	var a : $uquad;
	var b : $uquad;
	var result : $uquad;
	%ref length : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(lib$addx)] function $addx(
	var a : $uquad;
	var b : $uquad;
	var result : $uquad;
	%ref length : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(lib$day)] function $day(
	var day_number : unsigned;
	var user_time : $uquad := %immed 0;
	var day_time : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$fao)] function $fao(
	%stdescr ctrstr : packed array[$l1..$u1:integer] of char;
	var outlen : $uword := %immed 0;
	%stdescr outbuf : packed array[$l2..$u2:integer] of char;
	%immed params : [list] unsigned) : unsigned;
	extern;

[asynchronous, external(sys$creprc)] function $creprc(
	var pidadr : unsigned := %immed 0;
	%stdescr image : packed array[$l1..$u1:integer] of char;
	%stdescr sys_input : packed array[$l2..$u2:integer]
				of char := %immed 0;
	%stdescr sys_output : packed array[$l3..$u3:integer]
				of char := %immed 0;
	%stdescr sys_error : packed array[$l4..$u4:integer]
				of char := %immed 0;
	var prvadr : $uquad := %immed 0;
	%immed quota : unsigned := %immed 0;
	%stdescr prcnam : packed array[$l5..$u5:integer]
				of char := %immed 0;
	%immed baspri : unsigned := %immed 0;
	%immed uic : unsigned := %immed 0;
	%immed mbxunt : unsigned := %immed 0;
	%immed stsflg : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$hiber)] function $hiber : unsigned;
	extern;

[asynchronous, external(sys$wake)] function $wake(
	pidadr : unsigned := %immed 0;
	%stdescr prcnam : packed array[$l1..$u1:integer]
		of char := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$setimr)] function $setimr(
	%immed efn : unsigned := %immed 0;
	daytim : $uquad;
	%immed [asynchronous, unbound] procedure astadr(
		var i, r0, r1, pc, psl : integer) := %immed 0;
	%immed reqidt : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$brkthru)] function $brkthru(
	%immed efn : unsigned := %immed 0;
	%stdescr msgbuf : packed array[$l1..$u1:integer] of char;
	%stdescr sendto : packed array[$l2..$u2:integer]
				of char := %immed 0;
	%immed sndtyp : unsigned := %immed 0;
	var iosb : $brk_iosb;
	%immed carcon : unsigned := %immed 0;
	%immed flags : unsigned := %immed 0;
	%immed reqid : unsigned := %immed 0;
	%immed timout : unsigned := %immed 0;
	%immed [unbound, asynchronous] procedure astadr := %immed 0;
	%immed astprm : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(lib$put_output)] function $put_output(
	msg_str: varying[$u1] of char) : unsigned;
	extern;

[asynchronous, external(lib$put_output)] function $put_output_dx(
	desc : $descriptor) : unsigned;
	extern;

[asynchronous, external(str$append)] function $append_dx_dx(
	var dst_str : $descriptor;
	var src_str : $descriptor) : unsigned;
	extern;
[asynchronous, external(str$free1_dx)] function $free1_dx(
	var str : $descriptor) : unsigned;
	extern;
end.

