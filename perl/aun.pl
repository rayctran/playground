#!/usr/local/bin/perl

########################################################################
# 
# File   :  aun.pl
# History:  24-jun-2002 aun 
#
########################################################################
#
# Aun this local will only work with Perl version 5.004 and above
# to check run perl --ver
# 
# 
########################################################################
# 
use IO::File;
#use locale;
use Data::Dumper;

# Uncomment out 
#use Rcs;

my $DEBUG=0;

my $Forward_Zone_Directory="/chroot/named/conf/addr";
my $Reverse_Zone_Directory="/chroot/named/conf/rev";

my $Saved_Changes=0;
my $Do_Reverse=0;
#my $Select_Zone_File_From_Disk = 0;

# The next three scalar is used for RCS 
# Turn this off if you don't want to use RCS
my $Apply_RCS=1;
my $Me=`whoami`;
my $Date_String=`date '+%m-%d-%Y:%H:%M:%S'`;


if ($DEBUG) {
    my $Forward_Zone_Directory="/chroot/named/conf/addr";
    my $Reverse_Zone_Directory="/chroot/named/conf/rev";
    my $Apply_RCS=0;
}

sub main {
    if ( defined($Zone_File) ) {
        print "Current zone file is $Zone_File. Do you want to select a new file to modify? (y)es/(n)o\n";
        print "Note: if you choose yes, you're current changes will be written out to the file\n";
        chomp($get_new_zone_file = lc(<>));
        if ( "$get_new_zone_file" eq "y" ) {
	    if ( $Saved_Changes == 0 ) {
	        print "Changes have not been saved. Saving changes.\n";
                &apply_changes;
	    }
            &load_zone_file;
        } elsif ( "$get_new_zone_file" eq "n" ) {
            print "Using zone file $Zone_File\n";
        }

    } else {
        &load_zone_file;
    }
# check to see if we already set Action and give the user a change to change it
    if ( defined($Action) ) {
        print "Current action is set to $Action. Do you want to (c)ontinue or (s)elect another action\n";
        chomp($do_something_else = lc(<>));
        if ( $do_something_else !~ /c|s/ ) {
            print "Invalid input $do_something_else. Please try again\n";
            &main;
        } elsif ( "$do_something_else" eq "s" ) {
           &get_action; 
        }
    } else {
        &get_action;
    }

# Add section
    if ( "$Action" eq "a" ) {
        &get_info;
        push(@Zone_File_Contents,"$Line");
        if ( $Record_Type eq A ) {
            &load_reverse_file($Ip);
        }
    }	

# Change section
    if ( "$Action" eq "c" ) {
        &get_info;
        undef @TempArray;
        foreach $zone_line (@Zone_File_Contents) {
            if ( $zone_line =~ /$Find_Record_Result$/ ) {
                $zone_line = $Line;
            }
            push(@TempArray,$zone_line);
        }
        undef @Zone_File_Contents;
        @Zone_File_Contents = @TempArray;
    }	

# Delete section
    if ( "$Action" eq "d" ) {
        &get_info;
        undef @TempArray;
        foreach $zone_line (@Zone_File_Contents) {
            if ( $zone_line =~ /$Find_Record_Result$/ ) {
                next;
            } else {
                push(@TempArray,$zone_line);
            }
        }
        undef @Zone_File_Contents;
        @Zone_File_Contents = @TempArray;
    }	

# Loop through again. Anything other than m will save the changes then exit;
    print "Please select an option - (m)odify another record/(s)ave changes to file\n";
    chomp($new_action = lc(<>));
    if ( "$new_action" eq "m" ) {
        &main; 
    } else {
        &apply_changes;    
        exit 0;
    }
}

