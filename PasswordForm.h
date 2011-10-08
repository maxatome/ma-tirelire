/* -*- objc -*-
 * PasswordForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sam mar 27 17:46:21 2004
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__PASSWORDFORM_H__
#define	__PASSWORDFORM_H__

#include <Unix/unix_stdarg.h>

#include "MaTiForm.h"

#ifndef EXTERN_PASSWORDFORM
# define EXTERN_PASSWORDFORM extern
#endif

@interface PasswordForm : MaTiForm
{
}

+ (PasswordForm*)new:(UInt16)uh_id withLabel:(UInt16)uh_label va:(va_list)ap;

- (void)initLabelWith:(UInt16)uh_label va:(va_list)ap;

- (void)_clear;
- (void)_newDigit:(Char)a_digit;
- (void)_valid;

@end

#endif	/* __PASSWORDFORM_H__ */
