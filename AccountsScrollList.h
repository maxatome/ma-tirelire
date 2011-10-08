/* -*- objc -*-
 * AccountsScrollList.h -- 
 * 
 * Author          : Maxime Soulé
 * Created On      : Wed Jul  7 17:54:20 2004
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__ACCOUNTSSCROLLLIST_H__
#define	__ACCOUNTSSCROLLLIST_H__

#include "SumScrollList.h"

#ifndef EXTERN_ACCOUNTSSCROLLLIST
# define EXTERN_ACCOUNTSSCROLLLIST extern
#endif

@interface AccountsScrollList : SumScrollList
{
  MemHandle vh_accounts;
  UInt8 rua_id2account[dmRecNumCategories];

  // La somme dans la devise choisie est l'attribut l_sum de SumScrollList
}

- (void)changeSumFilter:(UInt16)uh_sum_filter;

@end

#endif	/* __ACCOUNTSSCROLLLIST_H__ */
