#!/tools/perl/5.6.0/SunOS/bin/perl

use Data::Dumper;
use IO::File;
use File::Basename;
use Date::Manip;
use File::stat;
use File::Basename;
use Mail::Sendmail;
use Net::Gnats;
use Tie::IxHash;
use strict;


my (%gnats, %report);
%gnats = (
          database   => "DigitalVideo",
          server     => "gnats-irva-3.broadcom.com",
          port       => "1530",
          user       => "gnats4",
          passwd     => "emsggn09",
          query_pr   => "/tools/bin/query-pr",
          gnats_root => "/tools/gnats/4.0",
         );

$gnats{databases}  = "$gnats{gnats_root}/etc/gnats/databases";

chop($report{date} = `date`);
my $today = UnixDate("today","%d-%b-%Y");
$report{dir}="$gnats{gnats_root}/www/htdocs/reports/$gnats{database}/weekly";
$report{file}="$report{dir}/DigitalVideo_Software_Interlock_report_${today}.html";
$report{web_link} = "http\:\/\/gnats-irva-3.broadcom.com\/reports/$gnats{database}\/weekly\/DigitalVideo_Software_Interlock_report_${today}.html";

#my $notification_admin="clearcase-bse-admin-list\@broadcom.com,sjeck\@broadcom.com,rajibb\@broadcom.com,erikg\@broadcom.com,lseverin\@broadcom.com,atrerise\@broadcom.com,shuang\@broadcom.com,marcusk\@broadcom.com,jasonh\@broadcom.com,dlwin\@broadcom.com,kannan.a\@broadcom.com,fassl\@broadcom.com,pchen\@broadcom.com ";
my $notification_admin="raytran\@broadcom.com";
my $notification;
my $notify_all = 1;
my $notify_admin = 1;
my $create_report = 1;
my $create_html = 1;
my $debug = 0;
my (%mail,$message,$mail_subject);

sub main {
    my ($ERR,);
    my (%db, %query_result, %date);
    my (%pr, %my_date, $delta_date, %converted_date);
    my (%responsible, $responsible_person, $responsible_pr_number);
    my (@first_query,@second_query);
    print "Verifying database $gnats{database}\n";
    my $found = 0;
    open(DBFILE, "$gnats{databases}") or die "Can't open database file: $!\n";
    while(<DBFILE>) {
            chop($_);
            next if /^#/;
            ($db{name},$db{desc},$db{dir}) = split(/:/);
            if ( $gnats{database} =~ /$db{name}/ ) {
                print "$db{name} found. Directory $db{dir}\n";
                $found = 1;
                if (! -d "$report{dir}") {
                    mkdir("$report{dir}", 0777);
                }
                last;
            }
    }

    if ( $found == 0 ) {
        print "ERROR - Can not locate source directory for database $gnats{database} in $gnats{gnats_root}/etc/gnats/databases. Please try again\n";
        exit 1;
    }

    $date{after}="01-Jun-2001";
#    $date{before} = UnixDate("today","%d-%b-%Y");
#    $date{before} = DateCalc("today","-14 days",\$ERR);
#    $date{before} = UnixDate("$date{before}","%d-%b-%Y");
    $date{before} = UnixDate("today","%d-%b-%Y");
    if ($debug) {
        print "date is $date{before}\n";
    }

# running query
    print "Running query\n";
#    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|eval\|insufficient_info\" \& Priority==\"high\" !(Responsible==gnats4-admin-dvt)\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\|%s\|\%s\|\%Q\" Number Category Synopsis Severity Priority Responsible Originator State Arrival-Date\' -B $date{before} 2>&1 |") or die "Can't run query: $!\n";
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|eval\|insufficient_info\" \& Priority=\"high\" \& Category~\"\.\*Software\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\|%s\|\%s\|\%Q\" Number Category Synopsis Severity Priority Responsible Originator State Arrival-Date\' 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        push(@first_query,$_);
        chop;
        ($pr{no},$pr{category},$pr{synopsis},$pr{severity},$pr{priority},$pr{responsible},$pr{originator},$pr{state},$pr{arrival_date})= split(/\|/);
           $responsible{$pr{responsible}}{$pr{no}}{category} = $pr{category};
           $responsible{$pr{responsible}}{$pr{no}}{synopsis} = $pr{synopsis};
           $responsible{$pr{responsible}}{$pr{no}}{severity} = $pr{severity};
           $responsible{$pr{responsible}}{$pr{no}}{state} = $pr{state};
           $responsible{$pr{responsible}}{$pr{no}}{priority} = $pr{priority};
           $responsible{$pr{responsible}}{$pr{no}}{originator} = $pr{originator};
           $responsible{$pr{responsible}}{$pr{no}}{arrival_date} = $pr{arrival_date};
           $responsible{$pr{responsible}}{$pr{no}}{last_modified} = $pr{last_modified};
#        }
    }
    close(QUERY);

    if ($debug) {
#        print Dumper(\%responsible);
         foreach $responsible_person (keys %responsible) {
            foreach $responsible_pr_number ( sort keys %{ $responsible{$responsible_person} } ) {
                    print "$responsible_pr_number=$responsible{$responsible_person}{$responsible_pr_number}{category}\n";
            } 

         }
    }

