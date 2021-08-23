#!/usr/local/bin/perl

use Tk;

my $wm = MainWindow->new;
$wm->title( "Hello World" );
$wm->Button(-text => "Exit", -command => sub { exit }) ->pack;
MainLoop;
