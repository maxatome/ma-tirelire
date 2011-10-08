/* -*- objc -*-
 * ClearingScrollList.h -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Fri Oct  7 22:38:25 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Nov 26 13:50:16 2007
 * Update Count    : 5
 * Status          : Unknown, Use with caution!
 */

#ifndef	__CLEARINGSCROLLLIST_H__
#define	__CLEARINGSCROLLLIST_H__

#include "SumScrollList.h"
#include "ProgressBar.h"

#ifndef EXTERN_CLEARINGSCROLLLIST
# define EXTERN_CLEARINGSCROLLLIST extern
#endif

struct s_auto_clearing_op
{
  UInt16   uh_rec_index;	// Doit être en tête
  t_amount l_amount;
};

@interface ClearingScrollList : SumScrollList
{
  MemHandle vh_infos;

  t_amount l_checked_sum;	// Somme des opérations pointées

  // Pour le prépointage
  UInt64 ull_autoclear_checked;	// currently auto-cleared transactions
  struct s_auto_clearing_op *ps_autoclear_amounts;
  UInt16 uh_autoclear_num_non_cleared; // # item in ps_autoclear_amounts
  UInt16 uh_autoclear_num_to_clear; // 0 si indéfini
  ProgressBar *oProgressBar;

  // Pour le tri
#define CLEAR_SORT_BY_VAL_DATE		0
#define CLEAR_SORT_BY_DATE		1
#define CLEAR_SORT_BY_MODE		2
#define CLEAR_SORT_BY_TYPE		3
#define CLEAR_SORT_BY_CHEQUE_NUM	4
#define CLEAR_SORT_BY_SUM		5
  UInt16 uh_sort_type;		// Type de tri
}

- (void)swapSumType;

- (Boolean)isCleared;
- (void)changeInternalFlag:(Boolean)b_to_clear stmtNum:(UInt32)ui_stmt_num;

- (Boolean)autoClearingRunning;
- (Boolean)autoClearingInit;
- (Boolean)autoClearingNext;
- (void)autoClearingFree:(Boolean)b_from_free;
- (void)autoClearingSetInternalFlag:(Boolean)b_set;

- (Boolean)changeSortType:(UInt16)uh_sort_type;
- (void)sort;

@end

#endif	/* __CLEARINGSCROLLLIST_H__ */
