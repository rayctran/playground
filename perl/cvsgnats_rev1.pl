#!/tools/perl/5.6.0/SunOS/bin/perl

########################################################################
#
# File   :  cvsgnats.pl
# History:  01-April-2004 raytran
#
########################################################################
#
# Script to update GNATS from CVS
# version 1.0
#
# Command Line usage 
# "Usage: $0 -cu {Commit User} -d {GNATS database} -u {GNATS User} -p {GNATS Password} -f {file list}\n";
# or 
# detect fail files .cvsgnatsfialed_$$
#
#
########################################################################


use strict;
use IO::File;
use Net::Gnats;
use Date::Manip;
use Mail::Sendmail;

# Use Jim Searle gnatsperl for now. We may want to put this somewhere standard
# use lib "/home/jims/sf/gnatsperl/gnatsperl/code";

my $host = "gnats-irva-3.broadcom.com";
my $port = "1530";

#my (%Arg %action_item);
my ($database, $user, $pw, $arg_opt, $arg_value, $login, $file_list, @log, %Arg, $failed_file, @cvs_com, $dir);
my $date_string=`date`;

my $debug = 1;
my $input_method;
my $me;
chop($me=`whoami`);

my $do_gnats = 0;
if ( $#ARGV < 0 ) {
# Read current directory to get any fail files
    my @failed_files = ();
    opendir(TMP,"/tmp") or die "Can't read directory: $!\n";
    my @failed_files = grep { /^\.cvsgnatsfailed_${me}$/ } readdir(TMP);
    if ( $#failed_files == -1 ) {
        print "Could not locate any failed cvs to gnats process. Please check and try again\n";
        exit 1;
    } elsif ( scalar(@failed_files) == 1 ) {
        $failed_file = join("",@failed_files);
        $failed_file = "/tmp/${failed_file}";
    } elsif ( scalar(@failed_files) > 1 ) {
        print "Too many GNATS failed files detected. Please investiage and try again.\n";
        exit 1;
    }
    $input_method = "file";
    if ($debug) { print "found file options\n"; }
} else {
    %Arg=@ARGV;
    while(($arg_opt,$arg_value)=each %Arg) {
        if ($arg_opt =~ /-cu/) {
            $login = $arg_value;
        }
        if ($arg_opt =~ /-d/) {
            $database = $arg_value;
        }
        if ($arg_opt =~ /-u/) {
            $user = $arg_value;
        }
        if ($arg_opt =~ /-p/) {
            $pw = $arg_value;
        }
        if ($arg_opt =~ /-f/) {
            $file_list = $arg_value;
        }
    }
    $input_method = "command";
    if ($debug) { print "got command line options\n"; }
}

my $notify_list = "${login}\@broadcom.com,gnats4-admin\@broadcom.com";
if ($debug) { print "running main\n"; }
main ();

# get a login name for the person doing the commit....
#
#if ($login eq '') {
#	$login = getlogin || (getpwuid($<))[0] || "nobody";
#}

# ******************************************************
# Stolen from Jim Searle
# These routines should be added to GNATS.pm.
#
# Create a categories hashref
sub getCategories {
  my $g = shift;
  return array2namehash($g->listCategories());
}
# Create a submitters hashref.
sub getSubmitters {
  my $g = shift;
  return array2namehash($g->listSubmitters());
}

sub getStates {
    my $g = shift;
    return array2namehash($g->listStates());
}

# Create a hashref from an array of arrays.
sub array2namehash {
  my $ret = {};
  foreach my $href (@_) {
    foreach my $key (keys %{$href}) {
      $ret->{$href->{name}}->{$key} = $href->{$key} if ($key ne "name")
    }
  }
  #die Dumper($ret);
  return $ret;
}

