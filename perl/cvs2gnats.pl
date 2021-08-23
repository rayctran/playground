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
my ($database, $user, $pw, $arg_opt, $arg_value, $login, $file_list, @log, %Arg, $failed_file, $cvs_com, $dir, @comments);
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
        print "No command line options or failed cvs to gnats process detected. Please check and try again\n";
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
    my ($header,$rest);
    open(IF,"${failed_file}") or die "Can't open failed GNATS file ${failed_file}: $!\n";
    while(<IF>) {
        if ( /^LOGIN:/ ) {
            ($header,$rest)=split(/:/);
            ($login,$database,$user,$pw,$file_list)=split(/\s+/,$rest);
        } 
    }
    close(IF);
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
    my ($prhead, $pr_no, $state, $state_change, $state_value, $pr_no, @prs, $audit_text, $current_state, $files_affected, @release_fixed_value);
    my ($error, @errors, $error_messages);

    my ($do_Audit_Trail, $do_Change_Set, $do_Fix, $do_Release_Fixed, $web_cgi);

    if ($debug) { print "command line $login $database $user $pw $file_list\n"; }

    ($directory,@files)=split(/\s+/,$file_list);

    if ( "$input_method" eq "command" ) {
# Parse the log and capture the PR information if exists    
        my $infh = new IO::File "< -";
        foreach ($infh->getlines) {
            push(@comments,$_);
            next if /^Update/;
            next if /^In directory/;
            next if /^Modified Files/;
            next if /^\s+\w+/;
            next if /^Log Message:/;
            if (/^PR/) {
                $do_Audit_Trail = 1;
                chop;
                ($prhead, $pr_no, $state_value, @release_fixed_value) = split(/\s+/);
                @prs = split(/,/,$pr_no);
                $do_gnats = 1;
                if ($debug) {
                    print  "PR list\n";
                    foreach (@prs) {
                        print  "$_\n";
                    }
                    print "state_value is $state_value\n go_gnats is set to $do_gnats\n";
                }
                next;
            }
            $cvs_com .= $_;
        }
        undef $infh;
    }

    if ( "$input_method" eq "file" ) {
        my ($header,$rest);
        open(IF,"${failed_file}") or die "Can't open failed GNATS file ${failed_file}: $!\n";
        while(<IF>) {
            next if /^LOGIN/;
            next if /^Update/;
            next if /^In directory/;
            next if /^Modified Files/;
            next if /^\s+\w+/;
            next if /^Log Message:/;
            if (/^PR/) {
                ($prhead, $pr_no, $state_value, @release_fixed_value) = split(/\s+/);
                @prs = split(/,/,$pr_no);
                $do_gnats = 1;
                next; 
            }
            $cvs_com .= $_;
        } 
        close(IF);
    }

# Custom setting for the databases

    if ("$database" eq "IT-Test") {
        $web_cgi="http\:\/\/ccase-irva-1\/viewcvs\/viewcvs.cgi\/$directory";
        if ($state_value =~ /feedback/ ) {
           $do_Fix = 1;
           $do_Release_Fixed = 1;
        }
    }

# set Audit-Trail text
    if ($do_Audit_Trail) {
        $audit_text .= "CVS commit Date:\t$date_string";
        $audit_text .= "Author:\t$login\n";
        $audit_text .= "Modified Directory:\t$directory\n";
        $audit_text .= "Files:\n";
        $files_affected .= "CVS commit date:\t$date_string\n";
        foreach(@files) {
            ($edit_file,$rev)=split(/,/);
            $audit_text .= "$edit_file, revision $rev ,${web_cgi}/$edit_file\n";
            $files_affected .= "$edit_file, revision $rev\n";
        }
        $audit_text .= "CVS Comments:\n";
        $audit_text .= $cvs_com;
    
    # separator for audit-text
        $audit_text .= "--------\n";
    
        if ($debug) { print  "$date_string\nAudit-trail message\n$audit_text"; }
    }

