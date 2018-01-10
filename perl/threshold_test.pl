#!/usr/bin/perl

use lib './include';
require "./include/lyonscg_functions.pl";

$threshold=5;
$date = ParseDate("now");
$myfile="/tmp/.raytran_tmp";



$mycode=threshold_control("$myfile","$threshold");

if ($mycode eq "red") {
    print "return code is  $mycode\n";
} elsif ($mycode eq "yellow") {
    print "return code is  $mycode\n";
}




