[inherit('lib$:typedef')] module sysdef;

const	dvi$_unit = 12;
	jpi$_username = 514;
	syi$_version = 4096;
	syi$_sid = 4097;
	syi$_node_swtype = 4309;
	syi$_node_swvers = 4310;
	syi$_node_hwtype = 4311;

type	$exit_block = record
			forward_link : unsigned;
			exit_handler : unsigned;
			arg_count : unsigned;
			condition : unsigned;
			param1 : [unsafe] unsigned;
			param2 : [unsafe] unsigned;
			param3 : [unsafe] unsigned;
		      end;

	$item = record
			buffer_length : $uword;
			item_code : $uword;
			buffer_address : unsigned;
			return_length_address : unsigned;
		end;
	$item_list = packed array[1..10] of $item;

	$signal_arg_vector = packed array[0..255] of [unsafe] integer;
	$mech_arg_vector = packed array[0..4] of [unsafe] integer;

var	ss$_normal,
	ss$_created,
	ss$_msgnotfnd,
	ss$_continue,
	ss$_resignal,
	ss$_unwind,
	ss$_mbfull,
	ss$_msgnotfnd,
	rms$_eof,
	rms$_fnf,
	rms$_nmf:
		 [external, value] unsigned;

[asynchronous, external(sys$getsyiw)] function $getsyiw(
	efn : unsigned := %immed 0;
	var csidadr : unsigned := %immed 0;
	%stdescr nodename : packed array[$l1..$u1:integer] of char := %immed 0;
	var itmlst : $item_list;
	var iosb : $uquad := %immed 0;
	%immed astadr : unsigned := %immed 0;
	%immed astprm : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$getjpiw)] function $getjpiw(
	efn : unsigned := %immed 0;
	var pidadr : unsigned := %immed 0;
	%stdescr prcnam : packed array[$l1..$u1:integer] of char := %immed 0;
	var itmlst : $item_list;
	var iosb : $uquad := %immed 0;
	%immed astadr : unsigned := %immed 0;
	%immed astprm : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$putmsg)] procedure $putmsg(
	var msgvec : $signal_arg_vector;
	%immed [unbound] function message_routine(
			var message : $uquad) : unsigned := %immed 0;
	%stdescr facnam : packed array[$l1..$u1:integer] of char := %immed 0;
	%immed actprm : unsigned := %immed 0);
	extern;

[asynchronous, external(sys$unwind)] procedure $unwind(
	var depadr : unsigned := %immed 0;
	%immed newpc : unsigned := %immed 0);
	extern;

[asynchronous, external(sys$setrwm)] function $setrwm(
	%immed watflg : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$getdvi)] function $getdvi(
	efn : unsigned := %immed 0;
	%immed chan : $uword := %immed 0;
	%stdescr devnam : packed array[$l1..$u1:integer]
				of char := %immed 0;
	var item_list : $item_list;
	var iosb : $quad := %immed 0;
	%immed astadr : unsigned := %immed 0;
	%immed astprm : unsigned := %immed 0;
	%immed nullarg : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$exit)] function $exit(
	%immed code : unsigned) : unsigned;
	extern;

[asynchronous, external(sys$crembx)] function $crembx(
	%immed prmflg : unsigned := %immed 0;
	var chan : [unsafe] $uword;
	%immed maxmsg : unsigned := %immed 0;
	%immed bufqio : unsigned := %immed 0;
	%immed promsk : unsigned := %immed 0;
	%immed acmode : unsigned := %immed 0;
	%stdescr lognam : packed array[$l1..$u1 : integer]
				of char := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$delmbx)] function $delmbx(
	%immed chan : [unsafe] $uword) : unsigned;
	extern;

[asynchronous, external(sys$dclexh)] function $dclexh(
	var desblk : $exit_block) : unsigned;
	extern;

[asynchronous, external(sys$fao)] function $fao(
	%stdescr ctrstr : packed array[$l1..$u1:integer] of char;
	var outlen : $uword := %immed 0;
	%stdescr outbuf : packed array[$l2..$u2:integer] of char;
	%immed args : [list] unsigned) : unsigned;
	extern;

[asynchronous, external(sys$getmsg)] function $getmsg(
	%immed msgid : unsigned;
	var msglen : $uword;
	%stdescr bufadr : packed array[$l1..$u1:integer] of char;
	%immed flags : unsigned := %immed 0;
	var outadr : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$gettim)] function $gettim(
	var timadr : $quad) : unsigned;
	extern;

[asynchronous, external(sys$bintim)] function $bintim(
	%stdescr timbuf : packed array[$l1..$u1:integer] of char;
	var timadr : $quad) : unsigned;
	extern;

[asynchronous, external(sys$asctim)] function $asctim(
	var timlen : $uword := %immed 0;
	%stdescr timbuf : packed array[$l1..$u1:integer] of char;
	%ref timadr : $quad;
	%immed cvtflg : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$schdwk)] function $schdwk(
	%ref pidadr : unsigned := %immed 0;
	%stdescr prcnam : packed array[$l1..$u1:integer]
				of char := %immed 0;
	daytim : $quad;
	reptim : $quad := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$wake)] function $wake(
	%ref pidadr : unsigned := %immed 0;
	%stdescr prcnam : packed array[$l1..$u1:integer]
				of char := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$hiber)] function $hiber : unsigned;
	extern;

[asynchronous, external(sys$assign)] function $assign(
	%stdescr devnam : packed array[$l1..$u1:integer] of char;
	var chan : [unsafe] $uword;
	%immed acmode : unsigned := %immed 0;
	%stdescr mbxnam : packed array[$l2..$u2:integer]
				of char := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$dassgn)] function $dassgn(
	%immed chan : [unsafe] $uword) : unsigned;
	extern;

[asynchronous, external(sys$cancel)] function $cancel(
	%immed chan : [unsafe] $uword) : unsigned;
	extern;

[asynchronous, external(sys$faol)] function $faol(
	%stdescr ctrstr : packed array[$l1..$u1:integer] of char;
	var outlen : $uword := %immed 0;
	%stdescr outbuf : packed array[$l2..$u2:integer] of char;
	%immed prmlst : unsigned) : unsigned;
	extern;
end.
