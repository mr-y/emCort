#!/usr/bin/perl -w

### Copyright (C) 2009 Martin Ryberg and Henrik Nilsson

### This program is free software: you can redistribute it and/or modify
### it under the terms of the GNU General Public License as published by
### the Free Software Foundation, either version 3 of the License, or
### (at your option) any later version.

### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
### GNU General Public License for more details.

### You should have received a copy of the GNU General Public License
### along with this program.  If not, see <http://www.gnu.org/licenses/>.

### contact: kryberg@utk.edu

use strict;

### Modules for downloading web pages. The commands for this were found at http://www.cs.utk.edu/cs594ipm/perl/crawltut.html
use LWP::Simple;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use HTML::LinkExtor;

### Geting time for filenames
my @date=localtime(time);
if ($date[3] < 10) {$date[3] = "0" . $date[3]; }
if ($date[4] < 10) {$date[4] = "0" . $date[4]; }
$date[5]=$date[5]-100;
if ($date[5] < 10) {$date[5] = "0" . $date[5]; }
my $date= $date[3] . $date[4] . $date[5];

### seting up a browser
my $browser = LWP::UserAgent->new();
$browser->timeout(300);

my $genus= "Cortinarius"; ### Here you can change the genus of interest.
my $IISorFIS= "3"; ### 3 means both IIS and FIS. 1 means IIS. 2 means FIS.
my $ITS2option="no"; ### If you want results based on only ITS2 or not (alternatives "ITS2" or "no")

print "Contacting emerencia to download FIS and IIS of $genus.\n";
### Downloading web page                            The text below is the URL
my $request = HTTP::Request->new(GET => "http://www.emerencia.org/cgi-bin/genustofasta.cgi?genustofasta=$genus$IISorFIS&ITS2option=$ITS2option");
my $response = $browser->request($request);
#if ($response->iserror()) {printf "%s\n", $response->status_line;} ### Did not get this to work, I don't know why. Can it have something to do with what version is used. I quietly blame Mac.

my $emGenoutput = $response->content();

### Making fasta out of HTML
$emGenoutput=~ s/<.+>>/>/g;
$emGenoutput=~ s/<.+>//g;

print "   Download compleat. Trying to open file to be uppdated (updated.fst).\n";
### Open file to be uppdated. If you are not interested in keeping an unaligned fasta file uppdated you still need this file to tell what accnos you already have.
### So this file does not really have to have any sequences but just > followed by the Accno eq. >FM204730. All have to be on separate lines.
open UPDATED, "updated.fst" or &noupdatedfile;
my @unupdated=<UPDATED>;
close UPDATED or die;

### Saving the old data as backup if something goes wrong and for archiving. If in need to use the backup cp it to updated.fst
print "   Saving sequences in updated to \"archive$date\.fst\" for keeping record and back up.\n";
open UNUPDATED, ">archive$date\.fst" or die;
foreach (@unupdated) {print UNUPDATED "$_";}
close UNUPDATED or die;

### Reading the accnos that are already pressent
my $i=0;
my @oldaccnos;
foreach (@unupdated) { if ($_=~ /^>([A-Za-z0-9]+)/) { $oldaccnos[$i++]=$1; } }

### Spliting the emerencia input into an array for easier prossesing
my @temp = split /\n/, $emGenoutput;
my $j=0;
my $k=0;

### Opening the outputfiles
print "\nAdding downloaded sequences previously not present in \"updated.fst\" to this file.\n";
print "\nAlso putting the new sequences in another file (newseq$date\.fst) if you are only interested in those.\n";
open NEWSEQ, ">newseq$date\.fst" or die;
open UPDATED, ">>updated.fst" or die;
my $counter=0;

### Adding all sequences not previously present to updated.fst. Putting all new sequences in newseq[todayesdate].fst.
for ($i=0; $i<scalar @temp; $i++) { 
   if ($temp[$i] =~ /^>([A-Za-z0-9]+)/) {
      for ($k=0; $k< scalar @oldaccnos; $k++) {
         if ($1 eq $oldaccnos[$k]) {last;} ### If the accno is already present proceed without any output
         elsif ($k == (scalar @oldaccnos -1)) { ### if not even the last accno in the old file was the same as the downloaded it must be a new one

            print NEWSEQ "$temp[$i]\n";   ### printing the title of the sequence
            print UPDATED "$temp[$i]\n";
            $counter++;
            for ($j=$i+1; $j<scalar @temp; $j++) { ### starting from the row below the sequence title print the sequence
               if ($temp[$j]=~ /^>/) { last; }  ### stop printing the sequence if you have got to the next sequence
               else {
                  print NEWSEQ "$temp[$j]\n";  ### print the sequence
                  print UPDATED "$temp[$j]\n";
               }
            }
         }
      }
   }
}


close NEWSEQ or die;  ### closing output files
close UPDATED or die;

print "\n$counter sequences not previous in \"updated.fst\" were downloaded and stored\n";
print "\nAll done. Have a nice day.\n\n";
exit;

sub noupdatedfile {
   print "Could not open the file \"updated.fst\". Do you want me to create this file (Y/N): ";
   my $answer=<STDIN>;
   if ($answer=~/^[Yy]/) { 
      open UPDATED, ">updated.fst" or die;
      print UPDATED "$emGenoutput";
      close UPDATED or die;
      print "Wrote Cortinarius sequences from emerencia to \"updated.fst\".\n";
   }
   elsif ($answer=~/^[Nn]/) { print "OK, you can try to create your own file \"updated.fst\" in fasta format. It should contain at least one sequence with name starting with a letter or a number.\n";}
   else { print "You must answer either Y or N, try run the program again.\n";}
   exit;
}
