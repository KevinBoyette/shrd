#!/usr/bin/perl
#use strict;
use warnings;
use Data::Dumper;

#------------DEBUG----------------#
#USE: $s_debug, integer
#E.G: 1-5 : Range in print debug information
my $s_debug = 2	;
if ($application::glob_debug > $s_debug)
	{$s_debug = $application::glob_debug;}
#TSK: Used by Search Function component to print debug information

#---------------------------------#

my @line;

#IO_QUERY
#####
	#Input and Output for query 
	#INPUT: user file (see $application::queryX | application.pl)
	#OUTPUT: intersection of files for each query words
	#PROCESS: Looks up search function for each line of query from user file
#####
sub io_query($){
	my @arr = @_;
	my $filename = $arr[0];
	my $outfile = $arr[1];
	
	open FILE, $filename or die "Error opening file $filename"; #TODO: Don't die
	
	unlink($outfile);
	open (OUTFILE, '>>', $outfile); 
	
	if ($s_debug >= 5){print "\nDEBUG::io_query::input - $filename \n";}
	
	while (<FILE>) {
		my @fileinfo;
		my @query_result;
		@line = split("\t",$_);
		my $queryid = $line[0];
		@query_result = search($line[0],$line[1]);
		
		my $ctime = time;
		if ($s_debug >= 5){print "\n\nDEBUG::io_query::output - $filename -> $outfile\n";}
		print OUTFILE "\n\n$filename\t$queryid\t$ctime\n\t";
		if ($s_debug >= 2){print "\n\n$filename\t$queryid\t$ctime\n";}
		foreach my $element(@query_result){
			my @file_info = sf_cfile($element);
			#print Dumper @file_info;
			my $path = $file_info[0];
			if ($path){
			my $local_path = $application::main_directory;
			$path =~ s/\Q$local_path\E//g; 
			}
			my $fname = $file_info[1];
			my $lpp = $file_info[2];
			
			if ($lpp){
				my $time_lpp = time - $lpp;
				if ($time_lpp < 60){
					print OUTFILE "$path\\$fname ";
					if ($s_debug >= 2){print "$path\\$fname\n";}
				}
			}
			
		}
		if ($time_lpp){
		print OUTFILE "\t$time_lpp\n";
		if ($s_debug >= 2){print "\n\t$time_lpp\n\n";}
		}
	}
	
	
	close (FILE);
	close (OUTFILE);
	return 0;
}

#SEARCH
#####
	#Search files for each query words, and return intersected arrays 
	#INPUT: query id, query words
	#OUTPUT: array of intersection of files for each query words for each query 
	#PROCESS: Looks up word id for each word and if exists looks up file id for each word and intersects them with other words info
#####
sub search($$){
	my $query = $line[1];
	
	my $word;
	my @file_word;
	
	#Splitting query into query words
		my @char = split(" ",$query);
		
		for my $char(@char){
			$char =~ s/(\.)*(\d)*(\,)*//g;
			$char = lc $char;
			my @file_array = sf_cword($char);
				#if ($s_debug > 5){print Dumper "DEBUG::search files for $char - [ @file_array ] \n"};
			
			if (@file_array){
				#TODO: push (@file_word,@file_array);
				#if (!$file_array[1]){
				#	next;
				#}
				push(@file_word, \@file_array);
			}
		}
	
	my $word_count = @char;
	my $file_count = @file_word;
	
	if ($s_debug > 5){print "Number of words in \"@char\": $word_count \n Numer of files $file_count\n"};
	if ($s_debug > 5){print "DEBUG::search::\@file_word: \n";}
	if ($s_debug > 5){print Dumper @file_word;}
	#TODO: return output
	
	my @query_result;
	
	if ($file_count > 1){
		my $arr_inst = intersection_complex(@file_word);
		@query_result = @$arr_inst;
	} 
	elsif ($file_count == 1){
		foreach (@file_word){
			push(@query_result,@$_);
		}
	}
	
	return @query_result;
}

sub intersection_complex{
	my $current_intersection = shift;
	
	#my $sizeof_array = @$current_intersection;
	while (@_){
		$current_intersection = intersection($current_intersection, shift);
	}
	
	return $current_intersection;
}

sub intersection{
	my ($arr_a, $arr_b) = @_;
	my @ist_array;
	
	foreach my $element(@$arr_a){
		foreach my $element_a (@$arr_b){
			if ($element == $element_a){
				push (@ist_array,$element);
			}
		}
	}

	return \@ist_array;
}

1;