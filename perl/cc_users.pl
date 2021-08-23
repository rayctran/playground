#!/usr/local/bin/perl

use strict;
use Data::Dumper;

my ( %grp,@members,@all_members,@final_member, %seen );


#open (IN,"clearusers.lst") or die "Can't open file: $!\n";
open(IN,"ypcat group \| grep clearusers |");
while(<IN>) {
    ($grp{name},$grp{passwd},$grp{gid},$grp{mem}) = split(/:/);
    @members=split(/,/,$grp{mem});
    push(@all_members,@members);
}

my @final_members = grep { ! $seen{$_} ++ } @all_members;

print Dumper(@final_members);
print scalar(@final_members);
