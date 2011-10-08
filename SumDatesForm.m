/* 
 * SumDatesForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Dim nov 14 20:00:22 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Jun 22 15:09:56 2006
 * Update Count    : 1
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: SumDatesForm.m,v $
 * Revision 1.4  2006/06/23 13:24:43  max
 * Now call -focusObject: instead of FrmSetFocus() to set focus to a field.
 *
 * Revision 1.3  2005/08/20 13:07:03  max
 * Updates are now genericaly managed by MaTiForm.
 *
 * Revision 1.2  2005/02/13 00:06:18  max
 * Change prototype of -keyFilter:for:
 * It allows to detect and not block special keys in numeric fields.
 * Now the Select key of the 5-way works everywhere...
 *
 * Revision 1.1  2005/02/09 22:57:23  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_SUMDATESFORM
#include "SumDatesForm.h"

#include "MaTirelire.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


@implementation SumDatesForm

- (Boolean)extractAndSave
{
  struct s_db_prefs *ps_db_prefs = [[oMaTirelire transaction] getPrefs];
  UInt16 uh_sum_date, uh_sum_todayplus;

  if ([self checkField:SumDatesOnDay
	    flags:FLD_CHECK_VOID|FLD_CHECK_NULL|FLD_TYPE_WORD
	    resultIn:&uh_sum_date
	    fieldName:strSumDatesOnDay] == false)
    return false;

  if (uh_sum_date >= (1 << 5))
    uh_sum_date = (1 << 5) - 1;

  if ([self checkField:SumDatesTodayDays
	    flags:FLD_CHECK_VOID|FLD_CHECK_NULL|FLD_TYPE_WORD
	    resultIn:&uh_sum_todayplus
	    fieldName:strSumDatesTodayDays] == false)
    return false;

  if (uh_sum_todayplus >= (1 << 5))
    uh_sum_todayplus = (1 << 5) - 1;

  // On n'envoie l'évènement que si ça a changé...
  if (uh_sum_date != ps_db_prefs->ul_sum_date
      || uh_sum_todayplus != ps_db_prefs->ul_sum_todayplus)
  {
    self->ui_update_mati_list |= (frmMaTiUpdateList
				  | frmMaTiUpdateListSumTypes);

    ps_db_prefs->ul_sum_date = uh_sum_date;
    ps_db_prefs->ul_sum_todayplus = uh_sum_todayplus;
  }
  
  return true;
}


- (Boolean)open
{
  struct s_db_prefs *ps_db_prefs = [[oMaTirelire transaction] getPrefs];

  // Somme le X du mois
  [self replaceField:REPLACE_FIELD_EXT | SumDatesOnDay
	withSTR:(Char*)ps_db_prefs->ul_sum_date	len:REPL_FIELD_DWORD];

  // Somme à aujourd'hui + X jours
  [self replaceField:REPLACE_FIELD_EXT | SumDatesTodayDays
	withSTR:(Char*)ps_db_prefs->ul_sum_todayplus len:REPL_FIELD_DWORD];

  [super open];

  // On place le focus sur le premier champ
  [self focusObject:SumDatesOnDay];

  return true;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case SumDatesSave:
    if ([self extractAndSave] == false)
      break;

    // On continue sur cancel...

  case SumDatesCancel:
    [self returnToLastForm];
    break;

  default:
    return false;
  }

  return true;
}


- (Boolean)keyDown:(struct _KeyDownEventType*)ps_key
{
  UInt16 fld_id;

  // On laisse la main à Papa pour gérer les déplacements entre champs...
  if ([super keyDown:ps_key])
    return true;

  fld_id = FrmGetFocus(self->pt_frm);

  if (fld_id != noFocus)
    switch (FrmGetObjectId(self->pt_frm, fld_id))
    {
    case SumDatesOnDay:
    case SumDatesTodayDays:
      return [self keyFilter:KEY_FILTER_INT | fld_id for:ps_key];
    }

  return false;
}

@end
