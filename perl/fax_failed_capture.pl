#! /tools/isofax/brcm/perl/bin/perl
# Take a count of the total number of failed jobs

# Log Format
# time_submitted:last_attempt:retry:job_handle

$FAIL_LOG="/tools/isosfax/logs/fail.log";

# DID file stores the fax job handles that we already calculated
$FAIL_DID="/tools/admin/public_html/mrtg/isofax-data/tmp/failed.txt"

open(DID,"+< $FAIL_DID") || die "Can't open did file\n";
@didlist=<DID>;

open(LOG,"<$FAIL_LOG") ||die "Can't open log file\n";
while(<LOG>) {
	($time_submitted,$last_attempt,$retry,$job_handle) = split(:,$_);
	$Matched = grep {/$job_handle/} @didlist;
	if ($Matched eq 0) {
        	$total = $total + 1;
		print DID "$job_handle\n";
	};
};
close (LOG);
close (DID);

print $total;
