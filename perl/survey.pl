#!/tools/perl/5.6.0/SunOS/bin/perl
#
# Read survey results, create report web page and cvs file.
#
#

use Data::Dumper;
use IO::File;
use GD;
use GD::Text;
use Date::Manip;
use Mail::Sendmail;
use Tie::IxHash;
#use GD::Graph::Map;

chop($MYYEAR=`date '+%Y'`);
chop($MYMONTH=`date '+%m'`);

$RPT_DIR="/home/vobadm/public_html/tmp/survey_1";
$IMG_DIR="/home/vobadm/public_html/images";
$SURVEY_FIELDS="/home/vobadm/public_html/tmp/survey/fields.txt";
$WEB_HOME="http://intranet.broadcom.com/\~vobadm";
$HTML_FILE="/home/vobadm/public_html/surveyresult${MYYEAR}${MYMONTH}.html";
$LINK="$WEB_HOME/reports/monthly/${MYYEAR}_${MYMONTH}.html";
$CSVFILE="/home/vobadm/public_html/surveycsv.txt";

# the survey fields file should have all the parameters and the question in English form
# format FIELD=QUESTION
tie %QLIST, "Tie::IxHash";
open(SF, "< $SURVEY_FIELDS") or die "Can't open survey fields config file: $!";
while (<SF>) {
	chop;
	my ($QVALUE, $DESCR) = split(/\s*=\s*/, $_, 2);
#	push(@{$QLIST{$QVALUE}}, $DESCR);
	$QLIST{$QVALUE} = $DESCR;
}
close(SF);

