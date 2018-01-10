#!/usr/bin/perl -w

use strict;
use POSIX qw(strftime);
use lib './lib';
use Date::Manip;


my $ct_file="/tmp/.raytran_log";
my $ct_th=5;# time in minutes

my ($ct_return_code,$ct_current_time,$ct_threshold_time,$ct_time_of_last_issue_detected,$ct_date_cmp_flag);

# Return code - Yellow (Warning) used for issues detected within the time threshold. Should trigger warning
# Return code - Red (Critical) used for issues detected beyond the time threshold. Should trigger alerts
$ct_return_code="yellow";


#my (%ct_date,return_code);

# if the threshold detection file exists, read the date time stemp otherwise create the file with a timestamp

$ct_current_time = ParseDate("now");
print "my current $ct_current_time\n";

if (-e $ct_file) {
      print "$ct_file exits. Opening file\n";
      open(CTFILE, "$ct_file") or die "Couldn't open $ct_file for reading: $!\n";
      while(<CTFILE>) {
	   print "$_\n";
           $ct_time_of_last_issue_detected = $_;
           print "last detected time $ct_time_of_last_issue_detected\n";
           $ct_threshold_time = DateCalc("$ct_time_of_last_issue_detected","+ $ct_th mins");
           print "threshold time $ct_threshold_time\n";
           $ct_date_cmp_flag=Date_Cmp($ct_current_time,$ct_threshold_time);
           if ($ct_date_cmp_flag>0) {
               print "current time $ct_current_time is later than the threshold time $ct_threshold_time\n";
               $ct_return_code="red";
               system("rm $ct_file");
           }
      }
      close(CTFILE);

} else {
      print "file doesn't exists\n";
#      my $reformatted_ct_time = $ct_time->strftime('%Y %m %d %H %M');
      open(CT_NEW_FILE, ">$ct_file") or die "Can't open file: $!\n";
#         print CT_NEW_FILE "$reformatted_ct_current_time";
          print CT_NEW_FILE "$ct_current_time";
      close CT_NEW_FILE;
}

print "code return is $ct_return_code\n";
