#!/tools/perl/5.6.0/SunOS/bin/perl
#
# Gnats database conversion script
#
#
use Data::Dumper;
use IO::File;
use File::Basename;
use Date::Manip;

$DBPATHNAME = "db-bse-sqa";
$GNATS4 = "/home/raytran/tmp";
$DBNAME = BSE_SQA;
$STRING = "$DBNAME:$DBNAME:${GNATS4}/${DBPATHNAME}\n";
open(DBFILE, "+< ${GNATS4}/databases") or die "Can't update databases file: $!\n";
seek(DBFILE, 0, 2);
syswrite(DBFILE, "$STRING");
close(DBFILE);
