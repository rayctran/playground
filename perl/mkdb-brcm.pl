#!/tools/perl/5.6.0/SunOS/bin/perl

# Script to create Gnats database
# per Broadcom's standard


if ($#ARGV < 0) {
        print "Usage: $0 {database directory name} {database name}\n";
        print "Example: $0 bse-sqa BSE_ClearCase\n";
        exit (1);
} else {
        $DBDIR="db-$ARGV[0]";
	$DBNAME=$ARGV[0];
        $DBDESCRIPTION=$ARGV[1];
}

$GNATSUSER="gnats4";
$GNATSHOST="gnats-irva-3";
$GNATSROOT="/tools/gnats/4.0";
$GNATSEXEC = "${GNATSROOT}/SunOS/libexec/gnats";
$GNATSHARE="${GNATSROOT}/share/gnats";
$GNATSADMTEMPLATE="${GNATSHARE}/db-template/gnats-adm";
$GNATS_ADDR="gnats4-${DBNAME}";
$GNATS_ADMIN_ADDR="gnats4-admin-${DBNAME}";
$CRON="${GNATSROOT}/brcm/crontab";
$ALIAS="${GNATSROOT}/brcm/aliases";
$TODIR="${GNATSHARE}/${DBDIR}";
$NEWADMDIR="${GNATSHARE}/${DBDIR}/gnats-adm";

chop($ME=`whoami`);
chop($HOST=`hostname`);

if ( "$ME" ne "$GNATSUSER" &&  "$HOST" ne "$GNATSHOST" ) {
	print "Please log in as $GNATSUSER user on $GNATSHOST and try again.\n";
	exit(1);
}

# Checking to see if the directory exists
if (-d $TODIR) {
	print "Directory $TODIR exists. Please specify a new database directory name\n";
} 

print "Adding database $DBDESCRIPTION to databases file\n";
open(DBFILE, "+< ${GNATSHARE}/databases") or die "Can't update databases file: $!\n";
seek(DBFILE, 0, 2);
syswrite(DBFILE, "${DBDESCRIPTION}:${DBDESCRIPTION}:${TODIR}\n");
close(DBFILE);

# Creating Database Directory
print "Creating directory $TODIR\n";
system("mkdir -p $NEWADMDIR/locks");
system("chgrp -R gnats $NEWADMDIR");
system("chmod -R g+s $NEWADMDIR");
system("mkdir -p $TODIR/gnats-queue");

opendir(TOPDIR, $GNATSADMTEMPLATE) or die "Can't access $GNATSADMTEMPLATE: $!";
while (defined ($ADMFILE = readdir TOPDIR)) {
        next if $ADMFILE =~ /^\.\.?$/; # skip . and ..
        next if $ADMFILE =~ /^locks$/; # skip locks
        next if $ADMFILE =~ /^RCS$/; # skip RCS
        print "Working on admin file $ADMFILE\n";
        if ( $ADMFILE =~ /^dbconfig$/ ) {
# Copying dbconfig from template
                open(DBCONFIGIN,"${GNATSADMTEMPLATE}/${ADMFILE}") or die "Can't open ${GNATSADMTEMPLATE}/${ADMFILE}: $!\n";
                open(DBCONFIGOUT,"> ${NEWADMDIR}/dbconfig") or die "Can't open ${NEWADMDIR}/dbconfig: $!\n";
                while(<DBCONFIGIN>) {
                        s/\"gnats4-admin\"/\"$GNATS_ADMIN_ADDR\"/;
                        s/\"gnats4\"/\"$GNATS_ADDR\"/;
                        s/DB_NAME/$DBDESCRIPTION/;
                        print DBCONFIGOUT $_;
                }
                close(DBCONFIGIN);
                close(DBCONFIGOUT);

        } elsif ($ADMFILE =~ /^categories|responsible|submitters$/ ) {
                open(ADMIN,"${GNATSADMTEMPLATE}/${ADMFILE}") or die "Can't open ${GNATSADMTEMPLATE}/${ADMFILE}
: $!\n";
                open(ADMOUT,"> ${NEWADMDIR}/${ADMFILE}") or die "Can't open ${NEWADMDIR}/${ADMFILE}:$!\n";
                while(<ADMIN>) {
                        s/for -n/for $DBDESCRIPTION/;
                        s/gnats-admin-n/$GNATS_ADMIN_ADDR/;
		        s/broadcom-n/broadcom-${DBNAME}/g;
		        s/irvine-n/irvine-${DBNAME}/g;
                        print ADMOUT $_;
                }
                close(ADMIN);
                close(ADMOUT);
        } else {
                print "Copying file ${GNATSADMTEMPLATE}/${ADMFILE}\n";
                system("cp ${GNATSADMTEMPLATE}/${ADMFILE} $NEWADMDIR");
        }
}

