#!/usr/local/bin/perl

use Time::ParseDate;

use Graph;
$Graph::debug = 1;

use GD;

@date = localtime();

@logs = glob('swaplog-*');
for($i = 0; $i <= $#logs; $i++) {
  if($logs[$i] =~ /^swaplog-(\d{2})(\d{2})(\d{2})$/) {
    if($1 == ($date[4] + 1) && $2 == $date[3] && $3 == $date[5]) {
      splice(@logs,$i,(scalar(@logs) - $i));
      last;
    }
    $logs[$i] = [$1, $2, $3];
    $logs{$3}{$1}{$2} = 1;
  } else {
    die "error";
  }
}

for(@logs) {
  local($month, $day, $year) = @{$_};
  $sd = sprintf("%02d%02d%02d", $month, $day, $year);
  $md = sprintf("%02d/%02d/%02d", $month, $day, $year);

  if(! -e "swap-${sd}.gif") {
    $changes = 1;

    $graph = new Graph;
    $graph->title("Swap Usage on Scully");
    $graph->subtitle($md);
    $graph->keys_label("Time");
    $graph->values_label("% Usage");
    $graph->value_min(0);
    $graph->value_max(100);
    $graph->value_labels("0,10,20,30,40,50,60,70,80,90,100");
    $graph->set_color("red",255,0,0);
    $graph->color_list("red");
    $graph->width(800);
#    $graph->background("bg.gif");

    $current = -1;
    open(LOG,"swaplog-$sd");
    while(<LOG>) {
      chop;
      (s!\[([^\]]+)\]\s*!!) && ($date = $1);
      ($sec,$min,$hour,$mday,$month,$year,$wday,$yday,$isdst) = localtime(parsedate($date));
      $month++;
      ($file, $dev, $swaplo, $blocks, $free) = split(/\s+/, $_);
      $use = ($blocks - $free) / $blocks * 100;
      if($hour > $current) {
        $label = "$hour";
        $current = $hour;
      } else {
        $label = "";
      }
      $graph->data($use,$label);
    }
    $graph->output("swap-${sd}.gif");
    `rsh -l root scully cp /home/admin/zarko/swap/swap-${sd}.gif /doc/www/switch/mis/test/info`;
  }

  if(! -e "swap-${sd}-sm.gif") {
    $changes = 1;

    open (GIF,"swap-${sd}.gif") || die;
    local($large_img) = newFromGif GD::Image(GIF) || die;
    close GIF;
    local($small_img) = new GD::Image(80,36);
    for($x = 0; $x < $large_img->colorsTotal(); $x++) {
      $small_img->colorAllocate($large_img->rgb($x));
    }
    $small_img->copyResized($large_img,0,0,0,0,80,36,800,360);
    open(GIF,">swap-${sd}-sm.gif");
    binmode GIF;
    print GIF $small_img->gif();
    close(GIF);
    `rsh -l root scully cp /home/admin/zarko/swap/swap-${sd}-sm.gif /doc/www/switch/mis/test/info`;
  }

  if(! -e "swap-${sd}.html") {
    $changes = 1;

    open(HTML,">swap-${sd}.html");
    print HTML <<EOP;
<HTML><HEAD>
  <TITLE>Swap Usage on Scully - ${md}</TITLE>
</HEAD><BODY BGCOLOR="#ffffff">
<IMG SRC="swap-${sd}.gif">
<BR CLEAR=ALL>
</BODY></HTML>
EOP
      ;
    close(HTML);
    `rsh -l root scully cp /home/admin/zarko/swap/swap-${sd}.html /doc/www/switch/mis/test/info`;
  }
}

if($changes) {
  open(INDEX,">index.html.new");
  print INDEX qq|<HTML><HEAD>\n|;
  print INDEX qq|  <TITLE>Swap Usage on Scully</TITLE>\n|;
  print INDEX qq|</HEAD><BODY BGCOLOR="#ffffff">\n|;
print "year from $logs[0][2] through $date[5]\n";
  for($y = $logs[0][2]; $y <= $date[5]; $y++) {
print "$y: month from $logs[0][0] through ".($date[4]+1)."\n";
    for($m = $logs[0][0]; $m <= ($date[4] + 1); $m++) {
      open(CAL,"/usr/bin/cal $m 19$y|");
      $caption = <CAL>;
      $labels = <CAL>;
      @cal = <CAL>;
      close(CAL);
      pop(@cal);
      chop(@cal);
      while(scalar(split(" ", $cal[0])) < 7) {
	$cal[0] = "<PRE></PRE> $cal[0]";
      }
      while(scalar(split(" ", $cal[$#cal])) < 7) {
	$cal[$#cal] .= " <PRE></PRE>";
      }
      chop($caption);
      chop($labels);

      print INDEX qq|<TABLE BORDER=4>\n|;
      print INDEX qq|<CAPTION><B>$caption</B></CAPTION>\n|;
      print INDEX qq|<TR>\n|;
      foreach $d (split(" ", $labels)) {
	print INDEX qq|<TH>$d</TH>\n|;
      }
      print INDEX qq|</TR>\n|;
      for(@cal) {
	print INDEX qq|<TR>\n|;
	foreach $d (split(" ", $_)) {
	  local($line,$sd);
	  if($d < 1) {
	    $line = $d;
	  } elsif($logs{$y}{sprintf('%02d',$m)}{sprintf('%02d',$d)}) {
	    $sd = sprintf("%02d%02d%02d", $m, $d, $y);
	    $line = qq|<A HREF="swap-${sd}.html">${d}<IMG SRC="swap-${sd}-sm.gif" BORDER=0></A>|;
	  } else {
	    $line = qq|$d<IMG SRC="blank.gif">|;
	  }
	  print INDEX "<TD ALIGN=RIGHT>$line</TD>\n";
	}
	print INDEX qq|</TR>\n|;
      }
      print INDEX qq|</TABLE>\n|;
    }
  }
  print INDEX qq|</BODY></HTML>\n|;
  close(INDEX);
  rename("index.html.new","index.html");
  `rsh -l root scully cp /home/admin/zarko/swap/index.html /doc/www/switch/mis/test/info`;
}
