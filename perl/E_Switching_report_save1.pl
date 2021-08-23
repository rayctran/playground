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
use GD;
use GD::Text;
use GD::Graph;
use strict;

my %gnats;
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
if ( $#ARGV < 0 ) {
        print "Usage: $0 [top level catgory]\n";
        exit;
} else {
        $gnats{top_level_cat}=$ARGV[0];
}


# Caculating dates
my (%after_date, %before_date, $delta_date, $ERR);
my (@data,@legend);

my $today = UnixDate("today","%d-%b-%Y");
#my $after_date="01-Jan-2000";
#my $today = "24-Oct-2004";

# First week
$before_date{week5} = UnixDate("$today","%d-%b-%Y");
$after_date{week5} = DateCalc("$today","-7 days", \$ERR);
$after_date{week5} = UnixDate("$after_date{week5}","%d-%b-%Y");
# Second week 
$before_date{week4} = DateCalc("$after_date{week5}","-1 days", \$ERR);
$before_date{week4} = UnixDate("$before_date{week4}","%d-%b-%Y");
$after_date{week4} = DateCalc("$before_date{week4}","-7 days", \$ERR);
$after_date{week4} = UnixDate("$after_date{week4}","%d-%b-%Y");
# Third week 
$before_date{week3} = DateCalc("$after_date{week4}","-1 days", \$ERR);
$before_date{week3} = UnixDate("$before_date{week3}","%d-%b-%Y");
$after_date{week3} = DateCalc("$before_date{week3}","-7 days", \$ERR);
$after_date{week3} = UnixDate("$after_date{week3}","%d-%b-%Y");
# Fourth week 
$before_date{week2} = DateCalc("$after_date{week3}","-1 days", \$ERR);
$before_date{week2} = UnixDate("$before_date{week2}","%d-%b-%Y");
$after_date{week2} = DateCalc("$before_date{week2}","-7 days", \$ERR);
$after_date{week2} = UnixDate("$after_date{week2}","%d-%b-%Y");
# Fifth week 
$before_date{week1} = DateCalc("$after_date{week2}","-1 days", \$ERR);
$before_date{week1} = UnixDate("$before_date{week1}","%d-%b-%Y");
$after_date{week1} = DateCalc("$before_date{week1}","-7 days", \$ERR);
$after_date{week1} = UnixDate("$after_date{week1}","%d-%b-%Y");

my (%report, $notify_list, $do_total, $do_graph, $do_report);
chop($report{date} = `date`);
$report{dir}="$gnats{gnats_root}/www/htdocs/reports/$gnats{database}/weekly";
$report{file}="$report{dir}/$gnats{top_level_cat}_5weeks_rpt_${today}.html";
$report{web_link}="http\:\/\/gnats-irva-3\/reports\/$gnats{database}\/weekly\/$gnats{top_level_cat}_5weeks_rpt_${today}.html";
$report{img_dir}="$report{dir}/images";

# Default actions
$do_total = 0;
$do_graph = 0;
$do_report = 0;

if ( $gnats{top_level_cat} =~ /Firebolt/ ) {
    $notify_list="raytran\@broadcom.com,samsang\@broadcom.com";
    $notify_list="raytran\@broadcom.com";
} 
if ( $gnats{top_level_cat} =~ /EasyRider/ ) {
    $notify_list="raytran\@broadcom.com,mngu\@broadcom.com";
    $do_total = 1;
    $do_graph = 1;
} 
if ( $gnats{top_level_cat} =~ /HELIX/ ) {
    $notify_list="raytran\@broadcom.com,mngu\@broadcom.com";
    $notify_list="raytran\@broadcom.com";
    $do_total = 1;
    $do_graph = 1;
} 
#$notify_list="raytran\@broadcom.com";
my $do_notify = 0;

