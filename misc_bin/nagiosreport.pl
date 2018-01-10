#!/usr/bin/perl -w
#
# Nagios overnight/daily/weekly/monthly reporter
#
# Fetches Nagios report from web, processes HTML/CSS and emails to someone
# Written by Rob Moss, 2005-07-26, coding@...
#
# Use at your own risk, knoweledge of perl required.
#
# Version 1.3.1
# - Overnight, Daily, Weekly, Monthly reports
#

use strict;
use Getopt::Long;
use Net::SMTP;
use LWP::UserAgent;
use Date::Manip;


my $mailhost    =       'mx.trigold.net'; #     Fill these in!
my $maildomain  =       'trigold.net';  #       Fill these in!
my $mailfrom    =       'nagios@...'; #       Fill these in!
my $mailto = "";
my $timeout             =       30;
my $mailsubject =       '';
my $mailbody    =       '';
my $file =      "";
my $filedir =   "";
my $logfile     =       '/apps/nagios/var/mail.log';    #       Where would you like your logfile to live?
my $debug               =       1; #Set the debug level to 1 or higher for information
my $type                =       '';
my $repdateprev;
my $reporturl;
my $availreport;
my $alertreport;
my $servicegroup        = "all";
my $nagssbody;
my $nagsssummary;

my $webuser             = 'nagios'; #Set this to a read-only nagios user (not nagiosadmin!)
my $webpass             = 'password'; #Set this to a read-only nagios user (not nagiosadmin!)
my $webbase             = 'http://monitor.office.trigold.net/nagios';;    #Set this to the base of Nagios web page

my $webcssembed =       0;


GetOptions (
        "debug=s"       =>      \$debug,
        "help"          =>      \&help,
        "type=s"        =>      \$type,
        "email=s"       =>      \$mailto,
        "file=s"        =>      \$filedir,
        "embedcss"      =>      \$webcssembed,
        "avail"         =>      \$availreport,
        "alerts"        =>      \$alertreport,
        "servicegroup=s"        =>      \$servicegroup,
);


if (not defined $type or $type eq "") {
        help();
        exit;
}
elsif ($type eq "overnight") {
        if ($availreport) {
                report_overnight_avail();
        }
        elsif ($alertreport) {
                report_overnight();
        }
        else { die("Unknown Availability or Alerts\n"); }
}
elsif ($type eq "daily") {
        report_daily();
        if ($availreport) {
                report_daily_avail();
        }
        elsif ($alertreport) {
                report_daily();
        }
        else { die("Unknown Availability or Alerts\n"); }
}
elsif ($type eq "weekly") {
        if ($availreport) {
                report_weekly_avail();
        }
        elsif ($alertreport) {
                report_weekly();
        }
        else { die("Unknown Availability or Alerts\n"); }
}
elsif ($type eq "monthly") {
        if ($availreport) {
                report_monthly_avail();
        }
        elsif ($alertreport) {
                report_monthly();
        }
        else { die("Unknown Availability or Alerts\n"); }
}
else {
        die("Unknown report type $type\n");
}

debug(1,"reporturl: [$reporturl]");

$mailbody = http_request($reporturl);
if ($webcssembed) {
        # Stupid hacks for dodgy notes
        $nagssbody              =
http_request("$webbase/stylesheets/summary.css");
        $nagsssummary = "<style type=\"text\/css\">\n";
        foreach ( split(/\n/,$nagssbody) ) {
                chomp;
                if (not defined $_ or $_ eq "" ) {
                        next;
                }
                $nagsssummary .= "<!-- $_ -->\n";
        }
        $nagsssummary .= "</style>\n";
        $nagsssummary .= "<base href=\"$webbase/cgi-bin/\">\n";

        $mailbody =~ s@<LINK REL=\'stylesheet\' TYPE=\'text/css\'
HREF=\'/stylesheets/common.css\'>@@;
        $mailbody =~ s@<LINK REL=\'stylesheet\' TYPE=\'text/css\'
HREF=\'/stylesheets/summary.css\'>@$nagsssummary@;
}

