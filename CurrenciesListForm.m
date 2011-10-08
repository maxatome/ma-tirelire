/* 
 * CurrenciesListForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Fri May 21 23:51:02 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Jul 17 13:53:59 2007
 * Update Count    : 22
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: CurrenciesListForm.m,v $
 * Revision 1.6  2008/01/14 17:16:18  max
 * Switch to new mcc.
 * External currencies handling reworked.
 *
 * Revision 1.5  2006/04/25 08:46:41  max
 * Add last rates date/time in dialog now based on last modification
 * date/time of the external currencies database.
 *
 * Revision 1.4  2005/11/19 16:56:19  max
 * Redraws reworked.
 *
 * Revision 1.3  2005/08/28 10:02:26  max
 * Bug with update pending event corrected.
 *
 * Revision 1.2  2005/08/20 13:06:45  max
 * Updates are now genericaly managed by MaTiForm.
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_CURRENCIESLISTFORM
#include "CurrenciesListForm.h"

#include "MaTirelire.h"
#include "ExternalCurrencyGlobal.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


// Pour la méthode -showHideList:selItem:
#define NO_INIT_LIST	0x8000	// Pas d'init de la liste
#define SEL_ITEM_MASK	(~NO_INIT_LIST)

@implementation CurrenciesListForm

- (CurrenciesListForm*)free
{
  // Libération de la liste principale
  [self->oCurrency listFree:self->ppa_list];

  // Libération de la liste désignant LA devise de référence
  [self->oCurrency popupListFree:self->pv_ref_list];

  return [super free];
}


- (Boolean)open
{
  ListType *pt_lst;
  UInt32 rui_last_upd_dates[EXTERNAL_CURRENCIES_NUM];
  UInt32 ui_last_update_date;

  self->oCurrency = [oMaTirelire currency];

  // Liste principale des devises
  self->uh_num = 0;
  self->ppa_list = [self->oCurrency listBuildInfos:NULL
			num:&self->uh_num largest:NULL];
  pt_lst = [self objectPtrId:CurrenciesList];

  LstSetDrawFunction(pt_lst, [self->oCurrency listDrawFunction]);

  [self showHideList:pt_lst selItem:0];

  // Popup listant LA devise de référence
  self->pv_ref_list = [self->oCurrency popupListInit:CurrenciesRefList
			   form:self->pt_frm
			   Id:[self->oCurrency referenceId]
			   forAccount:(char*)-1];

  // Dates de la dernière mise à jour
  [self->oCurrency getLastUpdateDates:rui_last_upd_dates];

  // On prend la plus récente
#if EXTERNAL_CURRENCIES_NUM == 1
  ui_last_update_date = rui_last_upd_dates[0];
#elif EXTERNAL_CURRENCIES_NUM == 2
  ui_last_update_date = rui_last_upd_dates[0] > rui_last_upd_dates[1]
    ? rui_last_upd_dates[0] : rui_last_upd_dates[1];
#else
  {
    UInt16 index;

    ui_last_update_date = 0;
    for (index = 0; index < EXTERNAL_CURRENCIES_NUM; index++)
      if (rui_last_upd_dates[index] > ui_last_update_date)
	ui_last_update_date = rui_last_upd_dates[index];
  }
#endif

  if (ui_last_update_date != 0)
  {
    Char *pa_str;
    Char ra_date[dateStringLength + timeStringLength];
    DateTimeType s_last_update_date;

    TimSecondsToDateTime(ui_last_update_date, &s_last_update_date);

    DateToAscii(s_last_update_date.month, s_last_update_date.day,
		s_last_update_date.year,
		(DateFormatType)PrefGetPreference(prefDateFormat), ra_date);

    pa_str = ra_date + StrLen(ra_date);
    *pa_str++ = ' ';

    TimeToAscii(s_last_update_date.hour, s_last_update_date.minute,
		(TimeFormatType)PrefGetPreference(prefTimeFormat), pa_str);

    [self fillLabel:CurrenciesListDate withSTR:ra_date];
  }
  else
  {
    [self hideId:CurrenciesListBeforeDate];
    [self hideId:CurrenciesListDate];
  }

  return [super open];
}


- (void)showHideList:(ListPtr)pt_lst selItem:(UInt16)uh_sel_item
{
  UInt16 uh_flags = uh_sel_item;
  UInt16 ruh_show_hide_ids[4 + 1], *puh_show_hide;

  puh_show_hide = ruh_show_hide_ids;

  uh_sel_item &= SEL_ITEM_MASK;

  if (pt_lst == NULL)
    pt_lst = [self objectPtrId:CurrenciesList];

  if ((uh_flags & NO_INIT_LIST) == 0)
    // On initialise la liste et on regarde s'il y a ou non une flèche
    // de scroll dans la marge de droite
    [self->oCurrency rightMarginList:pt_lst num:self->uh_num
	 in:(struct __s_list_dbitem_buf*)self->ppa_list selItem:uh_sel_item];

  // Au moins un item dans la liste
  if (self->uh_num > 0)
  {
    /* Les disparitions d'abord */
    /* Pas de + */
    *puh_show_hide++ = SET_SHOW(CurrenciesListPlus, uh_sel_item > 0);

    /* Pas de - */
    *puh_show_hide++ = SET_SHOW(CurrenciesListMinus,
				uh_sel_item < self->uh_num - 1);

    /* Pas de nouveau */
    *puh_show_hide++ = SET_SHOW(CurrenciesListNew,
				self->uh_num < [self->oCurrency dbMaxEntries]);

    /* Il faut edit */
    *puh_show_hide++ = SET_SHOW(CurrenciesListEdit, 1);
  }
  // Aucun élément
  else
  {
    *puh_show_hide++ = SET_SHOW(CurrenciesListPlus, 0);
    *puh_show_hide++ = SET_SHOW(CurrenciesListEdit, 0);
    *puh_show_hide++ = SET_SHOW(CurrenciesListMinus, 0);

    *puh_show_hide++ = SET_SHOW(CurrenciesListNew, 1);
  }

  *puh_show_hide = 0;
  [self showHideIds:ruh_show_hide_ids];
}


