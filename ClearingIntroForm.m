/* 
 * ClearingIntroForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Ven oct  7 19:03:11 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Oct 30 12:15:29 2006
 * Update Count    : 6
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: ClearingIntroForm.m,v $
 * Revision 1.6  2006/11/04 23:47:56  max
 * Use -selTriggerSignChange: to handle amount sign.
 *
 * Revision 1.5  2006/10/05 19:08:44  max
 * s/Int32/t_amount/g
 *
 * Revision 1.4  2006/06/23 13:25:06  max
 * Now call -focusObject: instead of FrmSetFocus() to set focus to a field.
 * Auto-select target balance field.
 *
 * Revision 1.3  2005/11/19 16:56:19  max
 * Redraws reworked.
 *
 * Revision 1.2  2005/10/16 21:44:01  max
 * Redraw last form before returning to it.
 *
 * Revision 1.1  2005/10/11 18:27:53  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_CLEARINGINTROFORM
#include "ClearingIntroForm.h"

#include "MaTirelire.h"
#include "ProgressBar.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


@implementation ClearingIntroForm

- (Boolean)open
{
  Currency *oCurrencies = [oMaTirelire currency];
  struct s_currency *ps_currency;

  // Mise en place de la devise du compte
  ps_currency = [oCurrencies getId:[[oMaTirelire transaction]
				     accountCurrency:ACCOUNT_PROP_CURRENT]];

  [self fillLabel:ClearingIntroCurrency withSTR:ps_currency->ra_name];

  [oCurrencies getFree:ps_currency];

  // On fait la somme des pointés
  [self computeSum];

  [super open];

  // On place le focus sur le premier champ de la boîte
  [self focusSum];

  return true;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case ClearingIntroTargetBalanceSign:
    [self selTriggerSignChange:ps_select];
    break;

  case ClearingIntroOK:
    if ([self checkField:ClearingIntroTargetBalance
	      flags:FLD_CHECK_VOID|FLD_SELTRIGGER_SIGN|FLD_TYPE_FDWORD
	      resultIn:&self->l_target_balance
	      fieldName:strClearingIntroTargetBalance] == false)
      break;

    FrmPopupForm(ClearingListFormIdx);
    break;

  case ClearingIntroCancel:
    [self returnToLastForm];
    break;

  default:
    return false;
  }

  return true;
}


- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key
{
  UInt16 fld_id;

  // On laisse la main à Papa pour gérer les déplacements entre champs
  // et les touches spéciales...
  if ([super keyDown:ps_key])
    return true;

  fld_id = FrmGetFocus(self->pt_frm);

  if (fld_id != noFocus
      && FrmGetObjectId(self->pt_frm, fld_id) == ClearingIntroTargetBalance)
    return [self keyFilter:KEY_FILTER_FLOAT | KEY_SELTRIGGER_SIGN | fld_id
		 for:ps_key];

  return false;
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  if (UPD_CODE(ps_update->updateCode) == frmMaTiUpdateClearingForm)
  {
    //
    // Il faut quitter le formulaire
    if (ps_update->updateCode & frmMaTiUpdateClearingFormClose)
      [self returnToLastForm];
    //
    // Recalcul de la somme des pointés
    else if (ps_update->updateCode & frmMaTiUpdateClearingFormUpdate)
    {
      [self computeSum];
      [self focusSum];
    }

    // Il ne faut pas que la classe mère conserve cet événement pour
    // Papa, on s'en est chargé nous-mêmes une ligne au dessus.
    ps_update->updateCode = 0;
  }

  return [super callerUpdate:ps_update];
}


// On fait la somme des pointés
- (void)computeSum
{
  Transaction *oTransactions = [oMaTirelire transaction];
  DmOpenRef db;
  MemHandle pv_tr;
  const struct s_transaction *ps_tr;
  t_amount l_sum;
  PROGRESSBAR_DECL;
  UInt16 uh_cur_account, index;

  l_sum = 0;

  db = oTransactions->db;
  uh_cur_account = oTransactions->ps_prefs->ul_cur_category;

  PROGRESSBAR_BEGIN(DmNumRecords(db), strProgressBarAccountBalance);

  index = 0;
  while ((pv_tr = DmQueryNextInCategory(db, &index, uh_cur_account)) // PG
	 != NULL)
  {
    ps_tr = MemHandleLock(pv_tr);

    if (ps_tr->ui_rec_checked)
      l_sum += ps_tr->l_amount;

    MemHandleUnlock(pv_tr);

    PROGRESSBAR_INLOOP(index, 50); // OK

    index++;
  }

  PROGRESSBAR_END;

  [self replaceField:REPLACE_FIELD_EXT | ClearingIntroTargetBalance
	withSTR:(Char*)l_sum
	len:REPL_FIELD_FDWORD | REPL_FIELD_SELTRIGGER_SIGN];
}


- (void)focusSum
{
  FieldType *ps_field;

  [self focusObject:ClearingIntroTargetBalance];

  // On sélectionne le champ entier
  ps_field = [self objectPtrId:ClearingIntroTargetBalance];
  FldSetSelection(ps_field, 0, FldGetTextLength(ps_field));
}

@end
