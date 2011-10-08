/* 
 * ExternalCurrencyCur4.m -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Thu Oct 26 17:30:11 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb  1 17:16:13 2008
 * Update Count    : 57
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: ExternalCurrencyCur4.m,v $
 * Revision 1.3  2008/02/01 17:15:33  max
 * Cosmetic change.
 *
 * Revision 1.2  2008/01/14 16:58:27  max
 * Rework external currencies handling.
 *
 * Revision 1.1  2006/11/04 23:47:51  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_EXTERNALCURRENCYCUR4
#include "ExternalCurrencyCur4.h"

#include "misc.h"


// External currency from Currency-4.0 programme (before modifying)
struct s_external_currency_currency4
{
  Char   isoCode[4];		// Nom de la monnaie au standard ISO-4217
  double value;			// Équivalent pour 1 euro
  UInt32 pDate;			// TimDateTimeToSeconds(DateTime) de mise à jour
  unsigned char onEuro;		// z z z z 0 0 0 x
				// x->0/1 (is on euro: yes/no) ???
				// zzzz -> rate source
				// - 0 European Central Bank
				// - 1 Federal Reserve Bank
				// - 2 Pacific Exchange Rate Service,
				//     Univ. of British Columbia
				// - 3 User defined
				// - 4 Estimated
  UChar padd[3];	// toujours à 0
};


// External currency from Currency-4.0 programme (after modifying)
struct s_external_currency_currency4_after_cur4
{
  Char          *nickName;	// Dummy value in PDB, used only by Cur4
  Char          *fullName;	// Dummy value in PDB, used only by Cur4
  Char          onEuro;		// z z z z 0 0 0 x
				// x->0/1 (is on euro: yes/no) ???
				// zzzz -> rate source
				// - 0 European Central Bank
				// - 1 Federal Reserve Bank
				// - 2 Pacific Exchange Rate Service,
				//     Univ. of British Columbia
				// - 3 User defined
				// - 4 Estimated
  double        oneBaseUnit;
  Char          editable;
  double        value;
  Char          ndec;
  Char          pos;
  DateTimeType  date;
};


#define CUR4_BASE_IDX	9

@implementation ExternalCurrencyCur4

- (ExternalCurrencyCur4*)init
{
  void *pv_buf;
  UInt32 ui_version = 0;
  UInt16 uh_num_curr = 0, uh_size;
  UInt16 uh_err;

  if ([super init] == nil)
    return nil;

  // On regarde si la base a été modifiée par Currency4

  // On charge le numéro de version
  pv_buf = [self getId:0];
  if (pv_buf == NULL)
    return nil;

  uh_size = MemPtrSize(pv_buf);
  if (uh_size == sizeof(ui_version))
    ui_version = *(UInt32*)pv_buf;

  [self getFree:pv_buf];

  // Numéro de version OK => a priori base "après-currency4"
  switch (ui_version)
  {
  case '0019': // 3.2b used
  case '0055': // 3.3beta
  case '0037': // 3.4beta
  case '0001': // 3.4
  case '0002': // 4.0
  case '0003': // 4.2
    // On charge le nombre de devises
    pv_buf = [self getId:1];
    if (pv_buf == NULL)
    {
      uh_err = 1;
      goto bad;
    }

    if (MemPtrSize(pv_buf) == sizeof(uh_num_curr))
      uh_num_curr = *(UInt16*)pv_buf;

    [self getFree:pv_buf];

    // Si cet enregistrement n'est pas bon, alors la base n'est pas bonne
    if (uh_num_curr + CUR4_BASE_IDX != DmNumRecords(self->db))
    {
      uh_err = 2;
      goto bad;
    }

    // On a affaire à une base des devises déjà retraitée par Currency4
    self->b_after_cur4 = true;

    return self;
  }

  // Sinon, il faut que ça fasse la taille d'un enregistrement "avant-currency4"
  if (uh_size == sizeof(struct s_external_currency_currency4))
  {
    MemHandle pv_rec;
    UInt16 index;

    // Par acquis de confiance on vérifie la taille des 3 suivants
    for (index = 1; index < 4; index++)
    {
      pv_rec = DmQueryRecord(self->db, index);
      if (pv_rec == NULL
	  || MemHandleSize(pv_rec)
	  != sizeof(struct s_external_currency_currency4))
      {
	uh_err = 3;
	goto bad;
      }
    }
    
    return self;
  }

  uh_err = 4;

bad:
  // On ne reconnaît pas le format de cette base
  return nil;
}


- (BOOL)getReferenceFrom:(Currency*)oCurrencies
	    andPutRateIn:(struct s_eur_ref*)ps_eur_ref
{
  struct s_external_currency_currency4 *ps_ext_cur;
  struct s_currency *ps_currency;
  Boolean b_ret = true;

  ps_currency = [oCurrencies getId:oCurrencies->uh_ref_id];

  // La devise EUR n'est pas présente dans cette base, puisque tout
  // est basée sur elle
  if (StrCompare(ps_currency->ra_iso4217, "EUR") == 0)
    ps_eur_ref->d_eur_ref_currency_amount = 1.;
  else
  {
    ps_ext_cur = [self getISO4217:ps_currency->ra_iso4217];

    if (ps_ext_cur == NULL)
      b_ret = false;
    else
    {
      ps_eur_ref->d_eur_ref_currency_amount = ps_ext_cur->value;

      [self getFree:ps_ext_cur];
    }
  }

  [oCurrencies getFree:ps_currency];

  ps_eur_ref->d_eur_ref_reference_amount = 1.;

  return b_ret;
}


//
// Cette base n'a pas l'air d'être triée...
- (void*)getISO4217:(Char*)pa_iso4217
{
  struct s_external_currency_currency4 *ps_external;
  UInt16 index, uh_first;

  if (StrLen(pa_iso4217) != 3)
    return NULL;

  uh_first = self->b_after_cur4 ? CUR4_BASE_IDX : 0;

  for (index = DmNumRecords(self->db); index-- > uh_first; )
  {
    ps_external = [self getId:index];
    if (ps_external != NULL)
    {
      if (StrCompare(pa_iso4217, ps_external->isoCode) == 0)
	return ps_external;

      [self getFree:ps_external];
    }
  }

  return NULL;
}


- (void*)getId:(UInt16)uh_id
{
  // Si la base a été modifiée par Cur4 ET qu'on tente d'accéder aux devises
  if (self->b_after_cur4 && uh_id >= CUR4_BASE_IDX)
  {
    struct s_external_currency_currency4 *ps_external, *ps_return;
    struct s_external_currency_currency4_after_cur4 *ps_external_cur4, *ps_cur;

    NEW_PTR(ps_return, sizeof(*ps_return), return NULL);

    // Le code ISO est bien dans cet enregistrement, mais le reste
    // dans dans le numéro 2
    ps_external = [super getId:uh_id];
    MemMove(ps_return->isoCode, ps_external->isoCode,
	    sizeof(ps_return->isoCode));
    [self getFree:ps_external];

    // Reste des infos
    ps_external_cur4 = [self getId:2];

    ps_cur = ps_external_cur4 + uh_id - CUR4_BASE_IDX;

    // Et le reste
    ps_return->onEuro = ps_cur->onEuro;
    ps_return->value = ps_cur->oneBaseUnit;
    ps_return->pDate = TimDateTimeToSeconds(&ps_cur->date);

    [self getFree:ps_external_cur4];

    return ps_return;
  }

  return [super getId:uh_id];
}


- (void)getFree:(void*)ps_item
{
  if (self->b_after_cur4 && MemPtrDataStorage(ps_item) == false)
    MemPtrFree(ps_item);
  else
    [super getFree:ps_item];
}


- (void)adjustCurrency:(struct s_currency*)ps_currency
  withExternalCurrency:(void*)ps_ext_cur_v
	  andReference:(struct s_eur_ref*)ps_eur_ref
{
  struct s_external_currency_currency4 *ps_ext_cur = ps_ext_cur_v;

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
       * 1. /* EUR */ * ps_eur_ref->d_eur_ref_currency_amount)
      / (ps_ext_cur->value * ps_eur_ref->d_eur_ref_reference_amount);
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
       * ps_ext_cur->value * ps_eur_ref->d_eur_ref_reference_amount)
      / (1. /* EUR */ * ps_eur_ref->d_eur_ref_currency_amount);
  }
}


- (Char*)iso4217:(void*)ps_ext_cur
{
  return ((struct s_external_currency_currency4*)ps_ext_cur)->isoCode;
}


- (UInt32)lastUpdate:(void*)ps_ext_cur
{
  return ((struct s_external_currency_currency4*)ps_ext_cur)->pDate;
}


- (UInt32)creatorType:(UInt32*)ui_type name:(Char*)pa_name
{
#define Cur4ExtCurrName	"CupdateDB" // À charger en priorité (avant CurrencyDB)
  MemMove(pa_name, Cur4ExtCurrName, sizeof(Cur4ExtCurrName));

  *ui_type = 'Data';
  return 'cRr6';
}


- (UInt16)dbMaxEntries
{
  UInt16 uh_num = [super dbMaxEntries];

  if (self->b_after_cur4)
    uh_num -= CUR4_BASE_IDX;	// Skip 9 first items...

  return uh_num;
}


- (UInt16)dbFirstItem
{
  return self->b_after_cur4 ? CUR4_BASE_IDX : 0;
}

@end
