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
#use lib "/home/jims/sf/gnatsperl/gnatsperl/code";
use Net::Gnats;
use Data::Dumper;

#$Net::Gnats::debugGnatsd = 0;

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

    my $cnt = 0;
    foreach my $prNum (@prs) {
      $cnt++;
      print "Getting PR \"$prNum\", ",$cnt," of ",$#prs,"\n";
      my $pr = $g->getPRByNumber($prNum);
      if ($pr) {
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

    print "Disconnecting\n";
    $g->disconnect();
}
