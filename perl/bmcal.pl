#!/usr/local/bin/perl

if ($#ARGV < 0) {
        print "Usage: $0 {INPUT FILE}\n";
        exit (1);
} else {
	$File=$ARGV[0];
}

# Set Count
$VTCount=0;
$COCount=0;
$UCOCount=0;
$CICount=0;
$TCOCount=0;
$TLSCCount=0;
$TUCCount=0;
$TCICount=0;
$UVCount=0;
$MKBCount=0;

# Set Total
$VT=0;
$CO=0;
$UCO=0;
$CI=0;
$TCO=0;
$TLSC=0;
$TUC=0;
$TCI=0;
$UV=0;
$MKB=0;

$HVT=0;
$HCO=0;
$HUCO=0;
$HCI=0;
$HTCO=0;
$HTLSC=0;
$HTUC=0;
$HTCI=0;
$HUV=0;
$HMKB=0;

open(BMF,"< $File") || die "Can't open log file\n";
while(<BMF>) {
    if (/^Version/) {
        ($Tag,$Time) = split(/:/,$_);
#        print "$Time\n";
        chop($Time);
        if ( $Time != 0 && $VTCount <= 105 ) {
            if ( $LVT == "" ) {
                $LVT = $Time;
            } 
            if ( $Time < $LVT ) {
                $LVT = $Time;
            }
            if ( $Time > $HVT ) {
                $HVT = $Time;
            }
            $VTCount++;
            $VT = $VT + $Time;
        }
    }
    if (/^One checkout/) {
        ($Tag,$Time) = split(/:/,$_);
        chop($Time);
        if ( $Time != 0 && $COCount <= 61 ) {
            if ( $LCO == "" ) {
                $LCO = $Time;
            } 
            if ( $Time < $LCO ) {
                $LCO = $Time;
            }
            if ( $Time > $HCO ) {
                $HCO = $Time;
            }
            $COCount++;
            $CO=$CO + $Time;
        }
    }
    if (/^One uncheckout/) {
        ($Tag,$Time) = split(/:/,$_);
        chop($Time);
        if ( $Time != 0 && $UCOCount <= 57) {
            if ( $LUCO == "" ) {
                $LUCO = $Time;
            } 
            if ( $Time < $LUCO ) {
                $LUCO = $Time;
            }
            if ( $Time > $HUCO ) {
                $HUCO = $Time;
            }
            $UCOCount++;
            $UCO=$UCO + $Time;
        }
    }
    if (/^One checkin/) {
        ($Tag,$Time) = split(/:/,$_);
        chop($Time);
        if ( $Time != 0 && $CICount <= 33) {
            if ( $LCI == "" ) {
                $LCI = $Time;
            } 
            if ( $Time < $LCI ) {
                $LCI = $Time;
            }
            if ( $Time > $HCI ) {
                $HCI = $Time;
            }
            $CICount++;
            $CI=$CI + $Time;
        }
    }
    if (/^Ten uncheckout/) {
        ($Tag,$Time) = split(/:/,$_);
        chop($Time);
        if ( $Time != 0 && $TCOCount <= 118 ) {
            if ( $LTCO == "" ) {
                $LTCO = $Time;
            } 
            if ( $Time < $LTCO ) {
                $LTCO = $Time;
            }
            if ( $Time > $HTCO ) {
                $HTCO = $Time;
            }
            $TCOCount++;
            $TCO=$TCO + $Time;
        }
    }
    if (/^Ten checkin/) {
        ($Tag,$Time) = split(/:/,$_);
        chop($Time);
        if ( $Time != 0 && $TCICount <= 118 ) {
            if ( $LTCI == "" ) {
                $LTCI = $Time;
            } 
            if ( $Time < $LTCI ) {
                $LTCI = $Time;
            }
            if ( $Time > $HTCI ) {
                $HTCI = $Time;
            }
            $TCICount++;
            $TCI=$TCI + $Time;
        }
    }
    if (/^Ten lscheckout/) {
        ($Tag,$Time) = split(/:/,$_);
        chop($Time);
        if ( $Time != 0 && $TLSCCount <= 118 ) {
            if ( $LTLSC == "" ) {
                $LTLSC = $Time;
            } 
            if ( $Time < $LTLSC ) {
                $LTLSC = $Time;
            }
            if ( $Time > $HTLSC ) {
                $HTLSC = $Time;
            }
            $TLSCCount++;
            $TLSC=$TLSC + $Time;
        }
    }
    if (/^Ten uncheckout/) {
        ($Tag,$Time) = split(/:/,$_);
        chop($Time);
        if ( $Time != 0 && $TUCCount <= 118 ) {
            if ( $LTUC == "" ) {
                $LTUC = $Time;
            } 
            if ( $Time < $LTUC ) {
                $LTUC = $Time;
            }
            if ( $Time > $HTUC ) {
                $HTUC = $Time;
            }
            $TUCCount++;
            $TUC=$TUC + $Time;
        }
    }
    if (/^Update view/) {
        ($Tag,$Time) = split(/:/,$_);
        chop($Time);
        if ( $Time != 0 && $UVCount <= 118 ) {
            if ( $LUV == "" ) {
                $LUV = $Time;
            } 
            if ( $Time < $LUV ) {
                $LUV = $Time;
            }
            if ( $Time > $HUV ) {
                $HUV = $Time;
            }
            $UVCount++;
            $UV=$UV + $Time;
        }
    }
    if (/^One mkbranch/) {
        ($Tag,$Time) = split(/:/,$_);
        chop($Time);
        if ( $Time != 0 && $MKBCount <= 113 ) {
            if ( $LMKB == "" ) {
                $LMKB = $Time;
            } 
            if ( $Time < $LMKB ) {
                $LMKB = $Time;
            }
            if ( $Time > $HMKB ) {
                $HMKB = $Time;
            }
            $MKBCount++;
            $MKB=$MKB + $Time;
        }
    }
}

