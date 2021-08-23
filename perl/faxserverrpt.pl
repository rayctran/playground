#!/tools/perl/5.6.0/SunOS/bin/perl

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

$TMPTagged="/tools/isofax/public_html/mrtg/tmp/tmptagged.txt";

# Copy tagged file to temporary file to add more tagged jobs
print "copy file\n";
copy($Tagged,$TMPTagged);

# Read in the tagged log file
open(TAG, "$Tagged") or print "Can't open tagged file\n" and die;
while(<TAG>) {
	push(@Tagged, $_);	
}
close(TAG);
open(NEWTAG, ">> $TMPTagged") or print "Can't open temp tag file\n" and die;

open(ITEM, "$Logfile") or print "Can't open log file\n" and die;
while(<ITEM>) {
	chop($_);
	($result_code,$today_date,$sender,$recipient,$rec_fax_no,$time_submitted,$first_attempt,$last_attempt,$time_sent,$c_length,$no_pages_sent,$retry,$fail_message,$job_handle) = split (/\,/,$_);
	if (( $result_code == 0 ) && (&istagged == 1)) {
		$success_cnt++;
		$delta = &DateCalc($time_submitted,$first_attempt);
		($a,$b,$c,$d,$hr,$min,$sec) = split (/:/, $delta);
		$queue_time =($hr * 3600) + ($min * 60) + $sec;
		$total_queue_time = $total_queue_time + $queue_time;
	}
	if (( $result_code == 1 ) && ( &istagged == 1 )) {
		$unsuccess_cnt++;
	}
}
close(ITEM);
close(NEWTAG);
print "$success_cnt\n";
unlink($Tagged) or die "Can't remove file $Tagged: $!\n";
rename($TMPTagged, $Tagged);
#unlink($TMPTagged) or die "Can't remove file temp tag: $!\n";

if ( "$do_what" eq "queue" ) {
	$average_queue_time = $total_queue_time / $success_cnt;
	print "$average_queue_time\n";
	print "$average_queue_time\n";
}
if ( "$do_what" eq "success" ) {
	print "$success_cnt\n";
	print "$success_cnt\n";
}
if ( "$do_what" eq "fail" ) {
	print "$fail_cnt\n";
	print "$fail_cnt\n";
}

sub istagged {
	local($job)=@_;
	for  ($i = 0; $i < scalar(@Tagged); $i++) {
		if ( $Tagged[$i] =~ /$job/) {
			return 1;
			last;
		} else {
			return 0;
		}
	}	
}

sub tagit {
	local($job)=@_;
	print NEWTAG $job;
}
