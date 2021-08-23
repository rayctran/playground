#!/tools/perl/5.6.0/SunOS/bin/perl

# $result_code,$today_date,$sender,$recipient,$rec_fax_no,$time_submitted,$last_attempt,$time_sent,$c_length,$no_pages_sent,$retry,$fail_message,$job_handle

use Date::Manip;

$today = &UnixDate(`date`,"%d-%m-%Y");
$Logfile="/tools/isofax/logs/usage/${today}";
$Tagged="/tools/isofax/public_html/mrtg/tmp/qtagged.txt";


# Read in the tagged log file
open(TAG,"$Tagged") or print "Can't open tagged file\n" and die;
while(<TAG>) {
	push(@Tagged, $_);	
}
close(TAG);
open(NEWTAG,"> /tmp/newtag.$$") or print "Can't open temp tag file\n" and die;

open(ITEM,"$Logfile") or print "Can't open log file\n" and die;
while(<ITEM>) {
	($result_code,$today_date,$sender,$recipient,$rec_fax_no,$time_submitted,$last_attempt,$time_sent,$c_length,$no_pages_sent,$retry,$fail_message,$job_handle) = split (/\,/,$_);
	if ( &istagged($job_handle) == 1 ) {
		print "found it as $job_handle\n";	
	}
}
close(ITEM);

close(NEWTAG);


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
