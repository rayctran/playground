#!/tools/perl/5.6.0/SunOS/bin/perl

use Data::Dumper;
use IO::File;
use File::Basename;
use Date::Manip;
use File::stat;
use File::Basename;
use Mail::Sendmail;
use Net::Gnats;
use strict;


#my ($database);
#if ( $#ARGV < 0 ) {
#        print "Usage: $0 [databaname]\n";
#        exit;
#} else {
#        $database=$ARGV[0];
#}

my (%gnats);

my $database = "BSE_SQA";
my $server = "gnats-irva-3.broadcom.com";
my $port = "1530";
my $user = "gnats4";
my $passwd = "emsggn09";
my $query_pr="/tools/bin/query-pr";
my $gnats_root="/tools/gnats/4.0";
my $databases="${gnats_root}/etc/gnats/databases";
chop(my $report_date = `date`);
my $report_dir="${gnats_root}/www/htdocs/reports/${database}";
#my $report_file="${gnats_root}/www/htdocs/reports/${database}/outstanding_PRs_${today}.html";
my $report_file="${report_dir}/outstanding_PRs_opened_before_06-01-2004.html";
#my $notification="raytran@broadcom.com,$jennifer@broadcom.com;rajibb@broadcom.com,cttok@broadcom.com";
#my $notification="raytran\@broadcom.com";
my $notify = 0;

sub main {
    my ($today, $ERR,);
    my ($db_name, $db_desc, $db_dir, %query_result);
    my ($after_date, $before_date);
    my ($pr,$synopsis,$responsible,$state,$priority,$arrival_date,$last_modified);
    my ($delta_date,$year,$month,$week,$day,$hr,$min,$sec);
    my (%mail,$message);
    my (@first_query,@second_query);
    print "Verifying database $database\n";
    my $found = 0;
    open(DBFILE, "$databases") or die "Can't open database file: $!\n";
    while(<DBFILE>) {
            chop($_);
            next if /^#/;
            ($db_name,$db_desc,$db_dir) = split(/:/);
            if ( $database =~ /$db_name/ ) {
                print "$db_name found. Directory $db_dir\n";
                $found = 1;
                if (! -d "$report_dir") {
                    mkdir("$report_dir", 0777);
                }
                last;
            }
    }

    if ( $found == 0 ) {
        print "ERROR - Can not locate source directory for database $database in ${gnats_root}/etc/g
nats/databases. Please try again\n";
        exit 1;
    }

    $today = UnixDate("today","%d-%b-%Y");

    $after_date="01-June-2001";
#    $after_date = DateCalc("today","-365 days", \$ERR);

     $before_date = UnixDate("today","%d-%b-%Y");
#    $before_date = "01-Jan-2004";

# Queries 
# First Report
# All High Priority Issues in Open/Eval state not modified within 2 days
    open(QUERY,"$query_pr -d $database -v $user -w $passwd --expr \'State\~\"open\|eval\" \& Priority==\"high\" \& Category==\"BCM7038_Software\"\' --format \'\"%s,%s,%s,%Q,%Q,%Q\" Number Synopsis Responsible Arrival-Date Last-Modified\' -a $after_date 2>&1 |") or die "Can't run query: $!\n";
#    open(QUERY,"$query_pr -d $database -v $user -w $passwd --expr \'State\~\"open\|eval\" & Category==\"BCM7038_Software\"\' --format \'\"%s,%s,%s,%s,%s,%Q,%Q,%Q\" Number Synopsis Responsible State Priority Arrival-Date Last-Modified\' -b $before_date 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        push(@first_query,$_);
        ($pr,$synopsis,$responsible,$state,$priority,$arrival_date,$last_modified) = split(/,/);
        $query_result = {
                        $pr            => $pr, 
                        $responsible   => $responsible, 
                        $state         => $state, 
                        $priority      => $priority, 
                        $arrival-date  => $arrival-date, 
                        $last-modified => $last-modifed, 
                         };
    }
    close(QUERY);

