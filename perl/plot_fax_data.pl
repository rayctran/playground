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

if ($#ARGV < 0) {
        print "Usage: $0 {mod_usage}/{fail}/{queue}\n (optional date in dd-mm-yyyy format)\n";
	print "Example: $0 mod_usage 01-03-2002\n";
        exit (1);
} else {
        $do_what=$ARGV[0];
	$myDate=$ARGV[1];
}

if ( "$myDate" eq "" ) {
	$myDate = &UnixDate(`date`,"%d-%m-%Y");
}

###
# Check date format
#**
if ( $myDate =~ /^\d{2}-\d{2}-\d{4}$/ ) {
	$pass=1;	
} else {
	print "wrong date format. The date format should be DD/MM/YYYY\n";
	exit 1;
}

#Universal usage log file
$Graphs_dir="/tools/isofax/public_html/graphs";

#######
# Modem usage section
# Extract data into @data array to be used in the plot section
#######
if ( "$do_what" eq "mod_usage" ) {
	$LogFile="/tools/isofax/work/modem_usage/usage-${myDate}";
	$GraphFile="${Graphs_dir}/usage_${date}.png";
	@TimeTemplate = (
			"5:00-6:00", 
			"6:00-7:00", 
			"7:00-8:00", 
			"8:00-9:00", 
			"9:00-10:00", 
			"10:00-11:00", 
			"11:00-12:00", 
			"12:00-13:00", 
			"13:00-14:00", 
			"14:00-15:00", 
			"15;00-16:00", 
			"16:00-18:00", 
			"18:00-19:00", 
			"19:00-20:00", 
			"20:00-21:00", 
			"21:00-22:00", 
			"22:00-23:00", 
			"23:00-24:00",
		);

	open (MYKAKA, "$LogFile") or print "Die" and die;
	$recno = 0;
	while (<MYKAKA>) {
		chop($_);
		next if (/^$/);
#		print "This is the line $_\n";
		if (/$date/) {
			($hexa,$time,$date) = split (' ', $_);		
#			print "time $time\n";
		}
		if (/ttya000/) {
			($ttya000, $ttya000_usage) = split ("==>", $_);
#			print "ttya000 $ttya000_usage\n";
		}
		if (/ttya001/) {
			($ttya001, $ttya001_usage) = split ("==>", $_);
#			print "ttya001 $ttya001_usage\n";
		}
		if (defined $ttya001) {
			$recno++;
			push(@TempData,"$time->$ttya000_usage->$ttya001_usage");
			undef $ttya001;
		} 
	} 
	close (MYKAKA);
	$found = 0;

	for($i=0;$i< scalar(@TimeTemplate); $i++) {
	#       	print "position $i for item $TimeTemplate[$i]\n";
		foreach $findit (@TempData) {
			if ( $findit =~ /$TimeTemplate[$i]/ ) {
		#		print "$findit\n";
				($time, $ttya000, $ttya001) = split (/-> */, $findit);
		#		print "$time\n";
		        	$found = 1;
		#		print "found column $i row 2 should be $ttya001\n";
				last;
			}

		}
		if ( $found == 0 ) {
			#print "running not found\n";
			$data[0]->[$i] = "$TimeTemplate[$i]";
			$data[1]->[$i] = 0;
			$data[2]->[$i] = 0;
		} else {
			#print "running found\n";
			$data[0]->[$i] = $TimeTemplate[$i];
			$data[1]->[$i] = $ttya000;
			$data[2]->[$i] = $ttya001;
			$found = 0;
		}
	}

	# Define data for plot
	$xSize=500;
	$ySize=800;
	$x_label="Time span";
	$y_label="Minutes";
	$title="Modem Usage";
	$y_max_value=3600;
	$y_min_value=0;
	$y_tick_number=30;
	$y_label_skip=2;
	$bar_width=50;
	$bar_spacing=5;
	$long_ticks=1;
	$x_labels_vertical=1;
	$bar_depth=5;
	$Legend="Modem 1, Modem 2, Modem 3";
}



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
open(IMG, '>$GraphFile') or die $!;
binmode IMG;
print IMG $gd->png;
close IMG;


