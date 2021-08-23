#! /tools/perl/5.6.0/SunOS/bin/perl

$LMSTAT="/tools/bin/lmstat";

if ( $#ARGV < 0 ) {
    $Prompt=0;
    print "Please specify server\n";
    exit;
} else {
	$Server=$ARGV[0];
}

if ( "$Server" eq "lic-irva-1" ) {
	$LICENSE_FILE="/tools/license/rational.lic-irva-1";
}
if ( "$Server" eq "lic-sj1-2" ) {
	$LICENSE_FILE="/tools/license/rational.lic-sj1-2";
}

$Used=0;
open(LIC,"$LMSTAT -a -c $LICENSE_FILE |") or die "Couldn't run lmstat command. $!\n";
while(<LIC>) {
	chop $_;
	if ( $_ =~ /^*Total of (\d{1,2})*/ ) {
		$Total=$1;
	}
	if ( $_ =~ /^*start*/ ) {
		$Used++;
	}	
	
}
close(LIC);

print "Total is $Total\n";
print "Used is $Used\n";
