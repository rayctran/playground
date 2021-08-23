#! /usr/local/bin/perl

$Server="ccase-irva-2";
$LogDir="/home/raytran/kaka";
$CT="/opt/rational/clearcase/bin/cleartool";
# Gather ClearCase Logs from the server

$vob="${LogDir}/vob.log";
$view="${LogDir}/view.log";
$shipping="${LogDir}/shipping.log";
$vobrpc="${LogDir}/vobrpc.log";
$vob_scrubber="${LogDir}/vob_scrubber.log";
$vobsnap="${LogDir}/vobsnap.log";
$scrubber="${LogDir}/scrubber.log";
$mvfs="${LogDir}/mvfs.log";
$lockmgr="${LogDir}/lockmgr.log";
$export_mvfs="${LogDir}/export_mvfs.log";
$db="${LogDir}/db.log";
$aldb="${LogDir}/aldb.log";
$admin="${LogDir}/admin.log";
@Logs = ("vob", "view", "shipping", "vobrpc", "vob_scrubber", "vobsnap", "scrubber", "mvfs", "lockmgr", "export_mvfs", "db", "albd", "admin");

foreach $Elem (@Logs) {
   print $Elem, "\n"; 
   open(LOG, ">${LogDir}/${Elem}.log") || die "Can't open log file ${LogDir}/${Elem}.log\n";
   if ( "$Elem" =~ /vob_scubber|scrubber|lockmgr|export_mvfs/ ) {
       open(GETLOG, "rsh $Server $CT getlog $Elem |");
   } else {
       print "since yesterday\n";
       open(GETLOG, "rsh $Server $CT getlog -since yesterday $Elem |");
   }
   while (<GETLOG>) {
       if ( $_ =~ /^=|^Log Name|^Selection|^-/ ) {
           print $_;
           next;
       } else {
           print LOG $_;
       }

   }
   close GETLOG;
   close LOG; 
}
