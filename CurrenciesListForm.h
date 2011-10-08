/* -*- objc -*-
 * CurrenciesListForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Fri May 21 23:51:04 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Nov 18 11:57:52 2005
 * Update Count    : 1
 * Status          : Unknown, Use with caution!
 */

#ifndef	__CURRENCIESLISTFORM_H__
#define	__CURRENCIESLISTFORM_H__

#include "MaTiForm.h"
#include "Currency.h"

#ifndef EXTERN_CURRENCIESLISTFORM
# define EXTERN_CURRENCIESLISTFORM extern
#endif

@interface CurrenciesListForm : MaTiForm
{
  UInt16 uh_entry_selected;	// used when child returns
  UInt16 uh_entry_index;	// used by child to save currency

  Char **ppa_list;
  VoidHand pv_ref_list;
  UInt16 uh_num;

  Currency *oCurrency;

  Boolean b_item_edited;
}

// Macros for the -update: method
#define frmDontUpdateRefList	0x0200 // Utilisé lors d'un changement de réf.

- (void)showHideList:(ListPtr)pt_list selItem:(UInt16)uh_sel_item;

- (void)moveItem:(WinDirectionType)dir;

- (UInt16)editedEntryIndex;
- (Boolean)isChildNewButton;

@end

#endif	/* __CURRENCIESLISTFORM_H__ */
