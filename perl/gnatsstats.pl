#!/tools/perl/5.6.0/SunOS/bin/perl
#
# This script file is used with cron to optain information about remote servers.
# Input required
# $1 SERVER's name
#

use File::Basename;
use Mail::Sendmail;
use Date::Manip;

if ( $#ARGV < 0 ) {
    $Prompt=0;
    print "Usage: $0 server\n";
    exit (1);
} else {
        $SERVER=$ARGV[0];
}

chop($TODAY=`date`);
chop ($ThisHost=`hostname`);
$EmailList = "gnats4-admin\@broadcom.com";
$PageList = "9494395234\@mobile.att.net,9493007499 \@mobile.att.net";
$GNATSDIR="/tools/gnats/4.0";
$DFWarnFile="/tools/gnats/4.0/brcm/tmp/df_warn_$SERVER.txt";
$DFLogFile="/tools/gnats/4.0/brcm/tmp/df_log_$SERVER.txt";
$DownWarnFile="/tools/gnats/4.0/brcm/tmp/down_warn_$SERVER.txt";


# ClearCase Logs
$LogDir="/tools/gnats/4.0/brcm/logs/${SERVER}/";
$GeneralLog="${LogDir}/general.log";
$CpuLog="${LogDir}/cpu.log";
$NetStatLog="${LogDir}/netstat.log";
$DfLog="${LogDir}/df.log";
$VobSpaceLog="${LogDir}/vobspace.log";
$CCVerLog="${LogDir}/ccver.log";
$WhoLog="${LogDir}/who.log";
$TopTenProcsLog="${LogDir}/toptenprocs.log";
$CCProcsLog="${LogDir}/ccprocs.log";

#open(PING,"/usr/sbin/ping $SERVER |") or die "Couldn't ping server\n";
#while(<PING>) {
#    if (/^no/) {
#        print "$SERVER is not available\n Try again later.\n";
#	if ((-e $DownWarnFile) == "") {
#                 open(WARN, "> $DownWarnFile") || die "Can't open down warn tag file\n";
#                 print WARN $_;
#                 close(WARN);
#		&Notify("$PageList","CC_MONITOR_WARNING - No response from $SERVER.\n","Warning, $SERVER did not response to the ping process from the monitor server $ThisHost.\n\n\n");
#         }
#        exit (1); 
#    } else {
#	if ( -e $DownWarnFile ) {
#		&Notify("$PageList","CC_MONITOR_WARNING - $SERVER is up.\n","SERVER $SERVER was offline or unreachable is now up.\n\n\n");
#		system("/usr/bin/rm $DownWarnFile");
#	}
#
#    }	
#}


open(INFOLOG,">$GeneralLog") || die "Can't open general log file\n";
print INFOLOG "Status for $SERVER as of $TODAY\n";
open(PRT, "/usr/platform/`uname -m`/sbin/prtdiag |");
while(<PRT>) {
    print INFOLOG $_;
}
close(PRT);
open(UPTIME, "uptime |");
while (<UPTIME>) {
    print INFOLOG $_;
}
close(UPTIME);
close(INFOLOG);

# Top Ten Processes
open(TOPPROCSLOG,">$TopTenProcsLog") || die "Can't open top ten processes log file\n";
open(TOPPROCS, "/usr/ucb/ps -auxxxxxx \| head -10 | ");
while(<TOPPROCS>) {
     print TOPPROCSLOG $_;
}
close(TOPPROCS);
close(TOPPROCSLOG);

# CPU 
open(CPULOG,">$CpuLog") || die "Can't open CPU log file\n";
open(CPU, "sar -u 2 10 |");
while (<CPU>) {
    if (/^Average/) {
        print CPULOG $_;
    }
}
close(CPU);
close(CPULOG);

# Netstat
open(NSLOG,">$NetStatLog") || die "Can't open Netstat Log file\n";
open(NS, "netstat -i -I hme0 2 10|");
while (<NS>) {
    print NSLOG $_;
}
close(NS);
close(NSLOG);


# DF
open(DFLOG,">$DfLog") || die "Can't open DF Log file\n";
open(DF, "$SERVER df -k -F ufs|");
while (<DF>) {
    print DFLOG $_;
}
close(DF);

# Determine storage location
open(DFL, "df -k $GNATSDIR|");
while(<DFL>) {
    next if /^Filesystem/;
    ($filesystem,$kbytes,$used,$avail,$capacity,$mounted)=split(/ +/);
    print DFLOG $_;
    if ( $avail < 5000000 ) {
         if ( -e $DFWarnFile ) {
		print "df warn file found\n";
                $OLDDF=`cat $DFWarnFile`;
                if ($OLDDF < $avail) {
 	                &Notify("$EmailList","CC_MONITOR_WARNING: current available space of $avail on directory $Loc of $SERVER is below the threshold\n","Warning, current available space of $avail on directory $Loc of $SERVER is less than 10Gb.\n\n\n");
                        open(WARN, "> $DFWarnFile") ||  die "Can't open warn tag file\n";
                        print WARN $avail;
                        close(WARN);
                } elsif ($OLDDF > $avail) {
                        unlink("$DFWarnFile") or die "Can't remove file $DFWarnFile";
                }
        } else {
		 print "df warn file not found\n";
                 &Notify("$EmailList","CC_MONITOR_WARNING: current available space of $avail on directory $Loc of $SERVER is below the threshold\n","Warning, current available space of $avail on directory $Loc of $SERVER is less than 10Gb.\n\n\n");
                 open(WARN, "> $DFWarnFile") ||  die "Can't open warn tag file\n";
                 print WARN $avail;
                 close(WARN);
 	 }
    }
}
close(DFL); close(DFLOG);


# who 
open(WHOLOG,">$WhoLog") || die "Can't open who log file\n";
open(WHO, "who -u |");
while (<WHO>) {
    print WHOLOG $_;
}



sub Notify {
    my($MySentTo,$MySubject,$MyMessage)=@_;
    %mail = (
            smtp    => 'smtphost.broadcom.com',
            to      => $MySentTo,
            from    => 'raytran@broadcom.com',
            subject => $MySubject,
            message => $MyMessage,
    );

    eval { sendmail(%mail) || die $Mail::Sendmail::error; };
    $Mail::Sendmail::log;

    if ($@) {
            print "mail could NOT be sent correctly - $@\n";
    } else {
            print "mail sent correctly\n";
    }
}
