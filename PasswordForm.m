/* 
 * PasswordForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sam mar 27 17:46:21 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Jan 14 17:36:23 2008
 * Update Count    : 23
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: PasswordForm.m,v $
 * Revision 1.4  2008/01/14 16:37:32  max
 * backspaceChr erase field.
 * Space char valids too.
 *
 * Revision 1.3  2006/06/23 13:25:14  max
 * No more need of fiveway.h with PalmSDK installed.
 * Rework T|T 5-way handling.
 *
 * Revision 1.2  2005/05/08 12:13:04  max
 * +new:withLabel:va: replaces +new:withLabel:
 * -initLabelWith:va: replaces -initLabelWith: as it can now use label format.
 * HardKey that power up the device is no more taken into account.
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#include <Common/System/palmOneNavigator.h>

#define EXTERN_PASSWORDFORM
#include "PasswordForm.h"

#include "MaTirelire.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


@implementation PasswordForm

+ (PasswordForm*)new:(UInt16)uh_id withLabel:(UInt16)uh_label va:(va_list)ap
{
  PasswordForm *oPasswd = (PasswordForm*)[self new:uh_id];

  [oPasswd initLabelWith:uh_label va:ap];

  return oPasswd;
}


- (void)initLabelWith:(UInt16)uh_label va:(va_list)ap
{
  Char ra_format[32 + 1], ra_label[32 + 32 + 1];
  Char *pa_label = ra_format;

  SysCopyStringResource(ra_format, uh_label);
  if (ap != NULL)
  {
    StrVPrintF(ra_label, ra_format, ap);
    pa_label = ra_label;
  }

  FrmCopyLabel(self->pt_frm, PasswordLabel, pa_label);
}


- (Boolean)open
{
  // On cache le label qui contient le mot de passe tapé
  [self hideId:PasswordValue];
  FrmCopyLabel(self->pt_frm, PasswordValue, "");

  // On vide le mot de passe caché (liste d'*)
  FrmCopyLabel(self->pt_frm, PasswordHidden, "");

  return [super open];
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
    // On efface le mot de passe
  case PasswordC:
    [self _clear];
    break;

    // Nouveau chiffre
  case Password0 ... Password9:
    [self _newDigit:ps_select->controlID - Password0 + '0'];
    break;

    // Fin...
  case PasswordOk:
    [self _valid];
    break;

  default:
    return false;
  }

  return true;
}


- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key
{
  switch (ps_key->chr)
  {
  case '0' ... '9':
    [self _newDigit:ps_key->chr];
    break;

    // Escape : on efface le champ
  case backspaceChr:
  case chrEscape:
    [self _clear];
    break;

    // 
  case vchrNavChange:		// OK (only 5-way T|T)
    if (ps_key->modifiers & autoRepeatKeyMask)
      return false;

    switch (ps_key->keyCode & (navBitsAll | navChangeBitsAll))
    {
    case navBitLeft | navChangeLeft:
      [self _newDigit:'0' + 10 + hard2Chr - hard1Chr];
      break;
    case navBitRight | navChangeRight:
      [self _newDigit:'0' + 10 + hard3Chr - hard1Chr];
      break;
    default:
      return false;
    }
    break;

  case hard1Chr ... hard4Chr:
    if ((ps_key->modifiers & poweredOnKeyMask) == 0)
      [self _newDigit:'0' + 10 + ps_key->chr - hard1Chr];
    break;

  case pageUpChr:
    [self _newDigit:'0' + 14];
    break;

    // Validation
  case pageDownChr:		// Page Down
  case chrCarriageReturn:	// Enter
  case chrLineFeed:
  case ' ':			// Espace (pour les Treo)
    [self _valid];
    break;

  default:
    return false;
  }

  return true;
}


- (void)_clear
{
  [self hideId:PasswordHidden];
  FrmCopyLabel(self->pt_frm, PasswordHidden, "");
  [self showId:PasswordHidden];

  FrmCopyLabel(self->pt_frm, PasswordValue, "");
}


- (void)_newDigit:(Char)a_digit
{
  const Char *pa_hidden;
  Char ra_password[8 + 1], ra_digit[2];

  pa_hidden = FrmGetLabel(self->pt_frm, PasswordHidden);
  if (StrLen(pa_hidden) < sizeof(ra_password) - 1)
  {
    StrCopy(ra_password, pa_hidden);
    StrCat(ra_password, "*");
    FrmCopyLabel(self->pt_frm, PasswordHidden, ra_password);

    StrCopy(ra_password, FrmGetLabel(self->pt_frm, PasswordValue));
    ra_digit[0] = a_digit;
    ra_digit[1] = '\0';
    StrCat(ra_password, ra_digit);
    FrmCopyLabel(self->pt_frm, PasswordValue, ra_password);
  }
}


- (void)_valid
{
  const Char *pa_cur;
  UInt32 ul_code = 0;

  EventType e_user;

  pa_cur = FrmGetLabel(self->pt_frm, PasswordValue);
  while (*pa_cur != '\0')
  {
    ul_code <<= 4;
    ul_code |= *pa_cur - '0' + 1;
    pa_cur++;
  }

  MemSet(&e_user, sizeof(e_user), 0);
  e_user.eType = firstUserEvent;
  *(UInt32*)&e_user.data.generic = ul_code;

  EvtAddEventToQueue(&e_user);
}

@end
