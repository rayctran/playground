#!/tools/perl/5.6.0/SunOS/bin/perl
#
# DVT Gnats database fix script for V4 conversion
#
#
use Data::Dumper;
use IO::File;

$WORKDIR="/tools/GNATS/share/gnats/db-dvt.MIGRATED";
$DESTDIR="/tools/gnats/v4/etc/gnats/db-dvt";
#$DESTDIR="/projects/ccase_irva/gnatstest";


opendir(TOPDIR, $WORKDIR) or die "Can't access $WORKDIR: $!";
while (defined ($PRDIR = readdir TOPDIR)) {
        next if $PRDIR =~ /^\.\.?$/; # skip . and ..
	next if $PRDIR =~ /^gnats-adm$/; 
#	next if $PRDIR =~ /^gnats-queue$/; 
	next if $PRDIR =~ /^temp$/; 
#	next if $PRDIR =~ /^pending$/; 
	next if $PRDIR =~ /^*.tar.gz$/; 
	next if $PRDIR =~ /^*.txt$/; 
	if (!-e "${DESTDIR}/${PRDIR}") {
		print "${DESTDIR}/${PRDIR} doesn't exists , creating directory\n";
		mkdir("${DESTDIR}/${PRDIR}",0755) or die "Can't create directory ${DESTDIR}/${PRDIR}: $!";	
	}
	opendir(CATDIR, "${WORKDIR}/${PRDIR}") or die "Can't open ${WORKDIR}/${PRDIR}: $!";
	while (defined ($PR = readdir CATDIR)) {
		print "$PR\n";
        	next if $PR =~ /^\.\.?$/; # skip . and ..
		open(PRFILE, "${WORKDIR}/${PRDIR}/${PR}") or die "Can't open PR file ${WORKDIR}/${PRDIR}/${PR}: $!";	
		open(NEWPRFILE, ">>${DESTDIR}/${PRDIR}/${PR}") or die "Can't create the new PR file ${DESTDIR}/${PRDIR}/${PR}: $!";
		print "Converting file ${PRDIR}/${PR} to ${DESTDIR}/${PRDIR}/${PR}\n";
		while(<PRFILE>) {
			next if /^Fix for:/;
			if (/^Resolution: /) {
				print "Fixing sub field Resolution\n";
				($Field,$Value)=split(/:/);
				print NEWPRFILE "\>Resolution: $Value";
			} elsif (/^Cloned-To: /) {
				print "Fixing sub field Cloned-To\n";
				($Field,$Value)=split(/:/);
				print NEWPRFILE "\>Cloned-To: $Value";
			} elsif (/^Operating-System: /) {
				print "Fixing sub field Operating-System";
				($Field,$Value)=split(/:/);
				print NEWPRFILE "\>Operating-System: $Value";
			} elsif (/^http:/) {
				print "Fixing http link\n";
				s/gnatsweb.broadcom.com/gnatsweb.broadcom.com:8080/;
				print NEWPRFILE $_;	
			} elsif (/gnats-dvt/) {
				print "Fixing gnats-dvt address\n";
				s/gnats-dvt/gnats4-dvt/;
				print NEWPRFILE $_;	
			} elsif (/gnats-admin-dvt/) {
				print "Fixing gnats-admin-dvt address\n";
				s/gnats-admin-dvt/gnats4-admin-dvt/;
				print NEWPRFILE $_;	
			} else {
				print NEWPRFILE $_;	
			}
		}
		close(PRFILE);
		close(NEWPRFILE);

	}
}
