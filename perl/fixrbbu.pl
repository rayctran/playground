#!/usr/local/bin/perl

#
# RBBU Gnats database fix script for V4 conversion
#
#
use Data::Dumper;
use IO::File;

# This is done so that there is a backup. Once you have verified
# rename the db directory accordingly. The good data is in fixed
#  
$WORKDIR="/tools/gnats/4.0/share/gnats/db-rbb-sw.fixed";
$DESTDIR="/tools/gnats/4.0/share/gnats/db-rbb-sw";

opendir(TOPDIR, $WORKDIR) or die "Can't access $WORKDIR: $!";
while (defined ($PRDIR = readdir TOPDIR)) {
#  add any other directories that you don't want process here
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
		open(NEWPRFILE, ">${DESTDIR}/${PRDIR}/${PR}") or die "Can't create the new PR file ${DESTDIR}/${PRDIR}/${PR}: $!";
		print "Converting file ${PRDIR}/${PR} to ${DESTDIR}/${PRDIR}/${PR}\n";
		while(<PRFILE>) {
		        $sorted_rt="";
			if (/^>Release-Targeted: /) {
				print "Fixing Release Targeted\n";
				chop;
				($field,$value)=split(/:\s*/);
				$sorted_rt = join (';', sort (split(/;/,$value)) );
				print NEWPRFILE "\>Release-Targeted:\t$sorted_rt\n";
			} else {
				print NEWPRFILE $_;	
			}
		}
		close(PRFILE);
		close(NEWPRFILE);

	}
}
