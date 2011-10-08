/* -*- objc -*-
 * RepeatsListForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mar nov  1 23:04:40 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Wed Nov 16 16:18:52 2005
 * Update Count    : 1
 * Status          : Unknown, Use with caution!
 */

#ifndef	__REPEATSLISTFORM_H__
#define	__REPEATSLISTFORM_H__

#include "SumListForm.h"

#ifndef EXTERN_REPEATSLISTFORM
# define EXTERN_REPEATSLISTFORM extern
#endif

@interface RepeatsListForm : SumListForm
{
  struct s_trans_form_args s_trans_form; // Infos pour TransForm

  DateType s_end_date;
  DateFormatType e_format;
}

@end

#endif	/* __REPEATSLISTFORM_H__ */
