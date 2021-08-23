#!/tools/perl/5.6.0/SunOS/bin/perl

use GD;
use GD::Graph::bars3d;
use GD::Text;
use Data::Dumper;
use Date::Manip;

# if no agrument is given assumes today's date

if ($#ARGV == 0) {
   	$myDate=$ARGV[0];   
} else {
	$myDate = &UnixDate(`date`,"%d-%m-%Y");
}

# Set Default input/output directories
$LogFile="/tools/isofax/work/modem_usage/usage-${myDate}";
$GraphFile="/tools/isofax/public_html/graphs/usage_${myDate}.png";

#Define time template from 5:00AM to 11:00PM
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
		"15:00-16:00", 
		"16:00-17:00", 
		"17:00-18:00", 
		"18:00-19:00", 
		"19:00-20:00", 
		"20:00-21:00", 
		"21:00-22:00", 
		"22:00-23:00", 
		"23:00-0:00",
	);


# Sanity check to make sure file exists
if ( (-e $LogFile) == 0 ) {
	print "File $LogFile does not exists. Please try again.\n";
	exit 1;
}

# Read the whole file into an array
open (LOGFILE, "$LogFile") or print "Die" and die;
while (<LOGFILE>) {
        push(@MyFile, $_);
}

# Calculates the modems devices and keep count
$modemcnt = 0;
foreach $k (@MyFile) {
	if ( $k =~ /^.*\/(.*?)\s*\=\=\>\s*(\d*)\s*\n$/ ) {
		if ( $modemnames =~ /$1/ ) {
			next;	
		} else {
			$modemnames = join " ", $modemnames, $1;
			$modemcnt++;
		}
	}
}

#print Dumper(\@MyFile);
#

$column = 0;
$matched = 0;
foreach $i (@TimeTemplate) {
	foreach $ifile (@MyFile) {
		if ( $matched == 1 )  {
			if ( $ifile =~ /^\n$/ ) {
		#		print "found blank line exit loop\n";
				last;
			} elsif ( $ifile =~ /^.*\/(.*?)\s*\=\=\>\s*(\d*)\s*$/ ) {
				push(@modemdata, $2);
			}	
		} else {
			if ( $ifile =~ /\s*$i\s*/ ) {
				($hexa,$time,$date) = split (' ', $ifile);
				push(@modemdata, $time);
				$matched = 1;
			}
		}
	}
		
	if ( $matched == 0 ) {
		$data[0]->[$column] = $i;
		for($m=1; $m < $modemcnt + 1; $m++ ) {
			$data[$m]->[$column] = 0;
		}
	} else {
		$data[0]->[$column] = "$time";
		for($m=1; $m < scalar(@modemdata); $m++) {
			$data[$m]->[$column] = $modemdata[$m];
		}
		undef $time;
		undef @modemdata;
		$matched = 0;
	}
	$column++;
}
#####
# Checks array's data
#####
#print Dumper(\@data);
#####

$title="Modem Usage Graph $myDate";
my $graph = GD::Graph::bars3d->new(700, 500);

$graph->set(
        x_label           => 'Time span',
        y_label           => 'Minutes',
        title             => $title,
        y_max_value       => '3600',
        y_min_value       => '0',
        y_tick_number     =>  30,
        y_label_skip      => 2,
        dclrs             => ['red','blue',],
        transparent       => 0,
        bar_width         => 50,
        bar_spacing       => 5,
        legend_placement  => 'BC',
        bgclr             => 'white',
	fgclr		  => 'black',
        long_ticks        => 1,
	x_labels_vertical => 1,
	bar_depth	  => 5,
);

$graph->set_title_font(gdLargeFont);
$graph->set_legend_font(gdLargeFont);
$graph->set_x_label_font(gdMediumBoldFont);
$graph->set_x_axis_font(gdMediumBoldFont);
$graph->set_y_label_font(gdMediumBoldFont);
$graph->set_y_axis_font(gdMediumBoldFont);
$graph->set_legend("Modem 1", "Modem 2", "Modem 3");

my $gd = $graph->plot(\@data);
open(IMG, "> $GraphFile") or die $!;
binmode IMG;
print IMG $gd->png;
close IMG;

#system("mv /tmp/plot.png $GraphFile");
