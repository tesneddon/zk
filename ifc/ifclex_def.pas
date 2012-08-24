[inherit('lib$:ifc$def')]
module ifc$lex_def;

[external(ifc$open_lex)]procedure $open_lex(
	source_filename : varying[$u1] of char);
	extern;

[external(ifc$close_lex)]procedure $close_lex;
	extern;

[external(ifc$reset_lex)] procedure $reset_lex(error : boolean);
	extern;

[external(ifc$advance_symbol)]procedure $advance_symbol;
	extern;

[external(ifc$get_symbol)]procedure $get_symbol(
	var symbol : $symbol_desc);
	extern;

[external(ifc$sync_symbol)]procedure $sync_symbol(
	followers : $symbol_set);
	extern;

[external(ifc$test_symbol)]procedure $test_symbol(
	expected, followers : $symbol_set);
	extern;

[external(ifc$defer_error_message)] procedure $defer_error_message(
	code : $error_code;
	string : $symbol_string;
	members : $symbol_set;
	value : $symbol_value);
	extern;
end.
