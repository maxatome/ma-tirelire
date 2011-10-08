/* 
 * AboutForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Tue Mar 23 20:11:37 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Wed Dec 12 10:36:47 2007
 * Update Count    : 3
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: AboutForm.m,v $
 * Revision 1.4  2008/01/14 17:28:45  max
 * Page up/down scroll translators list.
 *
 * Revision 1.3  2006/12/16 16:56:53  max
 * Change the translators list appearance.
 *
 * Revision 1.2  2006/04/26 10:44:02  max
 * Add MaTirelireDefsAuto.h include.
 *
 * Revision 1.1  2005/02/09 22:57:21  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_ABOUTFORM
#include "AboutForm.h"

#include "MaTirelire.h"

#include "objRsc.h"		// XXX
#include "MaTirelireDefsAuto.h"


@implementation AboutForm

- (Boolean)open
{
  MemHandle pv_translators;
  char *pa_translators;

  pv_translators = DmGetResource('tSTR', strTranslators);
  pa_translators = MemHandleLock(pv_translators);

  [self replaceField:AboutText withSTR:pa_translators len:-1];

  MemHandleUnlock(pv_translators);
  DmReleaseResource(pv_translators);

  // Si on est en mode gaucher, il faut inverser le texte avec la barre
  // de scroll
  if (oMaTirelire->s_prefs.ul_left_handed)
    [self swapLeft:AboutText rightOnes:AboutScrollbar, 0];

  [self fieldUpdateScrollBar:AboutScrollbar
	fieldPtr:[self objectPtrId:AboutText]
	setScroll:true];

  return [super open];
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  if (ps_select->controlID == AboutYop)
  {
    [self returnToLastForm];
    return true;
  }

  return false;
}


- (Boolean)sclRepeat:(struct sclRepeat *)ps_repeat
{
  [self fieldScrollBar:AboutScrollbar
	linesToScroll:ps_repeat->newValue - ps_repeat->value update:false];

  return false;
}


- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key
{
  switch (ps_key->chr)
  {
  case pageUpChr:
  case pageDownChr:
    [self fieldScrollBar:AboutScrollbar
	  linesToScroll:ps_key->chr == pageUpChr ? -1 : 1 update:true];
    break;
  }

  return [super keyDown:ps_key];
}

@end