sub main {
    my ($today, $ERR,);
    tie my %query_result, "Tie::IxHash";
    my (%pr, %db, $my_date, %time_stamp);
    my (@all_cat_list, %cat_list);
    my (%open_cat,%mod_cat,%closed_cat);
    my (%open_2nd_level_cat,%mod_2nd_level_cat,%closed_2nd_level_cat);
    my (%mail,$message);
    my ($cat_key, $cat_value);
    my (@first_query,@second_query, @data);
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
    
    my (%open_cnt, %closed_cnt, %mod_cnt); 
    my $all_cnt=0;
    $open_cnt{total}=0;
    $closed_cnt{total}=0;
    $mod_cnt{total}=0;

# Opened within the last 7 days
    print "$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -a $after_date{week1} -b $before_date{week1}\n";
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -a $after_date{week1} -b $before_date{week1} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $do_report=1;
            $open_cnt{week1}++;
            $open_cnt{total}++;
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $open_cat{$pr{category}}{week1}++;
            if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                $open_2nd_level_cat{$1}{week1}++;
            }
        } else {
            print "$_";
        }
    }
    close(QUERY);

# Modified within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -M $after_date{week1} -B $before_date{week1} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $do_report=1;
            $mod_cnt{week1}++;
            $mod_cnt{total}++;
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $mod_cat{$pr{category}}{week1}++;
            if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                $mod_2nd_level_cat{$1}{week1}++;
            }
        } else {
            print "$_";
        }
    }
    close(QUERY);

# Closed within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -Z $after_date{week1} -z $before_date{week1} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $do_report=1;
            $closed_cnt{week1}++;
            $closed_cnt{total}++;
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $closed_cat{$pr{category}}{week1}++;
            if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                $closed_2nd_level_cat{$1}{week1}++;
            }
        } else {
            print "$_";
        }
    }

# Opened within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -a $after_date{week2} -b $before_date{week2} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $do_report=1;
            $open_cnt{week2}++;
            $open_cnt{total}++;
           ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $open_cat{$pr{category}}{week2}++;
            if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                $open_2nd_level_cat{$1}{week2}++;
            }
        } else {
            print "$_";
        }
    }
    close(QUERY);

# Modified within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -M $after_date{week2} -B $before_date{week2} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $do_report=1;
            $mod_cnt{week2}++;
            $mod_cnt{total}++;
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $mod_cat{$pr{category}}{week2}++;
            if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                $mod_2nd_level_cat{$1}{week2}++;
            }
        } else {
            print "$_";
        }
    }
    close(QUERY);

# Closed within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -Z $after_date{week2} -z $before_date{week2} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $do_report=1;
            $closed_cnt{total}++;
            $closed_cnt{week2}++;
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $closed_cat{$pr{category}}{week2}++;
            if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                $closed_2nd_level_cat{$1}{week2}++;
            }
        } else {
            print "$_";
        }
    }

# Opened within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -a $after_date{week3} -b $before_date{week3} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $do_report=1;
            $open_cnt{week3}++;
            $open_cnt{total}++;
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $open_cat{$pr{category}}{week3}++;
            if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                $open_2nd_level_cat{$1}{week3}++;
            }
        } else {
            print "$_";
        }
    }
    close(QUERY);

# Modified within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -M $after_date{week3} -B $before_date{week3} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $do_report=1;
            $mod_cnt{week3}++;
            $mod_cnt{total}++;
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $mod_cat{$pr{category}}{week3}++;
            if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                $mod_2nd_level_cat{$1}{week3}++;
            }
        } else {
            print "$_";
        }
    }
    close(QUERY);

# Closed within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -Z $after_date{week3} -z $before_date{week3} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $do_report=1;
            $closed_cnt{week3}++;
            $closed_cnt{total}++;
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $closed_cat{$pr{category}}{week3}++;
            if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                $closed_2nd_level_cat{$1}{week3}++;
            }
        } else {
            print "$_";
        }
    }


# Opened within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -a $after_date{week4} -b $before_date{week4} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $do_report=1;
            $open_cnt{week4}++;
            $open_cnt{total}++;
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $open_cat{$pr{category}}{week4}++;
            if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                $open_2nd_level_cat{$1}{week4}++;
            }
        } else {
            print "$_";
        }
    }
    close(QUERY);

