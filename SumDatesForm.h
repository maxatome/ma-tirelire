/* -*- objc -*-
 * SumDatesForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Dim nov 14 20:00:22 2004
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__SUMDATESFORM_H__
#define	__SUMDATESFORM_H__

#include "MaTiForm.h"

#ifndef EXTERN_SUMDATESFORM
# define EXTERN_SUMDATESFORM extern
#endif

@interface SumDatesForm : MaTiForm
{
}

- (Boolean)extractAndSave;

@end

#endif	/* __SUMDATESFORM_H__ */
