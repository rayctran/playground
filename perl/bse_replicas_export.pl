#!/tools/perl/5.8.0/SunOS/bin/perl

#################################################################
#                                                               #
# remote_replicas_export.pl                                    #
#                                                               #
# Generates Beijing packes and send them via FTP                #
#                                                               #
# Author: Ray Tran                                              #
# Modify: Ray Tran                                              #
# Rev: 1.0 - Add in multidirectional between Irvine and China   #
#################################################################


use strict;
use Getopt::Long;
use Net::FTP;
use Net::Netrc;
use Data::Dumper;
use Date::Manip;

my $debug=0;

my ($cc,$mt,$notify,$user,$password,$ftp,$log_message,$error_message,$time_stamp,$current_log_file);
my ($log_dir,$packet_dir,$destination_dir,$archive_dir);
my (%local_files,%remote_files,@remote_contents);
my (@not_found,@resend_files,$my_host,$remote_server,$replica_desig,$remote_site,$local_site);

my $ct="/usr/atria/bin/cleartool";
my $mt="/usr/atria/bin/multitool";
my $date = UnixDate("today","%d");
my $month = UnixDate("today","%b");
my $year = UnixDate("today","%Y");

chop($my_host=`hostname`);

#
# detects which host we're running on so we can decide which direction to FTP to
# 
if ($my_host !~ /ccase-irva-2|ccase-peka-1/) {
    print "INVALID HOST $my_host.\nYou must run this script on either ccase-irva-2 or ccase-peka-1\n";
    print "Please try again.\n";
    exit(1);
}

my @vobs=("rockford","UCM-Projects","BSSS","BSEAV","magnum","DVTSJ","SetTop","CommEngine","TestTools","CFE","kylin");

#my $notify_list="vobadm\@broadcom.com";
my $notify_list="clearcase-bse-admin-list\@broadcom.com";

# set the archive flag
my $archive=1;

if ( $my_host =~ /ccase-irva-2/ ) {
    $replica_desig="BJ_";
    $remote_server="ccase-peka-1.cn.broadcom.com";
    $remote_site="Beijing";
    $local_site="Irvine";
    $destination_dir="shipping/ms_ship/incoming";
}
if ( $my_host =~ /ccase-peka-1/ ) {
    $remote_server="ccase-irva-2.broadcom.com";
    $remote_site="Irvine";
    $replica_desig="IRV";
    $local_site="Beijing";
    $destination_dir="/var/adm/rational/clearcase/shipping/ms_ship/incoming";
    $archive_dir="/projects/ccstgloc-bse/shipping/ms_ship/archive/${year}/${month}_${date}";
}

if ($debug) {
    print "Local Server ccase-irva-2\n";
}

$log_message .= "Local Server $my_host\n";
$log_dir="/home/vobadm/logs/${remote_site}/${year}/${month}/${date}";
$current_log_file="/home/vobadm/logs/${remote_site}/current";
$archive_dir="/projects/ccstgloc-bse/shipping/ms_ship/archive/${year}/${month}_${date}";

if ($debug) {
    $packet_dir="/projects/ccstgloc-bse/shipping/ms_ship/test";
    $destination_dir="shipping/ms_ship/test";
} else {
    $packet_dir="/projects/ccstgloc-bse/shipping/ms_ship/outgoing";
}

my $packet_max_size="1000M";
my $today = `date +"%d-%m-%Y %H:%M"`;
chop($today);

my $do_ftp=0;
my $email_subject = "$remote_site MultiSite Replica transfer log for $today";

