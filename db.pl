#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use Time::HiRes;
use Data::Dumper;

#Global Variables
our $wordinfile;
our $fileID;

#------------DEBUG----------------#
#USE: $db_debug, integer
#E.G: 1-5 : Range in print debug information
my $db_debug = 0;
if ($application::glob_debug > $db_debug)
	{$db_debug = $application::glob_debug;}
#TSK: Used by db component to print debug information

#---------------------------------#

#SQLite Database config
my $dbfile 		= "shrd.db";
my $dsn 		= "dbi:SQLite:dbname=$dbfile";
my $user 		= "";
my $password	= "";

#Database Handler
our $dbh;

#DATABASE MANAGEMENT
sub db_connect{
	$dbh = DBI->connect($dsn, $user, $password, {})
					or die $DBI::errstr."Error Can't connect \nEXITING\n\n";
}

sub db_disconnect{
	if ($dbh->disconnect){
		if ($db_debug > 0){print "Disconnecting Database\n\n"};
	} else {($DBI::errstr."Error Disconnecting from Database\n\n");}
}


#TABLE MANAGEMENT
#####
	#Check if Tables exists in Database
#####

sub db_ctable{
	my $sql;
	
	#Table FILES
	$sql = "
	CREATE TABLE if not exists files(
		fid				INTEGER PRIMARY KEY AUTOINCREMENT,
		fname			VARCHAR(30) NOT NULL,
		fpath			VARCHAR(30) NOT NULL,
		flparsed		INTEGER 	NULL,
		flmodified		INTEGER		NOT NULL,
		flpprocessed	INTEGER		NULL
	)";
	
	my $cf = $dbh->do($sql);
		if ($cf < 0){print $DBI::errstr;}
		else {if ($db_debug > 2){print "Table FILES exists or created\n\n";}}
	
	
	#Table WORDS
	$sql = "
	CREATE TABLE if not exists words(
		id              INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
		word            VARCHAR(40) NOT NULL
	)";	
	
	my $cw = $dbh->do($sql);
		if ($cw < 0){print $DBI::errstr;}	
		else {if ($db_debug > 2){print "Table WORDS exists or created\n\n";}}
	
	$sql = "CREATE INDEX if not exists index_word ON words (word)";
	my $index_word = $dbh->do($sql);
		if ($index_word < 0){print $DBI::errstr;}	
		else {if ($db_debug > 2){print "Table WORDS indexed\n\n";}}
	
	#Table LINK
	$sql = "
	CREATE TABLE if not exists link(
		wid            INTEGER NOT NULL,
		fid            INTEGER NOT NULL
	)";	

	my $cl = $dbh->do($sql);
		if ($cl < 0){print $DBI::errstr;}	
		else {if ($db_debug > 2){print "Table LINK exists or created\n\n";}}
}

#WORDS MANAGEMENT

#####
	#Parser checks for words in database
	#INPUT : parser_cword('word','fid')
	#Look up word index in shrd::words !exists-> add word
#####
sub parser_low($){
	my @arr = @_;
	my $fid = $arr[0];
	my $wid;
	my @listofwords;
	
	if (my $low = $dbh->prepare("SELECT `wid` FROM link WHERE `fid`= ? GROUP by `wid`")){
		
		$low->execute($fid);
		$low->bind_columns(\$wid);
		
		while ($low->fetch()){
			push @listofwords, $wid;
		}
		
	} else {return -1;}
	if ($db_debug >= 5){print "DEBUG::parser_low - @listofwords";}
	return @listofwords;
}

sub parser_cword($$){
	my @arr = @_;
	
	my $word = $arr[0];
	my $fid  = $arr[1];
	my $wid;
	my @c_link;
	my $wordinfile;
	
	if (my $cword = $dbh->prepare("SELECT `id` FROM words INDEXED BY `index_word`  WHERE `word`= ? LIMIT 1")){
		
		$cword->execute($word);
		$wordinfile = $cword->fetchrow_array;
		
		if (!!$wordinfile){
			#Check if the word id and file id is in link table
			if (my $cword = $dbh->prepare("SELECT `wid`,`fid` FROM link WHERE `wid` = ? AND `fid`=?")){
				$cword->execute($wordinfile, $fid);
				@c_link = $cword->fetchrow_array;
			} else{return -1;}
			#IF NOT: Add the word id and file id in link table
			if (!@c_link){
				if (my $cword = $dbh->prepare("INSERT INTO link(wid,fid) VALUES(?,?)")){
					$cword->execute($wordinfile, $fid);
				} else{return -1;}
			}
		}
	} else {return -1;}
	
	if (!$wordinfile){
		#Add word to the database
		if (my $cword = $dbh->prepare("INSERT INTO words(word) VALUES(?)")){
			$cword->execute($word);
		} else{return -1;}
		#Select id for the newly added word
		if (my $cword = $dbh->prepare("SELECT `id` FROM words INDEXED BY `index_word` WHERE `word` = ? LIMIT 1")){
			$cword->execute($word);
			$wid = $cword->fetchrow_array;
			$wordinfile = $wid;	
		} else{return -1;}
		#Add the word id and file id in link table
		if (my $cword = $dbh->prepare("INSERT INTO link(wid,fid) VALUES(?,?)")){
			$cword->execute($wid, $fid);
		} else{return -1;}
		
		return 0;
	}
	
	if ($db_debug >= 5){print "DEBUG::parser_cword - $wordinfile";}
	return $wordinfile;
}

