/* -*- objc -*-
 * ClearingListForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sam oct  8 22:45:38 2005
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__CLEARINGLISTFORM_H__
#define	__CLEARINGLISTFORM_H__

#include "SumListForm.h"

#include "TransForm.h"

#ifndef EXTERN_CLEARINGLISTFORM
# define EXTERN_CLEARINGLISTFORM extern
#endif

// Le solde visé est dans le formulaire précédent qui est un ClearingIntroForm
#define TARGET_BALANCE	((ClearingIntroForm*)oFrm->oPrevForm)->l_target_balance


// Pour StatementNumForm
union s_stmt_form_args
{
  t_amount l_cleared_sum;	// Pour l'init de StatementNumForm
  UInt32   ui_stmt_num;		// Pour le retour de StatementNumForm
};

// Pour ClearingAutoConfForm
struct s_clearing_auto_form_args
{
  DateType s_date;		// Date butoir
  UInt16   uh_num_transactions;	// 0 pas de nombre précis
};

@interface ClearingListForm : SumListForm
{
  struct s_trans_form_args s_trans_form; // Infos pour TransForm

  union s_stmt_form_args u;	// Pour StatementNumForm

  struct s_clearing_auto_form_args s_clear_auto_form; // ClearingAutoConfForm

  Boolean b_left_sum;

  Char a_autoclearing_char;
}

- (void)swapSumType;

- (void)autoClearing:(Boolean)b_continue;

@end

#endif	/* __CLEARINGLISTFORM_H__ */
