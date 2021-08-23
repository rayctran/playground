sub Notify {
    use Mail::Sendmail;
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
# Notify("raytran\@broadcom\.com","$notify_list",$cc_list","Testing","$message");
