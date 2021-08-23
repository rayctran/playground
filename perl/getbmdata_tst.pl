#!/usr/local/bin/perl


# Input required
# $1 server's name
# $2 which data to grab 
#  1 - 1 checkout/1 uncheckout
#  2 - checkin/10 checkin
#  3 - 10 checkout/10 uncheckout
#  4 - lscheckout/update view
#  5 - version tree/mkbrach 

$coth=2;
$cith=3;

if ($#ARGV < 1) {
        print "Usage: $0 server option\n";
        exit (1);
} else {
        $Server=$ARGV[0];
        $Option=$ARGV[1];
}

if ("$Server" eq "ccase-irva-2") {
    $Logfile="/projects/ccase/temp/Reports/ccase_benchmark_irvine_log";
} elsif ("$Server" eq "ccase-sj1-1") {
    $Logfile="/projects/ccase/temp/Reports/ccase_benchmark_sanjose_log";
} elsif ("$Server" eq "ccase-blr-1") {
    $Logfile="/projects/ccase/temp/Reports/ccase_benchmark_bangalore_log";
} elsif ("$Server" eq "ccase-rmna-1") {
    $Logfile="/projects/ccase/temp/Reports/ccase_benchmark_rmna_log";
} elsif ("$Server" eq "ccase-irva-tst2") {
    $Logfile="/projects/ccase_irva/logs/ccase_benchmark_irvine_log";
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
          if ($Time > $coth) {
              &Notify("clearcase-bse-admin-list\@broadcom.com,raytran\@broadcom.com","Warning, ClearCase checkout command exceeded threadshold on $Server\n","Checkout time on $Server is $Time.\n\n\n\n");
          }
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
          if ($Time > $cith) {
              &Notify("clearcase-bse-admin-list\@broadcom.com,raytran\@broadcom.com","Warning, ClearCase checkin command exceeded threadshold on $Server\n","Checkin time on $Server is $Time.\n\n\n\n");
          }
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

system ("rm /tmp/mylog.$$");

sub Notify {
    my($MySentTo,@MySubject,@MyMessage)=@_;
    %mail = (
            smtp    => 'smtphost.broadcom.com',
            to      => $MySentTo,
            from    => 'ccmonitor@broacom.com',
            subject => @MySubject,
            message => @MyMessage,
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