# Modified within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -M $after_date{week4} -B $before_date{week4} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $do_report=1;
            $mod_cnt{week4}++;
            $mod_cnt{total}++;
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $mod_cat{$pr{category}}{week4}++;
            if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                $mod_2nd_level_cat{$1}{week4}++;
            }
        } else {
            print "$_";
        }
    }
    close(QUERY);

# Closed within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -Z $after_date{week4} -z $before_date{week4} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $do_report=1;
            $closed_cnt{week4}++;
            $closed_cnt{total}++;
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $closed_cat{$pr{category}}{week4}++;
            if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                $closed_2nd_level_cat{$1}{week4}++;
            }
        } else {
            print "$_";
        }
    }

# Opened within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -a $after_date{week5} -b $before_date{week5} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $do_report=1;
            $open_cnt{week5}++;
            $open_cnt{total}++;
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $open_cat{$pr{category}}{week5}++;
            if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                $open_2nd_level_cat{$1}{week5}++;
            }
        } else {
            print "$_";
        }
    }
    close(QUERY);

# Modified within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -M $after_date{week5} -B $before_date{week5} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $do_report=1;
            $mod_cnt{week5}++;
            $mod_cnt{total}++;
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $mod_cat{$pr{category}}{week5}++;
            if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                $mod_2nd_level_cat{$1}{week5}++;
            }
        } else {
            print "$_";
        }
    }
    close(QUERY);

