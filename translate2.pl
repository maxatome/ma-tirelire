#!/usr/local/bin/perl -w
# 
# translate2.pl -- 
# 
# Author          : Max Root
# Created On      : Tue Mar 19 20:00:01 2002
# Last Modified By: Maxime Soule
# Last Modified On: Mon Aug 11 21:27:54 2008
# Update Count    : 37
# Status          : Unknown, Use with caution!
#

use strict;

my $DEBUG = 1;
my $BETA;
my $EMULATE_INCLUDE = 1;

my @LATIN_FONT = (5, 5, 5, 5, 5, 5, 5, 5, 5, 2, 5, 5, 5, 5, 5, 5,
		  5, 5, 5, 5, 11, 5, 8, 8, 6, 5, 5, 5, 5, 5, 5, 5,
		  2, 2, 4, 8, 6, 8, 7, 2, 4, 4, 6, 6, 3, 4, 2, 5, 5,
		  5, 5, 5, 5, 5, 5, 5, 5, 5, 2, 3, 6, 6, 6, 5, 8, 5,
		  5, 5, 6, 4, 4, 6, 6, 2, 4, 6, 5, 8, 6, 7, 5, 7, 5,
		  5, 6, 6, 6, 8, 6, 6, 6, 3, 5, 3, 6, 4, 3, 5, 5, 4,
		  5, 5, 4, 5, 5, 2, 3, 5, 2, 8, 5, 5, 5, 5, 4, 4, 4,
		  5, 5, 6, 6, 6, 4, 4, 2, 4, 7, 5, 8, 5, 3, 8, 5, 6,
		  6, 6, 4, 11, 5, 4, 8, 10, 10, 10, 10, 3, 3, 5, 5,
		  4, 4, 7, 7, 10, 4, 4, 8, 5, 5, 6, 2, 2, 6, 6, 8,
		  6, 2, 5, 4, 8, 5, 6, 6, 4, 8, 6, 5, 6, 4, 4, 3, 5,
		  6, 2, 4, 2, 5, 6, 8, 8, 8, 5, 5, 5, 5, 5, 5, 5, 7,
		  5, 4, 4, 4, 4, 3, 2, 3, 3, 7, 6, 7, 7, 7, 7, 7, 5,
		  8, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 8, 4, 5,
		  5, 5, 5, 2, 2, 3, 3, 5, 5, 5, 5, 5, 5, 5, 6, 7, 5,
		  5, 5, 5, 6, 5, 6);

