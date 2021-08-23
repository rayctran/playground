#!/usr/local/bin/perl
#&add_info(junk,"\tNetwork Information\n");
#open(DR, "/etc/defaultrouter") || die "Can not open /etc/defaultrouter";
#while (<DR>) {
#	chop;
#	($Defrouter)=$_;
#	&add_info(junk,"Default Router is\t= $Defrouter\n");
#}
#close(DR);
#open(RS, "/etc/resolv.conf") || die "Can not open /etc/resolv.conf";
#while (<RS>) {
#	if (/^nameserver/) {
#		($ns,$nsip)=split(' ',$_);
#		&add_info(junk,"DNS Server is\t\t= $nsip\n");
#	}
#	if (/^domain/) {
#		($dm,$domain)=split(' ',$_);
#		&add_info(junk,"DNS Domain is\t\t= $domain\n");
#	}
#}
#close(DR);
#chop($temp=`ps -ef | grep ypbind`);
#if (/ypbind/,temp) {
#
#	print "yes\n";
#}
#if (/ypserv/,`ps -ef | grep ypserv`));
#	print "yes\n";
#}
#$PScom="ps -ef";
##chop($domainname=`domainname`);
#open(FINDIT,"$PScom|")|| die "Could not run ps\n";
#while(<FINDIT>) {
#        if (/ypbind/) {
#                &add_info(junk,"System is configured as NIS client for domain $domainname\n");
#                open(FINDIT2,"$PScom|")|| die "Could not run ps\n"; 
#                        while(<FINDIT2>) {     
#                                if (/ypserv/) {
#                                &add_info(junk,"System is configured as NIS server for domain $domain
#name\n");
#                                }
#                        }
#                close(FINDIT2);
#	chop($NISserver=`/usr/bin/ypwhich`);
#	&add_info(junk,"Accessing tables from server $NISserver\n");
#	&add_info(junk,"NIS Servers List\n");
#	`/usr/bin/ypcat -t ypservers >> junk` ;
#        }
#}
#close(FINDIT);
#&add_info(junk,`date`);
#sub add_info {
#	local ($file,$line)=@_;
#	open (INFOFILE, ">>$file")|| die "Can not append to file $file";
#	print INFOFILE $line;
#	close(INFOFILE);
####}

########

# New Test section
#if ( $#ARGV < 0 ) { 
#        $Prompt=0;
#	print "No arguments to pass\n";
#	exit;
#} else {
#        %Arg=@ARGV;
#	while(($key,$value)=each %Arg){	
#			if ($key == "-f") {
#			$File = $value;
#		}
#	}
#	print "File is $File\n";
#} 
#use Time::ParseDate;
#
#use Graph;
#$Graph::debug = 1;
#
#use GD;
#
#@date = localtime();
#while @date {
#	print $_;
#}

#print "$ENV{'LOGNAME'}\n";

#($login,$passwd,$uid)=getpwnam(tran);
#print "$login\n";
#if ($login eq " ") {
#	print "User not found";
#} else {
#	print "$uid\n";
#}

#$Me=$ENV{'LOGNAME'};
#$Me=istest;

# Checking User's access
#$MyAcess=`/bin/nisgrpadm -l admin | grep $Me`;
#if ($MyAcess eq "") {
#   print "Sorry, you are not a member of the NIS+ admin group.\n";
#   print "Please try again after you have been added to the NIS+ admin group\n";
#   exit (1);
#} else {
#   print "you are OK in my book\n";
#}



#$Me=tran;
#$Me="$Me Yvette";
#print "$Me\n";

#print "$Me\n";
#$Old="test1.txt";
#$New="test1.txt.$$";
#$Backup="test1.bak";
#($uid,$gid) = (stat("$Old")) [4,5];
#open(OLD, "<$Old") || die "Can't open file\n";
#@LINES=<OLD>;
#close(OLD);
#open(NEW, ">$New") || die "Can't open file\n";
$CurItem=0;
#foreach $Line (@LINES) {
#    print "The line is $Line\n";
#    if ($Line =~ /\b$Me\b.*$/) {
#        print "Found it\n";
#        undef $LINES[$CurItem];
#    } else {
#        print NEW $Line; 
#    }
#     $Line =~ s/$Me,|,$Me//g;
#    $CurItem++;
#}
# List out the password table and stores it in an array
#@LINES=`/bin/niscat passwd.org_dir`;
#foreach $Line (@LINES) {
#    print "$Line";
#}