- (void)redrawForm
{
  ListType *pt_lst = [self objectPtrId:CurrenciesList];

  if (self->uh_num > 0)
    LstMakeItemVisible(pt_lst, self->uh_entry_selected);

  FrmDrawForm(self->pt_frm);

  // Si on est sur une rom < 3.2, il faut redessiner 2 fois de suite
  // la liste en cas d'ajout/suppression/édition d'élément...
  if (oMaTirelire->ul_rom_version < 0x03203000)
  {
    if (self->b_item_edited)
    {
      self->b_item_edited = false;
      LstDrawList(pt_lst);
    }
    LstDrawList(pt_lst);
  }
}


//
// Used by child to know if it's new or edit action
- (UInt16)editedEntryIndex
{
  return self->uh_entry_index;
}


//
// Used by child to know if it can display a new button (max items
// number not yet reached)
- (Boolean)isChildNewButton
{
  return (self->uh_num < [self->oCurrency dbMaxEntries]);
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case CurrenciesListPlus:
    [self moveItem:winUp];
    break;

  case CurrenciesListMinus:
    [self moveItem:winDown];
    break;

  case CurrenciesListNew:
    self->uh_entry_index = dmMaxRecordIndex;
    FrmPopupForm(EditCurrencyFormIdx);
    break;

  case CurrenciesListEdit:
  {
    UInt16 uh_sel_item = LstGetSelection([self objectPtrId:CurrenciesList]);

    if (uh_sel_item != noListSelection)
    {
      struct s_currency *ps_currency;

      self->uh_entry_selected = uh_sel_item; // Useful in -update: method

      // On passe l'index de l'enregistrement
      self->uh_entry_index = ((struct __s_list_currency_buf*)
			      self->ppa_list)->ruh_list2index[uh_sel_item];

      ps_currency =
	[self->oCurrency getId:ITEM_SET_DIRECT(self->uh_entry_index)];

      FrmPopupForm(ps_currency->ui_reference
		   ? EditReferenceCurrencyFormIdx
		   : EditCurrencyFormIdx);

      [self->oCurrency getFree:ps_currency];
    }
  }
  break;

  case CurrenciesRefPopup:
  {
    UInt16 uh_ref_id = [self->oCurrency popupList:self->pv_ref_list];
    if (uh_ref_id != noListSelection
	&& [self->oCurrency changeReferenceToId:uh_ref_id])
    {
      struct frmCallerUpdate s_update;

      // La devise de référence vient de changer, il faut rafraichir
      // la liste détaillée
      s_update.updateCode = frmMaTiUpdateEdit2List | frmDontUpdateRefList;
      guh_pending_events++;
      [self callerUpdate:&s_update]; // guh_pending_events OK

      // Si on est sur une rom < 3.2, il faut redessiner 2 fois de
      // suite la liste
      if (oMaTirelire->ul_rom_version < 0x03203000)
	LstDrawList([self objectPtrId:CurrenciesList]);
    }
  }
  break;

  case CurrenciesListOK:
    // Retour au formulaire précédent...
    [self returnToLastForm];
    break;

  default:
    return false;
  }

  return true;
}


