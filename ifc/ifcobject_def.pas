module ifc$object_def;

[external(ifc$compile_objects)] procedure $compile_objects(
	var source_filename : varying[$u1] of char;
	var object_filename : varying[$u2] of char;
	var def_filename : varying[$u3] of char);
	extern;

end.
