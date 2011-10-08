/* 
 * ClearingListForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sam oct  8 22:45:38 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Jun 27 10:32:17 2006
 * Update Count    : 6
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: ClearingListForm.m,v $
 * Revision 1.7  2008/01/14 17:09:32  max
 * Switch to new mcc.
 *
 * Revision 1.6  2006/10/05 19:08:45  max
 * Last sort and sum choices are now saved in database preferences.
 *
 * Revision 1.5  2006/06/28 09:41:32  max
 * SumScrollList +newInForm: prototype changed.
 * Now call SumScrollList -updateWithoutRedraw.
 *
 * Revision 1.4  2005/11/19 16:56:22  max
 * Handle new ClearingAutoConfForm dialog.
 * Redraws reworked.
 *
 * Revision 1.3  2005/10/16 21:44:02  max
 * Correct list update code.
 * Add definition of -sumTypeWidgetChange (prevent a crash on T3).
 * Redraw last form before returning to it.
 *
 * Revision 1.2  2005/10/14 22:37:24  max
 * Add auto clearing and sort features.
 * Now correctly updates TransListForm.
 *
 * Revision 1.1  2005/10/11 18:27:53  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_CLEARINGLISTFORM
#include "ClearingListForm.h"

#include "ClearingIntroForm.h"
#include "ClearingScrollList.h"
#include "ClearingAutoConfForm.h"

#include "MaTirelire.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX

#include "float.h"


@implementation ClearingListForm

- (Boolean)open
{
  struct s_mati_prefs *ps_prefs;
  ListType *pt_list;
  // Si passage en 64 bits penser à modifier le STR(12) dans obj.rcp
  Char ra_title[1 + 9 + 1 + 1];
  DateTimeType s_datetime;

  ps_prefs = [oMaTirelire getPrefs];

  // Type de tri
  pt_list = [self objectPtrId:ClearingListSortList];
  LstSetSelection(pt_list, ps_prefs->ul_clearing_sort);
  CtlSetLabel([self objectPtrId:ClearingListSortPopup],
	      LstGetSelectionText(pt_list, ps_prefs->ul_clearing_sort));

  // On initialise le type de somme
  self->b_left_sum = ps_prefs->ul_clearing_sum;

  self->oList = (SumScrollList*)[ClearingScrollList newInForm:(BaseForm*)self];

  [self swapSumType];

  // On place le solde visé dans le titre
  Str100FToA(ra_title, TARGET_BALANCE, NULL,
	     oMaTirelire->s_misc_infos.a_dec_separator);
  FrmCopyTitle(self->pt_frm, ra_title);

  // On garde la lettre correspondant au pointage auto
#define pa_autoclear_but CtlGetLabel([self objectPtrId:ClearingListAutoClear])
  self->a_autoclearing_char = pa_autoclear_but[0];
#undef pa_autoclear_but

  // Pour le pointage auto, par défaut on s'arrête à la date d'aujourd'hui
  TimSecondsToDateTime(TimGetSeconds(), &s_datetime);
  self->s_clear_auto_form.s_date.day = s_datetime.day;
  self->s_clear_auto_form.s_date.month = s_datetime.month;
  self->s_clear_auto_form.s_date.year = s_datetime.year - firstYear;

  return [super open];
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  if ([super ctlSelect:ps_select])
    return true;

  switch (ps_select->controlID)
  {
  case ClearingListQuit:
    // Aucune opération pointé
    if ([(ClearingScrollList*)self->oList isCleared] == 0)
    {
      // On retourne sur le formulaire d'intro et on y recalcule le
      // solde visé
      [self sendCallerUpdate:(frmMaTiUpdateClearingForm
			      | frmMaTiUpdateClearingFormUpdate)];

      [self returnToLastForm];
    }
    // Au moins une opération pointée
    else
    {
      struct s_account_prop *ps_prop;
      Boolean b_stmt_num;

      ps_prop
	= [[oMaTirelire transaction] accountProperties:ACCOUNT_PROP_CURRENT
				     index:NULL];
      b_stmt_num = ps_prop->ui_acc_stmt_num;
      MemPtrUnlock(ps_prop);

      // Pas de gestion des numéros de relevé
      if (b_stmt_num == false)
      {
	switch (FrmAlert(alertClearingConfirm))
	{
	case 0:			// Confirmation du pointage
	  [(ClearingScrollList*)self->oList changeInternalFlag:true stmtNum:0];

	  // Il faudra mettre à jour la liste des opérations
	  self->ui_update_mati_list |= (frmMaTiUpdateList
					| frmMaTiUpdateListTransactions);

	  // On retourne sur le formulaire d'intro et on le ferme
	  [self sendCallerUpdate:(frmMaTiUpdateClearingForm
				  | frmMaTiUpdateClearingFormClose)];

	  [self returnToLastForm];
	  break;

	default:		// case 1: On retourne à la liste...
	  break;

	case 2:			// Annuler totalement le pointage
	  [(ClearingScrollList*)self->oList changeInternalFlag:false
				stmtNum:0];

	  // On retourne sur le formulaire d'intro et on y recalcule le
	  // solde visé
	  [self sendCallerUpdate:(frmMaTiUpdateClearingForm
				  | frmMaTiUpdateClearingFormUpdate)];

	  [self returnToLastForm];
	  break;
	}
      }
      // Gestion des numéros de relevé
      else
      {
	// Si on est en mode "Reste" il faut repasser en "Pointés"
	if (self->b_left_sum)
	  self->u.l_cleared_sum = TARGET_BALANCE - self->oList->l_sum;
	else
	  self->u.l_cleared_sum = self->oList->l_sum;

	FrmPopupForm(StatementNumFormIdx);
      }
    }
    break;

  case ClearingListNew:
    [self->oList deselectLine];
    TransFormCall(self->s_trans_form,
		  false,	// debit
		  0, 0,		// pre_desc
		  0, 0,		// copy
		  -1);
    break;

  case ClearingListPopup:
    [self swapSumType];
    [(ClearingScrollList*)self->oList swapSumType];
    break;

  case ClearingListSortPopup:
  {
    ListType *pt_list = [self objectPtrId:ClearingListSortList];
    UInt16 index;

    index = LstPopupList(pt_list);
    if (index != noListSelection
	&& [(ClearingScrollList*)self->oList changeSortType:index])
    {
      CtlSetLabel([self objectPtrId:ClearingListSortPopup],
		  LstGetSelectionText(pt_list, index));

      // On sauve le nouvel état dans les préférences de l'application
      [oMaTirelire getPrefs]->ul_clearing_sort = index;
    }
  }
  break;

  case ClearingListAutoClear:
    // Le pointage auto est en cours
    if ([(ClearingScrollList*)self->oList autoClearingRunning])
    {
      if ([(ClearingScrollList*)self->oList autoClearingNext])
	[self autoClearing:true];
    }
    else
      FrmPopupForm(ClearingAutoConfFormIdx);
    break;

  default:
    return false;
  }

  return true;
}


- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key
{
  if ([super keyDown:ps_key])
    return true;

  // On recherche si une macro existe avec ce raccourci
  return [self transFormShortcut:ps_key listID:ClearingListDescList
	       args:&self->s_trans_form];
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  switch (UPD_CODE(ps_update->updateCode))
  {
  case frmMaTiUpdateList:
    // Si les types, les modes ou les opérations ont changé, on met la
    // liste à jour, ça permettra de tout retrier si besoin
    if (ps_update->updateCode & (frmMaTiUpdateListTypes
				 | frmMaTiUpdateListModes
				 | frmMaTiUpdateListTransactions))
    {
      UInt16 uh_index;

      // Dans le cas d'une opération modifiée, on la rend visible dans
      // la liste
      if ((ps_update->updateCode & frmMaTiUpdateListTransactions)
	  && (uh_index = (ps_update->updateCode >> 16)) > 0)
	[self->oList setCurrentItem:SCROLLLIST_CURRENT_DONT_RELOAD | uh_index];

      [self->oList updateWithoutRedraw];

      // On efface le contenu de la liste, le redraw de retour sur notre
      // écran fera le reste
      TblEraseTable(self->oList->pt_table);
    }
    break;

  case frmMaTiUpdateClearingForm:
    //
    // C'est l'écran de saisie du numéro de relevé qui nous cause
    if (ps_update->updateCode & frmMaTiUpdateClearingFormClose)
    {
      UInt32 ui_update_code;

      // Il vient de nous donner un numéro de relevé à mettre en place
      // => "OK"
      if (ps_update->updateCode & frmMaTiUpdateClearingFormUpdate)
      {
	
	[(ClearingScrollList*)self->oList changeInternalFlag:true
			      stmtNum:self->u.ui_stmt_num];

	// Il faudra mettre à jour la liste des opérations
	self->ui_update_mati_list |= (frmMaTiUpdateList
				      | frmMaTiUpdateListTransactions);

	// On retourne sur le formulaire d'intro et on le ferme
	ui_update_code = (frmMaTiUpdateClearingForm
			  | frmMaTiUpdateClearingFormClose);
      }
      // Il veut juste qu'on revienne sur le formulaire d'intro
      // => "Tout annuler"
      else
      {
	// On retourne sur le formulaire d'intro et on y recalcule le
	// solde visé
	ui_update_code = (frmMaTiUpdateClearingForm
			  | frmMaTiUpdateClearingFormUpdate);
      }

      [self sendCallerUpdate:ui_update_code];

      [self returnToLastForm];
    }

    //
    // Il faut lancer le pointage auto
    if (ps_update->updateCode & frmMaTiUpdateClearingFormAuto)
    {
      if ([(ClearingScrollList*)self->oList autoClearingInit]
	  && [(ClearingScrollList*)self->oList autoClearingNext])
	[self autoClearing:true];
    }

    // Il ne faut pas que la classe mère conserve cet événement pour
    // Papa, on s'en est chargé nous-mêmes une ligne au dessus.
    ps_update->updateCode = 0;
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


- (void)swapSumType
{
  Char ra_buf[32];

  if (self->uh_form_drawn)
    [oMaTirelire getPrefs]->ul_clearing_sum = (self->b_left_sum ^= 1);

  SysStringByIndex(strClearingListSumTypes, self->b_left_sum,
		   ra_buf, sizeof(ra_buf));

  [self fillLabel:ClearingListPopup withSTR:ra_buf];

  // On redimensionne le champ de la somme
  [self sumFieldRepos];
}


- (void)autoClearing:(Boolean)b_continue
{
  Char ra_str[] = { b_continue ? '+' : self->a_autoclearing_char, 0 };
  [self fillLabel:ClearingListAutoClear withSTR:ra_str];
}

@end
