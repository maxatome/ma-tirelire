/* -*- objc -*-
 * AccountsListForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mer jul  7 17:08:46 2004
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__ACCOUNTSLISTFORM_H__
#define	__ACCOUNTSLISTFORM_H__

#include "SumListForm.h"

#include "structs.h"


#ifndef EXTERN_ACCOUNTSLISTFORM
# define EXTERN_ACCOUNTSLISTFORM extern
#endif

@interface AccountsListForm : SumListForm
{
  MemHandle pv_db_list;		// Liste des bases de comptes

  Int16 h_account;		// Pour les formulaires fils
}

@end

#endif	/* __ACCOUNTSLISTFORM_H__ */