my %FONTS = ( # Standard latin font
	      -Flatin => \@LATIN_FONT,
	      # Big5 Chinese font
	      # See pilrc sources (font.c:IsBIG5) for explanations
	      -F5  => sub
	      {
		  my $bchar = shift;

		  if (length($bchar) > 1)
		  {
		      my($first,$second) = (ord $bchar, ord substr($bchar, 1));

		      if (($first >= 0x81 && $first <= 0xfe)
			  &&
			  (($second >= 0x40 && $second <= 0x7e)
			   || ($second >= 0xa1 && $second <= 0xfe)))
		      {
			  return (2, 13);
		      }
		  }

		  return (1, $LATIN_FONT[ord $bchar]);
	      },
	      # GB Chinese font
	      # See pilrc sources (font.c:IsGB) for explanations
	      -Fg  => sub
	      {
		  my $bchar = shift;

		  if (length($bchar) > 1)
		  {
		      my($first,$second) = (ord $bchar, ord substr($bchar, 1));

		      if (($first >= 0xa1 && $first <= 0xf7)
			  &&
			  ($second >= 0xa1 && $second <= 0xfe))
		      {
			  return (2, 13);
		      }
		  }

		  return (1, $LATIN_FONT[ord $bchar]);
	      },
	      # Korean font (hantip font)
	      # See pilrc sources (font.c:IsKoreanHantip) for explanations
	      -Fkt => sub
	      {
		  my $bchar = shift;

		  if (length($bchar) > 1)
		  {
		      my($first,$second) = (ord $bchar, ord substr($bchar, 1));

		      if (($first >= 0xb0 && $first <= 0xc8)
			  && 
			  ($second >= 0xa1 && $second <= 0xfe))
		      {
			  return (2, 8);
		      }
		  }

		  return (1, $LATIN_FONT[ord $bchar]);
	      },
	      # Korean font (hanme font)
	      # See pilrc sources (font.c:IsKoreanHanme) for explanations
	      -Fkm => sub
	      {
		  my $bchar = shift;

		  if (length($bchar) > 1)
		  {
		      my($first,$second) = (ord $bchar, ord substr($bchar, 1));

		      if (($first >= 0xb0 && $first <= 0xc8)
			  && 
			  ($second >= 0xa1 && $second <= 0xfe))
		      {
			  return (2, 11);
		      }
		  }

		  return (1, $LATIN_FONT[ord $bchar]);
	      },
	      # Japanese font
	      # See pilrc sources (font.c:IsJapanese) for explanations
	      -Fj  => sub
	      {
		  my $bchar = shift;
		  my $first = ord $bchar;

		  if ($first >= 0xa1 && $first <= 0xdf)
		  {
		      return (1, 5);
		  }
		  elsif (length($bchar) > 1)
		  {
		      my $second = ord substr($bchar, 1);

		      if ((($first >= 0x81 && $first <= 0x9f)
			   ||
			   ($first >= 0xe0 && $first <= 0xef))
			  &&
			  (($second >= 0x40 && $second <= 0x7e)
			   ||
			   ($second >= 0x80 && $second <= 0xfc)))
		      {
			  return (2, 9);
		      }
		  }

		  return (1, $LATIN_FONT[$first]);
	      },

	      # Hebrew font
	      # See pilrc sources (font.c:InitFontMem) for explanations
	      -Fh  => [ @LATIN_FONT[0 .. 0xdf],
			6, 6, 5, 6, 6, 3, 4, 6,
			6, 3, 6, 5, 6, 6, 6, 3,
			4, 6, 6, 6, 6, 6, 6, 6,
			6, 7, 7, 2, 2, 2, 2, 2,
			@LATIN_FONT[0xdf + 32 + 1 .. 0xff],
			],
	      # Cyrillic font
	      # See pilrc sources (font.c:InitFontMem) for explanations
	      -Fc  => [ @LATIN_FONT[0 .. 0xa7],
			4,
			@LATIN_FONT[0xa7 + 1 + 1 .. 0xb7],
			5,
			@LATIN_FONT[0xb7 + 1 + 1 .. 0xbf],
			5, 5, 5, 5, 7, 4, 8, 5,
			5, 5, 6, 6, 8, 6, 7, 5,
			5, 6, 6, 5, 8, 6, 6, 5,
			6, 7, 6, 7, 5, 5, 7, 5,
			5, 5, 5, 4, 6, 5, 8, 5,
			5, 5, 5, 5, 6, 5, 5, 5,
			5, 4, 6, 6, 6, 6, 6, 5,
			6, 7, 6, 7, 5, 5, 7, 5,
			@LATIN_FONT[0xbf + 64 + 1 .. 0xff],
			],
	      );

my $FONT = $FONTS{-Flatin};	# Latin font by default
my $DEFAULT_FONT = 1;


my $ref_rcp_file;
my $LANG;
my @INC_PATHS;


my $PILRC = "$ENV{HOME}/Projet/palm/pilrc-3.2/pilrc";
#my $PILRC = "$ENV{HOME}/Projet/palm/pilrc-2.9p9/pilrc";
#my $PILRC = 'pilrc';


