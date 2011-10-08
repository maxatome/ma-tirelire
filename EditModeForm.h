/* -*- objc -*-
 * EditModeForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sun Aug 24 12:13:23 2003
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__EDITMODEFORM_H__
#define	__EDITMODEFORM_H__

#include "MaTiForm.h"

#ifndef EXTERN_EDITMODEFORM
#define EXTERN_EDITMODEFORM extern
#endif

@interface EditModeForm : MaTiForm
{
  UInt16 uh_mode_id;
}

- (Boolean)extractAndSave:(UInt16)uh_update_code;

@end

#endif	/* __EDITMODEFORM_H__ */
