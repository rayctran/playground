#!/usr/local/bin/perl

chop ($Host = `hostname`);
chop ($Date = `date`);
print "Performance snapshot Report for $Host on $Date\n";
open(PRT, "/usr/platform/`uname -m`/sbin/prtdiag|"); 
while(<PRT>) {
    print $_;
}
print "=================\n";
print "Uptime Quick Look\n";
print "=================\n";
system "uptime";
print "\n";
print "================\n";
print "Top 10 processes\n";
print "================\n";
system "/usr/ucb/ps -aux | head -10";
print "\n";
print "=========\n";
print "CPU Usage\n";
print "=========\n";
system "sar -u 2 10";
print "\n";
print "=========\n";
print "Buffer Cache Usage\n";
print "=========\n";
system "sar -b 2 10";
print "\n";
print "=========\n";
print "Network Interface stats\n";
print "=========\n";
system "netstat -i -I hme0 2 10";


# Detect if this a ClearCase server then use this section
print "===============\n";
print "VOB Size Report\n";
print "===============\n";
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
print "=======================================\n";
print "Total disk usage for all VOBs is $Total\n";
print "\n";
