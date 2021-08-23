#!/tools/perl/5.6.0/SunOS/bin/perl

########################################################################
#
# File   :  p4gnats.pl
# History:  01-May-2004 raytran
#
########################################################################
#
# Script to update GNATS from Perforce
# version 1.0
#
# Command Line usage 
# "Usage: $0 -cfg {P4 config file}\n";
# or 
# detect fail files .p4gnatsfialed_$$
#
#
########################################################################


use strict;
use IO::File;
use Net::Gnats;
use Date::Manip;
use Mail::Sendmail;

my $host = "gnats-irva-3.broadcom.com";
my $port = "1530";

#my (%Arg %action_item);
my ($database, $user, $pw, $arg_opt, $arg_value, $login, $cfg_file, @log, $failed_file, @cvs_com, $dir);
my $date_string=`date`;

my $debug = 0;
my $debug_file = "/tmp/p4gnats_debug";
my $input_method;
my $me;
chop($me=`whoami`);


my $p4 = "/tools/bin/p4";
# Default counter is p4notifyd. This can be overwritten by the config file
my $p4counter = "p4notifyd";

if ( $#ARGV > 0 ) {
    my %Arg=@ARGV;
    while(($arg_opt,$arg_value)=each %Arg) {
        if ($arg_opt =~ /-cfg/) {
            $cfg_file = $arg_value;
        }
    }
    $input_method = "command";
} else {
    print "Usage: $0 -cfg {P4 config file}\n";
    exit 1;

}


# Reads P4 config file and build the p4 command
# The following are the only options that will be read
# P4CLIENT=host
# P4PORT=host:port
# P4USER=username (must have review previledge
# P4PASSWD=password for previous user
# P4COUNTER=counter
# GNATSDB=database
# GNATSUSER=user
# GNATSPASSWD=pw
# 

my ($p4user, $p4passwd);
open(CFG,"$cfg_file") or die "Can't read config file $cfg_file:$!. Please try again\n";
while (<CFG>) {
    chomp;
    s/#.*//;                # no comments
    s/^\s+//;               # no leading white
    s/\s+$//;               # no trailing white
    next unless length;     # anything left?
    my ($var, $value) = split(/\s*=\s*/, $_, 2);
    if ( $var =~ /P4CLIENT/ ) {
        $p4 = "$p4 -c $value";
    }
    if ( $var =~ /P4PORT/ ) {
        $p4 = "$p4 -p $value";
    }
    if ( $var =~ /P4USER/ ) {
        $p4 = "$p4 -u $value";
    }
    if ( $var =~ /P4PASSWD/ ) {
        $p4 = "$p4 -P $value";
    }
    if ( $var =~ /P4COUNTER/ ) {
        $p4counter = "$value";
    }
    if ( $var =~ /GNATSDB/ ) {
        $database = "$value";
    }
    if ( $var =~ /GNATSUSER/ ) {
        $user = "$value";
    }
    if ( $var =~ /GNATSPASSWD/ ) {
        $pw = "$value";
    }
}

if ($debug) { print "p4 is $p4\n"; }


my $notify_list = "gnats4-admin\@broadcom.com";

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

sub runp4cmd
{
  my ($cmd, $exit_on_err, $log, $notty) = @_;
  my ($sts, $output, $Myname);

  # May want to flip this on for debugging
  #
  if (0) { &msg("$Myname; $cmd\n", $log, $notty); return 0; }

  &msg("$Myname> $cmd\n", $log, $notty);

  if (! open(CMD, "$cmd 2>&1 |"))
    {
      &msg("$Myname: can't open \"$cmd 2>&1 |\": $!\n", $log, $notty);
      if ($exit_on_err) { exit $sts; }
      return 1;
    }

  while (<CMD>)
    {
      &msg(": $_", $log, $notty);
      $output .= $_;
    }
  close CMD;

  if ($sts = $?)
    {
      my $sig = $sts & 0x0f;
      $sts = $sts >> 8;
      &msg("$Myname: *** \"$cmd\" exited with signal $sig status $sts\n", $log, $notty);
      if ($exit_on_err) { exit $sts; }
    }
  return ($sts, $output);
}

