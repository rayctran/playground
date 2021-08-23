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

my $host = "gnats-irva-3.broadcom.com";
my $port = "1530";
my $gnats_user = "gnats4";
my $gnats_psswd = "emsggn09";
my $date_string=`date`;
my $debug = 1;
my ($input_file);
my @files_to_read = ("CoreExport.txt","PlatformsExport.txt","BRCMexport.txt");
#my @files_to_read = ("CoreExport.txt");
#my @files_to_read = ("PlatformsExport.txt");

#if ( $#ARGV > 0 ) {
#    $input_file = $ARGV[0];
#    if (!-e "$input_file") {
#        print "$input_file does not exists. Please check the file and try again\n";
#        exit 1;
#    }
#} else {
#    print "Usage: $0 {full path to input file}\n";
#    exit 1;
#
#}

my $notify_list = "gnats4-admin\@broadcom.com";

main ();

# ******************************************************
# Stolen from Jim Searle
# These routines should be added to GNATS.pm.
#
# Create a categories hashref
sub getCategories {
  my $g = shift;
  return array2namehash($g->listCategories());
}

# Create a submitters hashref.
sub getSubmitters {
  my $g = shift;
  return array2namehash($g->listSubmitters());
}

sub getStates {
    my $g = shift;
    return array2namehash($g->listStates());
}

# Create a hashref from an array of arrays.
sub array2namehash {
  my $ret = {};
  foreach my $href (@_) {
    foreach my $key (keys %{$href}) {
      $ret->{$href->{name}}->{$key} = $href->{$key} if ($key ne "name");
    }
  }
  #die Dumper($ret);
  return $ret;
}

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
   my ($hi, %prs_info, @header, $header_cnt, @ttp_line, @ttp_line_cnt);
   my ($value,$key, %seen_cat, @ttp_categories, @ttp_fields);
   my %field_mapping = ( 
       'Summary'        => 'Synopsis',
       'Status'         => 'State',
       'Product'        => 'State',
       'Entered By'     => 'Originator',
       'Sub-system'     => 'Class',
       'Priority'       => 'Priority',
       'Severity'       => 'Severity',
       'Date Entered'   => 'Arrival-Date',
       'Reference#'     => 'Reference_Number',
       'Detail-Current' => 'Responsible',
       'Detail-Description' => 'Description',
       'Detail-Reproduced' => 'Detail-Reproduced',
       'Detail-Reproduced-Steps to reproduced' => 'How-to-Repeat',
       'Detail-Test Config' => 'Detail-Test-Config',
       'Detail-Test Config-Other Hardware and Software' => 'Environment',
       'Detail-Attachments' => 'File-Attachments',
       'Workflow' => 'Workflow',
       'Workaround' => 'Workaround',
       'Source Code' => 'Workaround',
       'Notify' => 'Notify-List',
       'History' => 'Audit-Trail',
   );
   my $line_no = 0;
   foreach my $file (@files_to_read) {
       if (!-e "./Zyray/$file") {
           print "Can't access file $file: $!\n";
       } else {
           open(INFILE, "< ./Zyray/$file") or die "Can't open file: $!\n";
           while(<INFILE>) {
               chop;
               if (/^Number/) {
                   @header = split(/\t/);
                   $header_cnt = scalar(@header);
                #   print "File $file header count is $header_cnt\n";
                  # for ( $hi=0; $hi< scalar(@header); $hi++) {
                  #     print "$header[$hi]\n";
                  # }

               } else {
                   $line_no++;
                   @ttp_line = split(/\t/);
                   #print Dumper(\@ttp_line);
                   my $ttp_line_cnt = scalar(@ttp_line);
                #   print "line $line_no count $ttp_line_cnt\n";
                   for ( $hi=0; $hi< scalar(@header); $hi++) {
                #       print "$header[$hi]=$ttp_line[$hi]\n";
                       $prs_info{$line_no}{${header[$hi]}} = $ttp_line[$hi];
                   }
               }
           }
       }
#       print Dumper(%prs_info);
        foreach $key (sort keys %prs_info) {
#            print "$key\n";
            for $value ( sort keys %{ $prs_info{$key} } ) {
                if ($prs_info{$key}{$value} != "") {
             #       print "non empty value is $prs_info{$key}{$value}\n";
                    if ( !grep {/$value/} @ttp_fields ) {
                        push (@ttp_fields,$value);
                    }
                } else {
             #       print "empty value is $prs_info{$key}{$value}\n"
                }
                if ($value = "Component") {
                    if ( !grep {/$prs_info{$key}{$value}/} @ttp_categories ) {
                        push (@ttp_categories,$prs_info{$key}{$value});
                    }
                }
            }
        } 

############
# category report
#        print "** Input File is $file\n";
#        print "Components are\n";
#        foreach $key (@ttp_categories) {
#            print "$key\n";
#        }
#        print "****************************e\n";
############
   }

# fields report
#    my %seen = ();
    print "Non-Empty Fields are\n";
    foreach $key (@ttp_fields) {
        print "$key\n";
    }
#    foreach $key (@ttp_fields) {
#        unless ($seen{$key}) {
#            $seen{$key} = 1;
#            print "$key\n";
#        }
#    }
############

    
}