sub parse_delete($$){
	my @arr = @_;
	my $wid = $arr[0];
	my $fid = $arr[1];
	if ($db_debug >= 5){print "\nDeleting $wid, $fid\n";}
	if (my $cword = $dbh->prepare("DELETE FROM link where `wid` = ? AND `fid`=?")){
		
		$cword->execute($wid,$fid);
	} else{return -1;}
	
	return 0;
}

#FILE MANAGEMENT

#####
	#parse_updatefile(file id)
	#Updates last parsed for each file after it parses
	#-------------------------------------------------
	#pp_cfile(file name, file path, file last_modified)
	#Preprocessor checks if file exists in database, 
	#if YES returns file information and updates with latest last_modified and last_preprocessed info
	#if NOT inserts file information to database and returns file information
#####
sub parse_updatefile($){
	my @arr = @_;
	my $fid = $arr[0];
	
	if(my $cfile = $dbh->prepare("UPDATE files SET `flparsed` = ? WHERE `fid` = ?")){
	
		$cfile->execute(time, $fid);
		}else {return -1;}
	
	return 0;
}

sub pp_cfile($$$){
	my @arr = @_;
	my @fileinfo;
	
	my $fname = $arr[0];
	my $fpath = $arr[1];
	my $flmodified = $arr[2];	
	
	if(my $cfile = $dbh->prepare("SELECT `fid`, `flmodified`, `flparsed` FROM files WHERE `fname` = ? AND `fpath` = ?")){
	
		$cfile->execute($fname, $fpath);
		@fileinfo = $cfile->fetchrow_array;
		
		if(my $cfilea = $dbh->prepare("UPDATE files SET flmodified = ?, flpprocessed = ? WHERE `fname` = ? AND `fpath` = ?")){
			$cfilea->execute($flmodified, time, $fname, $fpath);
		}else {return -1;}
		
	} else {return -1;}
	
	if(!@fileinfo){
		
		if(my $cfile = $dbh->prepare("INSERT INTO files (fname, fpath, flmodified, flparsed, flpprocessed) VALUES (?, ?, ?, 0, ?)")){
			$cfile->execute($fname, $fpath, $flmodified, time);
		} else {return -1;}
		
		if(my $cfile = $dbh->prepare("SELECT `fid`, `flmodified`, `flparsed` FROM files WHERE `fname` = ? AND `fpath` = ?")){
			$cfile->execute($fname, $fpath);
			@fileinfo = $cfile->fetchrow_array;
		} else {return -1;}
	}
	
	if ($db_debug >= 5){print Dumper "DEBUG::parse_cfile -[ @fileinfo ]";}
	return @fileinfo;
}

#SF MANAGEMENT

#####
	#sf_cword checks for file containing word in the database::link, returns array of file id
	#sf_cfile checks file information and returns file id, path, name and last pre_preprocessed
#####

sub sf_cword($){
	my @arr = @_;
	my $word = $arr[0];
	my @query_fid;
	my $id;
	my $fid;
	
	if(my $cword = $dbh->prepare("SELECT `id` FROM words INDEXED BY `index_word` WHERE `word` = ? LIMIT 1")){
		
		$cword->execute($word);
		$id = $cword->fetchrow_array;
		
		if ($id){
			if(my $cfile = $dbh->prepare("SELECT `fid` FROM link WHERE `wid` = ? GROUP by `fid`")){
				$cfile->execute($id);
				$cfile->bind_columns(\$fid);
				
				while ($cfile->fetch()){
					push @query_fid, $fid;
				}
			}
		}
	} else {return -1;}
	$word = "";
	
	if ($db_debug >= 5){print Dumper "DEGUBG::sf_cword -[ @query_fid ]";}
	return @query_fid;
}

sub sf_cfile($){
	my @arr = @_;
	my $file_id = $arr[0];
	
	#print $file_id;
	my @info;
	
	if (my $cfile = $dbh->prepare("SELECT `fpath`,`fname`,`flpprocessed` FROM files where `fid`=?")){
		$cfile->execute($file_id);
		@info=$cfile->fetchrow_array;
	} else {return -1;}
	
	return @info;
}
1;