sub notify {
    my($sendto,$subject,$message)=@_;
    my %mail = (
            smtp    => 'smtphost.broadcom.com',
            to      => $sendto,
            from    => "gnats4\@broadcom.com",
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
    my ($prhead, $pr_no, $state, $state_value, $pr_no, @prs, $audit_text, $current_state);
    my ($error, @errors, $mailmessage);

# P4 specific 
    my (@p4change_list, $p4client_name, $p4change_date, $p4change_no, $p4topchange, $p4changed_by);
    my ($p4files_changed);
    if ($debug) { print  "command line $database $user $pw \n"; }

    my $found_cntr = 0;
    open(COUNTERS, "$p4 counters |") or die "Can't run p4 counters command: $!\n";
    while(<COUNTERS>) {
        if ( $_ =~ /^$p4counter/ ) {
            $found_cntr = 1;
        }
        if ( $_ =~ /^Access/ ) {
            $error = "Account $p4user does not exists.\n";
        }
        if ( $_ =~ /P4PASSWD/ ) {
            $error = "Account $p4user password is incorrect.\n";
        }
    }
    if ($found_cntr == 0) {
        $mailmessage = "Can't connect check counter $p4counter: ERROR:$error\n";
        &notify("$notify_list","P4/GNATS ERROR: Can not check counter $p4counter","$mailmessage");
        die "Can't check counter $p4counter: ERROR:$error\n";
    }

    open(REVIEW, "$p4 review -t $p4counter |") or die "Can't run p4 review: $!\n";
    while(<REVIEW>) {
        my($p4change, $p4user, $p4email, $p4fullname) = /Change (\d*) (\S*) <(\S*)> ((.*))/;
        push(@p4change_list,$p4change);
        $p4topchange = $p4change;
        if ($debug) { print "$p4change, $p4user, $p4email, $p4fullname\n"; }
    }
    close REVIEW;

    foreach my $p4change_no (@p4change_list) {
        if ($debug) { print "current change number is $p4change_no\n"; }
        undef $audit_text;
        open(DESCRIBE, "$p4 describe -s $p4change_no |") or die "Can't run p4 describe: $!\n";
        while(<DESCRIBE>) {
#           if ($debug) {print $_;}
            chop;
            if (/^Change\s*(\d+)\s*by\s*(\w*)@([^@\s]+) on (\d\d\d\d\/\d\d\/\d\d \d\d:\d\d:\d\d)/ ) {
                $p4change_no = $1; 
                $p4changed_by = $2; 
                $p4client_name = $3; 
                $p4change_date = $4; 
#                if ($debug) { print "describe info $p4change_no, $p4changed_by, $p4client_name, $p4change_date\n"; }
               $audit_text .= "Commit Date:\t$p4change_date\n";
               $audit_text .= "Author:\t$p4changed_by on Client:\t$p4client_name\n";
               $audit_text .= "Change Number:\t$p4change_no\n";
               $audit_text .= "File Changed:\n";
            }
            
#           if (/^Jobs fixed .../ || /^Affected files .../) { $state = "pass"; }
            if (/^\.\.\.\s([^@\s]+)\s*\w*/) { 
                my $p4files_changed = $1;
                $audit_text .= "$p4files_changed\n";
            }
            if (/^\s*PR\s([^@\s]+)\s*(state)*\s*(\w)*/) {
                chop;
                $pr_no = $1;
                @prs = split(/,/,$pr_no);
                if ($debug) {
                    print  "PR list ";
                    foreach (@prs) { print "$_ "; }
                    print "\n";
                }
            }
        }
        close(DESCRIBE);

        if ($debug) {
            print  "\nchange date $p4change_date\n";
            print  "Audit-trail message\n";
            print  $audit_text;
        }

    # Connect to GNATS server
        my $db = Net::Gnats->new($host,$port);
        if (! $db->connect()) {
            $error = $db->getErrorMessage;
            if ($debug) {
                print  "Can't connect to gnats server: $host port $port\n";
                print  "$error\n";
            }
            $mailmessage = "Can't connect to gnats server: $host port $port. ERROR:$error\n";
            &notify("$notify_list","P4/GNATS ERROR: Can not connect to GNATS server","$mailmessage");
            die "Can't connect to gnats server: $host port $port: ERROR:$error\n";
        } else {
            if ($debug) { print  "Connected\n"; }
        }
        if (! $db->login($database,$user,$pw)) {
            $error = $db->getErrorMessage;
            if ($debug) {
                print  "Can't login to GNATS database $database as $user\n";
                print  "$error\n";
            }
            $mailmessage = "Can't login to GNATS database: $database as $user\n ERROR:$error\n";
            &notify("$notify_list","P4/GNATS ERROR: Can not login to GNATS database $database","$mailmessage");
            die "Can't login to gnats database: $database as user $user: ERROR:$error\n";
    
        } else {
            if ($debug) { print  "login succesful\n"; }
        }
    
    # Check pr access before we modify them
        my $found_err = 0;
        my @error_messages = ();
        my @pr_numbers = ();
        foreach my $pr_no (@prs) {
           if ($debug) { print  "checking...\n"; }
           if (! $db->getPRByNumber($pr_no)) {
                $found_err = 1;
                $error = $db->getErrorMessage;
                push(@error_messages, "Invalid PR number $pr_no\n ERROR:$error\n");
                if ($debug) {
                    print "Invalid PR number $pr_no:",$error,"\n";
                }
           }
    # Lock and unlock PR just to make sure that we can
           if (! $db->lockPR($pr_no,"$user")) {
               $found_err = 1;
               $error = $db->getErrorMessage();
               if ( $error =~ /640/ ) {
                    push(@error_messages, "Can not update PR $pr_no. It appears to be locked.\n ERROR:$error\n");
               }
               if ($debug) {
                    print "Can't update PR $pr_no. ERROR: $error\n";
               }
            } else {
                $db->unlockPR($pr_no,"$user");
            }
        }
        
        if ($found_err) {
            push(@error_messages,"Please fix the problem then re-run the script $0.\n");
            &notify("$notify_list","P4/GNATS ERROR: Error detected - GNATS update cancelled","@error_messages");
            exit 1;
        }
        
    
    # Work on the PRs
        foreach my $pr_no (@prs) {
            if ($debug) { print "working on $pr_no\n"; }
            my $pr = $db->getPRByNumber($pr_no);
    #        $db->appendToField($pr_no,"Change_Set","$file_list");
            $db->appendToField($pr_no,"Audit-Trail","$audit_text");
#            my $valid_states = getStates($db);
#            $current_state = $pr->getField('State'); 
#            my $state_changed = 1;
#            if ( "$current_state" eq "$state_value" ) {
#                if ($debug) { print  "Current State is already set to $state_value. State will not be change\n"; }
#                my $state_changed = 0;
#            } 
#            if ( "$state_value" eq "" ) {
#                if ($debug) { print  "No State changes specify. State will not be change\n"; }
#                my $state_changed = 0;
#            }
#            if ($state_changed) {
#                if (! $db->replaceField($pr_no,'State',"$state_value","state changed by $login P4 commit")) {
#                    $error = $db->getErrorMessage;
#                    if ($debug) { print  "Can not change field State to $state_value:",$error,"\n"; }
#                    $mailmessage = "Can not change field State to $state_value\n ERROR: $error\n";
#                    &notify("$notify_list","P4/GNATS ERROR: Can not change field State to $state_value","$mailmessage");
#                    die "Can't change field State to $state_value: ERROR:$error\n";
#                }
#            } 
        }
        $db->disconnect; 
        system("$p4 review -c $p4change_no -t $p4counter"); 
    }
}
