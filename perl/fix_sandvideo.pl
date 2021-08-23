#!/tools/perl/5.8.0/SunOS/bin/perl

use strict;
use Data::Dumper;

my (%pr_map,$file,$pr_num,$platform);

my $pr_edit="/tools/gnats/4.0/SunOS/libexec/gnats/pr-edit";
my $database_name="SandVideo";
my $database_dir_old="/tools/gnats/4.0/share/gnats/db-sandvideo-old";
my $database_dir_new="/tools/gnats/4.0/share/gnats/db-sandvideo";
my $server="gnats-irva-3";
my $port="1530";

if ($#ARGV < 0) {
        print "Usage: $0 file \n";
        exit (1);
} else {
       $file=$ARGV[0];
}

open(FILE,"$file") or die "Can't open file: $!\n";
while(<FILE>) {
    chop($_);
    ($pr_num,$platform) = split(/:/,$_);
    $pr_map{$pr_num}=$platform;
}

#print Dumper(\%pr_map);

system("$pr_edit --host=$server --port=$port --database=$database_name -v gnats4 -w emsggn09 --lockdb");

opendir(TOPDIR, $database_dir_old) or die "Can't access $database_dir_old: $!";
while (defined ($pr_dir = readdir TOPDIR)) {
        next if -f $pr_dir;
        next if $pr_dir =~ /^\.\.?$/; # skip . and ..
        next if $pr_dir =~ /^*.tar.gz$/;
        next if $pr_dir =~ /^*.tgz$/;
        next if $pr_dir =~ /^*.\w*$/;
        next if $pr_dir =~ /^gnats-adm$/;
        next if $pr_dir =~ /^gnats-queue$/;
        next if $pr_dir =~ /^pending$/;
        print "Working on category directory $pr_dir\n";
        if (!-e "${database_dir_new}/${pr_dir}") {
                print "${database_dir_new}/${pr_dir} doesn't exists , creating directory\n";
                mkdir("${database_dir_new}/${pr_dir}",0755) or die "Can't create directory ${database_dir_new}/${pr_dir}: $!
";
        }
        opendir(CATDIR, "${database_dir_old}/${pr_dir}") or die "Can't open ${database_dir_old}/${pr_dir}: $!";
        while(defined ($pr = readdir CATDIR)) {
            next if $pr =~ /^\.\.?$/; # skip . and ..
            print "Copying data for PR $pr\n";
            open(PRFILE, "${database_dir_old}/${pr_dir}/${pr}") or die "Can't open PR file ${database_dir_old}/${pr_dir}/${pr}: $!";
            open(NEWPRFILE, ">>${database_dir_new}/${pr_dir}/${pr}") or die "Can't create the new PR file ${database_dir_new}/${pr_dir}/${pr}: $!";
            while(<PRFILE>) {
                if (/^>Platform/) {
                    print NEWPRFILE ">Platform:\t$pr_map{$pr}\n";
                } else {
                    print NEWPRFILE  $_;
                } 
            }
            close(PRFILE);
        }
        close(CATDIR);
}
close(TOPDIR);

system("$pr_edit --host=$server --port=$port --database=$database_name -v gnats4 -w emsggn09 --unlockdb");
