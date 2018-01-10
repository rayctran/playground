#!/usr/bin/perl
use File::Basename;
use File::stat;

chomp($CPU = `cat /proc/cpuinfo | grep processor | wc -l`);
chomp($MEM = `free -h  | awk '/Mem/{print \$2}'`);
chomp($DS =  `df -h | grep mapper | awk '{print \$2}'`);
chomp($HOSTNAME =  `hostname`);
chomp($HW =  `dmidecode -t 1`);

$phpPackages = `rpm -qa | grep php | sort`;
$mysqlPackages = `rpm -qa | grep mysql | sort`;
$httpPackages = `rpm -qa | grep httpd | sort`;

chop($Today=`date`);
$LOGFILE="/tmp/${HOSTNAME}sysinfo.log";


open(INFOLOG,">$GeneralLog") || die "Can't open general log file\n";
print INFOLOG "Status for $Server as of $Today\n";
open(PRT, "rsh $Server /usr/platform/`uname -m`/sbin/prtdiag |");
while(<PRT>) {
    print INFOLOG $_;
}
close(PRT);
open(UPTIME, "rsh $Server uptime |");
while (<UPTIME>) {
    print INFOLOG $_;
}
close(UPTIME);
close(INFOLOG);

# Top Ten Processes
open(TOPPROCSLOG,">$TopTenProcsLog") || die "Can't open top ten processes log file\n";
open(TOPPROCS, "rsh $Server /usr/ucb/ps -auxxxxxx \| head -10 | ");
while(<TOPPROCS>) {
     print TOPPROCSLOG $_;
}
close(TOPPROCS);
close(TOPPROCSLOG);

# ClearCase Processes
open(PROCSLOG,">$CCProcsLog") || die "Can't open ClearCase processes log file\n";
open(PROCS, "rsh $Server /usr/ucb/ps -auxxxxxx \| egrep \"(atria|db_server|view_server|vob_server)\" | ");
while(<PROCS>) {
     print PROCSLOG $_;
    ($owner,$pid,$cpu,$mem,$sz,$rss,$tt,$s,$start,$time,$comm)=split(/ +/);
    if ( $cpu > 15 ) {
        print "$owner, $pid\n";
#        &Notify("raytran\@broadcom.com","CC_MONITOR_WARNING: process $comm has $cpu% of the CPU on $Server\n");
    }
}
close(PROCS);
close(PROCSLOG);


# CPU
open(CPULOG,">$CpuLog") || die "Can't open CPU log file\n";
open(CPU, "rsh $Server sar -u 2 10 |");
while (<CPU>) {
    if (/^Average/) {
        print CPULOG $_;
    }
}
close(CPU);
close(CPULOG);

# Netstat
open(NSLOG,">$NetStatLog") || die "Can't open Netstat Log file\n";
open(NS, "rsh $Server netstat -i -I hme0 2 10|");
while (<NS>) {
    print NSLOG $_;
}
close(NS);
close(NSLOG);


# DF
open(DFLOG,">$DfLog") || die "Can't open DF Log file\n";
open(DF, "rsh $Server df -k -F ufs|");
while (<DF>) {
    print DFLOG $_;
}
close(DF);

# Determine storage location
open(SL, "rsh $Server $CT lsstgloc -vob|");
while(<SL>) {
#    print $_;
    ($N,$NA,$Location)= split(/ +/);
}
#print "$Location\n";
$Loc=dirname($Location);
#print "$Loc\n";
open(DFL, "rsh $Server df -k $Loc|");
while(<DFL>) {
    next if /^Filesystem/;
    ($filesystem,$kbytes,$used,$avail,$capacity,$mounted)=split(/ +/);
    print DFLOG $_;
#    ($capacity = $capacity) =~ s/\%//;
    print "disk space left is $avail\n";
    if ( $avail < 1500000 ) {
#    print "Over 90\%\n";
        &Notify("raytran\@broadcom.com","CC_MONITOR_WARNING: current available space of $avail on disk $Loc of server $Server is less than the 50Gb threshold specified\n","Warning, current available space of $avail on disk $Loc of server $Server is less than 50Gb.\n\n\n");
    }
}
close(DFL);
close(DFLOG);


# who
open(WHOLOG,">$WhoLog") || die "Can't open who log file\n";
open(WHO, "rsh $Server who -u |");
while (<WHO>) {
    print WHOLOG $_;
}

# ClearCase Version
open(CCVERLOG,">$CCVerLog") || die "Can't open ClearCase Version Log file\n";
open(CCVER, "rsh $Server $CT -ver|");
while (<CCVER>) {
    print CCVERLOG $_;
}
close(CCVER);
close(CCVERLOG);


# VOB Space
open(VSLOG,">$VobSpaceLog") || die "Can't open VOB space log\n";
open(VS, "rsh $Server $CT space -avob |");
while(<VS>) {
    if ($_ =~ /^Total/) {
            @TotalUsageLine = split(" ",);
            $VOB = @TotalUsageLine[5];
            $Size = @TotalUsageLine[7];
            print VSLOG "Current Size for VOB $VOB is $Size\n";
            $Total = $Total + $Size;
    }
}
print VSLOG "=======================================\n";
print VSLOG "Total disk usage for all VOBs is $Total\n";
print VSLOG "\n";
close(VS);
close(VSLOG);

# Gather ClearCase Logs from the server

@Logs = ("vob", "view", "shipping", "vobrpc", "vob_scrubber", "scrubber", "mvfs", "lockmgr", "db", "albd", "admin");

# Process each logs. Ignore the header
foreach $Elem (@Logs) {
   print $Elem, "\n";
   open(LOG, ">${LogDir}/${Elem}.log") || die "Can't open log file ${LogDir}/${Elem}.log\n";
   if ( "$Elem" =~ /vob_scubber|scrubber|lockmgr/ ) {
       open(GETLOG, "rsh $Server $CT getlog $Elem |");
   } else {
       open(GETLOG, "rsh $Server $CT getlog -since yesterday $Elem |");
   }
   while (<GETLOG>) {
       if ( $_ =~ /^=|^Log Name|^Selection|^-/ ) {
           print $_;
           next;
       } else {
           print LOG $_;
       }

   }

   close GETLOG;
   close LOG;
}

# Release license
system("rsh $Server /opt/rational/clearcase/bin/clearlicense -release");

sub Notify {
    my($MySentTo,$MySubject,$MyMessage)=@_;
    %mail = (
            smtp    => 'smtphost.broadcom.com',
            to      => $MySentTo,
            from    => 'ccmonitor@broadcom.com',
            subject => $MySubject,
            message => $MyMessage,
    );

    eval { sendmail(%mail) || die $Mail::Sendmail::error; };
    $Mail::Sendmail::log;

    if ($@) {
            print "mail could NOT be sent correctly - $@\n";
            exit(1);
    } else {
            print "mail sent correctly\n";
            exit(0);
    }
}
:w sysinfonew.pl