# Connect to GNATS server
    if ($do_gnats) {
        print "Modifying GNATS database $database\n"; 
        my $db = Net::Gnats->new($host,$port);
        if (! $db->connect()) {
            $error = $db->getErrorMessage;
            if ($debug) { print  "Can't connect to gnats server: $host port $port\n$error\n"; }
            $error_messages = "Can't connect to gnats server: $host port $port. ERROR:$error\n";
            &notify("$notify_list","CVS/GNATS ERROR: Can not connect to GNATS server","$error_messages");
            die "Can't connect to gnats server: $host port $port: ERROR:$error\n";
        } else {
            if ($debug) { print  "Connected\n"; }
        }
        if (! $db->login($database,$user,$pw)) {
            $error = $db->getErrorMessage;
            if ($debug) { print  "Can't login to GNATS database $database as $user\n$error\n"; }
            $error_messages = "Can't login to GNATS database: $database as $user\n ERROR:$error\n";
            &notify("$notify_list","CVS/GNATS ERROR: Can not login to GNATS database $database","$error_messages");
            die "Can't login to gnats database: $database as user $user: ERROR:$error\n";
    
        } else {
            if ($debug) { print  "login succesful\n"; }
        }
    
# Check pr access before we modify them
        my $found_err = 0;
        my @pr_numbers = ();
        foreach my $pr_no (@prs) {
           print "Changing GNATS PR number $pr_no\n"; 
    # Lock and unlock PR just to make sure that we can
           if (! $db->lockPR($pr_no,"$user")) {
               $found_err = 1;
               $error = $db->getErrorMessage();
               if ( $error =~ /400/ ) {
                    $error_messages .= "PR $pr_no does not exists. ERROR:$error\n";
               }
               if ( $error =~ /640/ ) {
                    $error_messages .= "Can't update PR $pr_no. It appears to be locked.\n ERROR:$error\n";
               }
               if ($debug) { print "Can't update PR $pr_no. ERROR: $error\n"; }
            } else {
                $db->unlockPR($pr_no,"$user");
            }
        }

# Get a hash of all valid states and check to see if the state value is valid
        my $validstates = getStates($db);
        
        if ("$state_value" ne "") {
            if (!defined $validstates->{$state_value}) {
                $error_messages .= "Invalid state $state_value.\n";
                $found_err = 1;
            }
        }
        
        if ($found_err) {
            my $failed_file_out = "/tmp/.cvsgnatsfailed_${login}";
            $error_messages .= "File $failed_file_out created. Please edit this file.\n";
            $error_messages .= "Fix the problem then re-run the script $0.\n";
            &notify("$notify_list","CVS/GNATS ERROR: Error detected - GNATS update cancelled","$error_messages");
            $file_list = join(/_/,$file_list);
            open(FF, "> $failed_file_out") or die "Can't open failed file $failed_file_out:$!\n";
            print FF "LOGIN:$login $database $user $pw $file_list\n";
            print FF @comments;
            close(FF);
            exit;
        }

# 
    # Work on the PRs
        foreach my $pr_no (@prs) {
            my $pr = $db->getPRByNumber($pr_no);

            $db->appendToField($pr_no,"Audit-Trail","$audit_text");
            $current_state = $pr->getField('State'); 
            $state_change = 1;
            if ( "$current_state" eq "$state_value" ) {
                if ($debug) {
                   print  "Current State is already set to $state_value. State will not be change\n";
                }
                $state_change = 0;
                if ($do_Fix) {
                    print "Fix field will not be changed\n";
                    $do_Fix = 0;
                }
                if ($do_do_Release_Fixed) {
                    print "Release-Fixed field will not be changed\n";
                    $do_do_Release_Fixed = 0;
                }
            } 
            if ( "$state_value" eq "" ) {
                if ($debug) {
                    print  "No State changes specify. State will not be change\n";
                }
                $state_change = 0;
            }
            if ($debug) {  print "state_change is $state_change\n"; }

            if ($do_Change_Set) {
                $db->appendToField($pr_no,"Change_Set","$files_affected");
            }
            if ($do_Fix) {
                $db->replaceField($pr_no,"Fix","$files_affected");
            }
            if ($do_Release_Fixed) {
                $db->replaceField($pr_no,"Release-Fixed","@release_fixed_value");
            }
            if ($state_change) {
                if ($debug) {  print  "changing State to $state_value\n"; }

                if (! $db->replaceField($pr_no,'State',"$state_value","state changed by $login CVS commit")) {
                    $error = $db->getErrorMessage;
                    if ($debug) {  print  "Can not change field State to $state_value:",$error,"\n"; }
                    $error_messages = "Can not change field State to $state_value\n ERROR: $error\n";
                    &notify("$notify_list","CVS/GNATS ERROR: Can not change field State to $state_value","$error_messages");
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
