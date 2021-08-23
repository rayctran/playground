#!/tools/perl/5.6.0/SunOS/bin/perl -w

use strict;
use Date::Manip;


my ($category, $pr_number, $from, $synopsis, $severity, $priority, $responsible, $state, $class,$arrival_date, $originator);
my ($organization, $description, $audit_trail, $reproduced, $test_config, $workflow, $reference_no);
my $db_dir = "/tools/gnatsQA/4.0/share/gnats/db-zyray-qa";
my $kaka_date = "03/31/2004";
$arrival_date = &UnixDate($kaka_date,"%a %b %e %H:%M:%S %Z %Y");
$pr_number = "6";
$category = "Tools-Sting_Ray";
$originator = "raytran";
$synopsis = "Testing from script";
$severity = "cosmetic";
$priority = "low";
$responsible = "raytran";
$organization = "IT";
$description = "This is the description line 1\nThis is line 2\n";

open(OUTFILE,"> $db_dir/$category/$pr_number") or die "Can't create PR $pr_number: $!\n";
print OUTFILE "From: $originator\@broadcom.com
Reply-To: $originator\@broadcom.com
To: bugs
Cc:
Subject: $synopsis
X-Send-Pr-Version: gnatsweb-4.00 (1.41)
X-GNATS-Notify:

>Number:         $pr_number
>Notify-List:
>Category:       $category
>Synopsis:       $synopsis
>Confidential:   no
>Severity:       $severity
>Priority:       $priority
>Responsible:    $responsible
>State:          open
>Keywords:
>Date-Required:
>Class:          Layer1FW
>Submitter-Id:   broadcom-zyray-qa
>Arrival-Date:   $arrival_date
>Closed-Date:
>Last-Modified:
>Originator:     raytran (Ray Tran)
>Organization:
$organization
>Environment:
None
>Description:
$description
>Reproduced:     reproduce-always
>Fix:
Unknown
>Workaround:
>Cloned-from:
>Cloned-to:
>Audit-Trail:
>Unformatted:
";
close(OUTFILE);

system("rm $db_dir/gnats-adm/index");
system("cd $db_dir/gnats-adm;/tools/bin/make index");
