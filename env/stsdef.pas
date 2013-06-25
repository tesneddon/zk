module stsdef;

const	sts$k_warning = 0;
	sts$k_success = 1;
	sts$k_error = 2;
	sts$k_informational = 3;
	sts$k_severe = 4;

	sts$m_msg_no = 2**3;
	sts$m_specific = 2**15;
	sts$m_facility = 2**16;
	sts$m_customer = 2**27;
	sts$m_inhibit = 2**28;

end.
