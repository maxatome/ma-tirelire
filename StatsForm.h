/* -*- objc -*-
 * StatsForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Dim mar 27 22:41:00 2005
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__STATSFORM_H__
#define	__STATSFORM_H__

#include "MaTiForm.h"
#include "Type.h"

#include "misc.h"

#ifndef EXTERN_STATSFORM
# define EXTERN_STATSFORM extern
#endif

#define TYPES_BITS_WIDTH	DWORDFORBITS(NUM_TYPES)	// mcc hack

@interface StatsForm : MaTiForm
{
  VoidHand pv_popup_types;
  VoidHand pv_popup_modes;
  VoidHand pv_popup_accounts;	// Liste des comptes

  UInt32 rul_types[TYPES_BITS_WIDTH];

  DateType rs_date[2];
  DateFormatType e_format;

  UInt16 uh_oldest_year:7;
  UInt16 uh_menu_choice:3;
  UInt16 uh_week_bounds:1;
}

- (void)applyPrevStat:(struct s_stats_prefs*)ps_stats;
- (void)initOldestYear;

- (void)initAccountsPopup:(UInt16)uh_accounts;

- (void)initAllDates:(Boolean)b_init_all;

- (void)chooseMonth:(UInt16)uh_month_choice today:(DateType*)ps_today;
- (void)chooseYear:(UInt16)uh_year_choice today:(DateType*)ps_today;

- (void)initByPopup:(UInt16)index;

@end

EXTERN_STATSFORM void stats_week_beg_end(DateType *ps_date, Boolean b_biweek);

#endif	/* __STATSFORM_H__ */
