/* -*- objc -*-
 * DBasesListForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mer jui 30 22:06:43 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Nov 18 13:57:47 2005
 * Update Count    : 1
 * Status          : Unknown, Use with caution!
 */

#ifndef	__DBASESLISTFORM_H__
#define	__DBASESLISTFORM_H__

#include "MaTiForm.h"

#ifndef EXTERN_DBASESLISTFORM
# define EXTERN_DBASESLISTFORM extern
#endif

@interface DBasesListForm : MaTiForm
{
  // Utilisé lors de l'édition des propriétés
  Char ra_db_name[dmDBNameLength];

  MemHandle pv_list;
  SysDBListItemType *ps_dbs;
  UInt16 uh_num;

  Int16 h_entry_index;
  Boolean b_item_edited;
}

- (void)showHideList:(ListPtr)pt_lst selItem:(Char*)pa_sel_db;

- (SysDBListItemType*)editedDB;

- (Boolean)checkAccess:(UInt16)uh_index;

- (void)cloneDB:(UInt16)index;

@end

#endif	/* __DBASESLISTFORM_H__ */
