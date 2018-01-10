#!/usr/bin/perl -w
use POSIX qw(strftime);

$now = strftime "%Y%m%d_%H_%M_%S", localtime;
print "$now\n";

