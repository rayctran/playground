#!/tools/perl/5.6.0/SunOS/bin/perl
#
# Read survey results, create report web page and cvs file.
#
#

use Data::Dumper;
use IO::File;
use GD;
use GD::Text;
use Date::Manip;
use Mail::Sendmail;
#use GD::Graph::Map;

$RPT_DIR="/home/vobadm/public_html/tmp/survey";
$WEB_HOME="http://intranet.broadcom.com/\~vobadm";
$HTML_FILE="${RPT_DIR}/${MYYEAR}_${MYMONTH}.html";
$LINK="$WEB_HOME/reports/monthly/${MYYEAR}_${MYMONTH}.html";

opendir(TOPDIR, $RPT_DIR) or die "Can't access $RPT_DIR: $!";
while (defined ($MYFILE = readdir TOPDIR)) {
	next if $MYFILE =~ /^\.\.?$/;     # skip . and ..
	next if $MYFILE =~ /^comments$/; # skip the comments file
	next if $MYFILE =~ /^ips$/; # skip the ips file
	open(FH, "< ${RPT_DIR}/${MYFILE}") or die "Can't open file ${RPT_DIR}/${MYFILE}: $!";
	print "${RPT_DIR}/${MYFILE}\n";
	while (<FH>) {
		chomp;
		s/^\s+//;               # no leading white
    		s/\s+$//;               # no trailing white
		next if /^Survey*/;
		next if /^Additional_Comments*/;
		next if /^Submit_Survey*/;
		next if /^=*/;
    		next unless length;     # anything left?
    		my ($VAR, $VALUE) = split(/\s*=\s*/, $_, 2);
		if (defined @QLIST) {
			@FOUND = grep /$VAR/, @QLIST;
			$CF = @FOUND;
			if ( $CF == 0 ) {
				push(@QLIST, $VAR);
				undef @FOUND;
				undef $CF;	
			}
				
		} else {
			push(@QLIST, $VAR);
		}
		if ( $VAR =~ /Use_ClearCase/ ) {
			$UCC->{TOTAL}++;
			if ( $VALUE =~ /Yes/ ) {
				$UCC->{Y}++;
			} elsif ( $VALUE =~ /No/ ) {
				$UCC->{N}++;
			}
		}	
		if ( $VAR =~ /Satisfied_ClearCase/ ) {
			$SCC->{TOTAL}++;
			if ( $VALUE =~ /Yes/ ) {
				$SCC->{Y}++;
			} elsif ( $VALUE =~ /No/ ) {
				$SCC->{N}++;
			} elsif ( $VALUE =~ /NA/ ) {
				$SCC->{NA}++;
			}
		}	
		if ( $VAR =~ /Use_CVS/ ) {
			$UCVS->{TOTAL}++;
			if ( $VALUE =~ /Yes/ ) {
				$UCVS->{Y}++;
			} elsif ( $VALUE =~ /No/ ) {
				$UCVS->{N}++;
			}
		}	
		if ( $VAR =~ /Use_SourceSafe/ ) {
			$USS->{TOTAL}++;
			if ( $VALUE =~ /Yes/ ) {
				$USS->{Y}++;
			} elsif ( $VALUE =~ /No/ ) {
				$USS->{N}++;
			}
		}	
		if ( $VAR =~ /Use_Other/ ) {
			$UO->{TOTAL}++;
			if ( $VALUE =~ /Yes/ ) {
				$UO->{Y}++;
			} elsif ( $VALUE =~ /No/ ) {
				$UO->{N}++;
			}
		}	
		if ( $VAR =~ /Training_Complicated/ ) {
			$TC->{TOTAL}++;
			if ( $VALUE =~ /Yes/ ) {
				$TC->{Y}++;
			} elsif ( $VALUE =~ /No/ ) {
				$TC->{N}++;
			}
		}	
		if ( $VAR =~ /Training_General/ ) {
			$TG->{TOTAL}++;
			if ( $VALUE =~ /Yes/ ) {
				$TG->{Y}++;
			} elsif ( $VALUE =~ /No/ ) {
				$TG->{N}++;
			}
		}	
		if ( $VAR =~ /More_Basic_Training/ ) {
			$MBT->{TOTAL}++;
			if ( $VALUE =~ /Yes/ ) {
				$MBT->{Y}++;
			} elsif ( $VALUE =~ /No/ ) {
				$MBT->{N}++;
			}
		}	
		if ( $VAR =~ /More_UCM_Training/ ) {
			$MUT->{TOTAL}++;
			if ( $VALUE =~ /Yes/ ) {
				$MUT->{Y}++;
			} elsif ( $VALUE =~ /No/ ) {
				$MUT->{N}++;
			}
		}	
		if ( $VAR =~ /More_BSE_Training/ ) {
			$MBSET->{TOTAL}++;
			if ( $VALUE =~ /Yes/ ) {
				$MBSET->{Y}++;
			} elsif ( $VALUE =~ /No/ ) {
				$MBSET->{N}++;
			}
		}	
		if ( $VAR =~ /FAQ/ ) {
			$FAQ->{TOTAL}++;
			if ( $VALUE =~ /Yes/ ) {
				$FAQ->{Y}++;
			} elsif ( $VALUE =~ /No/ ) {
				$FAQ->{N}++;
			}
		}	
		if ( $VAR =~ /GNATs/ ) {
			$GN->{TOTAL}++;
			if ( $VALUE =~ /Yes/ ) {
				$GN->{Y}++;
			} elsif ( $VALUE =~ /No/ ) {
				$GN->{N}++;
			}
		}	
		if ( $VAR =~ /User_Documentation/ ) {
			$UD->{TOTAL}++;
			if ( $VALUE =~ /Yes/ ) {
				$UD->{Y}++;
			} elsif ( $VALUE =~ /No/ ) {
				$UD->{N}++;
			}
		}	
		if ( $VAR =~ /Webboard/ ) {
			$WB->{TOTAL}++;
			if ( $VALUE =~ /Yes/ ) {
				$WB->{Y}++;
			} elsif ( $VALUE =~ /No/ ) {
				$WB->{N}++;
			}
		}	

	}
	close(FH);
}
closedir(TOPDIR);
print Dumper(\$UCC);
