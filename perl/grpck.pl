#!/usr/local/bin/perl
$|++;

$group = '';
$error = '';
open(GRPCK,"/usr/sbin/grpck /var/adm/security/yooper/etc/group 2>&1 |");
for(<GRPCK>) {
  chop;
  if($_ eq '') {
    $group = '';
    next;
  }
  if($group eq '') {
    ($group) = split(':',$_);
    next;
  }
  s/^\t//;
  if($_ eq "Group name too long") {
    push(@too_long, $group);
  } elsif($_ eq "1 Bad character(s) in group name") {
    push(@bad_char, $group);
  } else {
    print "$_\n\t$group\n\n";
  }
}
close(GRPCK);

print "Group name too long\n";
for(@too_long) {
  print "\t$_\n";
}
print "\n";

print "1 Bad character(s) in group name\n";
for(@bad_char) {
  print "\t$_\n";
}
print "\n";

open(GROUP,"/var/adm/security/yooper/etc/group");
for(<GROUP>) {
  chop;
  local($gname,$gpass,$gid,$gmem) = split(':',$_);
  local(@members) = split(',',$gmem);
  foreach $mem (@members) {
    $gcount{$mem}++;
  }
}
close(GROUP);

print "User in more than 14 secondary groups\n";
for(keys(%gcount)) {
  if($gcount{$_} > 14) {
    print "\t$gcount{$_}\t$_\n";
  }
}
