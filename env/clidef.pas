[inherit('lib$:typedef')]
module clidef;

[external(cli$dcl_parse)] function $dcl_parse(
	var command_string : varying[$u1] of char := %immed 0;
	var command_table : unsigned;
	%immed [unbound] function param_routine : unsigned := %immed 0;
	%immed [unbound] function prompt_routine : unsigned := %immed 0;
	prompt_string : varying[$u2] of char := %immed 0) : unsigned;
	extern;

[external(cli$dispatch)] function $dispatch(
	%immed userarg : unsigned := %immed 0) : unsigned;
	extern;

[external(cli$get_value)] function $get_value(
	entity_desc : varying[$u1] of char;
	var retdesc : varying[$u2] of char;
	var retlength : $uword := %immed 0) : unsigned;
	extern;

[external(cli$present)] function $present(
	entity_desc : varying[$u1] of char) : unsigned;
	extern;
end.
