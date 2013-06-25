module ifc$room_def;

[external(ifc$compile_rooms)] procedure $compile_rooms(
	room_filename : varying[$u1] of char;
	object_filename : varying[$u2] of char;
	def_filename : varying[$u3] of char);
	extern;

end.
