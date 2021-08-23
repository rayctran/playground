#!/tools/perl/5.6.0/SunOS/bin/perl

########################################################################
#
# File   :  gnatsconv.pl
# History:  05-Aug-2004 raytran
#
########################################################################
#
# Script to convert data to GNATS
# version 1.0
#
# Command Line usage
# "Usage: $0 {full path to input file}\n";
#
########################################################################


use strict;
use IO::File;
use Net::Gnats;
use Date::Manip;
use Mail::Sendmail;
use File::Basename;
use Data::Dumper;
use Tie::IxHash;

my $run_test = 0;
my $create_pr = 1;
my $notify = 1;
my $reset_gnats;

if ($run_test) {
    print "TEST MODE ON\n";
    $reset_gnats = 0;
} else {
    print "TEST MODE OFF\n";
    $reset_gnats = 1;
}
my $report = 1;
my $log_file;


my $date_string=`date`;
#my $debug = 1;
my ($input_file);
#my @files_to_read = ("CoreExport.txt","PlatformsExport.txt","BRCMexport.txt");
my @files_to_read = ("PlatformsExport.txt","BRCMexport.txt");
# Don't know if this will work or not, but it should force the order of this array
#tie @files_to_read, "Tie::IxHash";
if ($report) {
    $log_file = "/tmp/ttp_convert.log";
}

#my @files_to_read = ("CoreExport.txt");
#my @files_to_read = ("PlatformsExport.txt");
#my @files_to_read = ("BRCMexport.txt");

my $notify_list = "raytran\@broadcom.com";

main ();

