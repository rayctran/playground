#!/usr/local/bin/perl
############################################################################
###  Author: Ray Tran
###  Date:   Aug 22,2000
###  Purpose: Snapshot of the system performance for reports. The out text
###		file is tab delimited so it can easily imported into MS Excel.
###  Syntax : pulsecheck.pl
###  Requirement : perl
############################################################################
###  HISTORY
############################################################################
###  Date:       Author:       Description
############################################################################

$HOST=`hostname`;
chop($LOGDIR="/unixadm/Perf_Metrics/$HOST");
#
# Checking for Log directory
#
mkdir("$LOGDIR", 0775) if !-e "$LOGDIR";
chop($TODAY=`date '+%m-%d-%Y %H:%M:%S'`);
$SARDATA_FILE="$LOGDIR/sar.data";

# Report files
$CPU="$LOGDIR/sarcpu.txt";
$MEM="$LOGDIR/sarmem.txt";
$SYSCALL="$LOGDIR/sarsyscall.txt";
$FREESM="$LOGDIR/sarfreeswap_mem.txt";
$DRW="$LOGDIR/iostatdiskrw.txt";
$DKRW="$LOGDIR/iostatdiskkrw.txt";
$DSKIO="$LOGDIR/iostatdiskio.txt";
$DF="$LOGDIR/df.txt";
#
#Create header for each report if the file doesn't exists
#
if (!-e $CPU) {
	open(HEAD,">$CPU") || die "Can not open file $CPU\n";
	print HEAD "SAR CPU Utilization\n";
	print HEAD "date\tuser\tsystem\twaiting_for_IO\tidle\n";
	close(HEAD);
}
if (!-e $MEM) {
	open(HEAD,">$MEM") || die "Can not open file $MEM\n";
	print HEAD "SAR Memory Paging\n";
	print HEAD "date\tpage-out_request\tpages_paged-out\tfree_pages\tpage_scanned\tpercentage_of_indode_flushed\n";
	close(HEAD);
}
if (!-e $SYSCALL) {
	open(HEAD,">$SYSCALL") || die "Can not open file $SYSCALL\n";
	print HEAD "SAR System Calls\n";
	print HEAD "date\tsystem_calls\tread\twrite\tfork\texec\tbytes_transferred\tbytes_write\n";
	close(HEAD);
}
if (!-e $FREESM) {
	open(HEAD,">$FREESM") || die "Can not open file $FREESM\n";
	print HEAD "SAR Unused Memory\n";
	print HEAD "date\tfree_memory\tfree_swap\n";
	close(HEAD);
}

if (!-e $DRW) {
	open(HEAD,">$DRW") || die "Can not open file $DRW\n";
	print HEAD "Disk Read Write Bytes Per Second\n";
	print HEAD "date\tdisk\tread\twrite\n";
	close(HEAD);
}
if (!-e $DKRW) {
	open(HEAD,">$DKRW") || die "Can not open file $DKRW\n";
	print HEAD "Disk Read Write Kbytes Per Second\n";
	print HEAD "date\tdisk\tread\twrite\n";
	close(HEAD);
}
if (!-e $DF) {
	open(HEAD,">$DF") || die "Can not open file $DF\n";
	print HEAD "Disk Usage Kbytes Per Partition\n";
	print HEAD "date\tdevice\tcapacity\tused\tavailable\tpercent_used\tmounted\n";
	close(HEAD);
} else {
# Save the current DF report into array
	open(DFIN,"<$DF") || die "Can not open file $DF\n";
	next if /^date/
#	($date,$device,$capacity,$used,$available,$per_used,$mounted)=split(' ',$_);
	@RT=split(' ',$_);
	$device=$RT[1];
	$OLDDF{$device}="$_";
	close(DFIN);
	`cp /dev/null $DF`;
        open(HEAD,">$DF") || die "Can not open file $DF\n";
        print HEAD "Disk Usage Kbytes Per Partition\n";
        print HEAD "date\tdevice\tcapacity\tused\tavailable\tpercent_used\tmount
ed\n";
        close(HEAD);
}
# Samples are taken 10 times for the interval of 10 sec between samples
$INTERVAL=10;
$COUNT=10;
#
#Reset Sar data file
#
`cp /dev/null $SARDATA_FILE`;
`/bin/sar -o $SARDATA_FILE $INTERVAL $COUNT`;
open(CPURPT, ">>$CPU") || die "Can not append to file $CPU\n";
open(SARCPU,"/bin/sar -u -f $SARDATA_FILE |");
while(<SARCPU>) {
	chop;
	if (/^Average/) {
		($header,$usr,$sys,$wio,$idle)=split(' ',$_);
		print CPURPT "$TODAY\t$usr\t$sys\t$wio\t$idle\n";
	}
}
close(SARCPU);
close(CPURPT);

