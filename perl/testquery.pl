#!/tools/perl/5.6.0/SunOS/bin/perl


chop($MYMONTH=`date '+ %m_%Y'`);
$GNATSROOT="/tools/gnats/v4";
$GNATSEXEC="/tools/gnats/v4/SunOS/bin";
$QUERYPR="${GNATSEXEC}/query-pr";
$HOST="gnatsweb.broadcom.com";
$PORT=1531;

#$GNATSROOT="/tools/gnats/4.0";
#$GNATSEXEC="/tools/gnats/4.0/SunOS/bin";
#$QUERYPR="${GNATSEXEC}/query-pr";
#$HOST="gnatsweb.broadcom.com";
#$PORT=1530;

#$RPTFILE="${GNATSROOT}/brcm/reports/${MYMONTH}.log";


open(DBFILE, "${GNATSROOT}/share/gnats/databases") or die "Can't open file ${GNATSROOT}/share/gnats/databases: $!\n";
while (<DBFILE>) {
        next if /^#/;
        ($FROMDIR,$MYDBNAME) = split(/:/);
	push(@DB, $MYDBNAME);
}

foreach $MYDB (@DB) {
	print "Working on database $MYDB\n";
	open(OUT," $QUERYPR -H $HOST --port $PORT -d \"$MYDB\" -v gnats4 -w emsggn09 --arrived-after \"11/16/2003\" --arrived-before \"11/18/2003\" |") or die "Couldn't run query: $!\n";
	while (<OUT>) {
		if (/>Number/) {
			print $_;
		}
	}
}
