#!/usr/bin/perl

use strict;
use Getopt::Long;
use Net::FTP;
use Net::Netrc;
use Data::Dumper;
use Date::Manip;

my (@remote_contents,$rev,$prompt);
my ($machine,$user,$password,$ftp);
my $debug = 1;

if ( $#ARGV < 0 ) {
    $prompt=0;
    print "Usage: $0 revision. Ex r05.1\n";
    exit (1);
} else {
    $rev=$ARGV[0];
}

my $remote_server="ftp.perforce.com";
my $remote_dir="/perforce";
my $primary_release_area="/projects/IT_SCM/tools/perforce/releases";
my $p4_release_dir="/perforce/${rev}";
my @os = ('bin.linux24x86', 'bin.linux26amd64', 'bin.ntx86', 'bin.solaris8sparc', 'bin.linux26x86');

main();
exit;

sub main {

# Using ~/.netrc file. Must have 600 permission with the following contents
# machine ftp.perforce.com
# login anonymous
# password email@broadcom.com


    if (debug) {
        print "Getting netrc information\n";
        print "$remote_server\n";
    }
    $machine = Net::Netrc->lookup($remote_server);
    $user = $machine->login();
    $password = $machine->password();

    # FTP connect
    if (debug) {
        print "FTP connecting...\n";
    }
    $ftp = new Net::FTP($remote_server) or die "Can not connect to FTP server $remote_server:" .ftp->message;
    $ftp->login("$user","$password") or die "Invalid login:". $ftp->message;
    $ftp->binary();


    # Create top release directory
    mkdir ("${primary_release_area}/${rev}",0777) if !-e "${primary_release_area}/${rev}";
    foreach my $wd (@os) {
        mkdir ("${primary_release_area}/${rev}/${wd}",0777) if !-e "${primary_release_area}/${rev}/${wd}";

        chdir("${primary_release_area}/${rev}/${wd}");
        &get_it($wd);
    }

# Get out
    $ftp->quit;
    
}

sub get_it {
    my ($os_dir) = @_;
    $ftp->cwd("$p4_release_dir/$os_dir") or die "Can't cd to Perforce release area for $p4_release_dir/$os_dir:" . $ftp->message;
    @remote_contents = $ftp->ls(".") or die $ftp->message;
    if ($debug) {
        print "dumping out contents\n";
        print Dumper(@remote_contents);
    }
    foreach (@remote_contents) {
        if ($debug) {
            print "Getting file $_\n";
	}
        $ftp->get("$_");
    }

}
