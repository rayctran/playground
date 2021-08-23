#!/tools/perl/5.6.0/SunOS/bin/perl

use GD;
use GD::Text;
use Data::Dumper;
use Date::Manip;

$myDate="";

#Universal usage log file
$Graphs_dir="/home/raytran/p4workspace/ntsw";
$GraphFile="/home/raytran/public_html/tmp/ntsw_perf_com.png";
$LogFile_1="ntsw_perf_1";
$LogFile_2="ntsw_perf_2";

open (MYKAKA, "$LogFile_1") or print "Can't open log file: $!\n";
while (<MYKAKA>) {
    ($date,$time,$data,$no_of_file)=split(/;/);
    push(@{ $data[0] }, "$date");
    push(@{ $data[1] }, "$time");
} 
close (MYKAKA);
open (MYKAKA, "$LogFile_2") or print "Can't open log file: $!\n";
while (<MYKAKA>) {
    ($date,$time,$data,$no_of_file)=split(/;/);
    push(@{ $data[2] }, "$time");
} 
close (MYKAKA);

&create_line_graph("NTSW File Sync Time Comparison","Date","Time","15","0","15","$GraphFile");

sub create_line_graph {
        my($title,$x_label,$y_label,$y_max_value,$y_min_value,$y_tick_number,$OutFile) = @_;
        use GD::Graph::linespoints;
        use GD::Graph::Data;
        my $graph_width = 900;
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
                dclrs             => ['blue', 'green','yellow', 'orange'],
               # dclrs             => ['light-blue','yellow', 'orange', 'blue'],
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
