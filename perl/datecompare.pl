#!/usr/local/bin/perl

use Date::Manip;

# Compares dates
#$Date_1 = "Jan  1 2007";
#$Date_2 = "Jan  31 2007";
$Date_1 = "01/01/2007";
$Date_2 = "01/31/2007";

$FLAG = Date_Cmp($Date_2,$Date_1);
#print "$Date_1 against $Date_2 is  $FLAG\n";
#if ( $FLAG ne -1 ) {
#   print "$Date_1 is after $Date_2\n";
#}

#$FLAG = Date_Cmp($Date_2,$Date_1);
#print "$Date_2 against $Date_1 is  $FLAG\n";
#if ( $FLAG ge 0 ) {
#   print "$Date_2 is before $Date_1\n";
#}

#$FLAG = Date_Cmp($Date_1,$Date_1);
#print "$Date_1 against $Date_1 is  $FLAG\n";
#if ( $FLAG ge 0 ) {
#    print "$Date_1 is before $Date_1\n";
#}

until ( $FLAG lt 0 ) {

    print "compare $Date_2 to $Date_1 - $FLAG\n";

    $Date_1 = DateCalc("$Date_1", "+ 1 day",\$err,2);
    $Date_1 = UnixDate("$Date_1","%m/%d/%Y");
    $test = UnixDate("$Date_1","%m-%d-%Y");
    print "$test\n";
    $FLAG = Date_Cmp($Date_2,$Date_1);
}

%DateParts=&break_up_date("$Date_1");
print "captured month is $DateParts{month}\n";
print "captured year is $DateParts{year}\n";

sub break_up_date {
    my ($incoming_date)= @_;
    my %dateparts;

    ($dateparts{month},$dateparts{day},$dateparts{year}) = split(/\//,$incoming_date);

    return %dateparts;
}
