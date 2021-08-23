#!/home/raytran/local/perl/bin/perl

use IO::File;

#$fs = IO::File->new_tmpfile;
$new = IO::File->("> /tmp/kaka");

#print $fs "This is a temp file\n";
print $new "This is a temp file\n";

