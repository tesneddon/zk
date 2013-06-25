module types;

type	$ubyte = [byte] 0..2**8-1;
	$byte = [byte] -(2**7)..2**7-1;
	$uword = [word] 0..2**16-1;
	$quad  = [quad, unsafe] record l0 : unsigned; l1 : integer end;
	$uquad = [quad, unsafe] record l0, l1 : unsigned end;
end.
