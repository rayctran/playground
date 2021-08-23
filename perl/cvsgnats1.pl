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
#use lib "/home/jims/sf/gnatsperl/gnatsperl/code";

my $host = "gnats-irva-3.broadcom.com";
my $port = "1530";

#my (%Arg %action_item);
my ($database, $user, $pw, $arg_opt, $arg_value, $login, $file_list, @log, %Arg, $failed_file, @cvs_com);
my $date_string=&UnixDate("today","%a\,%f %b %Y %H\:%M\:%S");

my $debug = 0;
my $input_method;

if ( $#ARGV < 0 ) {
# Read current directory to get any fail files
    my @failed_files = ();
    opendir(PWD,".") or die "Can't read current directory : $!\n";
    my @failed_files = grep { /^\.cvsgnatsfialed_\d+$/ } readdir(PWD);
    if ( $#failed_files == -1 ) {
        print "Could not locate any failed cvs to gnats process. Please check and try again\n";
        exit 1;
    } elsif ( scalar(@failed_files) == 1 ) {
        my $failed_file = join("",@failed_files);
    } elsif ( scalar(@failed_files) > 1 ) {
        print "Too many GNATS failed files detected. Please investiage and try again.\n";
        exit 1;
    }
    $input_method = "file";
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
}


my $notify_list = "${login}\@broadcom.com,gnats4-admin\@broadcom.com";

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

    if ($debug) {
        open(logfh,">> /tmp/cvsgnats_debug") or die "Can't open log file: $!\n";
        print logfh "command line $login $database $user $pw $file_list\n";
    }
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
        print logfh "$date_string\n";
        print logfh "Audit-trail message\n";
        foreach (@audit_text) {
            print logfh $_;
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
                    print logfh "PR list\n";
                    foreach (@prs) {
                        print logfh "$_\n";
                    }
                }
            } else {
                # push(@audit_text,$_);
            }
        }
        undef $infh;
    }
    if ( "$input_method" eq "file" ) {
        my ($header,$rest);
        open(IF,"$failed_file") or die "Can't open failed GNATS file $failed_file: $!\n";
        while(<IF>) {
            if ( /^LOGIN:/ ) {
                ($header,$rest)=split(/:/);
                ($login,$database,$user,$pw,$file_list)=split(/\s+/,$rest);
                $file_list = split(/_/,$file_list);
            } elsif (/^PR/) {
                ($prhead, $pr_no, $state, $state_value) = split(/\s+/);
            }
        } 
    }


# Connect to GNATS server
    my $db = Net::Gnats->new($host,$port);
    if (! $db->connect()) {
        $error = $db->getErrorMessage;
        if ($debug) {
            print logfh "Can't connect to gnats server: $host port $port\n";
            print logfh "$error\n";
        }
        $mailmessage = "Can't connect to gnats server: $host port $port. ERROR:$error\n";
        &notify("$notify_list","CVS/GNATS ERROR: Can not connect to GNATS server","$mailmessage");
        die "Can't connect to gnats server: $host port $port: ERROR:$error\n";
    } else {
        if ($debug) {
            print logfh "Connected\n";
        }
    }
    if (! $db->login($database,$user,$pw)) {
        $error = $db->getErrorMessage;
        if ($debug) {
            print logfh "Can't login to GNATS database $database as $user\n";
            print logfh "$error\n";
        }
        $mailmessage = "Can't login to GNATS database: $database as $user\n ERROR:$error\n";
        &notify("$notify_list","CVS/GNATS ERROR: Can not login to GNATS database $database","$mailmessage");
        die "Can't login to gnats database: $database as user $user: ERROR:$error\n";

    } else {
        if ($debug) {
            print logfh "login succesful\n";
        }
    }

# Check pr access before we modify them
    my $found_err = 0;
    my @error_messages = ();
    my @pr_numbers = ();
    foreach my $pr_no (@prs) {
       if (! $db->getPRByNumber($pr_no)) {
            $found_err = 1;
            $error = $db->getErrorMessage;
            push(@error_messages, "Invalid PR number $pr_no\n ERROR:$error\n");
            if ($debug) {
                print "Invalid PR number $pr_no:",$error,"\n";
            }
       }
       if (! $db->appendToField($pr_no,"Change_Set","$file_list")) {
           $found_err = 1;
           $error = $db->getErrorMessage();
           if ( $error =~ /640/ ) {
                push(@error_messages, "Can not update PR $pr_no. It appears to be locked ERROR:$error\n");
           }
           if ($debug) {
                print "Can't update PR $pr_no. ERROR: $error\n";
           }
        }
    }
    
    if ($found_err) {
        push(@error_messages,"Please fix the problem then re-run the script");
        &notify("$notify_list","CVS/GNATS ERROR: Error detected - GNATS update cancelled","@error_messages");
        open(FF,">./cvsgnatsfailed_$$") or die "Can't open failed file .cvsgnatsfailed_$$:!$ \n";
        $file_list = join(/_/,$file_list);
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
        my $state_changed = 1;
        if ( "$current_state" eq "$state_value" ) {
            if ($debug) {
               print logfh "Current State is already set to $state_value. State will not be change\n";
            }
            my $state_changed = 0;
        } 
        if ( "$state_value" eq "" ) {
            if ($debug) {
                print logfh "No State changes specify. State will not be change\n";
            }
            my $state_changed = 0;
        }
        if ($state_changed) {
            if (! $db->replaceField($pr_no,'State',"$state_value","state changed by $login CVS commit")) {
                $error = $db->getErrorMessage;
                if ($debug) {
                    print logfh "Can not change field State to $state_value:",$error,"\n";
                }
                $mailmessage = "Can not change field State to $state_value\n ERROR: $error\n";
                &notify("$notify_list","CVS/GNATS ERROR: Can not change field State to $state_value","$mailmessage");
                die "Can't change field State to $state_value: ERROR:$error\n";
            }
        } 
    }
    $db->disconnect; 

    if ($debug) {
        close(logfh);
    }
}
