#! /tools/perl/5.6.0/SunOS/bin/perl

use File::Basename;


if ($#ARGV < 1) {
        print "Usage: $0 {User Name} {input file with list of missing files} {admin Email}\n";	
        exit (1);
} else {
        $UserName=$ARGV[0];
        $myFile=$ARGV[1];
#        $myEmail=$ARGV[2];
}

#if (  $myEmail !~ /^[a-z]+\@broadcom.com$/ ) {
#	print "Invalid Email. Please try again\n";
#	exit 1;
#}

if (!-e "/home/$UserName") {
	print "/home/$UserName does not exists. Please try again\n";
	exit 1;
}



$RPTFILE = "/tmp/$UserName.$$";
# Create the restore.0706 no matter what
if (!-e  "/home/$UserName/restore.0706") {
	mkdir("/home/$UserName/restore.0706",0777) || die "Can not create restore.0706 directory: $!";
}
# Check to make sure the RESTORE0706 exists then cd into it
$RESTOREDIR="/home/$UserName/.snapshot/RESTORE0706";
#$RESTOREDIR="/projects/restore0706/$UserName";

if ( -e "$RESTOREDIR" ) {
	chdir("$RESTOREDIR");
} else {
	print "Warning, $RESTOREDIR does not exists\n. Please restore the data first\n";
	exit 1;
}
# Read in the input file. Use the Help Desk ticket listing to create the file
open(FILE, "$myFile") or die "Can't open input file: $!";
open(RPT, ">>$RPTFILE") or die "Can't open log file: $!";
while (<FILE>) {
	chop;
	($size,$link,$perm,$link2,$user,$grp,$dirsize,$month,$date,$time,$file) = split(/ +/);
# Strip off the /home/username part
	($Target = $file) =~ s/\/home\/$UserName\///;
#	print "$Target\n";
	if ( $date == 6 || $date == 7 ) {
# Skip synopsys cache file
		if ($file =~ /synopsys_cache/) {
			print "Synopsys cache file detected $file\n";
			print RPT "Synopsys cache file detected $file\n";
			next;
		}
		if ($file =~ /windows/) {
			print "Windows directory detected, restoring data to restore.0706 directory\n";
			print RPT "Windows directory detected, restoring data to restore.0706 directory\n";
			system("tar cf - $Target \| \(cd /home/$UserName/restore.0706; tar xf -\)");
			next;	
		}
		if ($file =~ /pc/) {
			print "Windows directory detected, restoring data to restore.0706 directory\n";
			print RPT "Windows directory detected, restoring data to restore.0706 directory\n";
			system("tar cf - $Target \| \(cd /home/$UserName/restore.0706; tar xf -\)");
			next;	
		}

# If this is a directory compares the directory contents with the restored data 
		if (-d "$file") {
			if (-e "$file") {
				print "Directory $file exists, comparing directory contents before restoring data\n";			
				print RPT "Directory $file exists, comparing directory contents before restoring data\n";			
				opendir(DIR,$Target) or die "Can't access directory /home/$UserName/.snapshot/RESTORE0706/$Target: $!";
				while (defined($TargetFile = readdir(DIR))) {
					next if $TargetFile =~ /^\.\.?$/;     # skip . and ..
					if (-e "/home/$UserName/$Target/$TargetFile") {
						print "File /home/$UserName/$Target/$TargetFile exists, restoring data to /home/$UserName/restore.0706\n";
						print RPT "File /home/$UserName/$Target/$TargetFile exists, restoring data to /home/$UserName/restore.0706\n";
						system("\(cd $RESTOREDIR && tar cf - $Target/$TargetFile\) \| \(cd /home/$UserName/restore.0706; tar xf -\)");
					} else {
						print "File /home/$UserName/$Target/$TargetFile does not exists, restoring data to /home/$UserName\n";
						print RPT "File /home/$UserName/$Target/$TargetFile does not exists, restoring data to /home/$UserName\n";
						system("tar cf - $Target/$TargetFile \| \(cd /home/$UserName; tar xf -\)");
					}
			
				}	
				closedir(DIR);	

			} else {
				print "Directory $file does not exists, restoring directory to /home/$UserName\n";
				print RPT "Directory $file does not exists, restoring directory to /home/$UserName\n";
				system("tar cf - $Target \| \(cd /home/$UserName; tar xf -\)");
			}
		$LASTDIR = "$file";
		} elsif (-f $file) {
			$DIRNAME = dirname($file);
			if ( $DIRNAME eq $LASTDIR ) {
				print "file $file has been processed in $LASTDIR\n";
				print RPT "file $file has been processed in $LASTDIR\n";
				next;
			}
			if (-e "$file") {
				print "File $file exists. Restoring file to restore.0706 directory\n";
				print RPT "File $file exists. Restoring file to restore.0706 directory\n";
				system("tar cf - $Target \| \(cd /home/$UserName/restore.0706; tar xf -\)");
			} else {
				print "File $file does not exists, restoring file to /home/$UserName\n";
				print RPT "File $file does not exists, restoring file to /home/$UserName\n";
				system("tar cf - $Target \| \(cd /home/$UserName; tar xf -\)");
			}
		}
	} else {
		print "File $file date is not from target date of 7/6 or 7/7\n";
		next;
	}
}
close RPT;
#if (-z "$RPTFILE") {
#	system("/usr/bin/mailx -s \"Data Recovery Report for User $UserName\" $myEmail \< $RPTFILE");
#
#}