- (Boolean)lstSelect:(struct lstSelect *)ps_list_select
{
  if (ps_list_select->listID == CurrenciesList)
  {
    [self showHideList:ps_list_select->pList
	  selItem:NO_INIT_LIST | ps_list_select->selection];
    return true;
  }

  return false;
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  if (ps_update->updateCode & frmMaTiUpdateEdit2List)
  {
    UInt16 uh_sel_item = self->uh_entry_selected;

    // Destruction de l'ancienne liste
    [self->oCurrency listFree:self->ppa_list];

    // Création de la nouvelle
    self->uh_num = 0;
    self->ppa_list = [self->oCurrency listBuildInfos:NULL
			  num:&self->uh_num largest:NULL];

    // The edited item is deleted => new selected is previous if any
    if ((ps_update->updateCode & frmMaTiUpdateEdit2ListDeletedItem)
	&& uh_sel_item != 0)
      uh_sel_item--;

    // A new item was added => just after current OR at end
    if (ps_update->updateCode & frmMaTiUpdateEdit2ListNewItem)
    {
      if (ps_update->updateCode & frmMaTiUpdateEdit2ListNewItemAfter)
	uh_sel_item++;
      else
	uh_sel_item = self->uh_num - 1;
    }

    // Il s'agit d'un vrai update, pas juste un item qui bouge...
    if ((ps_update->updateCode & frmMaTiUpdateEdit2ListAfterMove) == 0)
      // Sert pour les OS < 3.2 voir -showHideList:selItem:
      self->b_item_edited = true;

    // Remplissage (le redraw va être fait avec l'événement redraw
    // envoyé automatiquement par le formulaire précédent)
    [self showHideList:NULL selItem:uh_sel_item];

    // Cas particulier : redessin si on a juste bougé la devise
    if (ps_update->updateCode & frmMaTiUpdateEdit2ListRedraw)
      LstDrawList([self objectPtrId:CurrenciesList]);

    // On reconstruit le popup de la monnaie de référence
    if ((ps_update->updateCode & frmDontUpdateRefList) == 0)
    {
      [self->oCurrency popupListFree:self->pv_ref_list];
      self->pv_ref_list = [self->oCurrency popupListInit:CurrenciesRefList
			       form:self->pt_frm
			       Id:[self->oCurrency referenceId]
			       forAccount:(char*)-1];
    }

    // Un changement a eu lieu : il faudra signaler notre père...
    self->ui_update_mati_list |=
      (frmMaTiUpdateList | frmMaTiUpdateListCurrencies);

    // Il ne faut pas que la classe mère conserve cet événement pour
    // Papa, on s'en est chargé nous-mêmes une ligne au dessus.
    ps_update->updateCode = 0;
  }

  return [super callerUpdate:ps_update];
}


- (void)moveItem:(WinDirectionType)dir
{
  ListPtr pt_lst = [self objectPtrId:CurrenciesList];
  UInt16 index = LstGetSelection(pt_lst);

  if (index != noListSelection
      /* Test utile uniquement pour les touches HAUT/BAS */
      && (dir == winUp
	  ? (index > 0)
	  : (index < LstGetNumberOfItems(pt_lst) - 1)))
  {
    UInt16 uh_rec_index;

    uh_rec_index
      = ((struct __s_list_currency_buf*)self->ppa_list)->ruh_list2index[index];

    if ([self->oCurrency moveId:uh_rec_index direction:dir])
    {
      struct frmCallerUpdate s_update;

      self->uh_entry_selected = index + (dir == winUp ? -1 : 1);

      s_update.updateCode = (frmMaTiUpdateEdit2List
			     | frmMaTiUpdateEdit2ListAfterMove
			     | frmMaTiUpdateEdit2ListRedraw);
      guh_pending_events++;
      [self callerUpdate:&s_update]; // guh_pending_events OK
    }
  }
}

@end
