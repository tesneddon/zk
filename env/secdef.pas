[inherit('lib$:typedef')] module secdef;

const	sec$m_gbl = 1;
	sec$m_crf = 2;
	sec$m_dzro = 4;
	sec$m_wrt = 8;
	sec$m_shmgs = 16;
	sec$m_wrtmod = 192;
	sec$m_amod = 768;
	sec$m_resident = 8192;
	sec$m_perm = 16384;
	sec$m_sysgbl = 32768;
	sec$m_pfnmap = 65536;
	sec$m_expreg = 131072;
	sec$m_protect = 262144;
	sec$m_pagfil = 524288;
	sec$m_execute = 1048576;

[asynchronous, external(sys$crmpsc)] function $crmpsc(
	var inadr : $quad := %immed 0;
	var retadr : $quad := %immed 0;
	%immed acmode : unsigned := %immed 0;
	%immed flags : unsigned := %immed 0;
	%stdescr gsdnam : packed array[$l1..$u1:integer]
				of char := %immed 0;
	ident : $quad := %immed 0;
	%immed relpag : unsigned := %immed 0;
	%immed chan : $uword := %immed 0;
	%immed pagcnt : [unsafe] unsigned := %immed 0;
	%immed vbn : unsigned := %immed 0;
	%immed prot : $uword := %immed 0;
	%immed pfc : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$deltva)] function $deltva(
	inadr : $quad := %immed 0;
	var retadr : $quad := %immed 0;
	%immed acmode : unsigned := %immed 0) : unsigned;
	extern;

end.
