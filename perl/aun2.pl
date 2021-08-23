#!/usr/local/bin/perl


#while(<STDIN>) {
#    ($oid, $value) = /([^\s]+)\s+.*"(.*)"$/; 
#    push @oids, $oid;
#    push @values, $value;
#    $maxlen = (length($oid) > $maxlen) ? length($oid) : $maxlen;
#}

#print "$value\n";

#if ($value =~ /63\.240\.26|205\.203\.132/) {
#    print "Match:\n" . $value;
#}

#server_NSSVC_HTTP_63.240.26.103:443(ny-s03-custom-ssl)_UP

#!/usr/bin/perl

# This is a snmptrapd handler script to convert snmp traps into email 
# messages.

# Usage:
# Put a line like the following in your snmptrapd.conf file:
#  traphandle TRAPOID|default /usr/local/bin/traptoemail [-f FROM] [-s SMTPSERVER]b ADDRESSES
#     FROM defaults to "root"
#     SMTPSERVER defaults to "localhost"

use Net::SMTP;
use Getopt::Std; 

$opts{'s'} = "localhost";
$opts{'f'} = 'root@' . `hostname`;
chomp($opts{'f'});
getopts("hs:f:", \%opts);

if ($opts{'h'}) {
    print "
    traptoemail [-s smtpserver] [-f fromaddress] toaddress [...]

      traptoemail shouldn't be called interatively by a user.  It is 
        designed to be called as an snmptrapd extension via a \"traphandle\"
	  directive in the snmptrapd.conf file.  See the snmptrapd.conf file for
	    details.

	      Options:
	          -s smtpserver      Sets the smtpserver for where to send the mail through.
		      -f fromaddress     Sets the email address to be used on the From: line.
		          toaddress          Where you want the email sent to. 

			  ";
			      exit;
			      }

			      die "no recepients to send mail to" if ($#ARGV < 0);

			      # process the trap: 
			      $hostname = <STDIN>;
			      chomp($hostname);
			      $ipaddress = <STDIN>;
			      chomp($ipaddress);

			      $maxlen = 0;
			      while(<STDIN>) {
			          ($oid, $value) = /([^\s]+)\s+.*"(.*)"$/; 
				      push @oids, $oid;
				          push @values, $value;
					      $maxlen = (length($oid) > $maxlen) ? length($oid) : $maxlen;
					      }
					      $maxlen = 60 if ($maxlen > 60);

					      die "illegal trap" if ($#oids < 1);

					      #
					      # run send_mail if 63.240.26 or 205.203.131, ignore everything else.;
					      # the "&" to call the sub-routine is optional
					      #
					      if ( $value =~ /63\.240\.26|205\.203\.131/ ) {
					          &send_mail($value,$hostname,$opt{'f'});
						  }

						  sub send_mail {
						      my ($myvalue,$myhost,$myfrom);
						      #$formatstr = "%" . $maxlen . "s  %s\n";
						          $formatstr = "%s\n"; 
							  # send the message
							      $message = Net::SMTP->new($opts{'s'}) || die "can't talk to server $opts{'s'}\n";
							          $message->mail($opts{'f'}); 
								      $message->to(@ARGV) || die "failed to send to the recepients ",join(",",@ARGV),": $!"; 
								          $message->data();
									      $message->datasend("To: " . join(", ",@ARGV) . "\n");
									          $message->datasend("From: $myfrom\n"); 
										      $message->datasend("Subject: Trap received from $myhost\n");
										          $message->datasend("\n");
											      $message->datasend(sprintf($formatstr, $myvalue));
											          $message->dataend();
												      $message->quit; 
												      }