# Closed within the last 7 days
    open(QUERY,"$gnats{query_pr} -d $gnats{database} -v $gnats{user} -w $gnats{passwd} --expr \'State\~\"open\|closed\|analyzed\" \& Category~\"$gnats{top_level_cat}\"\' --format \'\"%s\|%s\|%s\|%s\|%s\|%s\" Number Category Synopsis Responsible State Priority\' -Z $after_date{week5} -z $before_date{week5} 2>&1 |") or die "Can't run query: $!\n";
    while(<QUERY>) {
        if (!/no PRs matched/) {
            $do_report=1;
            $closed_cnt{week5}++;
            $closed_cnt{total}++;
            ( $pr{no},$pr{category},$pr{synopsis},$pr{responsible},$pr{state},$pr{priority} ) = split(/\|/);
            $closed_cat{$pr{category}}{week5}++;
            if ( $pr{category} =~ /($gnats{top_level_cat}-\w+)-\w+/ ) {
                $closed_2nd_level_cat{$1}{week5}++;
            }
        } else {
            print "$_";
        }
    }

    foreach $cat_key (sort keys %open_cat) {
        if ( ! exists($open_cat{$cat_key}{week1}) ) {
            $open_cat{$cat_key}{week1} = 0;
        }
        if ( ! exists($open_cat{$cat_key}{week2}) ) {
            $open_cat{$cat_key}{week2} = 0;
        }
        if ( ! exists($open_cat{$cat_key}{week3}) ) {
            $open_cat{$cat_key}{week3} = 0;
        }
        if ( ! exists($open_cat{$cat_key}{week4}) ) {
            $open_cat{$cat_key}{week4} = 0;
        }
        if ( ! exists($open_cat{$cat_key}{week5}) ) {
            $open_cat{$cat_key}{week5} = 0;
        }
    }
    foreach $cat_key (sort keys %mod_cat) {
        if ( ! exists($mod_cat{$cat_key}{week1}) ) {
            $mod_cat{$cat_key}{week1} = 0;
        }
        if ( ! exists($mod_cat{$cat_key}{week2}) ) {
            $mod_cat{$cat_key}{week2} = 0;
        }
        if ( ! exists($mod_cat{$cat_key}{week3}) ) {
            $mod_cat{$cat_key}{week3} = 0;
        }
        if ( ! exists($mod_cat{$cat_key}{week4}) ) {
            $mod_cat{$cat_key}{week4} = 0;
        }
        if ( ! exists($mod_cat{$cat_key}{week5}) ) {
            $mod_cat{$cat_key}{week5} = 0;
        }
    }
    foreach $cat_key (sort keys %closed_cat) {
        if ( ! exists($closed_cat{$cat_key}{week1}) ) {
            $closed_cat{$cat_key}{week1} = 0;
        }
        if ( ! exists($closed_cat{$cat_key}{week2}) ) {
            $closed_cat{$cat_key}{week2} = 0;
        }
        if ( ! exists($closed_cat{$cat_key}{week3}) ) {
            $closed_cat{$cat_key}{week3} = 0;
        }
        if ( ! exists($closed_cat{$cat_key}{week4}) ) {
            $closed_cat{$cat_key}{week4} = 0;
        }
        if ( ! exists($closed_cat{$cat_key}{week5}) ) {
            $closed_cat{$cat_key}{week5} = 0;
        }
    }

    foreach $cat_key (sort keys %open_2nd_level_cat) {
        if ( ! exists($open_2nd_level_cat{$cat_key}{week1}) ) {
            $open_2nd_level_cat{$cat_key}{week1} = 0;
        }
        if ( ! exists($open_2nd_level_cat{$cat_key}{week2}) ) {
            $open_2nd_level_cat{$cat_key}{week2} = 0;
        }
        if ( ! exists($open_2nd_level_cat{$cat_key}{week3}) ) {
            $open_2nd_level_cat{$cat_key}{week3} = 0;
        }
        if ( ! exists($open_2nd_level_cat{$cat_key}{week4}) ) {
            $open_2nd_level_cat{$cat_key}{week4} = 0;
        }
        if ( ! exists($open_2nd_level_cat{$cat_key}{week5}) ) {
            $open_2nd_level_cat{$cat_key}{week5} = 0;
        }
    }
    foreach $cat_key (sort keys %mod_2nd_level_cat) {
        if ( ! exists($mod_2nd_level_cat{$cat_key}{week1}) ) {
            $mod_2nd_level_cat{$cat_key}{week1} = 0;
        }
        if ( ! exists($mod_2nd_level_cat{$cat_key}{week2}) ) {
            $mod_2nd_level_cat{$cat_key}{week2} = 0;
        }
        if ( ! exists($mod_2nd_level_cat{$cat_key}{week3}) ) {
            $mod_2nd_level_cat{$cat_key}{week3} = 0;
        }
        if ( ! exists($mod_2nd_level_cat{$cat_key}{week4}) ) {
            $mod_2nd_level_cat{$cat_key}{week4} = 0;
        }
        if ( ! exists($mod_2nd_level_cat{$cat_key}{week5}) ) {
            $mod_2nd_level_cat{$cat_key}{week5} = 0;
        }
    }
    foreach $cat_key (sort keys %closed_2nd_level_cat) {
        if ( ! exists($closed_2nd_level_cat{$cat_key}{week1}) ) {
            $closed_2nd_level_cat{$cat_key}{week1} = 0;
        }
        if ( ! exists($closed_2nd_level_cat{$cat_key}{week2}) ) {
            $closed_2nd_level_cat{$cat_key}{week2} = 0;
        }
        if ( ! exists($closed_2nd_level_cat{$cat_key}{week3}) ) {
            $closed_2nd_level_cat{$cat_key}{week3} = 0;
        }
        if ( ! exists($closed_2nd_level_cat{$cat_key}{week4}) ) {
            $closed_2nd_level_cat{$cat_key}{week4} = 0;
        }
        if ( ! exists($closed_2nd_level_cat{$cat_key}{week5}) ) {
            $closed_2nd_level_cat{$cat_key}{week5} = 0;
        }
    }

    if ( $do_graph ) {
    }

