#!/usr/local/bin/perl
#######################
#######################
### Name: rmlogin
### Author: Ray Tran
### Date: 06/16/1999
### Purpose: Removes Unix logins for NIS and NIS+
### Usage: rmlogin.pl user user user
### Parameter
### Username - valid user login
###
### Restriction
### Must be executed by a user who is in the sysadmin 
### NIS+ group and in the sysadmin network group.
###
### required perl in /usr/local/bin
###
### Modification history
### Author:
### Date:
### Purpose:
###
###
#######################

if ($#ARGV < 0) {
	print "Usage: $0 {user user user}\n";
	exit (1);
} else {
	@Users=@ARGV;
}

$NISMaster="yooper";
$NISP_DIR="/var/adm/security";
$MyDomain=`bin/domainname`;
$O="org_dir.$MyDomain.";
$G="groups_dir.$MyDomain.";
$LogFile="$NISP_DIR/log/$MyDomain.log";
chop($Today=`date +%m/%d/19%y`);
$Me=$ENV{'LOGNAME'};
$PassFile="$NISP_DIR/$NISMaster/etc/passwd";
$GrpFile="$NISP_DIR/$NISMaster/etc/group";
$AliasFile="$NISP_DIR/$NISMaster/etc/aliases";
$AliasDir="/adm/lib/aliases";
$HomeRepDir="$NISP_DIR/xemplhome";
$NPpassFile="/tmp/nispasswd.$$";
$NPgrpFile="/tmp/nispasswd.$$";
$NPaliasFile="/tmp/nisaliases.$$";

# Checking NIS+ access
$MyAcess=`/bin/nisgrpadm -l admin | grep $Me` ;
if ($MyAcess eq "") {
   print "Sorry, you are not a member of the NIS+ admin group.\n";
   print "Please try again after you have been added to the NIS+ admin group\n";
   exit (1);
}
# Password section
open(CURFILE, "<$PassFile") || die "Can't open NIS password file\n";
    @MyArray=(<CURFILE>);
