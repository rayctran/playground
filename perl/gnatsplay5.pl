#!/tools/perl/5.6.1/SunOS/bin/perl -w
#
#use lib "/home/jims/sf/gnatsperl/gnatsperl/code";
use strict;
use Net::Gnats;
use Data::Dumper;
use File::Basename;
#use Date::Manip;

#sub getCategories {
#  my $db = shift;
#  return array2namehash($db->listCategories());
#}

sub getCategory {
  my $g = shift;
  my @category = $g->listCategories();
  my $CATEGORY = {};
  foreach my $href (@category) {
    $CATEGORY->{$href->{name}} = { desc => $href->{desc}, path => $href->{path} };
  }
  return $CATEGORY;
}

sub getStates {
    my $db = shift;
    return array2namehash($db->listStates());
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


my ($current_env, @env_list, $env_file, $env, $env_path, %branch_path);
my ($env_item, @pr_env_path, %env_matched,  $env_cnt, @branch_changed);
my (@pr_audit_line, $pr_audit, $pr_audit_line, $array_line, $total_path_matched);

$env_file="./branch_mapping_1.txt";

open(EF,"$env_file") or die "Can't open Environment mapping file: $!\n";
while(<EF>) {
    ($env,$env_path) = split(/\s+/);
# change the / in the path to _ to make searching easier
     $env_path =~ s/\//\_/g;
     $env_path =~ s/^_+//g;
     $branch_path{$env}=$env_path;
}
close(EF);
print Dumper(\%branch_path);

my $db = Net::Gnats->new("gnatsqa.broadcom.com",1530);
if ( $db->connect() ) {
    $db->login("Mobilink","mobilinkp4","p4user");
} else {
    print "can not connect\n";
    exit;
}

my $prnum = 300;

my $pr = $db->getPRByNumber("$prnum");
$current_env = $pr->getField('Environment');
print "environment is $current_env\n";
@env_list = split(/\s/,$current_env);
$env_cnt = scalar(@env_list);

foreach $array_line (@env_list) {
    print "$array_line\n";
}

foreach $array_line (@env_list) {
    print "found $branch_path{$array_line}\n";
    push (@pr_env_path, $branch_path{$array_line});
}

print "pr_env_path is\n";
print Dumper(\@pr_env_path);

$pr_audit = $pr->getField('Audit-Trail');
@pr_audit_line = split(/\n/,$pr_audit);

foreach $array_line (@pr_audit_line) {
    if ($array_line =~ /^\.\.\s([^@\s]+)\s*(\w*)/) {
        $array_line = dirname($1);
        $array_line =~ s/\//\_/g;
        $array_line =~ s/^_+//g;
        push (@branch_changed,$array_line);
#        print "audit line text $array_line\n";
    }
}

print "BRANCH_CHANGED\n";
print Dumper(\@branch_changed);

%env_matched = ();

foreach $array_line (@pr_env_path) { $env_matched{$array_line} = 1 };

print "ENV_MATCHED\n";
print Dumper(\%env_matched);

foreach $array_line (@branch_changed) {
#    print " branch_changed line is $array_line\n";
#    print "HO HO $env_matched{$array_line}\n";
    if ( $env_matched{$array_line} == 1) {
        print "matched\n";
        $total_path_matched++;
    }
}

my ($do_state, $state_value);
print "$total_path_matched, $env_cnt\n";
if ( $total_path_matched == $env_cnt ) {
    print "matched all path\n";
    $do_state = 1;
    $state_value="feedback";
}

exit;
