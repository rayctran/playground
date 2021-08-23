#!/tools/perl/5.6.0/SunOS/bin/perl

use Date::Manip;
use Data::Dumper;
use Tie::IxHash;
use File::stat;

$START_DATE="23-May-2003"; #&UnixDate("$MONTH/$DATE/$MYYEAR","%d-%b-%Y")
$TEXT_DATE=&UnixDate("$START_DATE", "%a, %d %b");

open(FILE,"/home/raytran/bin/perl/90") or die "Can't open file: $!\n";
while(<FILE>) {
	chop;
	if (/^\>Number:\s+(\w+)$/) {
		$PRNUM=$1;
        }
        if (/^\>Category:\s+(\w+)$/) {
                $PRFILE="${DBDIR}/$1/$PRNUM";
        }
        if (/^\>Arrival-Date:/) {
                $C_NC++;
                $NC++;
                ($KEY,$ADATE) = split(/:/, $_, 2);
                $MYHOUR = &GetHour($ADATE);
                push(@BUSYTIME,$MYHOUR);
        }
        if (/^\>Closed-Date:\s+[A-Z]/) {
                ($KEY,$CDATE) = split(/:/, $_, 2);
                push(@CTIME,$CDATE);
                $PRLIFE=&DateCalc($ADATE,$CDATE,\$ERR,1);
                $LIFEINHOUR = &ConvertDate($PRLIFE);
                $T_LIFEINHOUR = $LIFEINHOUR + $T_LIFEINHOUR;
                $LIFECNT++;
         }
         if (/--gnatsweb-attachment--/) {
                $PRINFO=stat("$PRFILE");
                $PRSIZE = $PRINFO->size;
                $T_PRSIZE = $T_PRSIZE + $PRSIZE;
                $FSCNT++;
         }
         if (/-When:/) {
               ($KEY,$WDATE) = split(/:/, $_, 2);
               if ( $WDATE =~ /$TEXT_DATE/) {
		print "found $_\n";
                       $MYHOUR = &GetHour($WDATE);
                       push(@BUSYTIME,$MYHOUR);
               }
         }
}

print Dumper(\@BUSYTIME);

sub ConvertDate {
        local($TimeSpan)=@_;
        ($YY,$MM,$WK,$DD,$HH,$MM,$SS) = split (/:/, $TimeSpan);
        $DaysinHour = $DD * 8;
        $WeekinHour = $WK * 40;
        $MonthinHour = $MM * 160;
        if ( $MM > 30 ) {
                $MininHour = 1;
        } else {
                $MininHour = 0;
        }
        $TotalTime = $MonthinHour + $WeekinHour + $DaysinHour + $DD + $MininHour;
        return $TotalTime;
}

sub GetHour {
        local($TimeStamp)=@_;
	print "timestamp is  $TimeStamp\n";
        if ( $TimeStamp =~ /\w+\s\w+\s\d+\s([0-2][0-9]):*:*/ ) {
		print "timestamp $TimeStamp converted to $1\n";
                return $1;
        }
}
