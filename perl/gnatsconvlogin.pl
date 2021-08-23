#!/tools/perl/5.6.0/SunOS/bin/perl

# Copy the Email list to a file and then run this to create the gnatsd.user_access file
# Example of line format
# Abe (Pingkwei) A. Shen   Eng-Switching Apps Eng  Zanker (SJ CA)  abeshen@broadcom.com
open(NEWFILE, "> gnatsd.user_access") or die "Can't open file: $!\n";
open(FILE, "ntswlist.txt") or die "Can't open file: $!\n";
while (<FILE>) {
#	print $_;
	if ( $_ =~ /\s+(\w+)\@broadcom\.com\s+$/) {
		print NEWFILE "$1\:\$0\$\*:edit\:\n";
	}

}
close(FILE);
close(NEWFILE);
