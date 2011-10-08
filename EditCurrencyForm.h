/* -*- objc -*-
 * EditCurrencyForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sat May 22 22:24:42 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Jun  3 15:29:42 2004
 * Update Count    : 2
 * Status          : Unknown, Use with caution!
 */

#ifndef	__EDITCURRENCYFORM_H__
#define	__EDITCURRENCYFORM_H__

#include "MaTiForm.h"

#ifndef EXTERN_EDITCURRENCYFORM
# define EXTERN_EDITCURRENCYFORM extern
#endif

@interface EditCurrencyForm : MaTiForm
{
  UInt16 uh_currency_id;
}

- (Boolean)extractAndSave:(UInt16)uh_update_code;

@end

#endif	/* __EDITCURRENCYFORM_H__ */
