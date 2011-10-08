/* -*- objc -*-
 * AccountPropForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mar oct 12 21:07:48 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Wed May 18 09:37:28 2005
 * Update Count    : 1
 * Status          : Unknown, Use with caution!
 */

#ifndef	__ACCOUNTPROPFORM_H__
#define	__ACCOUNTPROPFORM_H__

#include "MaTiForm.h"

#ifndef EXTERN_ACCOUNTPROPFORM
# define EXTERN_ACCOUNTPROPFORM extern
#endif

@interface AccountPropForm : MaTiForm
{
  VoidHand pv_popup_currencies;
  Int16 h_orig_currency;

  UInt16 uh_account_index;
}

- (void)beforeOpen;

- (void)fillWithAccount:(Int16)h_account;

- (Boolean)extractAndSave;

- (Int16)editedAccount;

@end

#endif	/* __ACCOUNTPROPFORM_H__ */
