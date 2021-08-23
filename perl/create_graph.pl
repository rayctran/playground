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
