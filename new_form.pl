#!/usr/local/bin/perl -w
# 
# new_form.pl -- 
# 
# Author          : Charlie Root
# Created On      : Sat Mar 27 15:02:48 2004
# Last Modified By: 
# Last Modified On: 
# Update Count    : 0
# Status          : Unknown, Use with caution!
#

use strict;

use POSIX;


die "usage: $0 FormName [SuperClassName]\n" unless @ARGV > 0;

my $CLASS = shift;
my $SUPERCLASS = shift || 'MaTiForm';

#$CLASS .= 'Form' if $CLASS !~ /Form\z/;

my $UCLASS = uc $CLASS;

if (-e "$CLASS.m" or -e "$CLASS.h")
{
    die "$CLASS.m or $CLASS.h already exists...\n";
}

my $now = POSIX::strftime('%a %b %e %H:%M:%S %Y', localtime(time));

my $open = "  return [super open];\n";

my $BUTTONS_SELECT = '';
{
    local $/ = undef;
    if (open(RCP, "obj.rcp"))
    {
	my $rcp = <RCP>;
	close RCP;

	if ($rcp =~ /\nFORM\s+${CLASS}Idx.*?\nBEGIN(.*?)\nEND/s)
	{
	    my @BUTTONS_SELECT;
	    $rcp = $1;

	    while ($rcp =~ /\b(?:BUTTON|(?:POPUP|SELECTOR)TRIGGER)
			    \s+"[^"]*"\s+ID\s+(\w+)/sgx) #"
	    {
		push(@BUTTONS_SELECT, $1);
	    }

	    if ($rcp =~ /FIELD\s+ID\s+(\w+)/)
	    {
		$open = <<ENDOFFOCUS;
  [super open];

  // On place le focus sur le premier champ de la boîte
  FrmSetFocus(self->pt_frm, FrmGetObjectIndex(self->pt_frm, $1));

  return true;
ENDOFFOCUS
	    }

	    $BUTTONS_SELECT = join("\n", map
				   {
				       "  case $_:\n    break;\n"
				   }
				   @BUTTONS_SELECT);
	}
    }
}

# Le .h
open(SRC, ">$CLASS.h") || die "Can't open $CLASS.h: $!\n";

print SRC <<ENDOFSRC;
/* -*- objc -*-
 * $CLASS.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : $now
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__${UCLASS}_H__
#define	__${UCLASS}_H__

#include "$SUPERCLASS.h"

#ifndef EXTERN_${UCLASS}
# define EXTERN_${UCLASS} extern
#endif

\@interface $CLASS : $SUPERCLASS
{
}

\@end

#endif	/* __${UCLASS}_H__ */
ENDOFSRC

close SRC;


# Le .m
open(SRC, ">$CLASS.m") || die "Can't open $CLASS.m: $!\n";

print SRC <<ENDOFSRC;
/* 
 * $CLASS.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : $now
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * \$Author\$
 * \$Log\$
 * ==================== RCS ==================== */

#define EXTERN_$UCLASS
#include "$CLASS.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


\@implementation $CLASS

- ($CLASS*)free
{
  return ($CLASS*)[super free];
}


- (Boolean)open
{
$open}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
$BUTTONS_SELECT
  default:
    return false;
  }

  return true;
}

\@end
ENDOFSRC

close SRC;
