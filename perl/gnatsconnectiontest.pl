#!/usr/local/bin/perl
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

my $db = Net::Gnats->new("gnats.broadcom.com",1530);
if ( $db->connect() ) {
    $db->login("DigitalVideo","vobadm","fixit");
} else {
    print "can not connect\n";
    exit;
}

