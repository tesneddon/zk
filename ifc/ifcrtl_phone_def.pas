[inherit('lib$:typedef')]
module ifc$rtl_phone_def;

[external(ifc$phone_play)] function $phone_play(
	name : varying[$u1] of char;
	interruptible : boolean := true) : char;
	extern;

[external(ifc$phone_get_key)] function $phone_get_key(
	timeout : integer := 0) : char;
	extern;

[external(ifc$phone_get_digits)] function $phone_get_digits(
	var s : varying[$u1] of char;
	max : integer;
	timeout : integer := 0) : unsigned;
	extern;

[external(ifc$phone_get_spelled)] function $phone_get_spelled(
	var s : varying[$u1] of char;
	max : integer) : unsigned;
	extern;

[external(ifc$phone_get_heard)] function $phone_get_heard(
	var s : varying[$u1] of char) : unsigned;
	extern;

[external(ifc$phone_set_line)] procedure $phone_set_line(
	line : varying[$u1] of char);
	extern;

[external(ifc$phone_say)] procedure $phone_say(
	line : varying[$u1] of char;
	interruptible : boolean := true);
	extern;

[external(ifc$phone_header)] function $phone_header(
	name : varying[$u1] of char;
	var value : varying[$u2] of char) : boolean;
	extern;

[external(ifc$phone_interrupted)] function $phone_interrupted : boolean;
	extern;
end.
