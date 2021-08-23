#!/usr/local/bin/perl

open(VSO, "/opt/rational/clearcase/bin/cleartool space -avob|");
while(<VSO>) {
    if ($_ =~ /^Total/) {
        @TotalUsageLine = split(" ",);
        $VOB = @TotalUsageLine[5];
        $Size = @TotalUsageLine[7];
        print "Current Size for VOB $VOB is $Size\n";
        $Total = $Total + $Size;
    }
}

print "Total disk usage for all VOBs is $Total\n";
