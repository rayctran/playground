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
$gnats{category}  = "BCM7038_Software";

chop($report{date} = `date`);
my $today = UnixDate("today","%d-%b-%Y");
$report{dir}="$gnats{gnats_root}/www/htdocs/reports/$gnats{database}/weekly";
$report{file}="$report{dir}/$gnats{category}_${today}.html";
$report{web_link} = "http\:\/\/gnats-irva-3.broadcom.com\/reports/$gnats{database}\/weekly\/$gnats{category}_${today}.html";

my $notification_admin="clearcase-bse-admin-list\@broadcom.com,sjeck\@broadcom.com,rajibb\@broadcom.com,erikg\@broadcom.com,lseverin\@broadcom.com,atrerise\@broadcom.com,shuang\@broadcom.com,marcusk\@broadcom.com,jasonh\@broadcom.com,dlwin\@broadcom.com,kannan.a\@broadcom.com,fassl\@broadcom.com,pchen\@broadcom.com ";
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
    $date{before} = DateCalc("today","-14 days",\$ERR);
    $date{before} = UnixDate("$date{before}","%d-%b-%Y");
    if ($debug) {
        print "before $date{before}, $date{after}, $date{two_weeks_ago}\n";
    }

# running query
    print "Running query\n";
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|eval\" \& Priority==\"high\" \& Category==\"$gnats{category}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|\%Q\|\%Q\" Number Synopsis Responsible Priority State Arrival-Date Last-Modified\' -M $date{after} -B $date{before} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        push(@first_query,$_);
        ($pr{no},$pr{synopsis},$pr{responsible},$pr{priority},$pr{state},$pr{arrival_date},$pr{last_modified}) = split(/\|/);
        if ($debug) {
#            print $_;
#           print "PR $pr{no}, created on $pr{arrival_date}, last modified date is $pr{last_modified}\n";
        }
           $responsible{$pr{responsible}}{$pr{no}}{synopsis} = $pr{synopsis};
           $responsible{$pr{responsible}}{$pr{no}}{state} = $pr{state};
           $responsible{$pr{responsible}}{$pr{no}}{priority} = $pr{priority};
           $responsible{$pr{responsible}}{$pr{no}}{arrival_date} = $pr{arrival_date};
           $responsible{$pr{responsible}}{$pr{no}}{last_modified} = $pr{last_modified};
#        }
    }
    close(QUERY);

    if ($debug) {
#        print Dumper(\%responsible);
         foreach $responsible_person (keys %responsible) {
            foreach $responsible_pr_number ( sort keys %{ $responsible{$responsible_person} } ) {
                    print "$responsible_pr_number=$responsible{$responsible_person}{$responsible_pr_number}{state}\n";
            } 

         }
#        while (($responsible_person, $responsible_pr_number) = each(%responsible)) { 
#             print "$responsible{$responsible_person}{$responsible_pr_number}{state}\n";
#        }
    }
# Create HTML report page
    if ($create_html) {
        open(HTMLPAGE,">$report{file}") or die "Can't open report file $report{file}: $!\n";
        print HTMLPAGE "
        <HTML>
        <HEAD>
        <META HTTP-equiv=\"Content-Type\" content=\"text/html; charset=windows-1252\">
        <META name=\"Description\" content=\"Broadcom GNATS Outstanding PR Report for $gnats{database}\">
        <META name=\"Broadcom, GNATS\" content=\"Broadcom GNATS Outstanding PR Report for $gnats{database}\">
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
          <TR><TD><H1><P ALIGN=CENTER>GNATS Outstanding PRs Report for $gnats{database} Category $gnats{category} $report{date}</P></H1></TD></TR>
          <TR><TD BGCOLOR=\"CCCCCC\">Problem Report for not modified in two weeks<BR></TD></TR>
          <TR><TD><TABLE BORDER=1 CELLSPACING=3>
            <TR BGCOLOR=\"CCCCCC\"><TD NOWRAP>Responsible Person</TD><TD NOWRAP>PR Number</TD><TD>Synopsis</TD><TD>State</TD><TD>Priority</TD><TD NOWRAP>Arrival Date</TD><TD NOWRAP>Last Modified</TD></TR>
        ";
         foreach $responsible_person (keys %responsible) {
            foreach $responsible_pr_number ( sort keys %{ $responsible{$responsible_person} } ) {
                print HTMLPAGE "<TR><TD>$responsible_person</TD><TD>$responsible_pr_number</TD><TD>$responsible{$responsible_person}{$responsible_pr_number}{synopsis}</TD><TD>$responsible{$responsible_person}{$responsible_pr_number}{state}</TD><TD>$responsible{$responsible_person}{$responsible_pr_number}{priority}</TD><TD NOWRAP>$responsible{$responsible_person}{$responsible_pr_number}{arrival_date}</TD><TD NOWRAP>$responsible{$responsible_person}{$responsible_pr_number}{last_modified}</TD>\n";
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
        &Notify("$notification_admin","GNATS $gnats{database} Report State=open/eval haven't been modified in 2 weeks for category $gnats{category} ","$message");
    }

    if ($notify_all) {
        foreach $responsible_person (keys %responsible) {
            $notification = "$responsible_person\@broadcom.com";
            $mail_subject = "GNATS $gnats{database} Report State=open/eval haven't been modified in 2 weeks for category $gnats{category}";
            $message .= "Please do not reply to the following message. It was generated by an automated messaging system\n";
            $message .= "Please review the GNATS DigitalVideo ticktet that have not been modified in the past two weeks.\n";
            $message .= "If an issue has been resolved, please move it to the closed state\n";
            $message .= "Thank-you\n";
            foreach $responsible_pr_number ( sort keys %{ $responsible{$responsible_person} } ) {
                   $message .= "PR number $responsible_pr_number, Synopsis $responsible{$responsible_person}{$responsible_pr_number}{synopsis}\n";
            }
            &Notify("$notification","$mail_subject","$message");
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
