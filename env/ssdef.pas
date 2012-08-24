[inherit('typedef')] module ssdef;

var	ss$_normal,
	ss$_created,
	ss$_msgnotfnd,
	rms$_nmf:
		 [external, value] unsigned;

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
end.
