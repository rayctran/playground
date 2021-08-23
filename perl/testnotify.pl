#!/tools/perl/5.6.0/SunOS/bin/perl
#

use File::Basename;
use Mail::Sendmail;
use Date::Manip;


#$PageList = "9494395234\@mobile.att.net";
$Notify_List = "raytran\@broadcom.com";
$Cc_List = "vobadm\@broadcom.com";

&Notify("$PageList","$Cc_List","CC_MONITOR_WARNING - No response from $Server.\n","Warning, $Server did not response to the ping process from the monitor server $ThisHost.\n\n\n");


sub Notify {
    my($MySentTo,$MyCcTo,$MySubject,$MyMessage)=@_;
    %mail = (
            smtp    => 'smtphost.broadcom.com',
            To      => $MySentTo,
            Cc      => $MyCcTo,
            From    => 'raytran@broadcom.com',
            Subject => $MySubject,
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
