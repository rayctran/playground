#!/tools/perl/5.6.0/SunOS/bin/perl

# Script to create Gnats database
# per Broadcom's standard

if ($#ARGV < 0) {
        print "Usage: $0 {database name}\n";
        print "Example: $0 bse-clearcase\n";
        exit (1);
} else {
        $DB_NAME=$ARGV[0];
}

$ME=`whoami`;
$HOST=`hostname`;

open(MYFILE,">README") or die "Can't open README file: $!\n";
print MYFILE "# Crontab\n";
print MYFILE "0,10,20,30,40,50 * * * * /tools/GNATS/SunOS/libexec/gnats/queue-pr --run --directory /tools/GNATS/share/gnats/db-${DB_NAME}\n";
print MYFILE "# aliases\n";
print MYFILE "gnats-${DB_NAME}:\t\t\"\| /tools/GNATS/SunOS/libexec/gnats/queue-pr -q -d /tools/GNATS/share/gnats/db-${DB_NAME}\"\n";
print MYFILE "gnats-admin-${DB_NAME}:\t\ttdinh\@broadcom.com\n";
print MYFILE "broadcom-${DB_NAME}-gnats:\t\tgnats-${DB_NAME}\n";
print MYFILE "#sendmail.cL\n";
print MYFILE "broadcom-${DB_NAME}-gnats\n";
print MYFILE "gnats-admin-${DB_NAME}\n";
print MYFILE "gnats-${DB_NAME}\n";

