#!/usr/local/bin/perl

use strict;
use Mail::Sendmail;


#####
# section 1
#####
sub Notify {
    my($MyFrom,$MySentTo,$MyCcTo,$MySubject,$MyMessage)=@_;
    
    my %mail = (
#            'Content-type' => 'text/html',
            Smtp    => 'smtphost.broadcom.com',
            From    => $MyFrom,
            To      => $MySentTo,
	    Cc      => $MyCcTo,
            subject => $MySubject,
            message => $MyMessage,
    );

    eval { sendmail(%mail) || die $Mail::Sendmail::error; };
    $Mail::Sendmail::log;

    if ($@) {
        print "mail could NOT be sent correctly - $@\n";
    } else {
        print "mail sent correctly\n";
        exit(0);
    }
}

######
# end section 1
######

#$Email_List="raytran\@broadcom.com, raytran\@broadcom.com";
#$TestBody = "Body test line one\n";
#$TestBody = "$TestBody line 2\n";


#open(SENDMAIL, "|/usr/lib/sendmail -oi -t -odq") or die "Can't fork for sendmail: $!\n";
#print SENDMAIL <<"EOF";
#From: Root <root\@dns-rmna-1.ca.broadcom.com>
#To: $Email_List
#Subject: A relevant subject line
#$TestBody
#EOF
#close(SENDMAIL)     or warn "sendmail didn't close nicely";

#system("mailx -s \"Test mail for me\" $Email_List < ttt");

my $notify_list="help\@broadcom.com";
my $cc_list="raytran\@broadcom.com";

my $message.="Testing. Please route ticket to SCM\-\>CVS\-\>Other.\n";
$message.="\@\~CT R\n";
$message.="\@\~CCA raytran\n";
$message.="\@\~C \"SCM\"\n";
$message.="\@\~T \"CVS\"\n";
$message.="\@\~I \"Other\"\n";
$message.="This is the body\n";
Notify("raytran\@broadcom\.com","$notify_list",$cc_list","Testing","$message");
