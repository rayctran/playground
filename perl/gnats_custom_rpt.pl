#!/tools/perl/5.6.0/SunOS/bin/perl

use Data::Dumper;
use IO::File;
use File::Basename;
use Date::Manip;
use File::stat;
use File::Basename;
use Mail::Sendmail;
use Tie::IxHash;
use strict;


my (%gnats,%Arg,$key,$value);
%gnats = (
       server    => "gnats-irva-3.broadcom.com",
       port      => "1530",
       user      => "gnats4",
       passwd    => "emsggn09",
       query_pr  => "/tools/bin/query-pr",
       root      => "/tools/gnats/4.0",
       databases => "/tools/gnats/4.0/etc/gnats/databases",
       );

if ( $#ARGV < 0 ) {
    print "Usage: $0 -d [database name] -c [top level category] -f [full path to the report HTML file] -a [after date] -b [before date]\n";
    print "Where - Date format is yyyy-mm-dd";
    print "Example: $0 -d E_Switching -c Firebolt -f /tools/gnats/reports/myreport.html -a 2003-12-01 -b 2004-10-11\n";
    exit;
} else {
    %Arg=@ARGV;
    while( ($key,$value)=each %Arg){
        if ($key =~ /-d/) {
            $gnats{database} = $value;
        }
        if ($key =~ /-c/) {
            $gnats{top_level_cat}=$value;
        }
        if ($key =~ /-b/) {
            $gnats{before_date}=$value;
        }
        if ($key =~ /-a/) {
            $gnats{after_date}=$value;
        }
        if ($key =~ /-f/) {
            $gnats{report_file}=$value;
        }
    }
}

#print Dumper(\%gnats);

# Need some checking for input format here

# checking date format
if ( ($gnats{after_date} !~ /\d{4}\-\d{1,2}\-\d{1,2}/) || ($gnats{before_date} !~ /\d{4}\-\d{1,2}\-\d{1,2}/) ) {
    print "Invalid date format, $gnats{after_date} or $gnats{before_date} should be yyyy-mm-dd\n"; 
    print "Please try again.\n";
    exit 1;
}

# checking directory existance and access
$gnats{rpt_file_name} = basename($gnats{report_file});
$gnats{rpt_dir_name} = dirname($gnats{report_file});
if ( ( ! -d $gnats{rpt_dir_name} ) && ( !-w $gnats{rpt_dir_name} ) ) {
    print "Invalid directory or directory is not writable $gnats{rpt_dir_name}\n"; 
    print "Please try again.\n";
    exit 1;
}
if ( $gnats{rpt_file_name} !~ /html|htm$/ ) {
    print "WARNING: Report file name does not end with a recognized HTML naming convention\n";
}


my $today = UnixDate("today","%d-%b-%Y");
my (%report, %day_map);

chop($report{date} = `date`);
#$report{dir}="$gnats{gnats_root}/www/htdocs/reports/$gnats{database}";
#$report{file}="$report{dir}/weekly/firebolt_${today}.html";
#$report{web_link} = "http\:\/\/gnats-irva-3.broadcom.com\/reports/$gnats{database}\/weekly\/$gnats{top_level_cat}_${today}.html";
my $notify_list="raytran\@broadcom.com,samsang\@broadcom.com";
my $notify = 0;

sub main {
    tie my %query_result, "Tie::IxHash";
    my ($before_date,$after_date,%open_cnt,%closed_cnt,%mod_cnt,%seen);
    my (%pr, %db, $my_date, %time_stamp,$week_no,$category);
    my (@all_cat_list, @all_week_list,%cat_list, %cnt);
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
        print "ERROR - Can not locate source directory for database $gnats{database} in $gnats{root}/etc/gnats/databases. Please try again\n";
        exit 1;
    }

# this section will break the start and end date into weeks
# assuming that the week starts with Monday to Sunday.
# also if the start request day starts at the middle of the
# week, then only process the days within that week. 

    my ($cmp_flag,$current_working_date,%working_date,$working_week,$dotw,$ERR);
#
# start with the input before date and work our way back
#
    $working_week = 1;
