#!/tools/perl/5.6.0/SunOS/bin/perl

use Date::Manip;

$now= &UnixDate("today","%b %e, %Y %T");

$html_refresh = '10'; ## use a number for seconds for html meta refresh
$bgcolor='WHITE';
$title_color = 'GREEN';
$text_color = 'BLACK';
$link_color = 'BLUE';
$vlink_color = 'PURPLE';
$warn_color = 'ORANGE';
$danger_color = 'RED';
$fixed_font_face = 'Clean, Fixed, Courier New, Courier, Terminal, Screen';
$q_position = 0;

if ($html_refresh) {
$meta_tag = "<META HTTP-EQUIV=Refresh CONTENT=$html_refresh>";
}


print "Content-Type: text/html\n\n";
print qq {
<HTML>
<HEAD>
<TITLE> IsoFax Queue $now </TITLE>
$meta_tag
</HEAD>
<BODY BGCOLOR=$bgcolor TEXT=$text_color LINK=$link_color VLINK=$vlink_color>

<LEFT><FONT FACE="Verdana,Arial,Helvetica"> IsoFax Queue Jobs $now </FONT> </LEFT>
<BR><BR>
<FONT face=Arial size=-4>
<TABLE border=0 cellPadding=0 cellSpacing=0 width=800 height="10">
<TBODY>
  <TR VALIGN=top>
    <TD bgColor=#000000>
      <TABLE border=0 cellPadding=5 cellSpacing=1 width="100%" height="100%">
        <TR VALIGN=top>
          <TD bgColor=#F9F9F9 width=25>Que Pos</TD>
          <TD bgColor=#F9F9F9 width=150><BR>Sender</TD>
          <TD bgColor=#F9F9F9 width=50><BR>Recipient</TD>
          <TD bgColor=#F9F9F9 width=200><BR>Fax Number</TD>
          <TD bgColor=#F9F9F9 width=50>PgSnt/<BR>PgTotal </TD>
          <TD bgColor=#F9F9F9 width=50>Tries/<BR>Total </TD>
          <TD bgColor=#F9F9F9 width=100>Time<BR>Submitted</TD>
          <TD bgColor=#F9F9F9 width=100><BR>Next Try </TD>
          <TD bgColor=#F9F9F9 width=50>QTime<BR>H:M</TD>
          <TD bgColor=#F9F9F9 width=25><BR>Pri</TD>
        </TR>
        <TR bgColor=#CC0000><TD height="1" Colspan=10></TD></TR>
};

#####################
# Uncomment for production
system("/tools/isofax/bristol/print_queue_info -i /tools/isofax/work/queue_log- -o /tmp/q.$$");
$b = `cat /tmp/q.$$`;
#####################


#####################
# Uncomment to test
#$b = `cat /tools/isofax/public_html/qdata.save`;
#####################

if ( $b =~ /total faxes: 0/ ) {
	print qq {
	  <TR bgColor=#F9F9F9>
	    <TD height=1 Colspan=10 align=CENTER>NO FAXES IN QUEUE</TD>
	  </TR>
	};
} else {
@b = split(/^----------*$/m, $b);
for $i (@b) {
    	$j=$i;
	$i =~ s/\n/ /g;
#	print "record no: $recno \n";
#	print $i, "\n";
	if ($i =~ /npages: (\d+) .* nsent: (\d+) .* pos: (\d+) .* previous_attempts: (.*?) .* priority: (.*?) .* time_submitted: (.*?) .* time_to_send: (.*?) .*  total_attempts: (.*?) .* phone_number: (.*?) .* recipient_name: (.*?) .*?senders_email_address: (.*?) .* $/m) {
		$pages_total = $1; 
		$pages_sent = $2; 
		$q_pos = $3; 
		$prev_att = $4; 
		$priority = $5; 
		$time_sub = $6; 
		$time_to_send = $7; 
		$delta = &DateCalc($time_sub,$time_to_send);
        	($a,$b,$c,$d,$hr,$min,$sec) = split (/:/,$delta);
        	$qtime = "$hr:$min";
        	$total_att = $8;
        	$fax_no = $9;
        	$recipient = $10;
        	$sender = $11;
		print qq {
        	<TR VALIGN=top>
        	  <TD bgColor=#F9F9F9>$q_pos</TD>
        	  <TD bgColor=#F9F9F9>$sender</TD>
        	  <TD bgColor=#F9F9F9>$recipient</TD>
        	  <TD bgColor=#F9F9F9>$fax_no</TD>
        	  <TD bgColor=#F9F9F9>$pages_sent/$pages_total</TD>
        	  <TD bgColor=#F9F9F9>$prev_att/$total_att</TD>
        	  <TD bgColor=#F9F9F9>$time_sub</TD>
        	  <TD bgColor=#F9F9F9>$time_to_send</TD>
        	  <TD bgColor=#F9F9F9>$qtime</TD>
        	  <TD bgColor=#F9F9F9>$priority</TD>
        	</TR>
		};
	}
	$recno++;
}
}
#print "</PRE>";
#select(MYKAKA); $/ = undef; select(STDOUT);
#$a = <MYKAKA>;
#
#print "<pre>$a</pre>";

print qq {
      </TABLE>
    </TD>
  </TR>
</TBODY>
</TABLE>
</BODY>
</HTML>
};
$status = system("rm /tmp/q.$$");
