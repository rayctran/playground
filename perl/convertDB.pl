#!/tools/perl/5.8.0/sun4u-5.6/bin/perl -w
#
# This script was used to fix my database.
# We changed from having 2 fields Category and Tool
# To a new Category field that contained both, since we
# now have hierarchical categories in gnatsweb :)
#
# At the same time, some database cleanup was required,
# like fixing invalid files like Submitter-Id and Class
# for old PR's.
#

use strict;
#use BCM;
use lib "/home/jims/sf/gnatsperl/gnatsperl/code";
use Net::Gnats;
use Data::Dumper;

$Net::Gnats::debugGnatsd = 0;

my $host = "gnats-irva-3.broadcom.com";
my $port = "1530";
my $db   = "Broadcom_Tools";
my $user = "jims";
my $pw   = "freeSoft";

main();

# ******************************************************
# These routines hould be added to Gnats.pm.
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

# Create a hashref from an array of arrays.
sub array2namehash {
  my $ret = {};
  foreach my $href (@_) {
    foreach my $key (keys %{$href}) {
      $ret->{$href->{name}}->{$key} = $href->{$key} if ($key ne "name")
    }
  }
  #die Dumper($ret);
  return $ret;
}

# ******************************************************

sub main{
    my $g = Net::Gnats->new($host,$port);
    print "Connecting\n";
    if (! $g->connect()) {
      die $g->getErrorMessage;
    }

    if (! $g->login($db,$user,$pw) ) {
      die $g->getErrorMessage;
    }

    my $cats       = getCategories($g);
    my $submitters = getSubmitters($g);
    my %cref = (
                bug => "sw-bug",
               );

    print "Searching for all PRs\n";
    my @prs = $g->query();
    #die Dumper(\@prs);

    # Get the categories

    my $cnt = 0;
    foreach my $prNum (@prs) {
      $cnt++;
      print "Getting PR \"$prNum\", ",$cnt," of ",$#prs,"\n";
      my $pr = $g->getPRByNumber($prNum);
      if ($pr) {
        # Get the Category and tool
        my $ocat = $pr->getField("Category");
        my $ncat = $ocat;
        $ncat ||= 'unknown'; # Default
        my $tool = $pr->getField("Tool");
        $tool ||= 'none'; # Default

        # Synopsys bought Avanti.
        $ncat = "Synopsys" if ($ncat eq "Avanti");
        # Changed this category name to remove '-'
        $tool = "GNATSConfig" if ($tool eq "GNATS-Config");
        # Concate the Category-Tool to build the new category name.
        if ($ncat ne "unknown" and $tool ne "Other" and $tool ne "none") {
          $ncat .= "-".$tool;
        }
        # Change Synthesis to DesignCompiler.
        $ncat = "Synopsys-DesignCompiler"
          if ($ncat eq "Synopsys-Synthesis");
        # Fix Some bad category/tool combinations.
        $ncat = "Magma" if ($ncat eq "Magma-Apollo");
        $ncat = "Magma-BlastFusion" if ($ncat eq "Magma-BlastFusion-BlastFusion");
        $ncat = "Magma-BlastPlan" if ($ncat eq "Magma-BlastPlan-Apollo");
        $ncat = "GNATS" if ($ncat eq "BRCM-GNATSConfig");
        $ncat = "BRCM" if ($ncat eq "BRCM-Apollo");
        # Remove Tool from test category.
        $ncat = "test" if ($ncat =~ /test\-.*/);
        die "? Error: Unknown Category \"$ncat\" for pr '$prNum'.\n" if (not defined $cats->{$ncat});
        my $t = $pr->getField("Tool");
        $t ||= 'none';
        print "Category=",$pr->getField("Category")," Tool=",$t," NewCategory=",$ncat,"\n";

        my $changes = 0;
        # Check the Submitter.
        my $submitter = $pr->getField("Submitter-Id");
        if (not defined($submitters->{$submitter})) {
          print " Change Submitter-Id from '$submitter' to 'broadcom'.\n";
          $pr->setField("Submitter-Id","broadcom");
          $changes++;
        }

        # Check the Class.
        my $class = $pr->getField("Class");
        if (defined $cref{$class}) {
          print " Change Class from '$class' to '$cref{$class}'.\n";
          $pr->setField("Class",$cref{$class});
          $changes++;
        }

        if ($ncat ne $ocat or $tool ne "none" or $changes) {
          # Set the fields and submit it.
          $pr->setField("Category",$ncat);
          $pr->setField("Tool","none");
          print " ******* Submitting...\n";
          my $st = $g->updatePR($pr);
          if (not $st) {
            die "Unable to update PR $prNum st=$st: ",$g->getErrorMessage,"\n";
          }
        } else {
          print " Skipping, since it looks correct.\n";
        }
      } else {
        warn "? Error getting PR $prNum:",$g->getErrorMessage,"\n";
      }
    }

    #    my $pr = $g->getPRByNumber("839");
#    $pr->setField("Synopsis","foo-$$");
#    $pr->setField("Keywords","goo-$$");
#    $pr->setField("Responsible","jims","mine");
#    if (not $g->updatePR($pr)) {
#      warn "Unable to update PR: ",$g->getErrorMessage,"\n";
#    }

    print "Disconnecting\n";
    $g->disconnect();
}
