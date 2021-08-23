#!/usr/bin/perl

# -*-Fundamental-*-

# $Id: //public/perforce/utils/reviewd/p4notifyd.pl#2 $

#  TBD:
#   - add restart control
#

#  This is a Perforce review daemon. Originally by Richard Geiger
#
#  There are many review daemons in the world, and it's unlikely that
#  any of them will be perfect for a given Perforce site without some
#  customization. Indeed, the wonderous actions review daemons might
#  take are limited only by your imagination.
#
#  That said, here are some of the features of this one:
#
#    - runs on Unix
#    - written in perl;
#    - can run in the background rather than being reinvoked by cron;
#    - supports nifty "cc: in the description" or "cc: in the client spec"
#      feature;
#    - can log its activity if requested;
#    - special every-change notifications to a separate cc list,
#      with special subject line tags for such messages;
#    - can add a hyperlink to p4web (or some other web-based Perforce browser)
#      to display full change information
#

use Carp;
use strict;

$| = 1;

my $Myname;
($Myname = $0) =~ s%^.*/%%;
my $Myspac = $Myname;
$Myspac =~ s/./ /g;
my $Mydir = &dirname($0);
my $Here = `/bin/pwd`; chop $Here;
chdir $Mydir || die; $Mydir = `/bin/pwd`; chop $Mydir; chdir $Here || die;

