#!/tools/perl/5.6.0/SunOS/bin/perl
#
# Gnats database category remap script
#
#

$WORKDIR="/tools/gnats/v4/etc/gnats/db-bse-sqa";
opendir(TOPDIR, $WORKDIR) or die "Can't access $WORKDIR: $!";
while (defined ($PRDIR = readdir TOPDIR)) {
	if ( $PRDIR =~ /^enhancement$/ ) {
                print "Mapping category enhancement\n";
		opendir(CATDIR, "${WORKDIR}/${PRDIR}") or die "Can't open ${WORKDIR}/${PRDIR}: $!";
        	while (defined ($PR = readdir CATDIR)) {
		next if $PR =~ /^\.\.?$/; # skip . and ..
                print "Found PR $PR\n";
			open(PRFILE, "${WORKDIR}/${PRDIR}/${PR}") or die "Can't open PR file ${WORKDIR}/${PRDIR}/${PR}: $!";
                	open(NEWPRFILE, ">>${WORKDIR}/ClearCase/${PR}") or die "Can't create the new PR file ${WORKDIR}/ClearCase/${PR}: $!";		
			while(<PRFILE>) {
                        	if (/^\>Class:\s+support/) {
                               		print "Mapping Class support\n";
                               		s/support/enhancement_request/;
                               		print NEWPRFILE $_;
                        	} elsif (/^\>Category:\s+enhancement/) {
                               		print "Mapping Category enhancement to ClearCase\n";
                               		s/enhancement/ClearCase/;
                               		print NEWPRFILE $_;
                        	} else {
                               		print NEWPRFILE $_;
                        	}
                	}
                	close(PRFILE);
                	close(NEWPRFILE);
		}
                close(CATDIR);
	} elsif ( $PRDIR =~ /^problem$/ ) {
                print "Mapping category problem\n";
		opendir(CATDIR, "${WORKDIR}/${PRDIR}") or die "Can't open ${WORKDIR}/${PRDIR}: $!";
        	while (defined ($PR = readdir CATDIR)) {
		next if $PR =~ /^\.\.?$/; # skip . and ..
                print "Found PR $PR\n";
			open(PRFILE, "${WORKDIR}/${PRDIR}/${PR}") or die "Can't open PR file ${WORKDIR}/${PRDIR}/${PR}: $!";
                	open(NEWPRFILE, ">>${WORKDIR}/ClearCase/${PR}") or die "Can't create the new PR file ${WORKDIR}/ClearCase/${PR}: $!";		
			while(<PRFILE>) {
                        	if (/^\>Class:\s+support/) {
                               		print "Mapping Class support\n";
                               		s/support/problem_report/;
                               		print NEWPRFILE $_;
                        	} elsif (/^\>Category:\s+problem/) {
                               		print "Mapping Category problem to ClearCase\n";
                               		s/problem/ClearCase/;
                               		print NEWPRFILE $_;
                        	} else {
                               		print NEWPRFILE $_;
                        	}
                	}
                	close(PRFILE);
                	close(NEWPRFILE);
		}
                close(CATDIR);
	} elsif ( $PRDIR =~ /^action_item$/ ) {
                print "Mapping category action item\n";
		opendir(CATDIR, "${WORKDIR}/${PRDIR}") or die "Can't open ${WORKDIR}/${PRDIR}: $!";
        	while (defined ($PR = readdir CATDIR)) {
		next if $PR =~ /^\.\.?$/; # skip . and ..
                print "Found PR $PR\n";
			open(PRFILE, "${WORKDIR}/${PRDIR}/${PR}") or die "Can't open PR file ${WORKDIR}/${PRDIR}/${PR}: $!";
                	open(NEWPRFILE, ">>${WORKDIR}/ClearCase/${PR}") or die "Can't create the new PR file ${WORKDIR}/ClearCase/${PR}: $!";		
			while(<PRFILE>) {
                        	if (/^\>Class:\s+support/) {
                               		print "Mapping Class support\n";
                               		s/support/action_item/;
                               		print NEWPRFILE $_;
                        	} elsif (/^\>Category:\s+action_item/) {
                               		print "Mapping Category action_item to ClearCase\n";
                               		s/action_item/ClearCase/;
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