print "$CRON\n";
open(MYCRON, "+< $CRON") or die "Can't update crontab file: $!\n";
seek(MYCRON, 0, 2);
syswrite(MYCRON, "0,10,20,30,40,50 * * * * /tools/gnats/4.0/SunOS/libexec/gnats/queue-pr --run --database=\'$DBDESCRIPTION\'\n");
close(MYCRON);

# Adding database to aliases

open(MYALIAS, "+< $ALIAS") or die "Can't update aliases file: $!\n";
seek(MYALIAS, 0, 2);
syswrite(MYALIAS, "\n\n\# $DBDESCRIPTION\n${GNATS_ADDR}:\t\t\"\| /tools/gnats/4.0/SunOS/libexec/gnats/queue-pr -q -d ${DBDESCRIPTION}\"\n");
syswrite(MYALIAS, "${GNATS_ADMIN_ADDR}:\t\ttdinh\@broadcom.com\,raytran\@broadcom.com\n");
syswrite(MYALIAS, "broadcom-${DBNAME}-gnats4:\t\t${GNATS_ADDR}\n");
close(MYALIAS);
system("cp ${GNATSADMTEMPLATE}/Makefile ${NEWADMDIR}/Makefile");
system("cd $NEWADMDIR");
system("make index; make cat");


open(TODO,">${NEWADMDIR}/TODO.ADMIN") or die "Can't open file ${NEWADMDIR}/TODO.ADMIN: $!\n";
print TODO " TO DO\n";
print TODO " 1. Update crontab - cd /tools/gnats/4.0/brcm; crontab crontab\n";
print TODO " 2. Copy /tools/gnats/4.0/brcm/aliases to /etc/aliases\n";
print TODO " 3. Run /usr/bin/newaliases \n";
print TODO " 4. Locate sendmail process and kill -HUP on the pid\n";
print TODO " 5. Add the link to the database in /tools/gnats/4.0/www/htdocs/index.html \n";
print TODO "### www/htdocs/index.html ###\n";
print TODO "\<li\>\n";
print TODO "  \<a href=\"http:\/\/gnats-irva-3.broadcom.com\/cgi-bin\/gnatsweb.pl\?database=${DBDESCRIPTION}\"\>\n";
print TODO "  Database Description \<\/a\> -  \<a href=\"mailto:email\@broadcom.com\"\>Name \<\/a\>\n";
print TODO "\<\/li\>\n";
print TODO " 6. Create the following Email accounts in pophost\n";
print TODO "${GNATS_ADDR}\@broadcom.com\n";
print TODO "Description: \-\> Alias for GNATS 4 for ${DBDESCRIPTION}\n";
print TODO "Additional E-mail Addesses:broadcom-${DBNAME}-gnats4\@broadcom.com, broadcom-${GNATS_ADDR}\@broadcom.com\n";
print TODO "Forwarding Addess: SMTP \<${GNATS_ADDR}\@gnats-irva-3.broadcom.com\>\n";
print TODO "${GNATS_ADMIN_ADDR}\@broadcom.com\n";
print TODO "Description:\ -\> Alias for GNATS 4 Admin ${DBDESCRIPTION}\n";
print TODO "Additional E-mail Addesses:broadcom-${GNATS_ADMIN_ADDR}\@broadcom.com\n";
print TODO "Forwarding Addess: SMTP \<${GNATS_ADMIN_ADDR}\@gnats-irva-3.broadcom.com\>\n";
print TODO " 7. Modify /tools/gnats/4.0/www/cgi-bin/gnatsweb.pl. Edit hash \%site_pr_submission_addr
ess and add \n";
print TODO " \'${DBDESCRIPTION}\' \=\> \'${GNATS_ADDR}\@broadcom.com\'\n";
print TODO " 8. Run make index in $NEWADMDIR\n";
close(TODO);
