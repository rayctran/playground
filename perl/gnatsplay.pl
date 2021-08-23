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

#sub getCategory {
#  my $db = shift;
#  my @category = $db->listCategories();
#  my $CATEGORY = {};
#  foreach my $href (@category) {
#    $CATEGORY->{$href->{name}} = { desc => $href->{desc}, path => $href->{path} };
#  }
#  return $CATEGORY;
#}

#sub getCategories {
#  my $db = shift;
#  return array2namehash($db->listCategories());
#}

#sub getStates {
#    my $db = shift;
#    return array2namehash($db->listStates());
#}

# Create a hashref from an array of arrays.
#sub array2namehash {
#  my $ret = {};
#  foreach my $href (@_) {
#    foreach my $key (keys %{$href}) {
#      $ret->{$href->{name}}->{$key} = $href->{$key} if ($key ne "name");
#    }
#  }
#  #die Dumper($ret);
#  return $ret;
#}

my $update_field = "Audit-Trail";

my $db = Net::Gnats->new("gnats-irva-3.broadcom.com",1530);
if ( $db->connect() ) {
    $db->login("IT-Test","raytran","emsggn09");
} else {
    print "can not connect\n";
    exit;
}

#getCategory;

#my @prNums = $db->query("State=\"open\"");
#print Dumper(@prNums);


# Don't have to authenticate for this command
#my @dbnames = $db->getDBNames();
#print Dumper(\@dbnames);

# Have to authenticate before running this one
#my %listdb = $db->listDatabases();
#print Dumper(\%listdb);

#
#my %Fields = $db->listFieldNames();
#print Dumper(\%Fields);

#my %states = $db->listStates();
#print Dumper(\%states);

#my @categories = $db->listCategories();
#print Dumper(\@categories);
#foreach my $href (@categories) {
#    print "$href->{name}\n";
#}

#my $cat = getCategories($db);
#print "Category is $cat\n";


#foreach my $key (keys %states) {
#    my $value = $states{$key};
#    print "$key is $value\n";
#}

#my $states = getStates($db);
#print $states;

#my $teststate = "anal";
#if (defined $mystates->{$teststate}) {
#    print "state $teststate is valid\n";
#} else {
#    print "state $teststate is invalid\n";
#}

#
# Get a pr and display some info about it
#
my $prnum = 44;
my $pr = $db->getPRByNumber("$prnum");
print "pr is $pr\n";
#my $error = $db->getErrorMessage();
##print "error is $error\n";
##print "$pr";
##print "\n--------------\n";
#print $pr->getField('State');
#print "\n--------------\n";
#print "Category\n";
#print $pr->getField('Category');
print $pr->getField('Audit-Trail');
#print "\n--------------\n";
#print $pr->getField('State');
#print "\n--------------\n";
#print $pr->getField('Synopsis');
#print "\n--------------\n";
#print $pr->asString();

#my $fieldcheck = $pr->getField('Change_Set');
#print "fieldcheck $fieldcheck\n";

exit;

#
# Lock a pr
#if(! $db->lockPR($prnum,"raytran") ) {
#        my $error = $db->getErrorMessage;
#        print "Can not lock PR $prnum\n ERROR: $error\n";
#}

# Validate a change 
#my $validate = $db->validateField("Audit-Trail","$Date_String\nTesting by RayTran\n");
#print "validate $validate\n";;

# Bad field
#my $validate = $db->validateField("Kaka","$Date_String\nTesting by RayTran\n");
#print "validate $validate\n";;

#
# Change something
# 
#if (! $db->appendToField($prnum,"Audit-Trail","$Date_String\nTesting by $login\n")) {
#    my $error = $db->getErrorMessage;
#    print "Can not append to field Audit-Trail -  ERROR: $error\n";
#}


#my $current_state =  $pr->getField('State');
#my $new_state = "feedback";
#print "$new_state  = $current_state\n";
#if ( $current_state ne $new_state ) {
#    print "changing state\n";
#    if (! $db->replaceField($prnum,'State',"$new_state","Changed by $login CVS commit test ii")) {
#        my $error = $db->getErrorMessage;
#        print "Can not change field State to $new_state\n ERROR: $error\n";
#    }
#}
#my $kakalist = $pr->getField('Environment');
#if ( $kakalist =~ /^\s*$/ ) {
#    print "kaka is blank\n";
#} else {
#    print "kaka is not blank: $kakalist\n";
#}
#print "test\n";

# Unlock pr
#my $unlockpr = $db->unlockPR("$prnum","raytran");
#print "unlock $unlockpr\n";;

#my $setfield = $pr->setField("State","open","Changed by $login CVS commit");
#print "setfield stats $setfield\n";
#$db->updatePR($prnum);

#if (! $st) {
#    print die "Unable to update PR $prnum st=$st: ",$db->getErrorMessage,"\n";
#}
