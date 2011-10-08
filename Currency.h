/* -*- objc -*-
 * Currency.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Thu May 20 18:17:17 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Jul 16 10:28:08 2007
 * Update Count    : 22
 * Status          : Unknown, Use with caution!
 */

#ifndef	__CURRENCY_H__
#define	__CURRENCY_H__

#include "DBItemId.h"

#ifndef EXTERN_CURRENCY
# define EXTERN_CURRENCY extern
#endif

#define NUM_CURRENCIES	(1 << 8)

//
// Currencies
struct s_currency
{
  UInt32 ui_id:8;		// ID de la devise
  UInt32 ui_reference:1;	// C'est LA devise servant de référence
  UInt32 ui_reserved:23;	// Reserved for future use
  double d_reference_amount;	// Somme en monnaie de référence
  double d_currency_amount;	// Équivalent dans cette devise
#define CURRENCY_ISO4217_LEN	4
  Char ra_iso4217[CURRENCY_ISO4217_LEN]; // Nom ISO-4217
#define CURRENCY_NAME_MAX_LEN	(4 + 1)
  Char ra_name[0];		// Nom devise fini par NUL (longueur variable)
};


@interface Currency : DBItemId
{
  UInt16 uh_ref_id;
}

- (UInt16)referenceId;
- (Boolean)changeReferenceToId:(UInt16)uh_new_ref_id;

- (UInt16)convertAmount:(t_amount*)pl_amount
		 fromId:(UInt16)uh_from_cur
		   toId:(UInt16)uh_to_cur;

- (void)updateRates;
- (void)getLastUpdateDates:(UInt32*)pui_last_upd_dates;

@end

struct __s_list_currency_buf
{
  __STRUCT_DBITEM_LIST_BUF(Currency);
  UInt16 uh_largest_currency;
  Char a_dec_sep;
  Char ra_edit_entry[32];	// XXX il faudrait un define XXX
  UInt16 ruh_list2index[0];
};

EXTERN_CURRENCY t_amount currency_convert_amount(t_amount l_amount,
						 struct s_currency *ps_old_cur,
						 struct s_currency*ps_new_cur);

EXTERN_CURRENCY t_amount currency_convert_amount2(t_amount l_amount,
						  t_amount l_from_amount,
						  t_amount l_to_amount);

#endif	/* __CURRENCY_H__ */
