#!/opt/perl/bin/perl

# This is a test program for me to learn Perl with

printf "\ui \uam what \ui \uam \n";
print "\x33 \x43 \n";
print "x41 is \x41 \n";
print "x42 is \x42 \n";
#print `ls *.*\n`;
print (A..Z);
print \n;
$a=0x45;
print "$a\n";

$scalar="This is stupid and stupidier";
$match = $scalar =~ m/stupid/;

print("\$match = $match\n");

$junk="ABC";
$junk1 = lc($junk);
print "$junk1\n";
