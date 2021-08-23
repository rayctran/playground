#!/tools/perl/5.6.0/SunOS/bin/perl
use File::Basename;

if ($#ARGV == 0) {
        $NTFile=$ARGV[0];
} else {
        print "No Input file provided\nUsage: $0 [Input File]\n";
        exit 1;
}
fileparse_set_fstype("MSWin32");
open(VOB,"$NTFile") or die "Can't open file: $!\n";
while(<VOB>) {
  	if ($_ =~ /^\*/) {
                ($MS, $VT, $VSL, $Type)=split;
        } else {
                ($VT, $VSL, $Type)=split;
        }

	$VT =~ s#\\#\\\\#g;
	$VBS = basename($VSL);
	print "$VBS\n";
}
