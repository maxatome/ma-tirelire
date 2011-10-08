/* -*- objc -*-
 * ClearingAutoConfForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mar nov  1 11:54:24 2005
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__CLEARINGAUTOCONFFORM_H__
#define	__CLEARINGAUTOCONFFORM_H__

#include "MaTiForm.h"

#ifndef EXTERN_CLEARINGAUTOCONFFORM
# define EXTERN_CLEARINGAUTOCONFFORM extern
#endif

@interface ClearingAutoConfForm : MaTiForm
{
  DateType s_date;
  DateFormatType e_format;
}

@end

#endif	/* __CLEARINGAUTOCONFFORM_H__ */
