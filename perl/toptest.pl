#!/tools/perl/5.6.0/SunOS/bin/perl

$pid =  open(TOP, "/tools/bin/top |") or die "Couldn't run top: $!\n";
while (<TOP>) {
		print $_;
	if ( $_ =~ /^Memory:.* (\w*)M.*\w+.* (\w*)M.*\w+.* (\w*)M.*\w+.* (\w*)M.*\w+$/ ) {
		print "Memory\n";
		print "1 is $1\n";	
		print "2 is $2\n";	
		print "3 is $3\n";	
		print "4 is $4\n";	
	}
}

#open(SWAP, "rsh ccase-irva-2 /usr/sbin/swap -s |") or die "Couldn't run top: $!\n";
#while (<SWAP>) {
#	print $_;
#	$_ =~ /\w*=.* (\w*)k.*used,.* (\w*)k.*available/;
#	print "$1 and $2\n";
#	$usedswap = $1;
#	$availswap = $2;
#	$maxswap = $1 + $2;
#	printf ("max is %d\n", $maxswap);
#	printf ("used is %d\n", $usedswap);
#}

open(SARR,"rsh ccase-irva-2 sar -u 1|");
	while(<SARR>) {
	print $_;
		next if /Idle/;
		($Date,$Usr,$Sys,$Wio,$Idle) = split(/ +/);
		$Busy = 100 - $Idle;
        }
print "$Busy\n";
close SARR;
