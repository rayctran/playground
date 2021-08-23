#!/tools/perl/5.8.0/SunOS/bin/perl

use strict;
use Getopt::Long;
use Net::FTP;
use Net::Netrc;
#use Date::Manip;

my ($cc,$mt,$notify,$user,$password,$ftp,$log_message,$error_message,$time_stamp);
my (%irvine_files,%beijing_files,@beijing_contents);
my (@not_found,@resend_files);

my $ct="/usr/atria/bin/cleartool";
my $mt="/usr/atria/bin/multitool";
my $server="ccase-peka-1.cn.broadcom.com";
my $packet_dir="/projects/ccstgloc-bse/shipping/ms_ship/test";
my @vobs=("rockford", "UCM-Projects", "BSSS", "BSEAV", "magnum", "DVTSJ", "SetTop", "CommEngine", "TestTools");
my $destination_dir="shipping/ms_ship/test";
my $notify_list="vobadm\@broadcom.com";
my $replica_desig="BJ_";
my $packet_max_size="1000M";
my $today = `date +"%d-%m-%Y"`;
chop($today);

my $debug=1;
my $do_ftp=0;

sub main {
    chop($time_stamp=`date +"%d%m%Y_%H_%M"`);
    my $found_vob=0;
    my $found_replica=0;
    my ($current_vob,$packet_name,$beijing_replica,$replica_list,$found_replica);
    my ($my_file,$file_size);

    foreach $current_vob (@vobs) {
        $packet_name="${packet_dir}/${current_vob}_${time_stamp}";
        if ($debug) {
            print "Working on VOB $current_vob\n";
            print "Packet name is $packet_name\n";
        }
        # verify that the VOB exists
        open(LSVOB,"$ct lsvob -s /vobs/$current_vob 2>&1|");
        while(<LSVOB>) {
            if ( $_ =~ /$current_vob/ ) {
                $found_vob=1;
                $log_message .= "VOB $current_vob found\n";
                if ($debug) {
                    print "found_vob set to $found_vob\n";
                }
            }
            if ( $_ =~ /cleartool: Error: No matching entries found/ ) {
                if ($debug) {
                    print "$_\n";
                }
                $error_message .= $_;
            } 
        }
        close(LSVOB);
        # check for the Beijing's replica
        open(LSREP, "$ct lsreplica -s -invob /vobs/$current_vob 2>&1 |");
        while(<LSREP>) {
            print "$_";
            if ( $_ =~ /^$replica_desig/ ) {
                chop($beijing_replica=$_);
                $found_replica=1; 
                $log_message .= "Beijing Replica $_ found\n";
                if ($debug) {
                    print "found replica $beijing_replica\n";
                }
            }
            $replica_list .= $_;
        }
        close(LSREP);
        if (!$found_replica) {
            $log_message .= "Beijing replica not found. Available replicas are\n";
            $log_message .= $replica_list;
            if ($debug) {
                print "Beijing replica not found. Available replicas are\n";
                print "$replica_list";
            }
        }

# removed for testing
        # Creating an export packet
    #    open(SYNCREP, "$mt syncreplica -export -maxsize $packet_max_size -out $packet_name $beijing_replica\@/vobs/${current_vob} 2 >&1 |");
    #    while(<SYNCREP>) {
    #        if ($_ =~ /Removing empty packet/) {
    #            $log_message .= "No updates for replica $beijing_replica\@/vobs/${current_vob}\n";
    #        } 
    #    }
    #    close(SYNCREP);
    }

# FTP Section

# get netrc information 

    &get_netrc_info;
    &ftp_connect;

# get the contents of the outgoing shipping directory so we can send it
    chdir($packet_dir);
    opendir(DIR,$packet_dir) or die "Can't read directory $packet_dir: $!\n";
    while( defined($my_file = readdir(DIR)) ) {
        next if $my_file =~ /^\.\.?$/;     # skip . and ..    
        $file_size=(stat($my_file))[7]; 
        $irvine_files{$my_file}=$file_size;
        $log_message .= "Attempt to send file $my_file size=$file_size\n";
        &ftp_send_file($my_file);
    }
    closedir(DIR);
    &ftp_disconnect;

# get the contents of the Beijing site so we can compare
    &ftp_connect;
    &ftp_get_remote_files; 
    &ftp_disconnect;

# process @beijing_contents and put them in hash
    undef %beijing_files;
    my ($perm,$id,$uid,$gid,$mon,$date,$time);
    foreach (@beijing_contents) {
        next if $_  =~ /^total/;
        ($perm,$id,$uid,$gid,$file_size,$mon,$date,$time,$my_file) = split(/\s+/, $_);
       # print "$_ is $file_size\n";
        $beijing_files{$_}=$file_size;
    }
    
# compares files in Irvine with Beijing
# if file is not located in beijing, put filename into array not_found
    $log_message .= "Verifying files...\n";
    @not_found=();
    foreach (keys %irvine_files) {
        $log_message .= "File $_ not found in Beijing. Add to resend list\n";
        push(@not_found, $_) unless exists $beijing_files{$_};
    }

    if ( $#not_found > 0 )   {
        push (@resend_files, @not_found);
    }

# compares file sizes to make sure Beijing has all the data
# if the file size are different, put the files into the removal
# list and the resend list
    $log_message .= "Checking Beijing file sizes...\n";
    my @remove_files;
    foreach (keys %beijing_files) {     
        if ( $irvine_files{$_} != $beijing_files{$_} ) {
            $log_message .= "File $_ in Beijing sizes $beijing_files{$_} does not match Irvine file size $irvine_files{$_}\n";
            push(@remove_files,$_);
        } 
    }

# clean up files that is not the same size as Irvine
# then resend all files in resend files list

    &ftp_connect;
    foreach (@remove_files) {
        $log_message .= "Removing file $_ in Beijing due to incomplete transfer\n";
        $log_message .= "File will be resent\n";
        &ftp_rm_file($_);
    }
    foreach (@resend_files) {
        $log_message .= "Sending file $_ to Beijing\n";
        &ftp_send_file($_);
    }
    &ftp_get_remote_files; 
    $log_message .= "Listing out contents of Beijing for manually verification\n";
    my $item;
    foreach $item (@beijing_contents) {
        next if $item  =~ /^total/;
        $log_message .= "$_";
         
    }
    &ftp_disconnect;

# send Email
    &notify($notify_list,"Beijing MultiSite Replica transfer log for $today",$log_message);
    
}

