#!/tools/perl/5.6.0/SunOS/bin/perl
#
# DVT Gnats database fix script for V4 conversion
#
#
use Data::Dumper;
use IO::File;

$WORKDIR="/tools/gnats/v4/etc/gnats/db-bse-clearcase.MIGRATED";
$DESTDIR="/tools/gnats/v4/etc/gnats/db-bse-sqa";
#$DESTDIR="/projects/ccase_irva/gnatstest";

opendir(TOPDIR, $WORKDIR) or die "Can't access $WORKDIR: $!";
while (defined ($PRDIR = readdir TOPDIR)) {
        next if $PRDIR =~ /^\.\.?$/; # skip . and ..
	next if $PRDIR =~ /^gnats-adm$/; 
	next if $PRDIR =~ /^gnats-queue$/; 
	next if $PRDIR =~ /^temp$/; 
	next if $PRDIR =~ /^pending$/; 
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
			if (/^http:/) {
				print "Fixing http link\n";
				s/BSE_ClearcaseIssues/BSE_SQA/;
				print NEWPRFILE $_;	
			} elsif (/broadcom-bse-cc/) {
				print "Fixing broadcom-bse-cc address\n";
				s/broadcom-bse-cc/broadcom-bse-sqa/;
				print NEWPRFILE $_;	
			} elsif (/irvine-bse-cc/) {
				print "Fixing irvine-bse-cc address\n";
				s/irvine-bse-cc/irvine-bse-sqa/;
				print NEWPRFILE $_;	
			} elsif (/gnats4-admin-bse-cc/) {
				print "Fixing gnats4-admin-bse-cc address\n";
				s/gnats4-admin-bse-cc/gnats4-admin-bse-sqa/;
				print NEWPRFILE $_;	
			} else {
				print NEWPRFILE $_;	
			}
		}
		close(PRFILE);
		close(NEWPRFILE);

	}

}