#
# Process the options to find the -L argument
for (my $index = 0; $index < @ARGV; $index++)
{
    if ($ARGV[$index] eq '-L')
    {
	$LANG = $ARGV[$index] if ++$index < @ARGV;
    }
    elsif ($ARGV[$index] eq '-I')
    {
	push(@INC_PATHS, $ARGV[$index]) if ++$index < @ARGV;
    }
    elsif ($ARGV[$index] eq '-p')
    {
	$PILRC = $ARGV[$index + 1];
	splice(@ARGV, $index, 2);
	$index--;
    }
    elsif ($ARGV[$index] eq '-q')
    {
	$DEBUG = 0;
    }
    elsif ($ARGV[$index] eq '-DBETA')
    {
	$BETA = 1;
    }
    elsif (exists $FONTS{$ARGV[$index]})
    {
	$FONT = $FONTS{$ARGV[$index]};
	$DEFAULT_FONT = 0;
    }
    elsif ($ARGV[$index] =~ /\.rcp\z/)
    {
	$ref_rcp_file = \$ARGV[$index];
    }
}

my %AUTO_DEFINES;
my $AUTO_DEFINES_FILE = 'MaTirelireDefsAuto.h';

defined $LANG or printf "**** Warning: can't find -L option...\n";

print STDERR "Base language is $LANG\n" if defined $LANG;

#
# We don't find the rcp file in arguments, let pilrc tell the usage...
exec $PILRC unless defined $ref_rcp_file;


my %REPL;
my %STRINGS;

my %MENUS_KBD;


#
# Compute the string width in pixels for the standard font
sub str_extent_array
{
    my $str = shift;
    my $width = 0;

    for (my $index = 0; $index < length($str); $index++)
    {
	$width += $FONT->[ord substr($str, $index, 1)];
    }

    return $width;
}


#
# Compute the string width in pixels for the standard font
sub str_extent_func
{
    my $str = shift;
    my $width = 0;

    for (my $index = 0; $index < length($str); )
    {
	my($bytes, $width_add) = $FONT->(substr($str, $index, 2));

	$index += $bytes;
	$width += $width_add;
    }

    return $width;
}

my $str_extent= ref($FONT) eq 'ARRAY' ? \&str_extent_array : \&str_extent_func;


sub find_include
{
    my $file = shift;

    unless (-e $file)
    {
	foreach my $inc (@INC_PATHS)
	{
	    return "$inc/$file" if -e "$inc/$file";
	}
    }

    return $file;
}


