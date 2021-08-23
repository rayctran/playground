#!/tools/perl/5.6.0/SunOS/bin/perl
#
# VOB Stats Logging and Graphing
#
# Version: 1.0 - RCT 8/28/2003
#

use Data::Dumper;
use IO::File;
use GD;
use GD::Text;
use Date::Manip;
use Mail::Sendmail;
use Tie::IxHash;

if ($#ARGV < 0) {
        print "Usage: $0 {VOB Name} \n";
        exit (1);
} else {
        $VOBNAME=$ARGV[0];
}

# Get month and date
chop($MYYEAR=`date '+%Y'`);
chop($MYMONTH=`date '+%m'`);
#$MYMONTH="08";
chop($MYDAY=`date '+%d'`);
chop($MYDATE=`date`);


# Working Directories
$LOGDIR="/home/vobadm/public_html/BSE/Reports";
$VOBCOUNTLOG="${LOGDIR}/${VOBNAME}_count_changes_log";
$VOBMONLOG="${LOGDIR}/${VOBNAME}_vobmon_log";
$LOGFILE_LINK="http://intranet.broadcom.com/~vobadm/BSE/Reports/${VOBNAME}_vobmon_log";
$CC_LINK="http://intranet.broadcom.com/~vobadm";

# Primary scalar for the rest of the log file settings

$RPT_DIR="/home/vobadm/public_html/BSE/Reports/${VOBNAME}_report";
$MAIN_WEB_LINK="http://intranet.broadcom.com/~vobadm/BSE/${VOBNAME}_report";

#$RPT_DIR="/home/raytran/public_html/tmp/${VOBNAME}_report";
#$MAIN_WEB_LINK="http://intranet.broadcom.com/~raytran/tmp/${VOBNAME}_report";

# 

$HTML_CURRENT_MONTH="${RPT_DIR}/${VOBNAME}_current_report.html";
$HTML_MONTH_DIR="${RPT_DIR}/${VOBNAME}_monthly_directory.html";
$HTML_MONTH_FILE="${RPT_DIR}/${VOBNAME}_monthly_file.html";
$HTML_MONTH_VS="${RPT_DIR}/${VOBNAME}_monthly_vobsize.html";
$HTML_YEARLY_HISTORY="${RPT_DIR}/${VOBNAME}_${MYYEAR}.html";

$IMG_MO_DI="${RPT_DIR}/${MYYEAR}_${MYMONTH}_${VOBNAME}_directories.png";
$IMG_MO_FI="${RPT_DIR}/${MYYEAR}_${MYMONTH}_${VOBNAME}_files.png";
$IMG_MO_VS="${RPT_DIR}/${MYYEAR}_${MYMONTH}_${VOBNAME}_vobsize.png";
$IMG_YR_DI="${RPT_DIR}/${MYYEAR}_${VOBNAME}_directories.png";
$IMG_YR_FI="${RPT_DIR}/${MYYEAR}_${VOBNAME}_files.png";
$IMG_YR_VS="${RPT_DIR}/${MYYEAR}_${VOBNAME}_vobsize.png";

$CURRENT_LINK="${MAIN_WEB_LINK}/${VOBNAME}_current_report.html";
$YEAR_LINK="${MAIN_WEB_LINK}/${VOBNAME}_${MYYEAR}.html";
$MO_DIR_LINK="${MAIN_WEB_LINK}/${VOBNAME}_monthly_directory.html";
$MO_FILE_LINK="${MAIN_WEB_LINK}/${VOBNAME}_monthly_file.html";
$MO_VS_LINK="${MAIN_WEB_LINK}/${VOBNAME}_monthly_vobsize.html";
$IMG_MO_DI_LN="${MAIN_WEB_LINK}/${MYYEAR}_${MYMONTH}_${VOBNAME}_directories.png";
$IMG_MO_FI_LN="${MAIN_WEB_LINK}/${MYYEAR}_${MYMONTH}_${VOBNAME}_files.png";
$IMG_MO_VS_LN="${MAIN_WEB_LINK}/${MYYEAR}_${MYMONTH}_${VOBNAME}_vobsize.png";
$IMG_YR_DI_LN="${MAIN_WEB_LINK}/${MYYEAR}_${VOBNAME}_directories.png";
$IMG_YR_FI_LN="${MAIN_WEB_LINK}/${MYYEAR}_${VOBNAME}_files.png";
$IMG_YR_VS_LN="${MAIN_WEB_LINK}/${MYYEAR}_${VOBNAME}_vobsize.png";


