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
$emailinfo{sub}="Survey Test - Please fill out the survey regarding our new vacation policy";
$emailinfo{mess}="Please access the following URL and submit a quick survey regarding our new vacation policy.\n";
$emailinfo{mess} .= "http://itbu.broadcom.com/scm/Lists/EngCM%20Test/overview.aspx\n";
$emailinfo{mess} .="Please note that you can only submit one entry. You are allow to modify your entry and delete your entry once you have submittted it. Please see the instruction below.\n";
$emailinfo{mess} .= "\n\n";
$emailinfo{mess} .="INSTRUCTIONS\n";
$emailinfo{mess} .="\<u\>To submit a survey\<u\>\n";
$emailinfo{mess} .= "Click on to the menu item \"Respond to this Survey\" to begin. Fill out the form. Please limit your response to 50 characters. Click \"Finish\" to complete the process.\n";
$emailinfo{mess} .= "\n\n";
$emailinfo{mess} .="\<u\>To change your survey\<u\>, please use the Internet Explorer browser and\n";
$emailinfo{mess} .= "1. Select this URL - http://itbu.broadcom.com/scm/Lists/EngCM%20Test/AllItems.aspx\n";
$emailinfo{mess} .= "2. Locate your response, move your mouse over the \"View response #<number>\", left click the down arrow to access the menu and select \"Edit Response\".\n";
$emailinfo{mess} .= "3. Select \"Edit Response\".\n";
$emailinfo{mess} .= "4. Change your response, then click \"Finish\".\n";
$emailinfo{mess} .= "\n\n";
$emailinfo{mess} .="\<u\>To delete your survey\<u\>, please use the Internet Explorer browser and\n";
$emailinfo{mess} .= "1. Select this URL - http://itbu.broadcom.com/scm/Lists/EngCM%20Test/AllItems.aspx\n";
$emailinfo{mess} .= "2. Locate your response, move your mouse over the \"View response #<number>\", left click the down arrow to access the menu.\n";
$emailinfo{mess} .= "3. Select \"Delete Response\" from the menu.\n";

my $email_add;
foreach $email_add (@myemaillist) {
    chop($email_add);
    $emailinfo{to} = $email_add;
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
        exit(0);
    }
}
