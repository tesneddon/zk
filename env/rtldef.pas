[inherit('lib$:typedef')] module rtldef;

const	lib$m_cli_ctrlt = %x00100000;
	lib$m_cli_ctrly = %x02000000;

(* Incompatible with IEEE FP; use Pascal RANDOM instead
[asynchronous, external(mth$random)] function $random(
	var seed : unsigned) : real;
	extern;
*)

[asynchronous, external(lib$day_of_week)] function $day_of_week(
	var time : $uquad := %immed 0;
	var day_number : integer) : unsigned;
	extern;

[asynchronous, external(str$replace)] function $replace(
	var dst_str : varying[$u1] of char;
	var src_str : varying[$u2] of char;
	start_pos : integer;
	end_pos : integer;
	var rep_str : varying[$u3] of char) : unsigned;
	extern;

[asynchronous, external(str$append)] function $append_vs_dx(
	var dst_str : varying[$u1] of char;
	var src_str : $uquad) : unsigned;
	extern;

[asynchronous, external(str$upcase)] function $upcase(
	var dst_str : varying[$u1] of char;
	src_str : varying[$u2] of char) : unsigned;
	extern;

[asynchronous, external(str$dupl_char)] function $dupl_char(
	var dst_str : varying[$u1] of char;
	length : integer;
	character : char) : unsigned;
	extern;

[asynchronous, external(lib$find_file)] function $find_file(
	file_spec : varying[$u1] of char;
	var result_spec : varying[$u2] of char;
	var context : unsigned;
	default_spec : varying[$u4] of char := %immed 0;
	related_spec : varying[$u5] of char := %immed 0;
	var stv_addr : unsigned := %immed 0;
	user_flags : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(lib$find_file_end)] function $find_file_end(
	context : unsigned) : unsigned;
	extern;

[asynchronous, external(lib$scopy_dxdx)] function $copy_dx_vs(
	var src_str : $quad;
	var dst_str : varying[$u1] of char) : unsigned;
	extern;

[asynchronous, external(lib$scopy_dxdx)] function $copy_vs_dx(
	var src_str : varying[$u1] of char;
	var dst_str : $quad) : unsigned;
	extern;

[asynchronous, external(lib$scopy_r_dx)] function $copy_r_dx(
	src_len : $uword;
	%immed src_str : unsigned;
	var dst_str : $quad) : unsigned;
	extern;

[asynchronous, external(lib$scopy_r_dx)] function $copy_r_vs(
	src_len : $uword;
	%immed src_str : unsigned;
	var dst_str : varying[$u1] of char) : unsigned;
	extern;

[asynchronous, external(lib$signal)] function $signal(
	%immed condition : unsigned;
	%immed additonal : [list] unsigned) : unsigned;
	extern;

(* Condition handler which returns signal to caller of establisher *)
[asynchronous, external(lib$sig_to_ret)] function $sig_to_ret(
	var sig_args : unsigned;
	var mech_args : unsigned) : unsigned;
	extern;

(* Subtract multiple precision *)
[asynchronous, external(lib$subx)] function $subx(
	var a : $quad;
	var b : $quad;
	var result : $quad;
	%ref length : unsigned := %immed 0) : unsigned;
	extern;

(* Add multiple precision *)
[asynchronous, external(lib$addx)] function $addx(
	var a : $quad;
	var b : $quad;
	var result : $quad;
	%ref length : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(lib$disable_ctrl)] function $disable_ctrl(
	disable_mask : unsigned;
	var old_mask : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(lib$enable_ctrl)] function $enable_ctrl(
	enable_mask : unsigned;
	var old_mask : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(str$compare)] function $compare(
	var src1_str : varying[$u1] of char;
	var src2_str : varying[$u2] of char) : integer;
	extern;

[asynchronous, external(str$compare)] function $compare_vs_dx(
	var src1_str : varying[$u1] of char;
	var src2_str : $quad) : integer;
	extern;

function lib$put_output : unsigned; extern;
[asynchronous, external(lib$put_output)] function $put_output(
	msg_str: varying[$u1] of char) : unsigned;
	extern;

function lib$get_input : unsigned; extern;
[asynchronous, external(lib$get_input)] function $get_input(
	var msg_str : varying[$u1] of char;
	prompt_str : varying[$u2] of char := %immed 0) : unsigned;
	extern;

[asynchronous, external(lib$get_foreign)] function $get_foreign(
	var get_str : varying[$u1] of char;
	user_prompt : varying[$u2] of char := %immed 0;
	var out_len : $uword := %immed 0;
	var force_prompt : unsigned := %immed 0) : unsigned;
	extern;

[asynchronous, external(lib$get_logical)] function $get_logical(
	%stdescr log_nam : packed array[$l1..$u1:integer] of char;
	var res_str : packed array[$l2..$u2:integer] of char;
	var res_len : $uword := %immed 0;
	tbl_nam : varying[$u4] of char := %immed 0;
	var max_index : integer := %immed 0;
	index : unsigned := %immed 0;
	acmode : $ubyte := %immed 0;
	flags : unsigned := %immed 0) : unsigned;
	extern;

end.
