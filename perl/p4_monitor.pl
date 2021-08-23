#!/bin/perl


use strict;
use Mail::Sendmail;


my $PLIST_CMD = "pslist.exe";
my $SERVER = "p4runner";
my $PROC = "p4s";
my $PROC_NAME="Mobile Com Perforce";
my $PAGE_LIST = "9494395234\@mobile.att.net;\n";
#my $NOTIFY_LIST = "raytran\@broadcom.com;wcheng\@broadcom.com\n";
my $NOTIFY_LIST = "raytran\@broadcom.com;wcheng\@broadcom.com\n";
my $MAX_CPU = 40;
my %proc_info;
my $current_time = localtime();

main ();
exit ();

sub main {
    my ($subject,$message,$cmd,$cmd_output);
    print "Running main\n";
    open (RUNPLIST, "$PLIST_CMD \-s 1 \\\\$SERVER $PROC | ") or die "Can't run $PLIST_CMD: $!\n";
       while (<RUNPLIST>) {
          chop;
           if (/^$PROC/) {
               (
                  $proc_info{proc_name},
                  $proc_info{pid},
                  $proc_info{cpu},
                  $proc_info{thd},
                  $proc_info{hnd},
                  $proc_info{priv},
                  $proc_info{cpu_time},
                  $proc_info{elap_time}
               ) = split(/^\s+$/);
               if ($proc_info{cpu} >= $MAX_CPU) {
                   $subject = "WARNING - $PROC_NAME on $SERVER exceed $MAX_CPU CPU percentage - $current_time\n";
                   $message .= "$PROC_NAME details information\n";
#                   $cmd = "$PLIST_CMD -x \\\\$SERVER $PROC";
                   $cmd_output = `$PLIST_CMD -s 1 \\\\$SERVER $PROC`;
                   $message .= $cmd_output;
                   $cmd_output = `$PLIST_CMD -x \\\\$SERVER $PROC`;
                   $message .= $cmd_output;
                   &Notify("$NOTIFY_LIST","$subject","$message");
                   #Paging. Remove body because we want to make it short and sweet
                   $message = "";
                   &Notify("$PAGE_LIST","$subject","$message");
               }
           }
       }
       close (RUNPLIST);
}

sub Notify {
    my ($SentTo,$Subject,$Message) = @_;
    my %mail = (
            smtp    => 'smtphost.broadcom.com',
            to      => $SentTo,
            from    => 'raytran@broadcom.com',
            subject => $Subject,
            message => $Message,
    );

    eval { sendmail(%mail) || die $Mail::Sendmail::error; };
    $Mail::Sendmail::log;

    if ($@) {
            print "mail could NOT be sent correctly - $@\n";
    } else {
            print "mail sent correctly\n";
    }
}
