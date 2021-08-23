#!/usr/local/bin/perl

my ($sec, $min, $hours, $day, $month, $year) = (localtime)[0..5];
print "$hours\n";
