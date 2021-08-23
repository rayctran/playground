#! /usr/local/bin/perl
use File::Basename;

chop($HOST = `hostname`);
$LOGFILE="/tmp/mykaka.log";
$CC = "/opt/rational/clearcase/bin/cleartool";
#print "Not found\n" if !-e "$LOGDIR";
#system ("$CC lsvob");


## Store ClearCase Regions in an array
#open(CR,"$CC lsregion |");
#while(<CR>) {
#    $REGION = $_;
#    fileparse_set_fstype("MSWin32") if ($REGION =~ /NT/);
#    print "$REGION";
#    open(VOB,"$CC lsvob -region $REGION|");
#    while(<VOB>) {
## Remove the mount indicated character *
#    s/\*//; 
##    print $_;
#    @VOBS = $_;
#    ($VT, $VSL) = split;
## Get the actual VOB's name so we can set up the new storage location
##    print "$VT\n";
#    $VN = basename($VSL);
#    print "$VN\n";
#    }
#}

#$OUT = `/etc/init.d/atria stop 2>&1`;
#print "Printing Error and Output";
#print $OUT;
#$TS=`date`;
#&printit("kaka at $TS\n");

#sub printit {
#local ($Text)=@_;
#print "Printing the message - $Text\n";
#}

#system("cd /vobstore; time tar -cf - Test.vbs | (cd /projects/cctstgloc/vobstore; tar -xBfp - > /tmp/kaka)" );

##############################
#$Region=IrvineNT;
#$Filername="\Q\\\Efs-irva-29\\";
#$NTStorLoc="Projects-V1\\ccase_irva\\cctstgloc\\vobstore\\";

#        fileparse_set_fstype("MSWin32");
## Read in Tag file
# Dumps all NT Region's VOB to a file
#        open(VTF,"/var/adm/atria/rgy/vob_tag") || die "Can not open /var/adm/atria/rgy/vob_tag file/n";
#        open(VTTEMP,">>/tmp/vobtag.tmp")||die "Can not create file /tmp/vobtag.tmp\n";
#        while (<VTF>) {
#            print VTTEMP if /NT/;
#         }
#        close VTF;
#        close VTTEMP;
#        open(NTVOBS,"$CC lsvob -region $Region |");
#        while (<NTVOBS>) {
#            print $_;
#
#        }
#        close NTVOBS;
#        open(VTTEMPR,"/tmp/vobtag.tmp")||die "Can not open /tmp/vobtag.tmp\n";
#        open(NVTFILE,">/tmp/my_vob_tag.tmp") || die "Can not open/var/adm/atria/rgy/vob_tag file/n";
#        while(<VTTEMPR>) {
#            ($Entry1, $VT1, $Gpath1, $Host1, $Mountac1, $Mountopt1, $Reg1, $VRI1) = split (/;/);
#            ($EntryT,$Entry) = split(/=/, $Entry1);
#            ($VTT,$VT) = split(/=/, $VT1);
#            $VBS = basename($Gpath1);
#            ($MountacT,$Mountac) = split(/=/, $Mountac1);
#            ($MountoptT,$Mountopt) = split(/=/, $Mountopt1);
#            ($VRIT,$VRI) = split(/=/, $VRI1);
#            print "Re-creating VOB tag $VT\n";
#            print NVTFILE "-entry=${Entry};-tag=${VT};-global_path=${Filername}${NTStorLoc}${VBS};-hostname=${Host};-mount_access=${Mountac};-mount_option=${Mountopt};-region=${Region};-vob_replica=${VRI}\n";
#        }
#        close(NVTFILE);
###################################
# read in Tag file and dumps all NT Region's VOB to a temporary file
#        open(VTF,"/var/adm/atria/rgy/vob_tag") || die "Can not open /var/adm/atria/rgy/vob_tag file/n";
#        while (<VTF>) {
#        #    print "Current line is $_\n";
#        #    print $_ if /region=[A-Z]+[a-z]+NT/;
#             print $_ if /-id|-dtm|-version/;
#             $LastLine = $_ if / total /;
#        }
#        close VTF;
#        print "last line is $LastLine\n";
#chop($Host = `hostname`);
#if ( $Host =~ /ccase-irva-tst2/ ) {
#    print "Correct\n";
#    $Filername="\Q\\\Efs-irva-29\\";
#    $NTVOBStorLoc="Projects-V1\\ccase_irva\\cctstgloc\\vobstore\\";
#}
#
#print "$Filername\n";
#print "$NTVOBStorLoc\n";

$Log = `cleartool lsvob`;
&LogIt;
$Log = `cleartool lsview`;
&LogIt;

# Logging information
sub LogIt {
        open(LOGIT,">>$LOGFILE") || die "Can't open log file\n";
        print LOGIT "$Log";
        close(LOGIT);
}