#    $after_date = "01-Jan-2004";
#    $before_date = "31-Mar-2004";
    open(QUERY,"$query_pr -d $database -v $user -w $passwd --expr \'State\~\"open\|eval\" & Category==\"BCM7038_Software\"\' --format \'\"%s,%s,%s,%s,%s,%Q,%Q,%Q\" Number Synopsis Responsible State Priority Arrival-Date Last-Modified\' -b $before_date -a $after_date 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        push(@second_query,$_);
    }
    close(QUERY);
# Create HTML report page
    open(HTMLPAGE,">$report_file") or die "Can't open report file $report_file: $!\n";
    print HTMLPAGE "
    <HTML>
    <HEAD>
    <META HTTP-equiv=\"Content-Type\" content=\"text/html; charset=windows-1252\">
    <META name=\"Description\" content=\"Broadcom GNATS Outstanding PR Report for $database\">
    <META name=\"Broadcom, GNATS\" content=\"Broadcom GNATS Outstanding PR Report for $database\">
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
      <TR><TD><H1><P ALIGN=CENTER>GNATS Outstanding PRs Report for $database $report_date</P></H1></TD></TR>
      <TR><TD BGCOLOR=\"CCCCCC\">Problem Report opened before January 01, 2004 that is still open\/eval state<BR></TD></TR>
      <TR><TD><TABLE BORDER=1 CELLSPACING=3>
        <TR BGCOLOR=\"CCCCCC\"><TD NOWRAP>PR Number</TD><TD>Synopsis</TD><TD NOWRAP>Responsible</TD><TD>State</TD><TD>Priority</TD><TD NOWRAP>Arrival Date</TD><TD NOWRAP>Last Modified</TD></TR>
    ";

    foreach my $line (sort { $a <=> $b } @first_query) {
        ($pr,$synopsis,$responsible,$state,$priority,$arrival_date,$last_modified)=split(/,/,$line); 
        if ( $last_modified == " " ) {
#            $last_modified = $arrival_date;
            $last_modified = "NA";
            next;
        } else {
            $delta_date = &DateCalc($last_modified,$today,\$ERR,1);
            ($year,$month,$week,$day,$hr,$min,$sec) = split (/:/, $delta_date);
        }
        if ($month > 0) {
            $message .= "PR $pr has not been modified for $month months $week week and $day days. Responsible person is $responsible\n";
        } elsif ($week > 2) {
            $message .= "PR $pr has not been modified for $week week and $day days. Responsible person is $responsible\n";
        } elsif ( ($week == 0) && ($day > 2) ) {
            $message .= "PR $pr has not been modified for $day days. Responsible person is $responsible\n";
        }
        print HTMLPAGE "<TR><TD>$pr</TD><TD>$synopsis</TD><TD>$responsible</TD><TD>$state</TD><TD>$priority</TD><TD>$arrival_date</TD><TD>$last_modified</TD>";
    }

    print HTMLPAGE"
        </TD></TD></TABLE>
        <TR><TD><BR></TD></TR>
        <TR><TD BGCOLOR=\"CCCCCC\">Problem Report opened between January 01,2004 and March 31, 2004 that is still in open\/eval state<BR></TD></TR>
        <TR><TD><TABLE BORDER=1 CELLSPACING=3>
        <TR BGCOLOR=\"CCCCCC\"><TD NOWRAP>PR Number</TD><TD>Synopsis</TD><TD NOWRAP>Responsible</TD><TD>State</TD><TD>Priority</TD><TD NOWRAP>Arrival Date</TD><TD NOWRAP>Last Modified</TD></TR>
        
    ";
    foreach my $line (sort { $a <=> $b } @second_query) {
        ($pr,$synopsis,$responsible,$state,$priority,$arrival_date,$last_modified)=split(/,/, $line); 
        if ( $last_modified == " " ) {
            $last_modified = "NA";
        }
        print HTMLPAGE "<TR><TD>$pr</TD><TD>$synopsis</TD><TD>$responsible</TD><TD>$state</TD><TD>$priority</TD><TD>$arrival_date</TD><TD>$last_modified</TD>";

    }
    print HTMLPAGE "
        </TD></TR></TABLE>
        </TD></TR>
        </TABLE>
        </BODY>
        </HTML>
    ";
    close(HTMLPAGE);
    if ($notify) {
        &Notify("$notification","Test Report run on State=open/eval Priority=high and haven't been modified in 2 days ","$message");
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
