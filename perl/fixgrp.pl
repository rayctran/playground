#!/usr/local/bin/perl
###
###
###
###
### Name:  fixgrp.pl
### Author:  Ray Tran
### Date:  14-June-1999
### Purpose:  Fix errors generated with grpck command against NIS/NIS+
### Usage:  fixgrp.pl
### Parameter:
###
### Restriction:               
### required /usr/local/bin/perl
###
### Modification history:
###     Author:
###     Date:
###     Purpose:
###
$DATADIR="/var/adm/security";
$NISDIR="${DATADIR}/yooper/etc";
chop($TODAY=`date +%y%m%d`);
$LOGFILE="$DATADIR/log/ec.rockwell.com.log";

sub add {
local($file,$line) = @_;
    ($uid,$gid)=(stat("$file"))[4,5];
    open(FILE,">>$file") || die "Can not open file\n";
    print FILE $line;
    close(FILE);
    chown($uid, $gid, $file) || die "Can't change ownership for file $file\n";
}

sub replace {
local($file,$str1,$str2,$line) = @_;


}
($fileuid,$filegid)=(stat("$NISDIR/group"))[4,5];
rename($NISDIR/group,"$NISDIR/group.$TODAY") || die "Can't create backup file\n";a
open(GRPFILE, "< $NISDIR/group") || die "Can't open group file\n";
@GRPDATA=<GRPFILE>;
close(GRPFILE);
open(GRPCK,"/usr/sbin/grpck /var/adm/security/yooper/etc/group 2>&1 |");
for(<GRPCK>) {
  chop;
  if($_ eq '') {
    $group = '';
    next;
  }
  if($group eq '') {
    ($group) = split(':',$_);
#    print  "group name is $group\n";
    next;
  }
  s/^\t//;
  if($_ =~ "Logname not found") {
     print "$_\n";
  }
}
close(GRPCK);
