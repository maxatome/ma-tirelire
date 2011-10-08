/* -*- objc -*-
 * TransListForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Tue Mar 23 19:44:18 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb 17 15:50:33 2006
 * Update Count    : 2
 * Status          : Unknown, Use with caution!
 */

#ifndef	__TRANSLISTFORM_H__
#define	__TRANSLISTFORM_H__

#include "SumListForm.h"
#include "TransForm.h"

#include "Transaction.h"


#ifndef EXTERN_TRANSLISTFORM
# define EXTERN_TRANSLISTFORM extern
#endif

@interface TransListForm : SumListForm
{
  VoidHand pv_popup_accounts;	// Liste des comptes

  struct s_trans_form_args s_trans_form;

#define TLIST_OD_OVERDRAWN	0
#define TLIST_OD_BETWEEN	1
#define TLIST_OD_NON_OVERDRAWN	2
  UInt16   uh_overdrawn:2;	// Dernier warning de découvert affiché

  // Date de la dernière opération saisie
  DateType s_last_new_op_date;
  TimeType s_last_new_op_time;
}

- (void)transactionDateEdit:(UInt16)uh_rec_index;
- (void)transactionTimeEdit:(UInt16)uh_rec_index;

- (struct s_trans_form_args*)transFormArgs;

- (Boolean)warningOverdrawn:(Boolean)b_reset;

@end

#endif	/* __TRANSLISTFORM_H__ */
