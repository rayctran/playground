#!/usr/local/bin/perl
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


my $db = Net::Gnats->new("gnatsqa.broadcom.com",1530);
if ( $db->connect() ) {
    print "Connecting...\n";
#    $db->login("IT-Test","raytran","emsggn09");
#    $db->login("Mobilink","gnats4","emsggn09");
    $db->login("HND_WLAN_CSPdev","SVCCSPDEVWLAN","cspdevwlan");
     
} else {
    print "can not connect\n";
    exit;
}

#my %categories = getCategory($db);
#my %responsible = getResponsible($db);
#print Dumper(%categories);
#print "Linux-Hardware $categories{'Linux-Hardware'}{resp}\n";
#print Dumper(%responsible);
#print "Full name of the person responsible for category Linux-Hardware is $responsible{$categories{'Linux-Hardware'}{resp}}{fullname}\n";

#my @category_search_list = ("2140-Software", "2141-Software", "2140-NewJersey");
#my (@found_prs_list,@found_prs);

#my @found_prs = $db->query("Category~\"2140-Software\*\"", "Category~\"2141-Software\*\"","Category~\"2140-NewJersey\*\"", "Reference_Number=\"SMS00105116\"");
#foreach my $cat (@category_search_list) {
#    @found_prs = $db->query("Category~\"$cat\*\"", "Reference_Number=\"SMS00105116\"");
#    @found_prs = $db->query("Reference_Number=\"SMS00105116\"");
#    push (@found_prs_list,@found_prs);
#}
#my @found_prs = $db->query("Reference_Number=\"SMS00105116\"");
#my @found_prs = $db->query('Number>"0"');
#print Dumper(@found_prs);
my ($test_q,$new_string);
my $test_q = "2140-Software,2141-Software,2140-NewJersey";
($new_string = $test_q) =~ s/,/\|/g;
print "$new_string\n";

my @found_prs = $db->query("Category~\"2140-Software*|2141-Software*\"","State~\"Open|Analyzed\"");
#print Dumper(@found_prs);
my ($pr,%pr_data,$target_pr);

foreach $target_pr (@found_prs) {
    unless ($pr = $db->getPRByNumber($target_pr)) {
        print "Can not get information for $target_pr\n";
    } else {
        $pr_data{state} = $pr->getField('State');
        $pr_data{category} = $pr->getField('Category');
	$pr_data{modifed_date} = $pr->getField('Last-Modified');
        print "$pr_data{state} - $pr_data{category} - $pr_data{modifed_date}\n";
    }

}

exit;
my $target_pr="6939";
my $target_pr="6610";
my ($pr,%pr_data);
unless ($pr = $db->getPRByNumber($target_pr)) {
    my $error = $db->getErrorMessage;
    print "Can not get problem report number 6393 ERROR: $error\n";

} else {
    print "No problems\n";
}
#print $pr->asString();
my @fieldname = $pr->getKeys();
#print Dumper(@fieldname);
foreach my $field (@fieldname) {
#    print "$field\n";
    my $value = $pr->getField("$field");
    if ( "$field" eq "Synopsis" ) {
#        print "$field = $value\n";
    }
}
$pr_data{Category} = $pr->getField('Category');
$pr_data{Synopsis} = $pr->getField('Synopsis');
#$pr_data{Description} = $pr->getField('Description');
print Dumper(\%pr_data);
