/* -*- objc -*-
 * StatementNumForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Lun oct 10 21:36:26 2005
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__STATEMENTNUMFORM_H__
#define	__STATEMENTNUMFORM_H__

#include "MaTiForm.h"

#ifndef EXTERN_STATEMENTNUMFORM
# define EXTERN_STATEMENTNUMFORM extern
#endif

@interface StatementNumForm : MaTiForm
{
  UInt32 ul_last_stmt_num;
}

@end

#endif	/* __STATEMENTNUMFORM_H__ */
