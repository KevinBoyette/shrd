#!/usr/bin/perl
use warnings;
use strict;

use Time::HiRes;
use Data::Dumper;

require 'db.pl';

#TODO: Clock time out implementation

#------------DEBUG----------------#
#USE: $pp_debug, integer
#E.G: 1-5 : Range in print debug information
my $pp_debug = 0;
if ($application::glob_debug > $pp_debug)
	{$pp_debug = $application::glob_debug;}
#TSK: Used by preprocessor component to print debug information

#---------------------------------#

#Local Scope Variables
our $path;

#PROCESS
#####
	#Processed each directory in the CONFIG file
	#INPUT: Name of individual directory, concatenated with $application::main_directory 
	#OUTPUT: TODO: Execution time in log
	#PROCESS: Complex, contact Kevin for details 
	#Runs wanted function for all files in directory
#####
sub process($){

	my @arr = @_;
	my $path = $arr[0];
	
	my $directory = $application::main_directory.$path."\\";
	if ($pp_debug > 0){print "Processing directory: $directory \n";}
	
	use File::Find();
	my $dropBox = $directory;
	#TODO: start time, my $programExecTime = clock();

	my $lastParsed = time() . "\n\n";

    use vars qw/*name *dir *prune/;

	*name = *File::Find::name;
	*dir = *File::Find::dir;
	*prune = *File::Find::prune;

	sub wanted;

	File::Find::find({wanted => \&wanted}, $dropBox);

    #TODO: prints execution time 
	#TODO: print ("\nExec Time: ",  clock() - $programExecTime . "\n"); 
}


#WANTED
#####
	#Reads file attributes, Gets file information for each file using filename, path and last modified, Look up pp_cfile in db.pl for details
	#INCLUDES: parse logic, see project requirements for details
	#INPUT: Complex, contact Kevin for details | see File::Find::find in sub process | Input is file 
	#OUTPUT: NONE, add files to global @application::parse_buffer is fits project requirements
	#PROCESS: Passes pp_cfile(filename, path and last modified) which returns file information, if file information matches parse 
	#requirement adds it to parse buffer
#####
sub wanted{
	my $find = "/";
    my $fileName;
	my @finfo;
	
	my $fid;
	my $flmodified;
	my $flparsed;
	
	my $mod_time = ( stat( $name) )[9];
    
    $fileName =  substr($name, rindex($name, $find)	 +1);
    my $name = substr $name, 0, rindex($name, $find);
	
	if ($name eq ($application::main_directory.$path)){
	
		#DEBUG
		if ($pp_debug > 0){
			print "\nProcessing File:\nFile Path\t$name\nFile Name\t$fileName\nLast Modified\t$mod_time \n\n";
		}
	
	@finfo = pp_cfile($fileName,$name,$mod_time);
    
		#DEBUG
		if ($pp_debug >= 5){
			print Dumper "DEBUG::wanted::pp_cfile returns [ @finfo ]";
		}
		
	}

	#*Note	@finfo : [fid, flmodified, flparsed]
	if (@finfo){
		$fid = $finfo[0];
		$flmodified = $finfo[1];
		$flparsed = $finfo[2];
		
		#DEBUG
		if ($pp_debug > 5){
			print Dumper "DEBUG::wanted::pp_cfile returns [ @finfo ]";
		}
		
		#LOGIC: Check if file has been modified since last preprocessed
		if (($flmodified < $mod_time) || ($flparsed == 0) || ($flparsed < $mod_time)){
			my $filepath = $name."/".$fileName;
			my @push_arr = [$filepath,$fid];
			push(@application::parse_buffer,@push_arr);
		}
		
		#TODO: Remove this TEMPORARY LOGIC, when Parser is fixed
		#if ($flparsed == 0){
		#	my $filepath = $name."/".$fileName;
		#	my @push_arr = [$filepath,$fid];
		#	push(@application::parse_buffer,@push_arr);
		#}
		
		@finfo = "";
		
	}
	
	return 0;
}

#gatherDirectories
#####
	#No functional use, see Kevin
#####
sub gatherDirectories(){
    my $entry;
    my @dirArray;

    opendir(DIR, '.');
    while($entry = readdir DIR) {
        next if ($entry eq "." or $entry eq "..");
        push (@dirArray, $entry) if (-d $entry);
    }
    return @dirArray;
}

#WANTED
#####
	#Read each line of CONFIG file, See requirements
	#INPUT: uses global $application::main_directory from application.pl 
	#OUTPUT: NONE
	#PROCESS: pass directory name from CONFIG to sub process
#####
sub read_config(){
	
	my $config = $application::main_directory."CONFIG";
	open FILE, $config or die "Can't find CONFIG file";
	while (<FILE>) {
		my $char = $_;
		chomp $char;
		if ($char ne ''){
			$path = $char;
			process($char);
		}
	}
	
	return 0;
}

1;
