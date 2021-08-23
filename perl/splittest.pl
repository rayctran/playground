#!/usr/local/bin/perl

use Data::Dumper;

open(FILE,"files.txt") or die "Can't open files.txt. Please dump out the files first \n";
while (<FILE>) {
    chop;
    s/^\.\///;
    ($cat,$pr) = split(/\//, $_);
    next if ($cat =~ /gnats-adm|gnats-queue|bcm4710-linux.ORIG/);
    if (!$seen{$pr}) {
#	print "Have not seen this PR - $pr\n";
        $seen{$pr}=1;
	$tracked{$pr}=$cat;
    } else {
        print "Duplicate PR $pr. Already exists in $tracked{$pr}\n";
    }
}
