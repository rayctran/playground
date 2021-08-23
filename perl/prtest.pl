#!/tools/perl/5.6.0/SunOS/bin/perl
#
# DVT Gnats database fix script for V4 conversion
#
#
use Data::Dumper;
use IO::File;

$WORKDIR="/tools/gnats/v4/share/gnats/db-dvt.MIGRATED";


opendir(TOPDIR, $WORKDIR) or die "Can't access $WORKDIR: $!";
while (defined ($PRDIR = readdir TOPDIR)) {
	print "checking $PRDIR\n";
        next if $PRDIR =~ /^\.\.?$/; # skip . and ..
	next if -f;
	next if $PRDIR =~ /^gnats-adm$/; 
#	next if $PRDIR =~ /^gnats-queue$/; 
	next if $PRDIR =~ /^temp$/; 
#	next if $PRDIR =~ /^pending$/; 
	print "$PRDIR passed \n";
}