# Prompt for Information and confirm before continue
# We want to "play nice" so we will allow the user to re-enter the 
# information if they screwed up, we check to 
# see if the value is set, if it's not then prompt for it.
# Then we verify the value, if it's not correct then we unset 
# the value and loop back through the subroutine. The subroutine
# then bypass any value that we've accepted as valid and continue
# to the bad input. 
sub get_info {
    if ( "$Action" eq "a" ) {
	if ( !defined($Record_Type) ) {
            print "Please enter Type of Record you want to add (A/MX/CNAME)?\n";
            chomp($Record_Type = uc(<>));
        }
        if ( $Record_Type eq "A" ) {
            if ( !defined($Host_Name) ) {
                print "Please enter Host name:\n";
                chomp($Host_Name = lc(<>));
            }
            if ( !defined($Ttl) ) {
                print "Please enter the TTL value: 86400 or 14400\n";
                chomp($Ttl = <>);
                if ( $Ttl !~ /86400|14400/ ) {
                    print "Invalid TTL value. Please try again\n";
                    undef $Ttl;
                    &get_info;
                }
            }
            if ( !defined($Ip) ) {
                print "Enter IP Address:\n";
                chomp($Ip = <>);
                $cipresult = &check_ip($Ip);
                if ( $cipresult == 0 ) {
                     print "Invalid IP address $IP, please try again\n";
                     undef $Ip;
                     &get_info;
                }
            }
           
        } elsif ( $Record_Type =~ /MX/ ) {
            if ( !defined($Ttl) ) {
                print "Please enter the TTL value: 86400 or 14400\n";
                chomp($Ttl = <>);
            }
            if ( $Ttl !~ /86400|14400/ ) {
                print "Invalid TTL value. Please try again\n";
                undef $Ttl;
                &get_info;
            }
            print "Please enter the preference value: 0-65535\n";
            chomp($Pref_Value = <>);
            if ( $Ttl !~ /[0-65535]/ ) {
                print "Invalid preference value. Please try again\n";
                undef($Pref_Value);
                &get_info;
            }
            print "Please enter the Mail Exchanger name:\n";
            chomp($Host_Name = lc(<>));
        } elsif ( $Record_Type =~ /CNAME/ ) {
            if ( !defined($Alias_Host) ) {
                print "Please enter the alias host name:\n";
                chomp($Alias_Host = lc(<>));
            }
            if ( !defined($Ttl) ) {
                print "Please enter the TTL value: 86400 or 14400\n";
                chomp($Ttl = <>);
            }
            if ( $Ttl !~ /86400|14400/ ) {
                print "Invalid TTL value. Please try again\n";
                undef $Ttl ;
                &get_info;
            }
            if ( !defined($Source_Host) ) {
                print "Please enter the source host name:\n";
                chomp($Host_Name = lc(<>));
            }
        } else {
            print "Invalid record type $Record_Type. Please try again\n";
            undef $Record_Type;
            &get_info;
        }
        print "Please confirm the following information:\n";
        print "Adding the following line to zone file $Zone_File\n";
        if ( "$Record_Type" eq "A" ) {
            sprintf "%-24s%-8sIN      %-8s%-15s\n", $Host_Name, $Ttl, $Record_Type, $Ip;
            $Line =  sprintf "%-24s%-8sIN      %-8s%-15s\n", $Host_Name, $Ttl, $Record_Type, $Ip;
        } elsif ( "$Record_Type" eq "MX" ) {
            sprintf "%29s   IN      %-8s%-1s %-15s\n", $Ttl, $Record_Type, $Pref_Value, $Host_Name;
            $Line = sprintf "%29s   IN      %-8s%-1s %-15s\n", $Ttl, $Record_Type, $Pref_Value, $Host_Name;
        } elsif ( "$Record_Type" eq "CNAME" ) {
            sprintf "%-24s%-8sIN      %-8s%-15s\n", $Alias_Host, $Ttl, $Record_Type, $Host_Name;
            $Line = sprintf "%-24s%-8sIN      %-8s%-15s\n", $Alias_Host, $Ttl, $Record_Type, $Host_Name;
        }
        print "Do you want to (r)e-enter the info, (c)ontinue to add the info to the zone file\n";
        chomp($info_confirm = lc(<>));
        if ( $info_confirm !~ /c|r/ ) {
            print "Invalid response. Please try again\n";
            &get_info;
        }
# if the user wants to re-define the data. We unset all the values fo sub get_info will re-prompt
        if ( "$info_confirm" eq "r" ) {
            if ( "$Record_Type" eq "A" ) {
                undef $Record_Type;
                undef $Host_Name;
                undef $Ttl;
                undef $Ip;
            }
            if ( "$Record_Type" eq "MX" ) {
                undef $Record_Type;
                undef $Host_Name;
                undef $Ttl;
                undef $Ip;
            }
            if ( "$Record_Type" eq "CNAME" ) {
                undef $Record_Type;
                undef $Alias_Host;
                undef $Ttl;
                undef $Host_Name;
            }
            &get_info;
        } 
    }

# Delete Section
    if ( "$Action" eq "d" ) {
        if ( !defined($Record_Type) ) {
            print "Please enter the record type that you would like to delete? (A/MX/CNAME)\n";
            chomp($Record_Type = uc(<>));
        }
        if ( $Record_Type !~ /A|MX|CNAME/ ) {
            print "Invalid record type $Record_Type. Please try again\n";
            undef $Record_Type;
            &get_info;
        }
        if ( !defined($Delete_Host) ) {
            print "Please enter in the hostname or IP that you would like to delete\n";
            chomp($Delete_Host = (<>));
        }
        if ( !defined($Find_Record_Result) ) {
            $Find_Record_Result = &find_record($Record_Type,$Change_Host);
            if ( $Find_Record_Result == 0 ) {
                print "Can not located record $Delete_Host in current zone file $Zone_File\n";
                print "Would you like to? (e)xit or (r)etry\n";
                chomp($next_action = lc(<>));
                if ( "$next_action" eq "e" ) {
                    exit;
                } elsif ( "$next_action" eq "r" ) {
                    undef $Find_Record_Result;
                    undef $Record_type;
                    undef $Delete_Host;
                    &get_info;
                }
            } 
        }
        print "Record located. Current record is $Find_Record_Result\n";
        print "Do you want to continue with the modification? (r)eselect, (c)ontinue\n";
        chomp($info_confirm = lc(<>));
        if ( $info_confirm !~ /c|r/ ) {
            print "Invalid response. Please try again.\n";
            undef $Record_Type;
            undef $Delete_Host;
            undef $find_record_sesult;
            &get_info;
        }
        if ( "$info_confirm" eq "r" ) {
            undef $Record_Type;
            undef $Delete_Host;
            undef $find_record_sesult;
            &get_info;
        }
    }

    if ( "$Action" eq "c" ) {
        if ( !defined($Record_Type) ) {
            print "Please enter the record type that you would like to change? (A/MX/CNAME)\n";
            chomp($Record_Type = uc(<>));
        }
        if ( !defined($Change_Host) ) {
            print "Please enter in the hostname that you would like to change\n";
            chomp($Change_Host = (<>));
        }
        if ( !defined($Find_Record_Result) ) {
            $Find_Record_Result = &find_record($Record_Type,$Change_Host);
            if ( $Find_Record_Result == 0 ) {
                print "Can not located record $Change_Host in current zone file $Zone_File\n";
                print "Would you like to? (e)xit or (r)etry\n";
                chomp($next_action = lc(<>));
                if ( "$next_action" eq "e" ) {
                    exit;
                } elsif ( "$next_action" eq "r" ) {
                    undef $Find_Record_Result;
                    undef $Record_type;
                    undef $Change_Host;
                    &get_info;
                }
            }
            print "Record located. Current record is $Find_Record_Result\n";
            print "Do you want to continue with the modification? (r)eselect, (c)ontinue\n";
            chomp($info_confirm = lc(<>));
            if ( $info_confirm !~ /c|r/ ) {
                print "Invalid response. Please try again\n";
                undef $Record_Type;
                undef $Change_Host;
                undef $find_record_result;
                &get_info;
            }
            if ( "$info_confirm" eq "r" ) {
                undef $Record_Type;
                undef $Change_Host;
                undef $find_record_result;
                &get_info;
            }
        }

        if ( "$Record_Type" eq "A" ) {
            ($hostname,$ttl,$in,$record_type,$ip) = split(/\s+/,$Find_Record_Result);
            print "Working on hostname $hostname.\n";
            if ( !defined($change_ttl) ) {
                print "The current TTL is $ttl. Would you like to keep this or change it? (k)eep, (c)hange.\n";
                chomp($change_ttl = lc(<>));
                if ( "$change_ttl" eq "k" ) {
                    $Ttl = $ttl;
                } elsif ( "$change_ttl" eq "c" ) {
                    print "Please enter in the new TTL value: 86400 or 14400\n";
                    chomp($Ttl = (<>));
                    if ( $Ttl !~ /86400|14400/ ) {
                        print "Invalid TTL value. Please try again\n";
                        undef $change_ttl ;
                        &get_info;
                    }
                } else {
                    print "Invalid response. Please try again\n";
                    undef $change_ttl;
                    &get_info;
                }
            } 
            if ( !defined($change_ip) ) {
                print "The current IP address is $ip. Would you like to keep this or change it? (k)eep, (c)hange.\n";
                chomp($change_ip = (<>));
                if ( "$change_ip" eq "k" ) {
                    $Ip = $ip;
                } elsif ( "$change_ip" eq "c" ) {
                    print "Please enter in the new IP address for this entry\n";
                    chomp($Ip = (<>));
                } else {
                    print "Invalid response. Please try again\n";
                    undef $change_ip;
                    &get_info;
                }
            }            
        } elsif ( "$Record_Type" eq "CNAME" ) {
            ($alias,$ttl,$in,$record_type,$hostname) = split(/\s+/,$Find_Record_Result);
            if ( !defined($change_alias) ) {
                print "The current alias is $alias. Would you like to keep this or change it? (k)eep, (c)hange.\n";
                chomp($change_alias = lc(<>));
                if ( "$change_alias" eq "k" ) {
                    $Host_Name = $alias;
                } elsif ( "$change_host" eq "c" ) {
                    print "Please enter in the new hostname\n";
                    chomp($Host_Name = (<>));
                } else {
                    print "Invalid response. Please try again\n";
                    undef $change_host;
                    &get_info;
                }
            } 
            if ( !defined($change_ttl) ) {
                print "The current TTL is $ttl. Would you like to keep this or change it? (k)eep, (c)hange.\n";
                chomp($change_ttl = lc(<>));
                if ( "$change_ttl" eq "k" ) {
                    $Ttl = $ttl;
                } elsif ( "$change_ttl" eq "c" ) {
                    print "Please enter in the new TTL value: 86400 or 14400\n";
                    chomp($Ttl = (<>));
                    if ( $Ttl !~ /86400|14400/ ) {
                        print "Invalid TTL value. Please try again\n";
                        undef $change_ttl ;
                        &get_info;
                    }
                } else {
                    print "Invalid response. Please try again\n";
                    undef $change_ttl;
                    &get_info;
                }
            } 
            if ( !defined($change_host) ) {
                print "The current source hostname is $change_host. Would you like to keep this or change it? (k)eep, (c)hange.\n";
                chomp($change_host = (<>));
                if ( "$change_host" eq "k" ) {
                    $Host_name = $hostname;
                } elsif ( "$change_host" eq "c" ) {
                    print "Please enter in the new source hostname for this entry\n";
                    chomp($Host_Name = (<>));
                } else {
                    print "Invalid response. Please try again\n";
                    undef $change_host;
                    &get_info;
                }
            }            
        } elsif ( $Record_Type eq MX ) {
            ($ttl,$in,$record_type,$hostname) = split(/\s+/,$Find_Record_Result);
            if ( !defined($change_ttl) ) {
                print "The current TTL is $ttl. Would you like to keep this or change it? (k)eep, (c)hange.\n";
                chomp($change_ttl = lc(<>));
                if ( "$change_ttl" eq "k" ) {
                    $Ttl = $ttl;
                } elsif ( "$change_ttl" eq "c" ) {
                    print "Please enter in the new TTL value: 86400 or 14400\n";
                    chomp($Ttl = (<>));
                    if ( $Ttl !~ /86400|14400/ ) {
                        print "Invalid TTL value. Please try again\n";
                        undef $change_ttl ;
                        &get_info;
                    }
                } else {
                    print "Invalid response. Please try again\n";
                    undef $change_ttl;
                    &get_info;
                }
            } 
            if ( !defined($change_host) ) {
                print "The current mail hostname is $change_host. Would you like to keep this or change it? (k)eep, (c)hange.\n";
                chomp($change_host = (<>));
                if ( "$change_host" eq "k" ) {
                    $Host_name = $hostname;
                } elsif ( "$change_host" eq "c" ) {
                    print "Please enter in the new source hostname for this entry\n";
                    chomp($Host_Name = (<>));
                } else {
                    print "Invalid response. Please try again\n";
                    undef $change_host;
                    &get_info;
                }

        } else {
            print "Invalid record type $Record_Type. Please try again\n";
            undef $Record_Type;
            &get_info;
        }
        print "Please confirm the following information:\n";
        print "Replacing the line $Find_Record_Result with\n";
        if ( "$Record_Type" eq "A" ) {
            sprintf "%-24s%-8sIN      %-8s%-15s\n", $Host_Name, $Ttl, $Record_Type, $Ip;
            $Line =  sprintf "%-24s%-8sIN      %-8s%-15s\n", $Host_Name, $Ttl, $Record_Type, $Ip;
        } elsif ( "$Record_Type" eq "MX" ) {
            sprintf "%29s   IN      %-8s%-1s %-15s\n", $Ttl, $Record_Type, $Pref_Value, $Host_Name;
            $Line = sprintf "%29s   IN      %-8s%-1s %-15s\n", $Ttl, $Record_Type, $Pref_Value, $Host_Name;
        } elsif ( "$Record_Type" eq "CNAME" ) {
            sprintf "%-24s%-8sIN      %-8s%-15s\n", $Alias_Host, $Ttl, $Record_Type, $Host_Name;
            $Line = sprintf "%-24s%-8sIN      %-8s%-15s\n", $Alias_Host, $Ttl, $Record_Type, $Host_Name;
        }
        print "Do you want to (r)e-enter the info, (c)ontinue to change the info in the zone file\n";
        chomp($info_confirm = lc(<>));
        if ( $info_confirm !~ /c|r/ ) {
            print "Invalid response. Please try again\n";
            &get_info;
        }
        if ( "$info_confirm" eq "r" ) {
            if ( "$Record_Type" eq "A" ) {
                undef $Record_Type;
                undef $Host_Name;
                undef $Ttl;
                undef $Ip;
            }
            if ( "$Record_Type" eq "MX" ) {
                undef $Record_Type;
                undef $Host_Name;
                undef $Ttl;
                undef $Ip;
            }
            if ( "$Record_Type" eq "CNAME" ) {
                undef $Record_Type;
                undef $Alias_Host;
                undef $Ttl;
                undef $Host_Name;
            }
            &get_info;
        } 
      }
    }
}

