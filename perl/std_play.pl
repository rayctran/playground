#!/tools/perl/5.8.0/SunOS/bin/perl

@a = <STDIN>;
$line = 0;

foreach (@a) {
    $line++;
    print "line number $line\n";
    print $_;
}
