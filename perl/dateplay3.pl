#!/usr/local/bin/perl

use Date::Manip;

my %AppConfig;

if ( $#ARGV < 0 ) {
    $AppConfig{end_date} = ParseDate("today");
} else {
    print "input is $ARGV[0]\n";
    $AppConfig{end_date} = ParseDate("$ARGV[0]");
}


$AppConfig{end_date} = DateCalc("$AppConfig{end_date}", "-1 day");
$AppConfig{start_date} = DateCalc("$AppConfig{end_date}", "-6 days");
$AppConfig{sd_rn} = UnixDate("$AppConfig{start_date}", "%m-%d-%Y");
$AppConfig{ed_rn} = UnixDate("$AppConfig{end_date}", "%m-%d-%Y");
$AppConfig{myweekno} = UnixDate("$AppConfig{start_date}", "%U");

print "One week span is date is $AppConfig{sd_rn} ending $AppConfig{ed_rn}\n";
print "This is week number $AppConfig{myweekno}\n";
