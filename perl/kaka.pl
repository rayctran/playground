#!/usr/local/bin/perl
#use locale;
#$MYLA = "db-test-it-moco";
#$DB, $REST) = split(/\s*-\s*/, $MYLA, 2);
#print "$REST\n";

#$OLDADMDIR="/tools/GNATS/share/gnats/db-hnd-softmodem/gnats-adm";
#$OLDADMDIR="/tools/GNATS/share/gnats/db-rbb/gnats-adm";
#open(CONF,"${OLDADMDIR}/config") or die "Can't open old config file: $!\n";
#while (<CONF>) {
#	if (/^GNATS_ADDR\=\"(\w+-\w+-*\w*)\"$/) {
#		print "$1\n";
#        }
#}
#close(CONF);

#MAIN: {
#	print "mykaka\n";
#	chomp($mykaka = lc(<>));
#
#	print "$mykaka\n";
#	goto MAIN;
#}

$Zone_File="./zonedir/virtualstockexchange.com.dns";
#$Zone_File="./zonedir/virtualstockexchange.com.com";
$Zone_File_a="./zonedir/virtualstockexchange.com.dns";

if ( !-e $Zone_File ) {
	print "No kaka here\n";
} else {
	print "Kaka is in the house\n";

}

if ( defined($Zone_File_a) ) {
	print "Zone_File_a exists\n";
} else {
	print "Zone_File_a don't exists\n";
}

sub get_me_a_drink {
    print "Ask me for default settting. (n)o or (y)es DEFAULT\n" ;
    $mykaka = lc(<>);
    print "\"$mykaka\"";
    if ( $mykaka =~ /y|^\n$/ ) {
    	print "default mykaka found\n";
        &get_me_a_drink;
    } elsif ( $mykaka =~ /n/ ) { 
        print "no\n";
    }
    if ( !defined($My_Host) ) {
 	print "Just checking\n";
    }

}

$My_Host = "1";
&get_me_a_drink;
$My_Host = undef;
print "My_host $My_Host\n";

#open(ZF, "$Zone_File") or die "Can't open $Zone_File: $!\n";
#@Zone_File_Contents = <ZF>;
#close(ZF);


$MyLine = "raytranmail                    14400   IN      A       129.250.100.245\n";
#push(@Zone_File_Contents, "$MyLine");

#chop($Serial_Number =`date '+%Y%m%d%H%M%S'`);
#foreach $Line (@Zone_File_Contents) {
#        chop($Serial_Number =`date '+%Y%m%d%H%M%S'`);
#	if ( $Line =~ /^\s*(\d+)\s+\;\s*serial$/ ) {
#	    print "Found serial\n";
#            $Line =~ s/$1/$Serial_Number/;
#        }
#	print $Line;
#}