$Months = {
	"01" => "January",
	"02" => "February",
	"03" => "March",
	"04" => "April",
	"05" => "May",
	"06" => "June",
	"07" => "July",
	"08" => "August",
	"09" => "September",
	"10" => "October",
	"11" => "November",
	"12" => "December",
};

@Month_number=("12","11","10","09","08","07","06","05","04","03","02","01");
# print "$Months->{$MYMONTH}\n";

tie %DIRTRACK, "Tie::IxHash";
tie %FILETRACK, "Tie::IxHash";
tie %VOBSIZE, "Tie::IxHash";
tie %MDIRTRACK, "Tie::IxHash";
tie %MFILETRACK, "Tie::IxHash";
tie %MVOBSIZE, "Tie::IxHash";

open(INLOG, "$VOBMONLOG") or die "Can't open log file $VOBMONLOG: $!\n";
	while(<INLOG>) {
		next if /^Date|^==/;
		chop;
		($Date,$NoOfDir,$NoOfFiles,$VOBSize,$VOBName) = split(/\s+/, $_);
		$DIRTRACK{ $Date } = $NoOfDir;
       		$FILETRACK{ $Date } = $NoOfFiles;
       		$VOBSIZE{ $Date } = $VOBSize;
		if ($Date =~ /^${MYMONTH}\/\d+\/\d+$/) {
			$MDIRTRACK{ $Date } = $NoOfDir;
                       	$MFILETRACK{ $Date } = $NoOfFiles;
                       	$MVOBSIZE{ $Date } = $VOBSize;	
		}
	}
close(INLOG);


# Current Monthly plot
$ThisMonth = $Months->{$MYMONTH};

$DirMax=0;
$DirMin=0;
$y_max_value = 0;
$y_min_value = 0;
$y_tick_number = 0;

while (($date,$dir) = each %MDIRTRACK ) {
#	print "$date, $dir\n";
	$CUR_MDIRTRACK=$dir;
	push(@{ $DATA[0] }, "$date");	
	push(@{ $DATA[1] }, "$dir");	
	if ( $DirMin == 0 ) {
		$DirMin = $dir;
	} elsif ( $dir < $DirMin ) {
		$DirMin = $dir;
	} 
	if ( $dir > $DirMax) {
		$DirMax = $dir;	
	}
}
$y_max_value = $DirMax + 1;
$y_min_value = $DirMin - 1;
$y_tick_number = $y_max_value - $y_min_value;
if ( $y_tick_number > 1000 ) {
	$y_tick_number = $y_tick_number / 100;
} elsif ( $y_tick_number > 100 ) {
	$y_tick_number = $y_tick_number / 10;
}
&create_graph("monthly","$ThisMonth Directory Count for $VOBNAME VOB - current count $CUR_MDIRTRACK","Date","Number of Directories",$y_max_value,$y_min_value,$y_tick_number,"$IMG_MO_DI");

# Files tracking
undef(@DATA);
$FileMax=0;
$FileMin=0;
$y_max_value = 0;
$y_min_value = 0;
$y_tick_number = 0;
while (($date,$file) = each %MFILETRACK ) {
#	print "$date, $file\n";
	$CUR_MFILETRACK=$file;
	push(@{ $DATA[0] }, "$date");	
	push(@{ $DATA[1] }, "$file");	
	if ( $FileMin == 0 ) {
		$FileMin = $file;
	} elsif ( $file < $FileMin ) {
		$FileMin = $file;
	} 
	if ( $file > $FileMax) {
		$FileMax = $file;	
	}
}
$y_max_value = $FileMax + 5;
$y_min_value = $FileMin - 5;
$y_tick_number = $y_max_value - $y_min_value;
if ( $y_tick_number > 1000 ) {
	$y_tick_number = $y_tick_number / 100;
} elsif ( $y_tick_number > 100 ) {
	$y_tick_number = $y_tick_number / 10;
}
#print "$y_max_value $y_min_value $y_tick_number\n";
&create_graph("monthly","$ThisMonth File Count for $VOBNAME VOB - current count $CUR_MFILETRACK","Date","Number of Files",$y_max_value,$y_min_value,$y_tick_number,"$IMG_MO_FI");


