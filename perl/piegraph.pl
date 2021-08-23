#!/tools/perl/5.6.0/SunOS/bin/perl

# Script file to create a detail plot of the Fax data
# Data to plot - based on input
# Modem usage - daily graph of modem usage
# Number of successful faxes V.S. Call Length for each fax
# Number of un-successful faxes per hour


use GD;
use GD::Text;
use Data::Dumper;
use Date::Manip;

$myDate="";
@DATA= ( 
	["One 15%", "Two 15%", "Three 70%" ], 
	[15, 15, 70] 
	);

&create_pie_chart("Success/Failed","/home/raytran/public_html/Experimental/kaka1.png");

####
# Graph Section
####
sub create_pie_chart {
        my($Title,$OutFile) = @_;
        use GD::Graph::pie;
        use GD::Graph::Data;

        my $graph = GD::Graph::pie->new(200, 200);

        $graph->set(
                title             => $Title,
                transparent       => 0,
                legend_placement  => 'BC',
                bgclr             => 'white',
                fgclr             => 'black',
                pie_height        => 15,
                start_angle       => 15,
        	dclrs             => ['blue','red','orange','green',],
        );

        $graph->set_title_font(gdLargeFont);
        $graph->set_value_font(gdSmallFont);
#        $graph->set_value_font(gdMediumBoldFont);

        my $gd = $graph->plot(\@DATA);
        open(IMG, "> $OutFile" ) or die $!;
        binmode IMG;
        print IMG $gd->png;
        close IMG;
}
