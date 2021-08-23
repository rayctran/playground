#!/usr/local/bin/perl
###
###
###
###
### Name:  user.pl
### Author:  Ray Tran
### Date:  14-June-1999
### Purpose:  To be executed with Solstice User Admin
### Usage:  user.pl
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

if ($ENV{'ADM_OPERATION'} eq "postadd") {
print "it works\n";   
}

sub add {
local($file,$line) = @_;
    ($uid,$gid)=(stat("$file"))[4,5];
    open(FILE,">>$file") || die "Can not open file\n";
    print FILE $line;
    close(FILE);
    chown($uid, $gid, $file) || die "Can't change ownership for file $file\n";
}

sub remove {
local($file,$pattern,$line) = @_;
    ($uid,$gid)=(stat("$file"))[4,5];
    open(FILE,"<$file") || die "Can not open file\n";
#        if ($line =~ /^.*$pattern.*$/) {
#         	    
#        } else {
#
#        }    


    close(FILE);
}

sub replace {
local($file,$str1,$str2,$line) = @_;


}

sub backupfile {



}

sub logit {



}
