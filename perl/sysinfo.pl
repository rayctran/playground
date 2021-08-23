#!/bin/sh
#The next line is executed by bin/sh
exec perl $0 ${1+"$@"}

chop ($hostname=`uname -n`);
chop ($ver=`uname -r`);
chop ($me=`whoami`);
$DataDir="/admin/data/sysinfo";
$Bindir="/home/admin/adm/bin.sun4";
chop ($Today=`date +%y%m%d`);

if ($ver =~ /^4.1/) {
	$Dir="$Bindir/sysinfosunos";
	$OS="sunos";
} elsif ($ver =~ /^5.4/) {
	$Dir="$Bindir/sysinfo2.4";
	$OS="solaris";
} elsif ($ver =~ /^5.5/) {
	$Dir="$Bindir/sysinfo2.5";
	$OS="solaris";
} elsif ($ver =~ /^5.6/) {
	$Dir="$Bindir/sysinfo2.6";
	$OS="solaris";
} else {
	exit 0;
}
$Syso="$DataDir/$OS.sysinfo.$hostname";
$Patcho="$DataDir/$OS.patches.$hostname";
$Crono="$DataDir/crontab.$hostname";
$Dfo="$DataDir/diskinfo.$hostname";
@Files=($Syso,$Patcho,$Crono,$Dfo);
# Backup files 
foreach $i (@Files) {
	if (-e $i) {
		print "File $i exists, renaming file\n";
		rename ($i, "$i.$Today")|| die "Can't create $i.$Today";
	}
}
print "Creating system information file\n";
`$Dir/sysinfo -cfdir $Dir/config @ARGV -level all> $Syso`;
#Create Crontab backup
print "Creating crontab backup file\n";
`/bin/crontab -l > $Crono`;
if ($OS eq "solaris") {
	print "Creating patch listing\n";
	`/bin/showrev -p > $Patcho`;
	print "Creating df file\n";
	&add_info($Dfo,"\n\tMount Table\n\n");
	`cp /etc/vfstab $Dfo`;
	&add_info($Dfo,"\n\tDisk Free Report\n\n");
	`df -k >> $Dfo`;
	$PScom="ps -ef"
}
if ($OS eq "sunos") {
	print "Creating df file\n";
	&add_info($Dfo,"\n\tMount Table\n\n");
	`cp /etc/fstab $Dfo`;
	&add_info($Dfo,"\n\tDisk Free Report\n\n");
	`df -a > $Dfo`;
	$PScom="ps -aux"
}

&add_info($Syso,"\n\tAdditional Network Information\n\n");
open(DR, "/etc/defaultrouter") || die "Can not open /etc/defaultrouter";
while (<DR>) {
        chop;
        ($Defrouter)=$_;
        &add_info($Syso,"Default Router is\t= $Defrouter\n");
}
close(DR);
open(RS, "/etc/resolv.conf") || die "Can not open /etc/resolv.conf";
while (<RS>) {
        chop;
        if (/^nameserver/) {
                ($ns,$nsip)=split(' ',$_);
                &add_info($Syso,"DNS Server is\t\t= $nsip\n");
        }
        if (/^domain/) {
                ($dm,$domain)=split(' ',$_);
                &add_info($Syso,"DNS Domain is\t\t= $domain\n");
        }
}
close(RS);
chop($DomainName=`domainname`);
open(FINDIT,"$PScom|")|| die "Could not run ps\n";
while(<FINDIT>) {
	if (/in.named/) {
		&add_info($Syso,"\nSystem is configured as a DNS server\n");
	}
	if (/rpc.pcnfsd/) {
		&add_info($Syso,"\nSystem is configured as a PC-NFS authentication and print server\n");
	}
        if (/ypbind/) {
                &add_info($Syso,"System is configured as NIS client for domain $DomainName\n");
                open(FINDIT2,"$PScom|")|| die "Could not run ps\n"; 
                        while(<FINDIT2>) {     
                                if (/ypserv/) {
                                &add_info($Syso,"System is configured as NIS server for domain $domain
name\n");
                                }
                        }
                close(FINDIT2);
        chop($NISserver=`/usr/bin/ypwhich`);
        &add_info($Syso,"Accessing NIS tables from server $NISserver\n\n");
        &add_info($Syso,"NIS Servers List\n");
        `/usr/bin/ypcat -t ypservers >> $Syso` ;
        }
}
&add_info($Syso,"\nOutput from ifconfig -a command\n");
`ifconfig -a >> $Syso`;
&add_info($Syso,"\nOutput from netstat -rn command\n");
`netstat -rn >> $Syso`;
&add_info($Syso,"\n");
&add_info($Syso,`date`);

sub add_info {
	local ($file,$line)=@_;
	open (INFOFILE, ">>$file")|| die "Can not append to file $file";
	print INFOFILE $line;
	close(INFOFILE);
}
