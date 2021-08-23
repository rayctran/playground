#!/tools/bin/perl

use strict;
use Date::Manip;


if ($#ARGV < 0) {
        print "Usage: $0 file \n";
        exit (1);
} else {
        my $file=$ARGV[0];
}

my (%date);

open (KAKA, "$file") or die "Can't open file: $!\n";
while(<KAKA>) {
    chop($_);
    if (/^\s*(\d+)\\(\d+)\\(\d+)/) {
        $date{year} = $1;
        $date{month} = $2;
        $date{date} = $3;
    }
    if (!-e $date{year}) {
        system("mkdir $date{year}");
    }
    if (!-e "$date{year}/$date{month}") {
        system("mkdir $date{year}/$date{month}");
    }
    
#    open(OUT,">> $date{year}/$date{month}/$date{date}") or print "Can't open log file: $!\n";
    print "$_\n";  
}
close(KAKA);
close(OUT);
