#!/tools/perl/5.8.0/SunOS/bin/perl

use strict;
use Getopt::Long;
use Net::FTP;
use Net::Netrc;
use Data::Dumper;

my ($user,$password,@beijing_contents);
my $server="ccase-peka-1.cn.broadcom.com";
my $packet_dir="/projects/ccstgloc-bse/shipping/ms_ship/test";
my $remote_user="vobadm";
my $destination_dir="shipping/ms_ship/test";
my (%irvine_files,%beijing_files);

sub main  {
    my ($machine,@beijing_contents,$my_file);

    $machine = Net::Netrc->lookup($server);
    $user = $machine->login;
    $password = $machine->password;
    print "Huh???$user $password\n";

# get netrc information
    my ($netrc,$machine,$my_file,$user,$password,$ftp);
    my ($file_size);

    $machine = Net::Netrc->lookup($server);
    $user = $machine->login();
    $password = $machine->password();

    $ftp = new Net::FTP($server);
    $ftp->login("$user","$password") or die "$ftp->message";
    $ftp->binary();
    $ftp->cwd($destination_dir);

# get the contents of the outgoing shipping directory so we can send it
    chdir($packet_dir);
    opendir(DIR,$packet_dir) or die "Can't read directory $packet_dir: $!\n";
    while( defined($my_file = readdir(DIR)) ) {
        next if $my_file =~ /^\.\.?$/;     # skip . and ..
        $file_size=(stat($my_file))[7];
        $irvine_files{$my_file}=$file_size;
        print "sending file $my_file\n";
        $ftp->put($my_file);
    }
    closedir(DIR);
    $ftp->quit;

# get the contents of the Beijing site so we can compare
    &get_remote_files;
    print Dumper(%irvine_files);
    print Dumper(%beijing_files);

# compares files


# compares sizes
}

sub get_remote_files {
    my ($ftp,$item);
    my ($perm,$id,$uid,$gid,$file_size,$mon,$date,$time,$file_name);
    print "$user $password $destination_dir test\n";
    $ftp = new Net::FTP($server);
    $ftp->login("$user","$password") or die "$ftp->message";
    $ftp->binary();
    @beijing_contents = $ftp->dir($destination_dir) or die $ftp->message;
    print "" . $ftp->message;
    $ftp->quit;

    foreach $item (@beijing_contents) {
        next if $item  =~ /^total/;
       # print "$item\n";
        ($perm,$id,$uid,$gid,$file_size,$mon,$date,$time,$file_name) = split(/\s+/, $item); 
        print "$file_name is $file_size\n"; 
        $beijing_files{$file_name}=$file_size;
    }

}

main();
exit;
