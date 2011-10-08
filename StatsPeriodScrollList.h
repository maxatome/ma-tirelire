/* -*- objc -*-
 * StatsPeriodScrollList.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Jeu aoû  4 23:37:40 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Jan 22 11:49:32 2008
 * Update Count    : 2
 * Status          : Unknown, Use with caution!
 */

#ifndef	__STATSPERIODSCROLLLIST_H__
#define	__STATSPERIODSCROLLLIST_H__

#include "CustomScrollList.h"

#ifndef EXTERN_STATSPERIODSCROLLLIST
# define EXTERN_STATSPERIODSCROLLLIST extern
#endif

struct s_stats_period
{
  t_amount l_sum;		// Somme pour ce type
  UInt16 uh_num_op;		// Nombre d'opérations
  UInt16 uh_accounts;		// Comptes concernés
  DateType s_beg;		// Date de début de la période
  DateType s_end;		// Date de fin de la période
  Boolean b_selected;		// Cette somme est sélectionnée
};

// Spécial semaines et quinzaines
struct s_week_interval
{
  Char ra_format[16];		// Format de la période
  Char ra_beg_day[5];		// Premier jour de la semaine
  Char ra_end_day[5];		// Dernier jour de la semaine
  DateFormatType e_date_short;	// Format de la date
};

struct s_private_search_period
{
  struct s_stats_period *ps_base_period_infos;
  struct s_stats_period *ps_cache;
};

@interface StatsPeriodScrollList : CustomScrollList
{
  struct s_week_interval s_week_interval;

  // Pour l'affinage par mode ou par type
  DateType rs_period_dates[2];

  struct s_private_search_period *ps_search_period_infos;
}

#define PERIOD_LABEL_MAX_LEN	64
- (void)fillLabel:(Char*)ra_buf
	forPeriod:(struct s_stats_period*)ps_period_infos;

@end

#endif	/* __STATSPERIODSCROLLLIST_H__ */
