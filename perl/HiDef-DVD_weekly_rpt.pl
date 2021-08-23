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

my (%gnats, %report,%date);
%gnats = (
          database   => "HiDef-DVD",
          server     => "gnatsweb.broadcom.com",
          port       => "1530",
          user       => "gnats4",
          passwd     => "emsggn09",
          query_pr   => "/tools/bin/query-pr",
          gnats_root => "/tools/gnats/4.0",
         );

$gnats{databases}  = "$gnats{gnats_root}/etc/gnats/databases";

chop($report{date} = `date`);
$date{today} = UnixDate("today","%d-%b-%Y");
$date{date} = UnixDate("today","%d");
$date{month} = UnixDate("today","%b");
$date{year} = UnixDate("today","%Y");
$report{dir}="$gnats{gnats_root}/www/htdocs/reports/$gnats{database}/weekly/$date{year}/$date{month}";
$report{file}="$report{dir}/$gnats{database}_$date{today}.html";
$report{web_link} = "http\:\/\/gnatsweb.broadcom.com\/reports/$gnats{database}\/weekly\/\/$date{year}\/$date{month}\/$gnats{database}_$date{today}.html";

my $notification_admin="raytran\@broadcom.com";
my $notification;
my $notify_all = 1;
my $notify_admin = 1;
my $create_report = 1;
my $create_html = 0;
my $debug = 0;
my (%mail,$message,$mail_subject);

sub main {
    my ($ERR,$cat,@found_prs,$state,$pr);
    my (%query_result, %date);
    my (%pr, %my_date, $delta_date, %converted_date);
    my (%responsible, $responsible_person, $responsible_pr_number);
    my (@first_query,@second_query);

    if (! -d "$report{dir}") {
        umask 0000;
        mkdir  $report{dir}, 0775;
    }

    my $db = Net::Gnats->new("$gnats{server}",$gnats{port});
    if ( $db->connect() ) {
        print "Connecting...\n";
        $db->login("$gnats{database}","$gnats{user}","$gnats{passwd}");
    } else {
        print "can not connect\n";
        exit;
    }

    $date{after}="01-Jun-2001";
    $date{before} = UnixDate("today","%d-%b-%Y");
    if ($debug) {
        print "date is $date{before}\n";
    }

# Get a list of categories and states

    my @categories = getCategory($db);
    my @states = getStates($db);

# for each categories, take a count of how many tickets are in each state

    foreach $cat (@categories) {
        foreach $state (@states) {
            @found_prs = ();
            @found_prs = $db->query("Category~\"$cat\"", "State=\"$state\""); 
            foreach $pr (@found_prs) {
                $query_result{$cat}{$state}++;
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

sub getCategory {
  my $db = shift;
  my @category = $db->listCategories();

# This section creates a hash of the categories
#  my %CATEGORY;
#  foreach my $href (@category) {
#   $CATEGORY{"$href->{name}"}{desc} = $href->{desc};
#   $CATEGORY{"$href->{name}"}{resp} = $href->{contact};
# }
#  return %CATEGORY;

# This section creates an array of the category names
  my @CATEGORY;
  foreach my $href (@category) {
    push(@CATEGORY,$href->{name});
  }
  return @CATEGORY;
}

sub getStates {
  my $db = shift;
  my @state = $db->listStates();
  my %STATE;
  foreach my $href (@state) {
    $STATE{"$href->{name}"}{desc} = $href->{desc};
  }
  return %STATE;
}

main;