close CURFILE;
foreach $User (@Users) {
    # Checking userid
    ($login,$passwd,$uid,$gid,$gcos,$home,$shell)=getpwname($User);
    if ($login eq " ") {
        print "User not found in the passwd database\n";
    } else {
        print "Found $User\n in the passwd database\n"; 
        print "Creating entry in the password history database for user $User\n";
        system ("/bin/nistbladm -a [name=$login,passwd="$passwd",
        uid=$uid,gid=$gid,gcos=$gcos,home=$home,shell=$shell],passwd_his.$O");
        print "Removing passwd entry\n";
        system ("/bin/nistbladm -r [name=$User],passwd.$O");
        print "Removing credential entry\n";
        system ("/bin/nisaddcred -r $login.$MyDomain.";
        $CurItem=0;
        foreach $Line (@MyArray) {
	    if ($Line =~ /\b$login\b.*$/) {
                undef $NISPasswd[$CurItem];
            }
            $CurItem++;
        }
        print "Adding log entry\n";
        &LogIt "User $login was deleted by $Me on $Today\n";
}
# Dumps out the NIS data base
print "Modifying NIS password table\n";
($uid,$gid)=(stat("$PassFile"))[4,5];
&BackupFile($PassFile);
open(NEWFILE, ">$PassFile") || die "Can not open new password file\n";
foreach $Line (@MyArray) {
    print NEWFILE $Line; 
}
close (NEWFILE);
chmod 0775,$PassFile;
chown($uid, $gid, $PassFile) || die "Can't change ownership for the NIS password file";

## Group section
## Dumps out the group table then read it into the array
#system ("/usr/lib/nis/nisaddent -d group  > $NPgrpFile");
#open(NISPGRP, "<$NPgrpFile");
#    @Nispgrp=(<NISPGRP>);
#close NISPGRP; 
#open(NISGRP, "<$GrpFile");
#    @Nisgrp=(<NISGRP>);
#close NISGRP; 
#foreach $User (@Users) {
#   $CurItem=0;
#   foreach $Line (@Nispgrp) {
#       ($gname,$gpasswd,$ggid,$members) = split (/:/,$Line);
#       if ($User eq $gname) {
#           print "Removing NIS+ group $gname\n";
#           &LogIt "Group $gname was deleted by $Me on $Today\n";
#  	   undef $Nispgrp[$CurItem];
##           system("nistbladm -a [name=$gname,table=group,entry=$gname:$ggid:$User],history.org_dir
#       }
#       if ($members =~ /$User/) {
#           print "Removing user $User from NIS+ group $gname\n";
#           &LogIt "User $User was removed from group $gname by $Me on $Today\n";
#           $Nispgrp[$CurItem] =~ s/$User,|,$User|$User//g;
##           system("nistbladm -a [name=$gname,table=group,entry=$gname:$ggid:$User],history.org_dir
#       } 
#       $CurItem++;
#   }
#   $CurItem=0;
#   foreach $Line (@Nisgrp) {
#       ($gname,$gpasswd,$ggid,$members) = split (/:/,$Line);
#       if ($User eq $gname) {
#           print "Removing NIS group $gname\n";
#  	   undef $Nisgrp[$CurItem];
#       }
#       if ($members =~ /$User/) {
#           print "Removing user $User from NIS group $gname\n";
#           $Nisgrp[$CurItem] =~ s/$User,|,$User|$User//g;
#       } 
#       $CurItem++;
#   }
#}
#
#&BackupFile($GrpFile);
#print "Modifying NIS group table\n";
#($uid,$gid)=(stat("$GrpFile"))[4,5];
#open(NEWFILE, ">$GrpFile") || die "Can not open new group file\n";
#foreach $Line (@Nisgrp) {
#    print NEWFILE $Line; 
#}
#close (NEWFILE);
#chown($uid, $gid, $GrpFile) || die "Can not change ownership for the NIS group file";
#print "Populating NIS+ group table\n";
#open(NEWFILE, ">$NPgrpFile") || die "Can not open NIS+ group file\n"; 
#foreach $Line (@Nispgrp) {
#    print NEWFILE $Line; 
#}
#close (NEWFILE);
#system("/usr/lib/nis/nisaddent -r -f $NPgrpFile group") 
#
#$AlFileLst="";
# Aliases section
## Dumps out the aliases table then read it into the array
#open(NISALIAS, "<$AliasFile");
#    @Nisalias=(<NISALIAS>);
#close NISALIAS; 
#foreach $User (@Users) {
#   $CurItem=0;
#   foreach $Line (@Nisalias) {
#       ($alias,$members,$inc,$file) = split (/:/,$Line);
#       if ($User eq $alias) {
#           print "Removing NIS+ alias entry for $User\n";
#  	   undef $Nisalias[$CurItem];
##           system("nistbladm -a [name=$alias,table=aliases,entry=$members],history.org_dir
#       }
#       if ($members =~ /$User/) {
#           print "Removing user $User from NIS+ alias entry $alias\n";
#           $Nisalias[$CurItem] =~ s/$User,|,$User|$User//g;
##           system("nistbladm -a [name=$gname,table=aliases,entry=$members],history.org_dir
#       } 
#       $CurItem++;
#   }
## Check for name entry in the aliases files.
#   chdir("$AliasDir");
#   open(ALCHK,"/bin/grep $User *.alias|");
#   for (<ALCHK>) {
#       ($File) = split (/:/,$_);
#           if ($AlFileLst !~ /$MyItem/) {
#               $AlFileLst="$AlFileList $MyItem";
#           }
#       }
#   }
#   close(ALCHK);
#}

#foreach $File ($AlFileLst) {
#   if (-f $File.$Today == 0) {
#      &BackupFile $File
#   } else {
#      ($uid,$gid)=(stat("$File"))[4,5];
#      open(MYFILE, "<$File") || die "Can not open alias file\n";
#      @TempArr (<MYFILE>);  
#      close (MYFILE);
#      $CurItem=0;
#      foreach $Line (@TempArr) {
#          foreach $User (@Users) {
#              if ($Line =~ /$User/) {
#                 undef $TempArr[$CurItem];
#              }
#          }
#      $CurItem++;
#      }
#      open (NEWFILE,">$File)
#      foreach $Line (@TempArr) {
#          NEWFILE print $Line;
#      }
#      close (NEWFILE);
#      chown($uid, $gid, $File) || die "Can not change ownership for the alias file";
#   }
#}
#&BackupFile($AliasFile);
#print "Modifying NIS alias table\n";
#($uid,$gid)=(stat("$PassFile"))[4,5];
#open(NEWFILE, ">$GrpFile") || die "Can not open new group file\n";
#foreach $Line (@Nisgrp) {
#    print NEWFILE $Line; 
#}
#close (NEWFILE);
#chmod 0775,$GrpFile;
#chown($uid, $gid, $GrpFile) || die "Can not change ownership for the NIS group file";
#print "Populating NIS+ group table\n";
#open(NEWFILE, ">$NPgrpFile") || die "Can not open NIS+ group file\n"; 
#foreach $Line (@Nispgrp) {
#    print NEWFILE $Line; 
#}
#close (NEWFILE);
#system("/usr/lib/nis/nisaddent -r -f $NPgrpFile group") 

# Misc section
#print "Removing user's mail file\n";
#system ("/usr/local/bin/sudo rm /var/mail/$login");
#if (-e /var/mail/$login_SIMS_index0003) {
#    system ("/usr/local/bin/sudo rm /var/mail/$login_SIMS_index003");
#}
#print "Moving user's home directory into the repository\n";
#$HomeDir=`bin/dirname $home`;
#HomeDir;
#system ("/bin/find $login -depth -print | cpio -pdm $HomeRepDir");
#system ("/usr/local/bin/sudo rm -r $login");
#--------

sub LogIt {
   my $Line=@_;
   open(LOG,">>$LogFile")|| die "Can not open Log file $LogFile\n";
   print LOG "$Line\n";
   close LOG;
}

sub BackupFile {
   my $File=@_;
   link($File,$File.$Today);
}
