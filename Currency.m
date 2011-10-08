/* 
 * Currency.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Thu May 20 18:17:13 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jan 11 14:43:40 2008
 * Update Count    : 115
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: Currency.m,v $
 * Revision 1.10  2008/01/14 17:15:31  max
 * External currencies handling reworked.
 *
 * Revision 1.9  2006/11/04 23:47:58  max
 * External currencies are now handled by ExternalCurrency class.
 * Search for multiple ExternalCurrency instances.
 * Do not update currency rates anymore in -init.
 *
 * Revision 1.8  2006/10/05 19:08:47  max
 * In currency_convert_amount(), don't do anything if the two amounts are
 * the same.
 *
 * Revision 1.7  2006/07/03 15:03:22  max
 * Add currency_convert_amount2() function.
 *
 * Revision 1.6  2006/04/25 08:46:45  max
 * Add -getLastUpdateDate method.
 * Last rates date/time is now based on last modification date/time of
 * the external currencies database.
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.5  2005/08/20 13:06:46  max
 * Prepare switching to 64 bits amounts.
 *
 * Revision 1.4  2005/05/08 12:12:51  max
 * Delete unused struct __s_currency_popup_list.
 *
 * Revision 1.3  2005/03/27 15:38:18  max
 * If one or both currencies don't exist, currency_convert_amount returns
 * the amount untouched.
 *
 * Revision 1.2  2005/02/19 17:11:33  max
 * -fullNameOfId:len: returns NULL when currency don't exists.
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_CURRENCY
#include "Currency.h"

#include "BaseForm.h"		// list_line_draw_line

#include "MaTirelire.h"
#include "ExternalCurrencyGlobal.h"

#include "ids.h"
#include "misc.h"
#include "graph_defs.h"
#include "float.h"
#include "objRsc.h"		// XXX


// Ici on a autant d'entrée dans le cache que de devise possible car
// il n'y a pas d'entrée "Unknown" ou "Unfiled"
#define CURRENCY_NUM_CACHE_ENTRIES	NUM_CURRENCIES

//
// new_amount = old_amount x (new_cur / new_ref) x (old_ref / old_cur)
// l_amount est en centimes
//
t_amount currency_convert_amount(t_amount l_amount,
				 struct s_currency *ps_old_cur,
				 struct s_currency *ps_new_cur)
{
  double d_new_amount;

  // Au moins une des deux devises n'existe pas...
  if (ps_old_cur == NULL || ps_new_cur == NULL)
    return l_amount;

  d_new_amount = ((double)l_amount * ps_new_cur->d_currency_amount
		  * ps_old_cur->d_reference_amount)
    / (ps_new_cur->d_reference_amount * ps_old_cur->d_currency_amount);

  // Pour l'arrondi entier qui va suivre...
  if (l_amount < 0)
    d_new_amount -= 0.5;
  else
    d_new_amount += 0.5;

  return (t_amount)d_new_amount;
}


//
// l_amount est dans la même monnaie que l_from_amount et va être
// converti dans la même monnaie que l_to_amount
t_amount currency_convert_amount2(t_amount l_amount,
				  t_amount l_from_amount, t_amount l_to_amount)
{
  // l_from_amount -> l_to_amount
  // l_amount	   -> x
  //
  // x = (l_amount * l_to_amount) / l_from_amount

  double d_new_amount;

  // Cas particulier : rien ne change
  if (l_amount == l_from_amount)
    return l_to_amount;

  d_new_amount = (((double)l_amount * (double)l_to_amount)
		  / (double)l_from_amount);

  // Pour l'arrondi entier qui va suivre...
  if (l_amount < 0)
    d_new_amount -= 0.5;
  else
    d_new_amount += 0.5;

  return (t_amount)d_new_amount;
}


@implementation Currency

- (Currency*)init
{
  VoidHand pv_currency;
  struct s_currency *ps_currency;
  UInt16 index, uh_num_currencies;
  Boolean b_quit = false;

  // Petit hack pour savoir lorsque la base vient d'être créée. Voir
  // la méthode -DBjustCreated et un peu plus bas...
  self->uh_ref_id = 0;

  if ([self cacheAlloc:CURRENCY_NUM_CACHE_ENTRIES] == false)
  {
    // XXX
    return nil;
  }

  // DB opening/creating
  if ([self initDBType:MaTiCurrType nameSTR:MaTiCurrName] == nil)
  {
    // XXX
    return nil;
  }

  // Init the cache...
  [self cacheInit];

  // On extrait la devise de référence
  uh_num_currencies = 0;
  for (index = DmNumRecords(self->db); index-- > 0 && b_quit == false; )
  {
    pv_currency = DmQueryRecord(self->db, index);
    if (pv_currency != NULL)
    {
      ps_currency = MemHandleLock(pv_currency);

      b_quit = ps_currency->ui_reference;
      if (b_quit)
	self->uh_ref_id = ps_currency->ui_id;

      MemHandleUnlock(pv_currency);

      uh_num_currencies++;
    }
  }

  // Pas de devise de référence trouvée
  if (b_quit == false)
  {
    // Il faut la créer...
    Char ra_local[sizeof(struct s_currency) + CURRENCY_NAME_MAX_LEN];
    struct s_currency *ps_currency;
    UInt16 uh_id;

    // Pourtant il y a des devises présentes dans la base !!!
    if (uh_num_currencies > 0)
    {
      // XXX
    }

    ps_currency = (struct s_currency*)ra_local;

    MemSet(ps_currency, sizeof(struct s_currency), 0);

    SysCopyStringResource(ps_currency->ra_iso4217, strDefaultLocalCurrencyIso);
    SysCopyStringResource(ps_currency->ra_name,
			  [Application appli]->ul_rom_version >= 0x03503000
			  ? strDefaultLocalCurrency
			  : strDefaultLocalCurrencyBefore35);
    ps_currency->ui_reference = 1; // LA devise de référence
    ps_currency->d_reference_amount = 1.;
    ps_currency->d_currency_amount = 1.;

    [self save:ps_currency
	  size:sizeof(struct s_currency) + StrLen(ps_currency->ra_name) + 1
	  asId:&uh_id asNew:true];

    self->uh_ref_id = ps_currency->ui_id;
  }

  return self;
}


//
// Renvoie l'ID de la monnaie de référence
- (UInt16)referenceId
{
  return self->uh_ref_id;
}


- (void)getLastUpdateDates:(UInt32*)pui_last_upd_dates
{
  UInt16 uh_size;

  uh_size = EXTERNAL_CURRENCIES_NUM * sizeof(UInt32);

  if ([self appInfoBlockLoad:(void**)pui_last_upd_dates
	    size:&uh_size flags:INFOBLK_DIRECTZONE] != errNone)
    // Pas de block AppInfo
    MemSet(pui_last_upd_dates, EXTERNAL_CURRENCIES_NUM * sizeof(UInt32), '\0');
}


//
// Mise à jour des taux de change automatiquement
- (void)updateRates
{
  ExternalCurrencyGlobal *oExternalCurrencyGlobal;
  struct s_currency *ps_currency;
  struct s_currency s_save;
  struct s_external_currency_update s_update;
  UInt16 index;

  // On charge les dates de dernière modif des bases externes qui ont
  // servi à la dernière mise à jour (elle sont stockées dans le
  // AppInfoBlock) (B)
  [self getLastUpdateDates:s_update.rui_last_dates];
  MemMove(s_update.rui_new_dates, s_update.rui_last_dates,
	  sizeof(s_update.rui_new_dates));

  s_update.ui_now = TimGetSeconds();
  s_update.b_updated = false;

  oExternalCurrencyGlobal = [ExternalCurrencyGlobal new:&s_update];
  if (oExternalCurrencyGlobal == nil)
    return;

  // Notre devise de référence ne fait partie d'aucune base des
  // devises externes
  if ([oExternalCurrencyGlobal initReferenceFrom:self] == nil)
  {
    // Boîte d'alerte pour dire qu'on ne peut pas mettre à jour...
    FrmAlert(alertNoRefInExternalCurrencyDB);
    return;
  }

  // Pour chaque enregistrement de notre base des devises
  for (index = DmNumRecords(self->db); index-- > 0; )
  {
    ps_currency = [self getId:ITEM_SET_DIRECT(index)];
    if (ps_currency != NULL)
    {
      // Il ne s'agit pas de la devise de référence
      if (ps_currency->ui_reference == 0)
      {
	// Le code ISO-4217 est reconnu ET le taux est plus récent
	if ([oExternalCurrencyGlobal
	      withCurrencyISO4217:ps_currency->ra_iso4217
	      adjustCurrency:ps_currency
	      in:&s_save
	      update:&s_update])
	{
	  // On libère avant de sauver
	  [self getFree:ps_currency];

	  // On peut sauver, mais on ne sauve que la structure (pas les noms)
	  DmWrite([self recordGetAtId:index], 0, (Char*)&s_save,
		  sizeof(s_save) - CURRENCY_ISO4217_LEN);
	  [self recordRelease:true];

	  continue;
	}
      }

      [self getFree:ps_currency];
    }	
  }

  if (s_update.b_updated)
    // On met à jour notre AppInfoBlock avec la date de mise à jour la
    // plus récente qui a servi à cette mise à jour
    [self appInfoBlockSave:s_update.rui_new_dates
	  size:sizeof(s_update.rui_new_dates)];

  [oExternalCurrencyGlobal free];
}


- (UInt16)convertAmount:(t_amount*)pl_amount
		 fromId:(UInt16)uh_from_cur
		   toId:(UInt16)uh_to_cur
{
  struct s_currency *ps_from_cur, *ps_to_cur;

  ps_from_cur = [self getId:uh_from_cur];
  if (ps_from_cur == NULL)
    return 1;			// La première devise n'existe pas

  ps_to_cur = [self getId:uh_to_cur];
  if (ps_to_cur == NULL)
  {
    [self getFree:ps_from_cur];
    return 2;			// La seconde devise n'existe pas
  }

  *pl_amount = currency_convert_amount(*pl_amount, ps_from_cur, ps_to_cur);

  [self getFree:ps_to_cur];
  [self getFree:ps_from_cur];

  return 0;			// Tout s'est bien passé
}


////////////////////////////////////////////////////////////////////////
//
// Loading currencies : DBItemId do that for us
//
////////////////////////////////////////////////////////////////////////

//
// Function called after a -getId:
- (void)getFree:(void*)pv_item
{
  // We have to unlock the chunck
  if (pv_item != NULL)
    MemPtrUnlock(pv_item);
}


////////////////////////////////////////////////////////////////////////
//
// Saving currencies
//
////////////////////////////////////////////////////////////////////////

- (UInt16)getIdFrom:(void*)pv_currency
{
  return ((struct s_currency*)pv_currency)->ui_id;
}


- (void)setId:(UInt16)uh_new_id in:(void*)pv_currency
{
  ((struct s_currency*)pv_currency)->ui_id = uh_new_id;
}


- (Boolean)changeReferenceToId:(UInt16)uh_new_ref_id
{
  double d_new_ref_reference_amount, d_new_ref_currency_amount;
  double d_factor, d_last_value;
  struct s_currency s_save;

  struct s_currency *ps_currency;

  UInt16 index;

  // Si la devise de référence ne change pas, il n'y a rien à faire
  if (uh_new_ref_id == self->uh_ref_id)
    return true;

  // La nouvelle référence
  ps_currency = [self getId:uh_new_ref_id];
  if (ps_currency == NULL)
    return false;

  d_new_ref_reference_amount = ps_currency->d_reference_amount;
  d_new_ref_currency_amount = ps_currency->d_currency_amount;
  [self getFree:ps_currency];

  for (index = DmNumRecords(self->db); index-- > 0; )
  {
    ps_currency = [self getId:ITEM_SET_DIRECT(index)];
    if (ps_currency != NULL)
    {
      // id, reference et reserved sont tous dans un UInt32 en tête
      *(UInt32*)&s_save = *(UInt32*)ps_currency;

      // C'est la nouvelle devise
      if (ps_currency->ui_id == uh_new_ref_id)
      {
	s_save.ui_reference = 1;
	s_save.d_currency_amount = 1;
	s_save.d_reference_amount = 1;
      }
      // L'ancienne devise de référence : on inverse
      else if (ps_currency->ui_id == self->uh_ref_id)
      {
	s_save.ui_reference = 0;
	s_save.d_currency_amount = d_new_ref_reference_amount;
	s_save.d_reference_amount = d_new_ref_currency_amount;
      }
      // Une devise lambda
      else
      {
	d_factor = 1.;

	// La partie "devise" est un nombre entier
	if ((double)(UInt32)ps_currency->d_currency_amount
	    == ps_currency->d_currency_amount
	    // ET la partie référence n'en est pas un
	    && (double)(UInt32)ps_currency->d_reference_amount
	    != ps_currency->d_reference_amount)
	{
	  // Par exemple :
	  // 1 EUR	= 6.55957 FRF
	  // On va chercher à préserver la partie devise
	  for (;;)
	  {
	    d_last_value =
	      ((d_factor * d_new_ref_currency_amount
		* ps_currency->d_reference_amount)
	       /
	       (d_new_ref_reference_amount * ps_currency->d_currency_amount));

	    if (d_last_value >= 1. || d_factor == 1000000.)
	      break;

	    d_factor *= 10.;
	  }

	  s_save.d_currency_amount = d_factor;
	  s_save.d_reference_amount = d_last_value;
	}
	else
	{
	  // Par exemple :
	  //  2 DEM	= 1 EUR
	  //  1.5 GBP	= 1 EUR
	  //  5.3 XXX	= 2.5 EUR
	  // On va chercher à préserver la partie monnaie de référence
	  for (;;)
	  {
	    d_last_value =
	      ((d_factor * d_new_ref_reference_amount
		* ps_currency->d_currency_amount)
	       /
	       (d_new_ref_currency_amount * ps_currency->d_reference_amount));

	    if (d_last_value >= 1. || d_factor == 1000000.)
	      break;

	    d_factor *= 10.;
	  }

	  s_save.d_currency_amount = d_last_value;
	  s_save.d_reference_amount = d_factor;
	}
      }

      // On libère avant de sauver
      [self getFree:ps_currency];

      // On peut sauver, mais on ne sauve que la structure (pas les noms)
      DmWrite([self recordGetAtId:index], 0, (Char*)&s_save,
	      sizeof(s_save) - CURRENCY_ISO4217_LEN);
      [self recordRelease:true];
    }
  }

  // La nouvelle devise de référence...
  self->uh_ref_id = uh_new_ref_id;

  return true;
}


////////////////////////////////////////////////////////////////////////
//
// Deleting modes : DBItemId do that for us
//
////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////
//
// Popup management
//
////////////////////////////////////////////////////////////////////////

// Si pa_account == NULL => écran d'édition des devises
// Sinon => popup
// Si (*puh_num & ITEM_ADD_EDIT_LINE), ajoute une entrée "Éditer..."
- (Char**)listBuildInfos:(void*)pv_infos
		     num:(UInt16*)puh_num
		 largest:(UInt16*)puh_largest
{
  struct __s_list_currency_buf *ps_buf;
  UInt16 uh_index, uh_num, uh_num_records;
  UInt16 uh_width, uh_largest, *puh_list2index;

  VoidHand vh_currency;
  struct s_currency *ps_currency;

  uh_num_records = DmNumRecords(self->db);

  NEW_PTR(ps_buf, sizeof(*ps_buf) + uh_num_records * sizeof(UInt16),
	  return NULL);

  uh_largest = 0;
  uh_num = 0;
  puh_list2index = ps_buf->ruh_list2index;

  // Calcul de la plus grande largeur + cache entrées liste / index
  for (uh_index = 0; uh_index < uh_num_records; uh_index++)
  {
    vh_currency = DmQueryRecord(self->db, uh_index);
    if (vh_currency != NULL)
    {
      ps_currency = MemHandleLock(vh_currency);

      // On prend uniquement la largeur de la monnaie
      uh_width = FntCharsWidth(ps_currency->ra_name,
			       StrLen(ps_currency->ra_name));

      if (uh_width > uh_largest)
	uh_largest = uh_width;

      uh_num++;
      *puh_list2index++ = uh_index;

      MemHandleUnlock(vh_currency);
    }
  }

  ps_buf->oItem = self;
  ps_buf->uh_num_rec_entries = uh_num;
  ps_buf->uh_is_right_margin = 0;
  ps_buf->uh_only_in_account_view = (pv_infos == NULL);

  // Cas particulier : on ajoute l'entrée "Edit..."
  if (*puh_num & ITEM_ADD_EDIT_LINE)
  {
    load_and_fit(strEditList, ps_buf->ra_edit_entry, &uh_largest);
    uh_num++;
  }
  else if (uh_num == 0)
  {
    MemPtrFree(ps_buf);
    ps_buf = NULL;
  }

  *puh_num = uh_num;

  if (puh_largest)
    *puh_largest = uh_largest;

  if (ps_buf != NULL)
  {
    ps_buf->uh_largest_currency = uh_largest;
    ps_buf->a_dec_sep = float_dec_separator();
  }

  return (Char**)ps_buf;
}


static void __list_currencies_draw(Int16 h_line, RectangleType *prec_bounds,
				   Char **ppa_lines)
{
  struct __s_list_currency_buf *ps_buf;
  char *pa_currency;
  UInt16 uh_len;

  VoidHand vh_currency = NULL;
  struct s_currency *ps_currency = NULL;


  ps_buf = (struct __s_list_currency_buf*)ppa_lines;

  // L'entrée sélectionnée est une devise
  if (h_line < ps_buf->uh_num_rec_entries)
  {
    vh_currency = DmQueryRecord(ps_buf->oItem->db,
				ps_buf->ruh_list2index[h_line]);
    ps_currency = MemHandleLock(vh_currency);

    pa_currency = ps_currency->ra_name;
  }
  // "Edit..." entry
  else
    pa_currency = ps_buf->ra_edit_entry;

  uh_len = StrLen(pa_currency);

  WinDrawChars(pa_currency, uh_len,
	       prec_bounds->topLeft.x, prec_bounds->topLeft.y);

  // Séparateur au dessus de "Éditer..."
  if (h_line == ps_buf->uh_num_rec_entries)
    list_line_draw_line(prec_bounds, 1);

  // Écran d'édition des devises
  if (ps_buf->uh_only_in_account_view)
  {
    UInt16 uh_right_margin, uh_x, uh_equal_width, uh_num_width;
    Int16 h_width;
    Char ra_num[DOUBLE_STR_SIZE];

    // Does this list contain scroll arrows?
    uh_right_margin = ps_buf->uh_is_right_margin
      ? LIST_RIGHT_MARGIN : LIST_RIGHT_MARGIN_NOSCROLL;

    uh_equal_width = FntCharWidth('=');

    uh_num_width = (prec_bounds->extent.x - uh_right_margin
		    - ps_buf->uh_largest_currency
		    - uh_equal_width
		    - MINIMAL_SPACE * 3) >> 1;

    // Partie devise
    StrDoubleToA(ra_num, ps_currency->d_currency_amount, &uh_len,
		 ps_buf->a_dec_sep, 9);	// 9 chiffres après la virgule au max

    uh_x = (prec_bounds->topLeft.x + ps_buf->uh_largest_currency
	    + MINIMAL_SPACE + uh_num_width);

    h_width = prepare_truncating(ra_num, &uh_len, uh_num_width);
    WinDrawTruncatedChars
      (ra_num, uh_len,
       uh_x - (h_width < 0 ? FntCharsWidth(ra_num, uh_len) : h_width),
       prec_bounds->topLeft.y, h_width);

    // La séparation entre les deux nombres
    uh_x += MINIMAL_SPACE;
    WinDrawChars("=", 1, uh_x, prec_bounds->topLeft.y);

    // Partie devise de référence
    StrDoubleToA(ra_num, ps_currency->d_reference_amount, &uh_len,
		 ps_buf->a_dec_sep, 9);	// 9 chiffres après la virgule au max

    uh_x += uh_equal_width + MINIMAL_SPACE + uh_num_width;

     h_width = prepare_truncating(ra_num, &uh_len, uh_num_width);
    WinDrawTruncatedChars
      (ra_num, uh_len,
       uh_x - (h_width < 0 ? FntCharsWidth(ra_num, uh_len) : h_width),
       prec_bounds->topLeft.y, h_width);
  }

  if (vh_currency != NULL)
    MemHandleUnlock(vh_currency);
}


- (ListDrawDataFuncPtr)listDrawFunction
{
  return __list_currencies_draw;
}


- (UInt16)dbMaxEntries
{
  return NUM_CURRENCIES;
}


////////////////////////////////////////////////////////////////////////
//
// Mode popup list
//
////////////////////////////////////////////////////////////////////////

- (UInt16)_popupListUnknownItem
{
  // Pas d'item "Unknown" ici, mais on renvoie la devise de
  // référence. Cela permet de retomber sur nos pattes lorsqu'une
  // devise inexistante est donnée aux méthodes -_popup*
  return self->uh_ref_id;
}


- (UInt16*)_popupListGetList2IndexFrom:(struct __s_list_dbitem_buf*)ps_buf
{
  return ((struct __s_list_currency_buf*)ps_buf)->ruh_list2index;
}


- (Char*)fullNameOfId:(UInt16)uh_id len:(UInt16*)puh_len
{
  struct s_currency *ps_currency;
  Char *pa_name;
  UInt16 uh_len = 1;		// Avec \0

  ps_currency = [self getId:uh_id];
  if (ps_currency == NULL)
  {
    pa_name = NULL;
    goto end;
  }

  uh_len += StrLen(ps_currency->ra_name);

  NEW_PTR(pa_name, uh_len, goto end);

  MemMove(pa_name, ps_currency->ra_name, uh_len);

  [self getFree:ps_currency];

 end:
  if (puh_len != NULL)
    *puh_len = uh_len - 1;	// Sans \0

  return pa_name;
}

@end
