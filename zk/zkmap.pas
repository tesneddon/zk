[inherit('lib$:zk$text', 'lib$:zk$room', 'lib$:zk$obj',
	 'ifc$library:ifc$rtl_def')]
program zk$map(input, output);

begin

	if (argc<2) then
	  begin
		writeln('%ZKMAP-F-INSFARG, insufficient arguments');
		writeln('');
		writeln('  ZKMAP - Generate a Graphviz map of ZK');
		writeln('');
		writeln('  $ zkmap map-name output-filename');
		writeln('');
		return 1;
	  end;

	writeln('%ZKMAP-I-NAME, graph will be named ', argv(1));
	writeln('%ZKMAP-I-OUTPUT, writing graph to ', argv(2));

	return $draw_map(zk$room_table, zk$room_max, argv(1), argv(2));
end.
