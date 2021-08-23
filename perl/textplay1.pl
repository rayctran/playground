#!/tools/perl/5.6.0/SunOS/bin/perl

use File::Basename;

open(FH,"./p4commit.txt") or die "can't open file $file: $!\n";
while(<FH>) {
    if (/Solution/ ... /^\s*$/) {
        $audit_text .= "$_";
     }
     if (/\[Reviewer(s)*\]/ ... /^\s*$/) {
        $audit_text .= "$_";
     }
     if (/^Affected files .../) { $audit_text .= "$_"; }
     if (/^\.+\s([^@\s]+)\s*(\w*)/) {
        $path_changed = dirname($1);
        for ($path_changed) {
            s/\//\_/g;
            s/^_+//g;
        }
#        print "$1 and $2\n";
        print "before $1 after $path_changed\n";
        $audit_text .="$_";
     }
}
close(FH);
print $audit_text;
