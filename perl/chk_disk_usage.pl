#! /tools/perl/5.6.0/SunOS/bin/perl

use strict;
use Data::Dumper;

my ($prompt,$dir,$log_dir,$notify);

if ( $#ARGV < 0 ) {
    $prompt=0;
    print "Usage: $0 directory\n";
    exit (1);
} else {
        $dir=$ARGV[0];
}

$notify=0;
$log_dir="/projects/viewstoreQA/QAprocess/FilerSpace";

sub main {
    my ($pid, %df, %date);
    ($date{sec},$date{min},$date{hour},$date{mday},$date{month},$date{year},$date{wday},$date{yday},$date{isdst}) = localtime();
    $date{month} = $date{month} + 1;
    $date{year} = 1900 + $date{year};

    chdir $dir; # invoke the automounter
    $pid = open(DF, "df -k $dir |") or die "Couldn't run df: $!\n";
    while (<DF>) {
        next if /^Filesystem/;
        ($df{source},$df{total},$df{used},$df{avail},$df{cap},$df{mounted})=split(' ',$_);
    }
    close(DF);

    $df{total} = sprintf("%d",$df{total} / 1024);
    $df{used} = sprintf("%d",$df{used} / 1024);
    print "$df{total}\n";
    print "$df{used}\n";

    open(LOG,"${log_dir}/$date{year}/$date{month}");
    print LOG "$date{mday},$dir,$df{total},$df{used}\n";
    close(LOG);
}

sub Notify {
    use Mail::Sendmail;
    my($MySentTo,$MySubject,$MyMessage)=@_;
    my %mail = (
            smtp    => 'smtphost.broadcom.com',
            to      => $MySentTo,
            from    => 'raytran@broadcom.com',
            subject => $MySubject,
            message => $MyMessage,
    );

    eval { sendmail(%mail) || die $Mail::Sendmail::error; };
    $Mail::Sendmail::log;

    if ($@) {
            print "mail could NOT be sent correctly - $@\n";
    } else {
            print "mail sent correctly\n";
    }
}
