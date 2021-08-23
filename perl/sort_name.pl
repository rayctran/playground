#!/tools/perl/5.6.0/SunOS/bin/perl

use Date::Manip;

$file="/home/raytran/bin/perl/trythis.pl";
$ctime=(stat("$file"))[10];
#$ctime=&ParseDate("epoch $ctime");
print "ctime is $ctime\n";

$warp=&DateCalc("$ctime","+ 8hours",\$err);
print $err;
$warp=&ParseDate($warp);
$now=&ParseDate(`date`);

print "warp time is $warp\n";
print "now is $now\n";

$newone = &DateCalc($now,$warp);
print "new one $newone\n";


$flag = &Date_Cmp($warp,$now);
print "$flag\n";
if ($flag < 0) {
	print "warp\n";
} elsif ($flag > 0) {
	print "now\n";
}


#print "$now\n";
#print "$modtime\n";
#print "check this ", scalar(localtime($modtime)), "\n";

$INPUT{'name'}="Ray Tran";
$INPUT{'fax'}="585-5871";
$INPUT{'to'} = "$INPUT{'name'}" . "/" . "$INPUT{'fax'}" . '<isofax@broadcom.com>';
print "$INPUT{'to'}\n";
