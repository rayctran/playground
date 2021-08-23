#!/usr/local/bin/perl
#
# Goal: Script takes an integer argument n, and compresses the 
#       directories Build_YYYY_MM_*, where n is the number of months
#       before the current month. n must be an integer between 1 and 12. 
#
#       e.g. if it's April, and n=3, it would compress all the January
#            builds. 
# 
#  djo 04/01/2002
#  Modification
#  Changed script to execute from single directory structure, locate all
#  build directories and do the compression for each
#  rct 12/09/2002

use Date::Manip;
use File::Find;
use Data::Dumper;

# get builddir and #months back to compress

($#ARGV == 1 ) or die "zipbuild.pl builddirectory #months_back\n";

$TopBuildDir = $ARGV[0];
$n_months_back = $ARGV[1];
$Email_List = "feltham\@broadcom.com";
#$Email_List = "raytran\@broadcom.com";
#print "$n_months_back\n";

if ( -e $TopBuildDir && -w $TopBuildDir) {
   } else {
      die "TopBuildDir does not exist or not writeable\n"; 
}
if ($n_months_back >= 13) {
   die "N must be between 1 and 12\n";
}

chop($MyDate=`date`);

# get current month and year
    $Today_date = ParseDate("today");
#    print "today is $Today_date\n";

# get target date based on the $n_months_back
    $Target_date = DateCalc("$Today_date","-  $n_months_back months", \$err);
    $Target_month = UnixDate(ParseDate($Target_date),"%f");
#    print "target date is $Target_date\n";
#    print "Target month is $Target_month\n";

#
# Build a muti-dimensional array of the projects and the build directory that will be archived
# only build directory in the format of YYYY_MM_DD will be scan for the specified date
# 
# %Compress_List = (
#	/projects/engineering/cabu/BuildRoot/xme_1.4 => [ "2002_10_11", "2002_10_12],
#	/projects/engineering/cabu/BuildRoot/xme_1.5 => [ "2002_09_02", "2002_12_24],
# ) 
#
@Projects_List = ();
opendir(TOPDIR, $TopBuildDir) or die "Can't access $TopBuildDir: $!";
while (defined ($ProjectDir = readdir TOPDIR)) {
	next if $ProjectDir =~ /^\.\.?$/; # skip . and ..
	$FullProjPath="${TopBuildDir}/${ProjectDir}";
#	push(@Projects_List, $FullProjPath);
	@BuildDir_List = ();
	#chdir("$FullProjPath");
	opendir(SUBDIR, $FullProjPath) or die "Can't access $FullProjPath: $!";	    
	while (defined ($BuildDir = readdir SUBDIR)) {
#		print "$BuildDir\n";
		if ($BuildDir =~ /^\d{4}_\d{2}_\d{2}$/) {
#			print "pass date check\n";
			($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat ("${FullProjPath}/${BuildDir}");
			$BuildDirMonth = UnixDate(ParseDateString("epoch $mtime"),"%f");
#			$BuildDirDate = ParseDateString("epoch $mtime");
#			print "$mtime = $BuildDirDate\n";
#			$Result = Date_Cmp($BuildDirDate,$Target_date);			
			if ($Target_month == $BuildDirMonth) {
#				print "$BuildDirDate is older than $Target_date\n";
				push(@BuildDir_List, $BuildDir); 
			
			 }
		}
	
	}
	if ( $#BuildDir_List > 0 ) {
		$Compress_List{$FullProjPath} = [ @BuildDir_List ];
	}
}
closedir(TOPDIR);

#print Dumper(\@Projects_List);
#print Dumper(\%Compress_List);

open(LOG, ">/tmp/archive_log.$$") || die "Can't open log file /tmp/archive_log.$$: $!\n";
print LOG "Archive Log $MyDate\n";

# Process List
# Create compress directory as we go
foreach $Proj ( keys %Compress_List ) {
	$arch_dir = $prev_arch_dir = ();
	if ( $#{$Compress_List{$Proj}} > 0 ) {
#		print "$Proj\n";
		chdir("$Proj");
		print LOG "Project directory $Proj\n";
		foreach $Builddir ( 0 .. $#{ $Compress_List{$Proj} } ) {
			($year,$month,$date)= split(/_/, $Compress_List{$Proj}[$Builddir]);
			$arch_dir = "${year}_${month}_compressed";
			if ( $arch_dir ne $prev_arch_dir ) {
				mkdir ("$arch_dir",0777) || die "Can't create archive director $arch_dir: $!\n";	
#				print "create archive directory $arch_dir\n";
			}
#			system("pwd");
			system("/tools/bin/tar czf ${arch_dir}/${Compress_List{$Proj}[$Builddir]}.tar.gz $Compress_List{$Proj}[$Builddir]");
			print LOG "$Compress_List{$Proj}[$Builddir] archived to subdirectory $arch_dir\n";
			$prev_arch_dir = $arch_dir;
		}
	}
}

print LOG "Build directory have been compressed. - Please delete\n";
close(LOG);

###
# send Email notification
###
system("mailx -s \"Build Directories Compressed\" $Email_List < /tmp/archive_log.$$");
system("rm /tmp/archive_log.$$");
