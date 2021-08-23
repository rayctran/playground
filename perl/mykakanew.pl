#!/tools/perl/5.6.0/SunOS/bin/perl

use GD::Graph::bars;
use GD::Graph::Data;

$date = "4\/24\/2002";
open (MYKAKA, "/tools/isofax/work/modem_usage/usage-24-04-2002") or print "Die" and die;
$recno = 0;
while (<MYKAKA>) {
	chop($_);
	next if (/^$/);
#	print "This is the line $_\n";
	if (/$date/) {
		($hexa,$time,$date) = split (' ', $_);		
#		print "time $time\n";
	}
	if (/ttyb/) {
		($ttyb, $ttyb_usage) = split ("==>", $_);
#		print "ttyb $ttyb_usage\n";
	}
	if (/ttya000/) {
		($ttya000, $ttya000_usage) = split ("==>", $_);
#		print "ttya000 $ttya000_usage\n";
	}
	if (/ttya001/) {
		($ttya001, $ttya001_usage) = split ("==>", $_);
#		print "ttya001 $ttya001_usage\n";
	}
	if (defined $ttya001) {
		$recno++;
		push(@captured,  {
			time	=> $time,
			ttyb	=> $ttyb_usage,
			ttya000	=> $ttya000_usage,
			ttya001	=> $ttya001_usage,
		});
		undef $ttya001;
	}
}

close (MYKAKA);

#######
#foreach ( @captured ) {
#	print "$_\n";
#}
#print $count = @captured;
#print "\n";
#print "$#captured\n";
for($i=0;$i< $#captured + 1;$i++) {
	push (@Time, $captured[$i]{"time"});
	push (@ttyb, $captured[$i]{"ttyb"});
	push (@ttya000, $captured[$i]{"ttya000"});
	push (@ttya001, $captured[$i]{"ttya001"});
       # print $captured[$i]{"time"},"\t",$captured[$i]{"ttyb"},"\t",$captured[$i]{"ttya000"},"\t",$data[$i]{"ttya001"},"\n";
}

my @data = (
	[@Time],
	[@ttyb],
	[@ttya000],
	[@ttya001]
);

#foreach (@ttyb) {
#	print "$_\n";
#}

#foreach (@data) {
#	print "$_\n";
#}

my $graph = GD::Graph::bars->new(500, 800);
$graph->set(
        x_label           => 'Time',
        y_label           => 'Hour',
        title             => 'Modem Usage Graph',
        y_max_value       => '3600',
        y_min_value       => '0',
        y_tick_number     => 5,
#        y_label_skip      => 2,
#        line_types        => [1,2,3],
        dclrs             => ['green','red','blue',],
        transparent       => 0,
#        line_width        => 2,
        bar_width         => 4,
        bar_spacing       => 2,
        legend_placement  => 'BC',
        bgclr             => 'white',
        long_ticks        => 1,
);

my $gd = $graph->plot(\@data);

open(IMG, '>myfile.png') or die $!;
binmode IMG;
print IMG $gd->png;
close IMG;

#my $data = GD::Graph::Data->new();
#$data->copy_from(\@data);
#$data->y_values($data);
