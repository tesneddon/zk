# zk-hear.sed: fixes to what the recogniser heard, applied by ifc-hear.
# The text is in capitals and still has its punctuation; afterwards
# everything but letters, digits and single spaces is taken out.  The
# personnel interview wants numbers as digits: "four" is 4, "one bit"
# is 1BIT.  FOR is not made 4: the read-back lets the caller try again.
s/\bZERO\b/0/g
s/\bONE\b/1/g
s/\bTWO\b/2/g
s/\bTHREE\b/3/g
s/\bFOUR\b/4/g
s/\bFIVE\b/5/g
s/\bSIX\b/6/g
s/\bSEVEN\b/7/g
s/\bEIGHT\b/8/g
s/\bNINE\b/9/g
