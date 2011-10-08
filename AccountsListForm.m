/* 
 * AccountsListForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mer jul  7 17:08:46 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Jul 16 13:54:11 2007
 * Update Count    : 30
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: AccountsListForm.m,v $
 * Revision 1.10  2008/01/14 17:28:16  max
 * Switch to new mcc.
 *
 * Revision 1.9  2006/10/05 19:08:42  max
 * Accounts list currency was not saved correctly. Corrected.
 * If Ma Tirelire is bound on a hard key, go to the next database when it
 * is pressed in this screen.
 *
 * Revision 1.8  2006/06/28 09:41:32  max
 * SumScrollList +newInForm: prototype changed.
 * Now call SumScrollList -updateWithoutRedraw.
 *
 * Revision 1.7  2006/06/23 13:24:53  max
 * No more need of fiveway.h with PalmSDK installed.
 * Add new Palm 5-way handling.
 *
 * Revision 1.6  2006/04/25 08:41:27  max
 * Don't take into account vchrHardPower char in hard keys handling.
 *
 * Revision 1.5  2005/11/19 16:56:19  max
 * Redraws reworked.
 *
 * Revision 1.4  2005/08/20 13:06:39  max
 * Currencies popup is now managed by SumListForm.
 * Stats can be called from this screen.
 * Update screen when transactions changed.
 *
 * Revision 1.3  2005/05/08 12:12:48  max
 * Move DBases popup list management to MaTiForm.m
 *
 * Revision 1.2  2005/02/19 17:12:09  max
 * More menu entries implemented
 * 5-way Tungsten works nows
 * "DB properties" & "back to DBs" entries swapped in DB popup menu.
 *
 * Revision 1.1  2005/02/09 22:57:21  max
 * First import.
 *
 * ==================== RCS ==================== */

#include <Common/System/palmOneNavigator.h>

#define EXTERN_ACCOUNTSLISTFORM
#include "AccountsListForm.h"

#include "MaTirelire.h"

#include "AccountsScrollList.h"

#include "db_list.h"

#include "ids.h"
#include "graph_defs.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX

#define MaxTitleWidth	(160 - 6 - (2 + AccountsListSelectListLargest + 2))


@implementation AccountsListForm

- (AccountsListForm*)free
{
  // On sauve la valeur de la devise si ça n'a pas été fait avant dans
  // -DBasesChangeTo:len:same:
  if (self->uh_currency != -1)
    [[oMaTirelire transaction] getPrefs]->ul_accounts_currency
      = self->uh_currency;

  if (self->pv_db_list != NULL)
    MemHandleFree(self->pv_db_list);

  return [super free];
}


- (void)DBasesChangeTo:(Char*)pa_db_name len:(UInt16)uh_db_name_len
		  same:(Boolean)b_current_db
{
  // Il faut sauver la devise courante maintenant, dans le -free il
  // sera trop tard, la base de compte aura changé...
  [[oMaTirelire transaction] getPrefs]->ul_accounts_currency
    = self->uh_currency;
  self->uh_currency = -1; // On va quitter l'écran, il ne faudra pas sauver

  [super DBasesChangeTo:pa_db_name len:uh_db_name_len same:b_current_db];
}


- (Boolean)menu:(UInt16)uh_id
{
  if ([super menu:uh_id])
    return true;

  switch (uh_id)
  {
    // Propriété de la base
  case AccountsListProperties:
    FrmPopupForm(DBasePropFormIdx);
    break;

  case AccountsListDBasesManage:
    [self gotoFormViaUpdate:DBasesListFormIdx];
    break;

  case AccountsListMenuStats:
    FrmPopupForm(StatsFormIdx);
    break;

  default:
    return false;
  }

  return true;
}


- (Boolean)open
{
  struct s_mati_prefs *ps_prefs;
  struct s_db_prefs *ps_db_prefs;
  ListType *pt_list;

  // On dit à Maman qu'on a un popup des devises...
  self->uh_subclasses_flags = SUMLISTFORM_HAS_CURRENCIES_POPUP;

  ps_db_prefs = [[oMaTirelire transaction] getPrefs];

  // La devise à utiliser avec son popup
  self->uh_currency = ps_db_prefs->ul_accounts_currency;
  [self reloadCurrenciesPopup];

  self->oList = (SumScrollList*)[AccountsScrollList newInForm:(BaseForm*)self];

  ps_prefs = [oMaTirelire getPrefs];

  // Nom de la base dans le titre
  [self displayPopupTitle:db_list_visible_name(ps_prefs->ra_last_db)
	maxWidth:MaxTitleWidth];

  switch (self->oList->uh_num_items)
  {
    // On simule l'appui sur le bouton "Nouveau" si on n'a aucun compte
  case 0:
    CtlHitControl([self objectPtrId:AccountsListNew]);
    break;

    // Pas de bouton "New"
  case MAX_ACCOUNTS:
    [self hideId:AccountsListNew];
    break;
  }

  // À droite de "New"
  [self sumTypeWidgetChange];

  // Filtre de somme (en haut à droite)
  pt_list = [self objectPtrId:AccountsListSelectList];
  LstSetSelection(pt_list, ps_db_prefs->ul_accounts_sel_type);
  CtlSetLabel([self objectPtrId:AccountsListSelectPopup],
	      LstGetSelectionText(pt_list, ps_db_prefs->ul_accounts_sel_type));

  [super open];

  // On affiche le bitmap du popup
  [self displayPopupBitmap];

  // Au prochain lancement on reviendra sur cet écran...
  ps_prefs->ul_first_form = FIRST_FORM_ACCOUNTS;

  return true;
}


