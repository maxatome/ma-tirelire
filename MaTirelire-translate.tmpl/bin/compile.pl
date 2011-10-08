#!/usr/bin/perl
# 
# compile.pl -- 
# 
# Author          : Max Root
# Created On      : Sun Apr 21 18:13:38 2002
# Last Modified By: 
# Last Modified On: 
# Update Count    : 0
# Status          : Unknown, Use with caution!
#

#
# The language must be the first parameter
# The optional pilrc parameters the next...
if (@ARGV < 1)
{
    die("usage: $0 LANGUAGE\n",
	"    examples : $0 fr\n",
	"               $0 en\n",
	"               $0 it\n",
	"               $0 de\n",
	"               $0 es\n",
	"               $0 cn -Fb5 -noEllipsis\n",
	"               ...\n");
}

my $LANG = shift;
my $FONT = join(' ', @ARGV);
my $ULANG = uc $LANG;

my $SL = ($^O && $^O !~ /win/i) ? '/' : '\\';

#
# Hide the setup.bat file if it's not done yet...
rename 'setup.bat', 'bin/setup.bat';

#
# The paths...
my $DATA = 'data';


#
# Final directory
my $RSCDIR = "$DATA${SL}rsc-$LANG";
mkdir $RSCDIR, 0777;

#
# Clean the pilrc directory
sub bins
{
    my($dir_path, $is_prefix) = @_;

    opendir(DIR, $dir_path);
    my @dirs = grep { /\.(?:bin|grc)\z/ } readdir DIR;
    closedir DIR;

    return map { "$dir_path/$_" } @dirs if $is_prefix;

    return @dirs;
}

unlink bins($RSCDIR, 1);

# Copy grc files in rsc-XX directory
undef $/;
opendir(DIR, $DATA);
foreach my $grc (grep { /\.(?:grc|out)\z/ } readdir DIR)
{
    open(GRC, "$DATA/$grc") || die "Can't open $DATA/$grc";
    binmode GRC;
    my $grc_contents = <GRC>;
    close GRC;

    open(NEWGRC, ">$RSCDIR/$grc") || die "Can't open $RSCDIR/$grc";
    binmode NEWGRC;
    print NEWGRC $grc_contents;
    close NEWGRC;
}
closedir DIR;

#
# Unlink the executable, it will be re-created below...
unlink "MaTirelire-$LANG.prc";


#
# Copy the local rcp file into data subdirectory
open(NEWRCP, ">data/MaTirelire-local.rcp") 
    || die "Can't write data/MaTirelire-local.rcp";

open(RCP, "obj-$LANG.rcp") || die "Can't open obj-$LANG.rcp: $!\n";
print NEWRCP <RCP>;
close RCP;

close NEWRCP;


my $defines = "rsc-$LANG${SL}DefinesRsc.h";
chdir 'data';
if (system("..${SL}bin${SL}perl ..${SL}bin${SL}translate.pl "
	   . "-p ..${SL}bin${SL}pilrc "
	   . "-L $ULANG $FONT -q -H $defines "
	   . "obj.rcp rsc-$LANG") == 0)
{
    # Let windows, sync its files... ;-)
    print "Syncing wait...3";
    sleep 1;
    print "\b2";
    sleep 1;
    print "\b1";
    sleep 1;
    print "\b0\n";

    # Build of MaTirelire-LANG.prc
    chdir "rsc-$LANG";
    print "Build Matirelire-$LANG.prc...\n";

    my $cmd = "..$SL..${SL}bin${SL}build-prc --backup "
	. "..$SL..${SL}MaTirelire-$LANG.prc 'MaTirelire2' MaT2 "
	. join(' ', bins('.', 0));

    system $cmd;
}
