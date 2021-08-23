#!/bin/sh
#The next line is executed by bin/sh
exec perl $0 ${1+"$@"}


OutFile="salesofficedisk.rpt"
chop ($Today=`date +%y%m%d`);
chop($hostname=`uname -n`);
if ($hostname != "scully") {
        print "Not on scully. Sorry!\n";
        exit 1;
}
open(OUTFILE,"salesoffices.rpt") || die "Can't open output report file\n";
open(SALESSERVERS,"/unixadm/salesservers") || die "Can't open the Sales Servers data file\n";
while(<SALESSERVERS>) {
	chop;
	open(DFCMD,"rsh $_ df -k|");
	
}

close OUTFILE;
close SALESSERVERS;
#	($Filesystem,$Capacity,$Used,$Avail,$Perc,$Filesys)=split(/ /);