if ($file) {
        open(FILE, "> $file") or warn "can't open file
/tmp/nagios-report-htmlout.html: $!\n";
        print FILE $mailbody;
        close FILE;
} elsif ($mailto) {
        sendmail();
} else {
        die("No File or Email Specified\n");
}


###############################################################################
sub help {
print <<_END_;

Nagios web->email reporter program.

$0 <args>

--help
        This screen

--email=<email>
        Send to this address instead of the default address
        "$mailto"

--file=<dir>
        Directory to write Reports to in eg /usr/local/nagios/share/reports
                ./avail/<daterun>-<type>-<avail|alert>.html
--type=overnight
        Overnight report, from 17h last working day to Today (9am)
--type=daily
        Daily report, 09:00 last working day to Today (9am)
--type=weekly
        Weekly report, 9am 7 days ago, until 9am today (run at 9am friday!)
--type=monthly
        Monthly report, 1st of prev month at 9am to last day of month, 9am

--avail Availabilty Reports
--alerts Aler Reports
--embedcss
        Downloads the CSS file and embeds it into the main HTML to enable
        Lotus Notes to work (yet another reason to hate Notes)

_END_

exit 1;

}

###############################################################################
sub report_monthly {
        # This should be run on the 1st of every month
        $repdateprev = DateCalc("yesterday",1);
        debug(1,"repdateprev = $repdateprev");
#                               #2006072116:48:37
        my ($repsday, $repsmonth, $repsyear, $repshour ) = 0;
        $repdateprev =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repsday = 01;
        $repsmonth = $2;
        $repsyear = $1;
        $repshour = 0;

        my ($repeday, $repemonth, $repeyear, $repehour ) = 0;
        my $repdatenow = ParseDate("today");
        debug(1,"repdatenow = $repdatenow");
        $repdatenow =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repeday = $3;
        $repemonth = $2;
        $repeyear = $1;
        $repehour = 0;

        $reporturl =
"$webbase/cgi-bin/summary.cgi?report=1&displaytype=1&timeperiod=custom"
.

"&smon=$repsmonth&sday=$repsday&syear=$repsyear&shour=$repshour&smin=0&ssec=0"
.

"&emon=$repemonth&eday=$repeday&eyear=$repeyear&ehour=$repehour&emin=0&esec=0"
.

"&hostgroup=all&servicegroup=$servicegroup&host=all&alerttypes=3&statetypes=2&hoststates=3"
.
                        "&servicestates=56&limit=500";
        $file = "$filedir/alerts/$type-$repeyear-$repemonth-$repeday.html";
        $mailsubject = "Nagios alerts for month $repsmonth/$repsyear";
}

sub report_monthly_avail {
        # This should be run on the 1st of every month
        $repdateprev = DateCalc("yesterday",1);
        debug(1,"repdateprev = $repdateprev");
#                               #2006072116:48:37
        my ($repsday, $repsmonth, $repsyear, $repshour ) = 0;
        $repdateprev =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repsday = 01;
        $repsmonth = $2;
        $repsyear = $1;
        $repshour = 0;

        my ($repeday, $repemonth, $repeyear, $repehour ) = 0;
        my $repdatenow = ParseDate("today");
        debug(1,"repdatenow = $repdatenow");
        $repdatenow =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repeday = $3;
        $repemonth = $2;
        $repeyear = $1;
        $repehour = 0;

        $reporturl =
"$webbase/cgi-bin/avail.cgi?show_log_entries=&servicegroup=$servicegroup&timeperiod=custom"
.

"&smon=$repsmonth&sday=$repsday&syear=$repsyear&shour=$repshour&smin=0&ssec=0"
.

"&emon=$repemonth&eday=$repeday&eyear=$repeyear&ehour=$repehour&emin=0&esec=0"
.

"&rpttimeperiod=24x7&assumeinitialstates=yes&assumestateretention=yes"
.

"&assumestatesduringnotrunning=yes&includesoftstates=no&initialassumedhoststate=0"
.
                        "&initialassumedservicestate=0&backtrack=4";
        $file =
"$filedir/availability/$type-$repeyear-$repemonth-$repeday.html";
        $mailsubject = "Nagios alerts for month $repsmonth/$repsyear";

}

