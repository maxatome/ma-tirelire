/* 
 * DBItemId.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sun Feb 22 16:11:36 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb  1 17:11:34 2008
 * Update Count    : 30
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: DBItemId.m,v $
 * Revision 1.7  2008/02/01 17:13:02  max
 * Avoid ID duplicate bug by reconstructing the cache when "creation by
 * insertion" occurs.
 * s/WinPrintf/alert_error_str/g
 *
 * Revision 1.6  2008/01/14 17:09:32  max
 * Switch to new mcc.
 *
 * Revision 1.5  2006/06/19 12:23:50  max
 * -save:size:asId:asNew: can now keep passed ID thanks to
 * ITEM_NEW_WITH_ID macro.
 *
 * Revision 1.4  2006/04/25 08:46:15  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.3  2005/08/28 10:02:29  max
 * Unfiled item is no longer made visible when selected in popup
 * list. This allows to select easily another item at the top of the
 * list without scrolling up.
 *
 * Revision 1.2  2005/05/08 12:12:54  max
 * Fix comment typo.
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_DBITEMID
#include "DBItemId.h"

#include "MaTirelire.h"

#include "graph_defs.h"
#include "objRsc.h"		// XXX


@implementation DBItemId

- (DBItemId*)free
{
  // Cache locked
  if (self->puh_id2index != NULL)
    [self cacheUnlock];

  MemHandleFree(self->pv_id2index);

  return [super free];
}


////////////////////////////////////////////////////////////////////////
//
// Cache management
//
////////////////////////////////////////////////////////////////////////


- (Boolean)cacheAlloc:(UInt16)uh_num_entries
{
  self->uh_num_cache_entries = uh_num_entries;

  NEW_HANDLE(self->pv_id2index, sizeof(UInt16) * uh_num_entries, return false);

  return true;
}


- (void)cacheInit
{
  VoidHand pv_item;
  UInt16 index;

  [self cacheLock];

  // Init the cache to all free...
  MemSet(self->puh_id2index,
	 self->uh_num_cache_entries * sizeof(*self->puh_id2index), 0xff);

  // Init the cache...
  for (index = DmNumRecords(self->db); index-- > 0; )
  {
    pv_item = DmQueryRecord(self->db, index);
    if (pv_item != NULL)
    {
      void *ps_item;

      ps_item = MemHandleLock(pv_item);

      self->puh_id2index[[self getIdFrom:ps_item]] = index;

      MemHandleUnlock(pv_item);
    }
  }

  [self cacheUnlock];
}


- (UInt16*)cacheLock
{
  if (self->puh_id2index == NULL)
    self->puh_id2index = (UInt16*)MemHandleLock(self->pv_id2index);

  return self->puh_id2index;
}


- (void)cacheUnlock
{
  MemHandleUnlock(self->pv_id2index);
  self->puh_id2index = NULL;
}


//
// On ne doit pas être locké lors de l'appel de cette méthode !!!
// (Modifie le cache)
- (void)cacheFreeId:(UInt16)uh_id withIndex:(UInt16)uh_index
{
  UInt16 *puh_id2index;

  // We have to shift all record indexes that follow this one in the cache
  [self cacheLock];

  self->puh_id2index[uh_id] = ITEM_FREE_ID;

  for (uh_id = self->uh_num_cache_entries, puh_id2index = self->puh_id2index;
       uh_id > 0;
       uh_id--, puh_id2index++)
    if (*puh_id2index != ITEM_FREE_ID && *puh_id2index > uh_index)
      (*puh_id2index)--;

  [self cacheUnlock];
}


//
// On ne doit pas être locké lors de l'appel de cette méthode !!!
// (Modifie le cache)
- (void)cacheAtId:(UInt16)uh_id putIndex:(UInt16)uh_index
{
  [self cacheLock];
  self->puh_id2index[uh_id] = uh_index;
  [self cacheUnlock];
}


- (Int16)cacheGetNextFreeId
{
  UInt16 uh_index;

  [self cacheLock];

  // On recherche le premier ID de libre dans le cache
  for (uh_index = 0; uh_index < self->uh_num_cache_entries; uh_index++)
    if (self->puh_id2index[uh_index] == ITEM_FREE_ID)
    {
      [self cacheUnlock];
      return uh_index;
    }

  [self cacheUnlock];

  return -1;
}


//
// *** WARNING this method lock AND unlock the cache at end
- (UInt16)getCachedIndexFromID:(UInt16)uh_id
{
  UInt16 index;

  [self cacheLock];
  index = self->puh_id2index[uh_id];
  [self cacheUnlock];

  return index;
}


////////////////////////////////////////////////////////////////////////
//
// Loading items
//
////////////////////////////////////////////////////////////////////////

//
// Return NULL if the item does not exist
// Returned pointer must be freed with a call to -getFree:
- (void*)getId:(UInt16)uh_id
{
  void *pv_item;
  UInt16 index;

  // Mode spécial de la classe mère
  if (ITEM_IS_DIRECT(uh_id))
    return [super getId:ITEM_CLR_DIRECT(uh_id)];

  // Retrieve the index from the ID
  index = [self getCachedIndexFromID:uh_id];
  if (index == ITEM_FREE_ID)
    return NULL;

  pv_item = [super getId:index];
  if (pv_item == NULL)
    return NULL;

  return pv_item;
}


//
// Function called after a -getId:
- (void)getFree:(void*)pv_item
{
  // Rien à faire
  if (pv_item == NULL)
    return;

  // Cas particulier, si l'ID de l'item est égal au nombre maxi
  // d'entrées dans le cache, c'est que la zone a été allouée
  // artificiellement par un MemPtrNew dans la sous-classe (c'est le
  // cas des items "Unfiled" et "Unknown" des types et modes)
  if ([self getIdFrom:pv_item] == self->uh_num_cache_entries)
    MemPtrFree(pv_item);
  // We have to unlock the chunck
  else
    MemPtrUnlock(pv_item);
}


////////////////////////////////////////////////////////////////////////
//
// Saving items
//
////////////////////////////////////////////////////////////////////////

// *puh_index doit être initialisé (à dmMaxRecordIndex si ajout en fin)
- (Boolean)save:(void*)pv_item size:(UInt16)uh_size asId:(UInt16*)puh_index
	  asNew:(UInt16)uh_new
{
  // Création : il faut créer un nouvel ID
  if (uh_new)
  {
    Int16 h_new_id;
    Boolean b_insertion = (*puh_index != dmMaxRecordIndex);

    // On nous demande de mettre un ID particulier
    if (uh_new == ITEM_NEW_WITH_ID)
    {
      h_new_id = [self getIdFrom:pv_item];
      if ([self getCachedIndexFromID:h_new_id] != ITEM_FREE_ID)
	goto get_next_free_id;
    }
    // Nouvel ID quelconque
    else
    {
  get_next_free_id:
      // On recherche le premier ID de libre dans le cache
      h_new_id = [self cacheGetNextFreeId];
      if (h_new_id < 0)
	return false;

      // On stocke le nouvel ID dans l'enregistrement
      [self setId:h_new_id in:pv_item];
    }

    if ([super save:pv_item size:uh_size asId:puh_index asNew:true] == false)
    {
      // XXX
      return false;
    }

    // Fin : mise à jour du cache

    // Si on s'est inséré, on a tout décalé => on recalcule tout le
    // cache, c'est plus simple
    if (b_insertion)
      [self cacheInit];
    // Si on s'est ajouté en fin, on n'a pas touché aux place des copains
    else
      [self cacheAtId:h_new_id putIndex:*puh_index];
  }
  // Il s'agit d'une modification d'un enregistrement existant
  else
  {
    *puh_index = [self getCachedIndexFromID:[self getIdFrom:pv_item]];
    if (*puh_index == ITEM_FREE_ID)
    {
      alert_error_str("ITEM_FREE_ID for ID %u", [self getIdFrom:pv_item]); //XXX
      return false;
    }

    if ([super save:pv_item size:uh_size asId:puh_index asNew:false] == false)
    {
      // XXX
      return false;
    }
  }

  return true;
}


- (UInt16)getIdFrom:(void*)pv_item
{
  return [self subclassResponsibility];
}


- (void)setId:(UInt16)uh_new_id in:(void*)pv_item
{
  [self subclassResponsibility];
}


- (Boolean)moveId:(UInt16)uh_index direction:(WinDirectionType)dir
{
  VoidHand pv_item;
  UInt16 uh_id, uh_other, uh_last;
  Int16 h_inc;

  // Current ID
  pv_item = DmQueryRecord(self->db, uh_index);
  uh_id = [self getIdFrom:MemHandleLock(pv_item)];
  MemHandleUnlock(pv_item);

  if (dir == winUp)
  {
    uh_last = 0;
    h_inc = -1;
  }
  else
  {
    h_inc = 1;
    uh_last = DmNumRecords(self->db);

    if (uh_last <= 1)		// 0 or 1 record: nothing to do
      return false;

    uh_last--;
  }

  // At end, we are the first/last record
  for (uh_other = uh_index; uh_other != uh_last;)
  {
    // Prev/next one
    uh_other += h_inc;

    pv_item = DmQueryRecord(self->db, uh_other);
    if (pv_item != NULL)
    {
      UInt16 uh_other_id;

      // After this record if winDown
      DmMoveRecord(self->db, uh_index, uh_other + (dir != winUp));

      // ID of the other item swapped
      uh_other_id = [self getIdFrom:MemHandleLock(pv_item)];
      MemHandleUnlock(pv_item);

      // Correct the cache
      [self cacheAtId:uh_id putIndex:uh_other];
      [self cacheAtId:uh_other_id putIndex:uh_other - h_inc];

      // OK
      return true;
    }
  }

  return false;
}


////////////////////////////////////////////////////////////////////////
//
// Deleting items
//
////////////////////////////////////////////////////////////////////////

- (Int16)deleteId:(UInt32)ui_id
{
  UInt16 uh_id, uh_index;
  Int16 h_ret;

  uh_id = ui_id & 0xffff;

  // Retrieve DB index from cache
  uh_index = [self getCachedIndexFromID:uh_id];
  if (uh_index == ITEM_FREE_ID)
  {
    // XXX
    return -1;
  }

  // Update the cache if the mode is Removed (not Deleted)
  h_ret = [super deleteId:uh_index];
  if (h_ret < 0)
  {
    // XXX
    return -1;
  }

  // Record is really removed, from the DB. We have to sync the cache...
  if (h_ret > 0)
    [self cacheFreeId:uh_id withIndex:uh_index];

  return h_ret;
}


////////////////////////////////////////////////////////////////////////
//
// DBItemId popup list
//
////////////////////////////////////////////////////////////////////////

- (Char*)fullNameOfId:(UInt16)uh_id len:(UInt16*)puh_len
{
  return [self subclassResponsibility];
}


- (VoidHand)popupListInit:(UInt16)uh_list_id
		     form:(FormType*)pt_form
		       Id:(UInt16)uh_id
	       forAccount:(Char*)pa_account
{
  VoidHand pv_list;
  struct __s_dbitem_popup_list *ps_list;

  NEW_HANDLE(pv_list, sizeof(struct __s_dbitem_popup_list), return NULL);

  ps_list = MemHandleLock(pv_list);

  ps_list->pt_form = pt_form;

  ps_list->uh_list_idx = FrmGetObjectIndex(pt_form, uh_list_id);
  ps_list->uh_popup_idx = FrmGetObjectIndex(pt_form, uh_list_id - 1);

  ps_list->pa_account = pa_account;
  ps_list->uh_flags = uh_id & ITEM_FLAGS_MASK;
  ps_list->uh_id = uh_id & ~ITEM_FLAGS_MASK;

  ps_list->pt_list = FrmGetObjectPtr(pt_form, ps_list->uh_list_idx);

  // Dans uh_id il y a peut-être des flags du style ITEM_ADD_XXX_LINE
  [self _popupListInit:ps_list];

  // Label du popup
  ps_list->pa_popup_label = NULL;
  [self _popupListSetLabel:ps_list];

  // Sélectionne l'item correspondant à l'ID
  [self _popupListSetSelection:ps_list];

  // Le callback de remplissage de la liste
  LstSetDrawFunction(ps_list->pt_list, [self listDrawFunction]);

  MemHandleUnlock(pv_list);

  return pv_list;
}


- (void)popupList:(VoidHand)pv_list setSelection:(UInt16)uh_id
{
  struct __s_dbitem_popup_list *ps_list;

  ps_list = MemHandleLock(pv_list);

  // Il se peut que l'ID ne soit pas présent dans la liste, mais on
  // veut tout de même le sélectionner
  if (uh_id & ITEM_CAN_NOT_EXIST)
  {
    uh_id &= ~ITEM_CAN_NOT_EXIST;
    ps_list->uh_flags |= ITEM_CAN_NOT_EXIST;
  }
  else
    ps_list->uh_flags &= ~ITEM_CAN_NOT_EXIST;

  // Il faut sélectionner le premier item de la liste
  if (uh_id & ITEM_SELECT_FIRST)
    uh_id = [self _popupList:ps_list getIdFromListIdx:0];

  ps_list->uh_id = uh_id;

  // On vérifie la présence de ps_list->uh_id dans la liste
  [self _popupListValidId:ps_list];

  [self _popupListSetLabel:ps_list];
  [self _popupListSetSelection:ps_list];

  MemHandleUnlock(pv_list);
}


//
// Re-construit la liste en fonction de l'ID (+ flags) et du compte
// contenus dans la structure opaque passée en paramètre
- (void)_popupListReinit:(VoidHand)pv_list flags:(UInt16)uh_flags
{
  struct __s_dbitem_popup_list *ps_list;

  // On nous passe directement la zone déjà lockée
  if (uh_flags & PLIST_REINIT_DIRECT)
    ps_list = (struct __s_dbitem_popup_list*)pv_list;
  else
    ps_list = MemHandleLock(pv_list);

  // Libération
  MemPtrFree(ps_list->ps_buf);

  // Réallocation
  [self _popupListInit:ps_list];

  // Label du popup
  if ((uh_flags & PLIST_REINIT_NO_LABEL) == false)
    [self _popupListSetLabel:ps_list];

  // Sélectionne l'item correspondant à l'ID
  if ((uh_flags & PLIST_REINIT_NO_SETSEL) == false)
    [self _popupListSetSelection:ps_list];

  if ((uh_flags & PLIST_REINIT_DIRECT) == false)
    MemHandleUnlock(pv_list);
}


- (UInt16)_popupListUnknownItem
{
  return [self subclassResponsibility];
}


- (UInt16*)_popupListGetList2IndexFrom:(struct __s_list_dbitem_buf*)ps_buf
{
  return [self subclassResponsibility];
}


- (UInt16)popupList:(VoidHand)pv_list
{
  struct __s_dbitem_popup_list *ps_list;
  UInt16 uh_item, uh_saved_id;

  ps_list = MemHandleLock(pv_list);

  uh_saved_id = ps_list->uh_id;

  uh_item = LstPopupList(ps_list->pt_list);

  // Il y a une sélection
  if (uh_item != noListSelection)
  {
    // Si on a une entrée "Any"
    if (ps_list->uh_flags & ITEM_ADD_ANY_LINE)
    {
      // Et en plus c'est celle là qu'on vient de sélectionner !
      if (uh_item == 0)
      {
	uh_item = ITEM_ANY;
	goto commit;
      }

      uh_item--;
    }

    // On vient de sélectionner un item
    if (uh_item < ps_list->ps_buf->uh_num_rec_entries)
      uh_item = [self _popupList:ps_list getIdFromListIdx:uh_item];
    // "Unknown" entry selected
    else if ((ps_list->uh_flags & ITEM_ADD_UNKNOWN_LINE)
	     && uh_item == ps_list->ps_buf->uh_num_rec_entries)
      uh_item = [self _popupListUnknownItem];
    else
    {
      uh_item = ITEM_EDIT;

      // Il faut resélectionner la bonne entrée pour la prochaine ouverture
      [self _popupListSetSelection:ps_list];

      goto end;
    }

 commit:
    if (uh_item != uh_saved_id)
    {
      ps_list->uh_id = uh_item;

      // Label du popup
      [self _popupListSetLabel:ps_list];
    }
  }

 end:
  MemHandleUnlock(pv_list);

  return uh_item;
}


//
// Retourne l'ID sélectionné ou (item unknown) ou ITEM_ANY
- (UInt16)popupListGet:(VoidHand)pv_list
{
  UInt16 uh_id;

  uh_id = ((struct __s_dbitem_popup_list*)MemHandleLock(pv_list))->uh_id;
  MemHandleUnlock(pv_list);

  return uh_id;
}


//
// Libère tout ce qui a été alloué...
- (void)popupListFree:(VoidHand)pv_list
{
  if (pv_list != NULL)
  {
    struct __s_dbitem_popup_list *ps_list;

    ps_list = MemHandleLock(pv_list);

    MemPtrFree(ps_list->pa_popup_label);
    MemPtrFree(ps_list->ps_buf);

    MemHandleUnlock(pv_list);

    MemHandleFree(pv_list);
  }
}


//
// Il faut initialiser la liste dont on vient de reconstruire le
// contenu
- (void)_popupListInit:(struct __s_dbitem_popup_list*)ps_list
{
  RectangleType s_rect;
  UInt16 uh_largest, uh_screen_width, uh_dummy;

  // Construction du contenu de la liste
  ps_list->uh_num = ps_list->uh_flags;
  ps_list->ps_buf =
    (struct __s_list_dbitem_buf*)[self listBuildInfos:ps_list->pa_account
				       num:&ps_list->uh_num
				       largest:&uh_largest];
  LstSetHeight(ps_list->pt_list, ps_list->uh_num);

  uh_largest += LIST_MARGINS_NO_SCROLL;

  // On initialise la liste et on regarde s'il y a ou non une flèche
  // de scroll dans la marge de droite
  if ([self rightMarginList:ps_list->pt_list num:ps_list->uh_num
	    in:ps_list->ps_buf selItem:-1])
    uh_largest += LIST_MARGINS_WITH_SCROLL - LIST_MARGINS_NO_SCROLL;

  // On s'adapte à la largeur de l'écran
  WinGetDisplayExtent(&uh_screen_width, &uh_dummy);
  if (uh_largest > uh_screen_width - LIST_EXTERNAL_BORDERS)
    uh_largest = uh_screen_width - LIST_EXTERNAL_BORDERS;

  // On remet la liste à la bonne position (avec une largeur adéquate)
  FrmGetObjectBounds(ps_list->pt_form, ps_list->uh_list_idx, &s_rect);
  s_rect.extent.x = uh_largest;
  FrmSetObjectBounds(ps_list->pt_form, ps_list->uh_list_idx, &s_rect);

  // Il faut sélectionner le premier item de la liste
  if (ps_list->uh_flags & ITEM_SELECT_FIRST)
  {
    ps_list->uh_flags &= ~ITEM_SELECT_FIRST;
    ps_list->uh_id = [self _popupList:ps_list getIdFromListIdx:0];
  }

  // On vérifie la présence de ps_list->uh_id dans la liste
  [self _popupListValidId:ps_list];
}


//
// En fonction de l'item sélectionné, modifie le label du popup
// associé à la liste.
- (void)_popupListSetLabel:(struct __s_dbitem_popup_list*)ps_list
{
  Char *pa_label;

  if (ps_list->pa_popup_label != NULL)
    MemPtrFree(ps_list->pa_popup_label);

  if (ps_list->uh_id == ITEM_ANY)
  {
    // Une seule allocation quelle que soit la taille...
    NEW_PTR(pa_label, 32, /* XXX un define à déclarer ??? XXX */
	    ({ ps_list->pa_popup_label = NULL; return; }));

    SysCopyStringResource(pa_label, strAnyList);
  }
  else
    // XXX Doit-on tronquer le label comme dans Type.m ??? XXX
    pa_label = [self fullNameOfId:ps_list->uh_id len:NULL];

  CtlSetLabel(FrmGetObjectPtr(ps_list->pt_form, ps_list->uh_popup_idx),
	      pa_label);

  ps_list->pa_popup_label = pa_label;
}


