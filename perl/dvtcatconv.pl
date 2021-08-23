#!/tools/perl/5.6.0/SunOS/bin/perl
#
# Gnats database category remap script
#

use File::Copy;

$WORKDIR="/tools/gnats/v4/etc/gnats/db-dvt";
@CATDIRLIST=("BCM7020_Linux_Driver", "BCM7040_Software","BCM7041_Software","BCM7110_Linux_Driver","BCM7115_Linux_Driver","BCM7315_Linux_Driver","BCM7320_Linux_Driver","BCM7501_software","BCM7XXX_Linux_OS","BCM97031STRM_Linux","BRUTUS_Software","Hydra_Software","Linux_Software","Linux_Software_PVR_GUI","M-BME7110_Software","M-BME7115_Software","M-BME7315_Software","M-BME7320_Software","M-BME7328_Software","Venom-I_Software","Venom-II_Software");

foreach $CATDIR (@CATDIRLIST) {
	print "${WORKDIR}/${CATDIR}\n";
	system("mkdir ${WORKDIR}/${CATDIR}.new");
	opendir(MYCATDIR, "${WORKDIR}/${CATDIR}") or die "Can't open ${WORKDIR}/${CATDIR}: $!";
		while (defined ($PR = readdir MYCATDIR)) {
			next if $PR =~ /^\.\.?$/; # skip . and ..
			next if $PR =~ /^*.orig$/; # skip . and ..
                	print "Found PR $PR\n";
			open(PRFILE, "${WORKDIR}/${CATDIR}/${PR}") or die "Can't open PR file ${WORKDIR}/${CATDIR}/${PR}: $!";
                	open(NEWPRFILE, ">>${WORKDIR}/${CATDIR}.new/${PR}") or die "Can't create the new PR file ${WORKDIR}/${CATDIR}.new/${PR}: $!";		
			while(<PRFILE>) {
                        	if (/^\>Priority:\s+(high|medium)$/) {
                               		print "Changing Priority from $1 to low\n";
                               		s/$1/low/;
                               		print NEWPRFILE $_;
                        	} elsif (/^\>Severity:\s+(critical|serious)$/) {
                               		print "Changing Severity from $1 to non-critical\n";
                               		s/$1/non-critical/;
                               		print NEWPRFILE $_;
                        	} else {
                               		print NEWPRFILE $_;
                        	}
                	}
                	close(PRFILE);
                	close(NEWPRFILE);
		}
	close(MYCATDIR);
	system("mv ${WORKDIR}/${CATDIR} ${WORKDIR}/${CATDIR}.old");
	system("mv ${WORKDIR}/${CATDIR}.new ${WORKDIR}/${CATDIR}");
}
