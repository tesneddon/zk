[inherit('lib$:typedef')] module lockdef;

const	lck$m_valblk = 1;
	lck$m_convert = 2;
	lck$m_noqueue = 4;
	lck$m_syncsts = 8;
	lck$m_system = 16;
	lck$m_noquota = 32;
	lck$m_cvtsys = 64;
	lck$m_recover = 128;
	lck$m_protect = 256;
	lck$m_nodlckwt = 512;
	lck$m_nodlckblk = 1024;
	lck$m_deqall = 1;
	lck$m_cancel = 2;
	lck$m_invvalblk= 4;

	lck$k_nlmode = 0;
	lck$k_crmode = 1;
	lck$k_cwmode = 2;
	lck$k_prmode = 3;
	lck$k_pwmode = 4;
	lck$k_exmode = 5;

type	$lock_status_block = [quad] record
				condition : $uword;
				reserved : $uword;
				lock_id : unsigned;
				end;

	$lock_value_block = [byte(16)] record end;

[asynchronous, external(sys$deq)] function $deq(
	%immed lkid : unsigned := %immed 0;
	var valblk : $lock_value_block := %immed 0;
	%immed acmode : unsigned := %immed 0;
	%immed flags : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(sys$enqw)] function $enqw(
	%ref efn : unsigned := %immed 0;
	%immed lkmode : unsigned;
	var lksb : $lock_status_block;
	%immed flags : unsigned := %immed 0;
	%stdescr resnam : packed array[$l1..$u1:integer]
				of char := %immed 0;
	%immed parid : unsigned := %immed 0;
	%immed astadr : unsigned := %immed 0;
	%immed astprm : unsigned := %immed 0;
	%immed blkast : unsigned := %immed 0;
	%immed acmode : unsigned := %immed 0;
	%immed nullarg : unsigned := %immed 0) : unsigned;
	extern;

end.