//
// En fonction de l'item sélectionné, sélectionne la bonne entrée dans
// la liste
- (void)_popupListSetSelection:(struct __s_dbitem_popup_list*)ps_list
{
  UInt16 uh_item;
  Boolean b_item_visible = true;

  switch (ps_list->uh_id)
  {
  case ITEM_ANY:
    uh_item = 0;		// Toujours en tête...
    break;

  default:
    // Entrée "Unknown"
    if ((ps_list->uh_flags & ITEM_ADD_UNKNOWN_LINE)
	&& ps_list->uh_id == [self _popupListUnknownItem])
    {
      // "Unfiled" est dernier si pas d'entrée "Edit...", avant dernier sinon
      uh_item = ps_list->uh_num - 1;

      if (ps_list->uh_flags & ITEM_ADD_EDIT_LINE)
	uh_item--;

      // Dans ce cas précis, on ne cherche pas à rendre visible l'item
      b_item_visible = false;
    }
    else
    {
      UInt16 *puh_list2index, uh_index;
      UInt16 uh_num_types = ps_list->ps_buf->uh_num_rec_entries;

      uh_index = [self getCachedIndexFromID:ps_list->uh_id];

      puh_list2index = [self _popupListGetList2IndexFrom:ps_list->ps_buf];

      for (uh_item = 0; uh_item < uh_num_types; uh_item++, puh_list2index++)
	if (*puh_list2index == uh_index)
	  break;

      // Si on a une première entrée "Any"
      if (ps_list->uh_flags & ITEM_ADD_ANY_LINE)
	uh_item++;
    }
    break;
  }

  LstSetSelection(ps_list->pt_list, uh_item);
  LstMakeItemVisible(ps_list->pt_list, b_item_visible ? uh_item : 0);
}


