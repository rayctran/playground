#!/tools/perl/5.6.0/SunOS/bin/perl

use Date::Manip;

$StartDate = "12/20/2003 4:34 PM";
$EndDate = "03/31/2004";
$mydate = &UnixDate($StartDate,"%a %b %e %H:%M:%S %Z %Y");
print "$mydate\n";

#$MyStartMonthName = &UnixDate($StartDate, "%B");
#$MyEndMonthName = &UnixDate($EndDate, "%B");
#$MyStartYear = &UnixDate($StartDate, "%Y");
#$MyEndYear = &UnixDate($EndDate, "%Y");

#print "$MyStartMonthName, $MyStartYear\n";
#print "$MyEndMonthName, $MyEndYear\n";

#$myRange = DateCalc($StartDate,$EndDate,\$ERR,1);
#($y,$m,$w,$d,$hr,$min,$sec) = split (/:/, $myRange);
#print "$myRange\n";
#print "year=$y, month=$m, week=$w, day=$d $hr:$min:$sec\n";

#$mycomp = Date_Cmp($EndDate,$StartDate);
#print "$mycomp\n";

