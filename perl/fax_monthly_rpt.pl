#!/tools/perl/5.6.0/SunOS/bin/perl
#
# Create monthly report from last month's statistics
#
# Version: 1.2 - RCT - Add in calculation for cost.
# Version: 1.3 - RCT - Add in Detail Failure stats.
#		 RCT - Add note explaining failure faxes
#

use Data::Dumper;
use IO::File;
use GD;
use GD::Text;
use Date::Manip;
use Mail::Sendmail;
#use GD::Graph::Map;

#if ($#ARGV < 0) {
#        print "Usage: $0 MM {Month in 2 digit format}\n";
#        print "Example: $0 03\n";
#        exit (1);
#} else {
#	if ( $ARGV[0] =~ /^\d{2}/ ) { 
#	       	$MYMONTH=$ARGV[0];
#	} else {
#		print "wrong month format. The date month should be MM\n";
#	       	 exit (1);
#	}
#}
#
###
# Check month format
###

chop($MYYEAR=`date '+%Y'`);
chop($THISMONTH=`date '+%m'`);
#$MYMONTH=01;

# Determine previous month;
$MYMONTH= $THISMONTH - 1;
if ( $MYMONTH =~ /^\d{1}/ ) {
	$MYMONTH="0${MYMONTH}";
}
# If this month is January (01) set report month to December (12)
# and set report year to last year

if ( $MYMONTH == 00 ) {
	$MYMONTH=12;
	$MYYEAR= $MYYEAR - 1;
}
########
#$MYMONTH="09";
#$MYMONTH="12";
#$MYYEAR=2002;
#######

$LOGDIR="/tools/isofax/logs/usage";
$LOGFILE="${MYYEAR}_${MYMONTH}";
$RPT_DIR="/tools/isofax/public_html/reports/monthly";
$IMG_DIR="${RPT_DIR}/images";
$WEB_HOME="http://intranet.broadcom.com/\~faxmgr";
$HTML_FILE="${RPT_DIR}/${MYYEAR}_${MYMONTH}.html";
$LINK="$WEB_HOME/reports/monthly/${MYYEAR}_${MYMONTH}.html";
$MODEMLOGDIR="/tools/isofax/logs/modem_usage";
$EMAILLIST="isofax-admins\@broadcom.com,jzak\@broadcom.com,awoo\@broadcom.com,djo\@broadcom.com";
#$EMAILLIST="raytran\@broadcom.com";

open(LOG, "${LOGDIR}/$LOGFILE") || die "Can't open log file ${LOGDIR}/$LOGFILE\n";

@SUCCESS_JH = @TO_JH = @FAIL_JH_U = ();
%FAIL_JH = ();

# Create key/value of Failed faxes using job handle
# The value beeing how many entries of the same job handle
while(<LOG>) {
	@MYLINE = parse_csv($_);
	$total_cnt++;
	$REC = {
		NUMBER		=> $total_cnt,	
		RESULT_CODE 	=> $MYLINE[0],
		DATE		=> $MYLINE[1],
		SENDER		=> $MYLINE[2],
		REC		=> $MYLINE[3],
		FAX_NO		=> $MYLINE[4],
		TIME_SUB	=> $MYLINE[5],
		L_ATTEMPT	=> $MYLINE[6],
		TIME_SENT	=> $MYLINE[7],
		C_LENGTH	=> $MYLINE[8],
		NO_PAGES_SENT	=> $MYLINE[9], 
		RETRY		=> $MYLINE[10], 
		FAIL_MSG	=> $MYLINE[11], 
		JOB_HANDLE	=> $MYLINE[12],
		TOTAL_ATTEMPT	=> $MYLINE[13],
		ATTEMPT		=> $MYLINE[14],
		ATTEMPT_LEFT	=> $MYLINE[15],
	};
	if ( $REC->{RESULT_CODE} == 0 ) {
		$scount++;
		$SUCCESS{ $REC->{NUMBER} } = $REC;
		push(@SUCCESS_JH, $REC->{JOB_HANDLE});
		
	}
	if ( $REC->{RESULT_CODE} == 1 ) {
		$fcount++;
                $FAIL{ $REC->{NUMBER} } = $REC;
		$FAIL_JH{$REC->{JOB_HANDLE}}++;
		push(@FAIL_JH, $REC->{JOB_HANDLE});
		push(@FAIL_MSG, $REC->{FAIL_MSG});
        }
	if ( $REC->{RESULT_CODE} == 300) {
                $TIMEDOUT{ $REC->{NUMBER} } = $REC;
		push(@TO_JH, $REC->{JOB_HANDLE});
		$tocount++;
        }
	$BYJOB{ $REC->{JOB_HANDLE} } = $REC;
}
#print "$total_cnt, $scount, $fcount, $tocount\n";

