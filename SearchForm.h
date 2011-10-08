/* -*- objc -*-
 * SearchForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mar oct  4 22:16:45 2005
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__SEARCHFORM_H__
#define	__SEARCHFORM_H__

#include "MaTiForm.h"

#ifndef EXTERN_SEARCHFORM
# define EXTERN_SEARCHFORM extern
#endif

@interface SearchForm : MaTiForm
{
  VoidHand pv_popup_types;
  VoidHand pv_popup_modes;

  DateType rs_date[2];
  DateFormatType e_format;
}

- (void)search;

@end

#endif	/* __SEARCHFORM_H__ */
