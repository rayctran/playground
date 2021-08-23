#!/tools/perl/5.6.0/SunOS/bin/perl
#
# Gnats database category remap script
#
#

$WORKDIR="/tools/gnats/v4/etc/gnats/db-bse-sqa";
opendir(TOPDIR, $WORKDIR) or die "Can't access $WORKDIR: $!";
while (defined ($PRDIR = readdir TOPDIR)) {
	if ( $PRDIR =~ /^ClearCase-UCM$/ ) {
                print "Mapping category enhancement\n";
		opendir(CATDIR, "${WORKDIR}/${PRDIR}") or die "Can't open ${WORKDIR}/${PRDIR}: $!";
        	while (defined ($PR = readdir CATDIR)) {
		next if $PR =~ /^\.\.?$/; # skip . and ..
                print "Found PR $PR\n";
			open(PRFILE, "${WORKDIR}/${PRDIR}/${PR}") or die "Can't open PR file ${WORKDIR}/${PRDIR}/${PR}: $!";
                	open(NEWPRFILE, ">>${WORKDIR}/UCM/${PR}") or die "Can't create the new PR file ${WORKDIR}/UCM/${PR}: $!";		
			while(<PRFILE>) {
                        	if (/^\>Category:\s+ClearCase-UCM/) {
                               		print "Mapping Category enhancement to ClearCase\n";
                               		s/ClearCase-UCM/UCM/;
                               		print NEWPRFILE $_;
                        	} else {
                               		print NEWPRFILE $_;
                        	}
                	}
                	close(PRFILE);
                	close(NEWPRFILE);
		}
                close(CATDIR);
	} elsif ( $PRDIR =~ /^Gnats-ClearCase_Integration$/ ) {
                print "Mapping category Gnats-ClearCase_Integration\n";
		opendir(CATDIR, "${WORKDIR}/${PRDIR}") or die "Can't open ${WORKDIR}/${PRDIR}: $!";
        	while (defined ($PR = readdir CATDIR)) {
		next if $PR =~ /^\.\.?$/; # skip . and ..
                print "Found PR $PR\n";
			open(PRFILE, "${WORKDIR}/${PRDIR}/${PR}") or die "Can't open PR file ${WORKDIR}/${PRDIR}/${PR}: $!";
                	open(NEWPRFILE, ">>${WORKDIR}/Gnats_Integration/${PR}") or die "Can't create the new PR file ${WORKDIR}/ClearCase/${PR}: $!";		
			while(<PRFILE>) {
                        	if (/^\>Category:\s+Gnats-ClearCase_Integration/) {
                               		print "Mapping Category problem to Gnats_Integration\n";
                               		s/Gnats-ClearCase_Integration/Gnats_Integration/;
                               		print NEWPRFILE $_;
                        	} else {
                               		print NEWPRFILE $_;
                        	}
                	}
                	close(PRFILE);
                	close(NEWPRFILE);
		}
                close(CATDIR);
	} else { 
		next; 
	}
}