opendir(TOPDIR, $RPT_DIR) or die "Can't access $RPT_DIR: $!";
while (defined ($MYFILE = readdir TOPDIR)) {
	next if $MYFILE =~ /^\.\.?$/;     # skip . and ..
	next if $MYFILE =~ /^comments$/; # skip the comments file
	next if $MYFILE =~ /^ips$/; # skip the ips file
	next if $MYFILE =~ /^fields.txt$/; # skip the fields file
	open(FH, "< ${RPT_DIR}/${MYFILE}") or die "Can't open file ${RPT_DIR}/${MYFILE}: $!";
#	print "${RPT_DIR}/${MYFILE}\n";
	while (<FH>) {
		chomp;
		s/^\s+//;               # no leading white
    		s/\s+$//;               # no trailing white
		next if /^Survey*/;
		next if /^Additional_Comments*/;
		next if /^Submit_Survey*/;
		next if /^=$/;
			my ($VAR, $VALUE) = split(/\s*=\s*/, $_, 2);
			$$VAR->{TOTAL}++;
			if ( $VALUE =~ /Yes/ ) {
				$$VAR->{Y}++;
			}
			if ( $VALUE =~ /No/ ) {
				$$VAR->{N}++;
			}
			if ( $VALUE =~ /NA/ ) {
				$$VAR->{NA}++;
			}
			if ( $VALUE =~ /NS/ ) {
				$$VAR->{NS}++;
			}
			#print "$$VAR->{TOTAL}\n";
		}
		close(FH);
	}
	closedir(TOPDIR);
	#
	#  TEST SECTION
	# 
	#print Dumper(\%QLIST);
	#print Dumper(\$Use_ClearCase);
	#print Dumper(\$Satisfied_ClearCase);

	#print "Use_ClearCase\n";
	#print "Total $Use_ClearCase->{TOTAL}\n";
	#print "Yes $Use_ClearCase->{Y}\n";
	#print "No $Use_ClearCase->{N}\n";
	#print "Description @{$QLIST{Use_ClearCase}}\n";
	while ( ($F,$D) = each %QLIST ) {
	#	print "@{QLIST{$F}}\n";
	}


	# Creating Pie Charts
	#

	open(CSV, "> $CSVFILE") or die "Can't create CSV file: $!";
	foreach $Field (keys %QLIST) {
	#	print "$Field $$Field->{TOTAL}\n";
		undef @DATA;
		$COL=0;
		$total = $$Field->{TOTAL};
		print CSV "Question: @{QLIST{$Field}}\n";
		if ( defined($$Field->{Y}) ) {
			$per_y = sprintf("%.1f",($$Field->{Y} / $total) * 100);
			$DATA[0]->[$COL] = "Yes $per_y%";
			$DATA[1]->[$COL] = "$per_y";
			$COL++;
			print CSV "Yes,$per_y\n";
		}
		if ( defined($$Field->{N}) ) {
			$per_n = sprintf("%.1f",($$Field->{N} / $total) * 100);
			$DATA[0]->[$COL] = "No $per_n%";
			$DATA[1]->[$COL] = "$per_n";
			$COL++;
			print CSV "No,$per_n\n";
		}
		if ( defined($$Field->{NA}) ) {
			$per_na = sprintf("%.1f",($$Field->{NA} / $total) * 100);
			$DATA[0]->[$COL] = "NA $per_na%";
			$DATA[1]->[$COL] = "$per_na";
			$COL++;
			print CSV "NA,$per_na\n";
		}
		if ( defined($$Field->{NS}) ) {
			$per_ns = sprintf("%.1f",($$Field->{NS} / $total) * 100);
			$DATA[0]->[$COL] = "NS $per_ns%";
			$DATA[1]->[$COL] = "$per_ns";
			$COL++;
			print CSV "NS,$per_ns\n";
		}
		print CSV "Total,$total\n";
	#	print Dumper(\@DATA);
		&create_pie_chart("$Field","${IMG_DIR}/${Field}${MYYEAR}${MYMONTH}.png");
	}
	close (CSV);

	# Creating Web Page

	open(HTMLPAGE, "> $HTML_FILE") || die "Can't open File $HTML_FILE: $!\n";
	print HTMLPAGE "
	\<HTML\>
	\<HEAD\>
	  \<META HTTP-equiv=\"Content-Type\" content=\"text/html; charset=windows-1252\"\>
	  \<META name=\"Description\" content=\"BSE ClearCase Survey Report $MYMONTH-$MYYEAR\"\>
	  \<META name=\"Broadcom, IsoFax, Fax\" content=\"BSE ClearCase Survey Report $MYMONTH-$MYYEAR\"\>
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
	  \<TD\> \<H1\>\<P ALIGN=CENTER\>ClearCase Survey Result for $MYMONTH/$MYYEAR \</P\>\</H1\>\</
	TD\>
	  \</TR\>
	";

	foreach $Field (keys %QLIST) {
	print HTMLPAGE "
	  \<TR\>\<TD BGCOLOR=\"CCCCCC\" COLSPAN=2\>Question: @{QLIST{$Field}}\<BR\>\</TD\>\</TR\>
	  \<TR\>
	  \<TD ALIGN=LEFT VALIGN=TOP\>\<BR\>
		\<TABLE BORDER=1 CellSpacing=0\>
	";
		$total = $$Field->{TOTAL};
		if ( defined($$Field->{Y}) ) {
			$per_y = sprintf("%.1f",($$Field->{Y} / $total) * 100);
			print HTMLPAGE "\<TR\>\<TD NOWRAP\>Yes\</TD\>\<TD ALIGN=RIGHT\> $$Field->{Y} \($per_y\%\)\</TD\>\</TR\>";
		}
		if ( defined($$Field->{N}) ) {
			$per_n = sprintf("%.1f",($$Field->{N} / $total) * 100);
			print HTMLPAGE "\<TR\>\<TD NOWRAP\>No\</TD\>\<TD ALIGN=RIGHT\> $$Field->{N} \($per_n\%\)\</TD\>\</TR\>";
		}
		if ( defined($$Field->{NA}) ) {
			$per_na = sprintf("%.1f",($$Field->{NA} / $total) * 100);
			print HTMLPAGE "\<TR\>\<TD NOWRAP\>NA\</TD\>\<TD ALIGN=RIGHT\> $$Field->{NA} \($per_na\%\)\</TD\>\</TR\>";
		}
		if ( defined($$Field->{NS}) ) {
			$per_ns = sprintf("%.1f",($$Field->{NS} / $total) * 100);
			print HTMLPAGE "\<TR\>\<TD NOWRAP\>NS\</TD\>\<TD ALIGN=RIGHT\> $$Field->{NS} \($per_ns\%\)\</TD\>\</TR\>";
		}
		
		print HTMLPAGE "
		\<TR\>\<TD NOWRAP\>Total\</TD\>\<TD ALIGN=RIGHT\> $$Field->{TOTAL}\</TD\>\</TR\>
		\</TABLE\>
		  \</TD\>
		  \<TD\>\<IMG SRC=\"images/${Field}${MYYEAR}${MYMONTH}.png\" ALT=\"$Field Statistics\"\>\</TD\> 
		  \</TR\>
	";

	}

	print HTMLPAGE "
		\</TABLE\>
		\</TD\>\</TR\>
	\</TABLE\>
	\</BODY\>
	\</HTML\>

	";


	close(HTMLPAGE);

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

        my $graph = GD::Graph::pie->new(250, 250);

        $graph->set(
                title             => $Title,
                transparent       => 0,
                legend_placement  => 'BC',
                bgclr             => 'white',
                fgclr             => 'black',
                pie_height        => 15,
                start_angle       => 60,
                dclrs             => ['blue','red','yellow','green'],
                #dclrs             => ['green','yellow','orange','red'],
                text_space        => 10,
        );

        $graph->set_title_font(gdLargeFont);
        $graph->set_value_font(gdLargeFont);
        $graph->set_label_font(gdSmallFont);

        my $gd = $graph->plot(\@DATA);
        open(IMG, "> $OutFile") or die $!;
        binmode IMG;
        print IMG $gd->png;
        close IMG;
}
