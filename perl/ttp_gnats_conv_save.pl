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

my $reset_gnats = 1;
my $report = 1;
my $log_file;


my $date_string=`date`;
#my $debug = 1;
my ($input_file);
my @files_to_read = ("CoreExport.txt","PlatformsExport.txt","BRCMexport.txt");
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

sub notify {
    my($sendto,$subject,$message)=@_;
    my %mail = (
            smtp    => 'smtphost.broadcom.com',
            to      => $sendto,
            from    => "gnats4\@broadcom.com",
            subject => $subject,
            message => $message,
    );

    eval { sendmail(%mail) || die $Mail::Sendmail::error; };
    $Mail::Sendmail::log;

    if ($@) {
            print "mail could NOT be sent correctly - $@\n";
    } else {
            print "mail sent correctly\n";
    }

}

# ******************************************************

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
   );
   if ($report) {
       open (LF, "> $log_file") or die "Can't open log file : $!\n";
   }
   my $line_no = 0;
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
   }

#print Dumper(%prs_info);
   #my $db_dir = "/tools/gnatsQA/4.0/share/gnats/db-zyray-qa";
   my $db_dir = "/home/raytran/db-zyray-qa";
   my %pr;
   foreach $key (keys %prs_info) {
       %pr = ();
       $pr{pr_number} = $key;
       if ($report) {
           print LF "Original TTP Ticket number is $prs_info{$key}{Number} converted to GNATS PR $pr{pr_number} from file $prs_info{$key}{Imported_file} \n";
           print "Original TTP Ticket number is $prs_info{$key}{Number} converted to GNATS PR $pr{pr_number} from file $prs_info{$key}{Imported_file} \n";
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
       if ( $prs_info{$key}{Sub_system} =~ /Measurements|Searcher/ ) {
           $pr{category} = "2140-Software-Searcher";
       }
       if ( $prs_info{$key}{Sub_system} =~ /Debug Interface|Rx General|Stack Interface|Tx General|ARM Sub-system|SPINNER_Cipher|SPINNER_Config|SPINNER_ISR|SPINNER_Tx|Layer 2 Simulator|Complex Test Case|Regression Test Case/ ) {
           $pr{category} = "2140-Software-Procedures";
       }

       print "figured out category - now doing the rest of the fields\n";
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
# Set state of ticket
       if ($prs_info{$key}{Status} =~ /^Open, not assigned$/ ) {
           $pr{state} = "Open";
       }
       if ($prs_info{$key}{Status} eq "Closed" ) {
           $pr{state} = "Closed";
           $pr{closed_date} = &UnixDate("$prs_info{$key}{Date_Modified}","%a %b %e %H:%M:%S %Z %Y");
       }
       if ($prs_info{$key}{Status} =~ /^Assigned, assigned to ((\w\s*)*)$/ ) {
           $pr{state} = "Assigned";
           $pr{responsible} = $responsible_lookup{"$1"};
       }
       if ($prs_info{$key}{Status} =~ /^In-Process, assigned to ((\w\s*)*)$/ ) {
           $pr{state} = "Assigned";
           $pr{responsible} = $responsible_lookup{"$1"};
       }
       if ($prs_info{$key}{Status} =~ /^Fixed, Needs Regression Test, assigned to ((\w\s*)*)$/ ) {
           $pr{state} = "Test";
           $pr{responsible} = $responsible_lookup{"$1"};
       }
       if ($prs_info{$key}{Assign_Resulting_State} eq "Assigned") {
           $pr{assigned_date} = &UnixDate("$prs_info{$key}{Assign_Date}","%a %b %e %H:%M:%S %Z %Y");
           $pr{assigned_by} = $prs_info{$key}{Assigned_By_User};
           $pr{assigned_to} = $prs_info{$key}{Assigned_To_User};
           if ($pr{re_assigned_status}) {
               print LF "Responsible already re-assigned to $pr{re_assigned_to}\n";
           } else {
               $pr{responsible} = $responsible_lookup{$pr{assigned_to}};
           }
           $pr{assigned_status} = 1;
  
       }
       if ($prs_info{$key}{Re_assign_Resulting_State} eq "In-Process") {
           $pr{re_assigned_date} = &UnixDate("$prs_info{$key}{Assign_Date}","%a %b %e %H:%M:%S %Z %Y");
           $pr{re_assigned_by} = $prs_info{$key}{Re_assign_By_User};
           $pr{re_assigned_to} = $prs_info{$key}{Re_assign_To_User};
           $pr{responsible} = $responsible_lookup{$pr{re_assigned_to}};
           $pr{re_assigned_status} = 1;
       }

       if ($prs_info{$key}{Force_Close_Resulting_State} eq "Closed") {
           $pr{closed_date} = &UnixDate("$prs_info{$key}{Date_Modified}","%a %b %e %H:%M:%S %Z %Y"); 
           $pr{force_close_by} = $prs_info{$key}{Force_Close_By_User};
           $pr{force_close_notes} = $prs_info{$key}{Force_Close_Notes};
           $pr{force_close_resolution} = $prs_info{$key}{Force_Close_Resolution};
           $pr{force_close_status} = 1;
       }

       if ($prs_info{$key}{Fix_Resulting_State} =~ /^Fixed/) {
           $pr{fix_date} = &UnixDate("$prs_info{$key}{Fix_Date}","%a %b %e %H:%M:%S %Z %Y"); 
           $pr{fix_by} = $prs_info{$key}{Fixed_By_User};
           $pr{fix_version} = $prs_info{$key}{Fix_Version};
           $pr{fix_resolution} = $prs_info{$key}{Fix_Resolution};
           $pr{fix_affects_doc} = $prs_info{$key}{Fix_Affects_Documentation};
           $pr{fix_notes} = $prs_info{$key}{Fix_Notes};
           $pr{fix_status} = 1;
           $pr{fix} = $pr{fix_resolution};
       }

       if ($prs_info{$key}{Verify_Resulting_State} eq "Closed") {
           $pr{verify_date} = &UnixDate("$prs_info{$key}{Verify_Date}","%a %b %e %H:%M:%S %Z %Y"); 
           $pr{verify_by} = $prs_info{$key}{Force_Close_By_User};
           $pr{verify_version} = $prs_info{$key}{Verify_Version};
           $pr{verify_notes} = $prs_info{$key}{Verify_Notes};
           $pr{verify_status} = 1;
       }
     
       $pr{found_date} = &UnixDate("$prs_info{$key}{Date_Found}","%a %b %e %H:%M:%S %Z %Y");
       $pr{found_by} = $prs_info{$key}{Found_by};

# The rest of the fields
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
       }
       if ($pr{re_assigned_status}) {
           $pr{audit_trail} .= "Responsible-Changed-By: $pr{re_assigned_by}\n";
           $pr{audit_trail} .= "Responsible-Changed-When: $pr{re_assigned_date}\n";
           $pr{audit_trail} .= "Responsible-Changed-From-To: $pr{assigned_to}->$pr{re_assigned_to}\n";
       }
       if ($pr{fix_status}) {
           $pr{audit_trail} .= "Fixed-By: $pr{fix_by}\n";
           $pr{audit_trail} .= "Fixed-When: $pr{fix_date}\n";
           $pr{audit_trail} .= "Fix-Resolution: $pr{fix_resolution}\n";
           $pr{audit_trail} .= "Fix-Affects-Doc: $pr{fix_affects_doc}\n";
           $pr{audit_trail} .= "Fix-Version: $pr{fix_version}\n";
           $pr{audit_trail} .= "Fix-Notes: $pr{fix_notes}\n";
       }

       if ($pr{force_close_status}) {
           $pr{audit_trail} .= "Force-close-By: $pr{force_close_by}\n";
           $pr{audit_trail} .= "Force-close-When: $pr{closed_date}\n";
           $pr{audit_trail} .= "Forced-close-Reason:\n";
           $pr{audit_trail} .= "$prs_info{$key}{Force_Close_Notes}\n";
           $pr{audit_trail} .= "$prs_info{$key}{Force_Close_Resolution}\n";
       }

       if ($pr{verify_status}) {
           $pr{audit_trail} .= "Verify-By: $pr{verify_by}\n";
           $pr{audit_trail} .= "Verify-When: $pr{verify_date}\n";
           $pr{audit_trail} .= "Verify-Version: $pr{verify_version}\n";
           $pr{audit_trail} .= "Verify-Notes: $pr{verify_notes}\n";
       }

       print "finish all field, testing\n";
# If for some reason the responsible person did not get set, we'll set it to the person
# that created the ticket
      if (!exists $pr{responsible}) {
          $pr{responsible} = $responsible_lookup{$prs_info{$key}{Created_By}};
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

       }

       print "done - creating file\n";
# Dumping out PR files
open(OUTFILE,"> $db_dir/$pr{category}/$pr{pr_number}") or die "Can't create PR $db_dir/$pr{category}/$pr{pr_number}: $!\n";
print OUTFILE "From: $pr{originator}
Reply-To: $pr{originator}
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
>Reproduced:     reproduce-always
>Reproduced-Steps:
None
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
        print "done creating file\n";
        if ($report) {
            print LF "File $db_dir/$pr{category}/$pr{pr_number} created\n";
        }
#       print Dumper(\%pr);
#        print "$pr{category}\n";
    } 
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
        system("mailx -s \"TTP GNATS Conversion Log\" $notify_list < $log_file");
    }
} # close for main
