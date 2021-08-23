#! /tools/perl/5.6.0/SunOS/bin/perl

use strict;
use Data::Dumper;

# Check ClearCase license and feed the information to mrtg
# 
# Input required
# $1 server's name
# $2 which data to grab
#  1 - memory
#  2 - CPU
#  3 - swap 
#  4 - storage location space. Required 3rd option of the directory
#  5 - IO stats, read and write rate. Required 3rd option of the disk device (sda)
#  6 - IO stats, average queue lenght. Required 3rd option of the disk device (sda)
#  7 - IO stats, service tim and utilization. Required 3rd option of the disk device (sda)
#  8 - Network stats, receive and transmit per sec. Required 3rd option of the network device (eth0)
#  9 - Network error stats, receive and transmit drop per sec. Required 3rd option of the network device (eth0)

my ($prompt,$server,$option,$device,$os,$this_host,$today,$local,%data);
my (%command,$rsh,$pid,%mem,%df,%sar,%swap);

if ( $#ARGV < 0 ) {
    $prompt=0;
    print "Usage: $0 server option\n";
    exit (1);
} else {
        $server=$ARGV[0];
        $option=$ARGV[1];
	$device=$ARGV[2];
}

my $debug = 1;
chop($today=`date`);
chop ($this_host=`hostname`);
if ( "$this_host" eq "$server" ) {
    $local = 1;
}

if ($local) {
    chop($os=`/bin/uname`);
} else {
    $os=`rsh $server /bin/uname`;
    $rsh="rsh $server";
}

if ( $os =~ /SunOS/ ) {
    %command = (
               'meminfo'  => "$rsh /tools/bin/top -n| grep Mem",
	       'sar'  => "$rsh /usr/sbin/sar -u 1",
	       'swap' => "$rsh /usr/sbin/swap -s",
	       'df'   => "$rsh /bin/df -k",
    );
}

#  old memory info command 'top'    => "$rsh /usr/bin/procinfo | grep Mem",
if ( $os =~ /Linux/ ) {
    %command = (
               'meminfo'    => "$rsh /usr/bin/free -m",
	       'sar'    => "$rsh /usr/bin/sar -u 1",
	       'swap'   => "$rsh /usr/bin/procinfo | grep Swap",
               'io'     => "$rsh /usr/bin/iostat -x $device 30 2",
               'net'    => "$rsh /usr/bin/sar -n DEV 30",
               'neterr' => "$rsh /usr/bin/sar -n EDEV 30",
	       'df'     => "$rsh /bin/df -k",
    );
}

if ( $option == 1 ) {
    $pid =  open(MEMINFO, "$command{meminfo} |") or die "Couldn't run mem info: $!\n";
    while (<MEMINFO>) {
        if ($os =~ /SunOS/) {
            if (/Memory:\s+([^ ]*)M\s+real,\s([^ ]*)M\s+free,/) {
                $mem{max} = $1;
                $mem{avail} = $2;
                $mem{used} = $mem{max} - $mem{avail};
            }
        }
        if ($os =~ /Linux/) {
#            next if /^Memory:/;
            if (/Mem:\s+([^ ]*)\s+([^ ]*)\s+([^ ]*)/) {
                print $_;
                $mem{max} = $1;
            }
            if (/\-\/\+ buffers\/cache:\s+([^ ]*)\s+([^ ]*)/) {
                print $_;
                $mem{used} = $1;
                $mem{avail} = $2;
            }
        }
    
    }
    printf ("%d\n",$mem{max});
    printf ("%d\n",$mem{used});
    close(TOP);
}

if ( $option == 2 ) {
    open(SARR,"$command{sar} |");
    while(<SARR>) {
        next if /SunOS|Linux/;
        next if /\%idle/;
        if ( $os =~ /SunOS/ ) {
            ($sar{date},$sar{usr},$sar{sys},$sar{wio},$sar{idle}) = split(/ +/);
        } 
        if ( $os =~ /Linux/ ) {
            ($sar{date},$sar{cpu},$sar{usr},$sar{sys},$sar{wio},$sar{idle}) = split(/ +/);
        } 
  
    }
    close SARR;
    $sar{busy} = 100 - $sar{idle};
    printf ("%d\n", $sar{busy});
    printf ("%d\n", $sar{busy});
}

