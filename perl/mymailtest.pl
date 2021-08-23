#!/tools/perl/5.6.0/SunOS/bin/perl
use Mail::Sendmail;

#$SentTo="raytran\@broadcom.com";
$SentTo="N/6304836602\<isofax\@broadcom.com\>";
$Subject="This is the new subject\n";
open(MT,"< test.txt");
while(<MT>) {
    $Message=join "", $Message,$_;
}

%mail = (
        smtp    => 'smtphost.broadcom.com',
        to      => $SentTo,
        from    => 'santa.clause@northpole.org',
        subject => $Subject,
        message => $Message,
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
