/* 
 * ClearingAutoConfForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mar nov  1 11:54:24 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Jun 22 15:02:44 2006
 * Update Count    : 1
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: ClearingAutoConfForm.m,v $
 * Revision 1.2  2006/06/23 13:24:43  max
 * Now call -focusObject: instead of FrmSetFocus() to set focus to a field.
 *
 * Revision 1.1  2005/11/19 16:56:44  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_CLEARINGAUTOCONFFORM
#include "ClearingAutoConfForm.h"

#include "ClearingListForm.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


#define s_clear_auto_args \
	((ClearingListForm*)self->oPrevForm)->s_clear_auto_form


@implementation ClearingAutoConfForm

- (Boolean)open
{
  // La date butoir...
  self->e_format = (DateFormatType)PrefGetPreference(prefLongDateFormat);
  self->s_date = s_clear_auto_args.s_date;
  [self dateSet:ClearingAutoConfDate date:self->s_date format:self->e_format];

  // Le nombre de transactions
  [self replaceField:REPLACE_FIELD_EXT | ClearingAutoConfNumTrans
	withSTR:(Char*)(UInt32)s_clear_auto_args.uh_num_transactions
	len:REPL_FIELD_DWORD | REPL_FIELD_EMPTY_IF_NULL];

  [super open];

  // On place le focus sur le premier champ de la boîte
  [self focusObject:ClearingAutoConfNumTrans];

  return true;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case ClearingAutoConfOK:
    [self checkField:ClearingAutoConfNumTrans
	  flags:FLD_CHECK_NOALERT|FLD_TYPE_WORD
	  resultIn:&s_clear_auto_args.uh_num_transactions
	  fieldName:FLD_NO_NAME];
    s_clear_auto_args.s_date = self->s_date;

    // Retour sur l'écran de pointage qui va lancer le pointage auto
    [self sendCallerUpdate:(frmMaTiUpdateClearingForm
			    | frmMaTiUpdateClearingFormAuto)];

    // Continue...

  case ClearingAutoConfCancel:
    [self returnToLastForm];
    break;

  case ClearingAutoConfDate:
    [self dateInc:ClearingAutoConfDate date:&self->s_date
	  pressedButton:ClearingAutoConfDate format:self->e_format];
    break;

  default:
    return false;
  }

  return true;
}


- (Boolean)ctlRepeat:(struct ctlRepeat *)ps_repeat
{
  switch (ps_repeat->controlID)
  {
  case ClearingAutoConfDateUp:
  case ClearingAutoConfDateDown:
    [self dateInc:ClearingAutoConfDate date:&self->s_date
          pressedButton:ps_repeat->controlID format:self->e_format];
    break;
  }

  // On retourne toujours false sinon la répétition s'arrête
  return false;
}

@end