sub parse_contents
{
    my $ref_contents = shift;
    my $result = '';

    my $modified = 0;

    my $last_pos = 0;

    my %local_repl;

    # PremiËre passe : les translations
    while ($$ref_contents
	   =~ /^(TRANSLATION\s+"([-\w]+)"\s+BEGIN)(.*?)^END/msg)
    {
	my($before, $lang, $tr) = ($1, $2, $3);

	print STDERR "  TRANSLATION block: language = $lang\n" if $DEBUG;

	# On ajoute l'entre deux...
	$result .= substr($$ref_contents, $last_pos,
			  pos($$ref_contents) - length($&) - $last_pos);

	# Pour le prochain tour
	$last_pos = pos($$ref_contents);

	# Un petit raccourci, qui Èvite du traveil pour rien quand ce
	# n'est pas la bonne langue
	if ($lang ne $LANG)
	{
	    $modified = 1;
	    next;
	}

	my $tmp;
	$tr =~ s/\[([^]]+)\]\s*=\s*
		 (?: \[ \s* ((?:"[^"]+"|[^]"]+)+) \s* \]
		  |(\S+))/
		$local_repl{$1} = defined($2) ? $2 : $3; # if $lang eq $LANG;
		$modified = 1;
		"\n" x (($tmp = $&) =~ tr,\n,,)
		/egsx;

	# On garde toutes les chaÓnes monoligne pour gÈrer le AUTOWIDTH
	while ($tr =~ /"((?:\\.|[^\"])*)"\s*=\s*
		       ("(?:\\.|[^\"])*"(?:\s*\\\n\s*"(\\.|[^\"])*")*)/gx)
	{
	    # Seulement les chaÓnes monoligne
	    unless (defined $3)
	    { $STRINGS{$1} = substr($2, 1, -1) } # On ne prend pas les "
	}

	# On note tous les raccoucis clavier
	# "XXX" = "Menu label" /Z
	# =>
	# "XXX" = "Menu label"
	# "XXX-Kbd" = "Z"
	$tr =~ s!("([^"]+)"\s*=\s*"[^"]*")\s+/([^/*\s])(\s+)
		!
		$MENUS_KBD{$2} = $3; # if $lang eq $LANG;
		$1 . "\n\"$2-Kbd\" = \"$3\"$4"
		!egsmx;

	$result .= $before . $tr . "END";
    }

    # Le reste...
    $result .= substr($$ref_contents, $last_pos);

    # On analyse les remplacements
    while (my($key, $value) =  each %local_repl)
    {
	$value =~ tr/\r\n/  /;	# Sur une seule ligne

	# Soit on a une liste de chaÓnes
	if ($value =~ /^\"/)
	{
	    my $max_list_width = 0;

	    $value =~ s,/\*.*?\*/,,g; # Delete C comments...

	    my $list = $value;
	    $list =~ s/^\s*"//;
	    $list =~ s/"\s*\z//;

	    foreach my $elt (split /"\s+"/, $list)
	    {
		$elt =~ s/\\(\d{3})/chr oct $1/ge;

		# Pour Èviter que les attributs de ligne ne soient comptÈs
		# * = gras
		# ^ = sÈparateur supÈrieur
		# _ = sÈparateur infÈrieur
		$elt =~ s/^[*^_]{1,2}//;

		my $len = 0;

		# '>' en fin de ligne => flËche du sous-menu
		$len += 8 if $elt =~ s/>\z//;

		$len += $str_extent->($elt);

		$max_list_width = $len if $len > $max_list_width;
	    }

	    $REPL{$key} = [ $value, "$max_list_width-1+4" ];
	}
	# Soit on a un alias simple...
	else
	{
	    $REPL{$key} = $value;
	}
    }

    # DeuxiËme passe : les remplacements
    my $regex = join('|', map { quotemeta } keys %REPL);
    $regex = qr/\[($regex)\]				  # $1
     |\bAUTO(?:LIST)?WIDTH\b
     |(ID|STRING(?:TABLE)?|FORM|GROUP)\s+(\w+)=(?:(\d+)|(\w+)(\+\+)?)# $[23456]
     |DEFINE\s+(\w+)=(\w+)(\+\+)?			  # $[789]
     |ID\s+(\w+)\+\+					  # $10
     |GENERICALERT\s+(\w+)\s+(\w+)(?:\s+\[([\s\*\w]+)\])? # $1[123]
     |GENERICSTRING\s+(\w+)(?:=(?:(\d+)|(\w+)(\+\+)?))?   # $1[4567]
     |((?:(?:PUSH)?BUTTON
        |(?:SELECTOR|POPUP)TRIGGER)\s+"((?:\\.|[^\"])*)") #$1[89]
     |\bSTR\s*\(([^)]+)\)				  # $20
     |\@\{([^}]+)\}					  # $21
     |FORMLINES\(\s*(\d+)(?:\s*,\s*(\d+))?\s*\)		  # $2[23]
     /xs;
    my $auto_list_width = "AUTO";

    $result =~ s%$regex%
		$modified = 1;
		# [...]
		if (defined $1)
		{
		    if (ref $REPL{$1})
		    {
			$auto_list_width = $REPL{$1}[1];
			$REPL{$1}[0];
		    }
		    else
		    { $REPL{$1} }
		}
		# BUTTON "..."
		elsif (defined $18)
		{
		    my($block, $str) = ($18, $19);

		    if (exists $STRINGS{$str})
		    {
			if (ref $STRINGS{$str})
			{ $auto_list_width = ${$STRINGS{$str}} }
			else
			{
			    $STRINGS{$str} =~ s/\\(\d{3})/chr oct $1/ge;
			    my $w = $str_extent->($STRINGS{$str});
			    $STRINGS{$str} = \$w; # Pour les prochains coups
			    $auto_list_width = $w;
			}
		    }
		    else
		    {
			$auto_list_width = $str_extent->($str);
		    }
		    $block;
		}
		# ID Toto=23 | ID Toto=Tata++
		elsif (defined $2)
		{
		    if (defined $4)
		    { $AUTO_DEFINES{$3} = $4 }
		    else
		    {
			unless (exists $AUTO_DEFINES{$5})
			{ die "*** $5 undefined, can't use it!\n" }

			# ++
			if (defined $6)
			{
			    unless (exists $AUTO_DEFINES{"${5}Last"})
			    { $AUTO_DEFINES{"${5}Last"} = $AUTO_DEFINES{$5} - 1 }

			    $AUTO_DEFINES{$3} = ++$AUTO_DEFINES{"${5}Last"};
			}
			else
			{
			    $AUTO_DEFINES{$3} = $AUTO_DEFINES{$5};
			}
		    }
		    "$2 $3";
		}
		# DEFINE Toto=1024
		elsif (defined $7)
		{
		    my($k, $v, $pp) = ($7, $8, $9);
		    if ($v =~ m!^\d+\z!)
		    { $AUTO_DEFINES{$k} = $v }
		    elsif ($v eq 'AUTOLISTWIDTH')
		    { $AUTO_DEFINES{$k}	= $auto_list_width eq 'AUTO'
					  ? $v : eval($auto_list_width) }
		    else
		    {
			unless (exists $AUTO_DEFINES{$v})
			{ die "*** $v undefined, can't use it in DEFINE!\n" }

			if (defined $pp)
			{
			    unless (exists $AUTO_DEFINES{"${v}Last"}) # 25/07/2004 MAX
			    { $AUTO_DEFINES{"${v}Last"} = $AUTO_DEFINES{$v} - 1 }

			    $AUTO_DEFINES{$k} = ++$AUTO_DEFINES{"${v}Last"};
			}
			else
			{
			    $AUTO_DEFINES{$k} = $AUTO_DEFINES{$v};
			}
		    }
		    '';
		}
		# ID Tata++   => pour les ID qu'on ne veut pas garder (onglets)
		elsif (defined $10)
		{
		    my $v = $10;

		    unless (exists $AUTO_DEFINES{$v})
		    { die "*** $v undefined, can't use it in ID $v++!\n" }

		    unless (exists $AUTO_DEFINES{"${v}Last"}) # 25/07/2004 MAX
		    { $AUTO_DEFINES{"${v}Last"} = $AUTO_DEFINES{$v} - 1 }

		    "ID " . ++$AUTO_DEFINES{"${v}Last"};
		}
		# GENERICALERT alertEmptyMacroDef ERROR [ OK Cancel ]
		elsif (defined $11)
		{
		    my($alert_id, $alert_type) = ($11, $12);
		    my @buttons;
		    if (defined $13)
		    {
			(my $button_list = $13) =~ s/^\s+|\s+\z//g;
			@buttons = split /\s+/, $button_list;

			if (@buttons == 0)
		        { die "*** GENERICALERT $alert_id "
			      . "buttons definition error!\n" }
		    }
		    else
		    { push(@buttons, 'Button') }

		    my $default = '';
		    my $buttons = '';
		    for (my $index = 0; $index < @buttons; $index++)
		    {
			if ($buttons[$index] =~ s/^\*//)
			{ $default = "DEFAULTBUTTON $index\n" }
			$buttons .= " \"\$$alert_id-$buttons[$index]\"";
		    }

		    "ALERT ID $alert_id\n$alert_type\n$default"
		    . "BEGIN\n"
		    . "\tTITLE   \"\$$alert_id-Title\"\n"
		    . "\tMESSAGE \"\$$alert_id-Message\"\n"
		    . "\tBUTTONS$buttons"
		    . "\nEND";
		}
		# GENERICSTRING strAnyList
		elsif (defined $14)
		{
		    my($name, $id_num, $id_name, $plusplus) 
			= ($14, $15, $16, $17);

		    # GENERICSTRING XXX=34
		    if (defined $id_num)
		    {
			$AUTO_DEFINES{$name} = $AUTO_DEFINES{$id_num};
		    }
		    # GENERICSTRING XXX=TOTO || GENERICSTRING XXX=TOTO++
		    elsif (defined $id_name)
		    {
			unless (exists $AUTO_DEFINES{$id_name})
			{ die "*** $id_name undefined, can't use it!\n" }

			# ++
			if (defined $plusplus)
			{
			    unless (exists $AUTO_DEFINES{"${id_name}Last"})
			    { $AUTO_DEFINES{"${id_name}Last"} = $AUTO_DEFINES{$id_name} - 1 }

			    $AUTO_DEFINES{$name} 
			      = ++$AUTO_DEFINES{"${id_name}Last"}
			}
			else
			{
			    $AUTO_DEFINES{$name} = $AUTO_DEFINES{$id_name};
			}
		    }

		    # GENERICSTRING XXX
		    "STRING $name\t\"\$$name\""
		}
		# STR(perl expression)
		elsif (defined $20)
		{
		    my $num_chars = eval $20;

		    die "STR($20): $@\n" if $@;

		    '"' . ('X' x $num_chars) . '"';
		}
		# @{DEFINE_NAME} ou @{perl expression}
		elsif (defined $21)
		{
		    my $contents;
		    if (exists $AUTO_DEFINES{$21})
		    {
			$contents = $AUTO_DEFINES{$21};
		    }
		    else
		    {
			$contents = eval $contents;
			die "\@{$21}: $@\n" if $@;
		    }
		    $contents;
		}
		# FORMLINES(nb_lines) ou FORMLINES(nb_lines, add_h_pixels)
		elsif (defined $22)
		{
		    my $h = $22 * 13 + 8 + 34 + ($23 || 0);
		    my $y = 160 - $h - 2;

		    "AT (2 $y 156 $h)"
		}
		# AUTOLISTWIDTH ou AUTOWIDTH
		else
		{
		    # On le garde dans les DEFINEs pour pouvoir le rÈcupÈrer
		    $AUTO_DEFINES{AUTOLISTWIDTH} = eval($auto_list_width);

		    $auto_list_width;
		}
		%egs;

    # On n'en a plus besoin
    delete $AUTO_DEFINES{AUTOLISTWIDTH};

    # Passe suivante, les menus et leurs raccourcis...
    my $result_menu = '';
    $last_pos = 0;
    while ($result =~ /^(MENU\s+ID\s+(\w+)\s+BEGIN)(.*?)^END/msg)
    {
	my($before, $menu_name, $menu_contents) = ($1, $2, $3);

	# On ajoute l'entre deux...
	$result_menu .= substr($result, $last_pos,
			       pos($result) - length($&) - $last_pos);

	# Pour le prochain tour
	$last_pos = pos($result);

	# Liste des raccourcis de ce menu
	my %defined_kbd;	# ClÈ=raccourci, valeur=label_item

	$menu_contents =~ s/(MENUITEM\s+"([^"]+)"\s+ID\s+\w+)(\s+"?)/ # $[123]
			   # Un raccourci pour cette entrÈe est dÈj‡ dÈfini
			   if (substr($3, -1) eq '"')
			   {
			       $1 . $3;
			   }
			   # Un raccourci auto existe dans le bloc TRANSACTION
			   elsif (exists $MENUS_KBD{$2})
			   {
			       # Ce raccourci est dÈj‡ dÈfini dans ce menu !!!
			       if (exists $defined_kbd{$MENUS_KBD{$2}})
			       {
				   die("*** Duplicated shortcut in menu "
				       . $menu_name
				       . "\n    for $2 and "
				       . $defined_kbd{$MENUS_KBD{$2}}
				       . " items\n");
			       }
			       $modified = 1;
			       $defined_kbd{$MENUS_KBD{$2}} = $2;
			       $1 . " \"$2-Kbd\"" . $3;
			   }
			   # Pas de raccourci pour cette entrÈe
			   else
			   {
			       print STDERR "    !!! No shortcut for $2\n";
			       $1 . $3;
			   }
			   /egxms;

	$result_menu .= $before . $menu_contents . "END";
    }

    # Le reste...
    $result = $result_menu . substr($result, $last_pos);

    # Enfin, derniËre passe on s'occupe de DIA
    my $result_dia = '';
    my %dia_defines;
    $last_pos = 0;
    while ($result =~ /^(WORDLIST ID (\w+)\s+BEGIN)(.*?)^END/msg)
    {
	my($before, $dia_name, $dia_contents) = ($1, $2, $3);

	# On ajoute l'entre deux...
	$result_dia .= substr($result, $last_pos,
			      pos($result) - length($&) - $last_pos);

	# Pour le prochain tour
	$last_pos = pos($result);

	# SpÈcial DIA
	if ($dia_name =~ /FormIdx\z/)
	{
	    # Chargement des constantes DIA
	    if (keys(%dia_defines) == 0)
	    {
		local $/ = "\n";

		my $resizeconsts = find_include("PalmResize/resizeconsts.h");

		open(DIA, $resizeconsts) or
		    die"DIA information without $resizeconsts: $!\n";
		while (defined(my $line = <DIA>))
		{
		    if ($line =~ /^\#\s*define\s+(DIA_\w+|GSI_OBJECT_ID)\s+(\d+)/)
		    {
			$dia_defines{$1} = $2;
		    }
		}
		close DIA;

		# User defined DIA_* constants
		while (my($name, $value) = each %AUTO_DEFINES)
		{
		    if ($name =~ /^DIA_/)
		    {
			$dia_defines{$name} = $value;
		    }
		}
	
		if (keys(%dia_defines) == 0)
		{
		    die "DIA information, but can't find any DIA constant: $!\n";
		}
	    }

	    # On regroupe les lignes multiples
	    $dia_contents =~ s/\\\n/ /g;
	
	    # On remplace les constantes
	    $dia_contents =~ s/(DIA_\w+|GSI_OBJECT_ID)/
			       exists($dia_defines{$1})
			       ? $dia_defines{$1}
			       : die "Unknown DIA constant `$1' in $dia_name\n"/eg;

	    # On fait de l'arithmetique...
	    $dia_contents =~ s/(\d+(?:\s*\+\s*\d+)+)/eval $1/ge;
	}

	# Suppression des commentaires
	$dia_contents =~ s,//.*,,g;

	# Pilrc ne fait pas de remplacement dans les wordlists
	$dia_contents =~ s/([a-zA-Z]\w*)/
			  if (not exists $AUTO_DEFINES{$1})
			  { $AUTO_DEFINES{$1} = ++$AUTO_DEFINES{ordObjectsLast} }
			  $AUTO_DEFINES{$1}
			  /ge;

	$result_dia .= $before . $dia_contents . "END";
    }

    if ($modified)
    {
	# Le reste...
	$result_dia .= substr($result, $last_pos);

	$$ref_contents = $result_dia;
	return 1;
    }

    return 0;
}


