#!/usr/local/bin/perl
########################################################################
########################################################################
###                                                                  ###
###                                                                  ###
### Name:  syncdomain                                                ###
###                                                                  ###
###                                                                  ###
### Author:  Ray Tran                                                ###
###                                                                  ###
###                                                                  ###
### Date:  26-MAR-1999                                               ###
###                                                                  ###
###                                                                  ###
### Purpose:  Create script file to synchronize the NIS and NIS+     ###
###     domains.                                                     ###
###                                                                  ###
###                                                                  ###
### Usage:  syncdomain                                               ###
###                                                                  ###
###                                                                  ###
### Parameter:                                                       ###
###                                                                  ###
### Restriction:                                                     ###
### This program must run on Sulpsin                                 ###
###                                                                  ###
### Modification history:                                            ###
###     Author:                                                      ###
###     Date:                                                        ###
###     Purpose:                                                     ###
###                                                                  ###
###                                                                  ###
########################################################################
########################################################################
if ($#ARGV < 0) {
        print "Usage: $0 Table (passwd,aliases,group)\n";
        exit (1);
} else {
	$Table=$ARGV[0];
}

$OutFile="syncit.sh";
chop($Today=`date +19%y%m%d`);
@group_skip=();
@aliases_skip=();
# If the nomatch variable is 1 then something did match between the old and the new entry
@nomatch="";
chop($hostname=`uname -n`);
if ($hostname != "sulpsin") {
	print "Not on sulpsin. Sorry!\n";
	exit 1;
}

open(OUTFILE,">$OutFile") || die "Can't initialize Output file\n";
print OUTFILE "\#\!\/bin\/sh \-x\n";
print OUTFILE "\#Created on $Today\n";
close OUTFILE;
system ("chmod 755 $OutFile");
close OUTFILE;
open(LOG,">syncdomain.log") || die "Can't initialize Log file\n";
&do_passwd if ($Table eq passwd);
&do_group if ($Table eq group);
&do_aliases if ($Table eq aliases);
&do_clean_up;
close LOG;

sub do_passwd {
	print "Working on the password table\n";
	print "Dumping password table to /tmp/passwd.$$\n";
	system ("/bin/niscat passwd  > /tmp/passwd.$$");
	open(NISPASSWD,"/var/adm/security/yooper/etc/passwd") || die "Can't get to NIS passwd file\n";
	while(<NISPASSWD>) {
		chop;
		@NISUser=$_;
		($NISname,$NISpass,$NISuid,$NISgid,$NISgcos,$NIShome,$NISshell)=split(/:/);
		print "Current User is $NISname\n";
		print LOG "Current User is $NISname\n";
#		@NISPname = getpwnam($NISName);
#		($name,$pass,$uid,$gid,$gcos,$home,$shell) = @NISPname;
#		($name,$pass,$uid,$gid,$gcos,$home,$shell) = getpwnam($NISUser);
		($name,@TheRest) = getpwnam($NISname);
		if ($name eq '') {
				print "$NISname not found\n" ;
				print LOG "$NISname not found\n" ;
				if ($NISname =~ /^(X|.+root|daemon|sys|uucp|nobody)/ ) {
					print "Skipping name $NISname\n";	
					print LOG "Skipping name $NISname\n";	
				} elsif ( $NISname =~ /^X/) {
					print "$NISname account disabled\n";		
					print LOG "$NISname account disabled\n";		
					$ExNISname =~ s/^X//;
					print "Removing existing account $ExNISname.\n";		
					print LOG "Removing existing account $ExNISname.\n";		
					&delete_it(passwd,$ExNISname);
				} else {
					&add_it(passwd,@NISUser);
				}
		} else {
			print "User $NISname found\n";
			print LOG "User $NISname found\n";
			if ($NISname =~ /^(X|daemon|sys|bin|uucp|nobody)$/ ) {
				print "Skipping name $NISname\n";
				print LOG "Skipping name $NISname\n";
			} else {
				$NISPUser=&check_it(passwd,${NISname});
#				print "$NISPUser received\n";
				($NISPname,$NISPpass,$NISPuid,$NISPgid,$NISPgcos,$NISPhome,$NISPshell)=split(/:/,$NISPUser);
				print "Checking user name $NISPname\n";
				print LOG "Checking user name $NISPname\n";
				foreach $X (passwd,gcos,gid,home) {
					if (${NIS.$X} ne ${NISP.$X}) {
						print "$X field ${NIS.$X} does not match ${NISP.$X}\n";
						print LOG "$X field ${NIS.$X} does not match ${NISP.$X}\n";
						&change_it(passwd,$X,@NISUser);
					}
				}
			}
		}
	}
	close NISPASSWD;
}


