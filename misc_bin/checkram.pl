#!/usr/bin/perl
#
# checkram.pl - Check RAM usage and reload if over 90%
# Install path: /usr/local/bin/checkram.pl
#### INSTALL: ####
# 1. Touch /var/log/checkram.log
# 2. Install crontab as below:
# * * * * * /usr/bin/perl /usr/local/bin/checkram.pl >> /var/log/checkram.log 2>&1

use warnings;
use strict;

my $os = `lsb_release -d \| /usr/bin/gawk -F\"\\t\" \'{print \$2}\'| awk \'{print \$1}\'`;

my $swap = `free -m | grep ^Swap`;
my $ram = `free -m | grep ^Mem`;
my @ramargs = split(' ',$ram);
my @args = split(' ',$swap);
my $value = $args[2];
my $total = $args[1];
my $ramval = $ramargs[2];
my $cacheval = $ramargs[6];
my $ramtot = $ramargs[1];

my $ts = scalar localtime;

my $ramused = $ramval - $cacheval;

print "[$ts] Ram (used-cache/total): $ramused/$ramtot Swap: $value/$total\n";

if ($value >= 1024 || $ramused >= ($ramtot * .90 )) {
        my $returnCode = 255;
        for (my $x = 1; $x <= 10; $x++) {
                print "[$ts] Attempt $x:\n";
        	print "[$ts] Bringing Down Apache...\n[$ts] ";
	        if ($os =~ /Ubuntu/) {
                    system("/usr/sbin/service apache2 stop");
        	} elsif ($os =~ /CentOS/) {
                    system("/sbin/service httpd stop");
        	}        
                if ($returnCode == 0) {
                        print "[$ts] Reloaded!\n";
                        last;
                }
                elsif ($x < 10) {
                        print "[$ts] Error: $!\n";
                        print "[$ts] Attempting again.\n";
                }
                else {
                    print "[$ts] KILLING APACHE PROCESSES!";
	            if ($os =~ /Ubuntu/) {
                        system ("killall -9 apache2");
        	    } elsif ($os =~ /CentOS/) {
                        system ("killall -9 httpd");
        	    }        
                }
        }

        $returnCode = system("/sbin/swapoff -a; /sbin/swapon -a");
        if ($returnCode != 0) {
                print "[$ts] Error: $!\n";
        }

        print "[$ts] Cleaning up semaphore...\n[$ts] ";
	if ($os =~ /Ubuntu/) {
	    $returnCode = system("for i in \`ipcs -s \| awk \'\/www-data\/ {print \$2}\'\`; do \(ipcrm -s \$i\)\; done");
	} elsif ($os =~ /CentOS/) {
	    $returnCode = system("for i in \`ipcs -s \| awk \'\/apache\/ {print \$2}\'\`; do \(ipcrm -s \$i\)\; done");
	}        

        if ($returnCode != 0) {
                print "[$ts] Error: $!\n";
        }

        print "[$ts] Restarting Apache...\n[$ts] ";
	if ($os =~ /Ubuntu/) {
            $returnCode = system("/usr/sbin/service apache2 start");
	} elsif ($os =~ /CentOS/) {
            $returnCode = system("/sbin/service httpd start");
        }

        if ($returnCode != 0) {
                print "[$ts] Error: $!\n";
        }
}
