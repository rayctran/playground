#!/tools/perl/5.6.0/SunOS/bin/perl

#
# This script file is used with cron to optain information about remote servers.
# Input required
# $1 server's name
#

use File::Basename;
use File::stat;
use Mail::Sendmail;
use Date::Manip;
use Data::Dumper;
use strict;

my ($today, $server, $this_host, $my_os,%notify,$debug,$top_log_dir,%log_file,$log_dir,$os,%command,$rsh);
my (%df_warning,$do_df_warning,%warning_file);
my $local=0;

if ( $#ARGV < 0 ) {
    my $prompt=0;
    print "Usage: $0 server\n";
    exit (1);
} else {
        $server=$ARGV[0];
}

chop($today=`date`);
chop ($this_host=`hostname`);
if ( "$this_host" eq "$server" ) {
    $local = 1;
}

$do_df_warning = 1;
$debug = 1;

$notify{email_list} = "clearcase-admins-list\@broadcom.com";
$notify{page_list} = "9494395234\@mobile.att.net,4088875749\@mobile.att.net,8777467135\skytel.com,8779074001\@skytel.com,clearcase-admins-list\@broadcom.com";

if ($debug) {
    $notify{email_list} = "raytran\@broadcom.com";
    $notify{page_list} = "9494395234\@mobile.att.net";
}
$top_log_dir="/projects/ccase_irva/logs";
$log_dir="$top_log_dir/${server}/";

%df_warning = (
              'level_3' => 1000000,
              'level_2' => 500000,
              'level_1' => 100000,
);

# ClearCase Logs
%log_file = (
             'down_warn'   => "${top_log_dir}/tmp/down_${server}.txt",
             'datestamp'   => "${top_log_dir}/tmp/datestamp",
             'df_warning'  => "${top_log_dir}/tmp/df_warning_${server}.txt",
             'df'          => "${log_dir}/df.log",
             'general'     => "${log_dir}/general.log",
             'cpu'         => "${log_dir}/cpu.log",
             'netstat'     => "${log_dir}/netstat.log",
             'vobspace'    => "${log_dir}/vobspace.log",
             'cc_ver'      => "${log_dir}/ccver.log",
             'who'         => "${log_dir}/who.log",
             'top_10_proc' => "${log_dir}/toptenprocs.log",
             'cc_procs'    => "${log_dir}/ccprocs.log",

);

if ($local) {
    chop($os=`/bin/uname`);
} else {
    $os=`rsh $server /bin/uname`;
    $rsh="rsh $server";
    print "remote server os is $os\n";
}

my $CT="/usr/atria/bin/cleartool";

system("date > $log_file{datestamp}");

if ( $os =~ /SunOS/ ) {
    print "Setting SunOS commands\n";
    %command = (
               'uname'       => "$rsh /bin/uname -a",
               'uptime'      => "$rsh /bin/uptime",
               'cpu_info'    => "$rsh /usr/sbin/psrinfo -v",
               'mem_info'    => "$rsh /usr/sbin/prtconf | grep Mem",
               'memusage_info'  => "$rsh /tools/bin/top -n | grep Mem",
               'swapusage_info' => "$rsh /usr/sbin/swap -s",
               'top_10_proc' => "$rsh /usr/ucb/ps -auxxx | head -10",
               'ps_cc'       => "$rsh /usr/ucb/ps -auxxx | egrep \"(atria|db_server|view_server|vob_server)\" ",
               'sar_cpu'     => "$rsh /usr/sbin/sar -u 1 20",
               'netstat'     => "$rsh /usr/bin/netstat -rn",
               'df'          => "$rsh /usr/sbin/df -k -F ufs",
               'who'         => "$rsh /usr/bin/who -u ",
               'mpstat'      => "$rsh /bin/mpstat 1 20 ",
    );
}

if ( $os =~ /Linux/ ) {
    print "Setting Linux commands\n";
    %command = (
               'uname'       => "$rsh /bin/uname -a",
               'uptime'      => "$rsh /usr/bin/uptime",
               'cpu_info'    => "$rsh cat /proc/cpuinfo",
               'mem_info'    => "$rsh /usr/bin/free",
               'top_10_proc' => "$rsh /bin/ps -auxxx | head -10",
               'ps_cc'       => "$rsh /bin/ps -auxxx | egrep \"\(atria\|db_server\|view_server\|vob_server\)\" ",
               'sar_cpu'     => "$rsh /usr/bin/sar -u 1 20",
               'netstat'     => "$rsh /bin/netstat -rn",
               'df'          => "$rsh /bin/df -lk",
               'who'         => "$rsh /usr/bin/who -u ",
               'mpstat'      => "$rsh /usr/bin/mpstat 1 20 ",
    );     
}

