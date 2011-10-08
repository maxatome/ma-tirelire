/* -*- objc -*-
 * EditTypeForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Wed Feb 18 23:51:22 2004
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__EDITTYPEFORM_H__
#define	__EDITTYPEFORM_H__

#include "MaTiForm.h"

#ifndef EXTERN_EDITTYPEFORM
#define EXTERN_EDITTYPEFORM extern
#endif

@interface EditTypeForm : MaTiForm
{
  UInt16  uh_type_id;
}

- (UInt16)signChoiceParent:(UInt16)uh_parent_id;

- (Boolean)extractAndSave:(UInt16)uh_update_code;

@end

#endif	/* __EDITTYPEFORM_H__ */
