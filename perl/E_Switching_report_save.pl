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


#my ($gnats{database});
#if ( $#ARGV < 0 ) {
#        print "Usage: $0 [databaname]\n";
#        exit;
#} else {
#        $gnats_info{database}=$ARGV[0];
#}


my ($after_date, $before_date, $delta_date, $ERR);

my $today = UnixDate("today","%d-%b-%Y");
#my $today = UnixDate("today","%Y-%m-%d");
#my $after_date="01-Jan-2000";

$before_date = UnixDate("today","%d-%b-%Y");
$after_date = DateCalc("today","-7 days", \$ERR);
$after_date = UnixDate("$after_date","%d-%b-%Y");

#    $before_date = "01-Jan-2004";

my (%gnats, %report);
#$gnasts{database} = "E_Switching";
%gnats = (
          server     => "gnats-irva-3.broadcom.com",
          database   => "E_Switching",
          port       => "1530",
          user       => "gnats4",
          passwd     => "emsggn09",
          query_pr   => "/tools/bin/query-pr",
          gnats_root => "/tools/gnats/4.0",
          databases  => "/tools/gnats/4.0//etc/gnats/databases",
         );
chop($report{date} = `date`);
$report{dir}="$gnats{gnats_root}/www/htdocs/reports/$gnats{database}";
#my $report{file}="$gnats{gnats_root}/www/htdocs/reports/$gnats{database}/Samir_Sanghani_${today}.html";
$report{data_file}="$report{dir}/samir_sanghani_data_${today}.txt";
$report{file}="$report{dir}/samir_sanghani_data_${today}.html";
#my $notification="raytran@broadcom.com,$jennifer@broadcom.com;rajibb@broadcom.com,cttok@broadcom.com";
#my $notify_list="raytran\@broadcom.com,samsang\@broadcom.com";
my $notify_list="raytran\@broadcom.com";
my $notify = 1;

sub main {
    my ($today, $ERR,);
    tie my %query_result, "Tie::IxHash";
    my (%pr, %db, $my_date, %time_stamp);
    my (@all_cat_list, %cat_list);
    my (%mail,$message);
    my ($cat_key, $cat_value);
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
        print "ERROR - Can not locate source directory for database $gnats{database} in $gnats{root}/etc/g nats/databases. Please try again\n";
        exit 1;
    }

    my $all_cnt=0;
    my $open_cnt=0;
    my $closed_cnt=0;
    my $analyzed_cnt=0;
 #   open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"Firebolt\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\|%Q\|%Q\|%Q\" Number Category Synopsis Responsible State Priority Arrival-Date Last-Modified Closed-Date\' 2>&1 |") or die "Can't run query: $!\n";
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"Firebolt\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\|%Q\|%Q\|%Q\" Number Category Synopsis Responsible State Priority Arrival-Date Last-Modified Closed-Date\' -a $after_date -b $before_date 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        $all_cnt++;
        push(@first_query,$_);
        ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority},$pr{arrival_date},$pr{last_modified},$pr{closed_date} ) = split(/\|/);
        $query_result{$pr{no}}{number} = $pr{no};
        $query_result{$pr{no}}{category} = $pr{catgory};
        $query_result{$pr{no}}{synopsis} = $pr{synopsis};
        $query_result{$pr{no}}{responsible} = $pr{responsible};
        $query_result{$pr{no}}{state} = $pr{state};
        $query_result{$pr{no}}{priority} = $pr{priority};
        $query_result{$pr{no}}{arrival_date} = $pr{arrival_date};
        $query_result{$pr{no}}{last_modified} = $pr{last_modified};
        $query_result{$pr{no}}{closed_date} = $pr{closed_date};
        push(@all_cat_list,$pr{category});
        if ($query_result{$pr{no}}{state} = "open") {
            $open_cnt++;
        } 
        if ($query_result{$pr{no}}{state} = "closed") {
            $closed_cnt++;
        } 
        if ($query_result{$pr{no}}{state} = "analyzed") {
            $analyzed_cnt++;
        } 
        $cat_list{$pr{category}}++;
    }
    close(QUERY);

    while(($cat_key,$cat_value) = each(%cat_list)) {
    }

#print Dumper(\%query_result);
#print Dumper(\%cnt_cat);

