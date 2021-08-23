#!/usr/local/bin/perl

use Mail::Sendmail;

#$SentTo="raytran\@broadcom.com";
#$CcTo="vobadm\@broadcom.com";
$SentTo="Test\/8155017418 \<isofaxq2\@broadcom.com\>";
$Subject="This is the new subject\n";
$Message="This is the message for all\n
          New line: adfadfad \n
          More new line: kkkkk\n\n\n";
&Notify($SentTo,$CcTo,$Subject,$Message);
#open(MT,"< test.txt");
#while(<MT>) {
#    $Message=join "", $Message,$_;
#}
#print $Message;
#&Notify("raytran\@broadcom.com, cttok\@broadcom.com","Test Mail","Hi Guys, Santa wants to wish you a Merry Christmas.\n Merry Christmas,\n Santa");

sub Notify {    
    my($MySentTo,$MyCcTo,@MySubject,@MyMessage)=@_;
    %mail = (
            smtp    => 'smtphost.broadcom.com',
            To      => $MySentTo,
            Cc      => $MyCcTo,
            From    => 'santa.clause@northpole.org',
            Subject => @MySubject,
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
