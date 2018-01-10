#!/usr/bin/perl -w
use strict;

use Net::SSH2;

my $ssh2 = Net::SSH2->new();
$ssh2->connect('10.0.1.7') or die $!;
my $auth = $ssh2->auth_publickey(
    'rtran',
    '/home/rtran/.ssh/id_rsa'
);

my $chan2 = $ssh2->channel();
$chan2->blocking(1);

# This is where we send the command and read the response
$chan2->exec("uname -a\n");
print "$_" while <$chan2>;

$chan2->close;
