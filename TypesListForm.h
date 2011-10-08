/* -*- objc -*-
 * TypesListForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sun Feb 15 21:10:32 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Nov 18 11:46:49 2005
 * Update Count    : 1
 * Status          : Unknown, Use with caution!
 */

#ifndef	__TYPESLISTFORM_H__
#define	__TYPESLISTFORM_H__

#include "MaTiForm.h"
#include "Type.h"

#ifndef EXTERN_TYPESLISTFORM
#define EXTERN_TYPESLISTFORM extern
#endif

// Pour l'attribut uh_entry_id
#define TYPE_NEW_UNDER	 0x8000		// New under ID
#define TYPE_NEW_AFTER	 0x4000		// New as brother of ID
#define TYPE_NEW_AT_ROOT 0x2000		// New at end of root
#define TYPE_NEW_MASK	(TYPE_NEW_UNDER | TYPE_NEW_AFTER | TYPE_NEW_AT_ROOT)

// Flag à mettre pour communiquer un ID à sélectionner par défaut dans
// la liste
#define TYPE_LIST_DEFAULT_ID	0x80000000

@interface TypesListForm : MaTiForm
{
  Type *oType;

  UInt16 uh_entry_selected; // used when child returns

  UInt16 uh_entry_id;

  Char **ppa_list;
  UInt16 uh_num;

  Boolean b_item_edited;
}

- (void)showHideList:(ListPtr)pt_list selItem:(UInt16)uh_sel_item;

- (UInt16)findListIndexFromId:(UInt16)uh_id;
- (void)moveItemFrom:(UInt16)uh_button;

- (UInt16)editedTypeId;
- (Boolean)isChildNewButton;

@end

#endif	/* __TYPESLISTFORM_H__ */