open(MEMRPT, ">>$MEM") || die "Can not append to file $MEM\n";
open(SARMEM,"/bin/sar -g -f $SARDATA_FILE |");

while(<SARMEM>) {
	chop;
	if (/^Average/) {
		($header,$pgout,$ppgout,$pgfree,$pgscan,$ufs_ipf)=split(' ',$_);
		print MEMRPT "$TODAY\t$pgout\t$ppgout\t$pgfree\t$pgscan\t$ufs_ipf\n";
	}
}
close(SARMEM);
close(MEMRPT);

open(SYSRPT, ">>$SYSCALL") || die "Can not append to file $SYSCALL\n";
open(SARSYS,"/bin/sar -c -f $SARDATA_FILE |");

while(<SARSYS>) {
	chop;
	if (/^Average/) {
		($header,$scall,$sread,$swrit,$fork,$exec,$schar,$wchar)=split(' ',$_);
		print SYSRPT "$TODAY\t$scall\t$sread\t$swrit\t$fork\t$exec\t$schar\t$wchar\n";
	}
}
close(SARSYS);
close(SYSRPT);

open(FSMRPT, ">>$FREESM") || die "Can not append to file $SYSCALL\n";
open(SARFM,"/bin/sar -c -f $SARDATA_FILE |");

while(<SARFM>) {
	chop;
	if (/^Average/) {
		($header,$freemem,$freeswap)=split(' ',$_);
		print FSMRPT "$TODAY\t$freemem\t$freeswap\n";
	}
}
close(SARFM);
close(FSMRPT);


open(IOSTAT,"iostat -x|");
while(<IOSTAT>) {
	chop;
	next if (/extended/);
	($disk,$rs,$ws,$krs,$kws,$wait,$actv,$svct)=split(' ',$_);
	push (@disks, {
                disk    => $disk,
                rs    	=> $rs,
                ws   	=> $ws,
                krs     => $krs,
                kws   	=> $kws,
                wait  	=> $wait,
                actv 	=> $actv,
                svct 	=> $actv,
        });
}

close(IOSTAT);

open(DRWRPT, ">>$DRW") || die "Can not append to file $DRW\n";
open(DKRWRPT, ">>$DKRW") || die "Can not append to file $DRW\n";

for($i=0;$i< $#disks + 1;$i++) {
        print DRWRPT "$TODAY\t",$disks[$i]{"disk"},"\t",$disks[$i]{"rs"},"\t",$disks[$i]{"ws"},"\n";
        print DKRWRPT "$TODAY\t",$disks[$i]{"disk"},"\t",$disks[$i]{"krs"},"\t",$disks[$i]{"kws"},"\n";
}

close(DRWRPT);
close(DKRWRPT);

open(DFIN,"df -k -F ufs|");
while(<DFRPT>) {
        next if /^Filesystem/
#       ($date,$device,$capacity,$used,$available,$per_used,$mounted)=split(' ',
$_);
        @RT=split(' ',$_);
        $device=$RT[0];
        $NEWDF{$device}="$_";
}
close(DFIN);
open(DFRPT, ">>$DF") || die "Can not append to $DF\n";
@UNIQ=keys % {{%OLDDF,%NEWDF}};
foreach $I (@UNIQ) {
	print DFRPT "$OLDDF{$I}\n";
	print NEWDF 

}