# VOB Size tracking
undef(@DATA);
$VobMax=0;
$VobMin=0;
$y_max_value = 0;
$y_min_value = 0;
$y_tick_number = 0;
while (($date,$vob) = each %MVOBSIZE ) {
#	print "$date, $vob\n";
	$CUR_MOVBSIZE=$vob;
	push(@{ $DATA[0] }, "$date");	
	push(@{ $DATA[1] }, "$vob");	
	if ( $VobMin == 0 ) {
		$VobMin = $vob;
	} elsif ( $vob < $VobMin ) {
		$VobMin = $vob;
	} 
	if ( $vob > $VobMax) {
		$VobMax = $vob;	
	}
}

$y_max_value = $VobMax + 10;
$y_min_value = $VobMin - 10;
$y_tick_number = $y_max_value - $y_min_value;
if ( $y_tick_number > 1000 ) {
	$y_tick_number = $y_tick_number / 100;
} elsif ( $y_tick_number > 100 ) {
	$y_tick_number = $y_tick_number / 10;
}
&create_graph("monthly","$ThisMonth VOB Size for $VOBNAME VOB - current size $CUR_MOVBSIZE KB","Date","VOB Size (KB)",$y_max_value,$y_min_value,$y_tick_number,"$IMG_MO_VS");

# Yearly plot

# Directories tracking
undef(@DATA);
$DirMax=0;
$DirMin=0;
$y_max_value = 0;
$y_min_value = 0;
$y_tick_number = 0;

while (($date,$dir) = each %DIRTRACK ) {
	$CUR_DIRTRACK=$dir;
	push(@{ $DATA[0] }, "$date");	
	push(@{ $DATA[1] }, "$dir");	
	if ( $DirMin == 0 ) {
		$DirMin = $dir;
	} elsif ( $dir < $DirMin ) {
		$DirMin = $dir;
	} 
	if ( $dir > $DirMax) {
		$DirMax = $dir;	
	}
}
$y_max_value = $DirMax + 10;
$y_min_value = $DirMin - 10;
$y_tick_number = $y_max_value - $y_min_value;
if ( $y_tick_number > 1000 ) {
	$y_tick_number = $y_tick_number / 100;
} elsif ( $y_tick_number > 100 ) {
	$y_tick_number = $y_tick_number / 10;
}
&create_graph("yearly","$MYYEAR Directory Count for $VOBNAME VOB","Date","Number of Directories",$y_max_value,$y_min_value,$y_tick_number,"$IMG_YR_DI");

# Files tracking
undef(@DATA);
$FileMax=0;
$FileMin=0;
$y_max_value = 0;
$y_min_value = 0;
$y_tick_number = 0;
while (($date,$file) = each %FILETRACK ) {
#	print "$date, $file\n";
	$CUR_FILETRACK=$file;
	push(@{ $DATA[0] }, "$date");	
	push(@{ $DATA[1] }, "$file");	
	if ( $FileMin == 0 ) {
		$FileMin = $file;
	} elsif ( $file < $FileMin ) {
		$FileMin = $file;
	} 
	if ( $file > $FileMax) {
		$FileMax = $file;	
	}
}
$y_max_value = $FileMax + 10;
$y_min_value = $FileMin - 10;
$y_tick_number = $y_max_value - $y_min_value;
if ( $y_tick_number > 1000 ) {
	$y_tick_number = $y_tick_number / 100;
} elsif ( $y_tick_number > 100 ) {
	$y_tick_number = $y_tick_number / 10;
}
#print "$y_max_value $y_min_value $y_tick_number\n";
&create_graph("yearly","$MYYEAR File Count for $VOBNAME VOB","Date","Number of Files",$y_max_value,$y_min_value,$y_tick_number,"$IMG_YR_FI");


# VOB Size tracking
undef(@DATA);
$VobMax=0;
$VobMin=0;
$y_max_value = 0;
$y_min_value = 0;
$y_tick_number = 0;
while (($date,$vob) = each %VOBSIZE ) {
#	print "$date, $vob\n";
	$CUR_VOBSIZE=$vob;
	push(@{ $DATA[0] }, "$date");	
	push(@{ $DATA[1] }, "$vob");	
	if ( $VobMin == 0 ) {
		$VobMin = $vob;
	} elsif ( $vob < $VobMin ) {
		$VobMin = $vob;
	} 
	if ( $vob > $VobMax) {
		$VobMax = $vob;	
	}
}

