#!/nextgen/gnu/bin/perl

#$command=`find /u5/smokkapa/ -name ".cshrc" -print`;
#@ARGS=split(/\n/, $command);

print "Appending, Replacing string/line? or Deleting line? [a, r, d, quit]: ";
chomp($option=<STDIN>);


 if ($option =~ /^a/i) {
	print "Find Files? or Use a Previous find? [f, p]: ";
	chomp($choice=<STDIN>); 
	@ARGS=&find_file($choice);
 	print "Enter line to be appended: ";
	$line=<STDIN>;
	&proc_append($line,@ARGS);
 }elsif ($option =~ /^d/i) {
	($pattern)= &get_opt($option);
	print "Find Files? or Use a Previous find? [f, p]: ";
	chomp($choice=<STDIN>); 
	@ARGS=&find_file($choice);
	print "@ARGS \n";
	&proc_delete($pattern,@ARGS); 
 }elsif($option =~ /^r/) {
	($string1,$string2)= &get_opt($option);
	print "Find Files? or Use a Previous find? [f, p]: ";
	chomp($choice=<STDIN>); 
	@ARGS=&find_file($choice);
	print "@ARGS \n";
	&proc_replace($string1,$string2,@ARGS) ;
 } else {
	exit 0;
 }

sub find_file {

local($choice)=@_;
local($command,$f_name,@DIRS,@ARGS);
  if($choice =~ /^f/i){
  print "Directory/directories to start the search from [eg: /home /usr]: ";
  chomp($command=<STDIN>);
  print "Filename to look for [eg: .cshrc]: ";
  chomp($f_name=<STDIN>);
  @DIRS=split(/\s+/, $command);
	if(-e "/tmp/$f_name.dirs") {
	   system("rm -f /tmp/$f_name.dirs");
	}
 	foreach $dir (@DIRS) {
	   system("find $dir -name $f_name -print >> /tmp/$f_name.dirs");
	}
  open(DIRHANDLE, "/tmp/$f_name.dirs");
  chomp(@ARGS=<DIRHANDLE>);
  close(DIRHANDLE);
  return @ARGS;
  } elsif($choice =~ /^p/i) {
  print "Whats the file to use? : ";
  chomp($d_name=<STDIN>);
  open(DIRHANDLE, "$d_name");
  chomp(@ARGS=<DIRHANDLE>);
  close(DIRHANDLE);
  return @ARGS;
  }
 
}

sub get_opt {

local($option)=@_;
local($string1,$string2,$pattern);
  if($option eq "r") {
	print "Give string to search for: ";
	chomp($string1=<STDIN>);
	print "Give string to replace with: ";
	chomp($string2=<STDIN>);
	return ($string1,$string2);
   } elsif($option eq "d") {
	print "Pattern to match? : ";
	chomp($pattern=<STDIN>);
	return ($pattern);
   } 
}
	
sub proc_replace {

local($string1,$string2,@FILES)=@_;
print "inside\n";
print "@FILES\n";
	foreach $file (@FILES) {
	($uid,$gid)=(stat("$file"))[4,5];
	open(CSHRC, "<$file") || die "Can't open $file";
	@LINES=<CSHRC>;
	close(CSHRC);

# Make a backup of the current version
	print "Copying $file to $file.bak\n";
	rename($file, "$file.bak") || die "Can't create $file.bak";

&clean_bak($file);
&str_replace($file,$string1,$string2,@LINES);

# Fix the permissions
	print "Fixing Permissions on $file\n";
	chown($uid, $gid, $file) || die "Can't change ownership for the $file";
	}
}

sub proc_delete {


local($pattern,@FILES)=@_;
	foreach $file (@FILES) {
	($uid,$gid)=(stat("$file"))[4,5];
	open(CSHRC, "<$file") || die "Can't open $file";
	@LINES=<CSHRC>;
	close(CSHRC);

# Make a backup of the current version
	print "Copying $file to $file.bak\n";
	rename($file, "$file.bak") || die "Can't create $file.bak";

&clean_bak($file);
&del_lines($file,$pattern,@LINES);

# Fix the permissions
	print "Fixing Permissions on $file\n";
	chown($uid, $gid, $file) || die "Can't change ownership for the $file";
	}
}

sub proc_append {

local($line,@FILES)=@_;
local($lin);
	foreach $file (@FILES) {
	($uid,$gid)=(stat("$file"))[4,5];
# Start appending
	open(CSHRC, ">>$file") || die "Can't open $file";
	$lin=chomp($line);
	print "Appending $lin to $file";
	print CSHRC $line;
	close(CSHRC);
# Make a backup of the current version
#	print "Copying $file to $file.bak\n";
#	rename($file, "$file.bak") || die "Can't create $file.bak";


&clean_bak($file);

# Fix the permissions
	print "Fixing Permissions on $file\n";
	chown($uid, $gid, $file) || die "Can't change ownership for the $file";
	}
}

# Remove the old backups, if any	
sub clean_bak {

local($file)=@_;

	print "Looking for ${file}_bak\n";
	if ( -e "${file}_bak" ){
		unlink("${file}_bak");
	} else {
	print "${file}_bak doesn't exist\n";
	}
}

# Delete lines that match the pattern
sub del_lines {

local($file,$pattern,@LINES)=@_;
	open(CSHRC, ">$file");
		foreach $line (@LINES) {
			if ($line =~ /^.*$pattern.*$/) {
			print "Deleting $line";
			} else {
			print CSHRC $line;
			}
		}
	close(CSHRC);
}

# String Replacement using match pattern
sub str_replace {

local($file,$string1,$string2,@LINES)=@_;
	open(CSHRC, ">$file");
                foreach $line (@LINES) {
			if ($line =~ /$string1/) {
                        print "Changing ... $line";
			} 
                      	$line =~ s/$string1/$string2/; 
                        print CSHRC $line;
		}
	close(CSHRC);
}
