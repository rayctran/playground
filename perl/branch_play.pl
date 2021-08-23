#!/tools/perl/5.6.0/SunOS/bin/perl

use strict;
use IO::File;
use Net::Gnats;
use Date::Manip;
use Mail::Sendmail;
use Data::Dumper;
use File::Basename;

my $env_file = "/home/raytran/bin/perl/branch_mapping.txt";
my ($env_v,$env_path,%env);

if ( !-e $env_file ) {
die "Error - environment mapping file $env_file does not exists\n. Exiting\n";
} else {
    open(EF,"$env_file") or die "Can't open environment file. $!\n";
    while(<EF>) {
       ($env_v, $env_path) = split(/\s/);
       $env{$env_v} = "$env_path";
    }
}

my $new_env = "dg018b";
my $kaka_env = "dg018b,de005, de0010";
my @newkaka = split(/,\s*/,$kaka_env);
foreach my $I (@newkaka) {
    print "$I\n";
    if (exists($env{"$I"})) {
        print "$I exists\n";
        print "$env{$I}\n";
        print "file name is ";
        print basename($env{$I});
        print "\npath name is ";
        print dirname($env{$I});
    }
}

#print Dumper(\%env);