#print Dumper(\%FAIL);
#exit 1;



#######################
# Success stats
#######################

#$no_of_sec = $no_of_ps = $local = $internat = $sent_on_retry = $sent_on_first = ();
@SENDER_LIST = ();
while (($NAME, $RECORD) = each %SUCCESS) {
		$no_of_sec = $RECORD->{C_LENGTH} + $no_of_sec;
		$no_of_ps = $RECORD->{NO_PAGES_SENT} + $no_of_ps;
		if ( $RECORD->{FAX_NO} =~ /^\+/ ) {
			$internat++;
			$int_cl = $RECORD->{C_LENGTH} + $int_cl;
		#	print "Found international number $RECORD->{FAX_NO}\n";
		} else {
			$local++;
			$local_cl = $RECORD->{C_LENGTH} + $local_cl;
		}
		if ( $RECORD->{ATTEMPT}  == 1 ) {
			$sent_on_first++;	
		} else {
			$sent_on_retry++;
		}
		push(@SUCC_ATT, $RECORD->{ATTEMPT});
		($SENDER,$BRCM) = split (/\@/, $RECORD->{SENDER});	
		push (@SENDER_LIST, $SENDER);
# Average Queue time
		$time_submit=$RECORD->{TIME_SUB};
		$time_sent=$RECORD->{TIME_SENT};
		$delta_time = &DateCalc($time_submit,$time_sent,\$err);
		($a,$b,$c,$d,$hr,$min,$sec) = split (/:/, $delta_time);
		$sec_in_queue =($hr * 3600) + ($min * 60) + $sec;
		$total_sec_in_queue = $total_sec_in_queue + $sec_in_queue;
}


#######################
# Cost stats
#######################

# Converts Call length number of secs into minutes
$no_of_min = sprintf("%.1f",$no_of_sec / 60);
$min_int_cl = sprintf("%.1f",$int_cl / 60);
$min_us_cl = sprintf("%.1f",$local_cl / 60);
# Calculate cost based on information provided by Telecom
# $.04/min local and $.50/min international
$cost_int_cl = sprintf("%.2f", $min_int_cl * .50);
$cost_us_cl = sprintf("%.2f", $min_us_cl * .04);
$total_cost = sprintf("%.2f", $cost_int_cl + $cost_us_cl);


# Array of sender in relation to the number of faxes
@S_CNT_SENDER = ();
foreach $I (@SENDER_LIST) { $S_CNT_SENDER{$I}++ };

# Array of successful faxes in relation to the number of attempts it took to send the fax
@S_CNT_ATT = ();
foreach $I (@SUCC_ATT) { $S_CNT_ATT{$I}++ };


#######################
# Fail stats
#######################
#
# if the number of attempts is equal to the total attempt then the fax 
# "really" failed
#

while (($NAME, $RECORD) = each %FAIL) {
	if ( $RECORD->{ATTEMPT} == $RECORD->{TOTAL_ATTEMPT} ) {
		push(@FAIL_NO, $RECORD->{FAX_NO});
		$real_fcount++;
	}
}

# Count how many time a particular fax number failed
@FFAX_NO = ();
foreach $I (@FAIL_NO) { $FFAX_NO{$I}++ }

#print Dumper(\@FAIL_NO);
#print Dumper(\%FFAX_NO);
#print Dumper(\@TRUEFAIL);

while (($NAME, $RECORD) = each %TRUEFAIL) {
	print "$RECORD->{FAX_NO} $RECORD->{FAIL_MSG}\n";
}

#exit 1;

$resubmit_fail = $fcount - $real_fcount;


# An array of error messages and how many failed faxes 
@FM = ();
foreach $I (@FAIL_MSG) { $FM{$I}++ }

$real_total_count = $scount + $real_fcount + $tocount;

# Caculating and Formatting percentage
$per_succ = sprintf("%.1f",($scount / $real_total_count) * 100);
$per_fail = sprintf("%.1f",($real_fcount / $real_total_count) * 100);
$per_to = sprintf("%.1f",($tocount / $real_total_count) * 100);
$per_local = sprintf("%.1f",($local / $scount) * 100);
$per_int = sprintf("%.1f",($internat / $scount) * 100);
$per_on_first = sprintf("%.1f",($sent_on_first / $scount) * 100);
$per_on_retry = sprintf("%.1f",($sent_on_retry / $scount) * 100);
$average_queue = sprintf("%.1f",($total_sec_in_queue / $scount) / 60);


