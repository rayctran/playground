#!/tools/perl/5.6.0/SunOS/bin/perl

use Date::Manip;

#$Date_1 = "Apr 17 12:05:31 2002";
#$Date_2 = "Apr 22 12:06:38 2002";
#$Date_1 = "Mon Apr 22 12:06:38 2002";
#$Date_2 = "Mon Apr 22 12:06:38 2002";

#$STRING = "State-Changed-When: Fri Jun  7 09:43:57 2002\n";
#$STRING2 = ">Arrival-Date:   Sat May 25 08:38:27 PDT 2002\n";

#if ($Date_1 =~ /\w+\s\w+\s\d+\s([0-2][0-9]):*:*/) {
#	$myDate = $1;
#	print "my date $myDate\n";
#}

# Compares dates
$Date_1 = "Fri Jun  7 2002";
$Date_2 = "Sat May 25 08:38:27 PDT 2002";
#$Date_2 = "";
#
#$FLAG = Date_Cmp($Date_1,$Date_2);
#print "$Date_1 against $Date_2 is  $FLAG\n";
#if ( $FLAG ne -1 ) {
#   print "$Date_1 is after $Date_2\n";
#

#$FLAG = Date_Cmp($Date_2,$Date_1);
#rint "$Date_2 against $Date_1 is  $FLAG\n";
#f ( $FLAG ge 0 ) {
#   print "$Date_2 is before $Date_1\n";
#
#FLAG = Date_Cmp($Date_1,$Date_1);
#rint "$Date_1 against $Date_1 is  $FLAG\n";
#if ( $FLAG ge 0 ) {
#    print "$Date_1 is before $Date_1\n";
#}
#
#$NewDate = "01/19/2003";
#$DateConv=&UnixDate("$NewDate","%d-%b-%Y\n");
#$CHECKDATEA=ParseDate($DateConv);
#print "$CHECKDATEA\n";
#print &Unixtate("$NewDate","%a %b %d\n");
#print &UnixDate("$NewDate", "%a, %d %b\n");
#print &UnixDate("today", "today %a, %d %b\n");
#print &UnixDate("tomorrow", "tomorrow %a, %d %b\n");
#
#print &UnixDate("$NewDate", "month name is %b\n");
#
#print &UnixDate("Yesterday", "month name is %b\n");
#print &UnixDate("Yesterday", "%Y");


# Get the delta between two dates
#$delta = &DateCalc($Date_1,$Date_2,\$ERR,1);
#$days = &UnixDate($delta,"%d");
#($a,$b,$c,$d,$hr,$min,$sec) = split (/:/, $delta);
#print "$delta\n";
#print "$d $hr:$min:$sec\n";
#print "days are $hours\n";
#exit;


#$Date = ParseDate("11/31/2003");
#print "None $Date\n";

#$StartDate = "01/20/2004";
#$EndDate = "03/31/2004";

#$MyStartMonthName = &UnixDate($StartDate, "%B");
#$MyEndMonthName = &UnixDate($EndDate, "%B");
#print "$MyStartMonthName\n";
#print "$MyEndMonthName\n";
#$myRange = DateCalc($StartDate,$EndDate);
#print "$myRange\n";

#$MyStartDayName = &UnixDate($StartDate, "%w");
#$MyEndDayName = &UnixDate($EndDate, "%w");
#print "$MyStartDayName\n";
#print "$MyEndDayName\n";

print "YYYY " . &UnixDate(today,"%Y") . "\n"; 

exit;


#####


#$Date_1="2004-01-15";
#$Date_1="01/15/2004";

# Extract only the date from a date string
#$Date=&UnixDate("$Date_1","%b %d %Y");
#$Date=&UnixDate($Date_1,"%F");
#$Time=&UnixDate($Date_1,"%T");
#print "$Date\n";
#print "$Time\n";
#######


# 
$Time_a = &UnixDate($Date_1,"%B");
#$Time_b = &UnixDate($Date_2,"%T");
#print "$Time_a\n";
#print &DateCalc(&UnixDate($Date_1,"%T"),&UnixDate($Date_2,"%T")),"\n";

#$today = &UnixDate(`date`,"%d-%m-%Y");
#$today = &UnixDate(`date`,"%Y_%m");
#print "$today\n";

#$File = "$today.log";

#open (KAKA, "< $File") ;
#while (<KAKA>) {
#    print $_;
#}

#$Date_1 = "17:48:30";
#$Date_2 = "18:07:16";

#$delta = &DateCalc($Date_1,$Date_2,\$err);
#($a,$b,$c,$d,$hr,$min,$sec) = split (/:/, $delta);
#print "$delta\n";
#print "$hr:$min:$sec\n";
#$sec =($hr * 3600) + ($min * 60) + $sec;
#print "$sec\n";
#$DATE="3/2/2002";

#$delta = &DateCalc($Date_1,$Date_2,\$err);
#($a,$b,$c,$d,$hr,$min,$sec) = split (/:/, $delta);
#print "$delta\n";
#print "$hr:$min:$sec\n";
#$nextday = &DateCalc("$Date_1","+ 8hours");
#print "$nextday\n";
#print $date = &UnixDate($Date_1,"%d-%m-%Y_%H:%M:%S");

$time = "+1:23.7";
$delta = &ParseDateDelta($time);
print "delta $delta\n";
$sec = &Delta_Format($time, 0, '%st');
print "sec $sec\n";
