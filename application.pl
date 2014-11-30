#!/usr/bin/perl

package application;


use strict;
use warnings;

#---------------------------------------------------------------------------------#
#Global Scope Variables                                                           

#USE: @application::parse_buffer, queue implementation
#E.G: array(['path/file name',file id],['path/file name',file id])
our @parse_buffer;	
#TSK: Used by Parser to parse file, and preprocessor to push files that need to be parsed	

#USE: $application::main_directory, string
#E.G: '/path/filename/'
our $main_directory = 'C:\\Users\\Ashish\\Dropbox\\ProjectData\\';
#TSK: Used by Parser and Preprocessor as root directory

#USE: $application::userX, string
#E.G: 'filename'
our $user1 = $main_directory."USER1copy";
our $user2 = $main_directory."USER2";
our $user3 = $main_directory."USER3";
our $user4 = $main_directory."USER4";
#TSK: Used by Search Function as User X input

#USE: $application::outputX, string
#E.G: 'filename'
our $output1 = "OUTPUT1";
#TSK: Used by Search Function to output query results for userX

#USE: $application::glob_debug, integer
#E.G: 1-5 : Range in print debug information
our $glob_debug = 1;
#TSK: Used by all components to print debug information

#------------------------------------#
#SHRD components
require 'preprocessor.pl';
require 'parser.pl';
require 'db.pl';
require 'search.pl';

#---------------------------------------------------------------------------------#
#Database SETUP

#Sqlite3 local database
#Reads shrd.db || Creats shrd.db 

#Start DB connection
db_connect();

#Create DB tables
db_ctable();
#---------------------------------------------------------------------------------#

sub main(){
	
	#Process ID of application.pl
	#my $pid = $$; 
	
	#Number of child $pid has created
	#my $num_child = `ps --no-headers -o pid --ppid=$pid | wc -w` - 1; 
	
	#if ($num_child == 0){	
		#execute preprocessor as a child
			read_config();
		#execute preprocessor as a child
		#execute parser as a child
			parser();
		#execute Search Function as child (user1)
			io_query($user1,$output1);
	#}
	#elsif ($num_child > 0 && $num_child < 7 ){
		#execute Search Function as child (user1)
	#}
	#else{
		#WARN Maximum number of user reached
	#}
}

main();

#Disconnect DB connection
db_disconnect();
1;
