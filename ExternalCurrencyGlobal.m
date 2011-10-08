/* 
 * ExternalCurrencyGlobal.m -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Sat Dec 30 21:32:12 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jan 11 14:16:14 2008
 * Update Count    : 32
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: ExternalCurrencyGlobal.m,v $
 * Revision 1.1  2008/01/14 17:30:14  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_EXTERNALCURRENCYGLOBAL
#include "ExternalCurrencyGlobal.h"

#include "ExternalCurrencyMaTi.h"
#include "ExternalCurrencyCur4.h"
#include "misc.h"


#define EXT_CURR_SHIFT	15
#define EXT_CURR_MASK	(((UInt16)1 << EXT_CURR_SHIFT) - 1)

// Caractère à ajouter en fin de ligne dans la liste des codes ISO
// pour les taux ne venant pas de Ma Tirelire
#define FOREIGN_ISO_RATE_STR	"."
#define FOREIGN_ISO_RATE_CHAR	FOREIGN_ISO_RATE_STR[0]

static Int16 _iso_compare(UInt16 *puh1, UInt16 *puh2, Int32 l_self)
{
  ExternalCurrencyGlobal *self = (ExternalCurrencyGlobal*)l_self;
  ExternalCurrency *o1, *o2;
  MemHandle pv1, pv2;
  void *ps1, *ps2;
  Int16 h_ret;

  o1 = self->rs_ext_curr[*puh1 >> EXT_CURR_SHIFT].oExternalCurrency;
  o2 = self->rs_ext_curr[*puh2 >> EXT_CURR_SHIFT].oExternalCurrency;

  pv1 = DmQueryRecord(o1->db, *puh1 & EXT_CURR_MASK);
  pv2 = DmQueryRecord(o2->db, *puh2 & EXT_CURR_MASK);

  ps1 = MemHandleLock(pv1);
  ps2 = MemHandleLock(pv2);

  h_ret = StrCompare([o1 iso4217:ps1], [o2 iso4217:ps2]);

  // Les deux codes ISO sont égaux on met le plus récent en tête, car
  // c'est lui qu'on va conserver
  if (h_ret == 0)
    h_ret = ([o1 lastUpdate:ps1] > [o2 lastUpdate:ps2]) ? -1 : 1;

  MemHandleUnlock(pv1);
  MemHandleUnlock(pv2);

  return h_ret;
}


void external_currency_iso_list_draw(Int16 h_line, RectangleType *prec_bounds,
				     Char **ppa_lines)
{
  ExternalCurrencyGlobal *self = (ExternalCurrencyGlobal*)ppa_lines;
  ExternalCurrency *oExternalCurrency;
  void *ps_ext_cur;
  Char *pa_iso;
  UInt16 uh_iso_idx, uh_foreign_idx, uh_len;

  uh_iso_idx = self->puh_iso_list[h_line];

  uh_foreign_idx = uh_iso_idx >> EXT_CURR_SHIFT;
  uh_iso_idx &= EXT_CURR_MASK;

  oExternalCurrency = self->rs_ext_curr[uh_foreign_idx].oExternalCurrency;

  ps_ext_cur = [oExternalCurrency getId:uh_iso_idx];

  pa_iso = [oExternalCurrency iso4217:ps_ext_cur];
  uh_len = StrLen(pa_iso);
  WinDrawChars(pa_iso, uh_len, prec_bounds->topLeft.x, prec_bounds->topLeft.y);

  // Taux étranger à Ma Tirelire
  if (uh_foreign_idx > 0)
    WinDrawChars(FOREIGN_ISO_RATE_STR, 1,
		 prec_bounds->topLeft.x + FntCharsWidth(pa_iso, uh_len),
		 prec_bounds->topLeft.y);

  [oExternalCurrency getFree:ps_ext_cur];
}


@implementation ExternalCurrencyGlobal

+ (ExternalCurrencyGlobal*)new:(struct s_external_currency_update*)ps_update
{
  return [[self alloc] init:ps_update];
}


- (ExternalCurrencyGlobal*)init:(struct s_external_currency_update*)ps_update
{
  // Les devises de Ma Tirelire et celles de Currency 4
  ExternalCurrency_c *roExternalCurrencyClass[EXTERNAL_CURRENCIES_NUM] =
  {
    (ExternalCurrency_c*)ExternalCurrencyMaTi,
    (ExternalCurrency_c*)ExternalCurrencyCur4
  };
  ExternalCurrency *oExtCur;
  UInt16 index;
  Boolean b_ok = false;

  for (index = 0; index < EXTERNAL_CURRENCIES_NUM; index++)
  {
    oExtCur = [roExternalCurrencyClass[index] new];
    if (oExtCur != nil)
    {
      // On ne doit pas charger les devises externes trop anciennes
      if (ps_update != NULL
	  && [oExtCur getLastUpdateDate] <= ps_update->rui_last_dates[index])
      {
	[oExtCur free];
	continue;
      }

      self->rs_ext_curr[index].oExternalCurrency = oExtCur;

      b_ok = true;
    }
  }

  return b_ok ? self : [self free];
}


- (ExternalCurrencyGlobal*)initReferenceFrom:(Currency*)oCurrencies
{
  ExternalCurrency *oExternalCurrency;
  UInt16 index;
  Boolean b_free = true;

  for (index = EXTERNAL_CURRENCIES_NUM; index-- > 0; )
  {
    oExternalCurrency = self->rs_ext_curr[index].oExternalCurrency;
    if (oExternalCurrency == nil)
      continue;

    if ([oExternalCurrency getReferenceFrom:oCurrencies
			   andPutRateIn:&self->rs_ext_curr[index].s_eur_ref])
      b_free = false;
    else
      self->rs_ext_curr[index].oExternalCurrency = [oExternalCurrency free];
  }

  if (b_free)
    return [self free];

  return self;
}


- (UInt16)buildListLargestISO4217:(UInt16*)puh_largest
{
  ExternalCurrency *oExternalCurrency;
  UInt16 i_db, index, uh_num, uh_from, uh_real_num;

  // Nombre d'entrées au maximum
  uh_num = 0;
  for (i_db = EXTERNAL_CURRENCIES_NUM; i_db-- > 0; )
  {
    oExternalCurrency = self->rs_ext_curr[i_db].oExternalCurrency;
    if (oExternalCurrency != nil)
      uh_num += [oExternalCurrency dbMaxEntries];
  }

  if (uh_num == 0)
    return 0;

  if (self->puh_iso_list != NULL)
    MemPtrFree(self->puh_iso_list);

  NEW_PTR(self->puh_iso_list, uh_num * sizeof(UInt16), return 0);

  uh_real_num = 0;
  for (i_db = EXTERNAL_CURRENCIES_NUM; i_db-- > 0; )
  {
    oExternalCurrency = self->rs_ext_curr[i_db].oExternalCurrency;
    if (oExternalCurrency != nil)
    {
      uh_from = [oExternalCurrency dbFirstItem];
      uh_num = [oExternalCurrency dbMaxEntries] + uh_from;
      for (index = uh_from; index < uh_num; index++)
	if (DmQueryRecord(oExternalCurrency->db, index) != NULL)
	  self->puh_iso_list[uh_real_num++] = (i_db << EXT_CURR_SHIFT) | index;
    }
  }

  if (uh_real_num == 0)
    return 0;

  // On trie par ordre alphabétique
  SysInsertionSort(self->puh_iso_list, uh_real_num,
		   sizeof(self->puh_iso_list[0]),
		   (CmpFuncPtr)_iso_compare, (Int32)self);

  // On élimine les doublons qui maintenant se suivent...
  {
    ExternalCurrency *oLastExtCur;
    void *ps_last, *ps_cur;
    UInt16 *puh_cur;
    Char *pa_last_iso, *pa_cur_iso;
    UInt16 uh_largest, uh_which, uh_foreign_width;

    // Caractère à ajouter en fin pour les taux ne venant pas de Ma Tirelire
    uh_foreign_width = FntCharWidth(FOREIGN_ISO_RATE_CHAR);

    puh_cur = self->puh_iso_list;

    uh_which = *puh_cur >> EXT_CURR_SHIFT;
    oLastExtCur = self->rs_ext_curr[uh_which].oExternalCurrency;
    ps_last = [oLastExtCur getId:*puh_cur & EXT_CURR_MASK];
    pa_last_iso = [oLastExtCur iso4217:ps_last];

    // Largeur maximale
    uh_largest = FntCharsWidth(pa_last_iso, StrLen(pa_last_iso));
    if (uh_which > 0)
      uh_largest += uh_foreign_width;

    puh_cur++;
    for (index = 1; index < uh_real_num; )
    {
      uh_which = *puh_cur >> EXT_CURR_SHIFT;
      oExternalCurrency	= self->rs_ext_curr[uh_which].oExternalCurrency;
      ps_cur = [oExternalCurrency getId:*puh_cur & EXT_CURR_MASK];
      pa_cur_iso = [oExternalCurrency iso4217:ps_cur];

      // Deux codes ISO identiques se suivent, on supprime le suivant,
      // car le sort a mis le plus récent en tête
      if (StrCompare(pa_last_iso, pa_cur_iso) == 0)
      {
	uh_real_num--;

	MemMove(puh_cur, puh_cur + 1,
		(uh_real_num - index) * sizeof(*self->puh_iso_list));

	[oExternalCurrency getFree:ps_cur];
      }
      else
      {
	UInt16 uh_width;
	
	[oLastExtCur getFree:ps_last];

	oLastExtCur = oExternalCurrency;
	ps_last = ps_cur;
	pa_last_iso = pa_cur_iso;

	// Largeur
	uh_width = FntCharsWidth(pa_last_iso, StrLen(pa_last_iso));
	if (uh_which > 0)
	  uh_width += uh_foreign_width;

	if (uh_width > uh_largest)
	  uh_largest = uh_width;

	index++;
	puh_cur++;
      }
    }

    [oLastExtCur getFree:ps_last];

    *puh_largest = uh_largest;
  }

  MemPtrResize(self->puh_iso_list, uh_real_num * sizeof(UInt16));

  return uh_real_num;
}


- (ExternalCurrencyGlobal*)free
{
  UInt16 index;

  for (index = EXTERNAL_CURRENCIES_NUM; index-- > 0; )
    if (self->rs_ext_curr[index].oExternalCurrency != nil)
      [self->rs_ext_curr[index].oExternalCurrency free];

  if (self->puh_iso_list != NULL)
    MemPtrFree(self->puh_iso_list);

  return [super free];
}


- (Boolean)withCurrencyListIndex:(UInt16)uh_iso_list_idx
		  adjustCurrency:(struct s_currency*)ps_currency
		    andPutNameIn:(Char*)pa_iso4217
{
  ExternalCurrency *oExternalCurrency;
  struct s_external_currency *ps_cur;
  void *pv_ext_cur;
  UInt16 index, uh_which;

  if (self->puh_iso_list == NULL)
    return NULL;

  index = self->puh_iso_list[uh_iso_list_idx];
  uh_which = (index >> EXT_CURR_SHIFT);
  index &= EXT_CURR_MASK;

  ps_cur = &self->rs_ext_curr[uh_which];
  oExternalCurrency = ps_cur->oExternalCurrency;

  pv_ext_cur = [oExternalCurrency getId:index];

  // On copie le nom ISO 4217 de la devise
  StrCopy(pa_iso4217, [oExternalCurrency iso4217:pv_ext_cur]);

  // On applique de la devise externe à la devise passée en paramètre
  [oExternalCurrency adjustCurrency:ps_currency
		     withExternalCurrency:pv_ext_cur
		     andReference:&ps_cur->s_eur_ref];

  [oExternalCurrency getFree:pv_ext_cur];

  return true;
}


- (Boolean)withCurrencyISO4217:(Char*)pa_iso4217
		adjustCurrency:(struct s_currency*)ps_currency_from
			    in:(struct s_currency*)ps_currency_to
			update:(struct s_external_currency_update*)ps_update
{
  ExternalCurrency *oExternalCurrency;
  struct s_external_currency *ps_cur, *ps_last = NULL;
  void *pv_ext_cur, *pv_last_cur = NULL;
  UInt32 ui_cur_date, ui_max_date = 0;
  UInt16 i_db;

  // Pour chaque base de devises externes
  ps_cur = self->rs_ext_curr;
  for (i_db = EXTERNAL_CURRENCIES_NUM; i_db-- > 0; ps_cur++)
  {
    oExternalCurrency = ps_cur->oExternalCurrency;
    if (oExternalCurrency != nil)
    {
      // Pas la peine de regarder cette base, elle a déjà été utilisée pour màj
      if (ps_update->rui_last_dates[i_db]
	  >= [oExternalCurrency getLastUpdateDate])
	continue;

      // On a une devise externe avec ce nom ISO
      pv_ext_cur = [oExternalCurrency getISO4217:pa_iso4217];
      if (pv_ext_cur != NULL)
      {
	ui_cur_date = [oExternalCurrency lastUpdate:pv_ext_cur];

	// La date de mise à jour ne peut pas être > à aujourd'hui
	if (ui_cur_date > ps_update->ui_now)
	  ui_cur_date = ps_update->ui_now;

	// Pour mettre à jour le AppInfoBlock de Currency
	if (ui_cur_date > ps_update->rui_new_dates[i_db])
	{
	  ps_update->rui_new_dates[i_db] = ui_cur_date;
	  ps_update->b_updated = true;
	}

	// Et sa date de mise à jour est la plus récente
	if (ui_cur_date > ui_max_date)
	{
	  ui_max_date = ui_cur_date;

	  if (ps_last != NULL)
	    [ps_last->oExternalCurrency getFree:pv_last_cur];

	  pv_last_cur = pv_ext_cur;
	  ps_last = ps_cur;
	}
	else
	  [oExternalCurrency getFree:pv_ext_cur];
      }
    }
  }

  // Monnaie pas trouvée
  if (ps_last == NULL)
    return false;

  // On recopie juste les taux...
  MemMove(ps_currency_to, ps_currency_from,
	  sizeof(*ps_currency_from) - CURRENCY_ISO4217_LEN);

  // On applique de la devise externe à la devise passée en paramètre
  [ps_last->oExternalCurrency adjustCurrency:ps_currency_to
			      withExternalCurrency:pv_last_cur
			      andReference:&ps_last->s_eur_ref];

  [ps_last->oExternalCurrency getFree:pv_last_cur];

  return true;
}

@end
