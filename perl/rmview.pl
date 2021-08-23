#!/tools/perl/5.6.0/SunOS/bin/perl
#
# Removes views using an input file for the list of views to remove.
# the format of the file should be from the output of the "cleartool lsview -s" command
# Author: Ray Tran 
# Date: 12/28/2002
########################


if ($#ARGV < 0) {
        print "Usage: $0 {ClearCase Region} {input file}\n";
        print "Example: $0 IrvineNT /tmp/myviewlist\n";
        exit (1);
} else {
        $REGION=$ARGV[0];
        $INFILE=$ARGV[1];
}

$CT="/opt/rational/clearcase/bin/cleartool";
$LOGFILE="/tmp/rmviews.log";
chop($HOST=`hostname`);

# Checking region
$REGFOUND=0;
open(LSREG,"$CT lsreg |") or die "Can't execute command: $!\n";
while(<LSREG>) {
	chop($_);
	if ( "$_" eq "$REGION") {
		print "Found\n";
		$REGFOUND=1;
	}

}

if ( $REGFOUND == 0 ) {
	print "Invalid region for server $HOST. Please try again\n";
	exit (1);
}

open(LOGIT,">>$LOGFILE") or die "Can't open log file: $!\n";
open(MYFILE, "$INFILE") or die "Can't open input file: $!\n";
while(<MYFILE>) {
	$VIEW=$_;
	chomp($VIEW);
	open(CT, "$CT lsview -l -region $REGION $VIEW|") or die "Can't execute cleartool lsview: $!\n"; 
	while (<CT>) {
		chomp($_);
		if (/^View on host:*/) {
			($TAG,$VIEWHOST) = split(/\: /);
		}
		if (/^View server access path:*/) {
			($TAG,$VIEWPATH) = split(/\: /);
			$Log="Removing view $VIEW on $VIEWHOST region $REGION located in $VIEWPATH\n";
        		print LOGIT "$Log";
		}
		if (/^View uuid:*/) {
			($TAG,$UUID) = split(/\: /);
			$Log=`$CT rmview -force -avobs -uuid $UUID`;
			#$Log=`echo $CT rmview -force -avobs -uuid $UUID`;
        		print LOGIT "$Log";
			$Log=`$CT unregister -view -uuid $UUID`;
			#$Log=`echo $CT unregister -view -uuid $UUID`;
        		print LOGIT "$Log";
		}
	}
#			$Log=`$CT rmtag -view -all $VIEW`;
			$Log=`echo $CT rmtag -view -all $VIEW`;
        		print LOGIT "$Log";
}

close(LOGIT);
#system("mailx -s \"Views Removed from $HOST\" raytran\@broadcom.com < $LOGFILE");
system("mailx -s \"Views Removed from $HOST\" jennifer\@broadcom.com,cttok\@broadcom.com,raytran\@broadcom.com < $LOGFILE");
system("rm $LOGFILE");