sub load_include
{
    my($match, $file) = @_;

    # Search the good path through include paths
    $file = find_include($file);

    local $/ = undef;

    # Open it (even if we didn't find it)
    print STDERR "  Open include $file\n" if $DEBUG;
    open(INC, $file) || die "Can't open $file: $!\n";
    my $inc_contents = <INC>;
    close INC;

    # Parse it, and if it changed, copy it under new name
    print STDERR "  Parse contents of $file\n" if $DEBUG;
    if (parse_contents(\$inc_contents))
    {
	# Instead of creating a new pre-parsed include file, we will
	# directly replace the #include directive by the pre-parsed
	# include contents
	if ($EMULATE_INCLUDE)
	{
	    print STDERR "  Replace #include \"$file\" directive\n" if $DEBUG;
	    return $inc_contents;
	}
	else
	{
	    print STDERR "  Write result to $file-tmp\n" if $DEBUG;

	    open(NEWINC, ">$file-tmp")
		|| die "Can't open temporary file $file-tmp: $!\n";
	    print NEWINC $inc_contents;
	    close NEWINC;
	}

	# And return the new include name
	return "#include \"$file-tmp\"";
    }

    # Nothing change...
    return $match;
}


#
# Read the original multilingual file
print STDERR "Open $$ref_rcp_file\n" if $DEBUG;

