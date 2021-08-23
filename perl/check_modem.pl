#!/tools/perl/5.6.0/SunOS/bin/perl

use File::Basename;
use Mail::Sendmail;
use Date::Manip;

$SERVER_INFO="/tools/isofax/work/server_info /tools/isofax/work.2/server_info";
$EMAILLIST="9492797671\@messaging.nextel.com,isofax-admins-list\@broadcom.com";
#$EMAILLIST="9492797671\@messaging.nextel.com,raytran\@broadcom.com";
#$EMAILLIST="9492797671\@messaging.nextel.com,raytran\@broadcom.com";

open(CHK,"cat $SERVER_INFO|");
        while(<CHK>) {
        if (/dev/) { 
#		print $_;
		chop($_);
		($MODEM,$TYPE,$USAGE,$STATUS) = split / +/, $_, 4;
		if ($STATUS =~ /DOWN/) {
			($DOWN,$MESSAGE) = split /:/, $STATUS, 2;	
#			print "$MESSAGE\n";
			&Notify("$EMAILLIST","ISOFAX_MONITOR - Modem $MODEM is down on fax-irva-1.\n","Warning, Modem $MODEM is down on fax-irva-1 with the following error message:\n $MESSAGE.\n\n");
			
		}
	}
}
close CHK;

sub Notify {
    my($MySentTo,$MySubject,$MyMessage)=@_;
    %mail = (
            smtp    => 'smtphost.broadcom.com',
            to      => $MySentTo,
            from    => 'faxmgr@broadcom.com',
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
