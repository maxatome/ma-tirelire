/* 
 * DescModesListForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Fri Aug 22 16:53:15 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jul  6 14:43:27 2007
 * Update Count    : 15
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: DescModesListForm.m,v $
 * Revision 1.7  2008/01/14 17:09:32  max
 * Switch to new mcc.
 *
 * Revision 1.6  2005/11/19 16:56:19  max
 * Redraws reworked.
 *
 * Revision 1.5  2005/08/31 19:43:06  max
 * Comment cleaning.
 *
 * Revision 1.4  2005/08/31 19:38:52  max
 * *** empty log message ***
 *
 * Revision 1.3  2005/08/28 10:02:26  max
 * Bug with update pending event corrected.
 *
 * Revision 1.2  2005/08/20 13:06:50  max
 * Updates are now genericaly managed by MaTiForm.
 * Use new form argument passing method.
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_DESCMODESLISTFORM
#include "DescModesListForm.h"

#include "MaTirelire.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


// Pour la méthode -showHideList:selItem:
#define NO_INIT_LIST	0x8000	// Pas d'init de la liste
#define SEL_ITEM_MASK	(~NO_INIT_LIST)

@implementation DescModesListForm

- (DescModesListForm*)free
{
  // Liberation de la liste
  [self->oDBItem listFree:self->ppa_list];

  return [super free];
}


- (Boolean)open
{
  ListPtr pt_lst;
  Char ra_title[32];

  self->b_modes_dialog = (self->uh_form_flags & DM_MODES_LIST_FORM) != 0;

  // Liste des modes
  if (self->b_modes_dialog)
  {
    self->oDBItem = (DBItem*)[oMaTirelire mode];
    SysCopyStringResource(ra_title, strTitleModesList);
  }
  // Liste des descriptions
  else
  {
    self->oDBItem = (DBItem*)[oMaTirelire desc];
    SysCopyStringResource(ra_title, strTitleDescList);
  }

  FrmCopyTitle(self->pt_frm, ra_title);

  self->uh_num = 0;    // On ne veut pas d'entrée "Indifférent" pour les modes
  self->ppa_list = [self->oDBItem listBuildInfos:NULL num:&self->uh_num
			largest:NULL];

  pt_lst = [self objectPtrId:DescModesList];

  LstSetDrawFunction(pt_lst, [self->oDBItem listDrawFunction]);

  [self showHideList:pt_lst selItem:0];

  return [super open];
}


- (void)showHideList:(ListPtr)pt_lst selItem:(UInt16)uh_sel_item
{
  UInt16 uh_flags = uh_sel_item;
  UInt16 ruh_show_hide_ids[4 + 1], *puh_show_hide;

  puh_show_hide = ruh_show_hide_ids;

  uh_sel_item &= SEL_ITEM_MASK;

  if (pt_lst == NULL)
    pt_lst = [self objectPtrId:DescModesList];

  if ((uh_flags & NO_INIT_LIST) == 0)
    // On initialise la liste et on regarde s'il y a ou non une flèche
    // de scroll dans la marge de droite
    [self->oDBItem rightMarginList:pt_lst num:self->uh_num
	 in:(struct __s_list_dbitem_buf*)self->ppa_list selItem:uh_sel_item];

  // Au moins un item dans la liste
  if (self->uh_num > 0)
  {
    /* Les disparitions d'abord */
    /* Pas de + */
    *puh_show_hide++ = SET_SHOW(DescModesListPlus, uh_sel_item > 0);

    /* Pas de - */
    *puh_show_hide++
      = SET_SHOW(DescModesListMinus, uh_sel_item < self->uh_num - 1);

    /* Pas de nouveau */
    *puh_show_hide++
      =SET_SHOW(DescModesListNew, self->uh_num < [self->oDBItem dbMaxEntries]);

    /* Il faut edit */
    *puh_show_hide++ = SET_SHOW(DescModesListEdit, 1);
  }
  // Aucun élément
  else
  {
    *puh_show_hide++ = SET_SHOW(DescModesListPlus, 0);
    *puh_show_hide++ = SET_SHOW(DescModesListEdit, 0);
    *puh_show_hide++ = SET_SHOW(DescModesListMinus, 0);

    *puh_show_hide++ = SET_SHOW(DescModesListNew, 1);
  }

  *puh_show_hide = 0;
  [self showHideIds:ruh_show_hide_ids];
}


