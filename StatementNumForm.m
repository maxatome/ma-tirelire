/* 
 * StatementNumForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Lun oct 10 21:36:26 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Jun 22 15:09:41 2006
 * Update Count    : 1
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: StatementNumForm.m,v $
 * Revision 1.4  2008/01/14 16:24:22  max
 * Switch to new mcc.
 * LstSetSelection: s/noListSelection/0/g.
 *
 * Revision 1.3  2006/06/23 13:24:43  max
 * Now call -focusObject: instead of FrmSetFocus() to set focus to a field.
 *
 * Revision 1.2  2005/11/19 16:56:31  max
 * Can now be called from TransListForm when transforming flagged to
 * checked.
 *
 * Revision 1.1  2005/10/11 18:27:53  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_STATEMENTNUMFORM
#include "StatementNumForm.h"

#include "MaTirelire.h"
#include "Currency.h"
#include "ClearingListForm.h"
#include "TransListForm.h"

#include "ProgressBar.h"

#include "float.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


@implementation StatementNumForm

- (Boolean)open
{
  Transaction *oTransactions = [oMaTirelire transaction];
  Currency *oCurrencies = [oMaTirelire currency];
  struct s_currency *ps_currency;
  t_amount l_cleared_sum;
  Char ra_num[1 + AMOUNT_LEN + 1];
  UInt16 uh_len;

  // Recherche du numéro de relevé courant et du suivant
  self->ul_last_stmt_num = [oTransactions getLastStatementNumber];
  if (self->ul_last_stmt_num != 0)
  {
    // Par défaut on met le dernier + 1
    [self replaceField:REPLACE_FIELD_EXT | StatementNumNum
	  withSTR:(Char*)(self->ul_last_stmt_num + 1) len:REPL_FIELD_DWORD];

    // On sélectionne la première entrée
    LstSetSelection([self objectPtrId:StatementNumList], 0);
  }
  else
    [self hideId:StatementNumPopup];

  // Le solde avec la devise du compte

  // On vient de l'écran de pointage
  if ([(Object*)self->oPrevForm->oIsa isKindOf:ClearingListForm])
    l_cleared_sum = ((ClearingListForm*)oFrm->oPrevForm)->u.l_cleared_sum;
  // On vient de la liste des opération en voulant transformer les
  // marqués en pointés (TransListForm)
  else
  {
    // Si on est déjà dans ce type de somme, il n'y a rien à calculer
    if (oTransactions->ps_prefs->ul_sum_type == VIEW_CHECKNMARKED)
      l_cleared_sum
	= ((SumScrollList*)((TransListForm*)self->oPrevForm)->oList)->l_sum;
    else
    {
      MemHandle vh_rec;
      struct s_transaction *ps_tr;
      UInt16 uh_record_num = 0, uh_account;
      PROGRESSBAR_DECL;

      uh_account = oTransactions->ps_prefs->ul_cur_category;

      l_cleared_sum = 0;

      PROGRESSBAR_BEGIN(DmNumRecords(oTransactions->db),
			strProgressBarAccountBalance);

      while ((vh_rec = DmQueryNextInCategory(oTransactions->db,	// PG
					     &uh_record_num,
					     uh_account)) != NULL)
      {
	ps_tr = MemHandleLock(vh_rec);

	// OK pour les propriétés de compte
	if (ps_tr->ui_rec_flags & (RECORD_MARKED|RECORD_CHECKED))
	  l_cleared_sum += ps_tr->l_amount;

	MemHandleUnlock(vh_rec);

	PROGRESSBAR_INLOOP(uh_record_num, 50);

	uh_record_num++;	/* Suivant */
      }

      PROGRESSBAR_END;
    }

    // Dans ce cas il n'y a pas le bouton "Tout annuler"
    [self hideId:StatementNumCancelClearing];
  }

  Str100FToA(ra_num, l_cleared_sum, &uh_len,
	     oMaTirelire->s_misc_infos.a_dec_separator);
  ra_num[uh_len++] = ' ';

  ps_currency = [oCurrencies getId:[oTransactions
				     accountCurrency:ACCOUNT_PROP_CURRENT]];
  StrCopy(&ra_num[uh_len], ps_currency->ra_name);
  [oCurrencies getFree:ps_currency];

  [self fillLabel:StatementNumBalance withSTR:ra_num];

  [super open];

  // On place le focus sur le premier champ de la boîte
  [self focusObject:StatementNumNum];

  return true;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case StatementNumPopup:
  {
    ListType *pt_list = [self objectPtrId:StatementNumList];
    UInt16 index;

    index = LstPopupList(pt_list);
    if (index != noListSelection)
    {
      // On sélectionne la première entrée
      LstSetSelection(pt_list, 0);

      [self replaceField:REPLACE_FIELD_EXT | StatementNumNum
	    withSTR:(Char*)(self->ul_last_stmt_num + index)
	    len:REPL_FIELD_DWORD];
    }
  }
  break;

  case StatementNumOK:
  {
    UInt32 ui_stmt_num;

    [self checkField:StatementNumNum flags:FLD_TYPE_DWORD
	  resultIn:&ui_stmt_num fieldName:FLD_NO_NAME];

    // Pas de numéro de relevé ou nul, on demande confirmation
    if (ui_stmt_num == 0 && FrmAlert(alertStatementNumberConfirmEmpty) == 0)
      break;

    // Si on vient de l'écran de pointage
    if ([(Object*)self->oPrevForm->oIsa isKindOf:ClearingListForm])
    {
      ((ClearingListForm*)oFrm->oPrevForm)->u.ui_stmt_num = ui_stmt_num;

      // Retour sur l'écran de pointage qui va mettre à jour les
      // opérations, puis fermeture de celui-ci
      [self sendCallerUpdate:(frmMaTiUpdateClearingForm
			      | frmMaTiUpdateClearingFormUpdate
			      | frmMaTiUpdateClearingFormClose)];
    }
    // On vient de la liste des opération en voulant transformer les
    // marqués en pointés (TransListForm)
    else
    {
      if ([[oMaTirelire transaction] changeFlaggedToChecked:ui_stmt_num])
	self->ui_update_mati_list |= (frmMaTiUpdateList
				      | frmMaTiUpdateListTransactions);
    }
  }
      
  // Continue...

  case StatementNumBackClearing:
    [self returnToLastForm];
    break;

    // Ce bouton n'est pas présent si on vient de la liste des opérations
  case StatementNumCancelClearing:
    // On retourne directement sur le formulaire d'intro et on y
    // recalcule le solde visé. Pour ce faire, on ferme juste le
    // précédent (l'écran de pointage).
    [self sendCallerUpdate:(frmMaTiUpdateClearingForm
			    | frmMaTiUpdateClearingFormClose)];

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
      && FrmGetObjectId(self->pt_frm, fld_id) == StatementNumNum)
    return [self keyFilter:KEY_FILTER_INT | fld_id for:ps_key];

  return false;
}

@end
