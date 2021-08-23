#! /tools/isofax/brcm/perl/bin/perl

# Calculate and returns stats from successful faxes for IsoFax
# Log Format
# Success
# time_submitted:last_attempt:time_sent:c_length:job_ handle

# Input required
# stats type
# 1 - Queue time

use Date::Manip;

if ("$SucOrFail" eq "s") {
	$FAIL_LOG="/tools/isosfax/logs/success.log";
}

if ("$SucOrFail" eq "f") {
	$FAIL_LOG="/tools/isosfax/logs/fail.log";
}

# DID file stores the fax job handles that we already calculated
$FAIL_DID="/tools/admin/public_html/mrtg/isofax-data/tmp/failed.txt"

open(DID,"+< $FAIL_DID") || die "Can't open did file\n";
@didlist=<DID>;

open(LOG,"<$FAIL_LOG") ||die "Can't open log file\n";
while(<LOG>) {
	($time_submitted:$last_attempt:$time_sent:$c_length:$job_ handle) = split(:,$_);
	$Matched = grep {/$job_handle/} @didlist;
	if ($Matched eq 0) {
		$Delta = &DateCalc($time_submitted,$time_sent,\$err);
		print DID "$job_handle\n";
	}
};
close (LOG);
close (DID);

print $total;
print $total;

$Date_1 = "Wed Apr 17 12:05:31 2002";
$Date_2 = "Wed Apr 17 12:06:38 2002";

$delta = &DateCalc($Date_1,$Date_2,\$err);

print "$delta\n";
