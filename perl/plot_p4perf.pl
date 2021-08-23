#!/tools/perl/5.6.0/SunOS/bin/perl

use GD;
use GD::Text;
use Data::Dumper;
use Date::Manip;

$myDate="";

#Universal usage log file
$Graphs_dir="/home/raytran/p4workspace/ntsw";
$GraphFile="/home/raytran/public_html/tmp/ntsw_perf.png";
$LogFile_1="perflog_1";
$LogFile_2="perflog_2";

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

# Define data for plot
$xSize=800;
$ySize=900;
$x_label="Date Time";
$y_label="Sync Minutes";
$title="Sync Time Tracking";
$y_max_value=25;
$y_min_value=0;
$y_tick_number=25;
$y_label_skip=0;
$bar_width=50;
$bar_spacing=5;
$long_ticks=1;
$x_labels_vertical=1;
$bar_depth=5;
$Legend="Sync time";



####
# Graph Section
####
use GD::Graph::bars3d;
use GD::Graph::Data;

my $graph = GD::Graph::bars3d->new($xSize, $ySize);

$graph->set(
        x_label           => $x_label,
        y_label           => $y_label,
        title             => $title,
        y_max_value       => $y_max_value,
        y_min_value       => $y_min_value,
        y_tick_number     => $y_tick_number,
        y_label_skip      => $y_label_skip,
#        line_types        => [1,2,3],
        dclrs             => ['red','blue',],
        transparent       => 0,
#        line_width        => 2,
        bar_width         => $bar_width,
        bar_spacing       => $bar_spacing,
        legend_placement  => 'BC',
        bgclr             => 'white',
	fgclr		  => 'black',
        long_ticks        => $long_ticks,
	x_labels_vertical => $x_labels_vertical,
	bar_depth	  => $bar_depth,
);
$graph->set_title_font(gdLargeFont);
$graph->set_legend_font(gdLargeFont);
$graph->set_x_label_font(gdMediumBoldFont);
$graph->set_x_axis_font(gdMediumBoldFont);
$graph->set_y_label_font(gdMediumBoldFont);
$graph->set_y_axis_font(gdMediumBoldFont);
$graph->set_legend($Legend);

my $gd = $graph->plot(\@data);
open(IMG, "> $GraphFile") or die $!;
binmode IMG;
print IMG $gd->png;
close IMG;
