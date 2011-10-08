/* 
 * ExternalCurrencyMaTi.m -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Thu Oct 26 16:57:55 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jan 11 14:25:01 2008
 * Update Count    : 19
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: ExternalCurrencyMaTi.m,v $
 * Revision 1.2  2008/01/14 16:56:49  max
 * Rework external currencies handling.
 *
 * Revision 1.1  2006/11/04 23:47:51  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_EXTERNALCURRENCYMATI
#include "ExternalCurrencyMaTi.h"

#include "ids.h"


@implementation ExternalCurrencyMaTi

- (BOOL)getReferenceFrom:(Currency*)oCurrencies
	    andPutRateIn:(struct s_eur_ref*)ps_eur_ref
{
  struct s_external_currency_mati *ps_ext_cur;
  struct s_currency *ps_currency;

  ps_currency = [oCurrencies getId:oCurrencies->uh_ref_id];
  ps_ext_cur = [self getISO4217:ps_currency->ra_iso4217];
  [oCurrencies getFree:ps_currency];

  if (ps_ext_cur == NULL)
    return false;

  ps_eur_ref->d_eur_ref_currency_amount = ps_ext_cur->ui_dec;
  ps_eur_ref->d_eur_ref_currency_amount /= (double)ps_ext_cur->ui_dec_factor;
  ps_eur_ref->d_eur_ref_currency_amount += ps_ext_cur->ui_int;
  ps_eur_ref->d_eur_ref_reference_amount = ps_ext_cur->ui_nb_eur;

  [self getFree:ps_ext_cur];

  return true;
}


- (void*)getISO4217:(Char*)pa_iso4217
{
  struct s_external_currency_mati *ps_external;
  UInt16 uh_size, index, uh_last = 0;
  Int16 h_inc = 0, h_cmp;

  if (StrLen(pa_iso4217) != 3)
    return NULL;

  uh_size = DmNumRecords(self->db);
  index = uh_size >> 1;

  for (;;)
  {
    // Il y a au moins un enregistrement dans la base et aucun n'est
    // supprimé puisque cette base n'est pas gérée sur Palm.
    ps_external = MemHandleLock(DmQueryRecord(self->db, index)); // OK

    h_cmp = StrCompare(pa_iso4217, ps_external->ra_iso4217);
    if (h_cmp == 0)
      return ps_external;

    MemPtrUnlock(ps_external);

    // Première fois
    if (h_inc == 0)
    {
      // Il faut aller plus loin
      if (h_cmp > 0)
      {
	h_inc = 1;
	uh_last = uh_size - 1;
      }
      // On est trop loin, il faut revenir en arrière
      else
      {
	h_inc = -1;
	uh_last = 0;
      }
    }
    // À partir de là, on ne trouvera plus rien...
    else if ((h_inc < 0) ^ (h_cmp < 0))
      return NULL;
 
    if (index == uh_last)
      return NULL;

    index += h_inc;
  }
}


- (void)adjustCurrency:(struct s_currency*)ps_currency
  withExternalCurrency:(void*)ps_ext_cur_v
	  andReference:(struct s_eur_ref*)ps_eur_ref
{
  struct s_external_currency_mati *ps_ext_cur = ps_ext_cur_v;
  double d_eur_currency_amount, d_eur_reference_amount;

  d_eur_currency_amount = ps_ext_cur->ui_dec;
  d_eur_currency_amount /= (double)ps_ext_cur->ui_dec_factor;
  d_eur_currency_amount += ps_ext_cur->ui_int;
  d_eur_reference_amount = ps_ext_cur->ui_nb_eur;

  // La partie "devise" est un nombre entier
  if ((double)(UInt32)ps_currency->d_currency_amount
      == ps_currency->d_currency_amount
      // ET la partie référence n'en est pas un
      && (double)(UInt32)ps_currency->d_reference_amount
      != ps_currency->d_reference_amount)
  {
    // Par exemple :
    // 1 EUR		= 6.55957 FRF
    // On va préserver la partie devise
    // => ps_currency->d_currency_amount ne bouge pas

    ps_currency->d_reference_amount =
      (ps_currency->d_currency_amount
       * d_eur_reference_amount * ps_eur_ref->d_eur_ref_currency_amount)
      / (d_eur_currency_amount * ps_eur_ref->d_eur_ref_reference_amount);
  }
  else
  {
    // Par exemple :
    //  2 DEM	= 1 EUR
    //  1.5 GBP	= 1 EUR
    //  5.3 XXX	= 2.5 EUR
    // On va préserver la partie monnaie de référence
    // => ps_currency->d_reference_amount ne bouge pas

    ps_currency->d_currency_amount =
      (ps_currency->d_reference_amount
       * d_eur_currency_amount * ps_eur_ref->d_eur_ref_reference_amount)
      / (d_eur_reference_amount * ps_eur_ref->d_eur_ref_currency_amount);
  }
}


- (Char*)iso4217:(void*)ps_ext_cur
{
  return ((struct s_external_currency_mati*)ps_ext_cur)->ra_iso4217;
}


//
// Pour cette base c'est la même date de mise à jour pour toutes les devises
- (UInt32)lastUpdate:(void*)ps_ext_cur
{
  if (self->ui_last_update == 0)
    self->ui_last_update = [self getLastUpdateDate];

  return self->ui_last_update;
}


- (UInt32)creatorType:(UInt32*)ui_type name:(Char*)pa_name
{
  //MemMove(pa_name, MaTiExtCurrName, sizeof(MaTiExtCurrName));
  *pa_name = '\0';		// On se fout du nom...

  *ui_type = MaTiExtCurrType;
  return MaTiCreatorID;
}

@end
