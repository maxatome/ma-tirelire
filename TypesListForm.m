/* 
 * TypesListForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sun Feb 15 21:10:29 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Nov 18 13:52:18 2005
 * Update Count    : 8
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: TypesListForm.m,v $
 * Revision 1.5  2008/01/14 13:09:35  max
 * Switch to new mcc.
 *
 * Revision 1.4  2005/11/19 16:56:19  max
 * Redraws reworked.
 *
 * Revision 1.3  2005/08/28 10:02:41  max
 * Update previous form when fold/unfold type.
 *
 * Revision 1.2  2005/08/20 13:07:18  max
 * Some cleaning.
 * Updates are now genericaly managed by MaTiForm.
 *
 * Revision 1.1  2005/02/09 22:57:23  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_TYPESLISTFORM
#include "TypesListForm.h"

#include "MaTirelire.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


// Pour la méthode -showHideList:selItem:
#define NO_INIT_LIST	0x8000	// Pas d'init de la liste
#define SEL_ITEM_MASK	(~NO_INIT_LIST)

@implementation TypesListForm

- (TypesListForm*)free
{
  // Liberation de la liste
  [self->oType listFree:self->ppa_list];

  return [super free];
}


- (Boolean)open
{
  ListPtr pt_lst;
  UInt16 uh_sel_item = 0;
  UInt32 ui_id;

  self->oType = [oMaTirelire type];

  self->ppa_list = [self->oType listBuildInfos:NULL num:&self->uh_num
			largest:NULL];

  // Le formulaire précédent nous demande de sélectionner un ID...
  ui_id = [self->oPrevForm getInfos];

  if (ui_id & TYPE_LIST_DEFAULT_ID)
    // Le bit TYPE_LIST_DEFAULT_ID va virer au passage à 16 bits...
    uh_sel_item = [self findListIndexFromId:(UInt16)ui_id];

  pt_lst = [self objectPtrId:TypesList];

  LstSetDrawFunction(pt_lst, [self->oType listDrawFunction]);

  [self showHideList:pt_lst selItem:uh_sel_item];

  return [super open];
}


- (void)showHideList:(ListPtr)pt_lst selItem:(UInt16)uh_sel_item
{
  UInt16 uh_flags = uh_sel_item;
  UInt16 ruh_show_hide_ids[7 + 1], *puh_show_hide;

  puh_show_hide = ruh_show_hide_ids;

  uh_sel_item &= SEL_ITEM_MASK;

  if (pt_lst == NULL)
    pt_lst = [self objectPtrId:TypesList];

  if ((uh_flags & NO_INIT_LIST) == 0)
    // On initialise la liste et on regarde s'il y a ou non une flèche
    // de scroll dans la marge de droite
    [self->oType rightMarginList:pt_lst num:self->uh_num
	 in:(struct __s_list_dbitem_buf*)self->ppa_list selItem:uh_sel_item];

  // Au moins un item dans la liste
  if (self->uh_num > 0)
  {
    struct s_type *ps_type, *ps_prev_type;

    // En fonction de l'élément sélectionné
#define ps_buf ((struct __s_edit_list_type_buf*)self->ppa_list)
    ps_type =
      [self->oType getId:ps_buf->rs_list2id[uh_sel_item].ui_id];
#undef ps_buf

    // Le frère précédent et notre père
    ps_prev_type = [self->oType getPrevBrother:ps_type parentIn:NULL];

    // Bouton ^ (plus) (si pas premier du niveau)
    *puh_show_hide++ = SET_SHOW(TypesListPlus, ps_prev_type != NULL);

    // Bouton v (minus) (si pas dernier du niveau)
    *puh_show_hide++
      = SET_SHOW(TypesListMinus, ps_type->ui_brother_id != TYPE_UNFILED);

    // Bouton <- (up) (si pas premier niveau)
    *puh_show_hide++
      = SET_SHOW(TypesListUp, ps_type->ui_parent_id != TYPE_UNFILED);

    // Bouton -> (down)
    // on veut se mettre en dernier fils de notre frère précédent
    *puh_show_hide++
      = SET_SHOW(TypesListDown,
		 // Il nous faut avoir un frère précédent...
		 ps_prev_type != NULL
		 // ET il faut que son signe soit compatible
		 && ((ps_type->ui_sign_depend & ps_prev_type->ui_sign_depend)
		     == ps_type->ui_sign_depend)
		 // ET il faut que la profondeur finale n'excède pas
		 //    le maximum
		 && ([self->oType getDepth:ps_prev_type]
		     + [self->oType getMaxDepth:ps_type]
		     < TYPE_MAX_DEPTH));

    [self->oType getFree:ps_prev_type];	// Marche même si NULL

    // Bouton "new under"
    *puh_show_hide++
      //	 On peut encore créer un type
      = SET_SHOW(TypesListNewUnder,
		 self->uh_num < [self->oType dbMaxEntries]
		 // ET la profondeur finale n'excède pas le maximum
		 && [self->oType getDepth:ps_type] < TYPE_MAX_DEPTH);

    [self->oType getFree:ps_type];

    // Bouton "new"
    *puh_show_hide++
      = SET_SHOW(TypesListNew, self->uh_num < [self->oType dbMaxEntries]);

    // Bouton "Edit" tout le temps
    *puh_show_hide++ = SET_SHOW(TypesListEdit, 1);
  }
  // Aucun élément
  else
  {
    
    *puh_show_hide++ = SET_SHOW(TypesListPlus, 0);
    *puh_show_hide++ = SET_SHOW(TypesListEdit, 0);
    *puh_show_hide++ = SET_SHOW(TypesListMinus, 0);
    *puh_show_hide++ = SET_SHOW(TypesListUp, 0);
    *puh_show_hide++ = SET_SHOW(TypesListDown, 0);
    *puh_show_hide++ = SET_SHOW(TypesListNewUnder, 0);

    *puh_show_hide++ = SET_SHOW(TypesListNew, 1);
  }

  *puh_show_hide = 0;
  [self showHideIds:ruh_show_hide_ids];
}


- (void)redrawForm
{
  ListType *pt_lst = [self objectPtrId:TypesList];

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
- (UInt16)editedTypeId
{
  return self->uh_entry_id;
}


//
// Used by child to know if it can display a new button (max items
// number not yet reached)
- (Boolean)isChildNewButton
{
  return (self->uh_num < [self->oType dbMaxEntries]);
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case TypesListPlus:
  case TypesListMinus:
  case TypesListUp:
  case TypesListDown:
    [self moveItemFrom:ps_select->controlID];
    break;

  case TypesListEdit:
  case TypesListNew:
  case TypesListNewUnder:
  {
    UInt16 uh_sel_item = LstGetSelection([self objectPtrId:TypesList]);

    if (uh_sel_item != noListSelection)
    {
      self->uh_entry_id = ((struct __s_edit_list_type_buf*)self->ppa_list)
	->rs_list2id[uh_sel_item].ui_id;

      switch (ps_select->controlID)
      {
      case TypesListEdit:
	self->uh_entry_selected = uh_sel_item; // Useful in -update: method
	break;
      case TypesListNew:
	self->uh_entry_id |= TYPE_NEW_AFTER;
	break;	
      case TypesListNewUnder:
	self->uh_entry_id |= TYPE_NEW_UNDER;
	break;
      }

      FrmPopupForm(EditTypeFormIdx);
    }
    // Pas besoin qu'un item soit sélectionné dans la liste pour le bouton new
    else if (ps_select->controlID == TypesListNew)
    {
      self->uh_entry_id = TYPE_NEW_AT_ROOT;
      FrmPopupForm(EditTypeFormIdx);
    }
  }
  break;

  case TypesListOK:
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
  if (ps_list_select->listID == TypesList)
  {
    struct __s_edit_list_type_buf *ps_buf;
    UInt16 uh_x, uh_depth_x, uh_id, uh_item;
    Boolean b_pen, b_redraw_list;

    // On regarde si on a cliqué sur l'icône de repli/dépli
    EvtGetPen(&uh_x, &uh_depth_x, &b_pen);

    ps_buf = (struct __s_edit_list_type_buf*)self->ppa_list;

    uh_depth_x = (ps_buf->uh_x_pos
		  + ps_buf->rs_list2id[ps_list_select->selection].ui_depth
		  * GLYPH_WIDTH);

    uh_item = NO_INIT_LIST | ps_list_select->selection;

    b_redraw_list = false;
    if (uh_x < uh_depth_x && uh_x >= uh_depth_x - 7)
    {
      uh_id = ps_buf->rs_list2id[ps_list_select->selection].ui_id;

      if ([self->oType foldId:uh_id])
      {
	// Destruction de l'ancienne liste
	[self->oType listFree:self->ppa_list];

	// Création de la nouvelle
	self->ppa_list = [self->oType listBuildInfos:NULL num:&self->uh_num
			      largest:NULL];

	uh_item = [self findListIndexFromId:uh_id];

	// Il faut signaler à l'écran précédent que la liste a changé d'aspect
	self->ui_update_mati_list
	  |= (frmMaTiUpdateList | frmMaTiUpdateListTypes);

	b_redraw_list = true;
      }
    }

    [self showHideList:ps_list_select->pList selItem:uh_item];

    if (b_redraw_list)
      LstDrawList(ps_list_select->pList);

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
    [self->oType listFree:self->ppa_list];

    // Création de la nouvelle
    self->ppa_list = [self->oType listBuildInfos:NULL num:&self->uh_num
			  largest:NULL];

    // The edited item is deleted => new selected is previous if any
    if ((ps_update->updateCode & frmMaTiUpdateEdit2ListDeletedItem)
	&& uh_sel_item != 0)
      uh_sel_item--;

    // A new item was added => find its place...
    if (ps_update->updateCode & frmMaTiUpdateEdit2ListNewItem)
      uh_sel_item = [self findListIndexFromId:(ps_update->updateCode
					       & frmMaTiUpdateEdit2ListNewId)];

    // Il s'agit d'un vrai update, pas juste un item qui bouge...
    if ((ps_update->updateCode & frmMaTiUpdateEdit2ListAfterMove) == 0)
      // Sert pour les OS < 3.2 voir -redrawForm
      self->b_item_edited = true;

    // Remplissage (le redraw va être fait avec l'événement redraw
    // envoyé par le formulaire précédent)
    [self showHideList:NULL selItem:uh_sel_item];

    // Cas particulier : redessin si on a juste bougé le type
    if (ps_update->updateCode & frmMaTiUpdateEdit2ListRedraw)
      LstDrawList([self objectPtrId:TypesList]);

    // Il faudra avertir Papa
    self->ui_update_mati_list |= (frmMaTiUpdateList | frmMaTiUpdateListTypes);

    // Il ne faut pas que la classe mère conserve cet événement pour
    // Papa, on s'en est chargé nous-mêmes une ligne au dessus.
    ps_update->updateCode = 0;
  }

  return [super callerUpdate:ps_update];
}


- (UInt16)findListIndexFromId:(UInt16)uh_id
{
  struct __s_one_type *ps_infos;
  UInt16 index;

  // Recherche de la nouvelle position dans la liste
  ps_infos = ((struct __s_edit_list_type_buf*)self->ppa_list)->rs_list2id;

  for (index = 0; index < self->uh_num; index++, ps_infos++)
    if (ps_infos->ui_id == uh_id)
      return index;

  // Peut arriver si le type vient d'être déplacé dans une branche repliée...

  return 0;
}


- (void)moveItemFrom:(UInt16)uh_button
{
  ListPtr pt_lst = [self objectPtrId:TypesList];
  UInt16 index = LstGetSelection(pt_lst);

  if (index != noListSelection)
  {
    UInt16 uh_id;
    Boolean b_ret;

    uh_id = ((struct __s_edit_list_type_buf*)self->ppa_list)
      ->rs_list2id[index].ui_id;

    switch (uh_button)
    {
    default:
    case TypesListPlus:
      b_ret = [self->oType moveIdPrev:uh_id];
      break;

    case TypesListMinus:
      b_ret = [self->oType moveIdNext:uh_id];
      break;

    case TypesListUp:
      b_ret = [self->oType moveIdUp:uh_id];
      break;

    case TypesListDown:
      b_ret = [self->oType moveIdDown:uh_id];
      break;
    }

    // Le déplacement s'est bien effectué
    if (b_ret)
    {
      // Dans PalmResize/resize.c
      extern void UniqueUpdateForm(UInt16 formID, UInt16 code);
      struct frmCallerUpdate s_update;

      s_update.updateCode = (frmMaTiUpdateEdit2List
			     | frmMaTiUpdateEdit2ListAfterMove
			     | frmMaTiUpdateEdit2ListNewItem
			     | frmMaTiUpdateEdit2ListRedraw
			     | uh_id);
      guh_pending_events++;
      [self callerUpdate:&s_update]; // guh_pending_events OK
    }
  }
}

@end
