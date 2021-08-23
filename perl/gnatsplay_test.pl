#!/tools/perl/5.6.1/SunOS/bin/perl -w
#
#use lib "/home/jims/sf/gnatsperl/gnatsperl/code";
use strict;
use Net::Gnats;
use Data::Dumper;
#use Date::Manip;

my $Date_String=`date`;
print "$Date_String\n";
my $login="gnats_cvs";

my $update_field = "Audit-Trail";

my $db = Net::Gnats->new("gnats-irva-3.broadcom.com",1530);
#    $db->login("IT-Test","raytran","emsggn09");
if ( $db->connect() ) {
    $db->login("HiDef-DVD","gnats4","emsggn09");
} else {
    print "can not connect\n";
    exit;
}

#
# Get a pr and display some info about it
#
my $prnum = 119;
my $pr = $db->getPRByNumber("$prnum");
print "pr is $pr\n";

if (! $db->replaceField($prnum,'Activity-Log',"Testing activity log changes.")) {
    my $error = $db->getErrorMessage;
    print "Can not change field Activity-Log \n ERROR: $error\n";
}
