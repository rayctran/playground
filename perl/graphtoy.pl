#!/tools/perl/5.6.0/SunOS/bin/perl

#use GD::Graph::bars;
#use GD::Graph3d::bars;
use GD;
use GD::Text;
use GD::Graph;
use strict;


my $OutFile="/home/raytran/public_html/graphtest/usage.png";

my @data = ( 
  ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
  [    1,    2,    5,    6,    3,  1.5,    1,     3,     4],
  [    4,    7,    9,    3,    3.2,  1.0,    10,     3.4,    4.4],
  [ sort { $a <=> $b } (1, 2, 5, 6, 3, 1.5, 1, 3, 4) ]
);

my @data = (
  ["Monday","Tuesday","Wednesday","Thrusday","Friday"],
  [ 0, 7, 2, 1, 3 ],
  [ 0, 9, 12, 1, 2 ],
  [ 0, 4, 2, 3, 5 ]
);

my @legend = ("open","modified","closed");
&create_bar_graph("Test","date","No. of PRs",25,"$OutFile");


sub create_bar_graph {
        my($title,$x_label,$y_label,$y_max_value,$OutFile) = @_;
        use GD::Graph::bars3d;
        use GD::Graph::Data;
        my $graph_width = 450;
        my $graph_height = 350;

        my $graph = GD::Graph::bars3d->new($graph_width, $graph_height);
        $graph->set(
                x_label           => $x_label,
                y_label           => $y_label,
                title             => $title,
                y_max_value       => $y_max_value,
                y_min_value       => 0,
                y_tick_number     => 5,
                y_label_skip      => 0,
                dclrs             => ['blue','red','green'],
                transparent       => 0,
                bar_width         => 2,
                bar_spacing       => 3,
                legend_placement  => 'BC',
                bgclr             => 'white',
                fgclr             => 'black',
                long_ticks        => 1,
                x_labels_vertical => 1,
        );
        $graph->set_title_font(gdLargeFont);
        $graph->set_legend_font(['verdana','arial','gdSmallFont']);
        $graph->set_y_label_font(gdLargeFont);
        $graph->set_x_label_font(gdLargeFont);
        $graph->set_x_axis_font(gdTinyFont);
        $graph->set_y_axis_font(gdTinyFont);
        $graph->set_legend_font(GD::gdMediumBoldFont);
        $graph->set_legend(@legend);
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

sub create_pie_chart {
        my($Title,$OutFile) = @_;
        use GD::Graph::pie;
        use GD::Graph::Data;

        my $graph = GD::Graph::pie->new(225,225);

        $graph->set(
                title             => $Title,
                '3d'              => 1,
                transparent       => 1,
                legend_placement  => 'BC',
                bgclr             => 'white',
                fgclr             => 'black',
                pie_height        => 15,
                start_angle       => 28,
                dclrs             => ['cyan','lblue', 'green', 'orange', 'lpurple', 'red', 'yellow']
,
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


#####
# Ramana's data
#
#my $graph = GD::Graph::lines->new(600, 450);
#
#$graph->set(
#        x_label           => 'Estimated Stock Price $',
#        y_label           => 'Total Gain',
#        title             => 'Projected Gain (Grant Price : ' . $GRANT_PRICE . ' & Current Options : ' . commify($NUM_BASE_OPTIONS) . ')',
#        y_max_value       => $m,
#        y_min_value       => 0,
#        y_tick_number     => 8,
#        y_label_skip      => 2,
#        line_types        => [1,2,3,4],
#        dclrs             => ['black', 'green','red','blue'],
#        transparent       => 0,
#        line_width        => 3,
#        legend_placement  => 'BC',
#        bgclr             => 'white',
#        long_ticks        => 1,
#        x_number_format   => \&x_format,
#        y_number_format   => \&y_format,
#        x_tick_number     => $T,
#        x_min_value       => 0,
#        x_max_value       => $M,
#);
#
#sub x_format {
#        my $v = shift;
#        $v == $M ? $v . '  ' : $v;
#}
#
#sub y_format {
#        my $v = shift;
#        $_ = $v;
#        1 while ($v =~ s/(\d)(\d\d\d)(?!\d)/$1,$2/g);
#        '$' . $v;
#}
#
#$graph->set_legend("Current", "Choice 1(Base+Focal)", "Choice 2(Cancel/Regrant+Focal)
#", "Choice 3(Base+Focal+Topup)");

#my $gd = $graph->plot(\@data);

