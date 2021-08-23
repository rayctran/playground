#!/tools/perl/5.6.0/SunOS/bin/perl

use Data::Dumper;

$LogFile="/tools/isofax/logs/modem_usage/24-04-2002";

$LookupDate="4/24/2002";
#Define time template from 5:00AM to 11:00PM
@TimeTemplate = (
                "5:00-6:00",
                "6:00-7:00",
                "7:00-8:00",
                "8:00-9:00",
                "9:00-10:00",
                "10:00-11:00",
                "11:00-12:00",
                "12:00-13:00",
                "13:00-14:00",
                "14:00-15:00",
                "15;00-16:00",
                "16:00-18:00",
                "18:00-19:00",
                "19:00-20:00",
                "20:00-21:00",
                "21:00-22:00",
                "22:00-23:00",
                "23:00-24:00",
        );

if ( (-e $LogFile) == 0 ) {
        print "File $LogFile does not exists. Please try again.\n";
        exit 1;
}

open (LOGFILE, "$LogFile") or print "Die" and die;
while (<LOGFILE>) {
	#	print "$_";
	push(@MyFile, $_);
}

# Count the modems so we know how many seperate modems there are
$modemcnt = 0;
foreach $k (@MyFile) {
	if ( $k =~ /^.*\/(.*?)\s*\=\=\>\s*(\d*)\s*\n$/ ) {
		if ( $modemnames =~ /$1/ ) {
			next;	
		} else {
			$modemnames = join " ", $modemnames, $1;
			$modemcnt++;
		}
	}
}

#print Dumper(\@MyFile);
$column = 0;
$matched = 0;
foreach $i (@TimeTemplate) {
	foreach $ifile (@MyFile) {
		if ( $matched == 1 )  {
			if ( $ifile =~ /^\n$/ ) {
		#		print "found blank line exit loop\n";
				last;
			} elsif ( $ifile =~ /^.*\/(.*?)\s*\=\=\>\s*(\d*)\s*$/ ) {
				push(@modemdata, $2);
			}	
		} else {
			if ( $ifile =~ /\s*$i\s*/ ) {
				($hexa,$time,$date) = split (' ', $ifile);
				push(@modemdata, $time);
				$matched = 1;
			}
		}
	}
		
	print "making column $column\n";
	#	print "$#modemdata\n";
	# print Dumper(\@modemdata);
	if ( $matched == 0 ) {
		$data[0]->[$column] = $i;
		for($m=1; $m < $modemcnt + 1; $m++ ) {
			print "building row $m\n";
			$data[$m]->[$column] = 0;
		}
	} else {
		$data[0]->[$column] = "$time";
		for($m=1; $m < scalar(@modemdata); $m++) {
			print "building row $m\n";
			$data[$m]->[$column] = $modemdata[$m];
		}
		undef $time;
		undef @modemdata;
		$matched = 0;
	}
	$column++;
}

print Dumper(\@data);
exit 0;

########
$modemno=0;
foreach $i (@MyFile) {
	if ( $i =~ /$LookupDate/ ) {
	        if (defined $time) {
                	push(@TempData,"$string");
        	}
		($hexa,$time,$date) = split (' ', $i);
		$string = "$time";
	}
	if ( $i =~ /^.*\/(.*?)\s*\=\=\>\s*(\d*)\s*$/ ) {
		$string= join ",", $string, $2;
	}

}
# Push the last line to the temp array since we exit
push(@TempData, "$string");


print "$modems\n";
print Dumper(\@TempData);

exit 0;
####

$a = `cat /tools/isofax/logs/modem_usage/25-04-2002`;


# Ramana
#%h = ($a =~ /^.*\/(.*?)\s*\=\=\>\s*(\d*)\s*$/gm);

#foreach $Item (keys %h) {
	#	print "$Item\n";
	#}
#print Dumper(\%h);


# Sree's
@b = split(/^.*\/\d{4}$/m, $a);
print Dumper(\@b);
for $i (@b) {
	$j=$i;
	$i =~ s/\n/ /g;
	if ($i =~ /^.*\/(.*?)\s*\=\=\>\s*(\d*)\s*$/) {
		printf ("%-20s%-25s\n",$1,$2);
		if ($modems =~ /$1/) {
			print "already in modem list\n";
		} else {
			$modems = join " ", $modems, $1;
		}
	}
	$recno++;

}
print "$modems\n";
####

