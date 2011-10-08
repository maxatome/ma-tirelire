/* -*- objc -*-
 * ExternalCurrencyGlobal.h -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Sat Dec 30 21:32:15 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Wed Dec 12 16:13:09 2007
 * Update Count    : 7
 * Status          : Unknown, Use with caution!
 */

#ifndef	__EXTERNALCURRENCYGLOBAL_H__
#define	__EXTERNALCURRENCYGLOBAL_H__

#include "Object.h"
#include "ExternalCurrency.h"

#ifndef EXTERN_EXTERNALCURRENCYGLOBAL
# define EXTERN_EXTERNALCURRENCYGLOBAL extern
#endif

struct s_external_currency
{
  ExternalCurrency *oExternalCurrency;
  struct s_eur_ref s_eur_ref;
};

#define EXTERNAL_CURRENCIES_NUM	2

struct s_external_currency_update
{
  UInt32 rui_last_dates[EXTERNAL_CURRENCIES_NUM];
  UInt32 rui_new_dates[EXTERNAL_CURRENCIES_NUM];
  UInt32 ui_now;		// Set to TimGetSeconds() by the caller
  Boolean b_updated;
};


@interface ExternalCurrencyGlobal : Object
{
  struct s_external_currency rs_ext_curr[EXTERNAL_CURRENCIES_NUM];

  UInt16 *puh_iso_list;
}

+ (ExternalCurrencyGlobal*)new:(struct s_external_currency_update*)ps_update;
- (ExternalCurrencyGlobal*)init:(struct s_external_currency_update*)ps_update;
- (ExternalCurrencyGlobal*)initReferenceFrom:(Currency*)oCurrencies;

- (UInt16)buildListLargestISO4217:(UInt16*)puh_largest;

- (Boolean)withCurrencyListIndex:(UInt16)index
		  adjustCurrency:(struct s_currency*)ps_currency
		    andPutNameIn:(Char*)pa_iso4217;

- (Boolean)withCurrencyISO4217:(Char*)pa_iso4217
		adjustCurrency:(struct s_currency*)ps_currency_from
			    in:(struct s_currency*)ps_currency_to
			update:(struct s_external_currency_update*)ps_update;

@end

EXTERN_EXTERNALCURRENCYGLOBAL void external_currency_iso_list_draw
		(Int16 h_line, RectangleType *prec_bounds, Char **ppa_lines);

#endif	/* __EXTERNALCURRENCYGLOBAL_H__ */
