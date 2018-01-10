#!/usr/bin/perl -w
use Data::Dumper;


my $files_dir=/var/www/html/files;
opendir(FILES, "$files_dir");
foreach $I (grep(/^${type}.+mdf$/,readdir(MDF))) {
        print "Processing file $I\n";
        system `mv $I /home/rtran/files`;
#        system `${BIN_DIR}/jfmerge ${CFG_DIR}/${I} ${input}.int -z"lp -d prt1e12,p" `;
}
closedir(FILES);

