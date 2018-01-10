#!/usr/bin/perl -w
use Data::Dumper;


$cfg_file = "/home/rtran/bin/mysql_repl_check.cfg";

open(CFG,"$cfg_file") or die "Can't read config file $cfg_file:$!. Please try again\n";
while (<CFG>) {
    chomp;
    s/#.*//;                # no comments
    s/^\s+//;               # no leading white
    s/\s+$//;               # no trailing white
    next unless length;     # anything left?
    my ($var, $value) = split(/\s*=\s*/, $_, 2);
    $Config_Setting{$var} = $value;
}

print Dumper \%Config_Setting;
print "$Config_Setting{hostip}\n"



