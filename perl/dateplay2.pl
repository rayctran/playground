#!/usr/local/bin/perl

use Date::Manip;

#$days = 7;
#$myDate = UnixDate("$myDate","%c");
#while ($days > 0) {
#    $start_date = DateCalc("today","-${days} days", \$err);
#    $end_date = DateCalc("$start_date","+1 day", \$err);
#    $start_date = UnixDate("$start_date","%c");
#    $end_date = UnixDate("$end_date","%c");
#    print "$start_date and $end_date\n";
#}
#continue {
#    $days--;
#}

#$myDate = UnixDate( DateCalc("today","-1 day",\$err), "%d");
$myDate =  DateCalc("today","-1 day",\$err);
$oneweekbefore = DateCalc("today","-7 days",\$err);
#$myDate = UnixDate("$myDate","%c");
print "$myDate\n$oneweekbefore\n";
