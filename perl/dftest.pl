#!/tools/perl/5.6.0/SunOS/bin/perl
#
# This script file is used with cron to optain information about remote servers.
# Input required
# $1 Server's name
#

use File::Basename;
use Mail::Sendmail;
use Date::Manip;

if ( $#ARGV < 0 ) {
    $Prompt=0;
    print "Usage: $0 server\n";
    exit (1);
} else {
        $Server=$ARGV[0];
}
chop ($ThisHost=`hostname`);
$NotifyList = "raytran\@webboard.broadcom.com";
$DFWarnFile="/home/raytran/temp/df_warn_$Server.txt";
$DownWarnFile="/tools/rational/brcm/tmp/down_warn_$Server.txt";
$DFLogFile="/home/raytran/temp/df_log_$Server.txt";
$CT="/opt/rational/clearcase/bin/cleartool";

#open(SL, "rsh $Server $CT lsstgloc -vob|");
#while(<SL>) {
#    print $_;
#    ($N,$NA,$Location)= split(/ +/);
#}
#print "$Location\n";
$Loc="/projects/ccstgloc";

open(DFL, "rsh $Server df -k $Loc|");
while(<DFL>) {
    print $_; 
    next if /^Filesystem/;
    ($filesystem,$kbytes,$used,$avail,$capacity,$mounted)=split(/ +/);
    print "$avail\n";
    if ( $avail < 120000000 ) {
	open(DFLOGIT, ">> $DFLogFile") or die "Can't open df log file\n";
	print DFLOGIT "$Server $Date $avail\n";
	close(DFLOGIT);
	if (-e $DFWarnFile) {
		print "df warn file found\n";
		$OLDDF=`cat $DFWarnFile`;
		if ($OLDDF < $avail) {
			print "Less notify\n";
                 	#&Notify("$NotifyList","CC_MONITOR_WARNING: current available space of $avail on directory $Loc of $Server is $avail\n","Warning, current available space of $avail on directory $Loc of $Server is less than 5Gb.\n\n\n");
                 	open(WARN, "> $DFWarnFile") ||  die "Can't open warn tag file\n";
                 	print WARN $avail;
                 	close(WARN);
		} else {
			print "no notify\n";
                 	unlink("$DFWarnFile") or die "Can't remove file $DFWarnFile";
		}
	} else {
		 print "df warn file not found\n";
		 print "Notifying\n";
               #  &Notify("$NotifyList","CC_MONITOR_WARNING: current available space of $avail on directory $Loc of $Server is less than the 5Gb threshold specified\n","Warning, current available space of $avail on directory $Loc of $Server is less than 5Gb.\n\n\n");
                 open(WARN, "> $DFWarnFile") ||  die "Can't open warn tag file\n";
                 print WARN $avail;
                 close(WARN);
	}
    }
}
close(DFL);
