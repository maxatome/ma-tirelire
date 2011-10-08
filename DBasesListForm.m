/* 
 * DBasesListForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mer jui 30 22:06:43 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jul  6 14:43:10 2007
 * Update Count    : 18
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: DBasesListForm.m,v $
 * Revision 1.8  2008/01/14 17:09:32  max
 * Switch to new mcc.
 *
 * Revision 1.7  2006/10/05 19:08:52  max
 * Redraw screen correctly after a database clone.
 *
 * Revision 1.6  2006/06/19 12:23:52  max
 * Now has a menu which includes an entry to check & correct erroneous
 * databases.
 *
 * Revision 1.5  2005/11/19 16:56:26  max
 * Redraws reworked.
 * Current database or last edited one is now selected in list.
 *
 * Revision 1.4  2005/08/20 13:06:48  max
 * Updates are now genericaly managed by MaTiForm.
 *
 * Revision 1.3  2005/05/08 12:12:56  max
 * Rework access code checking. Works now well when appStopEvent occurred.
 * Code cleaning.
 *
 * Revision 1.2  2005/03/27 15:38:22  max
 * Accounts databases can now be cloned.
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_DBASESLISTFORM
#include "DBasesListForm.h"

#include "MaTirelire.h"
#include "DBasePropForm.h"

#include "db_list.h"
#include "ids.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


@implementation DBasesListForm

- (DBasesListForm*)free
{
  if (self->pv_list != NULL)
  {
    MemHandleUnlock(self->pv_list);
    MemHandleFree(self->pv_list);
  }

  return [super free];
}


- (Boolean)checkAccess:(UInt16)uh_index
{
  UInt32 ul_access_code;
  void *pv_access_code;
  SysDBListItemType *ps_db;
  UInt16 uh_size;
  Int16 h_ret;

  if (uh_index == noListSelection)
    return false;

  pv_access_code = &ul_access_code;
  ps_db = &self->ps_dbs[uh_index];
  uh_size = sizeof(ul_access_code);

  // Récupération du code d'accès
  if (db_app_info_block_load(ps_db->cardNo, ps_db->dbID,
			     &pv_access_code, &uh_size, true))
  {
    // XXX
    return false;
  }

  if (ul_access_code != 0
      // On demande le code d'accès à la base
      && (h_ret = [oMaTirelire passwordDialogCode:ul_access_code
			       label:PasswordDataBase
			       flags:PW_FORMAT|PW_RTOFORM,
			       db_list_visible_name(ps_db->name)]) <= 0)
  {
    // Code incorrect (sans appStopEvent)
    if (h_ret == 0)
      FrmAlert(alertPasswordBadCode);
    return false;
  }

  return true;
}


- (Boolean)menu:(UInt16)uh_id
{
  if ([super menu:uh_id])
    return true;

  if (uh_id == DBasesListCorrect)
  {
    if ([oMaTirelire checkAndCorrectDBs] == false)
      FrmAlert(alertAllBasesAreOK);

    return true;
  }

  return false;
}


- (Boolean)open
{
  struct s_mati_prefs *ps_prefs;

  // Au cas où une base des comptes est ouverte, on la ferme...
  [oMaTirelire freeTransaction];

  ps_prefs = [oMaTirelire getPrefs];

  // Au prochain lancement on reviendra sur cet écran...
  ps_prefs->ul_first_form = FIRST_FORM_DBASES;

  // Sélection de la base par défaut des préférences
  [self showHideList:NULL selItem:ps_prefs->ra_last_db];

  [super open];

  // On simule l'appui sur le bouton "Nouvelle"
  if (self->uh_num == 0)
    CtlHitControl([self objectPtrId:DBasesListNew]);

  return true;
}


- (void)showHideList:(ListPtr)pt_lst selItem:(Char*)pa_sel_db
{
  Char **ppa_list;
  UInt16 ruh_show_hide_ids[2 + 1], *puh_show_hide;
  UInt16 uh_sel_item, index;

  puh_show_hide = ruh_show_hide_ids;

  if (pt_lst == NULL)
    pt_lst = [self objectPtrId:DBasesList];

  self->ps_dbs = NULL;
  ppa_list = NULL;

  self->pv_list = db_list_new(MaTiCreatorID, MaTiAccountsType,
			      &self->uh_num, NULL, 0, 0, false);

  if (self->pv_list != NULL)
  {
    ppa_list = MemHandleLock(self->pv_list);
    self->ps_dbs = (SysDBListItemType*)&ppa_list[self->uh_num];

    uh_sel_item = 0;
    if (pa_sel_db != NULL)
      for (index = 0; index < self->uh_num; index++)
	if (StrCompare(pa_sel_db, self->ps_dbs[index].name) == 0)
	{
	  uh_sel_item = index;
	  break;
	}
  }
  else
    uh_sel_item = noListSelection;

  LstSetListChoices(pt_lst, ppa_list, self->uh_num);
  LstSetSelection(pt_lst, uh_sel_item);

  if (self->uh_num == 0)
  {
    *puh_show_hide++ = SET_SHOW(DBasesListProperties, 0);
    *puh_show_hide++ = SET_SHOW(DBasesListOpen, 0);
  }
  else
  {
    *puh_show_hide++ = SET_SHOW(DBasesListProperties, 1);
    *puh_show_hide++ = SET_SHOW(DBasesListOpen, 1);
  }

  *puh_show_hide++ = 0;
  [self showHideIds:ruh_show_hide_ids];
}


- (void)redrawForm
{
  ListType *pt_lst = [self objectPtrId:DBasesList];

  if (self->uh_num > 0 && self->h_entry_index >= 0)
    LstMakeItemVisible(pt_lst, self->h_entry_index);

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


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  if (ps_select->controlID == DBasesListNew)
  {
    self->h_entry_index = -1;
    FrmPopupForm(DBasePropFormIdx);
  }
  else
  {
    UInt16 index = LstGetSelection([self objectPtrId:DBasesList]);
    if ([self checkAccess:index])
      switch (ps_select->controlID)
      {
      case DBasesListOpen:
	// On modifie les préférences générales avant de passer à
	// l'écran des comptes
	MemMove([oMaTirelire getPrefs]->ra_last_db,
		self->ps_dbs[index].name, dmDBNameLength);

	if ([oMaTirelire newTransaction:nil] != nil)
	  [self gotoFormViaUpdate:AccountsListFormIdx];
	break;

      case DBasesListProperties:
	self->h_entry_index = index;
	FrmPopupForm(DBasePropFormIdx);
	break;

      case DBasesListClone:
	[self cloneDB:index];
	break;

      default:
	return false;
      }
  }

  return true;
}


//
// Used by child to know if it's new or edit action
- (SysDBListItemType*)editedDB
{
  if (self->h_entry_index < 0)
    return NULL;

  return &self->ps_dbs[self->h_entry_index];
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  switch (UPD_CODE(ps_update->updateCode))
  {
  case frmMaTiUpdateList:
    // La liste des bases a changé
    if (ps_update->updateCode & frmMaTiUpdateListDBases)
    {
      // Destruction de l'ancienne liste
      if (self->pv_list != NULL)
      {
	MemHandleUnlock(self->pv_list);
	MemHandleFree(self->pv_list);
      }

      self->b_item_edited = true;

      // Remplissage (le redraw va être fait avec l'événement redraw
      // envoyé automatiquement par le formulaire précédent)
      [self showHideList:NULL selItem:self->ra_db_name];
    }
    break;
  }

  return [super callerUpdate:ps_update];
}


- (void)cloneDB:(UInt16)index
{
  Transaction *oTransactions, *oClone;
  Char *pa_orig_name;
  Char ra_clone_fmt[sizeof(MaTiAcntPrefix) + 15];
  Char ra_clone_name[dmDBNameLength + sizeof(ra_clone_fmt)];
  UInt16 uh_fmt_pos = 0;

  oTransactions = [[Transaction alloc]
		    initWithCardNo:self->ps_dbs[index].cardNo
		    withID:self->ps_dbs[index].dbID];
  if (oTransactions == nil)
    return;

  pa_orig_name = db_list_visible_name(self->ps_dbs[index].name);

  // Le format pour le nom du clone, précédé par notre préfixe s'il
  // était présent avant
  if (pa_orig_name != self->ps_dbs[index].name)
  {
    MemMove(ra_clone_fmt, MaTiAcntPrefix, sizeof(MaTiAcntPrefix) - 1);
    uh_fmt_pos = sizeof(MaTiAcntPrefix) - 1;
  }
  SysCopyStringResource(&ra_clone_fmt[uh_fmt_pos], strDBasesListCloneFmt);
  
  StrPrintF(ra_clone_name, ra_clone_fmt, pa_orig_name);
  ra_clone_name[dmDBNameLength - 1] = '\0'; // On tronque au cas où

  oClone = [oTransactions clone:ra_clone_name];
  [oTransactions free];

  // Le clonage a réussi, la liste des bases a donc changé...
  if (oClone != nil)
  {
    extern void UniqueUpdateForm(UInt16 formID, UInt16 code);

    [oClone free];

    // Pour nous-mêmes...
    [self sendCallerUpdate:frmMaTiUpdateList | frmMaTiUpdateListDBases]; // OK

    // On envoie un redraw, car personne ne va le faire pour nous
    UniqueUpdateForm(FrmGetFormId(self->pt_frm), frmRedrawUpdateCode);
  }
} 

@end
