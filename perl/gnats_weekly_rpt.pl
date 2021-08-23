#!/tools/perl/5.6.0/SunOS/bin/perl

use Data::Dumper;
use IO::File;
use File::Basename;
use Date::Manip;
use File::stat;
use strict;
use GD;
use GD::Text;
use GD::Graph;
use Tie::IxHash;
use CGI;

my ($database, $days, @data, @legend);

if ( $#ARGV < 0 ) {
        print "Usage: $0 [databaname] [how many days back to get]\n";
        exit;
} else {
        $database=$ARGV[0];
        $days=$ARGV[1];
}

sub main { 
    my (%db);
    my (@cat_list, @empty_cat_list, %category_stats, $pr);
    my ($tag, $value, %seen, %global_stats, $cat_name, %charts, %percent);
    my ($total_pr, $max_daily_graph);
 #   my (%open_cat_cnt, %closed_cat_cnt, %modified_cat_cnt);
    tie my %open_cat_cnt, "Tie::IxHash";
    tie my %modified_cat_cnt, "Tie::IxHash";
    tie my %closed_cat_cnt, "Tie::IxHash";
    my (%daily_open_cat, %daily_closed_cat, %daily_modified_cat);
    my $gnats_root="/tools/gnats/4.0";
    my $file_name=&UnixDate(`date`,"%Y_%m_%d");
    my $databases="${gnats_root}/etc/gnats/databases";
    my $report_dir="${gnats_root}/www/htdocs/reports/${database}/weekly";
    my $html_file="${report_dir}/${file_name}.html";
    my $img_dir="${report_dir}/images";
    my $web_link="http\:\/\/gnats-irva-3\.broadcom\.com\/reports\/${database}\/weekly\/${file_name}.html";
    my $query_pr="/tools/bin/query-pr";
    my (%pr);
    chop(my $today=`date`);

    print "Verifying database $database\n";
    my $found = 0;
    open(DBFILE, "$databases") or die "Can't open database file: $!\n";
    while(<DBFILE>) {
            chop($_);
            next if /^#/;
            ($db{name},$db{desc},$db{dir}) = split(/:/);
            if ( $database =~ /$db{name}/ ) {
                print "$db{name} found. Directory $db{dir}\n";
                $found = 1;
                if (! -d "$report_dir") {
                    print "Creating report directory $report_dir\n";
                    system("mkdir -p $report_dir");
                }
                if (! -d "$img_dir") {
                    print "Creating image directory $img_dir\n";
                    system("mkdir -p $img_dir");
                }
                last;
            }
    }

# Verify database
    if ( $found == 0 ) {
        print "ERROR - Can not locate source directory for database $database in ${gnats_root}/etc/gnats/databases. Please try again\n";
        exit 1;
    }

# Checking on categories    
# Count the actual PR per category
# Keep track of how severity, priority and state of each ticket per catgory

    open(CATLIST,"$query_pr -d $database -v gnats4 -w emsggn09 --list-categories |") or die "Can't open categories file:$!\n";
    while(<CATLIST>) {
        if (/^(\w+(-\w+)*):/)  {
            $total_pr = 0;
            $cat_name = $1;
            push(@cat_list,$cat_name);
            opendir(CAT_DIR,"${db{dir}}/${cat_name}") or die "Can't access directory ${db{dir}}/${cat_name}: $!\n";
            while (defined ($pr = readdir CAT_DIR)) {
                if ($pr =~ /^\d+$/) {
                    my (%local_cnt, $tag_name);
                    open(PRFILE,"${db{dir}}/${cat_name}/$pr") or die "Can't open PR number $pr: $!\n";
                    while(<PRFILE>) {
                        if (/^\>(Severity|Priority|State)/) {
                           my ($tag,$value)=split(/:/, $_, 2);
                           $value =~ s/\s+//g;
                           $tag =~ s/\>//g;
                           if ("$value" eq "") {
                               $value = "NA";
                           }
                           $category_stats{$cat_name}{$tag}{$value}++;
                           $global_stats{$tag}{$value}++;

                        }  
                    } 
                    $total_pr++;
                    $global_stats{count}{pr}++;
                }
            }
            if ($total_pr == 0) {
                push(@empty_cat_list,$cat_name);
                $global_stats{category}{$cat_name}=0;
                $global_stats{count}{inactive_cat}++;
            } else {
                $category_stats{$cat_name}{pr}{cnt} = $category_stats{$cat_name}{pr}{cnt} + $total_pr;
                $global_stats{category}{$cat_name}=$category_stats{$cat_name}{pr}{cnt};
                $global_stats{count}{active_cat}++;
            }
            $global_stats{count}{categories}++;
        }
    }
    close(CATLIST);
    
   print Dumper(\%category_stats);
   print Dumper(\%global_stats);
#    print Dumper(\@empty_cat_list);
# exit;

    
# Calculate stats per day. Assuming job runs
    my ($after_date, $before_date, $err, @day_stats, $day_cnt);
    my $max_cnt = 0;
#
# Run query-pr to get the stat and count it
#
# Open PRs
    my $open_days = $days;
    $day_cnt = 0;
    while ($open_days > 0) {
        $after_date = DateCalc("today","-${open_days} days", \$err);
        $after_date = UnixDate("$after_date", "%d-%b-%Y");
        push @{ $day_stats[0] }, "$after_date";
        $before_date = DateCalc("$after_date","+1 day", \$err);
        $before_date = UnixDate("$before_date", "%d-%b-%Y");
        open(QUERY,"$query_pr -d $database -v gnats4 -w emsggn09 -a \"$after_date\" -b \"$before_date\" --expr \'\!\(Category==\"test\"\|Category==\"pending\"\)\' --format \'\"%s\|%s\|%s\|%s\" State Priority Severity Category\' 2>&1 |") or die "Can't run query: $!\n";
        while(<QUERY>) {
            if (!/no PRs matched/) {
                $day_cnt++;
                ( $pr{state},$pr{priority},$pr{severity},$pr{category} ) = split(/\|/);
                $open_cat_cnt{$after_date}{$pr{category}}++;
            }
        }
        push @{ $day_stats[1] }, "$day_cnt";
        if ( $day_cnt > $max_cnt ) {
            $max_cnt = $day_cnt;
        }
    }
    continue {
        $open_days--;
    }

# Modified PRs
    my $mod_days = $days;
    $day_cnt = 0;
    while ($mod_days > 0) {
        $after_date = DateCalc("today","-${mod_days} days", \$err);
        $after_date = UnixDate("$after_date", "%d-%b-%Y");
        $before_date = DateCalc("$after_date","+1 day", \$err);
        $before_date = UnixDate("$before_date", "%d-%b-%Y");
        open(QUERY,"$query_pr -d $database -v gnats4 -w emsggn09 -M \"$after_date\" -B \"$before_date\" --expr \'\!\(Category==\"test\"\|Category==\"pending\"\)\' --format \'\"%s\|%s\|%s\|%s\" State Priority Severity Category\' 2>&1 |") or die "Can't run query: $!\n";
        while(<QUERY>) {
            if (!/no PRs matched/) {
                $day_cnt++;
                ( $pr{state},$pr{priority},$pr{severity},$pr{category} ) = split(/\|/);
                $modified_cat_cnt{$after_date}{$pr{category}}++;
            }
        }
        push @{ $day_stats[2] }, "$day_cnt";
        if ( $day_cnt > $max_cnt ) {
            $max_cnt = $day_cnt;
        }
    }
    continue {
        $mod_days--;
    }
# Closed PRs
    my $closed_days = $days;
    $day_cnt = 0;
    while ($closed_days > 0) {
        $after_date = DateCalc("today","-${closed_days} days", \$err);
        $after_date = UnixDate("$after_date", "%d-%b-%Y");
        $before_date = DateCalc("$after_date","+1 day", \$err);
        $before_date = UnixDate("$before_date", "%d-%b-%Y");
        open(QUERY,"$query_pr -d $database -v gnats4 -w emsggn09 -Z \"$after_date\" -z \"$before_date\" --expr \'\!\(Category==\"test\"\|Category==\"pending\"\)\' --format \'\"%s\|%s\|%s\|%s\|%s\" State Priority Severity Category\' 2>&1 |") or die "Can't run query: $!\n";
        while(<QUERY>) {
            if (!/no PRs matched/) {
                $day_cnt++;
                ( $pr{state},$pr{priority},$pr{severity},$pr{category} ) = split(/\|/);
                $closed_cat_cnt{$after_date}{$pr{category}}++;
            }
        }
        push @{ $day_stats[3] }, "$day_cnt";
        if ( $day_cnt > $max_cnt ) {
            $max_cnt = $day_cnt;
        }
    }
    continue {
        $closed_days--;
    }


    print Dumper(\@day_stats);
    print Dumper(\%open_cat_cnt);
    print Dumper(\%modified_cat_cnt);
    print Dumper(\%closed_cat_cnt);
    exit;
    
    $max_daily_graph = $max_cnt + 3;

#    print Dumper(\@day_stats); 
    undef(@data);

# Create bar graph of date range and activities
    undef(@data);
    @data = @day_stats;
    @legend = ("open","modified","closed");
    &create_bar_graph("Last $days Daily Graph","Date","No. of PRs","$max_daily_graph","${img_dir}/daily_chart_${file_name}.png");
    $charts{daily_graph}="./images/daily_chart_${file_name}.png";

# Create pie graphs of States, Priority, Severity
    my ($average, $array_column, $global_kw);
    foreach my $global_key (keys %global_stats) {
        if ( $global_key =~ /^State/ ) {
            ($global_kw = $global_key) =~ s/State_//;
            $average = sprintf("%.1f",($global_stats{$global_key} / $global_stats{pr_cnt}) * 100);
            push @{ $data[0] }, "$global_kw $average%";
            push @{ $data[1] }, "$global_stats{$global_key}";
            $percent{$global_key} = "$average%";
        }
    }
    &create_pie_chart("Percentage by States","${img_dir}/state_chart_${file_name}.png");
    $charts{state_chart}="./images/state_chart_${file_name}.png";
    undef(@data);
    foreach my $global_key (keys %global_stats) {
        if ( $global_key =~ /^Priority/ ) {
            ($global_kw = $global_key) =~ s/Priority_//;
            $average = sprintf("%.1f",($global_stats{$global_key} / $global_stats{pr_cnt}) * 100);
            push @{ $data[0] }, "$global_kw $average%";
            push @{ $data[1] }, "$global_stats{$global_key}";
            $percent{$global_key} = "$average%";
        }
    }
    &create_pie_chart("Percentage by Priority","${img_dir}/priority_chart_${file_name}.png");
    $charts{priority_chart}="./images/priority_chart_${file_name}.png";
    undef(@data);
    foreach my $global_key (keys %global_stats) {
        if ( $global_key =~ /^Severity/ ) {
            ($global_kw = $global_key) =~ s/Severity_//;
            $average = sprintf("%.1f",($global_stats{$global_key} / $global_stats{pr_cnt}) * 100);
            push @{ $data[0] }, "$global_kw $average%";
            push @{ $data[1] }, "$global_stats{$global_key}";
            $percent{$global_key} = "$average%";
        }
    }
    &create_pie_chart("Percentage by Severity","${img_dir}/severity_chart_${file_name}.png");
    $charts{severity_chart}="./images/severity_chart_${file_name}.png";
    undef(@data);

# HTML Section
    open (HTMLPAGE, "> $html_file") || die "Can't open File $html_file: $!\n";
    print HTMLPAGE "
    <HTML>
    <HEAD>
    <META HTTP-equiv=\"Content-Type\" content=\"text/html; charset=windows-1252\">
    <META name=\"Description\" content=\"Broadcom GNATS Weekly Report for $database\">
    <META name=\"Broadcom, GNATS\" content=\"Broadcom GNATS Weekly Report for $database\">
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
    <TABLE ALIGN=\"left\" BORDER=0 WIDTH=675 CELLSPACING=3>
      <TR><TD><H1><P ALIGN=CENTER>GNATS Weekly Report for $database $today</P></H1></TD></TR>
      <TR><TD BGCOLOR=\"CCCCCC\" COLSPAN=3>Database Statistic</TD></TR>
      <TR><TD><IMG SRC=\"$charts{daily_graph}\" ALT=\"Daily Graph\"><BR></TD></TR>
      <TR><TD BGCOLOR=\"CCCCCC\" COLSPAN=3></TD></TR>
      <TR><TD>Total Number of Problem Reports (PR) $global_stats{pr_cnt}</TD></TR>
      <TR><TD ALIGN=LEFT VALIGN=TOP>
        <TABLE BORDER=0 CellSpacing=5>
          <TR><TD ALIGN=LEFT VALIGN=top>
            <TABLE BORDER=1 CellSpacing=0 WIDTH=\"100\">
    ";
    print HTMLPAGE "<TR><TD BGCOLOR=\"CCCCCC\" COLSPAN=3>Number of PRs by State<BR></TD></TR>\n";
    foreach my $global_key (sort { $global_stats{$a} cmp $global_stats{$b} } %global_stats) {
        if ( $global_key =~ /^State/ ) {
            ($global_kw = $global_key) =~ s/State_//;
            print HTMLPAGE "<TR><TD NOWRAP>$global_kw</TD><TD ALIGN=RIGHT>$global_stats{$global_key}</TD><TD>$percent{$global_key}</TD></TR>\n";
        }
    }
    print HTMLPAGE "<TR><TD COLSPAN=3><IMG SRC=\"$charts{state_chart}\" ALT=\"State chart\"><BR></TD></TR>
    </TABLE></TD>
    ";
    print HTMLPAGE "
    <TD VALIGN=top><TABLE BORDER=1 CellSpacing=0 WIDTH=\"100\">
    <TR><TD BGCOLOR=\"CCCCCC\" COLSPAN=3>Number of PRs by Priority<BR></TD></TR>\n";
    foreach my $global_key (keys %global_stats) {
        if ( $global_key =~ /^Priority/ ) {
            ($global_kw = $global_key) =~ s/Priority_//;
            print HTMLPAGE "<TR><TD NOWRAP>$global_kw</TD><TD ALIGN=RIGHT>$global_stats{$global_key}</TD><TD>$percent{$global_key}</TD></TR>\n";
        }
    }
    print HTMLPAGE "<TR><TD COLSPAN=3><IMG SRC=\"$charts{priority_chart}\" ALT=\"Priority chart\"><BR></TD></TR>
    </TABLE></TD>
    ";
    
    print HTMLPAGE "
    <TD VALIGN=top><TABLE BORDER=1 CellSpacing=0 WIDTH=\"100\">
    <TR><TD BGCOLOR=\"CCCCCC\" COLSPAN=3>Number of PRs by Severity<BR></TD></TR>\n";
    foreach my $global_key (keys %global_stats) {
        if ( $global_key =~ /^Severity/ ) {
            ($global_kw = $global_key) =~ s/Severity_//;
            print HTMLPAGE "<TR><TD NOWRAP>$global_kw</TD><TD ALIGN=RIGHT>$global_stats{$global_key}</TD><TD>$percent{$global_key}</TD></TR>\n";
          }

    }
    print HTMLPAGE "<TR><TD COLSPAN=3><IMG SRC=\"$charts{severity_chart}\" ALT=\"Severity chart\"><BR></TD></TR>
    </TABLE></TD>
    </TR></TABLE>
    ";

# Categories stats
    print HTMLPAGE "<TR><TD BGCOLOR=\"CCCCCC\" COLSPAN=3></TD></TR>";
    print HTMLPAGE "
    <TR><TD>Total Number of Categories $global_stats{cat_cnt}<BR>
    Number of active categories (with PRs filed) $global_stats{active_cat}<BR>
    Number of in-active categories (with no PRs filed) $global_stats{inactive_cat}<BR>
    </TD></TR>
    <TD ALIGN=LEFT><BR>
        <TABLE BORDER=1 CellSpacing=0>
        <TR><TD BGCOLOR=\"CCCCCC\" COLSPAN=2>Number of PRs per Category<BR>Please click on to the Category<BR> name to go to the detail section of each category</TD></TR>
    ";
    my $global_key;
    foreach $global_key (sort keys %global_stats) 
    {
        if ($global_key =~ /^Category/ ) {
            ($global_kw = $global_key) =~ s/Category_//;
            if (! grep {/$global_kw/} @empty_cat_list ) {
                print HTMLPAGE "<TR><TD NOWRAP><A HREF=\"\#$global_kw\">$global_kw</A></TD><TD ALIGN=RIGHT>$global_stats{$global_key}</TD></TR>\n";
            }
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
#                dclrs             => ['cyan','lblue', 'green', 'orange', 'lpurple', 'red', 'yellow'],
                dclrs             => ['lblue', 'green', 'blue', 'red', 'lpurple', 'cyan', 'yellow'],
                text_space        => 5,
        );

        $graph->set_title_font(gdLargeFont);
        $graph->set_value_font(gdSmallFont);
        $graph->set_label_font(gdSmallFont);

        my $gd = $graph->plot(\@data);
        open(IMG, "> $OutFile") or die $!;
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
               # dclrs             => ['green','yellow', 'orange', 'blue'],
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

#        my $graph = GD::Graph::bars3d->new($graph_width, $graph_height);
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

main;
