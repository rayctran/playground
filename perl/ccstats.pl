#!/usr/local/bin/perl5.8.4

use strict;

use Date::Manip;
use File::Basename;
use Data::Dumper;

#-------------------------------------------------------------------------------
# Collect stastistics for ClearCase
#  
# File: ccstats.pl 
#-------------------------------------------------------------------------------
# Command Line Usage
# "Usage: $0 -w  {Full path to the p4workspace area} -d {1}
# -d 1 will switch to debug mode and will dump more information on the screen
#-------------------------------------------------------------------------------
# 
# Output format
# File name is Business Unit
# license indicator
# LIC:date:server_name:no_of_cc_licenses:no_of_ms_licenses
# VOBSTATS:date:server_name:vobname:vob space:no_of_elements:no_of_branch:no_of_version:no_of_replicas

my (%AppConfig,%Today,$arg_opt,$arg_value,%Data);
$AppConfig{mail_to} = 'raytran@broadcom.com';

if ( $#ARGV > 0 ) {
    my %Arg=@ARGV;
    while(($arg_opt,$arg_value)=each %Arg) {
        if ($arg_opt =~ /-d/) {
            $AppConfig{debug} = 1;
        }
    }
} else {
    print "Usage: $0 -d {1}\n";
    print "-d 1 will turn on the debug mode\n";
    exit 1;

}

# Determine path to log file based on YYYY/MM/DD
$Today{year} = &UnixDate("today","%Y");
$Today{month} = &UnixDate("today","%m");
$Today{day} = &UnixDate("today","%d");
$Today{date} = &UnixDate("today","%Y%m%d");
chop($AppConfig{hostname}=`hostname`);

# verify log directory and create it if neccessary
#$AppConfig{logdir}="/projects/scm_tools_logs/cc/stats/$Today{year}/$Today{month}";
$AppConfig{logdir}="/projects/ccase/SCM/logs/stats/$AppConfig{hostname}";
if (!-e "$AppConfig{logdir}") {
    system("mkdir -p $AppConfig{logdir}; chmod 776 $AppConfig{logdir}");
}

#-------------------------------------------------------------------------------
#       Globals

my $log_handle;                 # Log FileHandle object
my $cmd_output;                 # Standard output / error from the last command executed
my $cmd_rc;                     # Return code from the last executed command


#-------------------------------------------------------------------------------
#       Run the specified command as a subprocess.  Write the command, return code,

sub runCommand
{
        my $cmd = shift;


        # Execute the supplied command, capturing the output in the log file.
        # Redirect standard error to standard output so it is captured as well.

        $cmd_output     = `$cmd 2>&1`;
        $cmd_rc         = $? / 256;

    return $cmd_rc == 0;
}

#-------------------------------------------------------------------------------
#       Send Email

sub Notify {

    use Mail::Sendmail;
    my ($From,$SentTo,$Subject,$Message) = @_;

    my %mail = (
            Smtp    => 'smtphost.sj.broadcom.com',
            From    => $From,
            To      => $SentTo,
            Subject => $Subject,
            Message => $Message,
    );

    eval { sendmail(%mail) || die $Mail::Sendmail::error; };
    $Mail::Sendmail::log;

    if ($@) {
            print "mail could NOT be sent correctly - $@\n";
    } else {
            print "mail sent correctly\n";
    }
}

#-------------------------------------------------------------------------------
#       Send email notification of script failure, then exit.
sub dropDead
{
        my $rc  = shift;

        Notify("$AppConfig{mail_from}","$AppConfig{mail_to}","PERFORCE MONITOR ERROR: $AppConfig{BU}: Perforce Monitor failed ($rc)",
                                "$cmd_output\n" );
        exit $rc;
}

#--------------
# Main 


runCommand( "$AppConfig{p4} info" ) or dropDead(1);
foreach ( split /\n/, $cmd_output) {
    if ( $_ =~ /(\d+) users/ )  {
        $Data{no_of_lic} = $1; 
    }

}

runCommand( "$AppConfig{p4} users | /usr/bin/wc -l" ) or dropDead(2);
chop($cmd_output);
$AppConfig{user_cnt} = $cmd_output;

if ($die_msg) {
    Notify("$AppConfig{mail_from}","$AppConfig{mail_to}","PERFORCE MONITOR ERROR: $AppConfig{BU}: Could not sync in $AppConfig{limit} secs","$output");
    exit(1);
}

open(LOGFILE,">>$AppConfig{logfile}");
print LOGFILE "$now;$output_flattened;$t\n";
close(LOGFILE);

exit(0);
