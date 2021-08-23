#!/tools/perl/5.6.1/SunOS/bin/perl
#---------------------------------------------------------------------
# Get all PR numbers from the gnats database and save the data to
# the PR number log at all sites.
#
# Usage: perl update_prnums_log_sqa.pl
#
# Requirements:
# - Need Perl 5.6.1 and above version installed.
# - Need additional packages:
#	%Perl_5_6_1_Home%\lib\Mail\Sendmail.pm
#	%Perl_5_6_1_Home%\lib\Net\Gnats.pm
#	%Perl_5_6_1_Home%\lib\Net\Gnats\PR.pm
#
# Notes:
# - The gnats server, database, port, userid, and password are hard coded.
#
# Known errors/warnings:
# - Can't locate auto/Net/Gnats/autosplit.ix
# - Can't locate auto/Net/Gnats/PR/autosplit.ix
#
# Author: Chin Tiam Tok
#---------------------------------------------------------------------

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
#BEGIN { $| = 1; print "1..1\n"; }
#END {print "not ok 1\n" unless $loaded;}
#use Net::Gnats;
#$loaded = 1;
#print "ok 1\n\n";
######################### End of black magic.

$libpath = "/tools/perl/5.6.1/sun4u-5.6/bin /tools/perl/5.6.1/sun4u-5.6/lib/site_perl/5.6.1 /tools/perl/5.6.1/sun4u-5.6/lib/5.6.1";

# Insert Perl path to @INC
unshift(@INC,$libpath);

use Mail::Sendmail;
use Net::Gnats;


#---------------------------------------------------------------------
# Define the variables.
#---------------------------------------------------------------------
$script = "update_prnums_log_sqa.pl";
$fieldname = "Release-Note";
print "$script    Ver 1.0    21 Jan 2004\n\n";

if (defined $ENV{GNATSDB}) 
{
	($server, $port, $db, $username, $password) = split /:/, $ENV{GNATSDB};
}

$server   = 'gnats-irva-3.broadcom.com' 	unless length $server;
$port     = 1530				unless length $port;
$username = 'vobadm'				unless length $username;
$password = 'fixit'				unless length $password;
$db       = 'BSE_SQA'				unless length $db;


# The array of PR directories at all sites.
@prdirs = (
            "\\\\cc-atla-storage\\ccase\\script\\log\\$db\\pr",
            "\\\\Fs-blr-01v\\ccase\\script\\log\\$db\\pr",
            "\\\\Fs-irva-37\\ccase\\script\\log\\$db\\pr",
            "\\\\Fs-rmna-01\\ccase\\script\\log\\$db\\pr",
            "\\\\cc-sj-storage\\ccase\\bse\\script\\log\\$db\\pr"
           );

print "Database: $db\n".
	"Note: remaining tests will fail if gnatsd is not\n".
      "running on $server:$port\n\n";

#---------------------------------------------------------------------
# Start a constructor with the hostname and port of the target gnats
# server. Verify the connection.
#---------------------------------------------------------------------
my $g = Net::Gnats->new($server, $port);
my $connected;

if ($g->connect()) 
{
	$connected = 1;
	print "connect(): ok\n";
} 
else 
{
	$connected = 0;
	print "connect(): not ok\n";
	exit 1;
}

if ($connected) 
{ 
	# Bypass remaining tests if not connected
	$g->login($db, $username, $password);
	$rc = $g->getErrorMessage();
	chomp $rc;
	if ( $rc ne "" )
	{
		print "$rc\n";
		EmailAlert("$rc","Unable to login to $db as $username on $server:$port\n$rc\n");
		exit 1;
	}

	if (defined $g->listDatabases()) 
	{
		print "listDatabases(): ok\n";
	} 
	else 
	{
		print "listDatabases(): not ok\n";
		exit 1;
	}
} 
else 
{
	# Fail all remaining tests
	print "connect(): not ok\n";
	EmailAlert("Unable to connect to $server:$port\n");
	exit 1;
}

#---------------------------------------------------------------------
# Query and get the list of all existing PR numbers.
#---------------------------------------------------------------------
my @prnums = $g->query('Number>"0"');
unshift @prnums, " ";
push @prnums, " ";
#print "'@prnums'";

#---------------------------------------------------------------------
# Update the PR numbers to a log at each site.
# The user must have the UNIX account existing on the local UNIX domain;
# otherwise the script can't write the file to the filer location.
#---------------------------------------------------------------------
foreach $prdir (@prdirs)
{
	$prnums_log = $prdir . "\\prnums_log";
	open(PRNUMS_LOG,">$prnums_log") || warn "$!: cannot open '$prnums_log'";
	binmode(PRNUMS_LOG);
	print PRNUMS_LOG "@prnums";
	close(PRNUMS_LOG);
}

#---------------------------------------------------------------------
# Disconnect from the gnats database.
#---------------------------------------------------------------------
$g->disconnect();

#---------------------------------------------------------------------
# sub-routine to email notification upon failure.
#---------------------------------------------------------------------
sub EmailAlert
{
	($sub,$msg) = @_;
	#---------------------------------------------------------------------
	# Email the PR log, number, and error message.
	#---------------------------------------------------------------------
	$from = "clearcase-bse-admin-list\@broadcom.com";
	$sendto = "$from";
	$cc = "";
	$message = "";
	$subject = "$script: $sub\n";
	$hostname = `hostname`;
	chomp $hostname;

	$message = join "", $message, "$msg\n";
	$message = join "", $message, "\n**************************************************************\n";
	$message = join "", $message, "This is an automated email notification fired by a Perl script\n";
	$message = join "", $message, "($script) on Windows host: $hostname.\n\n";
	$message = join "", $message, "Thank you.";

	# Print $message;
	%mail = (
			smtp => 'smtphost.broadcom.com',
			from => $from,
			to => $sendto,
			cc => $cc,
			subject => $subject,
			message => $message,
		  );

	eval { sendmail(%mail) || die $Mail::Sendmail::error; };
	$Mail::Sendmail::log;

	if ($@) 
	{
		print "Mail could NOT be sent correctly - $@\n";
		exit 1;
	} 
	else 
	{
		print "Mail sent correctly.\n";
	}
}

# End of file.