- (void)redrawForm
{
  ListType *pt_lst = [self objectPtrId:DescModesList];

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
  return (self->uh_num < [self->oDBItem dbMaxEntries]);
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case DescModesListPlus:
    [self moveItem:winUp];
    break;

  case DescModesListMinus:
    [self moveItem:winDown];
    break;

  case DescModesListNew:
    self->uh_entry_index = dmMaxRecordIndex;
    if (self->b_modes_dialog)
      FrmPopupForm(EditModeFormIdx);
    else
      FrmPopupForm(EditDescFormIdx);
    break;

  case DescModesListEdit:
  {
    UInt16 uh_sel_item = LstGetSelection([self objectPtrId:DescModesList]);

    if (uh_sel_item != noListSelection)
    {
      self->uh_entry_selected = uh_sel_item; // Useful in -update: method

      if (self->b_modes_dialog)
      {
	// On passe l'index de l'enregistrement
	self->uh_entry_index = ((struct __s_list_mode_buf*)
				self->ppa_list)->ruh_list2index[uh_sel_item];
	FrmPopupForm(EditModeFormIdx);
      }
      else
      {
	// On passe l'index de l'enregistrement
	self->uh_entry_index = ((struct __s_list_desc_buf*)
				self->ppa_list)->ruh_list2index[uh_sel_item];
	FrmPopupForm(EditDescFormIdx);
      }
    }
  }
  break;

  case DescModesListOK:
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
  if (ps_list_select->listID == DescModesList)
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
    [self->oDBItem listFree:self->ppa_list];

    // Création de la nouvelle
    self->uh_num = 0;  // On ne veut pas d'entrée "Indifférent" pour les modes
    self->ppa_list = [self->oDBItem listBuildInfos:NULL num:&self->uh_num
			  largest:NULL];

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
      // Sert pour les OS < 3.2 voir -redrawForm
      self->b_item_edited = true;

    // Remplissage (le redraw va être fait avec l'événement redraw
    // envoyé automatiquement par le formulaire précédent)
    [self showHideList:NULL selItem:uh_sel_item];

    // Cas particulier : redessin si on a juste bougé le mode/desc
    if (ps_update->updateCode & frmMaTiUpdateEdit2ListRedraw)
      LstDrawList([self objectPtrId:DescModesList]);

    // Il faudra avertir Papa
    if (self->b_modes_dialog)
      self->ui_update_mati_list |= (frmMaTiUpdateList
				    | frmMaTiUpdateListModes);
    else
      self->ui_update_mati_list |= (frmMaTiUpdateList
				    | frmMaTiUpdateListDesc);

    // Il ne faut pas que la classe mère conserve cet événement pour
    // Papa, on s'en est chargé nous-mêmes une ligne au dessus.
    ps_update->updateCode = 0;
  }

  return [super callerUpdate:ps_update];
}


- (void)moveItem:(WinDirectionType)dir
{
  ListPtr pt_lst = [self objectPtrId:DescModesList];
  UInt16 index = LstGetSelection(pt_lst);

  if (index != noListSelection
      /* Test utile uniquement pour les touches HAUT/BAS */
      && (dir == winUp
	  ? (index > 0)
	  : (index < LstGetNumberOfItems(pt_lst) - 1)))
  {
    UInt16 uh_rec_index;

    if (self->b_modes_dialog)
      uh_rec_index
	= ((struct __s_list_mode_buf*)self->ppa_list)->ruh_list2index[index];
    else
      uh_rec_index
	= ((struct __s_list_desc_buf*)self->ppa_list)->ruh_list2index[index];

    // The ID of selected item is just before the string
    if ([self->oDBItem moveId:uh_rec_index direction:dir])
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
