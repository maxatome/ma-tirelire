/* -*- objc -*-
 * EditDescForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sun Feb 29 23:44:01 2004
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__EDITDESCFORM_H__
#define	__EDITDESCFORM_H__

#include "MaTiForm.h"

#ifndef EXTERN_EDITDESCFORM
#define EXTERN_EDITDESCFORM extern
#endif

@interface EditDescForm : MaTiForm
{
  UInt16 uh_desc_idx;		// Index de la description éditée dans sa base

  VoidHand pv_popup_types;
  VoidHand pv_popup_modes;
}

- (Boolean)extractAndSave:(UInt16)uh_update_code;

@end

#endif	/* __EDITDESCFORM_H__ */