# Set the action type
sub get_action {
    print "Do you want to (a)dd/(d)el/(m)odify a record?\n";
    chomp($Action = lc(<>));
}

sub check_ip {
	my ($localip) = @_;
	if ( $localip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.(\d{1,3})/ ) {
		return 1;
                 
	} else {
		return 0;
	}
}

sub load_zone_file {
    @Zone_File_Contents = ();
    print "Would you like a list of the forward zone files or would you like to enter the file name?(l)ist/(e)nter file [e]:\n";
    $list_or_not = lc(<>);
    if ( "$list_or_not" eq "l" ) {
        print "Please select a zone file from the following:\n";
        opendir (ZDIR, $Forward_Zone_Directory) or die "Can't open zone directory $Forward_Zone_Directory: $!\n";
        while(define($file = readdir(ZDIR))) {
            next if $file =~ /^\.\.?$/;     # skip . and .. 
            print "$file\n";
        }
        close(ZDIR);
    } elsif ( $list_or_not !~ /l|e/ ) {
        print "Invalid input. Please try again\n";
        &load_zone_file;
    }
    print "Please enter a zone file you would like to change:\n";
    chomp($Zone_File = <>);
    if ( !-e "$Forward_Zone_Directory/$Zone_File" ) {
        print "Zone file $Zone_File does not exists, please try again\n";
        print "Enter name of zone file to change\n";
        chomp($Zone_File = <>);
        if ( !-e "$Forward_Zone_Directory/$Zone_File" ) {
            print "Zone file $Zone_File does not exists, exiting try again later\n";
            exit 1;
        }
    } else {
        open(ZF, "$Zone_File") or die "Can't open $Zone_File: $!\n";
        @Zone_File_Contents = <ZF>;
        close(ZF);
    }

    if ( $DEBUG == 1 ) {
        print "Checking Zone File contents\n";
        print Dumper(\@Zone_File_Contents);
    }
}

