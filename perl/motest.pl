#!/home/raytran/local/perl/bin/perl

$job_handle = "C_02345";
$FAIL_DID = "./fails.txt";

open(DID, "+< $FAIL_DID") || die "Can't open did file\n";
@didlist=<DID>;
close(DID);
$Matched = grep {/$job_handle/} @didlist;
print "$Matched\n";
