#!/tools/perl/5.6.0/SunOS/bin/perl

use strict;
use IO::File;
use Net::Gnats;
use Date::Manip;
use Mail::Sendmail;
use Data::Dumper;
use File::Basename;

my $env_file = "/home/raytran/bin/perl";
my ($env_v,$env_path,%env);

print basename($env_file);
