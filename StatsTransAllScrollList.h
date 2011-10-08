/* -*- objc -*-
 * StatsTransAllScrollList.h -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Mon Oct 23 23:11:03 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Nov  2 11:40:21 2006
 * Update Count    : 2
 * Status          : Unknown, Use with caution!
 */

#ifndef	__STATSTRANSALLSCROLLLIST_H__
#define	__STATSTRANSALLSCROLLLIST_H__

#include "StatsTransScrollList.h"

#ifndef EXTERN_STATSTRANSALLSCROLLLIST
# define EXTERN_STATSTRANSALLSCROLLLIST extern
#endif

@interface StatsTransAllScrollList : StatsTransScrollList
{
}

- (void)searchMatch:(struct s_search_infos*)ps_infos addSplit:(Int16)h_split;

@end

#endif	/* __STATSTRANSALLSCROLLLIST_H__ */