sub main {
    tie my %prs_info, "Tie::IxHash";
    my ($hi, @header, $header_cnt, $file_column, @ttp_line, @ttp_line_cnt);
    my ($value,$key, %seen_cat, @ttp_categories, @ttp_fields, $category_data);
    my %originator_lookup = (
           'Jacobus Alberts'  => 'jalberts',
           'Simon Baker'      => 'sbaker',
           'Leo Borromeo'     => 'borromeo',
           'Louis Botha'      => 'lbotha',
           'Hendrik Bruyns'   => 'hbruyns',
           'Johan Conroy'     => 'jconroy',
           'Brian Davis'      => 'davis',
           'Frederic Hayem'   => 'fhayem',
           'Philip Koekemoer' => 'philipk',
           'David Foos'       => 'dfoos',
           'Andrew du Preez'  => 'adupreez',
           'Mark Kent'        => 'mkent',
           'Cyrill Krymmer'   => 'ckrymmer',
           'Uri Landau'       => 'ulandau',
           'Yuan Li'         => 'jconroy',
           'Michiel Lotter'   => "mlotter",
           'Ian Riphagen'     => 'iriphagen',
           'Bill Siepert'     => 'bsiepert',
           'Jim Shin'         => 'jshin',
           'Luis Vaz'         => 'lvaz',
           'Danie van Wyk'    => 'mlotter',
    );
    my %responsible_lookup = (
           'Arthur Tzianacos' => 'arthur',
           'Mark Kent'        => 'mkent',
           'Uri Landau'       => 'ulandau',
           'Louis Botha'      => 'lbotha',
           'Frederic Hayem'   => 'fhayem',
           'Philip Koekemoer' => 'philipk',
           'Cyrill Krymmer'   => 'ckrymmer',
           'Jacobus Alberts'  => 'jalberts',
           'Luis Vaz'         => 'lvaz',
           'Jim Shin'         => 'jshin',
           'Johan Conroy'     => 'jconroy',
           'Michael Paquette' => 'paquette',
           'Leo Borromeo'     => 'borromeo',
           'Francis Swarts'   => 'fswarts',
           'Hennie Bruyns'    => 'hbruyns',
           'Yuan Li'          => 'yli',
           'David Foos'       => 'dfoos',
           'Pieter Roux'      => 'pieterr',
           'Sang Sung'        => 'ssung',
           'Andrew du Preez'  => 'adupreez',
           'Severine Catreux' => 'scatreux',
           'Ian Riphagen'     => 'riphagen',
           'Bill Siepert'     => 'bsiepert',
           'Simon Baker'      => 'sbaker',
           'Yi Zhou'          => 'yizhou',
           'Joseph Lim'       => 'jlim',
           'Michiel Lotter'   => "mlotter",
           'Hendrik Bruyns'   => 'hbruyns',
           'Jensen Kenedy'    => 'jkennedy',
           'Brian Davis'      => 'davis',
    );
    if ($report) {
        open (LF, "> $log_file") or die "Can't open log file : $!\n";
    }
    my $line_no = 211;
    foreach my $file (@files_to_read) {
        if (!-e "./Zyray/$file") {
            print "Can't access file $file: $!\n";
        } else {
            open(INFILE, "< ./Zyray/$file") or die "Can't open file: $!\n";
            if ($report) {
                print LF "Reading in TTP export file $file\n";
            }
            while(<INFILE>) {
                chop;
                if (/^Number/) {
                    @header = split(/\t/);
                    $header_cnt = scalar(@header);
                    $file_column = $header_cnt + 1;
                    next;
                } else {
                    $line_no++;
                    @ttp_line = split(/\t/);
                    my $ttp_line_cnt = scalar(@ttp_line);
                    for ( $hi=0; $hi< scalar(@header); $hi++) {
                        $header[$hi] =~ s/\s/_/; #Replace spaces with _ to make query later easier
                        $header[$hi] =~ s/\-/_/; #Replace - with _
                        $header[$hi] =~ s/\"//; #Remove "
                        $header[$hi] =~ s/\#/No/; #Remove "
                        $prs_info{$line_no}{${header[$hi]}} = $ttp_line[$hi];
                    }
                    $prs_info{$line_no}{Imported_file} = "$file";
                }
            }
            close(INFILE);
        }
    } # close foreach my $file (@files_to_read)

#print Dumper(%prs_info);
    my $db_dir;
    if ($run_test) {
        $db_dir = "/tools/gnatsQA/4.0/share/gnats/db-zyray-qa";
    } else {
        $db_dir = "/tools/gnats/4.0/share/gnats/db-zyray";
    }

    my %pr;
    foreach $key (keys %prs_info) {
        %pr = ();
        $pr{pr_number} = $key;
        if ($report) {
            print LF "Original TTP defect number is $prs_info{$key}{Number} converted to GNATS PR $pr{pr_number} from file $prs_info{$key}{Imported_file} \n";
            print "Original TTP defect number is $prs_info{$key}{Number} converted to GNATS PR $pr{pr_number} from file $prs_info{$key}{Imported_file} \n";
        }
# Category Mapping
        if ( $prs_info{$key}{Imported_file} =~ /PlatformsExport/ ) {
            if ( $prs_info{$key}{Component} =~ /Hardware|HW: S-Gold Eval/ ) {
                $pr{category} = "Tools-FP1UE";
            }
            if ( $prs_info{$key}{Component} =~ /Spinner Terminal/ ) {
                $pr{category} = "Tools-Spinner_Terminal";
            }
            if ( $prs_info{$key}{Component} =~ /Calibration System|Development Env/ ) {
                $pr{category} = "Tools-Phone_Tool";
            }
            if ($report) {
                print LF "$prs_info{$key}{Component} is mapped to GNATS category $pr{category}\n";
            }
        }
        if ( $prs_info{$key}{Imported_file} =~  /CoreExport|BRCMexport/  ) {
            if ( $prs_info{$key}{Sub_system} =~ /Searcher|Measurements|Searcher/ ) {
                $pr{category} = "2140-Software-Searcher";
            }
            if ( $prs_info{$key}{Sub_system} =~ /RAKE|Combiner/ ) {
                $pr{category} = "2140-System-Chip_Level";
            }
            if ( $prs_info{$key}{Sub_system} =~ /AFC|Chip Matched Filter/ ) {
                $pr{category} = "2140-System-RF";
            }
            if ( $prs_info{$key}{Sub_system} =~ /Ciphering|De-Interleaver/ ) {
                $pr{category} = "2140-ASIC-Bit_Level";
            }
            if ( $prs_info{$key}{Sub_system} =~ /Tx Chip Level/ ) {
                $pr{category} = "2140-ASIC-Tx";
            }
            if ( $prs_info{$key}{Sub_system} =~ /AHB|Interrupt|Controller|ASIC Core|Baseband Interface|Clock|Layer 1 Interrupt Controller|Master TImer|Timer|UART|USIM/ ) {
                $pr{category} = "2140-ASIC-Core";
            }
            if ( $prs_info{$key}{Sub_system} =~ /Debug Interface|Rx General|Stack Interface|Tx General|ARM Sub-system|SPINNER_Cipher|SPINNER_Config|SPINNER_ISR|SPINNER_Tx|Layer 2 Simulator|Complex Test Case|Regression Test Case/ ) {
                $pr{category} = "2140-Software-Procedures";
            }
            if ( $prs_info{$key}{Sub_system} =~ /RF/ ) {
                $pr{category} = "2140-Software-RF";
            }
            if ( $prs_info{$key}{Sub_system} =~ /General|Rx Bit Level|Tx Bit Level|AHB Arbiter|no subsystem specified|^\s*$/ ) {
                $pr{category} = "2140-Unknown-Unknown";
            }
            if ( $prs_info{$key}{Component} =~ /Layer 1 Router|Layer 1 FW/ ) {
                $pr{category} = "2140-Software-Procedures";
            }
            if ($report) {
                print LF "$prs_info{$key}{Sub_system} is mapped to GNATS category $pr{category}\n";
            }
            if ( $prs_info{$key}{Description} =~ /nnlnlnl/ ) {
                $pr{category} = "2140-Software-Searcher";
                print LF "Force set category to 2140-Software-Searcher\n";
            }
        }
 # Set state of ticket
        if ($prs_info{$key}{Status} =~ /^Open, not assigned$/ ) {
            $pr{state} = "Open";
            $pr{open_not_assign} = 1;
            if ($report) {
                print LF "TTP Status is $prs_info{$key}{Status} - GNATS State set to Open\n";
            }
        }
        if ($prs_info{$key}{Status} =~ /^In-Process, assigned to ((\w\s*)*)$/ ) {
            $pr{state} = "Assigned";
            $pr{responsible} = $responsible_lookup{$1};
            if ($report) {
                print LF "TTP Status is $prs_info{$key}{Status} - GNATS State set to $pr{state}\n";
                print LF "Responsible is set to $pr{responsible}\n";
            }
        }
        if ($prs_info{$key}{Status} =~ /^Assigned, assigned to ((\w\s*)*)$/ ) {
            $pr{state} = "Assigned";
            $pr{responsible} = $responsible_lookup{$1};
            if ($report) {
                print LF "TTP Status is $prs_info{$key}{Status} - GNATS State set to $pr{state}\n";
                print LF "Responsible is set to $pr{responsible}\n";
            }
        }
        if ($prs_info{$key}{Status} =~ /^Fixed, Needs Regression Test, assigned to ((\w\s*)*)$/ ) {
            $pr{state} = "Test";
            $pr{responsible} = $responsible_lookup{$1};
            if ($report) {
                print LF "TTP Status is $prs_info{$key}{Status} - GNATS State set to $pr{state}\n";
                print LF "Responsible is set to $pr{responsible}\n";
            }
        }
        if ($prs_info{$key}{Status} eq "Closed" ) {
            $pr{state} = "Closed";
            $pr{closed_date} = &UnixDate("$prs_info{$key}{Date_Modified}","%a %b %e %H:%M:%S %Z %Y");
            if ($report) {
                print LF "TTP Status is $prs_info{$key}{Status} - GNATS State set to $pr{state}\n";
            }
        }
        if ($prs_info{$key}{Status} =~ /Closed, assigned to ((\w\s*)*)$/ ) {
            $pr{state} = "Closed";
            $pr{closed_date} = &UnixDate("$prs_info{$key}{Date_Modified}","%a %b %e %H:%M:%S %Z %Y");
            $pr{responsible} = $responsible_lookup{$1};
            if ($report) {
                print LF "TTP Status is $prs_info{$key}{Status} - GNATS State set to $pr{state}\n";
                print LF "Responsible is set to $pr{responsible}\n";
            }
        }

# Try to figure out the flow using state
        if ($prs_info{$key}{Assign_Resulting_State} =~ /Assigned/) {
            if ($report) {
                print LF "Dectected Assign Resulting State is $prs_info{$key}{Assign_Resulting_State}, getting information for Audit-Trail\n";
            }
            $pr{assigned_date} = &UnixDate("$prs_info{$key}{Assign_Date}","%a %b %e %H:%M:%S %Z %Y");
            $pr{assigned_by} = $prs_info{$key}{Assigned_By_User};
            $pr{assigned_to} = $prs_info{$key}{Assigned_To_User};
            $pr{assigned_notes} = $prs_info{$key}{Assign_Notes};
            if (! exists $pr{responsible}) {
                $pr{responsible} = $responsible_lookup{$pr{assigned_to}};
                if ($report) {
                    print LF "Responsible is set to $pr{responsible} using the Assigned_To_User field\n";
                }
            }
            $pr{assigned_status} = 1;
        }
        if ( $prs_info{$key}{Re_assign_Resulting_State} =~ /In(-|\s)Pro(gr|c)ess/ ) {

            if ($report) {
                print LF "Dectected Re-assign Resulting State is $prs_info{$key}{Re_assign_Resulting_State}, getting information for Audit-Trail\n";
            }
            $pr{re_assigned_date} = &UnixDate("$prs_info{$key}{Assign_Date}","%a %b %e %H:%M:%S %Z %Y");
            $pr{re_assigned_by} = $prs_info{$key}{Re_assign_By_User};
            $pr{re_assigned_to} = $prs_info{$key}{Re_assign_To_User};
            $pr{re_assigned_notes} = $prs_info{$key}{Re_assign_Notes};
  
            if (! exists $pr{responsible}) {
                $pr{responsible} = $responsible_lookup{$pr{re_assigned_to}};
                if ($report) {
                    print LF "Responsible is set to $pr{responsible} using the Re_assign_To_User field\n";
                }
            }
            $pr{re_assigned_status} = 1;
        }
 
        if ( $prs_info{$key}{Force_Close_Resulting_State} =~ /Closed/ ) {
            if ($report) {
                print LF "Dectected Force Close Resulting State is $prs_info{$key}{Force_Close_Resulting_State}, getting information for Audit-Trail\n";
            }
            $pr{closed_date} = &UnixDate("$prs_info{$key}{Date_Modified}","%a %b %e %H:%M:%S %Z %Y");
            $pr{force_close_by} = $prs_info{$key}{Force_Close_By_User};
            $pr{force_close_date} = $prs_info{$key}{Force_Close_Date};
            $pr{force_close_notes} = $prs_info{$key}{Force_Close_Notes};
            $pr{force_close_resolution} = $prs_info{$key}{Force_Close_Resolution};
            $pr{force_close_status} = 1;
        }
        if ( $prs_info{$key}{'Force_Close Resulting State'} =~ /Closed/ ) {
            if ($report) {
                print LF "Dectected Force Close Resulting State is $prs_info{$key}{Force_Close_Resulting_State}, getting information for Audit-Trail\n";
            }
            $pr{closed_date} = &UnixDate("$prs_info{$key}{Date_Modified}","%a %b %e %H:%M:%S %Z %Y");
            $pr{force_close_by} = $prs_info{$key}{'Force_Close By User'};
            $pr{force_close_date} = $prs_info{$key}{'Force_Close Date'};
            $pr{force_close_notes} = $prs_info{$key}{'Force_Close Notes'};
            $pr{force_close_resolution} = $prs_info{$key}{'Force_Close Resolution'};
            $pr{force_close_status} = 1;
        }
 
        if ($prs_info{$key}{Fix_Resulting_State} =~ /^Fixed/) {
            if ($report) {
                print LF "Dectected Fix Resulting State is $prs_info{$key}{Fix_Resulting_State}, getting information for Audit-Trail\n";
            }
            $pr{fix_date} = &UnixDate("$prs_info{$key}{Fix_Date}","%a %b %e %H:%M:%S %Z %Y");
            $pr{fix_by} = $prs_info{$key}{Fixed_By_User};
            $pr{fix_version} = $prs_info{$key}{Fix_Version};
            $pr{fix_resolution} = $prs_info{$key}{Fix_Resolution};
            $pr{fix_affects_doc} = $prs_info{$key}{Fix_Affects_Documentation};
            $pr{fix_notes} = $prs_info{$key}{Fix_Notes};
            $pr{fix_status} = 1;
            $pr{fix} = $pr{fix_resolution};
        }
        if ($prs_info{$key}{Assign_for_verify_Resulting_State} =~ /Fixed, Needs Regression Test/) {
            if ($report) {
                print LF "Dectected Assign for verify Resulting State is $prs_info{$key}{Assign_for_verify_Resulting_State},  getting information for Audit-Trail\n";
            }
            $pr{assign_for_verify_date} = &UnixDate("$prs_info{$key}{Assign_for_verify_Date}","%a %b %e %H:%M:%S %Z %Y");
            $pr{assign_for_verify_by} = $prs_info{$key}{Assign_for_verify_By_User};
            $pr{assign_for_verify_to} = $prs_info{$key}{Assign_for_verify_To_User};
            $pr{assign_for_verify_notes} = $prs_info{$key}{Assign_for_verify_Notes};
            $pr{assign_for_verify_status} = 1;
        }
        if ($prs_info{$key}{Verify_Resulting_State} =~ /Closed/) {
            if ($report) {
                print LF "Dectected Verify Resulting State is $prs_info{$key}{Verify_Resulting_State},  getting information for Audit-Trail\n";
            }
            $pr{verify_date} = &UnixDate("$prs_info{$key}{Verify_Date}","%a %b %e %H:%M:%S %Z %Y");
            $pr{verify_by} = $prs_info{$key}{Verify_By_User};
            $pr{verify_version} = $prs_info{$key}{Verify_Version};
            $pr{verify_notes} = $prs_info{$key}{Verify_Notes};
            $pr{verify_status} = 1;
        }
        if ($prs_info{$key}{Re_Open_Resulting_State} =~ /Open/) {
            if ($report) {
                print LF "Dectected Re-Open Resulting State is $prs_info{$key}{Re_Open_Resulting_State},  getting information for Audit-Trail\n";
            }
            $pr{re_open_date} = &UnixDate("$prs_info{$key}{Re_Open_Date}","%a %b %e %H:%M:%S %Z %Y");
            $pr{re_open_by} = $prs_info{$key}{Re_Open_By_User};
            $pr{re_open_notes} = $prs_info{$key}{Re_Open_Notes};
            $pr{re_open_status} = 1;
        }
        if ($prs_info{$key}{Verification_failed_Resulting_State} =~ /In-Process/) {
            if ($report) {
                print LF "Dectected Verify failed Resulting State is $prs_info{$key}{Verification_failed_Resulting_State},  getting information for Audit-Trail\n";
            }
            $pr{verification_failed_date} = &UnixDate("$prs_info{$key}{Verification_failed_Date}","%a %b %e %H:%M:%S %Z %Y");
            $pr{verification_failed_by} = $prs_info{$key}{Verification_failed_By_User};
            $pr{verification_failed_to} = $prs_info{$key}{Verification_failed_To_User};
            $pr{verification_failed_notes} = $prs_info{$key}{Verification_failed_Notes};
            $pr{verification_failed_status} = 1;
        }
        if( $prs_info{$key}{Comment_Notes} !~ /^\s*$/ ) {
            $pr{comment_notes} = $prs_info{$key}{Comment_Notes};
            $pr{comment_by} = $prs_info{$key}{Comment_By_User};
            $pr{comment_date} = &UnixDate("$prs_info{$key}{Comment_Date}","%a %b %e %H:%M:%S %Z %Y");
            $pr{comment_status} = 1;
        }
        if( $prs_info{$key}{Creation_Method} !~ /^\s*$/ ) {
            $pr{creation_method} = $prs_info{$key}{Creation_Method};
            $pr{creation_method_status} = 1;
        }
        if( $prs_info{$key}{Workaround} !~ /^\s*$/ ) {
            $pr{workaround} = $prs_info{$key}{Workaround};
            $pr{workaround_status} = 1;
        }
        if( $prs_info{$key}{Steps_to_Reproduce} !~ /^\s*$/ ) {
            $pr{steps_to_reproduce} = $prs_info{$key}{Steps_to_Reproduce};
            $pr{steps_to_reproduce_status} = 1;
        }
        if( $prs_info{$key}{Has_Release_Notes} !~ /^\s*$/) {
            $pr{has_release_notes} = $prs_info{$key}{Has_Release_Notes};
            $pr{has_release_notes_status} = 1;
        }
        if( $prs_info{$key}{'Has_Release Notes'} !~ /^\s*$/ ) {
            $pr{has_release_notes} = $prs_info{$key}{'Has_Release Notes'};
            $pr{has_release_notes_status} = 1;
        }

# Some last minute tweak based defects with multiple people assigned
        if ( (!exists $pr{responsible}) || ($pr{responsible} =~ /^\s*$/)) {
            if ( $prs_info{$key}{Summary} =~ /AFC control for inter RAT handover/ ) {
                $pr{responsible} = $responsible_lookup{'Louis Botha'};
                if ($report) {
                    print LF "Responsible is forced set to $pr{responsible} Core defect 111\n";
                }
            }
            if ( $prs_info{$key}{Summary} =~ /TX power mode levels in Phone Tool GUI/ ) {
                $pr{responsible} = $responsible_lookup{'Bill Siepert'};
                if ($report) {
                    print LF "Responsible is forced set to $pr{responsible} Platforms defect 7\n";
                }
            }
            if ( $prs_info{$key}{Summary} =~ /Interrupt from SPINNER to S\-GOLD on S\-GOLD I\/F board/ ) {
                $pr{responsible} = $responsible_lookup{'Bill Siepert'};
                if ($report) {
                    print LF "Responsible is forced set to $pr{responsible} Platforms defect 13\n";
                }
            }
            if ( $prs_info{$key}{Summary} =~ /SpinnerTerminal does not generate the DbgVars\.h/ ) {
                $pr{responsible} = $responsible_lookup{'Bill Siepert'};
                if ($report) {
                    print LF "Responsible is forced set to $pr{responsible} Platforms defect 76\n";
                }
            }
            if ( $prs_info{$key}{Summary} =~ /Tx min power is \-50 dBm not \-56 dBm/ ) {
                $pr{responsible} = $responsible_lookup{'Mark Kent'};
                if ($report) {
                    print LF "Responsible is forced set to $pr{responsible} Platforms defect 76\n";
                }
            }
        }

# Responsible last resort assign to forced_close_by
        if ( (!exists $pr{responsible}) && (!exists $pr{open_not_assign}) ) {
            if (exists $pr{force_close_by}) {
                $pr{responsible} = $responsible_lookup{"$pr{force_close_by}"};
                if ($report) {
                    print LF "No assignment, using force close by $pr{force_close_by}\n";
                }
            } else {
                $pr{responsible} = $responsible_lookup{$prs_info{$key}{Created_By}};
                if ($report) {
                    print LF "No assignment, using created by $pr{responsible}\n";
                }
            }
        }
 
        $pr{found_date} = &UnixDate("$prs_info{$key}{Date_Found}","%a %b %e %H:%M:%S %Z %Y");
        $pr{found_by} = $prs_info{$key}{Found_by};
 
 # The rest of the fields
        if ( $prs_info{$key}{Reproduced} !~ /^\s*$/ ) {
            print "$prs_info{$key}{Reproduced}\n";
            $pr{reproduced} = $prs_info{$key}{Reproduced};
            $pr{reproduced} =~ tr/A-Z/a-z/;
        } else {
             $pr{reproduced} = "always"; 
        }
        $pr{originator_lu} = $originator_lookup{$prs_info{$key}{Entered_by}};
        $pr{originator}="$pr{originator_lu}\@broadcom.com \($prs_info{$key}{Entered_by}\)";
        $pr{from}="$pr{originator_lu}\@broadcom.com";
        $pr{arrival_date} = &UnixDate("$prs_info{$key}{Date_Created}","%a %b %e %H:%M:%S %Z %Y");
        $pr{last_modified} = &UnixDate("$prs_info{$key}{Date_Modified}","%a %b %e %H:%M:%S %Z %Y");
        $pr{description} = $prs_info{$key}{Description};
        $pr{reference_number} = $prs_info{$key}{Reference_No};
        $pr{synopsis} = $prs_info{$key}{Summary};
        $pr{priority} = $prs_info{$key}{Priority};
        $pr{priority} =~ tr/A-Z/a-z/;
        $pr{severity} = $prs_info{$key}{Severity};
        $pr{severity} =~ tr/A-Z/a-z/;

# Audit-Trail input based on flow
        $pr{audit_trail} .= "Found-By: $pr{found_by}\n";
        $pr{audit_trail} .= "Found-When: $pr{found_date}\n";
 
        if ($pr{assigned_status}) {
            $pr{audit_trail} .= "Assigned-By: $pr{assigned_by}\n";
            $pr{audit_trail} .= "Assigned-When: $pr{assigned_date}\n";
            $pr{audit_trail} .= "Assigned-To: $pr{assigned_to}\n";
            $pr{audit_trail} .= "Assigned-Notes: \n";
            $pr{audit_trail} .= "$pr{assigned_notes}\n";
        }
        if ($pr{re_assigned_status}) {
            $pr{audit_trail} .= "Responsible-Changed-By: $pr{re_assigned_by}\n";
            $pr{audit_trail} .= "Responsible-Changed-When: $pr{re_assigned_date}\n";
            $pr{audit_trail} .= "Responsible-Changed-From-To: $pr{assigned_to}->$pr{re_assigned_to}\n";
            $pr{audit_trail} .= "Responsible-Changed-Notes:\n";
            $pr{audit_trail} .= "$pr{re_assigned_notes}\n";
        }
        if ($pr{fix_status}) {
            $pr{audit_trail} .= "Fixed-By: $pr{fix_by}\n";
            $pr{audit_trail} .= "Fixed-When: $pr{fix_date}\n";
            $pr{audit_trail} .= "Fix-Resolution: $pr{fix_resolution}\n";
            $pr{audit_trail} .= "Fix-Affects-Doc: $pr{fix_affects_doc}\n";
            $pr{audit_trail} .= "Fix-Version: $pr{fix_version}\n";
            $pr{audit_trail} .= "Fix-Notes:\n";
            $pr{audit_Trial} .= "$pr{fix_notes}\n";
        }
        if ($pr{re_open_status}) {
            $pr{audit_trail} .= "Re-Open-By: $pr{re_open_by}\n";
            $pr{audit_trail} .= "Re-Open-When: $pr{re_open_date}\n";
            $pr{audit_trail} .= "Re-Open-Notes:\n";
            $pr{audit_Trial} .= "$pr{re_open_notes}\n";
        }
 
        if ($pr{force_close_status}) {
            $pr{audit_trail} .= "Force-close-By: $pr{force_close_by}\n";
            $pr{audit_trail} .= "Force-close-When: $pr{force_close_date}\n";
            $pr{audit_trail} .= "Forced-close-Reason:\n";
            $pr{audit_trail} .= "$prs_info{$key}{force_close_notes}\n";
            $pr{audit_trail} .= "$prs_info{$key}{force_close_resolution}\n";
        }
        if ($pr{assign_for_verify_status}) {
            $pr{audit_trail} .= "Assign-For-Verify-By: $pr{assign_for_verify_by}\n";
            $pr{audit_trail} .= "Assign-For-Verify-When: $pr{assign_for_verify_date}\n";
            $pr{audit_trail} .= "Assign-For-Verify-To: $pr{assign_for_verify_to}\n";
            $pr{audit_trail} .= "Assign-For-Verify-Notes:\n";
            $pr{audit_trail} .= "$pr{assign_for_verify_notes}\n";
        }
        if ($pr{verify_status}) {
            $pr{audit_trail} .= "Verify-By: $pr{verify_by}\n";
            $pr{audit_trail} .= "Verify-When: $pr{verify_date}\n";
            $pr{audit_trail} .= "Verify-Version: $pr{verify_version}\n";
            $pr{audit_trail} .= "Verify-Notes:\n";
            $pr{audit_trail} .= "$pr{verify_notes}\n";
        }
        if ($pr{verification_failed_status}) {
            $pr{audit_trail} .= "Verification-Failed-By: $pr{verification_failed_by}\n";
            $pr{audit_trail} .= "Verification-Failed-When: $pr{verification_failed_date}\n";
            $pr{audit_trail} .= "Verification-Failed-To: $pr{verification_failed_to}\n";
            $pr{audit_trail} .= "Verification-Failed-Notes:\n";
            $pr{audit_trail} .= "$pr{verification_failed_notes}\n";
        }
        if ($pr{comment_status}) {
            $pr{audit_trail} .= "Comment-By: $pr{comment_by}\n";
            $pr{audit_trail} .= "Comment-When: $pr{comment_date}\n";
            $pr{audit_trail} .= "Comment-Notes:\n";
            $pr{audit_trail} .= "$pr{comment_notes}\n";
        }
        if ($pr{creation_method_status}) {
            $pr{audit_trail} .= "Creation-Method:\n";
            $pr{audit_trail} .= "$pr{creation_method}\n";
        }
        if ($pr{has_release_notes_status}) {
            $pr{audit_trail} .= "Release-Notes:\n";
            $pr{audit_trail} .= "$pr{has_release_notes}\n";
        }
        if ($pr{workaround_status}) {
            $pr{audit_trail} .= "Workaround:\n";
            $pr{audit_trail} .= "$pr{workaround}\n";
        }
# Report
       if ($report) {
           if (exists $pr{category}) {
              print LF "Category is $pr{category}\n";
           } else {
              print LF "ERROR: NO CATEGORY ASSIGNED\n";
           }
           if (exists $pr{responsible}) {
               print LF "Responsible is $pr{responsible}\n";
           } else {
               print LF "ERROR: NO RESPONSIBLE PERSON ASSIGNED\n";
           }
           if (exists $pr{originator}) {
               print LF "Originator is $pr{originator}\n";
           } else {
               print LF "ERROR: NO ORIGINATOR FOUND\n";
           }

           if (exists $pr{originator}) {
               print LF "Arrival-Date set to $pr{arrival_date}\n";
           } else {
               print LF "ERROR: NO ORIGINATOR FOUND\n";
           }
           if (exists $pr{state}) {
               print LF "State is $value $pr{state}\n";
           } else {
               print LF "ERROR: NO STATE SET\n";
           }
           if (exists $pr{severity}) {
               print LF "Severity set to $pr{severity}\n";
           } else {
               print LF "ERROR: NO SEVERITY SET\n";
           }
           if (exists $pr{priority}) {
               print LF "Priority set to $pr{priority}\n";
           } else {
               print LF "ERROR: NO PRIORITY SET\n";
           }
           if (exists $pr{synopsis}) {
               print LF "Summary set to $pr{synopsis}\n";
           } else {
               print LF "ERROR: NO SYNOPSIS FOUND\n";
           }
           if (exists $pr{audit_trail}) {
               print LF "Audit-Trail set to $pr{audit_trail}\n";
           } 

       }

# Was trying to avoide this but we'll have to loop through to get all Notes fields for the Audit-Trail
        for $value (keys %{ $prs_info{$key} } ) {
            if ( $value =~ /Notes/ ) {

            } 
        } # close for value loop


# Dumping out PR files
        if ($create_pr) {
open(OUTFILE,"> $db_dir/$pr{category}/$pr{pr_number}") or die "Can't create PR $db_dir/$pr{category}
/$pr{pr_number}: $!\n";
print OUTFILE "From: $pr{from}
Reply-To: $pr{from}
To: bugs
Cc:
Subject: $pr{synopsis}
X-Send-Pr-Version: gnatsweb-4.00 (1.41)
X-GNATS-Notify:

>Number:         $pr{pr_number}
>Notify-List:
>Category:       $pr{category}
>Synopsis:       $pr{synopsis}
>Confidential:   no
>Severity:       $pr{severity}
>Priority:       $pr{priority}
>Responsible:    $pr{responsible}
>State:          $pr{state}
>Keywords:
>Date-Required:
>Submitter-Id:   broadcom-zyray-qa
>Arrival-Date:   $pr{arrival_date}
>Closed-Date:    $pr{closed_date}
>Last-Modified:   $pr{last_modified}
>Originator:     $pr{originator}
>Reference_Number:  $pr{reference_number}
>Organization:
>Environment:
None
>Description:
$pr{description}
>Reproduced:     $pr{reproduced}
>Reproduced-Steps:
$pr{steps_to_reproduce}
>Test-Config:    National_Instruments
>Fix:
$pr{fix}
>Workaround:
None
>Cloned-from:
>Cloned-to:
>Audit-Trail:
$pr{audit_trail}



>Unformatted:
";
close(OUTFILE);

            if ($report) {
                print LF "File $db_dir/$pr{category}/$pr{pr_number} created\n";
            }

        } # close for if create_pr

    } # close foreach $key (keys %prs_info)

# Rebuild the index file
    if ($reset_gnats) {
        system("mv $db_dir/gnats-adm/current $db_dir/gnats-adm/current.old");
        if ($report) {
            print LF "Re-indexing database. Current number is set to $pr{pr_number}\n";
        }
        open(CURRENT,"> $db_dir/gnats-adm/current") or die "Can't write to current: $!\n";
        print CURRENT "$pr{pr_number}";
        close(CURRENT);
        system("rm $db_dir/gnats-adm/index");
        system("cd $db_dir/gnats-adm;/tools/bin/make index");
    }
    if ($report) {
        close(LF);
        if ($notify) {
            system("mailx -s \"TTP GNATS Conversion Log $date_string\" $notify_list < $log_file");
        }
    }


} # close main ()
