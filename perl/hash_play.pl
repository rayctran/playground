#!/tools/perl/5.6.0/SunOS/bin/perl

my %originator_lookup = (
           'Jacobus Alberts'  => 'jalberts',
           'Simon Baker'      => 'sbaker',
           'Leo Borromeo'     => 'borromeo',
           'Louis Botha'      => 'lbotha',
           'Hendrik Bruyns'   => 'hbruyns',
           'Johan Conroy'     => 'jconroy',
           'Brian Davis'      => 'davis',
           'Frederic Hayem'   => 'fhayem',
           'Philip Koekemoer' => 'philipk',
           'David Foos'       => 'dfoos',
           'Andrew du Preez'  => 'adupreez',
           'Mark Kent'        => 'mkent',
           'Cyrill Krymmer'   => 'ckrymmer',
           'Uri Landau'       => 'ulandau',
           'Michiel Lotter'   => "mlotter",
           'Ian Riphagen'     => 'iriphagen',
           'Bill Siepert'     => 'bsiepert',
           'Jim Shin'         => 'jshin',
           'Luis Vaz'         => 'lvaz',
);
$look_me_up = 'Andrew du Preez';

print "$originator_lookup{$look_me_up}\n";
