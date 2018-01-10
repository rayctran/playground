#!/usr/bin/perl -w

use Data::Dumper;
use Date::Manip;
use Date::Calc qw(Week_Number);;
use Excel::Writer::XLSX;
use strict;

my ($file, $outfile, $logfile, @resources, $current_resource, $outline, $project, $totalproj_found);
my (%proj, @current_line, @current_data, $proj_name_tag, $current_proj_name);
my ($date, $billablehr, $nonbillablehr,$totalhr, $year,$month,$week,$day, $date_entry_found, $entries_in);
my (@time_entry_list);

$file = "/home/rtran/projectdetailraw.txt";
$outfile = "/home/rtran/resourcetoprojecttime.txt";
$logfile = "/home/rtran/bin/projectscript.log";
@resources = ("Ray Tran", "Darius McCaskey", "Joe Whiteaker", "Robert Grizzell", "Ben Vaughan");

open(FILE,"$file") or die "Can't read file $file:$!. Please try again\n";
open(LOGFILE,">$logfile") or die "cant' open file $logfile:$!\n";
#open(OUTFILE,">$outfile");
%proj = ();
while (<FILE>) {
    chomp;
    s/#.*//;                # no comments
    s/^\s+//;               # no leading white
    s/\s+$//;               # no trailing white
#    next unless length;     # anything left?
#    next if /^\,+^Date|^Notes/;
    next if /^,+|^Date|^Notes|^Resource|^\s*$/;
#    print "current line is $_\n";
    if (/Notes:/ .. /,,,,,,,$/) {
        print;
	next if /Notes/ || /,+$/;
    }
    my @fields = split ',', $_;
    if ($fields[0] =~ /^Project Name:/) {
# reset project array
        my ($tag, $value) = split(/\s*:\s*/, $fields[0], 2);
# initialize project array
#	$proj{$value} = [];
#	print "$value\n";
	$current_proj_name = $value;
#	print "$current_proj_name\n";
	$proj{$current_proj_name} = [];
	$totalproj_found += 1;
        print LOGFILE "Current project is $current_proj_name\n";
    }
#   if ("@resources" =~ /$fields[0]/) {
    if ( grep ( /$fields[0]/, @resources) ) {
        $current_resource = $fields[0];
#        print "Current resource is $current_resource\n";
#	$resourceperproj += 1;
    }
    if ($fields[0] =~ /^[0-9][0-9]\/[0-9][0-9]\/2016/) {
	$date_entry_found += 1;
#        print "Current date line is $current_resource,$_\n";
	($year, $month, $day) = UnixDate($fields[0], "%Y", "%m", "%d");
#	print "Year = $year, Month = $month, Day = $day\n";
       	$week = Week_Number($year, $month, $day);
       	$date = $fields[0];
       	$project = $fields[2];
       	$billablehr = $fields[4];
       	$nonbillablehr = $fields[5];
       	$totalhr = $fields[8];
#	$outline = "$current_resource,$_,$year,$month,$week,$day\n";
#        print $outline;
#        print "$current_proj_name\n";
    	$outline = "$current_proj_name,$current_resource,$date,$project,$billablehr,$nonbillablehr,$totalhr,$year,$month,$week,$day\n";
	@current_data = ( $current_proj_name,$current_resource,$date,$project,$billablehr,$nonbillablehr,$totalhr,$year,$month,$week,$day);
	push @time_entry_list, [ @current_data ];
# print Dumper @current_data;
    	print LOGFILE "outline is - $outline";
	$proj{$current_proj_name} = [ @current_data ];
        next;
    }
}

#print "Proj dumper line start here\n";
#print Dumper @time_entry_list;
#print Dumper %proj;
#my $keys = keys(%proj);
#print "keys = $keys\n";


# create excel file
my $workbook = Excel::Writer::XLSX->new( '/home/rtran/resourceprojectmap.xlsx' );
my $worksheet = $workbook->add_worksheet( 'Data' );
my $date_format = $workbook->add_format( num_format => 'dd/mm/yyyy' );
my $time_entry_format = $workbook->add_format( num_format => '00.00' );
my $fourno_format = $workbook->add_format( num_format => '0000' );
my $twono_format = $workbook->add_format( num_format => '00' );
my $row = 1;

my ($proj_name, $time_log, $no_of_proj, $no_of_timelog, $log_item, $entry_line);

# This section using the array of lists
#foreach $proj_name ( sort keys %proj ) {
#    print "Working on project $proj_name\n";
#    $no_of_proj += 1;
#    foreach $time_log ( 0 .. $#{ $proj{$proj_name} } ) {
#        $no_of_timelog += 1;
#        $worksheet->write($row, $time_log, $proj{$proj_name}[$time_log]);        
#    }
#    $row += 1;
#}

# This section using the list of lists
for $time_log ( 0 ... $#time_entry_list ) {
    $entry_line = $time_entry_list[$time_log];
    $no_of_timelog += 1;
    foreach $log_item ( 0 .. $#{$entry_line} ) {
#         print "$row, $log_item,$entry_line->[$log_item]\n";
        $worksheet->write($row, $log_item,$entry_line->[$log_item]);
    }
    $row += 1;

}


print "Total number of time entry found is $date_entry_found\n";
print "Total number of time entry dumped to excel is $no_of_timelog\n";

#    print OUTFILE $outline;
#    if ($outline) {
#	$worksheet->write($row, 0, $current_resource);
#	$worksheet->write($row, 1, $date, $date_format);
#	$worksheet->write($row, 2, $project);
#	$worksheet->write($row, 3, $billablehr);
#	$worksheet->write($row, 4, $nonbillablehr);
#	$worksheet->write($row, 5, $totalhr);
#	$worksheet->write($row, 6, $year, $fourno_format);
#	$worksheet->write($row, 7, $month, $twono_format);
#	$worksheet->write($row, 8, $week, $twono_format);
#	$worksheet->write($row, 9, $day, $twono_format);
#	$outline = "";	
#	$row += 1;
#    }

close (FILE);
close (LOGFILE);

