/* -*- objc -*-
 * RepeatsScrollList.h -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Tue Nov  1 23:42:13 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Wed Nov 16 11:50:28 2005
 * Update Count    : 5
 * Status          : Unknown, Use with caution!
 */

#ifndef	__REPEATSSCROLLLIST_H__
#define	__REPEATSSCROLLLIST_H__

#include "SumScrollList.h"
#include "Transaction.h"

#ifndef EXTERN_REPEATSSCROLLLIST
# define EXTERN_REPEATSSCROLLLIST extern
#endif

@interface RepeatsScrollList : SumScrollList
{
  MemHandle vh_infos;

  t_amount l_non_repeats_sum;

  // Date à partir de laquelle au moins une opération répétée va apparaître
  // OU BIEN la somme des opérations non répétées va changer
  UInt16 uh_next_change_date;

  // Date de la dernière opération prise en compte
  UInt16 uh_last_change_date;
}

- (UInt16)numRepeatsFor:(struct s_transaction*)ps_tr
		maxDate:(UInt16)uh_max_date
		 putsIn:(UInt32*)pui_tr;

- (void)changeDate:(UInt16)uh_new_date;

@end

#endif	/* __REPEATSSCROLLLIST_H__ */
