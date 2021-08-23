#!/usr/local/bin/perl
#
# This script file is used with cron to optain information about remote servers.

# Input required
# $1 Server's name
#

use File::Basename;
#use File::stat;

#if ( $#ARGV < 0 ) {
#    $Prompt=0;
#    print "Usage: $0 server\n";
#    exit (1);
#} else {
#        $Server=$ARGV[0];
#}
#chop($Today=`date`);
##
##$LogDir="/projects/ccase_irva/logs/${Server}/";
#$GeneralLog="${LogDir}/general.log";
#$CpuLog="${LogDir}/cpu.log";
#$NetStatLog="${LogDir}/netstat.log";
#$DfLog="${LogDir}/df.log";
#$VobSpaceLog="${LogDir}/vobspace.log";
#$CCVerLog="${LogDir}/ccver.log";
#$WhoLog="${LogDir}/who.log";
#$TopTenProcsLog="test.log";
#$CCProcsLog="${LogDir}/ccprocs.log";
#
#
#$CT="/opt/rational/clearcase/bin/cleartool";
#
## Top Ten Processes
#open(TOPPROCSLOG,">$TopTenProcsLog") || die "Can't open top ten processes log file\n";
#open(TOPPROCS, "rsh $Server /usr/ucb/ps -auxxxxxx \| head -10 | ");
#while(<TOPPROCS>) {
#     print TOPPROCSLOG $_;
#}
#close(TOPPROCS);
#close(TOPPROCSLOG);


($atime1,$mtime1) = (stat("/home/raytran/bin/perl/mykakafile"))[8,9];
print "$mtime1\n";
($atime2,$mtime2) = (stat("/home/raytran/bin/perl/newkaka"))[8,9];
print "$mtime2\n";

$diff = $mtime2 - $mtime1;
print "Diff is $diff\n";