chop($my_os=`/bin/uname`);
if ( "$my_os" eq "SunOS" ) {
    print "Local OS is $my_os\n";
    $command{ping}="/usr/sbin/ping";
}
if ( "$my_os" eq "Linux" ) {
    print "Local OS is $my_os\n";
    $command{ping}="/bin/ping";
}

#print Dumper(\%command);
sub main {
    print "ping command is $command{ping}\n";
    open(PING,"$command{ping} $server |") or die "Couldn't ping server: $!\n";
    while(<PING>) {
        if (/^no/) {
            print "$server is not available\n Try again later.\n";
    	if ((-e $log_file{down_warn}) == "") {
                     open(WARN, "> $warning_file{down}") || die "Can't open down warn tag file: $!\n";
                     print WARN $_;
                     close(WARN);
    		&Notify("$notify{page_list}","CC_MONITOR_WARNING - No response from $server.\n","Warning, $server did not response to the ping process from the monitor server $this_host.\n\n\n");
             }
            exit (1); 
        } else {
    	if ( -e $log_file{down_warn} ) {
    		&Notify("$notify{page_list}","CC_MONITOR_WARNING - $server is up.\n","server $server was offline or unreachable is now up.\n\n\n");
    		system("/usr/bin/rm $log_file{down_warn}");
    	}
    
        }	
    }
   
    open(INFOLOG,">$log_file{general}") or die "Can't open general log file: $!\n";
    print INFOLOG "Status for $server as of $today\n";
    open(PRT, "$command{uname} |") or die "Can't run command $command{uname}: $!\n";
    while(<PRT>) {
        print INFOLOG $_;
    }
    close(PRT);
    print INFOLOG "CPU Information\n";
    open(CPUINFO, "$command{cpu_info} |") or die "Can't run command $command{cpu_info}: $!\n"; 
    while(<CPUINFO>) {
        print INFOLOG $_;
    }
    close(CPUINFO);
    print INFOLOG "Memory Information\n";
    open(MEMINFO, "$command{mem_info} |") or die "Can't run command $command{mem_info}: $!\n";
    while(<MEMINFO>) {
        print INFOLOG $_;
    }
    close(MEMINFO);
    if ( exists $command{memusage_info} ) {
        open(MEMINFO, "$command{memusage_info} |") or die "Can't run command $command{memusage_info}: $!\n";
        while(<MEMINFO>) {
            print INFOLOG $_;
        }
        close(MEMINFO);
    }
    if ( exists $command{swapusage_info} ) {
        open(MEMINFO, "$command{swapusage_info} |") or die "Can't run command $command{swapusage_info}: $!\n";
        while(<MEMINFO>) {
            print INFOLOG "Swap $_";
        }
        close(MEMINFO);
    }
    print INFOLOG "Uptime Information\n";
    open(UPTIME, "$command{uptime} |") or die "Can't run command $command{uptime}: $!\n";
    while (<UPTIME>) {
        print INFOLOG $_;
    }
    close(UPTIME);
    close(INFOLOG);
    
    # Top Ten Processes
    print "Top ten processes\n";
    open(TOPPROCSLOG,">$log_file{top_10_proc}") or die "Can't open top ten processes log file\n";
    open(TOPPROCS, "$command{top_10_proc} |") or die "Can't run command $command{top_10_proc}: $!\n";
    while(<TOPPROCS>) {
         print TOPPROCSLOG $_;
    }
    close(TOPPROCS);
    close(TOPPROCSLOG);
    
    # ClearCase Processes
    my %proc;
    print "ClearCase processes\n";
    open(PROCSLOG,">$log_file{cc_procs}") or die "Can't open ClearCase processes log file\n";
    open(PROCS, "$command{ps_cc} | ");
    while(<PROCS>) {
         print PROCSLOG $_;
        ($proc{owner},$proc{pid},$proc{cpu},$proc{mem},$proc{sz},$proc{rss},$proc{tt},$proc{s},$proc{start},$proc{time},$proc{comm})=split(/ +/);
        if ( $proc{cpu} > 15 ) {
            print "$proc{owner}, $proc{pid}\n";
    #        &Notify("$notify{email_list}","CC_MONITOR_WARNING: process $proc{comm} has $proc{cpu}% of the CPU on $server\n");
        } 
    }
    close(PROCS);
    close(PROCSLOG);
    
    # CPU 
    print "Sar CPU information\n";
    open(CPULOG,">$log_file{cpu}") or die "Can't open CPU log file\n";
    open(CPU, "$command{sar_cpu}|") or die "Can't run sar command $command{sar_cpu}\n";
    while (<CPU>) {
        if (/^Average/) {
            print CPULOG $_;
        }
    }
    close(CPU);
    close(CPULOG);
    
    # Netstat
    print "Netstat information\n";
    open(NSLOG,">$log_file{netstat}") or die "Can't open Netstat Log file\n";
    open(NS, "$command{netstat}|") or die "Can't run netstat command $command{netstat}\n";
    while (<NS>) {
        print NSLOG $_;
    }
    close(NS);
    close(NSLOG);
    
    
    # DF
    print "df information\n";
    open(DFLOG,">$log_file{df}") || die "Can't open DF Log file\n";
    open(DF, "$command{df} |");
    while (<DF>) {
        print DFLOG $_;
    }
    close(DF);
    
    # Determine storage location
    if ($debug) {
        print "df storage location information\n";
    }
    my (%storage_loc,%dfl, $old_dfl, $do_slc);
    open(SL, "rsh $server $CT lsstgloc -vob|");
    while(<SL>) {
         if ($_ =~ /^\s*$/) {
             if ($debug) {
                 print "No VOB storage location defined\n";
             }
             $do_slc = 0; 
         } else {
             ($storage_loc{n},$storage_loc{na},$storage_loc{location})= split(/ +/);
             if ($debug) {
                 print "VOB storage location defined: $storage_loc{location}$\n";
             }
             $do_slc = 1; 
         }
    }
    if ($do_slc) {
    #print "$storage_loc{location}\n";
        $storage_loc{location}=dirname($storage_loc{location});
        open(DFL, "rsh $server df -k $storage_loc{location}|");
        while(<DFL>) {
            next if /^Filesystem/;
            ($dfl{filesystem},$dfl{kbytes},$dfl{used},$dfl{avail},$dfl{capacity},$dfl{mounted})=split(/ +/);
            print DFLOG $_;
            if ($do_df_warning) {
            if ( ($dfl{avail} le $df_warning{level_3}) && ($dfl{avail} ge $df_warning{level_3}) ) {
                if ( -e $log_file{df_warning} ) {
                    if ($debug) {
    	                print "df warn file found\n";
                    }
                    $old_dfl=`cat $warning_file{df}`;
                    if ($old_dfl ne $dfl{avail}) {
                       open(WARN, "> $warning_file{df}") ||  die "Can't open warn tag file\n";
                            print WARN $dfl{avail};
                            close(WARN);
                       } elsif ($old_dfl > $dfl{avail}) {
                            system("rm $warning_file{df}");
                       }
                   } else {
                      print "df warn file not found\n";
                      open(WARN, "> $warning_file{df}") ||  die "Can't open warn tag file\n";
                          print WARN $dfl{avail};
                     close(WARN);
     	          }
              }
          }
          close(DFL); 
          }
          close(DFLOG);
     }

#                       &Notify("$notify{email_list}","CC_MONITOR_WARNING: current available space of$dfl{avail} on directory $storage_loc{location} of $server is below the threshold\n","Warning, current available space of $dfl{avail} on directory $storage_loc{location} of $server is less than 5Gb.\ n\n\n");
    
    
    # who 
    open(WHOLOG,">$log_file{who}") || die "Can't open who log file\n";
    open(WHO, "$command{who} |");
    while (<WHO>) {
        print WHOLOG $_;
    }
    
    # ClearCase Version
    open(CCVERLOG,">$log_file{cc_ver}") || die "Can't open ClearCase Version Log file\n";
    open(CCVER, "rsh $server $CT -ver|");
    while (<CCVER>) {
        print CCVERLOG $_;
    }
    close(CCVER);
    close(CCVERLOG);
    
    
    # VOB Space
    my (@TotalUsageLine, $VOB, $size, $total);
    open(VSLOG,">$log_file{vobspace}") || die "Can't open VOB space log\n";
    open(VS, "rsh $server $CT space -avob |");
    while(<VS>) {
        if ($_ =~ /^Total/) {
                @TotalUsageLine = split(" ",);
                $VOB = @TotalUsageLine[5];
                $size = @TotalUsageLine[7];
                print VSLOG "Current Size for VOB $VOB is $size\n";
                $total = $total + $size;
        }
    }
    print VSLOG "=======================================\n";
    print VSLOG "Total disk usage for all VOBs is $total\n";
    print VSLOG "\n";
    close(VS);
    close(VSLOG);
    
    # Gather ClearCase Logs from the server
    
    my @logs = ("vob", "view", "shipping", "vobrpc", "vob_scrubber", "scrubber", "mvfs", "lockmgr", "db", "albd", "admin");
    
    # Process each logs. Ignore the header
    my $elem;
    foreach $elem (@logs) {
       print $elem, "\n"; 
       open(LOG, ">${log_dir}/${elem}.log") || die "Can't open log file ${log_dir}/${elem}.log\n";
       if ( "$elem" =~ /vob_scubber|scrubber|lockmgr/ ) {
           open(GETLOG, "rsh $server $CT getlog $elem |");
       } else {
           open(GETLOG, "rsh $server $CT getlog -since yesterday $elem |");
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
    #system("rsh $server /usr/atria/bin/clearlicense -release");

}

sub Notify {
    my($MySentTo,$MySubject,$MyMessage)=@_;
    my %mail = (
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


main ();
