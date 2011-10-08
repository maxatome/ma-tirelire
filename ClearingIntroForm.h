/* -*- objc -*-
 * ClearingIntroForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Ven oct  7 19:03:11 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jun 23 10:15:42 2006
 * Update Count    : 1
 * Status          : Unknown, Use with caution!
 */

#ifndef	__CLEARINGINTROFORM_H__
#define	__CLEARINGINTROFORM_H__

#include "MaTiForm.h"

#ifndef EXTERN_CLEARINGINTROFORM
# define EXTERN_CLEARINGINTROFORM extern
#endif

@interface ClearingIntroForm : MaTiForm
{
  t_amount l_target_balance;	// Solde visé
}

- (void)computeSum;
- (void)focusSum;

@end

#endif	/* __CLEARINGINTROFORM_H__ */
