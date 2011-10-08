/* -*- objc -*-
 * StatsModeScrollList.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Dim aoû  7 10:36:31 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Jan 22 11:49:16 2008
 * Update Count    : 3
 * Status          : Unknown, Use with caution!
 */

#ifndef	__STATSMODESCROLLLIST_H__
#define	__STATSMODESCROLLLIST_H__

#include "CustomScrollList.h"

#ifndef EXTERN_STATSMODESCROLLLIST
# define EXTERN_STATSMODESCROLLLIST extern
#endif

struct s_stats_mode
{
  t_amount l_sum;		// Somme pour ce mode
  UInt16 uh_num_op;		// Nombre d'opérations
  UInt16 uh_accounts;		// Comptes concernés
  UInt16 uh_selected:1;		// Cette somme est sélectionnée
  UInt16 uh_id:5;		// ID du mode
};


struct s_private_search_mode
{
  struct s_stats_mode *ps_base_mode_infos; // Liste des modes 
  UChar rua_id2list[NUM_MODES];		   // Correspondance ID mode > idx list
};

@interface StatsModeScrollList : CustomScrollList
{
  UInt16 uh_mode;		// Pour StatsTransScrollList

  struct s_private_search_mode *ps_search_mode_infos;
}

@end

#endif	/* __STATSMODESCROLLLIST_H__ */
