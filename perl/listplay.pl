#!/tools/perl/5.6.0/SunOS/bin/perl

use GD::Graph::bars3d;
use GD::Graph::Data;
use Data::Dumper;

@TimeTemplate = ("5:00-6:00", "6:00-7:00", "7:00-8:00", "8:00-9:00", "9:00-10:00", "10:00-11:00", "11:00-12:00", "12:00-13:00", "13:00-14:00", "14:00-15:00", "15;00-16:00", "16:00-18:00", "18:00-19:00", "19:00-20:00", "20:00-21:00", "21:00-22:00", "22:00-23:00", "23:00-24:00");

# Number of element is
#$Element= $#Timespan + 1; # Count position 0
#for $i ( 0 .. $#Timespan ) {
#	print "$i\n";
#	print "\t element $i is [ @{$Timespan[$i]} ]\n";
#}
print "$Timespan->[0]\n";


#$date = "4\/25\/2002";
open (MYKAKA, "/tools/isofax/work/modem_usage/usage-25-04-2002") or print "Die" and die;
$recno = 0;
while (<MYKAKA>) {
	chop($_);
	next if (/^$/);
#	print "This is the line $_\n";
	if (/$date/) {
		($hexa,$time,$date) = split (' ', $_);		
#		print "time $time\n";
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
		push(@TempData,"$time->$ttya000_usage->$ttya001_usage");
		undef $ttya001;
	}
}
close (MYKAKA);
$found = 0;
#my @data = {
	#	[ ],
	#[ ],
	#[ ]
	#};
#for($i=0;$i< $#TimeTemplate + 1;$i++) {
for($i=0;$i< scalar(@TimeTemplate); $i++) {
	print "$i\n";
	#       	print "position $i for item $TimeTemplate[$i]\n";
	foreach $findit (@TempData) {
		if ( $findit =~ /$TimeTemplate[$i]/ ) {
		print "$findit\n";
		($time, $ttya000, $ttya001) = split (/-> */, $findit);
		#			print "$time\n";
		        $found = 1;
		#	print "found column $i row 2 should be $ttya001\n";
			last;
		}

	}
	if ( $found == 0 ) {
		print "running not found\n";
		#push (@Time, $TimeTemplate[$i]);
		#push (@Ttya000, 0);
		#push (@Ttya001, 0);
		$data[0]->[$i] = "$TimeTemplate[$i]";
		$data[1]->[$i] = 0;
		$data[2]->[$i] = 0;
		#push @{ $data[0] }, "$TimeTemplate[$i]";
		#push @{ $data[1]}, 0;
		#push @{ $data[2]}, 0;
	} else {
		print "running found\n";
		$data[0]->[$i] = $TimeTemplate[$i];
		$data[1]->[$i] = $ttya000;
		$data[2]->[$i] = $ttya001;
		#push @{ $data[0] }, "$TimeTemplate[$i]";
		#push @{ $data[1] }, $ttya000_time;
		#push @{ $data[2] }, $ttya001_time;
		$found = 0;
	}
}
print "data size is $#data\n";
print Dumper(@data);

@members = ("Yvette", "Jon", "Jason", "Kelsey", "Cerek", "Tristen", "Ayden");

$memberx = "Dad";
$item{input}->{firstname} = "Ray";
$item{input}->{lastname} = "Tran";
$item{input}->{family} = [@members];
push @{ $item{input}->{family} }, "$memberx";
print Dumper(%input);

@newmembers = @{ $item{input}->{family} };
$members = join("_",@newmembers);
print "members only $members\n";

print "my first name is $item{input}->{firstname}\n";
print "my last name is $item{input}->{lastname}\n";
print "@{ $item{input}->{family} }\n";

foreach (@newmembers) {
    print "listing $_\n";
}
