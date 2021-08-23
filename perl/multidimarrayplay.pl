#!/tools/perl/5.6.0/SunOS/bin/perl

$a->[0][0] = 'a00';
$a->[0][1] = 'a01';
$a->[1][0] = 'a10';
$a->[1][1] = 'a11';

use Data::Dumper;

print Dumper($a);