#
# cm_flag=0 is same day, cmp_flag = 1 is after, cmd_flag = -1 is before
# Only work on after or the same day as the input after date
# $working_date{dotw} is the number of the day of the week  - 1=Monday-7=Sunday
#
    $cmp_flag = 1;
    while ( $cmp_flag ge 0 ) {
        if ( !defined $current_working_date ) {
            $current_working_date = UnixDate("$gnats{before_date}","%d-%b-%Y");
            $working_date{$working_week}{before_date} = UnixDate("$gnats{before_date}","%d-%b-%Y");
        }
        $dotw = &UnixDate($current_working_date,"%w");
        if ( $dotw eq 1 ) {
            $working_date{$working_week}{after_date} = UnixDate("$current_working_date","%d-%b-%Y");
        }          
        if ( $dotw eq 7 ) {
            $working_week++; 
            if ( !defined $working_date{$working_week}{before_date} ) {
                $working_date{$working_week}{before_date} = UnixDate("$current_working_date","%d-%b-%Y");
            }
        }
        if ( ($cmp_flag eq 0) && (! defined $working_date{$working_week}{after_date}) ) {
            $working_date{$working_week}{after_date} = UnixDate("$current_working_date","%d-%b-%Y");
        }
        if ( !$seen{$working_week} ) {
            push(@all_week_list,$working_week);
            $seen{$working_week}=1;
        }
        $current_working_date = DateCalc("$current_working_date","-1 day",\$ERR);
        $current_working_date = &UnixDate("$current_working_date","%Y-%m-%d");
        $cmp_flag = Date_Cmp($current_working_date,$gnats{after_date});
    }


#print Dumper(\@all_week_list);
#print Dumper(\%working_date);

# Loop through the working_week 

    foreach my $week (sort keys %working_date) {

# Opened within the last 7 days
        undef %seen;
        undef @all_cat_list;
        open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -a $working_date{$week}{after_date} -b $working_date{$week}{before_date} 2>&1 |") or die "Can't run query: $!\n";
        while(<QUERY>) {
            if (!/no PRs matched/) {
                $open_cnt{$week}++;
                $open_cnt{total}++;
                ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
                $open_cat{$pr{category}}{$week}++;
                if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                    $open_2nd_level_cat{$1}{$week}++;
                    if ( !$seen{$pr{category}} ) {
                        push(@all_cat_list,$pr{category});
                        $seen{$pr{category}}=1;
                    }
                }
            } else {
                print "$_\n";
            }
        }
        close(QUERY);
        for $week_no (@all_week_list) {
            for $category ( @all_cat_list ) {
                if ( !exists($open_cat{$category}{$week_no}) ) {
                    $open_cat{$category}{$week_no}=0;
                }
            }
        }

        undef @all_cat_list;
        undef %seen;
# Modified within the last 7 days
        open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -M $working_date{$week}{after_date} -B $working_date{$week}{before_date} 2>&1 |") or die "Can't run query: $!\n";
        while(<QUERY>) {
            if (!/no PRs matched/) {
                $mod_cnt{$week}++;
                $mod_cnt{total}++;
                ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
                $mod_cat{$pr{category}}{$week}++;
                if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                    $mod_2nd_level_cat{$1}{$week}++;
                    if ( !$seen{$pr{category}} ) {
                        push(@all_cat_list,$pr{category});
                        $seen{$pr{category}}=1;
                    }
                }
            } else {
                print "$_\n";
            }
        }
        close(QUERY);
        for $week_no (@all_week_list) {
            for $category ( @all_cat_list ) {
                if ( !exists($mod_cat{$category}{$week_no}) ) {
                    $mod_cat{$category}{$week_no}=0;
                }
            }
        }

        undef @all_cat_list;
        undef %seen;
# Closed within the last 7 days
        open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -Z $working_date{$week}{after_date} -z $working_date{$week}{before_date} 2>&1 |") or die "Can't run query: $!\n";
        while(<QUERY>) {
            if (!/no PRs matched/) {
                $closed_cnt{$week}++;
                $closed_cnt{total}++;
                ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
                $closed_cat{$pr{category}}{$week}++;
                if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                    $closed_2nd_level_cat{$1}{$week}++;
                    if ( !$seen{$pr{category}} ) {
                        push(@all_cat_list,$pr{category});
                        $seen{$pr{category}}=1;
                    }
                }
            } else {
                print "$_\n";
            }
        }
        close(QUERY);
        for $week_no (@all_week_list) {
            for $category ( @all_cat_list ) {
                if ( !exists($closed_cat{$category}{$week_no}) ) {
                    $closed_cat{$category}{$week_no}=0;
                }
            }
        }
    }