$y_max_value = $VobMax + 10;
$y_min_value = $VobMin - 10;
$y_tick_number = $y_max_value - $y_min_value;
if ( $y_tick_number > 1000 ) {
	$y_tick_number = $y_tick_number / 100;
} elsif ( $y_tick_number > 100 ) {
	$y_tick_number = $y_tick_number / 10;
}
#print "$y_max_value $y_min_value $y_tick_number\n";
&create_graph("yearly","$MYYEAR VOB Size for $VOBNAME VOB","Date","VOB Size (KB)",$y_max_value,$y_min_value,$y_tick_number,"$IMG_YR_VS");

# Create web pages

open (HTMLCM, "> $HTML_CURRENT_MONTH") || die "Can't open File $HTML_CURRENT_MONTH: $!\n";
print HTMLCM qq {
<HTML>
<HEAD>
  <META HTTP-equiv="Content-Type" content="text/html; charset=windows-1252">
  <META name="Description" content="$VOBNAME Report">
  <META name="Broadcom" content=\"Broadcom $VOBNAME Report current data">
  <STYLE>
  body{font-family:Verdana,Arial,Helvetica,Sans-serif;font-size:12px;}
  td{font-family:Verdana,Arial,Helvetica,Sans-serif;font-size:12px;}
  h1{font-family:Verndana,Arial,Helvetica,Sans-serif;font-size:17px;}
  a {text-decoration:none;}
  blockquote {font-family:courier}
  a:hover {text-decoration:underline}
  input{font-family : Verdana,Arial,Helvetica,Sans-serif;font-size:12px; color:#000000;width : 90px\;}
 </STYLE>
</HEAD>
<BODY>
<H1>VOB Report for $VOBNAME Current data $MYDATE</H1>
Select an optional link below<BR><BR>
[ <A HREF="$CC_LINK">ClearCase Support</A>
| <A HREF="$LOGFILE_LINK">Source Log File</A>
| <A HREF="$MO_DIR_LINK">Monthly Directory</A>
| <A HREF="$MO_FILE_LINK">Monthly File</A>
| <A HREF="$MO_VS_LINK">Monthly VOB Size</A>
| <A HREF="$YEAR_LINK">Yearly Graphs</A> ]
<BR><BR>
<IMG SRC="$IMG_MO_DI_LN" ALT="$Months->{$MYMONTH} directory graph"><BR><BR>
<IMG SRC="$IMG_MO_FI_LN" ALT="$Months->{$MYMONTH} file graph"><BR><BR>
<IMG SRC="$IMG_MO_VS_LN" ALT="$Months->{$MYMONTH} vob size graph"><BR><BR>

</BODY>
</HTML>

};
close(HTMLCM);


open (HTMLYH, "> $HTML_YEARLY_HISTORY") || die "Can't open File $HTML_YEARLY_HISTORY: $!\n";
print HTMLYH qq {
<HTML>
<HEAD>
  <META HTTP-equiv="Content-Type" content="text/html; charset=windows-1252">
  <META name="Description" content="$VOBNAME Report">
  <META name="Broadcom" content=\"Broadcom $VOBNAME Report yearly history">
  <STYLE>
  body{font-family:Verdana,Arial,Helvetica,Sans-serif;font-size:12px;}
  td{font-family:Verdana,Arial,Helvetica,Sans-serif;font-size:12px;}
  h1{font-family:Verndana,Arial,Helvetica,Sans-serif;font-size:17px;}
  a {text-decoration:none;}
  blockquote {font-family:courier}
  a:hover {text-decoration:underline}
  input{font-family : Verdana,Arial,Helvetica,Sans-serif;font-size:12px; color:#000000;width : 90px\;}
 </STYLE>
</HEAD>
<BODY>
<H1>Yearly VOB Report for $VOBNAME $MYYEAR</H1>
Select an optional link below<BR><BR>
[ <A HREF="$CC_LINK">ClearCase Support</A>
| <A HREF="$LOGFILE_LINK">Source Log File</A>
| <A HREF="$CURRENT_LINK">Current Graphs</A> 
| <A HREF="$MO_DIR_LINK">Monthly Directory</A>
| <A HREF="$MO_FILE_LINK">Monthly File</A>
| <A HREF="$MO_VS_LINK">Monthly VOB Size</A> ]
<BR><BR>
<IMG SRC="$IMG_YR_DI_LN" ALT="$MYEAR directory graph"><BR><BR>
<IMG SRC="$IMG_YR_FI_LN" ALT="$MYEAR file graph"><BR><BR>
<IMG SRC="$IMG_YR_VS_LN" ALT="$MYEAR vob size graph"><BR><BR>

</BODY>
</HTML>

};
close(HTMLYH);


open (HTMLMD, "> $HTML_MONTH_DIR") || die "Can't open File $HTML_MONTH_DIR: $!\n";
print HTMLMD qq {
<HTML>
<HEAD>
  <META HTTP-equiv="Content-Type" content="text/html; charset=windows-1252">
  <META name="Description" content="$VOBNAME Report">
  <META name="Broadcom" content=\"Broadcom $VOBNAME Report yearly history">
  <STYLE>
  body{font-family:Verdana,Arial,Helvetica,Sans-serif;font-size:12px;}
  td{font-family:Verdana,Arial,Helvetica,Sans-serif;font-size:12px;}
  h1{font-family:Verndana,Arial,Helvetica,Sans-serif;font-size:17px;}
  a {text-decoration:none;}
  blockquote {font-family:courier}
  a:hover {text-decoration:underline}
  input{font-family : Verdana,Arial,Helvetica,Sans-serif;font-size:12px; color:#000000;width : 90px\;}
 </STYLE>
</HEAD>
<BODY>
<H1>Monthly VOB Report for $VOBNAME $MYYEAR</H1>
Select an optional link below<BR><BR>
[ <A HREF="$CC_LINK">ClearCase Support</A>
| <A HREF="$LOGFILE_LINK">Source Log File</A>
| <A HREF="$CURRENT_LINK">Current Graphs</A> 
| <A HREF="$MO_FILE_LINK">Monthly File</A>
| <A HREF="$MO_VS_LINK">Monthly VOB Size</A>
| <A HREF="$YEAR_LINK">Yearly Graphs</A> ]
<BR><BR>
};
foreach $month (@Month_number) {
	if (-e "${RPT_DIR}/${MYYEAR}_${month}_${VOBNAME}_directories.png") {
		print HTMLMD qq {
			<IMG SRC="${MAIN_WEB_LINK}/${MYYEAR}_${month}_${VOBNAME}_directories.png" ALT="$month directory graph"><BR><BR>
		};
	}
}

print HTMLMD qq {
</BODY>
</HTML>

};
close(HTMLMD);


open (HTMLMF, "> $HTML_MONTH_FILE") || die "Can't open File $HTML_MONTH_FILE: $!\n";
print HTMLMF qq {
<HTML>
<HEAD>
  <META HTTP-equiv="Content-Type" content="text/html; charset=windows-1252">
  <META name="Description" content="$VOBNAME Report">
  <META name="Broadcom" content=\"Broadcom $VOBNAME Report yearly history">
  <STYLE>
  body{font-family:Verdana,Arial,Helvetica,Sans-serif;font-size:12px;}
  td{font-family:Verdana,Arial,Helvetica,Sans-serif;font-size:12px;}
  h1{font-family:Verndana,Arial,Helvetica,Sans-serif;font-size:17px;}
  a {text-decoration:none;}
  blockquote {font-family:courier}
  a:hover {text-decoration:underline}
  input{font-family : Verdana,Arial,Helvetica,Sans-serif;font-size:12px; color:#000000;width : 90px\;}
 </STYLE>
</HEAD>
<BODY>
<H1>Monthly VOB Report for $VOBNAME $MYYEAR</H1>
Select an optional link below<BR><BR>
[ <A HREF="$CC_LINK">ClearCase Support</A>
| <A HREF="$LOGFILE_LINK">Source Log File</A>
| <A HREF="$CURRENT_LINK">Current Graphs</A> 
| <A HREF="$MO_DIR_LINK">Monthly Directory</A>
| <A HREF="$MO_VS_LINK">Monthly VOB Size</A>
| <A HREF="$YEAR_LINK">Yearly Graphs</A> ]
<BR><BR>
};
foreach $month (@Month_number) {
	if (-e "${RPT_DIR}/${MYYEAR}_${month}_${VOBNAME}_files.png") {
		print HTMLMF qq {
			<IMG SRC="${MAIN_WEB_LINK}/${MYYEAR}_${month}_${VOBNAME}_files.png" ALT="$month file graph"><BR><BR>
		};
	}
}

print HTMLMF qq {
</BODY>
</HTML>

};
close(HTMLMF);


open (HTMLMVS, "> $HTML_MONTH_VS") || die "Can't open File $HTML_MONTH_VS: $!\n";
print HTMLMVS qq {
<HTML>
<HEAD>
  <META HTTP-equiv="Content-Type" content="text/html; charset=windows-1252">
  <META name="Description" content="$VOBNAME Report">
  <META name="Broadcom" content=\"Broadcom $VOBNAME Report yearly history">
  <STYLE>
  body{font-family:Verdana,Arial,Helvetica,Sans-serif;font-size:12px;}
  td{font-family:Verdana,Arial,Helvetica,Sans-serif;font-size:12px;}
  h1{font-family:Verndana,Arial,Helvetica,Sans-serif;font-size:17px;}
  a {text-decoration:none;}
  blockquote {font-family:courier}
  a:hover {text-decoration:underline}
  input{font-family : Verdana,Arial,Helvetica,Sans-serif;font-size:12px; color:#000000;width : 90px\;}
 </STYLE>
</HEAD>
<BODY>
<H1>Monthly VOB Report for $VOBNAME $MYYEAR</H1>
Select an optional link below<BR><BR>
[ <A HREF="$CC_LINK">ClearCase Support</A>
| <A HREF="$LOGFILE_LINK">Source Log File</A>
| <A HREF="$CURRENT_LINK">Current Graphs</A> 
| <A HREF="$MO_FILE_LINK">Monthly File</A>
| <A HREF="$MO_DIR_LINK">Monthly Directory</A>
| <A HREF="$YEAR_LINK">Yearly Graphs</A> ]
<BR><BR>
};
foreach $month (@Month_number) {
	if (-e "${RPT_DIR}/${MYYEAR}_${month}_${VOBNAME}_vobsize.png") {
		print HTMLMVS qq {
			<IMG SRC="${MAIN_WEB_LINK}/${MYYEAR}_${month}_${VOBNAME}_vobsize.png" ALT="$month file graph"><BR><BR>
		};
	}
}

print HTMLMVS qq {
</BODY>
</HTML>

};
close(HTMLMVS);


###
# Plot current DATA Array
###

sub create_graph {
        my($type,$title,$x_label,$y_label,$y_max_value,$y_min_value,$y_tick_number,$OutFile) = @_;
	use GD::Graph::linespoints;
        use GD::Graph::Data;
	if ( "$type" eq "yearly" ) {
		$graph_width = 800;
		$graph_height = 400;
	} elsif ( "$type" eq "monthly" ) {
		$graph_width = 550;
		$graph_height = 350;
	}

	my $graph = GD::Graph::linespoints->new($graph_width, $graph_height);
	$graph->set(
        	x_label           => $x_label,
        	y_label           => $y_label,
        	title             => $title,
       	 	y_max_value       => $y_max_value,
        	y_min_value       => $y_min_value,
        	y_tick_number     => $y_tick_number,
        	testy_label_skip      => 0,
        	dclrs             => ['blue','red','green'],
        	line_width        => 2,
        	line_types        => [1,1,1],
        	transparent       => 0,
        	legend_placement  => 'BC',
        	bgclr             => 'white',
        	fgclr             => 'black',
        	long_ticks        => 1,
        	x_labels_vertical => 1,
        	markers 	  => [4,1],
        	markers_size      => 1,
        	zero_axis_only 	  => 0,
	);
	$graph->set_title_font(gdLargeFont);
	$graph->set_legend_font(['verdana','arial','gdSmallFont']);
	$graph->set_y_label_font(gdLargeFont);
	$graph->set_x_label_font(gdLargeFont);
	if ( "$type" eq "yearly" ) {
		$graph->set_x_axis_font(gdSmallFont);
		$graph->set_y_axis_font(gdSmallFont);
	} elsif ( "$type" eq "monthly" ) {
		$graph->set_x_axis_font(gdTinyFont);
		$graph->set_y_axis_font(gdTinyFont);
	}
        my $gd = $graph->plot(\@DATA);
        open(IMG, "> $OutFile") or die $!;
        binmode IMG;
        print IMG $gd->png;
        close IMG;
}
