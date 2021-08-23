#!/tools/perl/5.8.0/SunOS/bin/perl

use strict;
use Getopt::Long;
use Net::FTP;
use Net::Netrc;

#my ($user, $password);
my $server="ccase-peka-1.cn.broadcom.com";
my $packet_dir="/projects/ccstgloc-bse/shipping/ms_ship/test";
my $remote_user="vobadm";
my $destination_dir="shipping/ms_ship/incoming";

sub main  {
    my ($machine,@beijing_contents,$item,$my_file);
    my ($user, $password);

    $machine = Net::Netrc->lookup($server);
    $user = $machine->login;
    $password = $machine->password;
    print "Huh???$user $password\n";
}

main();
exit;