#print Dumper(\%open_cat);
#print Dumper(\%mod_cat);
#print Dumper(\%closed_cat);
#print Dumper(\%open_2nd_level_cat);
#print Dumper(\%mod_2nd_level_cat);
#print Dumper(\%closed_2nd_level_cat);
#exit;

    my $last_week_no = $all_week_list[$#all_week_list];

# Create HTML report page
    open(HTMLPAGE,">$gnats{report_file}") or die "Can't open report file $gnats{report_file}: $!\n";
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
      <TR><TD><H1><P ALIGN=CENTER>GNATS PRs Report for $pr{database} all $gnats{top_level_cat} catgories for the time span of $gnats{after_date} to $gnats{before_date}</P></H1></TD></TR>
      <TR><TD>Total number of tickets that was opened - $open_cnt{total}</TR></TD>
      <TR><TD>Total number of tickets that was modified - $mod_cnt{total}</TR></TD>
      <TR><TD>Total number of tickets that was closed - $closed_cnt{total}</TR></TD>
      <TR><TD BGCOLOR=\"CCCCCC\">All PRs opened during time window: $gnats{after_date} - $gnats{before_date}<BR></TD></TR>
      <TR><TD><TABLE BORDER=1 CELLSPACING=3>
    ";
    print HTMLPAGE "<TR BGCOLOR=\"CCCCCC\"><TD>Category</TD>";
    for $week_no (sort { $a <=> $b } @all_week_list) {
       print HTMLPAGE "<TD>Week $week_no<BR>$working_date{$week_no}{after_date}-$working_date{$week_no}{before_date}</TD>\n"; 
    }
    foreach $cat_key (sort keys %open_cat) {
        print HTMLPAGE "<TR><TD>$cat_key</TD>";
        for $week_no (sort { $a <=> $b } @all_week_list) {
           print HTMLPAGE "<TD>$open_cat{$cat_key}{$week_no}</TD>\n";
       }
       print HTMLPAGE "</TR>\n";
    }
    print HTMLPAGE "<TR><TD BGCOLOR=\"CCCCCC\">Total $gnats{top_level_cat}</TD>\n";
    for $week_no (sort { $a <=> $b } @all_week_list) {
       print HTMLPAGE "<TD>$open_cnt{$week_no}</TD>\n";
    }
    print HTMLPAGE "</TR></TABLE></TD></TR>
      <TR><TD BGCOLOR=\"CCCCCC\">All PRs modified during time window: $gnats{after_date} - $gnats{before_date}<BR></TD></TR>
      <TR><TD><TABLE BORDER=1 CELLSPACING=3> 
    ";
    print HTMLPAGE "<TR BGCOLOR=\"CCCCCC\"><TD>Category</TD>";
    for $week_no (sort { $a <=> $b } @all_week_list) {
       print HTMLPAGE "<TD>Week $week_no<BR>$working_date{$week_no}{after_date}-$working_date{$week_no}{before_date}</TD>\n"; 
    }
    foreach $cat_key (sort keys %mod_cat) {
        print HTMLPAGE "<TR><TD>$cat_key</TD>";
        for $week_no (sort { $a <=> $b } @all_week_list) {
            print HTMLPAGE "<TD>$mod_cat{$cat_key}{$week_no}</TD>\n";
        }
       print HTMLPAGE "</TR>\n";
    }
    print HTMLPAGE "<TR><TD BGCOLOR=\"CCCCCC\">Total $gnats{top_level_cat}</TD>\n";
    for $week_no (sort { $a <=> $b } @all_week_list) {
       print HTMLPAGE "<TD>$mod_cnt{$week_no}</TD>\n";
    }
    print HTMLPAGE "</TR></TABLE></TD></TR>
      <TR><TD BGCOLOR=\"CCCCCC\">All PRs closed during time window: $gnats{after_date} - $gnats{before_date}<BR></TD></TR>
      <TR><TD><TABLE BORDER=1 CELLSPACING=3> 
    ";
    print HTMLPAGE "<TR BGCOLOR=\"CCCCCC\"><TD>Category</TD>";
    for $week_no (sort { $a <=> $b } @all_week_list) {
       print HTMLPAGE "<TD>Week $week_no<BR>$working_date{$week_no}{after_date}-$working_date{$week_no}{before_date}</TD>\n"; 
    }
    foreach $cat_key (sort keys %closed_cat) {
        print HTMLPAGE "<TR><TD>$cat_key</TD>";
        for $week_no (sort { $a <=> $b } @all_week_list) {
            print HTMLPAGE "<TD>$closed_cat{$cat_key}{$week_no}</TD>\n";
        }
       print HTMLPAGE "</TR>\n";
    }
    print HTMLPAGE "<TR><TD BGCOLOR=\"CCCCCC\">Total $gnats{top_level_cat}</TD>\n";
    for $week_no (sort { $a <=> $b } @all_week_list) {
       print HTMLPAGE "<TD>$closed_cnt{$week_no}</TD>\n";
    }

    print HTMLPAGE "
        </TR></TABLE>
        </TD></TR>
        </TABLE>
        </BODY>
        </HTML>
    ";
    close(HTMLPAGE);

    print "GNATS report file $gnats{report_file} created\n";
    if ($notify) {
          $message .= "$gnats{database} Report for Samir Sanghani $report{date}\n";
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