###############################################################################
sub report_weekly {
        # This should be run on Monday, 9am
        $repdateprev = Date_PrevWorkDay("today",5);
        debug(1,"repdateprev = $repdateprev");
                                #2006072116:48:37
        my ($repsday, $repsmonth, $repsyear, $repshour ) = 0;
        $repdateprev =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repsday = $3;
        $repsmonth = $2;
        $repsyear = $1;
        $repshour = 9;

        my ($repeday, $repemonth, $repeyear, $repehour ) = 0;
        my $repdatenow = ParseDate("today");
        debug(1,"repdatenow = $repdatenow");
        $repdatenow =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repeday = $3;
        $repemonth = $2;
        $repeyear = $1;
        $repehour = 9;

        $reporturl =
"$webbase/cgi-bin/summary.cgi?report=1&displaytype=1&timeperiod=custom"
.

"&smon=$repsmonth&sday=$repsday&syear=$repsyear&shour=$repshour&smin=0&ssec=0"
.

"&emon=$repemonth&eday=$repeday&eyear=$repeyear&ehour=$repehour&emin=0&esec=0"
.

"&hostgroup=all&servicegroup=$servicegroup&host=all&alerttypes=3&statetypes=2&hoststates=3"
.
                        "&servicestates=56&limit=500";
        $file = "$filedir/alerts/$type-$repeyear-$repemonth-$repeday.html";
        $mailsubject = "Nagios alerts for week ending
$repsday/$repsmonth/$repsyear";

}


sub report_weekly_avail {
        # This should be run on Monday, 9am
        $repdateprev = Date_PrevWorkDay("today",5);
        debug(1,"repdateprev = $repdateprev");
                                #2006072116:48:37
        my ($repsday, $repsmonth, $repsyear, $repshour ) = 0;
        $repdateprev =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repsday = $3;
        $repsmonth = $2;
        $repsyear = $1;
        $repshour = 9;

        my ($repeday, $repemonth, $repeyear, $repehour ) = 0;
        my $repdatenow = ParseDate("today");
        debug(1,"repdatenow = $repdatenow");
        $repdatenow =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repeday = $3;
        $repemonth = $2;
        $repeyear = $1;
        $repehour = 9;

        $reporturl =
"$webbase/cgi-bin/avail.cgi?show_log_entries=&servicegroup=$servicegroup&timeperiod=custom"
.

"&smon=$repsmonth&sday=$repsday&syear=$repsyear&shour=$repshour&smin=0&ssec=0"
.

"&emon=$repemonth&eday=$repeday&eyear=$repeyear&ehour=$repehour&emin=0&esec=0"
.

"&rpttimeperiod=24x7&assumeinitialstates=yes&assumestateretention=yes"
.

"&assumestatesduringnotrunning=yes&includesoftstates=no&initialassumedhoststate=0"
.
                        "&initialassumedservicestate=0&backtrack=4";
        $file =
"$filedir/availability/$type-$repeyear-$repemonth-$repeday.html";
        $mailsubject = "Nagios alerts for week ending
$repsday/$repsmonth/$repsyear";

}

