/* 
 * EditCurrencyForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sat May 22 22:24:38 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb  1 17:12:20 2008
 * Update Count    : 64
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: EditCurrencyForm.m,v $
 * Revision 1.9  2008/02/01 17:13:49  max
 * Avoid old mcc hack...
 *
 * Revision 1.8  2008/01/14 17:04:21  max
 * Switch to new mcc.
 * External currencies handling reworked.
 * LstSetSelection: s/noListSelection/0/g.
 *
 * Revision 1.7  2006/11/04 23:48:03  max
 * External currencies are now handled by ExternalCurrency class.
 *
 * Revision 1.6  2006/06/23 13:24:43  max
 * Now call -focusObject: instead of FrmSetFocus() to set focus to a field.
 *
 * Revision 1.5  2006/04/25 08:46:15  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.4  2005/08/20 13:06:51  max
 * Updates are now genericaly managed by MaTiForm.
 *
 * Revision 1.3  2005/03/02 19:02:36  max
 * Swap buttons in alertCurrencyDelete.
 *
 * Revision 1.2  2005/02/13 00:06:17  max
 * Change prototype of -keyFilter:for:
 * It allows to detect and not block special keys in numeric fields.
 * Now the Select key of the 5-way works everywhere...
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_EDITCURRENCYFORM
#include "EditCurrencyForm.h"

#include "MaTirelire.h"
#include "CurrenciesListForm.h"
#include "ExternalCurrencyGlobal.h"

#include "float.h"
#include "graph_defs.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX
#include "ids.h"


static void __iso4217_list_name(Char *pa_buf, UInt16 uh_code);
static UInt16 __iso4217_list_prepare(UInt16 **ppuh_iso4217, UInt16 uh_nb,
				     UInt16 uh_key);
static void __iso4217_list_draw(Int16 h_line, RectangleType *prec_bounds,
				Char **ppa_lines);


@implementation EditCurrencyForm

- (Boolean)extractAndSave:(UInt16)uh_update_code
{
  Currency *oCurrency = [oMaTirelire currency];
  struct s_currency *ps_new_currency;
  UInt16 uh_size;
  Boolean b_ret = false;

  uh_size = sizeof(struct s_currency) + 1 // + 1 for \0 of ra_name
    + FldGetTextLength([self objectPtrId:EditCurrencyName]);

  NEW_PTR(ps_new_currency, uh_size, return false);

  MemSet(ps_new_currency, sizeof(struct s_currency), '\0');

  // Currency name
  if ([self checkField:EditCurrencyName flags:FLD_CHECK_VOID
	    resultIn:ps_new_currency->ra_name
	    fieldName:strEditCurrencyName] == false)
    goto end;

  // Code ISO-4217
  [self checkField:EditCurrencyIso4217 flags:FLD_CHECK_NONE
	resultIn:ps_new_currency->ra_iso4217
	fieldName:FLD_NO_NAME];

  // Currency ID (si création il sera écrasé)
  ps_new_currency->ui_id = self->uh_currency_id;

  // On édite une devise qui n'est pas la devise de référence
  if (FrmGetActiveFormID() == EditCurrencyFormIdx)
  {
    // Amount in currency
    if ([self checkField:EditCurrencyAmount
	      flags:FLD_CHECK_NULL|FLD_CHECK_VOID|FLD_TYPE_DOUBLE
	      resultIn:&ps_new_currency->d_currency_amount
	      fieldName:strEditCurrencyAmount] == false)
      goto end;

    // Amount in reference currency
    if ([self checkField:EditCurrencyRefAmount
	      flags:FLD_CHECK_NULL|FLD_CHECK_VOID|FLD_TYPE_DOUBLE
	      resultIn:&ps_new_currency->d_reference_amount
	      fieldName:strEditCurrencyRefAmount] == false)
      goto end;
  }
  // On édite la devise de référence
  else
  {
    struct s_currency *ps_ref_currency;

    ps_ref_currency = [oCurrency getId:[oCurrency referenceId]];

    ps_new_currency->ui_reference = 1;
    ps_new_currency->d_currency_amount = ps_ref_currency->d_currency_amount;
    ps_new_currency->d_reference_amount = ps_ref_currency->d_reference_amount;

    [oCurrency getFree:ps_ref_currency];
  }

  // Sauvegarde seulement si le contenu change...
  if (1)
  {
    UInt16 uh_index_pos;

    if (self->uh_currency_id != (UInt16)-1)
    {
      uh_index_pos = [oCurrency getCachedIndexFromID:self->uh_currency_id];

      // Il s'agit d'une création par copie => on se met juste après l'original
      if (uh_update_code & frmMaTiUpdateEdit2ListNewItem)
      {
	uh_update_code |= frmMaTiUpdateEdit2ListNewItemAfter;
	uh_index_pos++;
      }
    }
    // Création pure...
    else
      uh_index_pos = dmMaxRecordIndex;

    if ([oCurrency save:ps_new_currency size:uh_size
		   asId:&uh_index_pos
		   asNew:(uh_update_code & frmMaTiUpdateEdit2ListNewItem) != 0]
	== false)
      goto end;

    // On update Papa car ça a changé...
    self->ui_update_mati_list |= uh_update_code;
  }

  // On peut retourner chez Papa car tout s'est bien passé...
  [self returnToLastForm];

  b_ret = true;

 end:
  MemPtrFree(ps_new_currency);

  return b_ret;
}


- (Boolean)open
{
  struct s_currency *ps_currency;
  Currency *oCurrency = [oMaTirelire currency];
  UInt16 uh_index;

  // Default value...
  self->uh_currency_id = -1;

  uh_index = [(CurrenciesListForm*)self->oPrevForm editedEntryIndex];

  // New
  if (uh_index == dmMaxRecordIndex)
  {
    [self hideId:EditCurrencyDelete];
    [self hideId:EditCurrencyNew];
  }
  // Edit
  else
  {
    ps_currency = [oCurrency getId:ITEM_SET_DIRECT(uh_index)];
    if (ps_currency != NULL)
    {
      self->uh_currency_id = ps_currency->ui_id;

      // Currency name
      [self replaceField:EditCurrencyName withSTR:ps_currency->ra_name len:-1];

      // ISO-4217
      [self replaceField:EditCurrencyIso4217
	    withSTR:ps_currency->ra_iso4217 len:-1];

      // On édite une devise qui n'est pas celle de référence
      if (FrmGetActiveFormID() == EditCurrencyFormIdx)
      {
	// Currency amount
	[self replaceField:REPLACE_FIELD_EXT | EditCurrencyAmount
	      withSTR:(Char*)&ps_currency->d_currency_amount
	      len:REPL_FIELD_DOUBLE];

	// Reference currency amount
	[self replaceField:REPLACE_FIELD_EXT | EditCurrencyRefAmount
	      withSTR:(Char*)&ps_currency->d_reference_amount
	      len:REPL_FIELD_DOUBLE];
      }

      [oCurrency getFree:ps_currency];
    }
  }

  // On édite une devise qui n'est pas celle de référence
  if (FrmGetActiveFormID() == EditCurrencyFormIdx)
  {
    // Reference currency name
    ps_currency = [oCurrency getId:[oCurrency referenceId]];
    FrmCopyLabel(self->pt_frm, EditCurrencyReference, ps_currency->ra_name);
    [oCurrency getFree:ps_currency];
  }

  [super open];

  [self focusObject:EditCurrencyName];

  return true;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case EditCurrencyDelete:
    if (self->uh_currency_id != (UInt16)-1)
    {
      Currency *oCurrency;
      UInt32 ui_dbases_trans;

      // On vérifie que la devise à supprimer n'est pas la devise
      // principale d'un compte quelle que soit sa base
      ui_dbases_trans
	= do_on_each_transaction(Transaction->_numAccountCurrency_,
				 self->uh_currency_id);

      // Un compte avec cette devise existe
      if (ui_dbases_trans > 0)
      {
	Char ra_found_dbases[5 + 1], ra_found_accounts[5 + 1];

	StrIToA(ra_found_accounts, ui_dbases_trans & 0xffff);
	StrIToA(ra_found_dbases, ui_dbases_trans >> 16);

	FrmCustomAlert(alertAccountMainCurrency,
		       ra_found_accounts, ra_found_dbases, " ");
	break;
      }

      // Boîte de confirmation de suppression
      if (FrmAlert(alertCurrencyDelete) != 0)
      {
	oCurrency = [oMaTirelire currency];

	// Suppression effective
	if ([oCurrency deleteId:self->uh_currency_id] >= 0)
	{
	  // On répercute sur les opérations
	  ui_dbases_trans
	    = do_on_each_transaction(Transaction->_removeCurrency_,
				     self->uh_currency_id);
	  if (ui_dbases_trans > 0)
	  {
	    Char ra_dbases[5 + 1], ra_trans[5 + 1];

	    StrIToA(ra_trans, ui_dbases_trans & 0xffff);
	    StrIToA(ra_dbases, ui_dbases_trans >> 16);

	    FrmCustomAlert(alertCurrDelRecordsModified,
			   ra_trans, ra_dbases, " ");
	  }

	  // On envoie un update au formulaire précédent
	  self->ui_update_mati_list |= (frmMaTiUpdateEdit2List
					| frmMaTiUpdateEdit2ListDeletedItem);

	  // Puis retour...
	  [self returnToLastForm];
	}
      }
    }
    break;

  case EditCurrencyNew:
    if ([(CurrenciesListForm*)self->oPrevForm isChildNewButton])
      // Sauvegarde
      [self extractAndSave:(frmMaTiUpdateEdit2List
			    | frmMaTiUpdateEdit2ListNewItem)];
    break;

  case EditCurrencyOK:
    // Sauvegarde
    // (pas besoin de true si création car self->uh_currency_id == -1)
    [self extractAndSave:self->uh_currency_id == (UInt16)-1
	  ? frmMaTiUpdateEdit2List | frmMaTiUpdateEdit2ListNewItem
	  : frmMaTiUpdateEdit2List];
    break;

  case EditCurrencyCancel:
    [self returnToLastForm];
    break;

    // Popup des monnaies externes
  case EditCurrencyExternalPopup:
  {
    ExternalCurrencyGlobal *oExternalCurrencyGlobal;
    UInt16 uh_num, uh_largest;

    oExternalCurrencyGlobal = [ExternalCurrencyGlobal new:NULL];
    if (oExternalCurrencyGlobal == nil)
    {
      FrmAlert(alertNoExternalCurrencyDB);
      break;
    }

    // Notre devise de référence ne fait partie d'aucune base des
    // devises externes
    if ([oExternalCurrencyGlobal initReferenceFrom:[oMaTirelire currency]]
	== nil)
    {
      // Le free est déjà fait...
      FrmAlert(alertNoRefInExternalCurrencyDB);
      break;
    }

    uh_num = [oExternalCurrencyGlobal buildListLargestISO4217:&uh_largest];

    // Pas d'enregistrement dans la base externe (bizarre mais bon...)
    if (uh_num > 0)
    {
      ListType *pt_list;
      RectangleType s_list_rect;
      UInt16 index, uh_list_idx;

      uh_largest += LIST_MARGINS_NO_SCROLL;

      uh_list_idx = FrmGetObjectIndex(self->pt_frm, EditCurrencyExternalList);
      pt_list = FrmGetObjectPtr(self->pt_frm, uh_list_idx);

      LstSetDrawFunction(pt_list, external_currency_iso_list_draw);
      LstSetHeight(pt_list, uh_num); // Modifie la hauteur de la liste
      LstSetListChoices(pt_list, (Char**)oExternalCurrencyGlobal, uh_num);
      LstSetSelection(pt_list, 0); // Sélection de la 1ère entrée

      // Gestion de l'espace pris par la flèche de scroll
      if (LstGetVisibleItems(pt_list) != uh_num)
	uh_largest += LIST_MARGINS_WITH_SCROLL - LIST_MARGINS_NO_SCROLL;

      FrmGetObjectBounds(self->pt_frm, uh_list_idx, &s_list_rect);
      s_list_rect.extent.x = uh_largest;
      FrmSetObjectBounds(self->pt_frm, uh_list_idx, &s_list_rect);

      // Affichage de la liste
      index = LstPopupList(pt_list);
      if (index != noListSelection)
      {
	struct s_currency s_tmp_currency;
	Char ra_iso4217[CURRENCY_ISO4217_LEN];
	UInt16 uh_len;

	// Le taux de conversion (initialisé à 1 si champ vide)
	s_tmp_currency.d_currency_amount =
	  s_tmp_currency.d_reference_amount = 1.;

	// Form amount in currency
	[self checkField:EditCurrencyAmount
	      flags:(FLD_CHECK_NULL|FLD_CHECK_VOID|FLD_TYPE_DOUBLE
		     |FLD_CHECK_NOALERT)
	      resultIn:&s_tmp_currency.d_currency_amount
	      fieldName:strEditCurrencyAmount];

	// Form amount in reference currency
	[self checkField:EditCurrencyRefAmount
	      flags:(FLD_CHECK_NULL|FLD_CHECK_VOID|FLD_TYPE_DOUBLE
		     |FLD_CHECK_NOALERT)
	      resultIn:&s_tmp_currency.d_reference_amount
	      fieldName:strEditCurrencyRefAmount];

	// On récupère la devise qui vient d'être sélectionnée
	[oExternalCurrencyGlobal withCurrencyListIndex:index
				 adjustCurrency:&s_tmp_currency
				 andPutNameIn:ra_iso4217];

	// Copy currency amount back to form
	[self replaceField:REPLACE_FIELD_EXT | EditCurrencyAmount
	      withSTR:(Char*)&s_tmp_currency.d_currency_amount
	      len:REPL_FIELD_DOUBLE];

	// Copy reference currency amount back to form
	[self replaceField:REPLACE_FIELD_EXT | EditCurrencyRefAmount
	      withSTR:(Char*)&s_tmp_currency.d_reference_amount
	      len:REPL_FIELD_DOUBLE];

	// Le nom de la devise
	uh_len = StrLen(ra_iso4217);
	[self replaceField:EditCurrencyName withSTR:ra_iso4217 len:uh_len];
	[self replaceField:EditCurrencyIso4217 withSTR:ra_iso4217 len:uh_len];
      }
    }

    [oExternalCurrencyGlobal free];
  }
  break;

  default:
    return false;
  }

  return true;
}


- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key
{
  UInt16 fld_id;

  // On laisse la main à Papa pour gérer les déplacements entre champs...
  if ([super keyDown:ps_key])
    return true;

  fld_id = FrmGetFocus(self->pt_frm);

  if (fld_id != noFocus)
    switch (FrmGetObjectId(self->pt_frm, fld_id))
    {
    case EditCurrencyAmount:
    case EditCurrencyRefAmount:
      return [self keyFilter:KEY_FILTER_DOUBLE | fld_id for:ps_key];

      // Dans le champ du code ISO-4217 de la monnaie, on n'accepte
      // que les lettres non accentuées. Si elles sont saisies en
      // minuscules, on les passe en majuscules.
    case EditCurrencyIso4217:
      // A special key OR a control char
      if ((ps_key->modifiers & virtualKeyMask) || ps_key->chr < ' ')
	return false;

      // On passe en majuscules...
      if (ps_key->chr >= 'a' && ps_key->chr <= 'z')
	ps_key->chr -= 'a' - 'A';
      // Not an alphabetic char : skip it
      else if (ps_key->chr < 'A' || ps_key->chr > 'Z')
	return true;		// Skip it

      {
	FieldType *pt_field = FrmGetObjectPtr(self->pt_frm, fld_id);
	ListType *pt_list;
	Char *pa_contents = FldGetTextPtr(pt_field);
	UInt16 uh_list_idx;

	// Ça va être notre premier caractère => on sort le popup
	if (pa_contents == NULL || *pa_contents == '\0')
	{
	  MemHandle pv_iso4217;
	  UInt16    *puh_iso4217, uh_largest, uh_num;
	  Boolean   b_ret = false;

	  pv_iso4217 = DmGetResource('wrdl', wlstIso4217);
	  puh_iso4217 = MemHandleLock(pv_iso4217);

	  // Le nombre de devises (total - largeurs maxi)
	  uh_num = *puh_iso4217++ - 26;

	  // La + gde largeur est stockée ici
	  uh_largest = puh_iso4217[ps_key->chr - 'A'] + LIST_MARGINS_NO_SCROLL;

	  puh_iso4217 += 26;	// On saute la table des largeurs maxi

	  // Configuration de la liste
	  uh_num = __iso4217_list_prepare(&puh_iso4217, uh_num, ps_key->chr);

	  uh_list_idx = FrmGetObjectIndex(self->pt_frm,
					  EditCurrencyIso4217List);
	  pt_list = FrmGetObjectPtr(self->pt_frm, uh_list_idx);

	  LstSetDrawFunction(pt_list, __iso4217_list_draw);
	  LstSetHeight(pt_list, uh_num); // Modifie la hauteur de la liste
	  LstSetListChoices(pt_list, (Char**)puh_iso4217, uh_num);
	  LstSetSelection(pt_list, 0); // Sélection de la 1ère entrée

	  // Gestion de l'espace pris par la flèche de scroll
	  if (LstGetVisibleItems(pt_list) != uh_num)
	    uh_largest += LIST_MARGINS_WITH_SCROLL - LIST_MARGINS_NO_SCROLL;

	  // On va dérouler la liste pile poil sur le champ éditable
	  {
	    RectangleType s_fld_rect, s_list_rect;

	    FrmGetObjectBounds
	      (self->pt_frm,
	       FrmGetObjectIndex(self->pt_frm, EditCurrencyIso4217),
	       &s_fld_rect);
	    FrmGetObjectBounds(self->pt_frm, uh_list_idx, &s_list_rect);

	    s_list_rect.topLeft.x = s_fld_rect.topLeft.x;
	    s_list_rect.topLeft.y = s_fld_rect.topLeft.y;
	    s_list_rect.extent.x = uh_largest;
	    FrmSetObjectBounds(self->pt_frm, uh_list_idx, &s_list_rect);
	  }

	  uh_num = LstPopupList(pt_list);
	  if (uh_num != noListSelection)
	  {
	    Char ra_name[3];

	    // OK on a la devise
	    __iso4217_list_name(ra_name, puh_iso4217[uh_num]);

	    [self replaceField:EditCurrencyIso4217 withSTR:ra_name len:3];

	    // On doit renvoyer true
	    b_ret = true;
	  }

	  MemHandleUnlock(pv_iso4217);
	  DmReleaseResource(pv_iso4217);

	  return b_ret;
	}
      }
      break;			// Else, let the character pass to the system
    }

  return false;
}

@end


// pa_buf est un pointeur sur un buffer de 3 octets
static void __iso4217_list_name(Char *pa_buf, UInt16 uh_code)
{
  pa_buf[0] = 'A' + (uh_code >> 10);
  pa_buf[1] = 'A' + ((uh_code >> 5) & 0x1f);
  pa_buf[2] = 'A' + (uh_code & 0x1f);
}


// Renvoie le nombre d'éléments qu'il va y avoir dans la liste en
// fonction de la première lettre tapée
static UInt16 __iso4217_list_prepare(UInt16 **ppuh_iso4217, UInt16 uh_nb,
				     UInt16 uh_key)
{
  UInt16 uh_start, uh_end;
  UInt16 *puh_iso4217 = *ppuh_iso4217;

  uh_key -= 'A';

  // On recherche le début
  for (uh_start = 0; uh_start < uh_nb; uh_start++, puh_iso4217++)
    if ((*puh_iso4217 >> 10) == uh_key)
    {
      *ppuh_iso4217 = puh_iso4217;

      // On recherche la fin
      for (uh_end = uh_start + 1; uh_end < uh_nb; uh_end++)
      {
	if ((*++puh_iso4217 >> 10) != uh_key)
	  break;
      }

      return uh_end - uh_start;
    }

  // On n'a pas trouvé de devise correspondante...
  return 0;
}


static void __iso4217_list_draw(Int16 h_line, RectangleType *prec_bounds,
				Char **ppa_lines)
{
  Char ra_iso4217[3];

  __iso4217_list_name(ra_iso4217, ((UInt16*)ppa_lines)[h_line]);

  WinDrawChars(ra_iso4217, 3, prec_bounds->topLeft.x, prec_bounds->topLeft.y);
}
