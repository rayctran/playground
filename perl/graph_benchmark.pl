#!/tools/perl/5.6.0/SunOS/bin/perl

use GD;
use GD::Graph::lines;
use GD::Text;
use Data::Dumper;
use Date::Manip;
use File::Basename;

# if no agrument is given assumes today's date

if ($#ARGV == 0) {
   	$LogFile=$ARGV[0];   
} else {
	print "No benchmark data file found\n";
	exit 1;
}

$myDate=&UnixDate(`date`,"%d-%m-%Y");

# Sanity check to make sure file exists
if ( (-e $LogFile) == 0 ) {
	print "File $LogFile does not exists. Please try again.\n";
	exit 1;
}

($File,$Dir,$Ext) = fileparse($LogFile,'\..*');
# Set Default input/output directories
$GraphFile="$File.png";

# Read the whole file into an array
open (LOGFILE, "$LogFile") or print "Die" and die;
while (<LOGFILE>) {
	next if /^\**$/;
	if ( /^Run time/ ) {
		$_ =~ /^.*\:\s(.*)$/;
		$Time = $1;
	#	print "$Time\n";
		$Date = &UnixDate($Time, "%d-%m-%Y_%H:%M:%S");
#		print "$Date\n";
		push @{ $data[0] }, $Date;
	}
	($Action, $Time) = split(/\:/);
	if ( $Action =~ /Version/ ) {
		push @{ $data[1] }, $Time;
	}
	if ( $Action =~ /^One checkout$/ ) {
		push @{ $data[2] }, $Time;
	}
	if ( $Action =~ /^One uncheckout$/ ) {
		push @{ $data[3] }, $Time;
	}
	if ( $Action =~ /^One checkin$/ ) {
		push @{ $data[4] }, $Time;
	}
			
	if ( $Action =~ /^Ten checkout$/ ) {
		push @{ $data[5] }, $Time;
	}
	if ( $Action =~ /^Ten lscheckout$/ ) {
		push @{ $data[6] }, $Time;
	}
	if ( $Action =~ /^Ten uncheckout$/ ) {
		push @{ $data[7] }, $Time;
	}
	if ( $Action =~ /^Ten checkin$/ ) {
		push @{ $data[8] }, $Time;
	}
	if ( $Action =~ /^Update view$/ ) {
		push @{ $data[9] }, $Time;
	}
	if ( $Action =~ /^One mkbranch$/ ) {
		push @{ $data[10] }, $Time;
	}
	
}


#####
#print Dumper(\@data);
#exit 0;
#####

$title="Modem Usage Graph $File";
#my $graph = GD::Graph::lines->new(1000, 500);
my $graph = GD::Graph::lines->new(900, 650);

$graph->set(
        x_label           => 'Date_Time',
        y_label           => 'Seconds',
        title             => "$title",
        y_max_value       => '200',
        y_min_value       => '0',
        y_tick_number     =>  5,
        y_label_skip      => 1,
        dclrs             => ['red','blue','purple','green','pink','orange','yellow','marine','cyan','dbrown'],
	line_width        => 2,
	line_types        => [1,1,1,1,1,1,1,1,1,1],
        transparent       => 0,
        legend_placement  => 'BC',
        bgclr             => 'white',
	fgclr		  => 'black',
        long_ticks        => 1,
	x_labels_vertical => 1,
	x_label_skip   	  => 2,
	axis_space	  => 5,
);

$graph->set_title_font(gdLargeFont);
$graph->set_legend_font(gdLargeFont);
$graph->set_x_label_font(gdSmallFont);
$graph->set_x_axis_font(gdSmallFont);
$graph->set_y_label_font(gdSmallFont);
$graph->set_y_axis_font(gdMediumBoldFont);
$graph->set_legend("Version", "co", "unco", "ci", "10_co", "10_lsco", "10_unco", "10_ci", "update_view", "mkbr");
# Checkouts
#$graph->set_legend("co", "10 co", "10_lsco", "10_unco", "10_ci", "update_view", "mkbr");
#$graph->set_legend("unco", "10_unco", "10_ci", "update_view", "mkbr");
#$graph->set_legend("ci", "10_ci", "10_ci", "update_view", "mkbr");
#$graph->set_legend("ver", "10_lsco", "update_view", "mkbr");
#$graph->set_legend("update_view", "mkbr");

my $gd = $graph->plot(\@data);
open(IMG, "> $GraphFile") or die $!;
binmode IMG;
print IMG $gd->png;
close IMG;
