/* 
 * RepeatsListForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mar nov  1 23:04:40 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Jan 10 12:00:44 2008
 * Update Count    : 13
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: RepeatsListForm.m,v $
 * Revision 1.3  2008/01/14 16:31:44  max
 * Switch to new mcc.
 * Delete -free since it does nothing else than super does.
 *
 * Revision 1.2  2006/06/28 09:41:32  max
 * SumScrollList +newInForm: prototype changed.
 * Now call SumScrollList -updateWithoutRedraw.
 *
 * Revision 1.1  2005/11/19 16:56:44  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_REPEATSLISTFORM
#include "RepeatsListForm.h"

#include "RepeatsScrollList.h"
#include "MaTirelire.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


@implementation RepeatsListForm

- (Boolean)open
{
  Transaction *oTransaction;
  DateTimeType s_datetime;
  Char ra_account_name[dmCategoryLength];
  UInt16 uh_label_id, uh_len, x, y;

  oTransaction = [oMaTirelire transaction];

  // Le format de la date
  self->e_format = (DateFormatType)PrefGetPreference(prefDateFormat);

  // La date par défaut
  TimSecondsToDateTime(TimGetSeconds()
		       + oTransaction->ps_prefs->ul_repeat_days * 86400,
		       &s_datetime);
  self->s_end_date.day = s_datetime.day;
  self->s_end_date.month = s_datetime.month;
  self->s_end_date.year = s_datetime.year - firstYear;
  [self dateSet:RepeatsListDate date:self->s_end_date format:self->e_format];

  // Le nom du compte
  CategoryGetName(oTransaction->db, oTransaction->ps_prefs->ul_cur_category,
		  ra_account_name);

  uh_label_id = FrmGetObjectIndex(self->pt_frm, RepeatsListAccountName);

  // Le label : il doit être calé à la droite de l'écran
  WinGetDisplayExtent(&x, &uh_len);
  FrmGetObjectPosition(self->pt_frm, uh_label_id, &uh_len, &y);
  x -= FntCharsWidth(ra_account_name, StrLen(ra_account_name));
  FrmSetObjectPosition(self->pt_frm, uh_label_id, x, y);

  FrmCopyLabel(self->pt_frm, RepeatsListAccountName, ra_account_name);

  // Liste des opérations
  self->oList = (SumScrollList*)[RepeatsScrollList newInForm:(BaseForm*)self];

  [self sumFieldRepos];

  return [super open];
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  if ([super ctlSelect:ps_select])
    return true;

  switch (ps_select->controlID)
  {
  case RepeatsListQuit:
    [self returnToLastForm];
    break;

  case RepeatsListDate:
    [self dateInc:RepeatsListDate date:&self->s_end_date
	  pressedButton:RepeatsListDate format:self->e_format];
    [self sumFieldRepos];

    // Il faut donner la nouvelle date à notre liste
    [(RepeatsScrollList*)self->oList changeDate:DateToInt(self->s_end_date)];
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
  case RepeatsListDateUp:
  case RepeatsListDateDown:
    [self dateInc:RepeatsListDate date:&self->s_end_date
	  pressedButton:ps_repeat->controlID format:self->e_format];
    [self sumFieldRepos];

    // Il faut donner la nouvelle date à notre liste
    [(RepeatsScrollList*)self->oList changeDate:DateToInt(self->s_end_date)];
    break;
  }

  // On retourne toujours false sinon la répétition s'arrête
  return false;
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  switch (UPD_CODE(ps_update->updateCode))
  {
  case frmMaTiUpdateList:
    // Une opération a été ajoutée ou supprimée ou modifiée
    if (ps_update->updateCode & frmMaTiUpdateListTransactions)
    {
      UInt16 uh_index;

      // Dans le cas d'une opération modifiée, on la rend visible dans
      // la liste
      uh_index = (ps_update->updateCode >> 16);
      if (uh_index > 0)
	// Il faut que l'opération, que l'on vient d'éditer, soit visible
	[self->oList setCurrentItem:uh_index | SCROLLLIST_CURRENT_DONT_RELOAD];

      [self->oList updateWithoutRedraw];

      goto erase_list;
    }

    // Si les types ont changé, il faut juste rafraîchir la liste car
    // parfois le type est présent en lieu et place de la description
    if (ps_update->updateCode & frmMaTiUpdateListTypes)
    {
      // On efface le contenu de la liste, le redraw de retour sur notre
      // écran fera le reste
  erase_list:
      TblEraseTable(self->oList->pt_table);
    }

    break;
  }

  return [super callerUpdate:ps_update];
}


// Appelée par -redrawForm si le DIA a changé d'état avant le redessin
- (void)sumTypeWidgetChange
{
  // On redimensionne le champ de la somme
  [self sumFieldRepos];
}

@end
