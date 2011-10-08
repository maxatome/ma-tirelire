/* -*- objc -*-
 * ExternalCurrencyMaTi.h -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Thu Oct 26 16:57:58 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Oct 26 17:30:40 2006
 * Update Count    : 3
 * Status          : Unknown, Use with caution!
 */

#ifndef	__EXTERNALCURRENCYMATI_H__
#define	__EXTERNALCURRENCYMATI_H__

#include "ExternalCurrency.h"

#ifndef EXTERN_EXTERNALCURRENCYMATI
# define EXTERN_EXTERNALCURRENCYMATI extern
#endif

// External currency: used to update rates...
struct s_external_currency_mati
{
  UInt32 ui_int;		// Partie entière
  UInt32 ui_dec;		// Partie décimale
  UInt32 ui_dec_factor;		// Facteur à appliquer pour la partie décimale
  UInt32 ui_nb_eur;		// Équivalent en euros
  Char   ra_iso4217[0];		// Nom de la monnaie au standard ISO-4217
};


@interface ExternalCurrencyMaTi : ExternalCurrency
{
  UInt32 ui_last_update;
}

@end

#endif	/* __EXTERNALCURRENCYMATI_H__ */
