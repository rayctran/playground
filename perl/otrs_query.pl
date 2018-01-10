#!/usr/bin/perl  -w
use DBI;
#definition of variables
$db="MYTEST";
$host="localhost";
$user="root";
$password="rootpass";  # the root password

#connect to MySQL database
my $dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host",
                           $user,
                           $password) 
                           or die "Can't connect to database: $DBI::errstr\n";

#disconnect  from database 
$dbh->disconnect or warn "Disconnection error: $DBI::errstr\n";

exit;
