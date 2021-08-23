#!/usr/local/bin/perl


#$a = `cat ./qdata.save`;
#print $a;
#$h = Mykaka;
#map { $h{$1} = $2 if (/\s*(\S+)\s*:\s*(.*?)\s*$/) } split("\n", $a);

#while(($key,$value)=each %h) {
#    print "$key\n";
#    print "$value\n";
#
#}

#use Data::Dumper;
#print Dumper(\%h);

$string = "                         14400   IN      MX      10 mail.marketwatch.com.";
$string1 = "                        14400   IN      A       63.240.174.66";
$string2 = "www                     14400   IN      CNAME   game.marketwatch.com.";
$string3 = "email                   14400   IN      A       216.187.77.17";

$string =~ s/^\s+//;

($hostname,$ttl,$in,$record_type,$ip) = split(/\s+/,$string2);
print "my line $hostname,$ttl,$in,$record_type,$ip\n";
($hostname,$ttl,$in,$record_type,$ip) = split(/\s+/,$string);
print "my line $hostname,$ttl,$in,$record_type,$ip\n";

$Host_Name = "email";
$Ttl = "14400";
$Record_Type = "A";
$Ip = "63.240.174.66";

printf "#####%-24s%-8sIN      %-8s%-15s\n", $Host_Name, $Ttl, $Record_Type, $Ip;

$Ttl = "14400";
$Record_Type = "MX";
$Pref_Value = "0";
$Host_Name = "mail.marketwatch.com.";
printf "%29s   IN      %-8s%-1s %-15s\n", $Ttl, $Record_Type, $Pref_Value, $Host_Name;


$Alias_Host = "smtp";
$Ttl = "14400";
$Record_Type = "CNAME";
$Host_Name = "mail";
printf "#########%-24s%-8sIN      %-8s%-15s\n", $Alias_Host, $Ttl, $Record_Type, $Host_Name;

undef $Alias_Host;# $Ttl $Record_Type $Host_Name;
$Line = sprintf("%-24s%-8sIN      %-8s%-15s\n", $Alias_Host, $Ttl, $Record_Type, $Host_Name);
print "my line is $Line";

$testline = "PR=1244,4560,4567,304 state=validate";
$newline = "perlscripts svr_rpt.pl,1.2 sysstats.pl,1.3 textplay.pl,1.2 vobmv.pl,1.5";

($dir,@files)=split(/\s+/,$newline);

print "dir i s$dir\n";

foreach (@files) {
    print "$_\n";   
}

## 

print "NEW TEST START HERE\n";

$textstring .= "new line\n";
$textstring .= "another new line\n";
$textstring .= "kaka for bread\n";
$textstring .= "kaka for bread line 2\n";
$textstring .= "kaka for bread line 3\n";

print $textstring;


