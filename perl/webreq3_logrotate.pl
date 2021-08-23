#!/usr/local/bin/perl -w

use strict;
use File::Basename;
use Date::Manip;

my $top_log_dir="/projects/IT_SCM/tools_logs/cvs/BusAppsMaster";
my $today = localtime();
my $this_year = UnixDate("today","%Y");
my $this_month = UnixDate("today","%m");
my $this_day = UnixDate("today","%d");
my $log_dir="$top_log_dir/$this_year";

my $notify_list="webreq3-notify-list\@broadcom.com";
my $log_file="/projects/BusAppsMaster/master/CVSROOT/webreq3.log";

#my $notify_list="raytran\@broadcom.com";
#my $log_file="/home/raytran/bin/perl/webreq3.log";

if (!-e ${log_dir}) {
        system("mkdir -p ${log_dir}");
}
system("mailx -s \"CVS_LOG: Monthly Log for CVS WebReq3 Project - $this_month/$this_day/$this_year\" $notify_list < $log_file");
system("cp $log_file ${top_log_dir}/${this_year}/webeq3.log.${this_month}${this_day}");
system("cp /dev/null $log_file");
