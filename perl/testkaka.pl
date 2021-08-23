#!/tools/perl/5.6.0/SunOS/bin/perl

use Data::Dumper;

#if ($#ARGV < 0) {
#        print "Usage: $0 {database directory name} {database name}\n";
#        print "Example: $0 bse-sqa BSE_ClearCase\n";
#        exit (1);
#} else {
#        $DBDIR="db-${ARGV[0]}";
#        $DBNAME=$ARGV[1];
#}
#print "$DBDIR\n";

opendir(PWD,".") or die "can't do it\n";
@failed_files = grep { /^\.mykaka\d+$/ } readdir(PWD);
if ( scalar(@failed_files) < 2 ) {
    print "this many @failed_files\n";
    $file = join("",@failed_files);
    print "output file is $file\n";
}
open(FH,"$file") or die "can't open file $file: $!\n";
while(<FH>) {
    if ( /^/ ) {
        print $_;
        print $1;
    }
    if ( /^PR/ ) {
        print $_;
        ($pr,$state_value) =~ /^PR\s*(\d+(,\d+)*)\s*state\s*(\w+)$/;
    }
}

close(FH);

print "login is $login\n";
print "PRs is $pr\n";
print "state is $state\n";

my $pwd;
chop ($pwd=`pwd`);
print "current dir $pwd";
