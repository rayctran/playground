#!/tools/isofax/brcm/perl/bin/perl

open (DATA, " /tools/isofax/work/modem_usage/usage-23-04-2002") or  print "Can't open file\n" and die;
while (<DATA>) {
#	chop($_);
#	print $_;
        if (/4\/23\/2002/) {
                ($a,$hours,$date) = split(' ',$_); 
		
        }
}

