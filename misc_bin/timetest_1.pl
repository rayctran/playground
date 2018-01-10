#!/usr/bin/perl

use lib './lib';
use Date::Manip;

$date = ParseDate("now");

$min_from_now = DateCalc("$date","+900 secs");

$flag=Date_Cmp($min_from_now,$date);

if ($flag<0) {
    print "$min_from_now is earlier then $date\n";
} elsif ($flag>0) {
    print "$min_from_now is later then $date\n";
}