- (void)_popupListValidId:(struct __s_dbitem_popup_list*)ps_list
{
  // On vérifie l'existence de ps_list->uh_id
  UInt16 uh_unknown = [self _popupListUnknownItem];

  if (ps_list->uh_id != uh_unknown && ps_list->uh_id != ITEM_ANY)
  {
    UInt16 uh_index = [self getCachedIndexFromID:ps_list->uh_id];
    
    // Il est présent dans le cache, il faut qu'il soit présent dans
    // la liste des choix, au cas où il aurait été filtré...
    if (uh_index != ITEM_FREE_ID)
    {
      UInt16 *puh_list2index;
      UInt16 uh_item, uh_num_types;

      // Il est possible que le mode n'existe pas dans la liste, et
      // c'est pas grave...
      if (ps_list->uh_flags & ITEM_CAN_NOT_EXIST)
	return;

      uh_num_types = ps_list->ps_buf->uh_num_rec_entries;

      puh_list2index = [self _popupListGetList2IndexFrom:ps_list->ps_buf];

      for (uh_item = 0; uh_item < uh_num_types; uh_item++, puh_list2index++)
	if (*puh_list2index == uh_index)
	  return;		// On a trouvé, on quitte...
    }

    // Cet ID n'existe pas
    ps_list->uh_id = uh_unknown;
  }
}


- (UInt16)_popupList:(struct __s_dbitem_popup_list*)ps_list
    getIdFromListIdx:(UInt16)uh_index
{
  void *ps_item;
  UInt16 uh_id;

  if (uh_index < ps_list->ps_buf->uh_num_rec_entries)
  {
    ps_item = [self getId:ITEM_SET_DIRECT([self _popupListGetList2IndexFrom:
						  ps_list->ps_buf][uh_index])];
    uh_id = [self getIdFrom:ps_item];
    [self getFree:ps_item];
  }
  else
    uh_id = [self _popupListUnknownItem];

  return uh_id;
}

@end