sub do_group {
	print "Dumping group table to /tmp/group.$$\n";
	system ("/usr/lib/nis/nisaddent -d group  > /tmp/group.$$");
	open(NISGRP,"/var/adm/security/yooper/etc/group") || die "Can't get to NIS group file\n";
	while(<NISGRP>) {
		chop;
		@NISgrp=$_;
		($NISname,$NISpass,$NISgid,$NISmembers)=split(/:/);
		$grpStat=&check_it(group,$NISname);
		if ($grpStat == 1 ) {
			print "Group $NISname not found\n";
			&add_it(group,@NISgrp);
		} else {
			$NISPgrp=$grpStat;
			($NISPname,$NISPpass,$NISPgid,@NISPmembers)=split(/:/,$NISPgrp);
			print "Checking group name $NISPgrp\n";
			if ($NISgid ne $NISPgid) {
				print "GID $NISgid does not match $NISPgid\n";
				print LOG "GID $NISgid does not match $NISPgid\n";
				&change_it(group,gid,$NISgid);
			}
			@members=split(',',$NISmembers);	
			@Pmembers=split(',',$NISPmembers);	
                        foreach $X (@members) {
                            

                        }
		}
	}
	close NISGRP;
}


sub do_aliases {
print "Dumping aliases table to /tmp/aliases.$$\n";
system ("/usr/lib/nis/nisaddent -d aliases  > /tmp/aliases.$$");

}

# Function to output the nistbladm command to a file
sub add_it {
local ($Table,$Info)=@_;
#print $Info;
open(OUTFILE,">>$OutFile") || die "Can't open Output file\n";
        if ($Table eq passwd) {
        	($name,$pass,$uid,$gid,$gcos,$home,$shell)=split(/:/,$Info);
        	print OUTFILE "nistbladm -a name=$name passwd=\"$pass\" uid=$uid \\
        	gid=$gid gcos=\"$gcos\" home=$home shell=$shell  passwd.org_dir\n";
        	print OUTFILE "nischmod w-r [name=${name}],passwd.org_dir\n";
        	print OUTFILE "nisaddcred -p $uid -P $name.ec.rockwell.com. local\n";
        	print OUTFILE "nisaddcred -p unix.$uid\@ec.rockwell.com -P $name.ec.rockwell.com. des\n";
        	print OUTFILE "nischown $name [name=${name}],passwd.org_dir\n";
        }
	if ($Table eq group) {
        	($name,$pass,$gid,$members)=split(/:/,$Info);
		print OUTFILE "nistblamd -a name=$name passwd=\"$pass\" gid=$gid \\
		members=$members group.org_dir\n";
	}
close OUTFILE;
}

sub change_it {
local ($Table,$ColName,$Info)=@_;
#print $Info;
open(OUTFILE,">>$OutFile") || die "Can't open Output file\n";
	if ("$Table" == "passwd") {
       		($name,$pass,$uid,$gid,$gcos,$home,$shell)=split(/:/,$Info);
		print OUTFILE "nistbladm -m $ColName=\"$$ColName\" \'[name=${name}],passwd.org_dir\'\n";
	}
close OUTFILE;
}	

sub delete_it {
	local ($Table,$Info)=@_;
open(OUTFILE,">>$OutFile") || die "Can't open Output file\n";
	if ($Table eq passwd) {
		print OUTFILE "nistbladm -r [name=$Info],passwd.org_dir\n";
	}
close OUTFILE;
}	

sub check_it {
	local ($Table,$MyInfo)=@_;
	#print "@_\n";
#	print "User ${MyInfo} was passed on\n";
	if ($Table eq passwd) {
		open(NISPPASSWD,"/tmp/passwd.$$") || die "Can't get to NIS+ passwd file\n";
		while(<NISPPASSWD>) {
			chop;
#			@Line=$_;
#			print "This is it @Line\n";
			($name,$pass,$uid,$gid,$gcos,$home,$shell)=split(/:/);
			print "my name is $name. Matching againts $MyInfo\n" if /^${MyInfo}$/;
			return $_ if ($name =~ /^${MyInfo}$/);
		}
	close NISPPASSWD;
	}
	if ($Table eq group) {
		open(NISPGRP,"/tmp/group.$$") || die "Can't get to NIS+ group file\n";
		while(<NISPGRP>) {
			chop;
			($name,$pass,$gid,$members)=split(/:/);
			if ($name =~ /^${MyGrp}/) {
				return $_;
			} else {
				return 1;
			} 
		}
		close NISPGRP;
	}
}


sub do_clean_up {
	exec 'rm /tmp/*.$$'
}
