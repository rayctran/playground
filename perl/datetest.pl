#!/usr/local/bin/perl

use Date::Manip;
use Data::Dumper;

$myDate="04-12-2002";
#$myDate="4/12/2002";
$myDate="4-12-2002";
$firstDate="Aug 03 14:30:11 PST 2007";
$secDate="Feb 03 14:30:11 PST 2009";

#$delta_time{offset} = DateCalc($firstDate,$secDate,$err,1);
#($delta_time{yr},$delta_time{mo},$delta_time{w},$delta_time{d},$delta_time{hr},$delta_time{min},$delta_time{s}) = split (/:/,$delta_time{offset});
#$delta_time{yr} =~ s/^\+|\-//;
#print Dumper(\%delta_time);


#print "$delta_time{offset}}\n";
#$delta_time{age} = Delta_Format($delta_time{offset},2,"%dt");
#print "$delta_time{age}\n";

#$firstDate="Jan 03 14:30:11 PST 2009";
#$secDate="Feb 14 14:30:11 PST 2009";
$firstDate="Aug 03 14:30:11 PST 2008";
$secDate="Feb 03 14:30:11 PST 2009";
$delta_time{offset} = DateCalc($firstDate,$secDate,$err,1);
($delta_time{yr},$delta_time{mo},$delta_time{w},$delta_time{d},$delta_time{hr},$delta_time{min},$delta_time{s}) = split (/:/,$delta_time{offset});
print "$delta_time{offset}}\n";
$delta_time{age} = Delta_Format($delta_time{offset},2,"%dt");
print "$delta_time{age}\n";
print Dumper(\%delta_time);

#
#$firstDate="Feb 01 14:30:11 PST 2009";
#$secDate="Feb 19 14:30:11 PST 2009";
#print "At least 3 weeks\n";
#$delta_time{offset} = DateCalc($firstDate,$secDate,$err,1);
#print "$delta_time{offset}}\n";
#$delta_time{age} = Delta_Format($delta_time{offset},2,"%dt");
#print "$delta_time{age}\n";
