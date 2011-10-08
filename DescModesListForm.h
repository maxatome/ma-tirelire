/* -*- objc -*-
 * DescModesListForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Fri Aug 22 16:53:20 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Nov 18 11:08:22 2005
 * Update Count    : 1
 * Status          : Unknown, Use with caution!
 */

#ifndef	__DESCMODESLISTFORM_H__
#define	__DESCMODESLISTFORM_H__

#include "MaTiForm.h"
#include "DBItem.h"

#ifndef EXTERN_DESCMODESLISTFORM
#define EXTERN_DESCMODESLISTFORM extern
#endif

#define DM_MODES_LIST_FORM	0x8000
#define DescListFormIdx		(DescModesListFormIdx)
#define ModesListFormIdx	(DM_MODES_LIST_FORM | DescModesListFormIdx)

@interface DescModesListForm : MaTiForm
{
  DBItem *oDBItem;

  Word uh_entry_selected;	// used when child returns
  Word uh_entry_index;		// used by child to save mode

  Char **ppa_list;
  UInt16 uh_num;

  Boolean b_modes_dialog;
  Boolean b_item_edited;
}

- (void)showHideList:(ListPtr)pt_list selItem:(UInt16)uh_sel_item;

- (void)moveItem:(WinDirectionType)dir;

- (UInt16)editedEntryIndex;
- (Boolean)isChildNewButton;

@end

#endif	/* __DESCMODESLISTFORM_H__ */
