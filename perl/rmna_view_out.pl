#! /tools/perl/5.6.0/SunOS/bin/perl

use strict;
use Data::Dumper;

my ($prompt,$infile,@view_list,$view);
my ($server,$gpath,$hpath);

if ( $#ARGV < 0 ) {
    $prompt=0;
    print "Usage: $0 server option\n";
    exit (1);
} else {
        $infile=$ARGV[0];
}

my $CT="cleartool";

open(IF,"$infile") or die "Can't open file $info: $!\n";
while(<IF>) {
    chop;
    push(@view_list,$_);
}
close(IF);

foreach $view (@view_list) {
    open(VIEW_INFO,"$CT lsview -reg rmnaNT -l|") or die "Can't run lsview :$!\n";
    while(<VIEW_INFO>) {
        $server =~ /\s*Server host:\s(\w+)/;
        print "$server\n";
    }
}
