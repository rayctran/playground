#!/usr/local/bin/perl
############################################################################
###  Author: Ray Tran
###  Date:   October 12,2000
###  Purpose: Lock massive accounts using an input file with names
###  Syntax : lockacct.pl
###  Requirement : perl
############################################################################
###  HISTORY
############################################################################
###  Date:       Author:       Description
############################################################################
if ($#ARGV < 0) {
        print "Usage: $0 filename\n";
        exit (1);
} else {
        $InputFile=$ARGV[0];
}

open(IF,"<$InputFile") || die "Can not read or locate file $InputFile.\n";
while (<IF>) {
	chop;
	$username=$_;
	($login,$passwd,$uid)=getpwnam($username);
			
}
