#! /tools/isofax/brcm/perl/bin/perl
# Take a count of the total number of fax jobs
# input required - s (success) or f (failed) jobs

# Log Format
# Success
# time_submitted:last_attempt:time_sent:c_length:job_ handle
# Failed
# time_submitted:last_attempt:retry:job_handle

if ( $#ARGV < 0 ) {
    $Prompt=0;
    print "Usage: $0 (s or f)\n";
    exit (1);
} else {
        $SucOrFail=$ARGV[0];
}

#  Log file
$FAIL_LOG="/tools/isosfax/logs/success_fail/success.log";

# DID file stores the fax job handles that we already calculated
$DID_FILE="/tools/admin/public_html/mrtg/isofax-data/tmp/did.log"

open(DID,"+< $DID_FILE") || die "Can't open did file\n";
@didlist=<DID>;

open(LOG,"<$FAIL_LOG") ||die "Can't open log file\n";
while(<LOG>) {
	if ("$SucOrFail" eq "s") {
		($time_submitted:$last_attempt:$time_sent:$c_length:$job_ handle) = split(:,$_);
	}
	if ("$SucOrFail" eq "f") {
		($time_submitted,$last_attempt,$retry,$job_handle) = split(:,$_);
	}
	$Matched = grep {/$job_handle/} @didlist;
	if ($Matched eq 0) {
        	$total = $total + 1;
		print DID "$job_handle\n";
	};
};
close (LOG);
close (DID);

print $total;
print $total;
