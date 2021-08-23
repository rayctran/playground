#!/tools/perl/5.8.0/SunOS/bin/perl

#################################################################
#                                                               #
# bse_replicas_import.pl                                        #
#                                                               #
# import in replica packets                                     #
#                                                               #
# Author: Ray Tran                                              #
#################################################################


use strict;
use Data::Dumper;

my $debug=0;
my $ct="/usr/atria/bin/cleartool";
my $mt="/usr/atria/bin/multitool";

chop($my_host=`hostname`);
my $incoming_dir="/home/vobadm/shipping/ms_ship/incoming";
my ($log_message);
my $do_import=0;
my $today = `date +"%d-%m-%Y %H:%M"`;
chop($today);
my $email_subject = "$remote_site MultiSite Replica transfer log for $today";
my $notify_list="vobadm\@broadcom.com";


my main {

    my ($my_file,$file_size);

    opendir(DIR,$incoming_dir) or die "Can't read directory $incoming_dir: $!\n";
    while( defined($my_file = readdir(DIR)) ) {
        next if $my_file =~ /^\.\.?$/;     # skip . and ..
        if ($debug) {
            print "$my_file\n";
        }
        $file_size=(stat("$incoming_dir/$my_file"))[7];
        $local_files{$my_file}=$file_size;
        if ($debug) {
            print "File located in source directory $my_file size=$file_size\n";
        }
        $log_message .= "File located file $my_file size=$file_size\n";

        open(IMPORT, "$mt syncreplica -import $incoming_dir/$my_file |");
        while(<IMPORT>) {
            if ($_ =~ /multitool\: Error\:/) {
                .log_message .= "Filer $incoming_dir/$my_file not imported\n";
            }
            .log_message .= $_;
        }
    }

    &notify("$notify_list","$email_subject","$log_message");
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
