#!/tools/rational/brcm/perl/bin/perl

use Mail::Sendmail;

# Check ClearCase license and feed the information to mrtg
# 
# input require 
# -s server name
# -p product name
# -d denied report

$Denied=0;
$LicRpt="/tmp/lic.rpt";

if ( $#ARGV < 0 ) {
    $Prompt=0;
    print "No arguments to pass\n";
    exit;
} else {
    %Arg=@ARGV;
    while(($key,$value)=each %Arg) {
#        print "current key is $key, value is $value\n";
        if ($key =~ /-s/) {
            $Server = $value;
        }
        if ($key =~ /-p/) {
            $Product = $value;
        }
        if ($key =~ /-d/) {
            $Denied = 1;
        }
    }   
}
#       print "Server is $Server\n";
#       print "Product is $Product\n";
chop ($ThisHost=`hostname`);
open(PING,"/usr/sbin/ping $Server |") or die "Couldn't ping server\n";
while(<PING>) {
    if (/^no/) {
        &Notify("raytran\@broadcom.com","CC_MONITOR_WARNING - No response from $Server.\n","Warning,$Server did not response to the ping process from the monitor server $ThisHost.\n\n\n");
        exit (1);
    }
}

open(CL,"rsh $Server /opt/rational/clearcase/bin/clearlicense -product $Product|")|| die "Can not execute command\n";
open(TMP,"> $LicRpt") || die "Can not open temp file\n";
while(<CL>) {
    print TMP $_;
    if (/Maximum/) {
        while ( /(\d+)/gc ) {
            $Max=$1;  
        }
    }
    if (/Current/) {
        while ( /(\d+)/gc ){
            $Used=$1;  
        }
    }
    if (/denied/) {
        while ( /(\d+)/gc ){
            $Reject=$1;  
        }
    }
    if (/bumped/) {
        while ( /(\d+)/gc ){
            $Bumped=$1;  
        }
    }
}
if ( $Denied == 0 ) {
    print STDOUT "$Max\n$Used\n";
} 
if ( $Denied == 1 ) {
    print STDOUT "$Reject\n$Bumped\n";
}
close(CL);
close(TMP);
print "$Used\n";
print "$Max\n";
if ( "$Max" != "" || "$Max" != "0" ) {
    $Message="Warning, the maximum number of licenses for $Product on $Server have been acquired\n";
    open(LIC,"< $LicRpt") || die "Can not open license log file\n";
    while(<LIC>) {
        $Message = join "",$Message,$_;
    }
    close(LIC);
    if ( "$Used" == "$Max") {
        &Notify("clearcase-admins-list\@broadcom.com","CC_MONITOR_WARNING: Warning, the maximum number of licenses for $Product on $Server have been acquired\n","$Message");
    }
}

# Release license
system("rsh $Server /opt/rational/clearcase/bin/clearlicense -release vobadm");
system("rm $LicRpt");

sub Notify {
    my($MySentTo,$MySubject,$MyMessage)=@_;
    %mail = (
            smtp    => 'smtphost.broadcom.com',
            to      => $MySentTo,
            from    => 'ccmonitor@broadcom.com',
            subject => $MySubject,
            message => $MyMessage,
    );

    eval { sendmail(%mail) || die $Mail::Sendmail::error; };
    $Mail::Sendmail::log;

    if ($@) {
            print "mail could NOT be sent correctly - $@\n";
            exit(1);
    } else {
            print "mail sent correctly\n";
            exit(0);
    }
}
