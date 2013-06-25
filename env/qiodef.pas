[inherit('lib$:typedef')] module qiodef;

const	io$_setmode = 35;
	io$_writevblk = 48;
	io$_readvblk = 49;
	io$m_ctrlcast = 256;
	io$m_ctrlyast = 128;
	io$m_readattn = 128;
	io$m_wrtattn = 256;
	io$m_now = 64;

type	$iosb_mailbox = [quad] record
				status : [unsafe] $uword;
				byte_count : $uword;
				pid : unsigned;
			       end;

[asynchronous, external(sys$qiow)] function $qiow_ast(
	%immed efn : unsigned := %immed 0;
	%immed chan : [unsafe] $uword;
	%immed func : unsigned;
	var iosb : $quad := %immed 0;
	%immed [unbound, asynchronous] procedure $astadr(
		var ast_param, r0, r1, pc, psl : unsigned) := %immed 0;
	%immed astprm : [unsafe] unsigned := %immed 0;
	%immed [unbound, asynchronous] procedure $ast_routine(
		var ast_param, r0, r1, pc, psl : unsigned) := %immed 0;
	%immed ast_param : [unsafe] unsigned := %immed 0;
	%immed access_mode : unsigned := %immed 0;
	%immed p4 : unsigned := %immed 0;
	%immed p5 : unsigned := %immed 0;
	%immed p6 : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$qiow)] function $qiow(
	%immed efn : unsigned := %immed 0;
	%immed chan : [unsafe] $uword;
	%immed func : unsigned;
	var iosb : $quad := %immed 0;
	%immed [unbound, asynchronous] procedure $astadr(
		var ast_param, r0, r1, pc, psl : unsigned) := %immed 0;
	%immed astprm : [unsafe] unsigned := %immed 0;
	%immed buffer : unsigned := %immed 0;
	%immed bufsiz : unsigned := %immed 0;
	%immed p3 : unsigned := %immed 0;
	%immed p4 : unsigned := %immed 0;
	%immed p5 : unsigned := %immed 0;
	%immed p6 : unsigned := %immed 0) : unsigned;
	extern;

end.
