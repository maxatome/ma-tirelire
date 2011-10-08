/* -*- objc -*-
 * DBItemId.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sun Feb 22 16:11:39 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jun  9 14:24:52 2006
 * Update Count    : 1
 * Status          : Unknown, Use with caution!
 */

#ifndef	__DBITEMID_H__
#define	__DBITEMID_H__

#include "DBItem.h"

#ifndef EXTERN_DBITEMID
#define EXTERN_DBITEMID extern
#endif

// In cache, free IDs have index value ITEM_FREE_ID
#define ITEM_FREE_ID	0xffff

// Pour la gestion générique des popups/ID
struct __s_dbitem_popup_list
{
  FormType *pt_form;
  ListType *pt_list;
  struct __s_list_dbitem_buf *ps_buf;
  Char *pa_account;		/* Le popup dépend de ce compte */
  Char *pa_popup_label;		/* MemPtrFree à faire */
  UInt16 uh_list_idx;		/* Index de la liste dans le formulaire */
  UInt16 uh_popup_idx;		/* Index du popup dans le formulaire */
  UInt16 uh_id;			/* ID du mode actuellement sélectionné */
  UInt16 uh_flags;		/* Flags à conserver */
  UInt16 uh_num;		/* Nombre total d'entrées */
};


@interface DBItemId : DBItem
{
  VoidHand pv_id2index;
  UInt16 *puh_id2index;		// Non NULL only when pv_id2index locked
  UInt16 uh_num_cache_entries;
}

- (Boolean)cacheAlloc:(UInt16)uh_num_entries;
- (void)cacheInit;

- (UInt16*)cacheLock;
- (void)cacheUnlock;

- (void)cacheFreeId:(UInt16)uh_id withIndex:(UInt16)uh_index;

- (void)cacheAtId:(UInt16)uh_id putIndex:(UInt16)uh_index;

- (Int16)cacheGetNextFreeId;

- (UInt16)getCachedIndexFromID:(UInt16)uh_id;

- (UInt16)getIdFrom:(void*)pv_item;
- (void)setId:(UInt16)uh_new_id in:(void*)pv_item;

// Pour accéder directement à un enregistrement par son index plutôt
// que par son ID
#define ITEM_SET_DIRECT(uh_id)	(uh_id | 0x8000)
#define ITEM_IS_DIRECT(uh_id)	(uh_id & 0x8000)
#define ITEM_CLR_DIRECT(uh_id)	(uh_id & ~0x8000)

// Pour le paramètre asNew: de -save:size:asId:asNew:
#define ITEM_NEW_WITH_ID	2

- (Char*)fullNameOfId:(UInt16)uh_id len:(UInt16*)puh_len;

////////////////////////////////////////////////////////////////////////
//
// Gestion complète d'un popup

// Fake return types
#define ITEM_ADD_EDIT_LINE	0x8000 // The "Edit..." last line is present
#define ITEM_ADD_UNKNOWN_LINE	0x4000 // The "Unknown..." last but
				       // one line is present
#define ITEM_ADD_ANY_LINE	0x2000 // The "Any" first line is present
#define ITEM_CAN_NOT_EXIST	0x1000 // Selected item can not exist in list
#define ITEM_SELECT_FIRST	0x0800 // Select the first list item
#define ITEM_FLAGS_MASK		0xf800
- (VoidHand)popupListInit:(UInt16)uh_list_id
		     form:(FormType*)pt_form
		       Id:(UInt16)uh_id
	       forAccount:(Char*)pa_account;

// Allows to select another ID without rebuilding the list
- (void)popupList:(VoidHand)pv_list setSelection:(UInt16)uh_id;

#define PLIST_REINIT_DIRECT	0x0001
#define PLIST_REINIT_NO_SETSEL	0x0002
#define PLIST_REINIT_NO_LABEL	0x0004
- (void)_popupListReinit:(VoidHand)pv_list flags:(UInt16)uh_flags;

#define ITEM_EDIT	0x100
#define ITEM_ANY	0x200
- (UInt16)popupList:(VoidHand)pv_list;

- (UInt16)_popupListUnknownItem;

- (UInt16)popupListGet:(VoidHand)pv_list;

- (void)popupListFree:(VoidHand)pv_list;

- (void)_popupListInit:(struct __s_dbitem_popup_list*)ps_list;
- (void)_popupListSetLabel:(struct __s_dbitem_popup_list*)ps_list;
- (void)_popupListSetSelection:(struct __s_dbitem_popup_list*)ps_list;
- (UInt16)_popupList:(struct __s_dbitem_popup_list*)ps_list
    getIdFromListIdx:(UInt16)uh_index;
- (void)_popupListValidId:(struct __s_dbitem_popup_list*)ps_list;

- (UInt16*)_popupListGetList2IndexFrom:(struct __s_list_dbitem_buf*)ps_buf;

@end

#endif	/* __DBITEMID_H__ */
