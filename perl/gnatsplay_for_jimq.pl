#!/tools/perl/5.8.0/SunOS/bin/perl -w

use strict;
use Net::Gnats;
use Data::Dumper;
#use Date::Manip;

my $db = Net::Gnats->new("gnats-irva-3.broadcom.com",1530);
if ( $db->connect() ) {
    $db->login("IT-Test","gnats_cvs","cvstest");
} else {
    print "can not connect\n";
    exit;
}

print $db->getDBNames ();
