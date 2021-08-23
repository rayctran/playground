#!/tools/perl/5.6.0/SunOS/bin/perl

($NAME,$PASS,$GID,$MEML) = getgrnam(clearusers);
@MEML = split(" ",$MEML);
foreach $X (@MEML) {
	 ($NAME,$PASS,$UID,$GID,$GCOS,$HOME,$SHELL) = getpwnam($X);
	 print "$NAME  = $PASS\n";

}

