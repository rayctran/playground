#!/usr/bin/perl -w

use Date::Parse;
use Data::Dumper;

my $string = "bind *:443 ssl crt /etc/ssl/certs/www.johnnie-o.com.selfsigned.combined.crt crt /etc/ssl/certs/wc.lcgosc.com.combined.crt";

@cert_path = $string =~ /\scrt\s(\S+)/g ;

print "@cert_path\n";