open(RCP, $$ref_rcp_file) || die "Can't open $$ref_rcp_file: $!\n";
undef $/;
my $contents = <RCP>;
close RCP;

# If we are compiling a STABLE version, delete the alertBeta dialog box
unless (defined $BETA)
{
    $contents =~ s/(^alert\s+id\s+alertBeta\s+.*?\s+end\s+)/
		   my $c = $1; $c =~ tr,\n,,cd; $c/eism;

    # Delete /* BETA */ .... lines
    $contents =~ s,/\*\s*BETA\s*\*/.*,,;
}

# If a version number is present, we will replace all occurences
# of @VERSION@ token by it...
if ($contents =~ /^VERSION\s+"(.*?)"/m)
{
    my $version = $1;
    $contents =~ s/\@VERSION\@/$version/g;
}

# If translators file is present, we will replace all occurences
# of @TRANSLATORS@ token by it...
my $translators = '';
if (open(TRANSLATORS, 'translators.txt'))
{
    $translators = '* ' . <TRANSLATORS>;
    $translators =~ s/\s+\z//s;
    $translators =~ s/\n/\\n"\\\n\t"* /g;
    close TRANSLATORS;
}
else
{
    warn "No translators.txt file found: $!\n";
}
$contents =~ s/\@TRANSLATORS\@/$translators/g;

