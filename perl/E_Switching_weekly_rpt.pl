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

$before_date = UnixDate("today","%d-%b-%Y");
$after_date = DateCalc("today","-7 days", \$ERR);
$after_date = UnixDate("$after_date","%d-%b-%Y");

    $before_date = "24-Oct-2004";

print "before $before_date, after $after_date\n";

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
          databases  => "/tools/gnats/4.0/etc/gnats/databases",
         );
chop($report{date} = `date`);
$report{dir}="$gnats{gnats_root}/www/htdocs/reports/$gnats{database}";
$report{data_file}="$report{dir}/weekly/firebolt_${today}.txt";
$report{file}="$report{dir}/weekly/firebolt_${today}.html";
$report{web_link} = "http\:\/\/gnats-irva-3.broadcom.com\/reports/$gnats{database}\/weekly\/firebolt_${today}.html";
#my $notify_list="raytran\@broadcom.com,samsang\@broadcom.com";
my $notify_list="raytran\@broadcom.com";
my $notify = 1;

sub main {
    tie my %query_result, "Tie::IxHash";
    my (%pr, %db, $my_date, %time_stamp);
    my (@all_cat_list, %cat_list);
    my (@open_query,@mod_query,@closed_query);
    my (%open_cat,%mod_cat,%closed_cat);
    my (%open_2nd_level_cat,%mod_2nd_level_cat,%closed_2nd_level_cat);
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
    my $mod_cnt=0;

# Opened within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"Firebolt\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -a $after_date -b $before_date 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $open_cnt++;
            push(@open_query,$_);
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $open_cat{$pr{category}}++;
            if ( $pr{category} =~ /(Firebolt-\w+)-\w+/ ) {
                $open_2nd_level_cat{$1}++;
            }
        } else {
            print "no PRs matched\n";
        }
    }
    close(QUERY);

# Modified within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"Firebolt\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -M $after_date -B $before_date 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $mod_cnt++;
            push(@mod_query,$_);
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $mod_cat{$pr{category}}++;
            if ( $pr{category} =~ /(Firebolt-\w+)-\w+/ ) {
                $mod_2nd_level_cat{$1}++;
            }
        } else {
            print "no PRs matched\n";
        }
    }
    close(QUERY);

# Closed within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"Firebolt\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -Z $after_date -z $before_date 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $closed_cnt++;
            push(@closed_query,$_);
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $closed_cat{$pr{category}}++;
            if ( $pr{category} =~ /(Firebolt-\w+)-\w+/ ) {
                $closed_2nd_level_cat{$1}++;
            }
        } else {
            print "no PRs matched\n";
        }
    }

#print Dumper(\%open_cat);
#print Dumper(\%mod_cat);
#print Dumper(\%closed_cat);
print Dumper(\%open_2nd_level_cat);
print Dumper(\%mod_2nd_level_cat);
print Dumper(\%closed_2nd_level_cat);
exit;

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
      <TR><TD><H1><P ALIGN=CENTER>GNATS PRs Report for $pr{database} all Firebolt catgories for the week of $after_date to $before_date</P></H1></TD></TR>
      <TR><TD>Total number of tickets that was opened - $open_cnt</TR></TD>
      <TR><TD>Total number of tickets that was modified - $closed_cnt</TR></TD>
      <TR><TD>Total number of tickets that was closed - $closed_cnt</TR></TD>
      <TR><TD BGCOLOR=\"CCCCCC\">All PRs opened during time window: $after_date - $before_date<BR></TD></TR>
      <TR><TD><TABLE BORDER=1 CELLSPACING=3>
        <TR BGCOLOR=\"CCCCCC\"><TD NOWRAP>Category</TD><TD>Number of PRs</TD></TR>
    ";
      while (($cat_key, $cat_value) = each(%open_cat)) {
          print HTMLPAGE "<TR><TD>$cat_key</TD><TD>$cat_value</TD></TR>";
      }
      while (($cat_key, $cat_value) = each(%open_2nd_level_cat)) {
          print HTMLPAGE "<TR><TD BGCOLOR=\"CCCCCC\">Total $cat_key</TD><TD>$cat_value</TD></TR>";
      }
      print HTMLPAGE "    
        </TABLE></TD></TR>
      <TR><TD BGCOLOR=\"CCCCCC\">All PRs modified during time window: $after_date - $before_date<BR></TD></TR>
      <TR><TD><TABLE BORDER=1 CELLSPACING=3>
        <TR BGCOLOR=\"CCCCCC\"><TD NOWRAP>Category</TD><TD>Number of PRs</TD></TR>
    ";
      while (($cat_key, $cat_value) = each(%mod_cat)) {
          print HTMLPAGE "<TR><TD>$cat_key</TD><TD>$cat_value</TD></TR>";
      }
      while (($cat_key, $cat_value) = each(%mod_2nd_level_cat)) {
          print HTMLPAGE "<TR><TD BGCOLOR=\"CCCCCC\">Total $cat_key</TD><TD>$cat_value</TD></TR>";
      }
      print HTMLPAGE "    
        </TABLE></TD></TR>
      <TR><TD BGCOLOR=\"CCCCCC\">All PRs closed during time window: $after_date - $before_date<BR></TD></TR>
      <TR><TD><TABLE BORDER=1 CELLSPACING=3>
        <TR BGCOLOR=\"CCCCCC\"><TD NOWRAP>Category</TD><TD>Number of PRs</TD></TR>
    ";
      while (($cat_key, $cat_value) = each(%closed_cat)) {
          print HTMLPAGE "<TR><TD>$cat_key</TD><TD>$cat_value</TD></TR>";
      }
      while (($cat_key, $cat_value) = each(%closed_2nd_level_cat)) {
          print HTMLPAGE "<TR><TD BGCOLOR=\"CCCCCC\">Total $cat_key</TD><TD>$cat_value</TD></TR>";
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
          $message .= "E_Switching Report for Samir Sanghani $report{date}\n";
          $message .= "Please find the link location for your report here\n";
          $message .= "$report{web_link}\n";
#         system("mailx -s \"E_Switching Report for Samir Sanghani $report{date}\" $notify_list < $report{file}");
         &notify("$notify_list","E_Switching Report for Samir Sanghani $report{date}","$message");
         print "Email sent\n";
    }

}

sub notify {
    my($sendto,$subject,$message)=@_;
    my %mail = (
            smtp    => 'smtphost.broadcom.com',
            to      => $sendto,
            from    => "gnats4\@broadcom.com",
            subject => $subject,
            message => $message,
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