#close(NEW);
#
#rename($Old, $Backup);
#rename($New, $Old);
#chown($uid, $gid, $Old);
#open(FILE, '+< $Old') || die "Can't open file\n";
#while (<FILE>) {
#    if ($_ =~ /\b$Me\b.*$/) {
#        print "Found it\n";
#    } else {
#        print
#    }
#}
#chdir("/adm/lib/aliases");
#open(ALCHK,"/bin/grep $Me *.alias|");
#for (<ALCHK>) {
#    ($File) = split (/:/,$_);
#    print "$File\n";
#}
#close(ALCHK);
#$Me=tran;
#$File=test.txt;
#open (TEST,"|ed $File") || die "Can't do it\n";
#}
#close (TEST);
#print "exists\n" if !-e test100.txt;
#$DIR="/tmp/kaka";
#mkdir("$DIR", 0777) if !-e "$DIR";
#print "don't exists\n" if (!-e test1.txt);
#if (-f test.txt == 1) {
#    print "exists\n";
#}
#$SARDATA_FILE="/unixadm/Perf_Metrics/spawn/sar.data";
#open (SARDA,"/bin/sar -d -f $SARDATA_FILE | sed -n -e '/Average/,\$p' | sed -e s/Average// |");
#for(<SARDA>) {
#        chop;
#        ($disk,$busy,$avque,$rw,$blks,$avwait,$avserv)=split(' ',$_);
##        @diska=("$disk", [$busy,$avque,$rw,$blks,$avwait,$avserv]);
##        @diska=([$busy,$avque,$rw,$blks,$avwait,$avserv]);
#        push (@disks, {
#		disk	=> $disk,
#		busy	=> $busy,
#		avque	=> $avque,
#		rw	=> $rw,
#		$blks	=> $blks,
#		avwait	=> $avwait,
#		$avserv	=> $avserv,
#		});
#}
#close(SARDA);
#for($i=0;$i< $#disks + 1;$i++) {
#	print $disks[$i]{"disk"}," rw per sec= ",$disks[$i]{"rw"},"\n";
#}
#$LOGDIR="/unixadm/Perf_Metrics/$HOST";
#$CPU="$LOGDIR/sarcpu.txt";
#$MEM="$LOGDIR/sarmem.txt";
##$SYSCALL="$LOGDIR/sarsyscall.txt";
#$FREESM="$LOGDIR/sarfreeswap_mem.txt";
#$DRW="$LOGDIR/iostatdiskrw.txt";
#$DKRW="$LOGDIR/iostatdiskkrw.txt";
#$DSKIO="$LOGDIR/iostatdiskio.txt";
##Create header for each report
#@RPTS=($CPU, $MEM, $SYSCALL, $FREESM, $DRW, $DKRW, $DSKIO);
#foreach (@RPTS) {
#	print "$_\n";
#}
#open(TEST,"df -k -F ufs|");
#while(<TEST>){
#	($device,$kbytes,$used,$avail,$cap,$mounted)=split(' ',$_);
#	$device=~ s/\//\_/g;
#	$mounted=~ s/\//\_/g;
#	@_=split(' ',$_);
#	$device=$_[0];
#	$mounted=$_[5];
#	print "$device mounted as $mounted\n";
#}
chop($TODAY=`date '+%m-%d-%Y_%H:%M:%S'`);
$DF="df.txt";
$DFE=0;
if (-e $DF) {
	$DFE=1;
	print "file exists\n";
# Save the current DF report into array
        open(DFIN,"<$DF") || die "Can not open file $DF\n";
	while(<DFIN>) {
	        next if /^date|^Disk/;
#       ($date,$device,$capacity,$used,$available,$per_used,$mounted)=split(' ', $_);
        	@RT=split(' ',$_);
        	$device=$RT[1];
		print "device is $device\n";
        	$OLDDF{$device}="$_";
		print "old dev is",$OLDDF{$device},"\n";
	}
        close(DFIN);
        `cp /dev/null $DF`;
}
open(HEAD,">$DF") || die "Can not open file $DF\n";
print HEAD "Disk Usage Kbytes Per Partition\n";
print HEAD "date\tdevice\tcapacity\tused\tavailable\tpercent_used\tmounted\n";
close(HEAD);
#
open(DFRPT, ">>$DF") || die "Can not append to $DF\n";
open(DFIN,"df -k -F ufs|");
while(<DFIN>) {
        next if /^Filesystem/;
        ($device,$capacity,$used,$available,$per_used,$mounted)=split(' ', $_);
	$device=~ s/\//\_/g;
	$mounted=~ s/\//\_/g;
	print "$device mounted as $mounted\n";
	if ($DFE) {
		$NEWDF{$device}=("$TODAY","$device","$capacity","$used","$available","$per_used","$mounted");
	} else {
		print "$TODAY\t$device\t$capacity\t$used\t$available\t$per_used\t$mounted\n";
		print DFRPT "$TODAY\t$device\t$capacity\t$used\t$available\t$per_used\t$mounted\n";		
	}
}
close(DFIN);
if ($DFE == 1) {
	@UNIQ=keys % {{%OLDDF,%NEWDF}};
	foreach $I (@UNIQ) {
#       	 $TXT1=join(\t,"$OLDDF{$I}");
#       	 $TXT2=join(\t,"$NEWDF{$I}");
# 	 print DFRPT "$TXT1\n$TXT2\n";	
	print DFRPT "$OLDDF{$I}\n";
	print DFRPT "$NEWDF{$I}\n";
	}
}
close (DFRPT);
