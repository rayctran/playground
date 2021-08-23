#!/usr/local/bin/perl
#
#
#  Created on: January 14, 2000
#  Modified on: January 25, 2000
#  By: Wavyne Miller.
#  Description: This script will append the user's location in the gcos
#  field after the user's fullname.  
# 
#########################################################################

#  Constants
my $alias = "/home/admin/wmiller/temp/sydney.mine";
my $passwd = "/home/admin/wmiller/temp/passwd.mine";
my $newfile = "./newpasswd.temp";

$LOC="Australia";

#  Open files for reading and writing.
open (ALIAS, "$alias") || die "can't open file $alias";
open (PASSWD, "$passwd") || die "can't open file $passwd";
open (NEWPASSWD, ">$newfile") || die "can't write to $newfile";

while ($passwd_entry = <PASSWD>) {
    @currentElem=split(/:/,$passwd_entry);
    while ($user  = <ALIAS>){
    	chomp($user);   # taking off the newline
        if ($currentElem[0] =~ /$user/) {
            if (($currentElem[4] =~ /$LOC/) || ($currentElem[4] =~ /auxacct/)) {
                # DO NOTHING
            }else {   #inner if
            	#Append location in the gcos field
                $currentElem[4]="$currentElem[4], $LOC";
                $passwd_entry=join(':', @currentElem);
            }  #else
    	}  #outter if
    } #inner while
    seek(ALIAS,0,0);
    print NEWPASSWD $passwd_entry;
}  #outter while

# Close files
close (ALIAS);
close (PASSWD);
