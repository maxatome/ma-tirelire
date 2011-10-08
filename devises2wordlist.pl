#!/usr/local/bin/perl -w
# 
# devises2hex.pl -- 
# 
# Author          : Maxime Soule
# Created On      : Thu Jun  3 14:42:02 2004
# Last Modified By: Maxime Soule
# Last Modified On: Thu Jun  3 17:45:06 2004
# Update Count    : 26
# Status          : Unknown, Use with caution!
#

use strict;

# Largeur des caractères pour la fonte standard (pris de char_width.pl)
my @std = (5, 5, 5, 5, 5, 5, 5, 5, 5, 2, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
           11, 5, 8, 8, 6, 5, 5, 5, 5, 5, 5, 5, 2, 2, 4, 8, 6, 8, 7,
           2, 4, 4, 6, 6, 3, 4, 2, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 2,
           3, 6, 6, 6, 5, 8, 5, 5, 5, 6, 4, 4, 6, 6, 2, 4, 6, 5, 8, 6,
           7, 5, 7, 5, 5, 6, 6, 6, 8, 6, 6, 6, 3, 5, 3, 6, 4, 3, 5, 5,
           4, 5, 5, 4, 5, 5, 2, 3, 5, 2, 8, 5, 5, 5, 5, 4, 4, 4, 5, 5,
           6, 6, 6, 4, 4, 2, 4, 7, 5, 8, 5, 3, 8, 5, 6, 6, 6, 4, 11,
           5, 4, 8, 10, 10, 10, 10, 3, 3, 5, 5, 4, 4, 7, 7, 10, 4, 4,
           8, 5, 5, 6, 2, 2, 6, 6, 8, 6, 2, 5, 4, 8, 5, 6, 6, 4, 8, 6,
           5, 6, 4, 4, 3, 5, 6, 2, 4, 2, 5, 6, 8, 8, 8, 5, 5, 5, 5, 5,
           5, 5, 7, 5, 4, 4, 4, 4, 3, 2, 3, 3, 7, 6, 7, 7, 7, 7, 7, 5,
           8, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 8, 4, 5, 5, 5, 5,
           2, 2, 3, 3, 5, 5, 5, 5, 5, 5, 5, 6, 7, 5, 5, 5, 5, 6, 5,
           6);

# Pris sur http://www.xe.com/iso4217.htm + anciennes monnaies européennes
my @DEVISES = qw(FRF BEF ATS DEM ESP FIM IEP ITL LUF NLG PTE GRD

		 AED AFA ALL AMD ANG AOA ARS AUD AWG AZM BAM BBD BDT
		 BGN BHD BIF BMD BND BOB BRL BSD BTN BWP BYR BZD CAD
		 CDF CHF CLP CNY COP CRC CSD CUP CVE CYP CZK DJF DKK
		 DOP DZD EEK EGP ERN ETB EUR FJD FKP GBP GEL GGP GHC
		 GIP GMD GNF GTQ GYD HKD HNL HRK HTG HUF IDR ILS IMP
		 INR IQD IRR ISK JEP JMD JOD JPY KES KGS KHR KMF KPW
		 KRW KWD KYD KZT LAK LBP LKR LRD LSL LTL LVL LYD MAD
		 MDL MGA MKD MMK MNT MOP MRO MTL MUR MVR MWK MXN MYR
		 MZM NAD NGN NIO NOK NPR NZD OMR PAB PEN PGK PHP PKR
		 PLN PYG QAR ROL RUR RWF SAR SBD SCR SDD SEK SGD SHP
		 SIT SKK SLL SOS SPL SRD STD SVC SYP SZL THB TJS TMM
		 TND TOP TRL TTD TVD TWD TZS UAH UGX USD UYU UZS VEB
		 VND VUV WST XAF XAG XAU XCD XDR XOF XPD XPF XPT YER
		 ZAR ZMK ZWD); # ))

  print <<EOF;
WORDLIST ID wlstIso4217
BEGIN
EOF

# On calcule la largeur maxi en pixel des noms
my @largest = (0) x 26;
foreach my $devise (@DEVISES)
{
    my($first, $second, $third) = unpack('CCC', $devise);
    my $width = $std[$first] + $std[$second] + $std[$third];

    $largest[$first - 65] = $width if $width > $largest[$first - 65];
}

# Les largeurs
print "    // Largest width for each letter (from A to Z)\n";
print "    ", join(" ", @largest[0 .. 12]), "\n";
print "    ", join(" ", @largest[13 .. $#largest]), "\n\n";

print "    // Each currency...\n";
my $index = 0;
foreach my $devise (sort @DEVISES)
{
    print "    " if $index % 10 == 0;

    my($first, $second, $third) = unpack('CCC', $devise);

    $first  -= 65;		# 'A'
    $second -= 65;
    $third  -= 65;

    printf "%5d ", ($first << 10) | ($second << 5) | $third;

    print "\n" if ++$index % 10 == 0
}

print "\nEND\n";
