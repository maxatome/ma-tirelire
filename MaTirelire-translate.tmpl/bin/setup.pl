#!/usr/bin/perl
# 
# setup.pl -- 
# 
# Author          : Max Root
# Created On      : Sun Dec 16 12:08:50 2001
# Last Modified By: 
# Last Modified On: 
# Update Count    : 0
# Status          : Unknown, Use with caution!
#

#
# Language choice...
print "\n\nWelcome to the MaTirelire 2 translator setup.\n";
print "Enter the new language you will translate Ma Tirelire 2 to:\n";
my $LANG;
do
{
    print "(2 letters, example: it for italian, de for german...) -> ";
    chop($LANG = <STDIN>);
}
while ($LANG !~ /^[a-z]{2}$/i);

$LANG = lc $LANG;

my @FONTS = ([ "Standard latin font",		''     ],
	     [ "Big5 Chinese font",		'-F5 -noEllipsis'  ],
	     [ "Korean font (hantip font)",	'-Fkt -noEllipsis' ],
	     [ "Korean font (hanme font)",	'-Fkm -noEllipsis' ],
	     [ "Japanese font",			'-Fj -noEllipsis'  ],
	     [ "Hebrew font",			'-Fh -noEllipsis'  ],
	     [ "Cyrillic font",			'-Fc -noEllipsis'  ]);

my $FONT;
do
{
    print "\nWhat font do your Palm use?\n";

    for (my $index = 0; $index < @FONTS; $index++)
    {
	printf " %d. $FONTS[$index][0]", $index + 1;
	print " (if you don't know choose this)" if $FONTS[$index][1] eq '';
	print "\n";
    }

    printf "Type a number from 1 to %d -> ", scalar @FONTS;
    chop($FONT = <STDIN>);
}
while ($FONT !~ /^\d\z/ or $FONT == 0 or $FONT > 7);

$FONT--;

print "\nYou choose language $LANG with $FONTS[$FONT][0].\n";

$FONT = $FONTS[$FONT][1];	# Font parameter...

undef $/;


#
# Compilator batch...
my $COMPILE = "compile.bat";
open(COMPILE, "bin/$COMPILE") || die "Can't open bin/$COMPILE: $!\n";
my $contents = <COMPILE>;
close COMPILE;

$contents =~ s/LANG/$LANG/g;
$contents =~ s/FONT/$FONT/g;

open(COMPILE, ">$COMPILE") || die "Can't write $COMPILE: $!\n";
print COMPILE $contents;
close COMPILE;


#
# Language specific file, to modify later...
my $sample = (-e "samples/obj-$LANG.rcp") ? $LANG : 'en';

open(RCP, "samples/obj-$sample.rcp") 
    || die "Can't open samples/obj-$sample.rcp: $!\n";
my $rcp = <RCP>;
close RCP;

$rcp =~ s/TRANSLATION "[-\w]+"/TRANSLATION "\U$LANG\E"/;

open(RCP, ">obj-$LANG.rcp")
    || die "Can't write obj-$LANG.rcp: $!\n";
print RCP $rcp;
close RCP;


#
# That's all, after the final notice...
print <<ENDOFSETUP;

Ma Tirelire 2 translator successfully configured...

You have to modify the file obj-$LANG.rcp and translate each string
in your language.

*** Don't change the order nor the structure of this file ***
*** Only modify strings contents and position numbers     ***
*** Samples are available in samples directory...         ***

You can also validate your changes by creating a MaTirelire-$LANG.prc file
with the compile.bat command this setup has created...

Read the README file for more informations...

Good luck ;-)

Max -- info\@Ma-Tirelire.net
ENDOFSETUP

# I don't know why, but windows create a setup.pif file, delete it...
unlink 'setup.pif';
