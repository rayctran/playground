#!/usr/local/bin/perl

#!/usr/bin/perl -w

@hotels=("Bellagio","Venetian","Mandalay Bay","Ceasars","MGM Grand","Orleans","New York-New York","Luxor","Rio","Paris","Treasure Island");
$num=$#hotels+1;

$n=1;
foreach $num(@hotels)
{
    if ($num=~/Ceasars/i)
    {
        print $num." is my favourite";
    }else{
        print $n." ".$num;}
    print "\n";
    $n++;
}
