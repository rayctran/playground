#!/tools/perl/5.8.0/SunOS/bin/perl
use strict;
use Net::Gnats;
use Data::Dumper;

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
my $db = Net::Gnats->new("gnatsweb.broadcom.com",1530);
if ( $db->connect() ) {
    print "Connecting...\n";
    $db->login("IT-Test","raytran","emsggn09");
     
} else {
    print "can not connect\n";
    exit;
}

my %categories = getCategory($db);
my %responsible = getResponsible($db);
#print Dumper(%categories);
#print "Linux-Hardware $categories{'Linux-Hardware'}{resp}\n";
#print Dumper(%responsible);
print "Full name of the person responsible for category Linux-Hardware is $responsible{$categories{'Linux-Hardware'}{resp}}{fullname}\n";
