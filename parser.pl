#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

require 'db.pl';

#TODO: implement exception, DO NOT run if parse_buffer is empty
#TODO: implement execution from preprocessor
#requires use of parse buffer our @parse_buffer = (["path/filename1",file id],["path/filename2",file id]); 

#------------DEBUG----------------#
#USE: $p_debug, integer
#E.G: 1-5 : Range in print debug information
my $p_debug = 10;
if ($application::glob_debug > $p_debug)
	{$p_debug = $application::glob_debug;}
#TSK: Used by parser component to print debug information

#---------------------------------#

#Local Variables
my $word;

sub parser{
	while (@application::parse_buffer){
		my $filename =  $application::parse_buffer[0][0];
		my $fid 	 =  $application::parse_buffer[0][1];
		
		if ($p_debug > 0){print "\n Parsing file name | file id: $filename, $fid\n"};
		
		#open FILE, $filename or {logfile($filename); next;};
		my $file_read = open(FILE,"<",$filename);
		if (!$file_read){
			print "Error Opening File $filename";
			shift @application::parse_buffer;
			next;
		}
		#"Error opening file $filename"; #TODO: Don't die
		
		#Get list of words (low) from parse table
		my @low = parser_low($fid);
			if ($p_debug >=5){print Dumper "DEBUG::parser:\@low pre_parse: [ @low ]\n\n";}
			if ($p_debug > 5) {print "DEBUG::parser:: Words in File \n---------------------------------\n";}
		
		#Split each line into characters and convert them to word with use of space
		while (<FILE>) {
			my @char = split //;
			for my $char(@char){
				$char =~ s/(\.)*(\d)*(\,)*//g;
				if ($char eq " "){
					#If $word is not empty
					if ($word ne ""){
						$word = lc $word;
						#Get word id, compare it with LOW:list of words and erase if they match
						my $wif = parser_cword($word, $fid);
						if ($wif != 0){
								if ($p_debug > 5) {print "$wif, $word\t";}
							my $i = 0;
							foreach my $item(@low){
								if ($item == $wif) {splice(@low, $i, 1);}
								$i++;
							}
						}
						$word = "";
					}
				}
				else {
					if ($char ne ""){$word = $word.$char;}
				}
			}
		$word = "";
		}
		
		
		if ($p_debug > 5){print "\n---------------------------------\n";}
		if ($p_debug >=5){print Dumper "\nDEBUG::parser:\@low post_parse: [ @low ]\n\n";}
		
		#Delete all remaining words from link table
		foreach my $id(@low){
			parse_delete($id,$fid);
		}
		
		#Update files database with new parsed date
		parse_updatefile($fid);
		
		#Reset @low
		@low = "";
		
		#Removing file from parse buffer after parse is completed
		shift @application::parse_buffer;	
		
		if ($p_debug >=5){print "DEBUG::\@applicaion::parse_buffer post parse: \n-- \n";}
		if ($p_debug >=5){print Dumper \@application::parse_buffer;}
		if ($p_debug >=5){print "--\n";}
	}
}


1;