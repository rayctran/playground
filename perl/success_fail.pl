#!/tools/perl/5.6.0/SunOS/bin/perl

# @(#)success_fail.pl.proto	9.1    12/09/98
#
# The following script reads a bunch of attribute/value pairs
# from STDIN, formats a notification email and sends it to the
# admin user.
# Script modified from Bristol
# Added logs for success and failure


use Mail::Sendmail;
use File::Basename;
use Date::Manip;

$direction = shift;
$result_code = shift;

$today = &UnixDate(`date`,"%d-%m-%Y");

$LOGDIR = "/tools/isofax/logs/usage";
$LOG_FILE = "$LOGDIR/$today";

# If you want to see the raw input from STDIN, set $debug = "TRUE";.  
# This will write the raw input to the file ./success_fail_debug.

$debug = "TRUE";
$debug_dir = "/tools/isofax/tmp/success_fail_debug.log";

if ($debug =~ /TRUE/) {
	open(OUTY, ">>$debug_dir") || die "can't open file\n";
	select(OUTY);
}

if ($debug =~ /TRUE/) {
	print "$direction\n";
	print "$result_code\n";
}

while(<>) {
    chop;
    s/^\s*//;                    	# Remove leading whitespace.
    s/\s*$//;                    	# Remove trailing whitespace.

	if ($debug =~ /TRUE/) {
		print "$_\n";
	}

	if(/^key:/) {
	    $key = $_;
	    $key =~ s/^.*\[(.*)\].*$/$1/;
	    next;  						# Continue with loop.
	}

    ($a,$b) = split(/\s*=\s*/);    	# Split at '=' and remove whitespace.

	# The following block takes the full pathname of the fax file and
	# extracts the incoming directory and the fax file name.

	if ($a =~ /FAX_FILE/) {
    	$b =~ s/[\[\]]//g;
		@path_array = split("/", $b);
		$fax_file = @path_array[$#path_array];
		for ($i=0; $i < $#path_array; $i++)
		{
			$incoming_cat = $incoming . @path_array[$i] . "/";
			$incoming = $incoming_cat;
		}
	}

	# If you want to use what's been passed from STDIN use the 
	# following 2 entries as examples.
	#
	# If admin's email address has just been passed from STDIN
	# get the value and put it in the variable $email.

	if ($a =~ /email_address/ && $key =~ /admin/) {
		$email = get_value($b);
	}

	# If RECIPIENT_NAME has just been passed from STDIN
	# get the value and put it in the variable $recipient.

	if ($a =~ /RECIPIENT_NAME/) {
		$recipient = get_value($b);
	}

	# get the sender's Email address
	if ($a =~ /SENDERS_EMAIL_ADDRESS/) {
		$sender = get_value($b);
	}

	# get the target's phone number
	if ($a =~ /PHONE_NUMBER/) {
		$rec_fax_no = get_value($b);
	}
	# get the actual no dailed
	if ($a =~ /S_csi/) {
		$fax_dailed = get_value($b);
	}
	# get the Email subject
	if ($a =~ /SUBJECT/) {
		$subject = get_value($b);
	}
	# get the unique job handle without the directory structure
	if ($a =~ /JOB_HANDLE/) {
		$job_handle = get_value($b);
		$job_handle = basename($job_handle);
	}
	# get the compression info
	if ($a =~ /COMPRESSION/) {
		$compression = get_value($b);
	}
	# get the number of pages submitted
	if ($a =~ /TOTAL_PAGES/) {
		$no_pages_sub = get_value($b);
	}

	# get the number of pages sent
	if ($a =~ /S_page/) {
		$no_pages_sent = get_value($b);
	}

	# get the time the faxes was submitted
	if ($a =~ /TIME_SUBMITTED/) {
		$time_submitted = get_value($b);
		$today_date=&UnixDate($time_submitted,"%b %e %Y");
		$time_submitted=&UnixDate($time_submitted,"%T");
	}
	# get the time the first attempt to fax
	if ($a =~ /TIME_FIRST_ATTEMPT/) {
		$first_attempt = get_value($b);
		$first_attempt=&UnixDate($first_attempt,"%T");
	}
	# get the time the last attempt to fax
	if ($a =~ /TIME_LAST_ATTEMPT/) {
		$last_attempt = get_value($b);
		$last_attempt=&UnixDate($last_attempt,"%T");
	}
	# get the time the faxes was sent
	if ($a =~ /S_TIMESTAMP/) {
		$time_sent = get_value($b);
		$time_sent=&UnixDate($time_sent,"%T");
	}
	# get the length of call
	if ($a =~ /S_length/) {
		$clength = get_value($b);
	}

	# get the error
	if ($a =~ /FAIL_EXCUSE/) {
		$fail_message = get_value($b);
	}
	# get the retry status
	if ($a =~ /S_reinit/) {
		$retry = get_value($b);
                if ("$retry" eq "TRUE") {
                    $resubmitted = "YES";
                } elsif ("$retry" eq "FALSE") {
		    $resubmitted = "NO";
                }
	}
	# get the attempts status
	if ($a =~ /TOTAL_ATTEMPTS/) {
		$totalat = get_value($b);
	}
	if ($a =~ /PREVIOUS_ATTEMPTS/) {
		$prevatno = get_value($b);
                $attemptleft = 5 - $prevatno;
	}
}

if ($debug =~ /TRUE/) {
	close(OUTY);
}


if ($direction =~ /SEND/) {
	if ($result_code eq "0") {
  $message = "
  Fax was successfully sent
  ==========================================
  Fax number:               $rec_fax_no
  Total pages sent:         $no_pages_sent
  Time submitted to queue:  $time_submitted
  Time sent:                $time_sent
  Number of attempts:       $prevatno
  Total call time (sec):    $clength
  Compression Information:  $compression
  ";
# Log information
	&LogIt;
	}
	elsif ($result_code eq "1") {
  $subject = "ERROR, FAX NOT SENT -  $subject";
  $message = "
  IMPORTANT!!! FAX NOT SENT
  ==========================================
  Fax number:               $rec_fax_no
  Time submitted:           $time_submitted
  Resubmitted to queue:     $resubmitted
  Retry number:             $prevatno
  No of retries left:       $attemptleft
  Time of last attempt:     $last_attempt
  Error Message:            $fail_message
  ==========================================
  ";
  
		if ($fail_message =~ /NO ANSWER/) {
  $message = "
  $message
  The following are the possible issues:
  o The fax number is invalid.
  o The fax number is a voice phone.
  o The remote fax machine did not pick up the line.
  Please confirm the fax number and try again.
  If you required assistance,  please contact the Help Desk and report
  the following error message:
  Error code[$result_code]. Error message $fail_message.
  ";
		}
		elsif ($fail_message =~ /BUSY/) {
  $message = "
  $message
  The following are the possible issues:
  o The fax line is currently busy.
  o The fax number is invalid.
  If the fax job has not been resubmitted to the queue,
  please confirm the fax number and try again.
  If you required assistance,  please contact the Help Desk and report
  the following error message:
  Error code[$result_code]. Error message $fail_message.
   ";
		}	
		elsif ($fail_message =~ /NO DIALTONE/) {
  $message = "
  $message
  The following are the possible issues:
  o The fax line is currently not in service.
  o The fax line is currently not connected.
  o The modem is offline.
  Please contact the Help Desk and report the following error message:
  Error code[$result_code]. Error message $fail_message.
   ";
		}	
		elsif ($fail_message =~ /hung up/) {
  $message = "
  $message
  The following are the possible issues:
  o The fax communication was disconnected while transmitting.
  
   ";
		}	
# Log information
	&LogIt;
	} 
}

else {
	if ($result_code eq "0") {
		print "Subject: Fax received.\n\n";
		print "Incoming fax $fax_file in $incoming just received by IsoFax.\n";
	}
	else {
		print "Subject: Fax not received.\n\n";
		print "Fax not received. error code[$result_code]\n";
	}
}

&Notify("$sender","$subject\n","$message\n\n\n");

exit(0);

# This subroutine strips the '[' and ']' from the value passed
# in and returns it.
sub get_value {
	my($b) = @_;
   	$b =~ s/[\[\]]//g;
	return $b;
}


#
# Send Mail
#
sub Notify {
    my($MySentTo,$MySubject,$MyMessage)=@_;
    %mail = (
            smtp    => 'smtphost.broadcom.com',
            to      => $MySentTo,
            from    => 'faxmgr@broadcom.com',
            subject => $MySubject,
            message => $MyMessage,
    );

    eval { sendmail(%mail) || die $Mail::Sendmail::error; };
    $Mail::Sendmail::log;

    if ($@) {
            print "mail could NOT be sent correctly - $@\n";
            exit(1);
    } else {
            print "mail sent correctly\n";
            exit(0);
    }
}

# Logging information
sub LogIt {
	open(LOGIT,">>$LOG_FILE") || die "Can't open log file\n";
	print LOGIT "$result_code,$today_date,$sender,$recipient,$rec_fax_no,$time_submitted,$last_attempt,$time_sent,$c_length,$no_pages_sent,$retry,$fail_message,$job_handle\n";
	close(LOGIT);
}

######################
# 
# The SUCCESS_FAIL_SCRIPT dynamic configuration variable enables developers 
# to customize the succeed/fail notification that occurs after sending or 
# receiving a fax. 
#
# If the variable is not empty, IsoFax attempts to execute its contents.  
# The executed program is expected to take its input from standard input.  
# A sample perl script named success_fail.pl.proto is provided below.
#
# If the variable has no value, email is used as the means of  notification. 
# The content and subject of the mail are formed internally by IsoFax. 
# The default value for the variable is no value.
#
# The executable is exec'ed with two parameters:  a direction 
# string ("SEND" or "RECV") and an integer status code. The 
# function that execs the script complains if the script 
# exits with a nonzero exit code.
#
# The integer status codes are:
#
#
#   0       Successful
#   1       Unsuccessful: session completed, but an error occurred
#   2       Unsuccessful: session canceled because cover sheet generation failed
#   3       Unsuccessful: Unknown error occured
#   4       Unsuccessful: Bad phone number
#   5       Unsuccessful: Bad fax file
#   100     Unsuccessful: session failed while starting up (internal error)
#   101     Unsuccessful: session failed while modem was idle (hypothetical)
#   102     Unsuccessful: session failed while sending
#   103     Unsuccessful: session failed while receiving
#   104     Unsuccessful: session failed while converting compression format 
#   105     Unsuccessful: session failed while generating cover sheet
#   106     Unsuccessful: session failed while forwarding to a remote server 
#   107     Unsuccessful: session failed while initializing
#   200     Unsuccessful: not a fax call (no fax tones heard after answer)
#   300     Unsuccessful: session was killed by signal
#
# The script's standard input is fed ASCII attribute-value in
# a record format.  Each record begins with:
#
#    key: [THEKEYVALUE]\n
#
# Each additional attribute-value pair that follows has the following
# format:
#
#    ATTR=[VALUE]\n
#
# eg.
#   key:  [status]
#    S_TIMESTAMP=[Thu Apr 24 10:16:49 1997]
#
# The script always receives the entire USER_LIST.info entry for the
# [admin] user.  When the session is a "RECV", the forwarder for the
# fax file's incoming directory is also provided.
#
# Two additional records are always present.  This first is [file]
# which contains (at the least) the fax's filename.  When the script
# is called following a "SEND", additional information is provided.
# The second record is the [status] record.
#
# The script may receive one or more of the following attributes in the
# [status] record.
#
#   Attribute            Value Description
#   ------------------   ------------------------------------------------
#   S_TIMESTAMP          Status file UNIX-style time stamp
#   S_page               Last page transmitted or received 
#   S_error              String explaining failure (if any)
#   S_info               Informational text 
#   S_filename           Fax filename
#   S_length             Duration of call
#   S_csi                Fax id of answering fax
#   S_tsi                Fax id of sending fax
#   S_did                DID routing information string 
#   S_reinit             Cause a reinitialization of modem
#
#
# The script will receive one or more of the following attributes after
# a send or receive operation in the [file] record:
#
#   Attribute            Value Description (... for the obvious)
#   ------------------   ------------------------------------------------
#   BILLING_CODE         ...
#   CLIENT_NAME          Client's login or user name
#   FAIL_EXCUSE          Text describing reason for failure (Note:
#                        this attribute will only be available following
#                        an unsuccessful send).
#   FAX_FILE             Name of fax file
#   LAST_PAGE_SUCCESSFULLY_TRANSMITTED  ...
#   PHONE_NUMBER         Phone number filtered before dialing
#   PREVIOUS_ATTEMPTS    As defined in FAX_SERVER_CONF.proto 
#   PRIORITY             ASCII integer
#   RECIPIENT_NAME       ...
#   RESOLUTION           string describing resolution.
#   REV                  ASCII integer C-file revision number
#   SUBJECT              ...
#   TIME_SUBMITTED       UNIX time style string.
#   TIME_TO_SEND         UNIX date style string.
#   TOTAL_ATTEMPTS       As defined in FAX_SERVER_CONF.proto
#   TRACKING_ID          ...
#   UID                  Client's user id
#
# For future compatibility, scripts must ignore unrecognized attributes.
################################################################################