sub main {
    chop($time_stamp=`date +"%d%m%Y_%H_%M"`);
    my $found_vob=0;
    my $found_replica=0;
    my ($current_vob,$packet_name,$remote_replica,$replica_list,$found_replica);
    my ($my_file,$file_size,@send_files);

    foreach $current_vob (@vobs) {
        $packet_name="${packet_dir}/${current_vob}_${time_stamp}";
        if ($debug) {
            print "Working on VOB $current_vob\n";
            print "Packet name is $packet_name\n";
        }
        # verify that the VOB exists
        # log only if we can't locate the log
        open(LSVOB,"$ct lsvob -s /vobs/$current_vob 2>&1|");
        while(<LSVOB>) {
            if ( $_ =~ /$current_vob/ ) {
                $found_vob=1;
                if ($debug) {
                    print "found_vob set to $found_vob\n";
                }
            }
            if ( $_ =~ /cleartool: Error: No matching entries found/ ) {
                if ($debug) {
                    print "$_\n";
                }
                $error_message .= $_;
                $log_message .= "VOB $current_vob not found: $_\n";
            } 
        }
        close(LSVOB);
        # check for the remote replica
        # log only if we can't locate the replica
        open(LSREP, "$ct lsreplica -s -invob /vobs/$current_vob 2>&1 |");
        while(<LSREP>) {
            if ( $_ =~ /^$replica_desig/ ) {
                chop;
                $remote_replica=$_;
                $found_replica=1; 
                if ($debug) {
                    print "found replica $remote_replica\n";
                }
            }
            $replica_list .= $_;
        }
        close(LSREP);
        if (!$found_replica) {
            $log_message .= "$remote_site replica not found. Available replicas are\n";
            $log_message .= $replica_list;
            if ($debug) {
                print "$remote_site replica not found. Available replicas are\n";
                print "replica list is \n$replica_list";
            }
        }

# removed for testing
        # Creating an export packet
        open(SYNCREP, "$mt syncreplica -export -maxsize $packet_max_size -out $packet_name $remote_replica\@/vobs/${current_vob} |");
        while(<SYNCREP>) {
            if ($_ =~ /Removing empty packet/) {
                $log_message .= "No updates for replica $remote_replica\@/vobs/${current_vob}\n";
            } 
        }
        close(SYNCREP);
    }

# Build a list of files to send
    if ($debug) {
        print "Checking outgoing directory $packet_dir\n";
    }

    #
    open(CURRENT_LOG,">$current_log")
     
 
    opendir(DIR,$packet_dir) or die "Can't read directory $packet_dir: $!\n";
    while( defined($my_file = readdir(DIR)) ) {
        next if $my_file =~ /^\.\.?$/;     # skip . and ..    
        if ($debug) {
            print "$my_file\n";
        }
        $file_size=(stat("$packet_dir/$my_file"))[7]; 
        $local_files{$my_file}=$file_size;
        if ($debug) {
            print "File located in source directory $my_file size=$file_size\n";
        }
        $log_message .= "File located file $my_file size=$file_size\n";
        print CURRENT_LOG "$my_file size=$file_size\n";
        push(@send_files,"$packet_dir/$my_file");
        $do_ftp=1;
    }
    closedir(DIR);
    if ($debug) {
        print "do_ftp is set to $do_ftp\n";
        print Dumper(@send_files);
    }

# FTP Section

# track how may times we FTP over data
    my $attempts=0;

    while ($do_ftp) {

# get netrc information 
        if (debug) {
            print "Getting netrc information\n";
            print "$remote_server\n";
        }
        my ($machine);
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
        $ftp->cwd($destination_dir) or die "Can't cd to $destination_dir:" . $ftp->message;

        foreach $my_file (@send_files) {
            if (debug) {
                print "Sending file $my_file\n";
            }
            $ftp->put($my_file) or die "Can't send file $my_file:". $ftp->message;
        }
# once we processes all items from @send_file. undef it so we can use it again
        undef @send_files;

# verify files
        undef %remote_files;
        undef @remote_contents;
        @remote_contents = $ftp->dir(".") or die $ftp->message;
        if ($debug) {
            print "dumping out $remote_site contents\n";
            print Dumper(@remote_contents);
        }

# process @remote_contents and put them in hash
        my ($perm,$id,$uid,$gid,$mon,$date,$time);
        foreach (@remote_contents) {
            next if $_  =~ /^total/;
            next if $_ =~ /^\.\.?$/;     # skip . and ..
            ($perm,$id,$uid,$gid,$file_size,$mon,$date,$time,$my_file) = split(/\s+/, $_);
            $remote_files{$my_file}=$file_size;
            if (debug) {
                print "$remote_site files found $my_file size is $file_size\n";
            }
        }

# compares files in local with remote
# if file is not located in remote, put filename into array not_found
        if (debug) {
            print "Verifying files...\n";
        }
        @not_found=();
        foreach (keys %local_files) {
            if (!exists $remote_files{$_}) {
                push(@send_files, "$packet_dir/$_");
                $log_message .= "File $_ not found in $remote_site. Add to resend list\n";
                if ($debug) {
                    print "File $_ in $local_site can not be located in $remote_site\n";
                    print "Adding file to resend list\n";
                }
            } else {
                if ($debug) {
                    print "File $_ Found in $remote_site\n";
                }
                $log_message .= "File $_ Found in $remote_site\n";
            }
#            push(@send_files, "$packet_dir/$_") unless exists $remote_files{$_};
        }

# compares file sizes to make sure remote site has all the data
# if the file size are different, put the files into the removal
# list and the resend list
        if (debug) {
            print "Verifying files sizes...\n";
        }

# if the file size does not match then we remove the remote file then re-send it
        foreach (keys %remote_files) {     
            if ( $local_files{$_} != $remote_files{$_} ) {
                $log_message .= "File $_ in $remote_site sizes $remote_files{$_} does not match $local_site file size $local_files{$_}\n";
                $log_message .= "Removing file $_ from $remote_site\n";
                $log_message .= "Adding file $_ to resend list\n";
                if (debug) {
                    print "File $_ in $remote_site sizes $remote_files{$_} does not match $local_site file size $local_files{$_}\n";
                    print "Removing file $_ from $remote_site\n";
                    print "Adding file $_ to resend list\n";
                }
                push(@send_files,"$packet_dir/$_");
                $ftp->delete($_);
            }  else {
                $log_message .= "File $_ size matched $local_site=$local_files{$_}, $remote_site=$remote_files{$_}\n";
                if (debug) {
                    print "File $_ size matched $local_site=$local_files{$_}, $remote_site=$remote_files{$_}\n";
                }
            }
        }

# Quit out of FTP
        $ftp->quit;

# Everything worked out - No more files to send 
        if ( $#send_files < 0 ) {
            if ($debug) {
                print "size of send_files is $#send_files\n";
                print "Transfer completed\n";
            }
            $do_ftp=0;
            $log_message .= "Transfer completed\n";
            
        } else {
           if ($debug) {
               print "size of send_files is $#send_files\n";
               print "$do_ftp is set to $do_ftp. Looping through again?\n";
           }
           $log_message .= "Files detected on the send list. Re-sending files\n";
        }

# increment attempts
        $attempts++;

# since that was attempt number 5 we loop out and send appropriate Email so 
# that someone can take a look at the file and manaully fix it
        if ($attempts == 5) {
            $do_ftp = 0;
            $log_message .= "WARNING - THE SCRIPT HAD EXCEED $attempts attempts. Please check files manually to make all the data is there\n";
           $email_subject="WARNING - MANUAL VERIFICATION REQUIRED - $email_subject";
        }

    }

# archive files
    if ($archive) {
        if (! -d "$archive_dir") {
            print "Creating dir $archive_dir\n";
            system("mkdir -p $archive_dir; chmod 776 $archive_dir");
        }
        opendir(DIR,$packet_dir) or die "Can't read directory $packet_dir: $!\n";
        while( defined($my_file = readdir(DIR)) ) {
            next if $my_file =~ /^\.\.?$/;     # skip . and ..
            if ($debug) {
                print "archiving $my_file\n";
            }
            $log_message .= "File $my_file archived to $archive_dir\n";
            system("mv $packet_dir/$my_file $archive_dir");
        }
        closedir(DIR);
    }

# send Email cause we're done
    &notify($notify_list,"$email_subject","$log_message");
    
}

sub notify {
    use Mail::Sendmail;
    my($sendto,$subject,$message)=@_;
    my %mail = (
            smtp    => 'smtphost.broadcom.com',
            to      => $sendto,
            #from    => "vobadm\@broadcom.com",
            from    => "clearcase-bse-admin-list\@broadcom.com",
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
