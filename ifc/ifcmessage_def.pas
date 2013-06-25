module ifc$message_def;

[external(ifc$compile_messages)] procedure $compile_messages(
	message_filename : varying[$u1] of char;
	object_filename : varying[$u2] of char;
	def_filename : varying[$u3] of char);
	extern;

end.