my (@pwent) = getpwuid($<);
if ($#pwent < 7)
  {
    print STDERR "$Myname: can't get your passwd file entry.\n";
    exit 1;
  }
my $Username = $pwent[0];

delete $ENV{"PWD"};

my $Usage = <<USAGE;

$Myname: usage:

  $Myname [ verbose ] [ once ] [log <logfile>] [ p4port <p4port> ] [ p4config <p4config> ]
  $Myspac [ interval <secs> ] [ notify <email> ] [ self ] [ from <sender> ] 
  $Myspac [ url <url_pat \%C> ] [ subject <sub_pat \%C> ] [ help ]

USAGE


sub usage
{
  print STDERR "$Usage";
  exit 1;
}


sub help
{
  print STDERR <<LIT;
$Usage

$Myname is a p4 change review notification daemon.

Options:

  verbose              Be more verbose (for debugging, mainly)
  once                 Run once then terminate (for use with cron)
  log <logfile>        Log actions to <logfile>
  p4port <p4port>      The Perforce server to do reviews for
  p4config <p4config>  Name to use for \$P4CONFIG
  interval <secs>      Seconds to sleep between reviews (0 means the same as "once") [60]
  notify <email>       Always send a separate notification to <email>
  self                 Allow "Reviews" notifications to the user who submitted a change
  from <sender>        Set the From: header on notifications to <sender> [p4notifyd]
  url <url_pat %C>     Include a link to the change using <url_pat> (see below)
  subject <sub_pat %C> Subject line for notification messages [Perforce change %C]
  help                 Show this help message
        
Description:

  This notify daemon can be used either by being run as a periodic
  cron job (with the "once" option), or in a background mode (the
  default), in which case it will sleep for a specified interval
  (given with the "interval" option) between reviews.

  It keeps track of it's highest-numbered reviewed change with
  a counter named "p4notifyd".

Features:

  This review daemon sends notifications addressed To: users, in the
  customary manner: based on the Reviews: in their Perforce User
  Specifications.  Normally, the user submitting a change will _not_
  be included in the To: list for a notification resulting from a
  Reviews: match. (This can be overidden with the "self" option).

  There are also some other ways to cause a user to be notified (and
  these will be honored for the user submitting the change):

  cc: in the submitting client specification:

     When reviewing a change, the client specification for the client
     from which the change was submitted is examined; if the
     Description field contains a line of the format "cc: <address>[,]
     <address>[,] ...", then the indicated addresses will be cc'ed on
     the notification message for the change.

  cc: in the change description:

     Likewise, if the change description contains a line of the format
     "cc: <address>[,] <address>[,] ...", then the indicated addresses
     will be cc'ed on the notification message for the change.

  The subject line to be used for notifications can be set with the
  "subject <sub_pat %C>" option, by default "Perforce change %C".

  Finally, the daemon can be configured to send notifications of ALL
  changes unconditionally, with the "notify <email>" option. Such
  messages have a recognizable Subject: line in the form

    Subject: [ADMIN] <subject>

  hyperlink to a web based view of the change description:

     With the "url <url_pat>" option, "<url_pat> gives a pattern for a
     URL that can be used to access the change description via a web
     browser.  The pattern should contain a %C, for which the change
     number will be substituted in the actual notification message.

LIT
  exit 1;
}


#my $P4;
#if (-x "/usr/local/bin/p4")
#  { $P4 = "/usr/local/bin/p4"; }
#else
#  { die "can't find p4"; }

my $P4 = "/tools/bin/p4";


my $Notty = 1;

my $Log;
my $Notify;
my $P4port;
my $P4config;
my $Interval = 60;         # Change review interval
my $Url_pat;
my $Sub_pat = "Perforce change %C";
my $Noself = 1;
my $From = "p4notifyd";
my $Counter = "p4notifyd"; # undocumented, for debugging

my $Sendmail;		   
if (-x "/usr/lib/sendmail")
  { $Sendmail = "/usr/lib/sendmail"; }
elsif (-x "/usr/sbin/sendmail")
  { $Sendmail = "/usr/sbin/sendmail"; }
else
  { die "can't find sendmail"; }

while ($#ARGV >= 0)
  {
       if ($ARGV[0] eq "verbose")    { $Notty = 0; shift; next; }
    elsif ($ARGV[0] eq "once")       { $Interval = 0; shift; next; }
    elsif ($ARGV[0] eq "self")       { $Noself = 0; shift; next; }
    elsif ($ARGV[0] eq "log")
      { shift; if ($#ARGV < 0) { &usage; } $Log = $ARGV[0]; shift; next; }
    elsif ($ARGV[0] eq "notify")
      { shift; if ($#ARGV < 0) { &usage; } $Notify = $ARGV[0]; shift; next; }
    elsif ($ARGV[0] eq "p4port")
      { shift; if ($#ARGV < 0) { &usage; } $P4port = $ARGV[0]; shift; next; }
    elsif ($ARGV[0] eq "p4config")
      { shift; if ($#ARGV < 0) { &usage; } $P4config = $ARGV[0]; shift; next; }
    elsif ($ARGV[0] eq "interval")
      { shift; if ($#ARGV < 0) { &usage; } $Interval = $ARGV[0]; shift; next; }
    elsif ($ARGV[0] eq "url")
      { shift; if ($#ARGV < 0) { &usage; } $Url_pat = $ARGV[0]; shift; next; }
    elsif ($ARGV[0] eq "from")
      { shift; if ($#ARGV < 0) { &usage; } $From = $ARGV[0]; shift; next; }
    elsif ($ARGV[0] eq "subject")
      { shift; if ($#ARGV < 0) { &usage; } $Sub_pat = $ARGV[0]; shift; next; }
    elsif ($ARGV[0] eq "counter") # undocumented, for debugging
      { shift; if ($#ARGV < 0) { &usage; } $Counter = $ARGV[0]; shift; next; }
    elsif ($ARGV[0] eq "sendmail") # undocumented, for debugging
      { shift; if ($#ARGV < 0) { &usage; } $Sendmail = $ARGV[0]; shift; next; }
    elsif ($ARGV[0] eq "cc")
      { print "$Myname: compile check ok\n"; exit 0; }
    else { &usage; }
  }

if ($P4config) { $ENV{"P4CONFIG"} = $P4config; }

if ($P4port) { $P4 = "$P4 -p $P4port"; }


##### Normal daemon operation...
#
&msg("$Myname starting.\n", $Log, $Notty);

while (1)
  {
    &do_review;
    if ($Interval == 0) { last; } 
    sleep $Interval;
  }


sub do_review
{
  my $topchange = 0;
  &msg("do_review(): starting.\n", "", $Notty);

  if (! open(REVIEW, "$P4 review -t $Counter |")) { return; }

  Change: while(<REVIEW>)
    {
      # Format: "Change x user <email> (Full Name)"
      #
      my($change, $user, $email, $fullname) = /Change (\d*) (\S*) <(\S*)> (\(.*\))/;

      &do_notify($change, $user, $email, $fullname);
      $topchange = $change;
    }
  close REVIEW;

  if ($topchange) { &s("$P4 review -c $topchange -t $Counter", 1, $Log, $Notty); }
}


sub do_notify
{
  my($change, $user, $email, $fullname) = @_;

  &msg("===== check change $change\n", $Log, $Notty);

  # Get list of people who will be notified of this change
  #
  my $reviewers = "";

  if (! open(REVIEWERS, "$P4 reviews -c $change |")) { next; }

  while(<REVIEWERS>)
    {
      # user <email> (Full Name)
      #
      my($user2, $email2, $fullname2) = /(\S*) <(\S*)> (\(.*\))/;

      # Use next line if author shouldn't get email, too.
      #   
      if ($Noself && ($user eq $user2)) { next; }

      if ($reviewers) { $reviewers .= ", "; }
      $reviewers .= $email2;
    }
  close(REVIEWERS);

  if (! open(DESCRIBE, "$P4 describe -s $change |")) { next; }

  my $mailmsg = "";
  my $state = "in_desc";
  my @ccers;
  my $clientname = "";
  my $changenum; 
  while(<DESCRIBE>)
    {
      if (/^Change (\d+) by [^@\s]+@([^@\s]+) on \d\d\d\d\/\d\d\/\d\d \d\d:\d\d:\d\d/)
        { $changenum = $1; $clientname = $2; }
      if (/^Jobs fixed .../ || /^Affected files .../) { $state = "pass"; }
      if ($state eq "in_desc" && /^\t\s*cc:\s*(.*)$/i) #  Add to the Cc list
        { push(@ccers, split(/[^a-z0-9_\-\.\@]+/i, $1)); }
      $mailmsg .= $_;

    }
  close(DESCRIBE);

  if ($changenum && $Url_pat)
    {
      my $url = $Url_pat;
      $url =~ s/\%C/$change/g;
      $mailmsg .= "  $url\n";
    }

  my $subject = $Sub_pat;
  $subject =~ s/\%C/$change/g;

  if ($clientname)
    {
      if (! open(CLIENT, "$P4 client -o $clientname |")) { next; }
      my $in_desc = 0;
      cli_line: while(<CLIENT>)
        {
          if (/^Description:/)
            {
              while (<CLIENT>)
                {
                  if (/^[^\s]/) { last cli_line; }
                  if (/^\t\s*cc:\s*(.*)$/i) #  Add to the Cc list
                    { 
                      my @cli_ccers;
                      @cli_ccers = split(/[^a-z0-9_\-\.\@]+/i, $1);
                      my $cli_ccers = join(", ", @cli_ccers);                   
                      push(@ccers, @cli_ccers);
                    }
                 }
            }
        }
      close CLIENT;
    }

  my $cmd = "$Sendmail -t";

  #  If anybody (like an administrator) wants special notifications of
  #  *all* changes, they can go here... (This allows the admin to
  #  still have a more meaningful list of notification subscriptions,
  #  and to quickly see which are which).
  #
  if ($Notify)
    {
      &msg("notify: $Notify\n", $Log, $Notty);
      if (open(MAIL, "| $cmd" ))
        {
          print MAIL <<MSG;
To: $Notify
From: $From
Reply-To: $email ($fullname)
Subject: [ADMIN] $subject
MSG
          print MAIL $mailmsg;
          close(MAIL);
        }
    }

  my $ccers = join(", ", @ccers);

  &nodups_reset;

  $reviewers = &nodups_str($reviewers);
  $ccers = &nodups_str($ccers);

  if ($reviewers || $ccers)
    {
      if (! open(MAIL, "| $cmd")) { next; } 

      if ($reviewers)
        {
          &msg("to: $reviewers\n", $Log, $Notty);
          print MAIL <<MSG;
To: $reviewers
MSG
        }
      if ($ccers)
        {
          &msg("cc: $ccers\n", $Log, $Notty);
          print MAIL <<MSG;
Cc: $ccers
MSG
        }

      print MAIL <<MSG;
From: $From
Reply-To: $email ($fullname)
Subject: $subject
MSG
      print MAIL $mailmsg;
      close(MAIL);
    }
}


sub dirname
{
  my ($dir) = @_;

  $dir =~ s%^$%.%; $dir = "$dir/";
  if ($dir =~ m%^/[^/]*//*$%) { return "/"; }
  if ($dir =~ m%^.*[^/]//*[^/][^/]*//*$%)
    { $dir =~ s%^(.*[^/])//*[^/][^/]*//*$%$1%; { return $dir; } }
  return ".";
}


sub msg
{
  my($msg, $log, $notty, $mailto) = @_;

  if ((! $notty) && -t STDERR) { print STDERR $msg; }

  if (! $log) { return; }

  if (! open(LOG, ">>$log"))
    {
      if (-t STDERR)
        { print STDERR "Can't open logfile \"$Log\": $! <$msg>\n"; }
    }
  else
    {
      $msg = sprintf("%14s %05s %-10s %s", &ts, $$, $Username, $msg);
      print LOG $msg;
      if ($mailto) { &mail($mailto, $msg); }            
      close LOG;
    }
}


sub ts
{
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  return sprintf("%04d%02d%02d%02d%02d%02d", 1900+$year, $mon+1, $mday, $hour, $min, $sec);
}


sub s
{
  my ($cmd, $exit_on_err, $log, $notty) = @_;
  my ($sts, $output);

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


my %Seen;

sub nodups_reset
{
  undef %Seen;
}

sub nodups_str
{
  my ($l) = @_;
  return (&nodups_list(split(/\s*,\s*/, $l)));
}

sub nodups_list
{
  my (@l) = @_;
  my @ln;
  
  foreach my $i (@l)
    {
      if (! defined $Seen{$i}) { push(@ln, $i); }
      $Seen{$i} = 1;
    }
  if ($#ln < 0) { return ""; }
  return (join(", ", @ln));
}


sub mail
{
  my($to, $subject, $msg) = @_;

  $subject =~ s/\n+$//;

  if (! defined($msg)) { $msg = "\n$subject\n"; }

  if (! open(MAIL, "|$Sendmail $to"))
    {
      &msg("$Myname: Can't open \"|$Sendmail $to\": $!.\n", $Log);
      return;
    }

  &nodups_reset;
  $to = &nodups_str(split(/\s+/, $to));

  print MAIL <<MSG;
To: $to
Subject: $subject

$msg
MSG
  close MAIL;
  return $?;
}





