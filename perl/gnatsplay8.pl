#!/usr/local/bin/perl -w
use strict;
use Net::Gnats;
use Data::Dumper;

my %AppConfig;

sub getCategory {
  my $db = shift;
  my @category = $db->listCategories();
  my %CATEGORY;
  foreach my $href (@category) {
#    $CATEGORY->{$href->{name}} = { desc => $href->{desc}, resp => $href->{contact} };
#     print "$href->{name}\n";
    $CATEGORY{"$href->{name}"}{desc} = $href->{desc};
    $CATEGORY{"$href->{name}"}{resp} = $href->{contact};
  }
  return %CATEGORY;
}

sub getResponsible {
  my $db = shift;
  my @responsible = $db->listResponsible();
  my %RESPON;
  foreach my $href (@responsible) {
    $RESPON{"$href->{name}"}{fullname} = "$href->{realname}";
    $RESPON{"$href->{name}"}{email} = $href->{email};
  }
  return %RESPON;
}

$AppConfig{server}='gnatsqa.broadcom.com';
$AppConfig{port}='1530';
$AppConfig{db}='HND_WLAN_CSPdev';
$AppConfig{user}='SVCCSPDEVWLAN';
$AppConfig{passwd}='cspdevwlan';

my $db = Net::Gnats->new("$AppConfig{server}",$AppConfig{port});

if ( $db->connect() ) {
    print "Connecting...\n";
    unless ( $db->login("$AppConfig{db}","$AppConfig{user}","$AppConfig{passwd}")) {
        $AppConfig{error} = $db->getErrorMessage();
        print "Can not login: $AppConfig{error}\n";
	exit;
    } else {
        print "Connected to $AppConfig{db}\n";

    }
     
} else {

   print "can not connect\n";
   exit;
}

my @found_prs = $db->query("Modified-Date>\"\2007-06-27*\"");
print Dumper(@found_prs);
