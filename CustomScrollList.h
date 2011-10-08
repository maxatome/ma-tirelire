/* -*- objc -*-
 * CustomScrollList.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Ven aoû  5 22:15:25 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Oct 31 14:54:24 2006
 * Update Count    : 2
 * Status          : Unknown, Use with caution!
 */

#ifndef	__CUSTOMSCROLLLIST_H__
#define	__CUSTOMSCROLLLIST_H__

#include "SumScrollList.h"

#include "Transaction.h"


#ifndef EXTERN_CUSTOMSCROLLLIST
# define EXTERN_CUSTOMSCROLLLIST extern
#endif

struct s_clist_stats_search
{
  UInt16  uh_beg_date;		// Ces deux dates doivent rester ensemble
  UInt16  uh_end_date;
  UInt32  ui_rec_flags_mask;
  UInt32  ui_rec_flags_value;
  UInt32  *pul_types;		// Si != NULL, types à prendre en compte
  Int16   h_one_type;		// Si > 0, un seul type à tester
  UInt16  uh_on;
  UInt16  uh_accounts;
#define STATS_SCREEN_TYPES	0x0001
#define STATS_SCREEN_MODES	0x0002
#define STATS_SCREEN_PERIOD	0x0004
  UInt16  uh_stats_screens;
  Boolean b_val_date;		// En fonction de la date de valeur
  Boolean b_ignore_nulls;	// Ignore les montants nuls
  Boolean b_flagged;
};

@interface CustomScrollList : SumScrollList
{
  MemHandle vh_infos;

  UChar rua_accounts_curr[MAX_ACCOUNTS];

#define CLIST_SUM_ALL        0
#define CLIST_SUM_SELECT     1
#define CLIST_SUM_NON_SELECT 2
  UInt16 uh_sum_filter;
}

- (UInt16)initAccountsCurrencyCache;
- (UInt16)accounts;
- (void)initFormCurrency;

- (void)changeSumFilter:(UInt16)uh_sum_filter;

#define CLIST_SELECT_INVERT	-1
#define CLIST_SELECT_CLEAR	0
#define CLIST_SELECT_SET	1
- (void)selectChange:(Int16)h_action;

- (Boolean)beforeQuitting;

//
// Recherche...
struct s_search_infos
{
  Currency *oCurrencies;
  Transaction *oTransactions;

  struct s_currency *ps_form_currency;	   // Devise du formulaire
  struct s_currency *ps_other_currency;	   // Devise temporaire

  // L'opération en cours de recherche
  const struct s_transaction *ps_tr;
  t_amount l_amount;
  struct s_rec_options s_options;
  UInt16 uh_account;		// Compte de l'opération
  UInt16 uh_date;		// Date de l'opération

  UInt16 index;			// Index de l'opération

  // Les critères de recherche des stats
  struct s_clist_stats_search s_search_criteria;
};

- (Boolean)searchFrom:(UInt16)uh_from amount:(Boolean)b_dont_compute_amount;
- (Boolean)searchMatch:(struct s_search_infos*)ps_infos;
- (Boolean)searchInit:(struct s_search_infos*)ps_infos;
- (void)searchFree:(struct s_search_infos*)ps_infos;

@end

#endif	/* __CUSTOMSCROLLLIST_H__ */