###############################################################################
sub report_daily {
        # This should be run on Daily, 7am
        $repdateprev = Date_PrevWorkDay("today",1);
        debug(1,"repdateprev = $repdateprev");
                                #2006072116:48:37
        my ($repsday, $repsmonth, $repsyear, $repshour ) = 0;
        $repdateprev =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repsday = $3;
        $repsmonth = $2;
        $repsyear = $1;
        $repshour = 7;

        my ($repeday, $repemonth, $repeyear, $repehour ) = 0;
        my $repdatenow = ParseDate("today");
        debug(1,"repdatenow = $repdatenow");
        $repdatenow =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repeday = $3;
        $repemonth = $2;
        $repeyear = $1;
        $repehour = 7;

        $reporturl =
"$webbase/cgi-bin/summary.cgi?report=1&displaytype=1&timeperiod=custom"
.

"&smon=$repsmonth&sday=$repsday&syear=$repsyear&shour=$repshour&smin=0&ssec=0"
.

"&emon=$repemonth&eday=$repeday&eyear=$repeyear&ehour=$repehour&emin=0&esec=0"
.

"&hostgroup=all&servicegroup=$servicegroup&host=all&alerttypes=3&statetypes=2&hoststates=3"
.
                        "&servicestates=56&limit=500";
        $file = "$filedir/alerts/$type-$repeyear-$repemonth-$repeday.html";
        $mailsubject = "Nagios alerts for 24 hours
$repsday/$repsmonth/$repsyear ${repshour}h to present";

}

sub report_daily_avail {
        # This should be run on Daily, 7am
        $repdateprev = Date_PrevWorkDay("today",1);
        debug(1,"repdateprev = $repdateprev");
                                #2006072116:48:37
        my ($repsday, $repsmonth, $repsyear, $repshour ) = 0;
        $repdateprev =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repsday = $3;
        $repsmonth = $2;
        $repsyear = $1;
        $repshour = 7;

        my ($repeday, $repemonth, $repeyear, $repehour ) = 0;
        my $repdatenow = ParseDate("today");
        debug(1,"repdatenow = $repdatenow");
        $repdatenow =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repeday = $3;
        $repemonth = $2;
        $repeyear = $1;
        $repehour = 7;

        $reporturl =
"$webbase/cgi-bin/avail.cgi?show_log_entries=&servicegroup=$servicegroup&timeperiod=custom"
.

"&smon=$repsmonth&sday=$repsday&syear=$repsyear&shour=$repshour&smin=0&ssec=0"
.

"&emon=$repemonth&eday=$repeday&eyear=$repeyear&ehour=$repehour&emin=0&esec=0"
.

"&rpttimeperiod=24x7&assumeinitialstates=yes&assumestateretention=yes"
.

"&assumestatesduringnotrunning=yes&includesoftstates=no&initialassumedhoststate=0"
.
                        "&initialassumedservicestate=0&backtrack=4";
        $file =
"$filedir/availability/$type-$repeyear-$repemonth-$repeday.html";
        $mailsubject = "Nagios alerts for 24 hours
$repsday/$repsmonth/$repsyear ${repshour}h to present";

}

###############################################################################
sub report_overnight {
        $repdateprev = Date_PrevWorkDay("today",1);
        debug(1,"repdateprev = $repdateprev");
                                #2006072116:48:37
        my ($repsday, $repsmonth, $repsyear, $repshour ) = 0;
        $repdateprev =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repsday = $3;
        $repsmonth = $2;
        $repsyear = $1;
        $repshour = 17;

        my ($repeday, $repemonth, $repeyear, $repehour ) = 0;
        my $repdatenow = ParseDate("today");
        debug(1,"repdatenow = $repdatenow");
        $repdatenow =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repeday = $3;
        $repemonth = $2;
        $repeyear = $1;
        $repehour = 9;

        $reporturl =
"$webbase/cgi-bin/summary.cgi?report=1&displaytype=1&timeperiod=custom"
.

"&smon=$repsmonth&sday=$repsday&syear=$repsyear&shour=$repshour&smin=0&ssec=0"
.

"&emon=$repemonth&eday=$repeday&eyear=$repeyear&ehour=$repehour&emin=0&esec=0"
.

"&hostgroup=all&servicegroup=$servicegroup&host=all&alerttypes=3&statetypes=2&hoststates=3"
.
                        "&servicestates=56&limit=500";
        $file = "$filedir/$repdatenow-$type-alert.html";
        $mailsubject = "Nagios overnight alerts from
$repsday/$repsmonth/$repsyear ${repshour}h to present";

}

