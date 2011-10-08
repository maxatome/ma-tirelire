/* -*- objc -*-
 * EditSplitForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Ven fév 24 14:40:22 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Dec 11 11:04:40 2007
 * Update Count    : 16
 * Status          : Unknown, Use with caution!
 */

#ifndef	__EDITSPLITFORM_H__
#define	__EDITSPLITFORM_H__

#include "MaTiForm.h"
#include "Desc.h"

#ifndef EXTERN_EDITSPLITFORM
# define EXTERN_EDITSPLITFORM extern
#endif

@interface EditSplitForm : MaTiForm
{
  VoidHand pv_popup_desc;
  VoidHand pv_popup_types;

  Coord uh_x_counter;
  Coord uh_y_counter;
  UInt16 uh_cur;
  UInt16 uh_num;
}

- (void)beforeOpen;

- (void)fillCounter;

- (Boolean)saveSplit;
- (void)loadSplit;

- (void)expandMacro:(UInt16)uh_desc with:(Desc*)oDesc;

- (void)setCredit:(Boolean)b_credit;
- (void)initTypesPopup:(UInt16)uh_type;

@end

#endif	/* __EDITSPLITFORM_H__ */