sub get_netrc_info {
    my ($machine);
    $machine = Net::Netrc->lookup($server); 
    $user = $machine->login();
    $password = $machine->password();
}

sub ftp_connect {
    $ftp = new Net::FTP($server);
    $ftp->login("$user","$password") or die "$ftp->message";
    $ftp->binary();
    $ftp->cwd($destination_dir);
}

sub ftp_send_file {
    my $send_this_file=@_;
    $ftp->put($send_this_file);
}

sub ftp_rm_file {
    my $rm_this_file=@_;
    $ftp->delete($rm_this_file);
}

sub ftp_disconnect {
    $ftp->quit;
}

sub ftp_get_remote_files {
    # make sure Beijing tracking array hash are blank
    undef @beijing_contents;
    @beijing_contents = $ftp->dir($destination_dir);

}

sub notify {
    use Mail::Sendmail;
    my($sendto,$subject,$message)=@_;
    my %mail = (
            smtp    => 'smtphost.broadcom.com',
            to      => $sendto,
            from    => "vobadm\@broadcom.com",
            subject => $subject,
            message => $message,
    );

    eval { sendmail(%mail) || die $Mail::Sendmail::error; };
    $Mail::Sendmail::log;

    if ($@) {
            print "mail could NOT be sent correctly - $@\n";
    } else {
            print "mail sent correctly\n";
    }

}

main;
exit;