# Create HTML report page
    if ($create_html) {
        open(HTMLPAGE,">$report{file}") or die "Can't open report file $report{file}: $!\n";
        print HTMLPAGE "
        <HTML>
        <HEAD>
        <META HTTP-equiv=\"Content-Type\" content=\"text/html; charset=windows-1252\">
        <META name=\"Description\" content=\"Software Interlock Report for $gnats{database}\">
        <META name=\"Broadcom, GNATS\" content=\"Software Interlock Report for $gnats{database}\">
        <STYLE>
        body{font-family:Verdana,Arial,Helvetica,Sans-serif;font-size:12px;}
        td{font-family:Verdana,Arial,Helvetica,Sans-serif;font-size:12px;}
        h1{font-family:Verndana,Arial,Helvetica,Sans-serif;font-size:17px;}
        a {text-decoration:none;}
        blockquote {font-family:courier}
        a:hover {text-decoration:underline}
        input{font-family : Verdana,Arial,Helvetica,Sans-serif;font-size:12px;
        color:#000000;width : 90px;}
        </STYLE>
        </HEAD>
        <BODY>
        <TABLE ALIGN=\"left\" BORDER=0 CELLSPACING=3 WIDTH=1000>
          <TR><TD><H1><P ALIGN=CENTER>GNATS Software Interlock Report for $gnats{database} $report{date}</P></H1></TD></TR>
          <TR><TD><TABLE BORDER=1 CELLSPACING=3>
            <TR BGCOLOR=\"CCCCCC\"><TD NOWRAP>PR Number</TD><TD NOWRAP>Category</TD><TD NOWRAP>Synopsis</TD><TD NOWRAP>Severity</TD><TD NOWRAP>Priority</TD><TD NOWRAP>Responsible</TD><TD NOWRAP>State</TD><TD>Arrival-Date</TD><TD NOWRAP>Originator</TD></TR>
        ";
         foreach $responsible_person (keys %responsible) {
            foreach $responsible_pr_number ( sort keys %{ $responsible{$responsible_person} } ) {
                print HTMLPAGE "<TR><TD>$responsible_pr_number</TD><TD>$responsible{$responsible_person}{$responsible_pr_number}{category}</TD><TD>$responsible{$responsible_person}{$responsible_pr_number}{synopsis}</TD><TD>$responsible{$responsible_person}{$responsible_pr_number}{severity}</TD><TD>$responsible{$responsible_person}{$responsible_pr_number}{priority}</TD><TD>$responsible_person</TD><TD>$responsible{$responsible_person}{$responsible_pr_number}{state}</TD><TD>$responsible{$responsible_person}{$responsible_pr_number}{arrival_date}</TD><TD>$responsible{$responsible_person}{$responsible_pr_number}{originator}</TD>\n";
            }
        }
    
        print HTMLPAGE "
            </TD></TR></TABLE>
            </TD></TR>
            </TABLE>
            </BODY>
            </HTML>
        ";
        close(HTMLPAGE);
    }
    if ($notify_admin) {
        $message .= "Please find the link location for the report here\n";
        $message .= "$report{web_link}\n";
        &Notify("$notification_admin","GNATS Software Interlock Report for $gnats{database} $report{date}","$message");
        undef $message;
    }

    if ($notify_all) {
        foreach $responsible_person (keys %responsible) {
            $notification = "$responsible_person\@broadcom.com";
#            $notification = "raytran\@broadcom.com";
            $mail_subject = "Software Interlock Meeting Notice";
            $message .= "This is an automated notification message - Please do not reply.\n";
            $message .= "This message is to inform you of an upcoming Software Interlock Meeting.\n\n";
            $message .= "Monday 8:00 AM PST\n";
            $message .= "Meeting Place ID: 7001\n\n";
            $message .= "You currently have the following software related issue(s) assigned to you.\n";
            $message .= "Please be prepared to provide status during the meeting.  If you are unable\n";
            $message .= "to attend, please update your manager (or other designee) on the status of\n";
            $message .= "your issue(s) and send him/her in your place.\n\n\n";

            foreach $responsible_pr_number ( sort keys %{ $responsible{$responsible_person} } ) {
                   $message .= "PR no. $responsible_pr_number, Category $responsible{$responsible_person}{$responsible_pr_number}{category}\n"; 
                   $message .= "  Synopsis $responsible{$responsible_person}{$responsible_pr_number}{synopsis}\n";
                   $message .= "  Severity $responsible{$responsible_person}{$responsible_pr_number}{severity}, Priority $responsible{$responsible_person}{$responsible_pr_number}{priority}, State $responsible{$responsible_person}{$responsible_pr_number}{state}\n";
                   $message .= "  Arrival-Date $responsible{$responsible_person}{$responsible_pr_number}{arrival_date}, Originator $responsible{$responsible_person}{$responsible_pr_number}{originator}\n";
                   $message .= "-------------------------------------------------\n";
            }
            &Notify("$notification","$mail_subject","$message");
            undef $message;
        }
    }

}

sub Notify {
    my ($MySentTo,$MySubject,$MyMessage) = @_;
    my %mail = (
            smtp    => 'smtphost.broadcom.com',
            to      => $MySentTo,
            from    => 'gnats4@broadcom.com',
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


main;
