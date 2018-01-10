#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper qw(Dumper);
use File::Find;
use v5.10; # for say() function
# 
use DBI;
# MySQL database configuration
my $dsn = "DBI:mysql:tracker,host=10.0.90.31";
my $username = "root";
my $password = 'qazxcde1231';
my $attlocation = "/var/www/html/files";
my $exclude_file="/home/rtran/tmp/redmine_remove_att_exclude_list";
my $target_file="/home/rtran/tmp/redmine_remove_att.sh";

my @projects; 
my @exclude_projects=("Anchor Hocking","WWRD-NA","[Comark] - DW Implementation");
my (%red_projs,%attachments,%projattmap);
my ($filename,$pid,$red_pid,$projname,$info,$newfilename,@foundfiles);
my (@attfiles);

my $debug=1;

# Locate all attachment files and load them into attfiles 
say "PHASE1 - load attachment directory contents";
&loadattfiles($attlocation);
if ($debug) {
    say "PHASE1 RESULT - array attfile data";
    # print Dumper(@attfiles);
}

# connect to MySQL database
my %attr = ( PrintError=>0,  # turn off error reporting via warn()
             RaiseError=>1);   # turn on error reporting via die()           
say "PHASE2 - Database connection";
say "Connected to the MySQL database.";
my $dbh  = DBI->connect($dsn,$username,$password, \%attr);

say "PHASE3 - Get list of projects from MySQL";
my $sth = $dbh->prepare("SELECT * FROM tracker.projects");
$sth->execute();

while (my $ref = $sth->fetchrow_hashref()) {
    $pid = $ref->{'id'};
    $projname = $ref->{'name'};
if ($debug) {
#    print "Found a row: id = $ref->{'id'}, name = $ref->{'name'}\n";
}
    push(@projects,$ref->{'name'});
    $red_projs{$pid} = $projname;
}

if ($debug) {
    say "PHASE3 RESULT - Content of hash red_projs";
    # print Dumper (\%red_projs);
    say "PHASE3 RESULT - Content of array projects";
    # print Dumper(@projects);
}
say "PHASE4 - Get list of dmsh_files from the database";
$sth = $dbh->prepare("SELECT project_id,name FROM tracker.dmsf_files");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
    ($filename = $ref->{'name'}) =~ s/\s/_/g;
    $pid = $ref->{'project_id'};
    if ($debug) {
        say "working on $pid from query";
    }
    my $projectname = $red_projs{$pid};
    if (!defined $projectname) {
        say "project pid is $pid project name is unknown";
        $projectname = "Unknown";
    }
    if ($debug) {
        say "locating file $filename in array attfiles";
    }
    @foundfiles = grep /$filename$/, @attfiles;
    foreach my $ff (@foundfiles) {
        push @{ $projattmap{$projectname}}, $ff;         
     }     
}

if ($debug) {
    say "PHASE4 RESULT - content of hash projattmap";
    # print Dumper (\%projattmap);
}

# check files

# Creating script files
#
say "PHASE5 - Generating scripts";
my @matchexclude;
open(TF,">$target_file") or die "Can not open files $target_file: $!\n";
chmod 0755, $target_file;
open(EF,">$exclude_file") or die "Can not open files $exclude_file: $!\n";
print TF "#\!\/bin\/sh\n";
for $projname ( keys %projattmap ) {
    say "working on project: $projname";
     if ( @matchexclude = grep { $_ eq $projname } @exclude_projects ) {
        say "excluded project identified: $projname";
        print EF "#### $projname ####\n";
        foreach my $ef ( @{ $projattmap{$projname} } ) {
            print EF "${ef}\n";
        }
    } else {
        say "target project identified:$projname";
        print TF "#### $projname ####\n";
        print TF "mysql -uroot -pqazxcde1231 -e \"UPDATE tracker.projects SET status=9 WHERE name=\'$projname\'\;\"\n";
        foreach my $tf ( @{ $projattmap{$projname} } ) {
            if (-e $tf) {
                say "File $tf located";
                print TF "rm ${tf}\n";
            } else {
                print "File $tf doesn't exist\n";
            }
        }
    }
}

close TF;
close EF;

$sth->finish();
$dbh->disconnect();

sub loadattfiles {
    my ($floc) = @_;
    opendir (DIR, "$floc") or die "Can not open $floc: $!\n";
    my @files = readdir(DIR);
    foreach my $file (@files) {
        next if $file =~ /^\.\.?$/;
        my $file_full_path = $floc."/".$file;
        if (-d $file_full_path) {
            &loadattfiles($file_full_path);
        } else {
            push (@attfiles,$file_full_path);
        } 
    }
}
