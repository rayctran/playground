#!/usr/local/bin/perl


# Input required
# $1 server's name
# $2 which data to grab 
#  1 - 1 checkout/1 uncheckout
#  2 - checkin/10 checkin
#  3 - 10 checkout/10 uncheckout
#  4 - lscheckout/update view
#  5 - version tree/mkbrach 


# Setting upper level (in sec) for each data collected
#

# Checkouts
$co_th=4;
$uco_th=4;



if ($#ARGV < 1) {
        print "Usage: $0 server\n";
        exit (1);
} else {
        $Server=$ARGV[0];
        $Option=$ARGV[1];
}

if ("$Server" eq "ccase-irva-2") {
    $Logfile="/projects/ccase/temp/Reports/ccase_benchmark_irvine_log";
}
if ("$Server" eq "ccase-sj1-1") {
    $Logfile="/projects/ccase/temp/Reports/ccase_benchmark_sanjose_log";
}
#
# We only need the last 11 lines of the log file
#
system ("tail -10 $Logfile > /tmp/mylog.$$");

# Read in the temp log file
open(LF,"/tmp/mylog.$$") || die "Can't open temp log file\n";
while(<LF>) {
   chop;
   if ("$Option" == 1) {
      if (/One checkout/) {
          s/ +//g;
          ($Action,$Time) = split(/\:/);
          print "$Time\n";
      }
      if (/One uncheckout/) {
          s/ +//g; #Remove blanks
          ($Action,$Time) = split(/\:/);
          print "$Time\n";
      }
   } 
   if ("$Option" == 2) {
      if (/One checkin/) {
          s/ +//g;
          ($Action,$Time) = split(/\:/);
          print "$Time\n";
      }
      if (/Ten checkin/) {
          s/ +//g; #Remove blanks
          ($Action,$Time) = split(/\:/);
          print "$Time\n";
      }
   } 
   if ("$Option" == 3) {
      if (/Ten checkout/) {
          s/ +//g;
          ($Action,$Time) = split(/\:/);
          print "$Time\n";
      }
      if (/Ten uncheckout/) {
          s/ +//g; #Remove blanks
          ($Action,$Time) = split(/\:/);
          print "$Time\n";
      }
   } 
   if ("$Option" == 4) {
      if (/Ten lscheckout/) {
          s/ +//g;
          ($Action,$Time) = split(/\:/);
          print "$Time\n";
      }
      if (/Update view/) {
          s/ +//g; #Remove blanks
          ($Action,$Time) = split(/\:/);
          print "$Time\n";
      }
   } 
   if ("$Option" == 5) {
      if (/Version Tree/) {
          s/ +//g;
          ($Action,$Time) = split(/\:/);
          print "$Time\n";
      }
      if (/One mkbranch/) {
          s/ +//g; #Remove blanks
          ($Action,$Time) = split(/\:/);
          print "$Time\n";
      }
   } 
}

sub Notify {
    local ($Subject,$Message)=@_;

open(SENDMAIL, "|/usr/lib/sendmail -oi -t -odq") or die "Can't fork sendmail: $!\n";
print SENDMAIL <<"EOF";
From: raytran\@broadcom.com,clearcase-bse-admin-list@broadcom.com
To:  raytran\@broadcom.com
Subject: $Subject

$Message
EOF
close(SENDMAIL);    



}
system ("rm /tmp/mylog.$$");