sub notify {
    my($sendto,$subject,$message)=@_;
    my %mail = (
            smtp    => 'smtphost.broadcom.com',
            to      => $sendto,
            from    => "${login}\@broadcom.com",
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

# ******************************************************

sub main {

    my ($directory, @files, $edit_file, $rev);
    my ($prhead, $pr_no, $state, $state_value, $pr_no, @prs, @audit_text, $current_state);
    my ($error, @errors, $mailmessage);
    my ($do_change_set, $do_fix, $do_release_fixed);

    if ($debug) { print "command line $login $database $user $pw $file_list\n"; }
    push(@audit_text,"CVS commit Date:\t$date_string\n");
    push(@audit_text,"Author:\t$login\n");
    
    ($directory,@files)=split(/\s+/,$file_list);
    push(@audit_text,"Modified Directory:\t$directory\n");
    push(@audit_text,"Files:\n");
    foreach(@files) {
        ($edit_file,$rev)=split(/,/);
        push(@audit_text,"$edit_file, revision $rev\n");
    }
    if ($debug) {
        print  "$date_string\n";
        print  "Audit-trail message\n";
        foreach (@audit_text) {
            print  $_;
        }
    }

    if ( "$input_method" eq "command" ) {
# Parse the log and capture the PR information if exists    
        my $infh = new IO::File "< -";
        foreach ($infh->getlines) {
            push(@cvs_com,"$_");
            if (/^PR/) {
                chop;
                ($prhead, $pr_no, $state, $state_value) = split(/\s+/);
                @prs = split(/,/,$pr_no);
                if ($debug) {
                    print  "PR list\n";
                    foreach (@prs) {
                        print  "$_\n";
                    }
                    print "state_value is $state_value\n";
                }
                $do_gnats = 1;
            } else {
                # push(@audit_text,$_);
            }
        }
        undef $infh;

        if ("$database" eq "Test-IT") {
            $do_fix = 1;
            $do_release_fixed = 1;
        }

    }

    if ( "$input_method" eq "file" ) {
        my ($header,$rest);
        open(IF,"${failed_file}") or die "Can't open failed GNATS file ${failed_file}: $!\n";
        while(<IF>) {
            if ( /^LOGIN:/ ) {
                ($header,$rest)=split(/:/);
                ($login,$database,$user,$pw,$file_list)=split(/\s+/,$rest);
           #     my @file_list = split(/_/,$file_list);
            } elsif (/^PR/) {
                ($prhead, $pr_no, $state, $state_value) = split(/\s+/);
                @prs = split(/,/,$pr_no);
                $do_gnats = 1;
            }
        } 
        close(IF);
    }

# Connect to GNATS server
    if ($do_gnats) {
        my $db = Net::Gnats->new($host,$port);
        if (! $db->connect()) {
            $error = $db->getErrorMessage;
            if ($debug) { print  "Can't connect to gnats server: $host port $port\n$error\n"; }
            $mailmessage = "Can't connect to gnats server: $host port $port. ERROR:$error\n";
            &notify("$notify_list","CVS/GNATS ERROR: Can not connect to GNATS server","$mailmessage");
            die "Can't connect to gnats server: $host port $port: ERROR:$error\n";
        } else {
            if ($debug) { print  "Connected\n"; }
        }
        if (! $db->login($database,$user,$pw)) {
            $error = $db->getErrorMessage;
            if ($debug) { print  "Can't login to GNATS database $database as $user\n$error\n"; }
            $mailmessage = "Can't login to GNATS database: $database as $user\n ERROR:$error\n";
            &notify("$notify_list","CVS/GNATS ERROR: Can not login to GNATS database $database","$mailmessage");
            die "Can't login to gnats database: $database as user $user: ERROR:$error\n";
    
        } else {
            if ($debug) { print  "login succesful\n"; }
        }
    
    # Check pr access before we modify them
        my $found_err = 0;
        my @error_messages = ();
        my @pr_numbers = ();
        foreach my $pr_no (@prs) {
           if ($debug) { print  "working on PR $pr_no\n"; }
           if (! $db->getPRByNumber($pr_no)) {
                $found_err = 1;
                $error = $db->getErrorMessage;
                push(@error_messages, "Invalid PR number $pr_no\n ERROR:$error\n");
                if ($debug) { print "Invalid PR number $pr_no:",$error,"\n"; }
           }
    # Lock and unlock PR just to make sure that we can
           if (! $db->lockPR($pr_no,"$user")) {
               $found_err = 1;
               $error = $db->getErrorMessage();
               if ( $error =~ /640/ ) {
                    push(@error_messages, "Can not update PR $pr_no. It appears to be locked.\n ERROR:$error\n");
               }
               if ($debug) { print "Can't update PR $pr_no. ERROR: $error\n"; }
            } else {
                $db->unlockPR($pr_no,"$user");
            }
        }
        
        if ($found_err) {
            my $failed_file_out = "/tmp/.cvsgnatsfailed_${login}";
            push(@error_messages,"Please fix the problem then re-run the script $0.\n");
            &notify("$notify_list","CVS/GNATS ERROR: Error detected - GNATS update cancelled","@error_messages");
            $file_list = join(/_/,$file_list);
            open(FF, "> $failed_file_out") or die "Can't open failed file $failed_file_out:$!\n";
            print FF "LOGIN:$login $database $user $pw $file_list\n";
            print FF @cvs_com;
            close(FF);
            exit 1;
        }
        
    
    # Work on the PRs
        foreach my $pr_no (@prs) {
            my $pr = $db->getPRByNumber($pr_no);
            $db->appendToField($pr_no,"Change_Set","$file_list");
            $db->appendToField($pr_no,"Audit-Trail","@audit_text");
            my $valid_states = getStates($db);
            $current_state = $pr->getField('State'); 
            my $state_change = 1;
            if ( "$current_state" eq "$state_value" ) {
                if ($debug) {
                   print  "Current State is already set to $state_value. State will not be change\n";
                }
                my $state_change = 0;
            } 
            if ( "$state_value" eq "" ) {
                if ($debug) {
                    print  "No State changes specify. State will not be change\n";
                }
                my $state_change = 0;
            }
            if ($state_change) {
                if (! $db->replaceField($pr_no,'State',"$state_value","state changed by $login CVS commit")) {
                    $error = $db->getErrorMessage;
                    if ($debug) {
                        print  "Can not change field State to $state_value:",$error,"\n";
                    }
                    $mailmessage = "Can not change field State to $state_value\n ERROR: $error\n";
                    &notify("$notify_list","CVS/GNATS ERROR: Can not change field State to $state_value","$mailmessage");
                    die "Can't change field State to $state_value: ERROR:$error\n";
                }
            } 
        }
        $db->disconnect; 
    }
    if ( "$input_method" eq "file" ) {
        unlink($failed_file);
    }
}
