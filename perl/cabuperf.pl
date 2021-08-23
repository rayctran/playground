#!/tools/perl/5.6.0/SunOS/bin/perl

use File::Basename;
use Mail::Sendmail;
use Date::Manip;

# To be used with MRTG
# $ARGV[0] - Which file to open
# $ARGV[1] - Which data to grab
# 1 - ping time to ccase-rmna-1
# 2 - ping time to fs-rmna-1
# 3 - checkout 3
# 4 - uncheckout
# 5 - ldx updates
# 6 - lsvtree pveblkeg.c
# 7 - lsvtree pveblkin.c
# 8 - lsbl ldx_hausware
# 9 - lsbl xme 

$MYYEAR=&UnixDate(`date`,"%Y");
$LOGDIR="/projects/ccase/cabuperf/${MYYEAR}";
$MYDATE=&UnixDate(`date`,"%y_%m_%d");

if ( $#ARGV < 0 ) {
    $Prompt=0;
    print "Usage: $0 log_file option\n";
    exit (1);
} else {
        $FILE=$ARGV[0];
        $OPTION=$ARGV[1];
}


open (LOGFILE, "$LOGDIR/$FILE") or print "Can't open log file $FILE: $!\n";
while (<LOGFILE>) {
	chop($_);
	if ( $_ =~ /^fs-rmna-01.ca.broadcom.com.*min\/avg\/max\/stddev.*=.*(\w*)\/(\w*)\/(\w*)\/(\w*).*ms$/ ) {
		print "$2\n";
	}

}

close(LOGFILE);