# Create HTML report page
    open(HTMLPAGE,">$report{file}") or die "Can't open report file $report{file}: $!\n";
    print "Creating report page\n";
    print HTMLPAGE "
    <HTML>
    <HEAD>
    <META HTTP-equiv=\"Content-Type\" content=\"text/html; charset=windows-1252\">
    <META name=\"Description\" content=\"Broadcom GNATS PR Report for $gnats{database}\">
    <META name=\"Broadcom, GNATS\" content=\"Broadcom GNATS PR Report for $gnats{database}\">
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
      <TR><TD><H1><P ALIGN=CENTER>GNATS PRs Report for $pr{database} $report{date} for all Firebolt</P></H1></TD></TR>
      <TR><TD>Total number of ticket - $all_cnt</TR></TD>
      <TR><TD>Total number of tickets in open state - $open_cnt</TR></TD>
      <TR><TD>Total number of ticket in analyzed state - $closed_cnt</TR></TD>
      <TR><TD>Total number of closed ticket - $closed_cnt</TR></TD>
      <TR><TD><TABLE BORDER=1 CELLSPACING=3>
        <TR BGCOLOR=\"CCCCCC\"><TD NOWRAP>Category</TD><TD>Number of PRs</TD></TR>
    ";
      foreach $cat_key (keys %cat_list) {
          $cat_value = $cat_list{$cat_key};
          print HTMLPAGE "<TR><TD>$cat_key</TD><TD>$cat_value</TD></TR>";
      }
      print HTMLPAGE "    
        </TABLE></TD></TD>
      <TR><TD><TABLE BORDER=1 CELLSPACING=3>
        <TR><TD BGCOLOR=\"CCCCCC\">All PRs that are in open state for Firebolt<BR></TD></TR>
        <TR BGCOLOR=\"CCCCCC\"><TD NOWRAP>PR Number</TD><TD>Category</TD><TD>Synopsis</TD><TD NOWRAP>Responsible</TD><TD>State</TD><TD>Priority</TD><TD NOWRAP>Arrival Date</TD><TD NOWRAP>Last Modified</TD></TR>
    ";
    foreach $cat_key (keys %query_result) {
        if ($query_result{$cat_key}{state} eq "open") {
            print HTMLPAGE "<TR><TD>$query_result{$cat_key}</TD><TD>$query_result{$cat_key}{category}</TD><TD>$query_result{$cat_key}{synopsis}</TD><TD>$query_result{$cat_key}{responsible}</TD><TD>$query_result{$cat_key}{state}</TD><TD>$query_result{$cat_key}{priority}</TD><TD>$query_result{$cat_key}{arrival_date}</TD><TD>$query_result{$cat_key}{last_modified}</TD></TR>";
        }
    }
      print HTMLPAGE "    
        </TABLE></TR></TD>
      <TR><TD><TABLE BORDER=1 CELLSPACING=3>
       <TR><TD>$pr{no}</TD><TD>$pr{synopsis}</TD><TD>$pr{responsible}</TD><TD>$pr{state}</TD><TD>$pr{priority}</TD><TD>$pr{arrival_date}</TD><TD>$pr{last_modified}</TD>
        </TD></TD></TABLE>
        <TR><TD><BR></TD></TR>
        <TR><TD BGCOLOR=\"CCCCCC\">All PRs that are in analyzed state for Firebolt<BR></TD></TR>
        <TR><TD><TABLE BORDER=1 CELLSPACING=3>
        <TR BGCOLOR=\"CCCCCC\"><TD NOWRAP>PR Number</TD><TD>Synopsis</TD><TD NOWRAP>Responsible</TD><TD>State</TD><TD>Priority</TD><TD NOWRAP>Arrival Date</TD><TD NOWRAP>Last Modified</TD></TR>
    ";
    foreach $cat_key (keys %query_result) {
        if ($query_result{$cat_key}{state} eq "analyzed") {
            print HTMLPAGE "<TR><TD>$query_result{$cat_key}</TD><TD>$query_result{$cat_key}{category}</TD><TD>$query_result{$cat_key}{synopsis}</TD><TD>$query_result{$cat_key}{responsible}</TD><TD>$query_result{$cat_key}{state}</TD><TD>$query_result{$cat_key}{priority}</TD><TD>$query_result{$cat_key}{arrival_date}</TD><TD>$query_result{$cat_key}{last_modified}</TD></TR>";
        }
    }
      print HTMLPAGE "    
        </TABLE></TR></TD>
      <TR><TD><TABLE BORDER=1 CELLSPACING=3>
       <TR><TD>$pr{no}</TD><TD>$pr{synopsis}</TD><TD>$pr{responsible}</TD><TD>$pr{state}</TD><TD>$pr{priority}</TD><TD>$pr{arrival_date}</TD><TD>$pr{last_modified}</TD>
        </TD></TD></TABLE>
        <TR><TD><BR></TD></TR>
        <TR><TD BGCOLOR=\"CCCCCC\">All PRs that are are closed for Firebolt<BR></TD></TR>
        <TR><TD><TABLE BORDER=1 CELLSPACING=3>
        <TR BGCOLOR=\"CCCCCC\"><TD NOWRAP>PR Number</TD><TD>Synopsis</TD><TD NOWRAP>Responsible</TD><TD>State</TD><TD>Priority</TD><TD NOWRAP>Arrival Date</TD><TD NOWRAP>Last Modified</TD><TD NOWRAP>Closed Date</TD></TR>
    ";
    foreach $cat_key (keys %query_result) {
        if ($query_result{$cat_key}{state} eq "closed") {
            print HTMLPAGE "<TR><TD>$query_result{$cat_key}</TD><TD>$query_result{$cat_key}{category}</TD><TD>$query_result{$cat_key}{synopsis}</TD><TD>$query_result{$cat_key}{responsible}</TD><TD>$query_result{$cat_key}{state}</TD><TD>$query_result{$cat_key}{priority}</TD><TD>$query_result{$cat_key}{arrival_date}</TD><TD>$query_result{$cat_key}{last_modified}</TD><TD>$query_result{$cat_key}{closed_date}</TD></TR>";
        }
    }
    print HTMLPAGE "
        </TABLE>
        </TD></TR>
        </TABLE>
        </BODY>
        </HTML>
    ";
    close(HTMLPAGE);
    if ($notify) {
         system("mailx -s \"E_Switching Report for Samir Sanghani $report{date}\" $notify_list < $report{file}");
         print "Email sent\n";
    }

}

main;
