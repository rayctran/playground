#!/opt/perl/bin/perl

@hosts=();
open(HL,"ypcat hosts |");
while (<HL>) {
	chop;
	($ip,@hn)=split (' ',$_);
	push (@hosts, @hn);
}
close(HL);
open(REP,">>/home/admin/tran/namematch.rpt");
while (($user) = getpwent) {
	if (grep (/\b$user\b/, @hosts) > 0) {
		print "Found match for $user\n";
		print REP "Found match for $user\n";	
	}
}
close(REP);
#$user=jaguar;
#print "$user\n" if grep (/$user/,@hosts);
