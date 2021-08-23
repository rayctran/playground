#!/usr/local/bin/perl-ARS

use ARS;
use CGI;
use Time::ParseDate;
use Time::CTime;
use Data::Dumper;
use strict;

my (%AppConfig,%remedy,$query,%fields_name_value,$ticket,$ctrl);

$AppConfig{myuser}="raytran";

sub sort_by_caseid {

   my (%entry_a,%entry_b,$aa,$bb);
   %entry_a = ars_GetEntry($remedy{ctrl}, $remedy{schema}, $a);
   %entry_b = ars_GetEntry($remedy{ctrl}, $remedy{schema}, $b);
   $aa = $entry_a{$fields_name_value{'Case ID+'}};
   $bb = $entry_b{$fields_name_value{'Case ID+'}};
   $aa cmp $bb
}

my $q = new CGI;

my %remedy;
$remedy{server}      = $q->param('server') || 'remedy.broadcom.com';
$remedy{user}        = $q->param('user') || 'arweb';
$remedy{password}    = $q->param('password') || 'arweb';
$remedy{schema}      = $q->param('schema') || 'HPD:HelpDesk';

$ctrl = ars_Login($remedy{server}, $remedy{user}, $remedy{password});

my %fields_name_value = ars_GetFieldTable($ctrl, $remedy{schema});

#$query="'Group+' = \"SCM L2\" AND 'Status' < \"Resolved\" AND  'Case Type' != 2 AND ( 'Due Date' = NULL OR 'Due Date' < \"$AppConfig{duedate_time}\" ) ";

#$query="'Category' = \"SCM\" AND 'Status' < \"Resolved\" AND 'Item' = \"Account Disable\" AND 'Type' = \"ClearQuest\" ";
#$query="'Category' = \"SCM\" AND 'Status' < \"Resolved\" AND 'Item' = \"Account Disable\" ";
$query="'Category' = \"SCM\" AND 'Case Type' != \"Project\" AND 'Status' != \"Resolved\" AND 'Status' != \"Closed\" ";

#$query="'Assignee Login Name' = \"$AppConfig{myuser}\" AND 'Status' < \"Resolved\" AND 'Type' = \"ClearQuest\" AND 'Item' = \"Account Disable\"";

#$query="'Case ID' = \"HD0000001590465\"";
$query="'Case ID' = \"HD0000000872331\"";
#$query="'Category' = \"SCM\" AND 'Due Date Ever Expired?' = \"Yes\"";
#$query="'Category' = \"SCM\" AND 'Due Date Ever Expired?' = \"Yes\"";

print "ran query\n";
my %entries = ars_GetListEntry($ctrl, $remedy{schema}, ars_LoadQualifier($ctrl, $remedy{schema}, $query), 0);
print Dumper(%entries);

my ($ticket, $expired, $duedatemoved);
for my $t (sort sort_by_caseid keys %entries) {
   my %entry = ars_GetEntry($ctrl, $remedy{schema}, $t);
   $ticket=$entry{$fields_name_value{'Case ID+'}};
   $expired=$entry{$fields_name_value{'Due Date Ever Expired?'}};
   $duedatemoved=$entry{$fields_name_value{'Due Date Changes'}};
   print "$ticket - expired $expired, due date changes - $duedatemoved\n";
}
