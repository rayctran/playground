#!/tools/perl/5.6.0/SunOS/bin/perl
#
# Calculates data from log file and return it to MRTG for graphing
#
# $result_code,$today_date,$sender,$recipient,$rec_fax_no,$time_submitted,$last_attempt,$time_sent,$c_length,$no_pages_sent,$retry,$fail_message,$job_handle

use Date::Manip;
use File::Copy;

# Input required
# $1 what data to report

if ($#ARGV < 0) {
        print "Usage: $0 {successs}/{fail}/{queue}\n";
        exit (1);
} else {
        $do_what=$ARGV[0];
}


$today = &UnixDate(`date`,"%d-%m-%Y");
chop ($dateis=`date`);
#$today = "01-05-2002";
$Logfile="/tools/isofax/logs/usage/${today}";
if ( "$do_what" eq "queue" ) {
	$Tagged="/tools/isofax/public_html/mrtg/tmp/qtagged.txt";
}
if ( "$do_what" eq "success" ) {
	$Tagged="/tools/isofax/public_html/mrtg/tmp/stagged.txt";
}
if ( "$do_what" eq "fail" ) {
	$Tagged="/tools/isofax/public_html/mrtg/tmp/ftagged.txt";
}
if ( "$do_what" eq "c_length" ) {
	$Tagged="/tools/isofax/public_html/mrtg/tmp/ctagged.txt";
}

$tmpTag="/tools/isofax/public_html/mrtg/tmp/tmptagged.txt";
$LogMe="/tools/isofax/public_html/mrtg/tmp/logme.txt";

#####
# Tag keeps track of the fax job handle that has been processed by MRTG already today
#####
# Read in the tagged log file
#####
if ( -e $Tagged ) {
# Copy tagged file to temporary file to add more tagged jobs
	copy($Tagged, $tmpTag);
	open(TAG, "$Tagged") or print "Can't open tagged file\n" and die;
	while(<TAG>) {
		chop($_);
		$Job_Tagged = join '\t', $Job_Tagged, $_;	
	}
	close(TAG);
}
open(NEWTAG, ">> $tmpTag") or print "Can't open temp tag file\n" and die;
open(ITEM, "$Logfile") or print "Can't open log file\n" and die;
$success_cnt = 0;
$fail_cnt = 0;
while(<ITEM>) {
	chop($_);
	($result_code,$today_date,$sender,$recipient,$rec_fax_no,$time_submitted,$last_attempt,$time_sent,$c_length,$no_pages_sent,$retry,$fail_message,$job_handle) = split (/\,/,$_);
	if ( $Job_Tagged =~ /$job_handle/ ) {
		$tagged = 1;
	} else {
		$tagged = 0;
		print NEWTAG "$job_handle\n";
	}
	if (( $result_code == 0 ) && ($tagged == 0)) {
		$success_jobs = join '\t', $success_jobs, $job_handle; 
		$success_cnt++;
		$delta = &DateCalc($time_submitted,$last_attempt);
		($a,$b,$c,$d,$hr,$min,$sec) = split (/:/, $delta);
		$queue_time =($hr * 3600) + ($min * 60) + $sec;
		$total_queue_time = $total_queue_time + $queue_time; 
		$total_c_length = $total_c_length + $c_length;
	}
	if (( $result_code == 1 ) && ($tagged == 0)) {
		$fail_cnt++;
	}
}
close(ITEM);
close(NEWTAG);
if ( -e $Tagged ) {
	unlink($Tagged) or die "Can't remove file $Tagged: $!\n";
}
rename($tmpTag, $Tagged) or die "Can't rename file $tmpTag: $!\n";

open(LOGME, ">> $LogMe") or print "Can't open temp tag file\n" and die;

#####
# Returns value
#####
if ( "$do_what" eq "queue" ) {
	if ( $success_cnt == 0 ) {
		print "0\n";
		print "0\n";
		print LOGME "queue,$dateis,0,0\n";
	} else {
		$average_queue_time = $total_queue_time / $success_cnt;
		printf "%-10d\n", $average_queue_time;
		printf "%-10d\n", $average_queue_time;
		print LOGME "queue,$dateis, $success_jobs,$average_queue_time,$average_queue_time\n";
	}
}
if ( "$do_what" eq "success" ) {
	if ( $success_cnt == 0 ) {
		print "0\n";
		print "0\n";
		print LOGME "success,$dateis,0,0\n";
	} else {
		print "$success_cnt\n";
		print "$success_cnt\n";
		print LOGME "success,$dateis,$success_cnt,$success_cnt\n";
	}

}
if ( "$do_what" eq "fail") {
	if ( $fail_cnt == 0 ) {
		print "0\n";
		print "0\n";
		print LOGME "fail,$dateis,0,0\n";
	} else {
		print "$fail_cnt\n";
		print "$fail_cnt\n";
		print LOGME "fail,$dateis,$fail_cnt,$fail_cnt\n";
	}
}
if ( "$do_what" eq "c_length" ) {
	if ( $success_cnt == 0 ) {
		print "0\n";
		print "0\n";
		print LOGME "c_length,$dateis,0,0\n";
	} else {
		$average_c_length = $total_c_length / $success_cnt;
		printf "%-10d\n", $average_c_length;
		printf "%-10d\n", $average_c_length;
		print LOGME "c_length,$dateis, $average_c_length,$average_c_length\n";
	}
}
