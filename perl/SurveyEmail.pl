#!/usr/brcm/ba/bin/perl
use strict;
use ARS;
use Getopt::Std;
use Data::Dumper;
use GD::Graph::area;
use Date::Manip;
use File::Path;
use Mail::Sendmail;
use Tie::IxHash;

my (@myemaillist, %emailinfo);

#open(FILE,"/home/raytran/tmp/myemaillist.txt") or die "Can't open Email file: $!\n";
open(FILE,"/home/raytran/tmp/myemaillist1.txt") or die "Can't open Email file: $!\n";
while(<FILE>) {
    push (@myemaillist,$_);
}

#print Dumper(@myemaillist);
$emailinfo{from}="awoo\@broadcom.com";
$emailinfo{sub}="Survey Test - Please fill out the survey regarding our new vacation policy\n";
$emailinfo{mess} = '
Please access the following URL and submit a quick survey regarding our new vacation policy.<br>
http://itbu.broadcom.com/scm/Lists/EngCM%20Test/overview.aspx<br>
Please note that you can only submit one entry. You are allow to modify your entry and delete your entry once you have submitted it. Please see the instruction below.<br>
<br>
<br>
<b>INSTRUCTIONS</b><br>
<u>To submit a survey</u><br>
Please use the Internet Explorer browser and<br>
1. Select/Click on this URL - http://itbu.broadcom.com/scm/Lists/EngCM%20Test/overview.aspx<br>
2. Click on to the menu item "Respond to this Survey".<br>
3. Fill out the form. Please limit your response to 50 characters or less.<br>
4. Click "Finish" to complete the process.<br>
<br>
<br>
<u>To change your survey</u><br>
Please use the Internet Explorer browser and<br>
1. Select/Click on this URL - http://itbu.broadcom.com/scm/Lists/EngCM%20Test/AllItems.aspx<br>
2. Locate your response, move your mouse over the "View response #", left click the down arrow to access the menu and select "Edit Response".<br>
3. Select "Edit Response".<br>
4. Change your response, then click "Finish".<br>
<br>
<br>
<u>To delete your survey</u><br>
Please use the Internet Explorer browser and<br>
1. Select/Click this URL - http://itbu.broadcom.com/scm/Lists/EngCM%20Test/AllItems.aspx<br>
2. Locate your response, move your mouse over the "View response #", left click the down arrow to access the menu.<br>
3. Select "Delete Response" from the menu.<br>
';


my $email_add;
foreach $email_add (@myemaillist) {
    chop($email_add);
    $emailinfo{to} = $email_add;
#    print "Sending Email to $email_add\n";
    &Notify("$emailinfo{from}","$emailinfo{to}","$emailinfo{sub}","$emailinfo{mess}");
}

sub Notify {
    my($MyFrom,$MySentTo,$MySubject,$MyMessage)=@_;
    
    my %mail = (
            'Content-type' => 'text/html',
            Smtp    => 'smtphost.broadcom.com',
            From    => $MyFrom,
            To      => $MySentTo,
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