sub report_overnight_avail {
        $repdateprev = Date_PrevWorkDay("today",1);
        debug(1,"repdateprev = $repdateprev");
                                #2006072116:48:37
        my ($repsday, $repsmonth, $repsyear, $repshour ) = 0;
        $repdateprev =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repsday = $3;
        $repsmonth = $2;
        $repsyear = $1;
        $repshour = 17;

        my ($repeday, $repemonth, $repeyear, $repehour ) = 0;
        my $repdatenow = ParseDate("today");
        debug(1,"repdatenow = $repdatenow");
        $repdatenow =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
        $repeday = $3;
        $repemonth = $2;
        $repeyear = $1;
        $repehour = 9;

        $reporturl =
"$webbase/cgi-bin/avail.cgi?show_log_entries=&servicegroup=$servicegroup&timeperiod=custom"
.

"&smon=$repsmonth&sday=$repsday&syear=$repsyear&shour=$repshour&smin=0&ssec=0"
.

"&emon=$repemonth&eday=$repeday&eyear=$repeyear&ehour=$repehour&emin=0&esec=0"
.

"&rpttimeperiod=24x7&assumeinitialstates=yes&assumestateretention=yes"
.

"&assumestatesduringnotrunning=yes&includesoftstates=no&initialassumedhoststate=0"
.
                        "&initialassumedservicestate=0&backtrack=4";
        $file = "$filedir/$repdatenow-$type-avail.html";
        $mailsubject = "Nagios overnight alerts from
$repsday/$repsmonth/$repsyear ${repshour}h to present";

}

###############################################################################
sub http_request {
        my $ua;
        my $req;
        my $res;

        my $geturl = shift;
        if (not defined $geturl or $geturl eq "") {
                warn "No URL defined for http_request\n";
                return 0;
        }
        $ua = LWP::UserAgent->new;
        $ua->agent("Nagios Report Generator " . $ua->agent);
        $req = HTTP::Request->new(GET => $geturl);
        $req->authorization_basic($webuser, $webpass);
        $req->header(   'Accept'                        =>      'text/html',
                                        'Content_Base'          =>
 $webbase,
                                );

        # send request
        $res = $ua->request($req);

        # check the outcome
        if ($res->is_success) {
                debug(1,"Retreived URL successfully");
                return $res->decoded_content;
        }
        else {
                print "Error: " . $res->status_line . "\n";
                return 0;
        }
}

###############################################################################
sub debug {
        my ($lvl,$msg) = @_;
        if ( defined $debug and $lvl <= $debug ) {
                chomp($msg);
                print localtime(time) .": $msg\n";
        }
        return 1;
}

#########################################################
sub sendmail {
        my $smtp = Net::SMTP->new(
                        $mailhost,
                        Hello => $maildomain,
                        Timeout => $timeout,
                        Debug   => $debug,
                );

        $smtp->mail($mailfrom);
        $smtp->to($mailto);

        $smtp->data();
        $smtp->datasend("To: $mailto\n");
        $smtp->datasend("From: $mailfrom\n");
        $smtp->datasend("Subject: $mailsubject\n");
        $smtp->datasend("MIME-Version: 1.0\n");
        $smtp->datasend("Content-type: multipart/mixed;
boundary=\"boundary\"\n");
        $smtp->datasend("\n");
        $smtp->datasend("This is a multi-part message in MIME format.\n");
        $smtp->datasend("--boundary\n");
        $smtp->datasend("Content-type: text/html\n");
        $smtp->datasend("Content-Disposition: inline\n");
        $smtp->datasend("Content-Description: Nagios report\n");
        $smtp->datasend("$mailbody\n");
        $smtp->datasend("--boundary\n");
        $smtp->datasend("Content-type: text/plain\n");
        $smtp->datasend("Please read the attatchment\n");
        $smtp->datasend("--boundary--\n");


        $smtp->dataend();

        $smtp->quit;
}
