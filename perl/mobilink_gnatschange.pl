#!/usr/local/bin/perl
# Change state by hacking the problem report so that we don't get any notifications
#
use strict;
use Net::Gnats;
use Data::Dumper;
use Date::Manip;

sub getCategory {
  my $db = shift;
  my @category = $db->listCategories();
  my %CATEGORY;
  foreach my $href (@category) {
#    $CATEGORY->{$href->{name}} = { desc => $href->{desc}, resp => $href->{contact} };
#     print "$href->{name}\n";
    $CATEGORY{"$href->{name}"}{desc} = $href->{desc};
    $CATEGORY{"$href->{name}"}{resp} = $href->{contact};
  }
  return %CATEGORY;
}

sub getResponsible {
  my $db = shift;
  my @responsible = $db->listResponsible();
  my %RESPON;
  foreach my $href (@responsible) {
    $RESPON{"$href->{name}"}{fullname} = "$href->{realname}";
    $RESPON{"$href->{name}"}{email} = $href->{email};
  }
  return %RESPON;
}

sub getDatabases {
  my $db = shift;
  my @databases = $db->listDatabases();
  my %DBS;
  foreach my $href (@databases) {
    $DBS{"$href->{name}"}{path} = "$href->{path}";
    $DBS{"$href->{name}"}{desc} = $href->{desc};
  }
  return %DBS;
}


my $db = Net::Gnats->new("gnatsweb.broadcom.com",1530);
if ( $db->connect() ) {
    print "Connecting...\n";
    $db->login("Mobilink","xqiu","xqiu");
     
} else {
    print "can not connect\n";
    exit;
}

# determine the database directory path for the silent modification
my %databases=getDatabases($db);
my $top_working_dir="$databases{Mobilink}{path}";

my $target_cat="Protocol_Stack-L2_L3";
my $today_date=UnixDate("today","%a\,%f %b %Y %H\:%M\:%S %Z");
my (@found_prs_list,@found_prs);

@found_prs = $db->query("Category~\"$target_cat\*\"", "Number<\"4000\"");
#print Dumper(@found_prs);

my ($pr,%pr_data,$target_pr,$error);

# go to the target directory
chdir("$top_working_dir/$target_cat");

# Logging
my $running_log="";

my $old_audit_trail_detected=0;
foreach $target_pr (@found_prs) {
    $pr_data{new_audit_trail}="";
    unless ($pr = $db->getPRByNumber($target_pr)) {
        print "Can not get information for $target_pr\n";
    } else {

        $pr_data{synopsis} = $pr->getField('Synopsis');
        $pr_data{current_state} = $pr->getField('State');
        $pr_data{old_audit_trail} = $pr->getField('Audit-Trail');
	if ( $pr_data{old_audit_trail} =~ /^\s*$/ ) {
	    $pr_data{new_audit_trail} = ">Audit-Trail:\n";
	    print "no audit trail detected\n";
            $old_audit_trail_detected=0;

	}  else {
	    $pr_data{new_audit_trail} = "$pr_data{old_audit_trail}";
	    print "old audit trail detected\n";
            $old_audit_trail_detected=1;
	}
        $pr_data{new_audit_trail} .= "Synopsis: $pr_data{synopsis}\n";
	$pr_data{new_audit_trail} .= "State-Changed-From-To: $pr_data{current_state}->Closed\n";
	$pr_data{new_audit_trail} .= "State-Changed-By: xqiu\n";
	$pr_data{new_audit_trail} .= "State-Changed-When: $today_date\n";
	$pr_data{new_audit_trail} .= "State-Changed-Why:\n";
	$pr_data{new_audit_trail} .= "Close the old CR. Please open a new one should the same problem occurs with the latest code.\n";
	$pr_data{new_audit_trail} .= "\n";

	if ( $pr_data{current_state} =~ /Closed/ ) {
            print "PR $target_pr current state is already Closed. Skipping...\n";
	} else {
###############################
# changing state the correct way is too noisy due to the notification Emails
###############################
#            if (! $db->replaceField($target_pr,'State',"Closed","Close the old CR. Please open a new one should the same problem occurs with the latest code.")) {
#                   $error = $db->getErrorMessage;
#                   print  "Can not change field State to Closed:",$error,"\n";
#            } else {
#	        print "Changed PR state from $pr_data{current_state} to Closed\n";
#
#	    }
###############################
            print "Changing PR $target_pr\n";
	    print "State change from $pr_data{current_state} to Closed\n";
            open(OLDFILE, "< $target_pr") or die "Can't open $target_pr: $!\n";
	    open(NEWFILE, "> $target_pr.new") or die "Can't open $target_pr.new: $!\n";
	    while (<OLDFILE>) {
	        if ($pr_data{old_audit_trail} != " ") {
	            if (/^>State:/) {
                        print NEWFILE ">State:          Closed\n";
		    } elsif (/^>Audit-Trail:/ ... /^>Unformatted:/) {
                        print NEWFILE "$pr_data{new_audit_trail}";
                        print NEWFILE ">Unformatted:\n";
		    } else {
                        print NEWFILE $_;
                    }

		} else {
	            if (/^>State:/) {
                        print NEWFILE ">State:          Closed\n";
		    } elsif (/^>Unformatted:/) {
                        print NEWFILE "$pr_data{new_audit_trail}";
                        print NEWFILE ">Unformatted:\n";
		    } else {
                        print NEWFILE $_;
		    }
		}

	    }

	    close(OLDFILE);
	    close(NEWFILE);
	    rename($target_pr, "$target_pr.orig");
	    rename("$target_pr.new", $target_pr);

	}

    }

    print "-----------------ENDOFPR-------------------------\n";

}


sub Notify {
    use Mail::Sendmail;
    my($MyFrom,$MySentTo,$MyCcTo,$MySubject,$MyMessage)=@_;
    
    my %mail = (
#            'Content-type' => 'text/html',
            Smtp    => 'smtphost.broadcom.com',
            From    => $MyFrom,
            To      => $MySentTo,
	    Cc      => $MyCcTo,
            subject => $MySubject,
            message => $MyMessage,
    );

    eval { sendmail(%mail) || die $Mail::Sendmail::error; };
    $Mail::Sendmail::log;

    if ($@) {
        print "mail could NOT be sent correctly - $@\n";
    } else {
        print "mail sent correctly\n";
        exit(0);
    }
########
# usage
# Notify("raytran\@broadcom\.com","$notify_list",$cc_list","Testing","$message");
########
}
