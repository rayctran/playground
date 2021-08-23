#!/opt/perl/bin/perl

package System;
	sub new {
		my($class) = shift;
		my(%param) = @_;
		
		bless {

			"HOSTNAME"	=> $params{"HOSTNAME"},
			"OS" 		=> $params{"OS"},
		}, $class;
	}
package main;
	$item = System->new(
#	"HOSTNAME"	=> system("uname -n"),
	"HOSTNAME"	=> jaguar,
	"OS"		=> SUNOS);

	print ("Hostname  is" . %{$item}->{'HOSTNAME'} . "\n");
	print ("OS  is" . %{$item}->{'OS'} . "\n");

