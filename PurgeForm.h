/* -*- objc -*-
 * PurgeForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sam fév 26 17:30:34 2005
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__PURGEFORM_H__
#define	__PURGEFORM_H__

#include "MaTiForm.h"

#ifndef EXTERN_PURGEFORM
# define EXTERN_PURGEFORM extern
#endif

@interface PurgeForm : MaTiForm
{
  DateType rs_date[2];
  DateFormatType e_format;
}

- (void)purge;

@end

#endif	/* __PURGEFORM_H__ */