- (void)redrawForm
{
  [super redrawForm];

  // On affiche le bitmap du popup
  [self displayPopupBitmap];
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  if ([super ctlSelect:ps_select])
    return true;

  switch (ps_select->controlID)
  {
  case AccountsListNew:
    self->h_account = -1;
    FrmPopupForm(AccountPropFormIdx);
    break;

  // Change le filtre de somme
  case AccountsListSelectPopup:
  {
    ListType *pt_list = [self objectPtrId:AccountsListSelectList];
    UInt16 uh_index;

    uh_index = LstPopupList(pt_list);
    if (uh_index != noListSelection)
    {
      CtlSetLabel(ps_select->pControl,
		  LstGetSelectionText(pt_list, uh_index));

      [(AccountsScrollList*)self->oList changeSumFilter:uh_index];
    }
  }
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

  // Touche spéciale
  if (ps_key->modifiers & virtualKeyMask)
  {
    switch (ps_key->chr)
    {
      // La touche directe
    case hardKeyMin ... hardKeyMax:
    case calcChr:
      // Passage à la prochaine base
      if ((ps_key->modifiers & poweredOnKeyMask) == 0
	  // Sauf s'il s'agit du bouton d'allumage
	  && ps_key->chr != vchrHardPower)
      {
	MemHandle hdl_dbs;
	UInt16 uh_num = 0;

	if (SysCreateDataBaseList(MaTiAccountsType, MaTiCreatorID, &uh_num,
				  &hdl_dbs, false) && uh_num > 0)
	{
	  // Il n'y aura pas de suivant
	  if (uh_num > 1)
	  {
	    SysDBListItemType *ps_dbids;
	    struct s_mati_prefs *ps_prefs = [oMaTirelire getPrefs];
	    UInt16 index;

	    ps_dbids = (SysDBListItemType*)MemHandleLock(hdl_dbs);

	    // Sort the list alphabeticaly
	    SysInsertionSort(ps_dbids, uh_num, sizeof(*ps_dbids),
			     (CmpFuncPtr)sort_string_compare, 0);

	    for (index = 0; index < uh_num; ps_dbids++, index++)
	    {
	      if (StrCompare(ps_prefs->ra_last_db, ps_dbids->name) == 0)
	      {
		if (index + 1 == uh_num)
		  ps_dbids -= index;
		else
		  ps_dbids++;

		[self DBasesChangeTo:ps_dbids->name len:StrLen(ps_dbids->name)
		      same:false];

		break;
	      }
	    }

	    MemHandleUnlock(hdl_dbs);
	  }

	  MemHandleFree(hdl_dbs);
	}

	return true;
      }
      break;

      // 5-way Tungsten
    case vchrNavChange:
      // On regarde le navigator pour dérouler le menu des bases
      if ((ps_key->modifiers & autoRepeatKeyMask) == 0
	  &&
	  (ps_key->keyCode & (navBitsAll | navChangeBitsAll))
	  == (navBitRight | navChangeRight))
      {
	[self penDown:NULL];
	return true;
      }
      break;

      // De NavSelectHSPressed()
    case vchrRockerRight:
      if (ps_key->modifiers & commandKeyMask)
      {
	[self penDown:NULL];
	return true;
      }
      break;
    }
  }

  return false;
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  switch (UPD_CODE(ps_update->updateCode))
  {
  case frmMaTiUpdateList:
    // La liste des bases a changé
    if (ps_update->updateCode & frmMaTiUpdateListDBases)
    {
      // Nom de la base dans le titre, le tout sera redessiné grâce au
      // redraw de retour sur notre écran
      [self displayPopupTitle:
	      db_list_visible_name([oMaTirelire getPrefs]->ra_last_db)
	    maxWidth:MaxTitleWidth];

      // On libère la liste des bases si besoin (normalement toujours
      // le cas puisque DBasePropForm a été appelé de là)
      if (self->pv_db_list != NULL)
      {
	MemHandleFree(self->pv_db_list);
	self->pv_db_list = NULL;
      }
    }

    // La liste des comptes OU BIEN des opérations a changé
    if (ps_update->updateCode & (frmMaTiUpdateListAccounts
				 | frmMaTiUpdateListTransactions))
    {
      [self->oList updateWithoutRedraw];

      // On remplace la somme
      [self->oList displaySum];

      // On efface le contenu de la liste, le redraw de retour sur
      // notre écran fera le reste
      TblEraseTable(self->oList->pt_table);

      // Normalement, test à faire seulement si la liste des comptes...
      if (self->oList->uh_num_items == MAX_ACCOUNTS)
	[self hideId:AccountsListNew];
    }    
    break;
  }

  return [super callerUpdate:ps_update];
}


- (Boolean)penDown:(EventType*)e
{
  // Pas besoin de FrmPointInTitle(), car si screenX <= 12 alors
  // forcément on est dans le titre...
  if (e == NULL || (e->screenX <= 12 && e->screenY <= 14))
  {
    [self DBasesPopupList:AccountsListDBases in:&self->pv_db_list
	  calledAsSubMenu:false];
    return true;
  }

  return false;
}

@end
