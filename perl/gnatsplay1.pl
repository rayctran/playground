#!/usr/local/bin/perl -w
#
#use lib "/home/jims/sf/gnatsperl/gnatsperl/code";
use strict;
use Net::Gnats;
use Data::Dumper;
#use Date::Manip;

my $Date_String=`date`;
print "$Date_String\n";
my $login="gnats_cvs";

sub getStates {
    my $g = shift;
    return array2namehash($g->listStates());
}

sub getCategory {
  my $g = shift;
  my @category = $g->listCategories();
  my $CATEGORY = {};
  foreach my $href (@category) {
    $CATEGORY->{$href->{name}} = { desc => $href->{desc}, contact => $href->{contact} };
  }
  return $CATEGORY;
}

# Create a hashref from an array of arrays.
sub array2namehash {
  my $ret = {};
  foreach my $href (@_) {
    foreach my $key (keys %{$href}) {
      $ret->{$href->{name}}->{$key} = $href->{$key} if ($key ne "name");
    }
  }
  #die Dumper($ret);
  return $ret;
}

my $update_field = "Audit-Trail";

my $db = Net::Gnats->new("gnatsqa.broadcom.com",1530);
if ( $db->connect() ) {
    $db->login("IT_Test","svcaccnt1","emsggn09");
    print "Logged in\n";
} else {
    print "can not connect\n";
    exit;
}

#my $CATEGORY    = getCategory($db);
#print Dumper(\$CATEGORY);
my ($cat_type );
my $Cat = "Linux-Software";

my @category = $db->listCategories();
foreach my $href (@category) {
    print "$href->{name}, $href->{contact}\n";
}

#my @category_1 = $db->listCategories();
#print Dumper(\@category_1);
#foreach my $cat_name (@category_1) {
#    print "$cat_name -> \n";
#}


#my $newPR = Net::Gnats::PR->new();
#$newPR->setField("Category","Linux-Hardware");
#$newPR->setField("Synopsis","PR created from a script");
#$newPR->setField("Severity","non-critial");
#$newPR->setField("Decription","This PR was created from the script\nsecond line\nthird line.");
#$db->submitPR($newPR);
