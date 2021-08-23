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

sub Notify {
    my($MySentFrom,$MySentTo,$MyCcTo,$MySubject,$MyMessage)=@_;
    my %mail = (
        smtp    => 'smtphost.broadcom.com',
	To      => $MySentTo,
	Cc      => $MyCcTo,
	From    => $MySentFrom,
	Subject => $MySubject,
	message => $MyMessage,
   );
    eval { sendmail(%mail) || die $Mail::Sendmail::error; };
    $Mail::Sendmail::log;
    if ($@) {
        print "mail could NOT be sent correctly - $@\n";
    } else {
         print "mail sent correctly\n";
   }
}


my (@prs,$pr_line,%report,%gnats,$date,$debug,$target_pr,$pr,$field_value,$current_line);
$gnats{gnats_root}="/tools/gnats/4.0";
$debug=1;
$report{dir}="$gnats{gnats_root}/www/htdocs/reports/$gnats{database}";
$report{file}="$report{dir}/report_for_Bryan_Chase_${date}.csv";
my $notify_list="raytran\@broadcom.com,bchase\@broadcom.com";
# list of fields to include in the report
my @fields = ("Category","Synopsis","Description","Audit-Trail");

# hard code the input file for now
# read in the PR list, extract the PR number then 
# push the PR number into the array prs

open(INFILE,"pr_list.txt") or die "Can't read PR file: $!\n";
while(<INFILE>) {
    if ($_ =~ /\[\s*GNATS*\s+\w*\d+\s*\]/g) {
        $pr_line = $_;
	if ($debug) {print "found GNATS line\n$_\n";}
	$pr_line =~ /\[\s*GNATS*\s+\w*?(\d+)\s*\]/g;
	push (@prs, $1);
    }
}
print Dumper(@prs);

my $db = Net::Gnats->new("gnatsweb.broadcom.com",1530);
if ( $db->connect() ) {
    print "Connecting...\n";
    $db->login("Mobilink","raytran","emsggn09");
     
} else {
    print "can not connect\n";
    exit;
}

#open(LOG,">>$report{file}") or die "Can't open log file: $!\n";
print "PR,Category,Synopsis,Description,Audit-Trail\n";

foreach $target_pr (@prs) {
    $current_line = "$target_pr,";
    $pr = $db->getPRByNumber("$target_pr");
    $field_value = $pr->getField("Category");
    $current_line .= "$field_value,";
    $field_value = $pr->getField("Synopsis");
    $current_line .= "$field_value,";
    $field_value = $pr->getField("Description");
    $current_line .= "$field_value,";
    $current_line .= "\n";
    print $current_line

}
