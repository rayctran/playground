#!/usr/local/bin/perl
#######################
#######################
### Name: prtck.pl
### Author: Ray Tran
### Date: 06/16/1999
### Purpose: Checks a few used printer queues and 
### troubleshoot it if necessary
### Usage: prtck.pl
### Parameter
###
### Restriction
### required perl in /usr/local/bin
###
### Modification history
### Author:
### Date:
### Purpose:
###
###
#######################
@Printers=(prt1e12,prt2e45)
$LPQ="/usr/ucb/lpq -P"
$TMPDIR="/adm/tmp"
