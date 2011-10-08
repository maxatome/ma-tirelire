/* -*- objc -*-
 * ExternalCurrency.h -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Thu Oct 26 16:55:20 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Dec 13 12:19:54 2007
 * Update Count    : 31
 * Status          : Unknown, Use with caution!
 */

#ifndef	__EXTERNALCURRENCY_H__
#define	__EXTERNALCURRENCY_H__

#include "DBItem.h"
#include "Currency.h"


#ifndef EXTERN_EXTERNALCURRENCY
# define EXTERN_EXTERNALCURRENCY extern
#endif


// Taux de conversion de la devise de référence par rapport à l'euro
// rempli par -getReference:andPutRateIn:
struct s_eur_ref
{
  double d_eur_ref_currency_amount;
  double d_eur_ref_reference_amount;
};


@interface ExternalCurrency : DBItem
{
}

- (UInt32)getLastUpdateDate;

- (BOOL)getReferenceFrom:(Currency*)oCurrencies
	    andPutRateIn:(struct s_eur_ref*)ps_eur_ref;

- (void*)getISO4217:(Char*)pa_iso4217;
- (void)adjustCurrency:(struct s_currency*)ps_currency
  withExternalCurrency:(void*)ps_ext_cur
	  andReference:(struct s_eur_ref*)ps_eur_ref;

- (Char*)iso4217:(void*)ps_ext_cur;
- (UInt32)lastUpdate:(void*)ps_ext_cur;

- (UInt32)creatorType:(UInt32*)ui_type name:(Char*)pa_name;

- (UInt16)dbFirstItem;

@end

#endif	/* __EXTERNALCURRENCY_H__ */