close (BMF);

# Getting rid of the high and low mark, recalculate the count then 
# average it out
$X = $HVT + $LVT;
$VT = $VT - $X;
$VTCount = $VTCount - 2;
$VAverage=$VT / $VTCount;
print "$VTCount Samples collected for Version Tree listing.";
printf ("The average is %.2f seconds \n",$VAverage);
print "The highest time is $HVT and the lowest time is $LVT.\n";


# Getting rid of the high and low mark, recalculate the count then 
# average it out
$X = $HCO + $LCO;
$CO = $CO - $X;
$COCount = $COCount - 2;
$COverage=$CO / $COCount;
print "$COCount Samples collected for One checkout.";
printf ("The average is %.2f seconds \n",$COverage);
print "The highest time is $HCO and the lowest time is $LCO.\n";

# Getting rid of the high and low mark, recalculate the count then 
# average it out
$X = $HUCO + $LUCO;
$UCO = $UCO - $X;
$UCOCount = $UCOCount - 2;
$UCOverage=$UCO / $UCOCount;
print "$UCOCount Samples collected for One uncheckout.";
printf ("The average is %.2f seconds \n",$UCOverage);
print "The highest time is $HUCO and the lowest time is $LUCO.\n";

# Getting rid of the high and low mark, recalculate the count then 
# average it out
$X = $HCI + $LCI;
$CI = $CI - $X;
$CICount = $CICount - 2;
$CIverage=$CI / $CICount;
print "$CICount Samples collected for One checkin.";
printf ("The average is %.2f seconds \n",$CIverage);
print "The highest time is $HCI and the lowest time is $LCI.\n";

# Getting rid of the high and low mark, recalculate the count then 
# average it out
$X = $HTCO + $LTCO;
$TCO = $TCO - $X;
$TCOCount = $TCOCount - 2;
$TCOverage=$TCO / $TCOCount;
print "$TCOCount Samples collected for Ten checkouts.";
printf ("The average is %.2f seconds \n",$TCOverage);
print "The highest time is $HTCO and the lowest time is $LTCO.\n";

# Getting rid of the high and low mark, recalculate the count then 
# average it out
$X = $HTCI + $LTCI;
$TCI = $TCI - $X;
$TCICount = $TCICount - 2;
$TCIverage=$TCI / $TCICount;
print "$TCICount Samples collected for Ten checkins.";
printf ("The average is %.2f seconds \n",$TCIverage);
print "The highest time is $HTCI and the lowest time is $LTCI.\n";

# Getting rid of the high and low mark, recalculate the count then 
# average it out
$X = $HTLSC + $LTLSC;
$TLSC = $TLSC - $X;
$TLSCCount = $TLSCCount - 2;
$TLSCverage=$TLSC / $TLSCCount;
print "$TLSCCount Samples collected for Ten lscheckouts.";
printf ("The average is %.2f seconds \n",$TLSCverage);
print "The highest time is $HTLSC and the lowest time is $LTLSC.\n";

# Getting rid of the high and low mark, recalculate the count then 
# average it out
$X = $HTCU + $LTUC;
$TUC = $TUC - $X;
$TUCCount = $TUCCount - 2;
$TUCverage=$TUC / $TUCCount;
print "$TUCCount Samples collected for Ten uncheckouts.";
printf ("The average is %.2f seconds \n",$TUCverage);
print "The highest time is $HTUC and the lowest time is $LTUC.\n";

# Getting rid of the high and low mark, recalculate the count then 
# average it out
$X = $HUV + $LUV;
$UV = $UV - $X;
$UVCount = $UVCount - 2;
$UVverage=$UV / $UVCount;
print "$UVCount Samples collected for Update view.";
printf ("The average is %.2f seconds \n",$UVverage);
print "The highest time is $HUV and the lowest time is $LUV.\n";

# Getting rid of the high and low mark, recalculate the count then 
# average it out
$X = $HMKB + $LMKB;
$MKB = $MKB - $X;
$MKBCount = $MKBCount - 2;
$MKBverage=$MKB / $MKBCount;
print "$MKBCount Samples collected for makebranch.";
printf ("The average is %.2f seconds \n",$MKBverage);
print "The highest time is $HMKB and the lowest time is $LMKB.\n";
