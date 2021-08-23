#!/tools/perl/5.6.0/SunOS/bin/perl

# Script to create Gnats database
# per Broadcom's standard

if ($#ARGV < 0) {
        print "Usage: $0 {database name} {Web Page}\n";
        print "Example: $0 bse-clearcase BSE_ClearCase\n";
        exit (1);
} else {
        $DB_NAME=$ARGV[0];
        $DB_DESC=$ARGV[1];
}

chop($ME=`whoami`);
chop($HOST=`hostname`);

if ( "$ME" ne "gnats" &&  "$HOST" ne "gnats-irva-1" ) {
	print "Please log in as Gnats user on gnats-irva-1 and try again.\n";
	exit(1);
}

$GNATS_ROOT=$ENV{'GNATS_ROOT'};
$GNATSVER=$ENV{'GNATSVER'};
$GNATS_DIR="/tools/GNATS/share/gnats";
$GNATS_TEMPLATE="db-template";
$GNATS_DB="/tools/GNATS/share/gnats/gnats-db";

chdir("$GNATS_DIR");
system("/usr/bin/tar xf ${GNATS_TEMPLATE}.tar");
rename("$GNATS_TEMPLATE","db-${DB_NAME}");
system("cp ${GNATS_DB}/gnats-adm/Makefile db-${DB_NAME}/gnats-adm");
chdir("db-${DB_NAME}/gnats-adm");


# Config file
open(MYFILE, "+< config") or die "Can't read config file: $!\n";
$OUT = '';
while (<MYFILE>) {
	s/gnats-n/gnats-${DB_NAME}/g;
	s/gnats-admin-n/gnats-admin-${DB_NAME}/g;
	s/broadcom-n/broadcom-${DB_NAME}/g;
	s/irvine-n/irvine-${DB_NAME}/g;
	$OUT .= $_;
}
seek(MYFILE, 0, 0)        or die "Can't seek to start of config: $!";
print MYFILE $OUT         or die "Can't print to config $!";
truncate(MYFILE, tell(MYFILE)) or die "Can't truncate config: $!";
close(MYFILE)             or die "Can't close config: $!";

# Categories file
open(MYFILE, "+< categories") or die "Can't read categories file: $!\n";
$OUT = '';
while (<MYFILE>) {
	s/gnats-admin-n/gnats-admin-${DB_NAME}/g;
	$OUT .= $_;
}
seek(MYFILE, 0, 0)        or die "Can't seek to start of categories: $!";
print MYFILE $OUT         or die "Can't print to categories $!";
truncate(MYFILE, tell(MYFILE)) or die "Can't truncate categories: $!";
close(MYFILE)             or die "Can't close categories: $!";

# Submitters file
open(MYFILE, "+< submitters") or die "Can't read submitters file: $!\n";
$OUT = '';
while (<MYFILE>) {
	s/gnats-n/gnats-${DB_NAME}/g;
	s/gnats-admin-n/gnats-admin-${DB_NAME}/g;
	s/broadcom-n/broadcom-${DB_NAME}/g;
	s/irvine-n/irvine-${DB_NAME}/g;
	$OUT .= $_;
}
seek(MYFILE, 0, 0)        or die "Can't seek to start of submitters: $!";
print MYFILE $OUT         or die "Can't print to submitters $!";
truncate(MYFILE, tell(MYFILE)) or die "Can't truncate submitters: $!";
close(MYFILE)             or die "Can't close submitters: $!";

# 
system("/tools/bin/make");
open(MYFILE,">README") or die "Can't open README file: $!\n";
print MYFILE " PLEASE USE THIS FILE AS A TEMPLATE FOR THE SPECIFIED FILE\n";
print MYFILE "###  Crontab ###\n";
print MYFILE "0,10,20,30,40,50 * * * * /tools/GNATS/SunOS/libexec/gnats/queue-pr --run --directory /tools/GNATS/share/gnats/db-${DB_NAME}\n";
print MYFILE "### aliases ####\n";
print MYFILE "gnats-${DB_NAME}:\t\t\"\| /tools/GNATS/SunOS/libexec/gnats/queue-pr -q -d /tools/GNATS/share/gnats/db-${DB_NAME}\"\n";
print MYFILE "gnats-admin-${DB_NAME}:\t\ttdinh\@broadcom.com\n";
print MYFILE "broadcom-${DB_NAME}-gnats:\t\tgnats-${DB_NAME}\n";
print MYFILE "### sendmail.cL ###\n";
print MYFILE "broadcom-${DB_NAME}-gnats\n";
print MYFILE "gnats-admin-${DB_NAME}\n";
print MYFILE "gnats-${DB_NAME}\n";
print MYFILE "### gnats-db.conf ###\n";
print MYFILE "/tools/GNATS/share/gnats/db-${DB_NAME}:${DB_DESC}\n";
print MYFILE "### www/htdocs/index.html ###\n";
print MYFILE "\<li\>\n";
print MYFILE "  \<a href=\"http:\/\/gnatsweb.broadcom.com\/cgi-bin\/gnatsweb.pl\?database=${DB_DESC}\"\>\n";
print MYFILE "  Networking Dev \<\/a\> -  Azra Rashid & Scott McDaniel\n";
print MYFILE "\<\/li\>\n";
print MYFILE "### pophost accounts ###\n";
print MYFILE "gnats-${DB_NAME}\n";
print MYFILE "Description: Email Alias for GNATS ${DB_DESC}\n";
print MYFILE "Forwarding Addess: SMTP \<gnats-${DB_NAME}\@gnatsweb.broadcom.com\>\n";
print MYFILE "gnats-admin-${DB_NAME}\n";
print MYFILE "Description: Email Alias for GNATS ${DB_DESC}\n";
print MYFILE "Forwarding Addess: SMTP \<gnats-admin-${DB_NAME}\@gnatsweb.broadcom.com\>\n";