#print Dumper(\%open_cat);
#print Dumper(\%mod_cat);
#print Dumper(\%closed_cat);
#print Dumper(\%open_2nd_level_cat);
#print Dumper(\%mod_2nd_level_cat);
#print Dumper(\%closed_2nd_level_cat);
#exit;

    if ($do_report) {
    
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
          <TR><TD><H1><P ALIGN=CENTER>GNATS PRs Report for $pr{database} all $gnats{top_levelcat} catgories for the time window: $after_date{week1} to $before_date{week5}</P></H1></TD></TR>
          <TR><TD>Total number of tickets that was opened - $open_cnt{total}</TR></TD>
          <TR><TD>Total number of tickets that was modified - $mod_cnt{total}</TR></TD>
          <TR><TD>Total number of tickets that was closed - $closed_cnt{total}</TR></TD>
          <TR><TD BGCOLOR=\"CCCCCC\">All PRs opened during time window: $after_date{week1} - $before_date{week5}<BR></TD></TR>
          <TR><TD><TABLE BORDER=1 CELLSPACING=3>
            <TR BGCOLOR=\"CCCCCC\"><TD NOWRAP>Category</TD><TD>Week 1<BR>${after_date{week1}}-${before_date{week1}}</TD><TD>Week 2<BR>${after_date{week2}}-${before_date{week2}}</TD><TD>Week 3<BR>${after_date{week3}}-${before_date{week3}}</TD><TD>Week 4<BR>${after_date{week4}}-${before_date{week4}}</TD><TD>Week 5<BR>${after_date{week5}}-${before_date{week5}}</TD></TR>\n
        ";
          foreach $cat_key (sort keys %open_cat) { 
              print HTMLPAGE "<TR><TD>$cat_key</TD><TD>$open_cat{$cat_key}{week1}</TD><TD>$open_cat{$cat_key}{week2}</TD><TD>$open_cat{$cat_key}{week3}</TD><TD>$open_cat{$cat_key}{week4}</TD><TD>$open_cat{$cat_key}{week5}</TD></TR>\n";
          }
          foreach $cat_key (sort keys %open_2nd_level_cat) { 
              print HTMLPAGE "<TR><TD BGCOLOR=\"CCCCCC\">Total $cat_key</TD><TD>$open_2nd_level_cat{$cat_key}{week1}</TD><TD>$open_2nd_level_cat{$cat_key}{week2}</TD><TD>$open_2nd_level_cat{$cat_key}{week3}</TD><TD>$open_2nd_level_cat{$cat_key}{week4}</TD><TD>$open_2nd_level_cat{$cat_key}{week5}</TD></TR>\n";
          }
          if ($do_total) {
              print HTMLPAGE "<TR><TD BGCOLOR=\"CCCCCC\">Total $gnats{top_level_cat}</TD><TD>$open_cnt{week1}</TD><TD>$open_cnt{week2}</TD><TD>$open_cnt{week3}</TD><TD>$open_cnt{week4}</TD><TD>$open_cnt{week5}</TD></TR>\n";
          }
          print HTMLPAGE "    
            </TABLE></TD></TR>
          <TR><TD BGCOLOR=\"CCCCCC\">All PRs modified during time window: $after_date{week1} - $before_date{week5}<BR></TD></TR>
          <TR><TD><TABLE BORDER=1 CELLSPACING=3>
            <TR BGCOLOR=\"CCCCCC\"><TD NOWRAP>Category</TD><TD>Week 1<BR>$after_date{week1}-$before_date{week1}</TD><TD>Week 2<BR>$after_date{week2}-$before_date{week2}</TD><TD>Week 3<BR>$after_date{week3}-$before_date{week3}</TD><TD>Week 4<BR>$after_date{week4}-$before_date{week4}</TD><TD>Week 5<BR>$after_date{week5}-$before_date{week5}</TD></TR>\n
        ";
          foreach $cat_key (sort keys %mod_cat) { 
              print HTMLPAGE "<TR><TD>$cat_key</TD><TD>$mod_cat{$cat_key}{week1}</TD><TD>$mod_cat{$cat_key}{week2}</TD><TD>$mod_cat{$cat_key}{week3}</TD><TD>$mod_cat{$cat_key}{week4}</TD><TD>$mod_cat{$cat_key}{week5}</TD></TR>\n";
          }
          foreach $cat_key (sort keys %mod_2nd_level_cat) { 
              print HTMLPAGE "<TR><TD BGCOLOR=\"CCCCCC\">Total $cat_key</TD><TD>$mod_2nd_level_cat{$cat_key}{week1}</TD><TD>$mod_2nd_level_cat{$cat_key}{week2}</TD><TD>$mod_2nd_level_cat{$cat_key}{week3}</TD><TD>$mod_2nd_level_cat{$cat_key}{week4}</TD><TD>$mod_2nd_level_cat{$cat_key}{week5}</TD></TR>\n";
          }
          if ($do_total) {
              print HTMLPAGE "<TR><TD BGCOLOR=\"CCCCCC\">Total $gnats{top_level_cat}</TD><TD>$mod_cnt{week1}</TD><TD>$mod_cnt{week2}</TD><TD>$mod_cnt{week3}</TD><TD>$mod_cnt{week4}</TD><TD>$mod_cnt{week5}</TD></TR>\n";
          }
          print HTMLPAGE "    
            </TABLE></TD></TR>
          <TR><TD BGCOLOR=\"CCCCCC\">All PRs closed during time window: $after_date{week1} - $before_date{week5}<BR></TD></TR>
          <TR><TD><TABLE BORDER=1 CELLSPACING=3>
            <TR BGCOLOR=\"CCCCCC\"><TD NOWRAP>Category</TD><TD>Week 1<BR>$after_date{week1}-$before_date{week1}</TD><TD>Week 2<BR>$after_date{week2}-$before_date{week2}</TD><TD>Week 3<BR>$after_date{week3}-$before_date{week3}</TD><TD>Week 4<BR>$after_date{week4}-$before_date{week4}</TD><TD>Week 5<BR>$after_date{week5}-$before_date{week5}</TD></TR>\n
        ";
          foreach $cat_key (sort keys %closed_cat) { 
              print HTMLPAGE "<TR><TD>$cat_key</TD><TD>$closed_cat{$cat_key}{week1}</TD><TD>$closed_cat{$cat_key}{week2}</TD><TD>$closed_cat{$cat_key}{week3}</TD><TD>$closed_cat{$cat_key}{week4}</TD><TD>$closed_cat{$cat_key}{week5}</TD></TR>\n";
          }
          foreach $cat_key (sort keys %closed_2nd_level_cat) { 
              print HTMLPAGE "<TR><TD BGCOLOR=\"CCCCCC\">Total $cat_key</TD><TD>$closed_2nd_level_cat{$cat_key}{week1}</TD><TD>$closed_2nd_level_cat{$cat_key}{week2}</TD><TD>$closed_2nd_level_cat{$cat_key}{week3}</TD><TD>$closed_2nd_level_cat{$cat_key}{week4}</TD><TD>$closed_2nd_level_cat{$cat_key}{week5}</TD></TR>\n";
          }
          if ($do_total) {
              print HTMLPAGE "<TR><TD BGCOLOR=\"CCCCCC\">Total $gnats{top_level_cat}</TD><TD>$closed_cnt{week1}</TD><TD>$closed_cnt{week2}</TD><TD>$closed_cnt{week3}</TD><TD>$closed_cnt{week4}</TD><TD>$closed_cnt{week5}</TD></TR>\n";
          }
        print HTMLPAGE "
            </TABLE>
            </TD></TR>
            </TABLE>
            </BODY>
            </HTML>
        ";
        close(HTMLPAGE);
        if ($do_notify) {
            $message .= "E_Switching Report for top level Category $gnats{top_level_cat} $report{date}\n";
            $message .= "Please find the link location for your report here\n";
            $message .= "$report{web_link}\n";
            &notify("$notify_list","E_Switching Report for top level Category $gnats{top_level_cat} $report{date}","$message");
        }
    } else {
        $message .= "No Data to report for the week period between $before_date{week5} and $after_date{week1}. \n";
        &notify("$notify_list","E_Switching Report for top level Category $gnats{top_level_cat} $report{date}","$message");
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

sub create_pie_chart {
        my($Title,$OutFile) = @_;
        use GD::Graph::pie;
        use GD::Graph::Data;

        my $graph = GD::Graph::pie->new(200,200);

        $graph->set(
                title             => $Title,
                '3d'              => 1,
                transparent       => 1,
                legend_placement  => 'BC',
                bgclr             => 'white',
                fgclr             => 'black',
                pie_height        => 15,
                start_angle       => 30,
                suppress_angle    => 5,
                dclrs             => ['lblue', 'green', 'blue', 'red', 'lpurple', 'cyan', 'yellow'],
                text_space        => 5,
        );

        $graph->set_title_font(gdLargeFont);
        $graph->set_value_font(gdSmallFont);
        $graph->set_label_font(gdSmallFont);

        my $gd = $graph->plot(\@data);
        open(IMG, "> $OutFile") or die "Can't create graph :$!\n";
        binmode IMG;
        print IMG $gd->png;
        close IMG;
}

sub create_line_graph {
        my($type,$title,$x_label,$y_label,$y_max_value,$y_min_value,$y_tick_number,$OutFile) = @_;
        use GD::Graph::linespoints;
        use GD::Graph::Data;
        my $graph_width = 800;
        my $graph_height = 400;

        my $graph = GD::Graph::linespoints->new($graph_width, $graph_height);
        $graph->set(
                x_label           => $x_label,
                y_label           => $y_label,
                title             => $title,
                y_max_value       => $y_max_value,
                y_min_value       => 0,
                y_tick_number     => $y_tick_number,
                t_margin          => 15,
                b_margin          => 15,
                l_margin          => 15,
                r_margin          => 15,
                testy_label_skip      => 0,
                dclrs             => ['light-blue','yellow', 'orange', 'blue'],
                line_width        => 2,
                line_types        => [1,1,1],
                transparent       => 0,
                legend_placement  => 'BC',
                bgclr             => 'white',
                fgclr             => 'black',
                long_ticks        => 1,
                x_labels_vertical => 1,
                markers           => [4,1],
                markers_size      => 1,
                zero_axis_only    => 0,
        );
        $graph->set_title_font(gdLargeFont);
        $graph->set_legend_font(['verdana','arial','gdSmallFont']);
        $graph->set_y_label_font(gdLargeFont);
        $graph->set_x_label_font(gdLargeFont);
        $graph->set_x_axis_font(gdTinyFont);
        $graph->set_y_axis_font(gdTinyFont);
        my $gd = $graph->plot(\@data);
        open(IMG, "> $OutFile") or die $!;
        binmode IMG;
        print IMG $gd->png;
        close IMG;
}

sub create_bar_graph {
        my($title,$x_label,$y_label,$y_max_value,$OutFile) = @_;
#        use GD::Graph::bars3d;
        use GD::Graph::bars;
        use GD::Graph::Data;
        my $graph_width = 500;
        my $graph_height = 400;

        my $graph = GD::Graph::bars->new($graph_width, $graph_height);
        $graph->set(
                x_label           => $x_label,
                y_label           => $y_label,
                title             => $title,
                y_max_value       => $y_max_value,
                y_min_value       => 0,
                y_tick_number     => $y_max_value,
                y_label_skip      => 0,
                dclrs             => ['blue','red','green'],
                transparent       => 0,
                bar_width         => 15,
                bar_spacing       => 5,
                legend_placement  => 'BC',
                bgclr             => 'white',
                fgclr             => 'black',
                long_ticks        => 1,
                show_values       => 1,
                x_labels_vertical => 1
        );
        $graph->set_title_font(gdLargeFont);
        $graph->set_legend_font(['verdana','arial','gdSmallFont']);
        $graph->set_y_label_font(gdLargeFont);
        $graph->set_x_label_font(gdLargeFont);
        $graph->set_x_axis_font(gdSmallFont);
        $graph->set_y_axis_font(gdSmallFont);
        $graph->set_legend_font(GD::gdMediumBoldFont);
        $graph->set_legend(@legend);
        my $gd = $graph->plot(\@data);
        open(IMG, "> $OutFile") or die $!;
        binmode IMG;
        print IMG $gd->png;
        close IMG;
}

# Run main
main;
