/* -*- objc -*-
 * MiniStatsForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Ven sep  8 23:22:20 2006
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__MINISTATSFORM_H__
#define	__MINISTATSFORM_H__

#include "MaTiForm.h"

#ifndef EXTERN_MINISTATSFORM
# define EXTERN_MINISTATSFORM extern
#endif

@interface MiniStatsForm : MaTiForm
{
  DateType rs_date[2];
  DateFormatType e_format;
}

- (void)computeSum;

@end

#endif	/* __MINISTATSFORM_H__ */