sub load_reverse_file {
    my ($ip_add) = @_;
    $reverse_file =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}).\d{1,3}$/;
    @Reverse_File_Contents = ();
    if ( !-e "$Reverse_Zone_Directory/$Reverse_File" ) {
        print "Reverse zone file $Reverse_File does not exists, please try again\n";
        if ( !-e "$Forward_Zone_Directory/$Zone_File" ) {
            print "Zone file $Zone_File does not exists, exiting try again later\n";
            print "Please make the changes manually\n";
        }
    } else {
        open(RZF, "$Zone_File") or die "Can't open $Zone_File: $!\n";
        @Reverse_File_Contents = <RZF>;
        close(RZF);
    }
    if ( $DEBUG == 1 ) {
        print "Checking Reverse Zone File contents\n";
        print Dumper(\@Reverse_File_Contents);
    }
}

sub find_record {
    my ($data_type,$item) = @_;
    foreach $zone_line (@Zone_File_Contents) {
        chop($zone_line);
        if ( ($zone_line =~ /$data_type/) && ( $zone_line =~ /$item/ ) ) {
            $zone_line =~ s/^\s+//; # remove any leading spaces
            return "$zone_line";
        } else {
            return 0;
        }
    }
}

sub apply_changes {
    if ( !-e "${Forward_Zone_Directory}/.${Zone_File}_lock" ) {
        system("touch ${Forward_Zone_Directory}/.${Zone_File}_lock"); # Locking mechanism
    } else {
        print "Lock file detected. Can not write changes at this time.\n";
    }
# Use RCS??
    chop($Serial_Number =`date '+%Y%m%d%H%M%S'`);
    if ( $Apply_RCS == 1 ) {
        Rcs->bindir('/usr/bin');
        my $rcsobj = Rcs->new;
        $rcsobj -> file(${Forward_Zone_Directory}/${Zone_File});    
        $rcsobj -> co('-l');    
    } else {
        rename(${Forward_Zone_Directory}/${Zone_File},${Forward_Zone_Directory}/${Zone_File}.${Serial_Number});
    }
    open(MYZF, "> ${Forward_Zone_Directory}/${Zone_File}") or die "Can't open Zone File for writing $Zone_File: $!\n"; 
    foreach my $Line (@Zone_File_Contents) {
	if ( $Line =~ /^\s*(\d+)\s*\;\s*serial$/ ) {
            chop($Serial_Number =`date '+%Y%m%d%H%M%S'`);
            $Lines =~ s/$1/$Serial_Number/;
        }
        print MYZF $Line; 
    }
# Checkin the forward zone file and check out the reverse zone file
    if ( $Apply_RCS == 1 ) {
        $rcsobj -> ci("-u","-m"."Modified by $Me on $Date_String");    
    }
    if ( $Apply_RCS == 1 ) {
        Rcs->bindir('/usr/bin');
        my $rcsobj = Rcs->new;
        $rcsobj -> file($Zone_File);    
        $rcsobj -> co('-l');    
    } else {
        rename(${Reverse_Zone_Directory}/${Zone_File},${Reverse_Zone_Directory}/${Zone_File}.${Serial_Number});
    }
    open(MYZF, "> ${Forward_Zone_Directory}/${Zone_File}") or die "Can't open Zone File for writing $Zone_File: $!\n"; 
    foreach my $Line (@Zone_File_Contents) {
	if ( $Line =~ /^\s*(\d+)\s*\;\s*serial$/ ) {
            chop($Serial_Number =`date '+%Y%m%d%H%M%S'`);
            $Lines =~ s/$1/$Serial_Number/;
        }
        print MYZF $Line; 
    }
    if ( $Apply_RCS == 1 ) {
        $rcsobj -> ci("-u","-m"."Modified by $Me on $Date_String"); 
    }
}


# Run main

main;