#  Storing stats
$STATS = {
	TOTAL     		=> $total_cnt, 	
	SUCCESS     		=> $scount, 	
	FAILED_INT     		=> $fcount, 	
	FAILED_REAL    		=> $real_fcount, 	
	TIMEDOUT		=> $tocount,
	PER_SUCC 		=> $per_succ,
	PER_FAIL 		=> $per_fail,
	PER_TO 			=> $per_to,
	TOTAL_SEC		=> $no_of_sec,
	TOTAL_MIN		=> $no_of_min,
	TOTAL_PAGESNT		=> $no_of_ps,
	LOCAL_CALLS		=> $local,
	INT_CALLS		=> $internat,
	PER_LOCAL_CALLS		=> $per_local,
	PER_INT_CALLS		=> $per_int,
	SENT_ON_1		=> $sent_on_first,
	SENT_ON_RETRY		=> $sent_on_retry,
	PER_SENT_ON_1		=> $per_on_first,
	PER_SENT_ON_RETRY	=> $per_on_retry,
	AVERAGE_Q_TIME		=> $average_queue,
	REAL_TOTAL		=> $real_total_count,
	MIN_US			=> $min_us_cl,
	MIN_INT			=> $min_int_cl,
	COST_PER_MIN_US		=> $cost_us_cl,
	COST_PER_MIN_INT	=> $cost_int_cl,
	TOTAL_COST		=> $total_cost,
	};


#print Dumper(\@STATS);
#exit 1;


# Modem Stats
opendir(ML,"$MODEMLOGDIR") or die "Can't access Modem Log directory: $!\n";
while (defined ($M_LOG_FILE = readdir ML)) {
	if ($M_LOG_FILE =~ /^\d{2}-${MYMONTH}-${MYYEAR}$/) {
		open (MLOGFILE, "${MODEMLOGDIR}/${M_LOG_FILE}") or die "Can't open log file ${MODEMLOGDIR}/${M_LOG_FILE}: $!\n";
		while(<MLOGFILE>) {
			if ( $_ =~ /^*${MYYEAR}$/ ) {
				($HEX,$TIME,$DATE) = split(/ /, $_);
			}
			if ( $_ =~ /^.*\/(.*?)\s*\=\=\>\s*(\d*)\s*$/ ) {
			#	print "$1 => $2\n";
				$MODEM_STATS{"$1"} += $2;
				if ( $MODEM_LIST =~ /$1/ ) {
					$MODEM_STATS->{"$1"} += $2;
				} 
			}
		}
	}
}
##########################
# Creating pie charts
##########################


# US/International Average

undef(@DATA);
@DATA = ( 
	["US $STATS->{PER_LOCAL_CALLS}%", "Int $STATS->{PER_INT_CALLS}%"], 
	[ $STATS->{PER_LOCAL_CALLS}, $STATS->{PER_INT_CALLS} ]
	);
&create_pie_chart("International V.S. US","${IMG_DIR}/${MYYEAR}_${MYMONTH}_nd.png");
$IMG_ND = "./images/${MYYEAR}_${MYMONTH}_nd.png";

# Success/Failed Average
undef(@DATA);
@DATA = ( 
	[ "Success $STATS->{PER_SUCC}%", "Failed $STATS->{PER_FAIL}%", "TO $STATS->{PER_TO}%"], 
	[ $STATS->{PER_SUCC}, $STATS->{PER_FAIL}, $STATS->{PER_TO} ]
	);
&create_pie_chart("Fax Result Percentage","${IMG_DIR}/${MYYEAR}_${MYMONTH}_rs.png");
M1G/IMG_RS
$IMG_RS = "./images/${MYYEAR}_${MYMONTH}_rs.png";
#print Dumper(\@DATA);

# Attempts Sent

undef(@DATA);
while (($k,$v) = each(%S_CNT_ATT)) {
	$per_cal = sprintf("%.1f",($v / $scount) * 100);
	push(@{ $DATA[0] }, "$k ${per_cal}%");
	push(@{ $DATA[1] }, "${per_cal}");
	push(@Two, $per_cal);
}
&create_pie_chart("Attempts Percentage","${IMG_DIR}/${MYYEAR}_${MYMONTH}_sa.png");
$IMG_SA = "./images/${MYYEAR}_${MYMONTH}_sa.png";