# The used font is not the latin one, so translate all accented
# characters to non accented version on the main RCP file only.
if ($DEFAULT_FONT == 0)
{
    $contents =~ tr[‡‚·‰ÁÈËÍÎÓÔÙˆ˘˚Ò¿¬¡ƒ«…» ÀŒœ‘÷Ÿ€—]
		   [aaaaceeeeiioouunAAAACEEEEIIOOUUN];
}


#
# On charge les #include
print STDERR "Load includes of $$ref_rcp_file\n" if $DEBUG;
$contents =~ s/^(\#\s*include\s*[<"](.*?)[<"])/load_include($1, $2)/egm;


#
# On parse le contenu
print STDERR "Parse contents of $$ref_rcp_file\n" if $DEBUG;
parse_contents(\$contents);

#
# We save the .rcp file in /tmp/ directory to give it to pilrc later
$$ref_rcp_file =~ s,.*/,,;
$$ref_rcp_file .= "-$LANG.tmp";
print STDERR "Write result to $$ref_rcp_file\n" if $DEBUG;
open(NEW, ">$$ref_rcp_file") || die "Can't open $$ref_rcp_file: $!\n";
print NEW $contents;
close NEW;

#
# Auto defs file...
if (%AUTO_DEFINES)
{
    my($old_contents, $new_contents) = ('', '');

    # Old contents, if file exists...
    if (open(AUTO, $AUTO_DEFINES_FILE))
    {
	$old_contents = <AUTO>;
	close AUTO;
    }

    foreach my $key (sort keys %AUTO_DEFINES)
    {
	$new_contents .= "#define $key\t$AUTO_DEFINES{$key}\n"
    }

    # Don't overwrite if no change...
    if ($new_contents ne $old_contents)
    {
	open(AUTO, ">$AUTO_DEFINES_FILE")
	  || die "Can't open $AUTO_DEFINES_FILE: $!\n";
	print AUTO $new_contents;
	close AUTO;
    }
}

#
# Call pilrc, the .rcp file given is the .rcp translated...
print "$PILRC @ARGV\n";
exec $PILRC, @ARGV;