if ( $option == 3 ) {
    $pid = open(SWAP, "$command{swap} |") or die "Couldn't run swap $command{swap}: $!\n";
    while (<SWAP>) {
        if ($os =~ /SunOS/) {
            $_ =~ /\w*=.* (\d+)k.*used,.* (\d+)k.*available/;
            $swap{used} = $1 * .001;
            $swap{avail} = $2 * .001;
            $swap{max} = $swap{used} + $swap{avail};
        }
        if ($os =~ /Linux/) {
            $_ =~ /^Swap\:\s+([^ ]*)\s+([^ ]*)\s+([^ ]*)/;
            $swap{avail} = $1 * .001;
            $swap{used} = $2 * .001;
            $swap{max} = $swap{avail};
        }
    }
    printf ("%d\n", $swap{max});
    printf ("%d\n", $swap{used});
}

if ( $option == 4 ) {
    $pid = open(DF, "$command{df} $device |") or die "Couldn't run df: $!\n";
    while (<DF>) {
        next if /^Filesystem/;
        if ( $os =~ /SunOS/ ) {
            ($df{source},$df{total},$df{used},$df{avail},$df{cap},$df{mounted})=split(' ',$_);
        }
        if ( $os =~ /Linux/ ) {
            next if /^\w+/;
            ($df{total},$df{used},$df{avail},$df{cap},$df{mounted})=split(' ',$_);
        }
        $df{total} = $df{total} / 1024;
        $df{used} = $df{used} / 1024;
    }
    printf ("%d\n", $df{total});
    printf ("%d\n", $df{used});
}

if ( $option =~ /[5-8]/ ) {
    my $local_line=0;
    $pid = open(IOSTAT, "$command{io} |") or die "Couldn't run $command{io}: $!\n";
    while (<IOSTAT>) {
        if (/$device/) {
            $local_line++;
            next if ($local_line == 1);
            print $_;
            $_ =~ /^\/dev\/$device\s+[^ ]*\s+[^ ]*\s+[^ ]*\s+[^ ]*\s+[^ ]*\s+[^ ]*\s+([^ ]*)\s+([^ ]*)\s+[^ ]*\s+([^ ]*)\s+([^ ]*)\s+([^ ]*)\s+([^ ]*)/;
            $data{rkbs}=$1;
            $data{wkbs}=$2;
            $data{avgqu}=$3;
            $data{await}=$4;
            $data{svctm}=$5;
            $data{util}=$6;

        } else {
            next;
        }
    }
    close IOSTAT;
    if ( $option == 5 ) {
        if ( $data{rkbs} >= 0.50 ) {
            $data{rkbs} = 1;
        }
        if ( $data{wkbs} >= 0.50 ) {
            $data{wkbs} = 1;
        }
        printf ("%d\n", $data{rkbs});
        printf ("%d\n", $data{wkbs});
    }
    if ( $option == 6 ) {
        printf ("%d\n", $data{avgqu});
        printf ("%d\n", $data{avgqu});
    }
    if ( $option == 7 ) {
        printf ("%d\n", $data{await});
        printf ("%d\n", $data{svctm});
    }
    if ( $option == 8 ) {
        printf ("%d\n", $data{util});
        printf ("%d\n", $data{util});
    }
}

if ( $option =~ /9/ ) {
    $pid = open(NETSTAT, "$command{net} |") or die "Couldn't run $command{net}: $!\n";
    while (<NETSTAT>) {
        if (/^Average/) {
            if (/^Average:\s+$device\s+[^ ]*\s+[^ ]*\s+([^ ]*)\s+([^ ]*)\s+[^ ]*\s+[^ ]*\s+[^ ]*/) {
                print $_;
                $data{rxbyt}=$1;
                $data{txbyt}=$2;
            }
        } else {
            next;
        }
    }
    close NETSTAT;
    printf ("%d\n", $data{rxbyt});
    printf ("%d\n", $data{txbyt});
}

if ( $option =~ /10/ ) {
    $pid = open(NETERR, "$command{neterr} |") or die "Couldn't run $command{neterr}: $!\n";
    while (<NETERR>) {
        if (/^Average/) {
            if (/^Average:\s+$device\s+[^ ]*\s+[^ ]*\s+[^ ]*\s+([^ ]*)\s+([^ ]*)\s+[^ ]*\s+[^ ]*/) {
                print $_;
                $data{rxdrop}=$1;
                $data{txdrop}=$2;
            }
        } else {
            next;
        }
    }
    close NETERR;
    printf ("%d\n", $data{rxdrop});
    printf ("%d\n", $data{txdrop});
}