#############################
# Create HTML Page
#############################


open (HTMLPAGE, "> $HTML_FILE") || die "Can't open File $HTML_FILE: $!\n";
print HTMLPAGE " 
\<HTML\>
\<HEAD\>
  \<META HTTP-equiv=\"Content-Type\" content=\"text/html; charset=windows-1252\"\>
  \<META name=\"Description\" content=\"Broadcom Isofax Monthly Report\"\>
  \<META name=\"Broadcom, IsoFax, Fax\" content=\"Broadcom Isofax Monthly Report\"\>
  \<STYLE\>
  body\{font-family:Verdana,Arial,Helvetica,Sans-serif;font-size:12px\;\}
  td\{font-family:Verdana,Arial,Helvetica,Sans-serif;font-size:12px\;\}
  h1\{font-family:Verndana,Arial,Helvetica,Sans-serif;font-size:17px\;}
  a \{text-decoration:none\;\}
  blockquote \{font-family:courier\}
  a:hover \{text-decoration:underline}
  input\{font-family : Verdana,Arial,Helvetica,Sans-serif\;font-size:12px;
         color:\#000000;width : 90px\;\}
 \</STYLE\>
\</HEAD\>
\<BODY\>
\<TABLE ALIGN=\"left\" BORDER=0 WIDTH=650\>
  \<TR\>
  \<TD\> \<H1\>\<P ALIGN=CENTER\>Fax Server Monthly Statistics for $MYMONTH/$MYYEAR \</P\>\</H1\>\</TD\>
  \</TR\>
  \<TR\>\<TD BGCOLOR=\"CCCCCC\" COLSPAN=2\>General Statistic\<BR\>\</TD\>\</TR\>
  \<TR\>
  \<TD ALIGN=LEFT\>\<BR\>
	\<TABLE BORDER=1 CellSpacing=0\>
	\<TR\>\<TD NOWRAP\>Number of Faxes Submitted to Queue\</TD\>\<TD ALIGN=RIGHT\> $STATS->{TOTAL} \</TD\>\</TR\>
	\<TR\>\<TD NOWRAP\>Faxes Sent\</TD\>\<TD ALIGN=RIGHT\> $STATS->{SUCCESS} \</TD\>\</TR\>
	\<TR\>\<TD NOWRAP\>Faxes Failed \</TD\>\<TD ALIGN=RIGHT\> $STATS->{FAILED_REAL} \</TD\>\</TR\>
	\<TR\>\<TD NOWRAP\>Fax Server Timed Out\</TD\>\<TD ALIGN=RIGHT\> $STATS->{TIMEDOUT} \</TD\>\</TR\>
	\<TR\>\<TD NOWRAP\>Total\</TD\>\<TD ALIGN=RIGHT\> $STATS->{REAL_TOTAL} \</TD\>\</TR\>
	\<TR\>\<TD NOWRAP\>Average Queue time in minute(s)\</TD\>\<TD ALIGN=RIGHT\> $STATS->{AVERAGE_Q_TIME} \</TD\>\</TR\>
";

foreach $Modem (sort keys %MODEM_STATS) {
        print HTMLPAGE "\<TR\>\<TD NOWRAP\>Modem $Modem total time in seconds</TD\>\<TD ALIGN=RIGHT\>$MODEM_STATS{$Modem}\</TD\>\</TR\>";
}
	
print HTMLPAGE "
	\</TABLE\>
  \</TD\>
  \</TR\>
  \<TR\>\<TD\>\<IMG SRC=\"$IMG_RS\" ALT=\"Success/Failure Statistics\"\>\<BR\>\<BR\>\</TD\>\</TR\>
  \<TR\>\<TD BGCOLOR=\"CCCCCC\" COLSPAN=2\>Successful Faxes Statistics\<BR\>\</TD\>\</TR\>
  \<TR\>\<TD ALIGN=LEFT\>\<BR\>
	\<TABLE BORDER=1 CellSpacing=0\>
	\<TR\>\<TD NOWRAP\>Number of US Calls\</TD\>\<TD ALIGN=RIGHT\> $STATS->{LOCAL_CALLS} \</TD\>\</TR\>
	\<TR\>\<TD NOWRAP\>Number of Minutes for Domestic Calls\</TD\>\<TD ALIGN=RIGHT\> $STATS->{MIN_US} \</TD\>\</TR\>
	\<TR\>\<TD NOWRAP\>Estimated cost for Domestic Calls (\$.04/min)\</TD\>\<TD ALIGN=RIGHT\> \$ $STATS->{COST_PER_MIN_US} \</TD\>\</TR\>
	\<TR\>\<TD NOWRAP\>Number of International Calls\</TD\>\<TD ALIGN=RIGHT\> $STATS->{INT_CALLS} \</TD\>\</TR\>
	\<TR\>\<TD NOWRAP\>Number of Minutes for International Calls\</TD\>\<TD ALIGN=RIGHT\> $STATS->{MIN_INT} \</TD\>\</TR\>
	\<TR\>\<TD NOWRAP\>Estimated cost for International Calls (\$.50/min)\</TD\>\<TD ALIGN=RIGHT\> \$ $STATS->{COST_PER_MIN_INT} \</TD\>\</TR\>
	\<TR\>\<TD NOWRAP\>Total Number of pages sent\</TD\>\<TD ALIGN=RIGHT\> $STATS->{TOTAL_PAGESNT} \</TD\>\</TR\>
	\<TR\>\<TD NOWRAP\>Total Number of minutes\</TD\>\<TD ALIGN=RIGHT\> $STATS->{TOTAL_MIN} \</TD\>\</TR\>
	\<TR\>\<TD NOWRAP\>Total Estimated Monthly Cost\</TD\>\<TD ALIGN=RIGHT\> \$ $STATS->{TOTAL_COST} \</TD\>\</TR\>
";

foreach $Attempt (sort keys %S_CNT_ATT) {
        print HTMLPAGE "\<TR\>\<TD NOWRAP\>Faxes sent on $Attempt attempt(s)\</TD\>\<TD ALIGN=RIGHT\> $S_CNT_ATT{$Attempt}\</TD\>\</TR\>";
}
print HTMLPAGE "
	\</TABLE\>
  \</TD\>\</TR\>
  \<TR\>
  \<TD\> \<IMG SRC=\"$IMG_ND\" ALT=\"Number Dialied\"\>\<BR\> \</TD\>
  \<TD\> \<IMG SRC=\"$IMG_SA\" ALT=\"Sent/Attempts\"\>\<BR\></BR> \</TD\> 
  \</TR\>
  \<TR\>\<TD BGCOLOR=\"CCCCCC\" COLSPAN=2\>Successful Faxes by Senders\<BR\>\</TD\>\</TR\>
     \<TR\>\<TD ALIGN=LEFT\>\<BR\>
        \<TABLE BORDER=1 CellSpacing=0\>
	\<TR\>\<TD NOWRAP\>Originator\</TD\>\<TD NOWRAP ALIGN=RIGHT\>Number of Faxes\</TD\>\</TR\>
";

foreach $Sender (sort keys %S_CNT_SENDER) {
	print HTMLPAGE "\<TR\> \<TD NOWRAP\>$Sender\</TD\>\<TD ALIGN=RIGHT\> $S_CNT_SENDER{$Sender}\</TD\>\</TR\>";
}

print HTMLPAGE "
  \</TABLE\>\<BR\>
  \<TR\>\<TD BGCOLOR=\"CCCCCC\" COLSPAN=2\>Unsuccessful Faxes Statistics\<BR\> Notes: Actual failure meaning that the fax had exceeded the maximum 4 attempts.\<BR\>\</TD\>\</TR\>
  \<TR\>\<TD ALIGN=LEFT\>\<BR\>
	\<TABLE BORDER=1 CellSpacing=0\>
	\<TR\>\<TD NOWRAP\>Number of Failed Attempts\</TD\>\<TD ALIGN=RIGHT\> $STATS->{FAILED_INT} \</TD\>\</TR\>
	\<TR\>\<TD NOWRAP\>Actual Failed Faxes \</TD\>\<TD ALIGN=RIGHT\> $STATS->{FAILED_REAL} \</TD\>\</TR\>
	\</TABLE\>\<BR\>
  	\<TR\>\<TD BGCOLOR=\"CCCCCC\" COLSPAN=2\>Number of faxes by Error message\<BR\>\</TD\>\</TR\>
     	\<TR\>\<TD ALIGN=LEFT\>\<BR\>
	\<TABLE BORDER=1 CellSpacing=0\>
	\<TR\>\<TD NOWRAP\>Error Message\</TD\>\<TD ALIGN=RIGHT NOWRAP \>Number of Faxes\</TD\>\</TR\>
";
foreach $Err_Msg (sort keys %FM) {
        print HTMLPAGE "\<TR\>\<TD NOWRAP\>$Err_Msg\</TD\>\<TD ALIGN=RIGHT\>$FM{$Err_Msg}\</TD\>\</TR\>";
}


print HTMLPAGE "
	\</TABLE\>\<BR\>
  	\<TR\>\<TD BGCOLOR=\"CCCCCC\" COLSPAN=2\>Number of Fail Faxes by Fax Number\<BR\>Notes: Fax number with + character indicates an international number.\<BR\>\</TD\>\</TR\>
     	\<TR\>\<TD ALIGN=LEFT\>\<BR\>
	\<TABLE BORDER=1 CellSpacing=0\>
	\<TR\>\<TD NOWRAP\>Fax Number Attempted\</TD\>\<TD ALIGN=LEFT\>Number of Failures\</TD\>\</TR\>
";
foreach $FaxNo (sort keys %FFAX_NO) {
	print HTMLPAGE "\<TR\> \<TD NOWRAP\>$FaxNo\</TD\>\<TD ALIGN=LEFT\> $FFAX_NO{$FaxNo}\</TD\>\</TR\>";
}

print HTMLPAGE "
	\</TABLE\>\<BR\>
  	\<TR\>\<TD BGCOLOR=\"CCCCCC\" COLSPAN=2\>Fail Fax Number and the Failure Message\<BR\>\</TD\>\</TR\>
     	\<TR\>\<TD ALIGN=LEFT\>\<BR\>
	\<TABLE BORDER=1 CellSpacing=0\>
	\<TR\>\<TD NOWRAP\>Fax Number\</TD\>\<TD ALIGN=LEFT\>Failure Message\</TD\>\</TR\>
";
while (($NAME, $RECORD) = each %FAIL) {
        if ( $RECORD->{ATTEMPT} == $RECORD->{TOTAL_ATTEMPT} ) {
		print HTMLPAGE "\<TR\> \<TD NOWRAP\>$RECORD->{FAX_NO}\</TD\>\<TD NOWRAP ALIGN=LEFT\> $RECORD->{FAIL_MSG}\</TD\>\</TR\>";
		
        }
}


print HTMLPAGE "
\</TABLE\>
\</TD\>\</TR\>
\</TABLE\> 
\</BODY\>
\</HTML\>

";

&Notify("$EMAILLIST", "Monthly Fax Server Statistic for ${MYMONTH}/${MYYEAR} generated.\n", "Please find the Fax server statistic for ${MYMONTH}/${MYYEAR} here\n ${LINK} \n");

sub parse_csv {
    my $text = shift;      # record containing comma-separated values
    my @new  = ();
    push(@new, $+) while $text =~ m{
        # the first part groups the phrase inside the quotes.
        # see explanation of this pattern in MRE
        "([^\\"\\]*(?:\\.[^\\"\\]*)*)\",?
           |  ([^,]+),?
           | ,
       }gx;
       push(@new, undef) if substr($text, -1,1) eq ',';
       return @new;      # list of values that were comma-separated
}  

sub pretty {
    my($n,$width) = @_;
    $width -= 2; # back off for negative stuff
    $n = sprintf("%.2f",$n); # sprintf is in later chapter
    if ($n < 0) {
        return sprintf("%$width.2f%", -$n);
    } else {
        return sprintf("% $width.2f%", $n);
    }
}

###
# Plot current DATA Array
###
sub create_pie_chart {
	my($Title,$OutFile) = @_;
	use GD::Graph::pie;
	use GD::Graph::Data;

	my $graph = GD::Graph::pie->new(200, 200);
	
	$graph->set(
        	title             => $Title,
	        transparent       => 0,
	        legend_placement  => 'BC',
        	bgclr             => 'white',
        	fgclr             => 'black',
        	pie_height        => 15,
        	start_angle       => 60,
		#dclrs             => ['blue','red','orange','green'],
		dclrs             => ['green','yellow','orange','red'],	
		text_space	  => 10,
	);

	$graph->set_title_font(gdLargeFont);
	$graph->set_value_font(gdSmallFont);
	$graph->set_label_font(gdSmallFont);

	my $gd = $graph->plot(\@DATA);
	open(IMG, "> $OutFile") or die $!;
	binmode IMG;
	print IMG $gd->png;
	close IMG;
#	$map = new GD::Graph::Map($gd, info=> '%p%');
#	$HTML_MAP = $map->imagemap("$OutFile",\@DATA);
}

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
    } else {
            print "mail sent correctly\n";
    }

}
