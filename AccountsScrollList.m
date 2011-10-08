/* 
 * AccountsScrollList.m -- 
 * 
 * Author          : Maxime Soulé
 * Created On      : Wed Jul  7 17:54:14 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jul  6 14:40:18 2007
 * Update Count    : 8
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: AccountsScrollList.m,v $
 * Revision 1.11  2008/01/14 17:27:37  max
 * Switch to new mcc.
 * Always select first long clic popup entry.
 *
 * Revision 1.10  2006/11/04 23:47:53  max
 * Minor fix.
 *
 * Revision 1.9  2006/06/28 09:41:41  max
 * s/pt_frm/oForm/g attribute.
 *
 * Revision 1.8  2006/04/25 08:46:14  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.7  2005/10/16 21:44:00  max
 * Correct sum bug introduced in the last beta.
 *
 * Revision 1.6  2005/10/11 19:11:51  max
 * Optimize sum computation.
 * Use generic SumScrollList -shortClic* methods.
 *
 * Revision 1.5  2005/08/20 13:06:41  max
 * Prepare switching to 64 bits amounts.
 * Currencies popup is now managed by SumListForm.
 * Select correctly the item line during the display of the popup when
 * called from the keyboard.
 *
 * Revision 1.4  2005/05/08 12:12:49  max
 * struct s_account reworked to allows generic name sorting.
 *
 * Revision 1.3  2005/03/02 19:02:33  max
 * Add progress bars for slow operations.
 *
 * Revision 1.2  2005/02/19 17:11:51  max
 * Next account procedure reworked.
 *
 * Revision 1.1  2005/02/09 22:57:21  max
 * First import.
 *
 * ==================== RCS ==================== */

#include <PalmOSGlue/TblGlue.h>

#define EXTERN_ACCOUNTSSCROLLLIST
#include "AccountsScrollList.h"

#include "BaseForm.h"
#include "MaTirelire.h"

#include "ProgressBar.h"

#include "AccountsListForm.h"

#include "float.h"
#include "misc.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


struct s_account
{
  Char ra_name[dmCategoryLength]; // Nom du compte (laisser en tête pour Sort)
  t_amount l_sum;		// Somme totale (affichée) du compte
  t_amount l_account_sum;	// Somme totale dans la monnaie du compte
  UInt16 uh_num_op;		// Nombre d'opérations dans le compte
  UInt16 uh_cat_id:4;		// ID de la catégorie correspondant à ce compte
  UInt16 uh_selected:1;		// Cette somme est sélectionnée
  UInt16 uh_unused:3;
  UInt16 uh_currency:8;		// ID de la monnaie du compte
};


static void __trans_draw_account(void *pv_table, Int16 h_row, Int16 h_col,
				 RectangleType *prec_bounds)
{
  AccountsScrollList *oAccountsScrollList = ScrollListGetPtr(pv_table);
  struct s_account_prop *ps_prop;
  struct s_account *ps_account;
  struct s_misc_infos *ps_infos;
  Char ra_buf[1 + 10 + 1 + 1];	// -99999999,99\0
  UInt16 uh_len;
  Int16 h_width;
  FontID uh_save_font;
  Boolean b_colored = false;

  ps_account = MemHandleLock(oAccountsScrollList->vh_accounts);
  ps_account += TblGetRowID((TableType*)pv_table, h_row);

  // Propriétés du compte
  ps_prop = [oMaTirelire->oTransactions
			accountProperties:ps_account->uh_cat_id
			index:NULL];

  // Si on a la couleur...
  if (oMaTirelire->uh_color_enabled)
  {
    struct s_mati_prefs *ps_prefs = &oMaTirelire->s_prefs;
    IndexedColorType a_color;

    WinPushDrawState();

    WinSetBackColor(UIColorGetTableEntryIndex(UIFieldBackground));
    a_color = UIColorGetTableEntryIndex(UIObjectForeground);

    // Compte pas à découvert
    if (ps_account->l_sum >= ps_prop->l_non_overdraft_thresold)
    {
      if (ps_prefs->uh_list_flags & USER_CREDIT_COLOR)
	a_color = ps_prefs->ra_colors[COLOR_CREDIT];
    }
    // Compte à découvert
    else if (ps_account->l_sum <= ps_prop->l_overdraft_thresold)
    {
      if (ps_prefs->uh_list_flags & USER_DEBIT_COLOR)
	a_color = ps_prefs->ra_colors[COLOR_DEBIT];
    }

    WinSetTextColor(a_color);

    b_colored = true;
  }

  uh_save_font = FntSetFont(oMaTirelire->s_fonts.uh_list_font);

  ps_infos = &oMaTirelire->s_misc_infos;

  // Le nom du compte
  uh_len = StrLen(ps_account->ra_name);
  h_width = prepare_truncating(ps_account->ra_name, &uh_len,
			       prec_bounds->extent.x
			       - ps_infos->uh_max_amount_width);
  WinDrawTruncatedChars(ps_account->ra_name, uh_len,
			prec_bounds->topLeft.x, prec_bounds->topLeft.y,
			h_width);

  // La somme des opérations du compte
  Str100FToA(ra_buf, ps_account->l_sum, &uh_len, ps_infos->a_dec_separator);
  WinDrawChars(ra_buf, uh_len,
	       prec_bounds->topLeft.x + prec_bounds->extent.x
	       - FntCharsWidth(ra_buf, uh_len),
	       prec_bounds->topLeft.y);

  // Somme sélectionnée
  if (ps_account->uh_selected)
  {
    RectangleType s_rect;

    s_rect = *prec_bounds;
    s_rect.topLeft.x += s_rect.extent.x - ps_infos->uh_max_amount_width;
    s_rect.extent.x = ps_infos->uh_max_amount_width;

    if (b_colored)
      WinInvertRectangleColor(&s_rect);
    else
      WinInvertRectangle(&s_rect, 0);
  }

  MemPtrUnlock(ps_prop);

  MemHandleUnlock(oAccountsScrollList->vh_accounts);

  if (b_colored)
    WinPopDrawState();
  else
    FntSetFont(uh_save_font);
}


@implementation AccountsScrollList

- (AccountsScrollList*)free
{
  if (self->vh_accounts != NULL)
    MemHandleFree(self->vh_accounts);

  return [super free];
}


// Méthode à appeler lorsque le nombre d'entrées dans la liste a changé
//
// Contruit un tableau contenant tous les comptes.
// Pour chaque compte :
// - initialisation uh_cat_id
// - initialisation ra_name
// + cache self->rua_id2account
- (void)initRecordsCount
{
  DmOpenRef db = [[oMaTirelire transaction] db];
  struct s_account *ps_accounts, *ps_cur;
  UInt16 index, uh_nb;

  if (self->vh_accounts != NULL)
    MemHandleFree(self->vh_accounts);

  NEW_HANDLE(self->vh_accounts, MAX_ACCOUNTS * sizeof(struct s_account),
	     ({ self->uh_num_items = 0; return; }));

  ps_accounts = ps_cur = MemHandleLock(self->vh_accounts);
  MemSet(ps_accounts, MAX_ACCOUNTS * sizeof(struct s_account), '\0');
  uh_nb = 0;

  for (index = 0; index < MAX_ACCOUNTS; index++)
  {
    CategoryGetName(db, index, ps_cur->ra_name);
    if (ps_cur->ra_name[0] != '\0')
    {
      ps_cur->uh_cat_id = index;

      ps_cur++;
      uh_nb++;
    }
  }

  // Sort the list alphabeticaly
  SysInsertionSort(ps_accounts, uh_nb, sizeof(*ps_accounts),
		   (CmpFuncPtr)sort_string_compare, 0);

  // Tableau de correspondance entre les catégories et les items de la liste
  MemSet(self->rua_id2account, sizeof(self->rua_id2account), '\0');
  for (index = 0; index < uh_nb; index++)
    self->rua_id2account[ps_accounts[index].uh_cat_id] = index;

  MemHandleUnlock(self->vh_accounts);

  // Aucun compte, on libère tout...
  if (uh_nb == 0)
  {
    MemHandleFree(self->vh_accounts);
    self->vh_accounts = NULL;
  }
  // On a réservé trop de place, on en redonne
  else if (uh_nb < MAX_ACCOUNTS)
    MemHandleResize(self->vh_accounts, uh_nb * sizeof(struct s_account));

  self->uh_num_items = uh_nb;

  // On passe à papa qui va calculer les sommes de chaque compte
  [super initRecordsCount];
}


//
// Pour chaque compte :
// - initialisation l_account_sum
// - initialisation uh_currency
// - initialisation uh_num_op
// - initialisation uh_selected
- (void)computeEachEntrySum
{
  Transaction *oTransactions;
  DmOpenRef db;
  struct s_db_prefs *ps_db_prefs;
  MemHandle pv_item;
  const struct s_transaction *ps_tr;
  struct s_account *ps_accounts, *ps_cur;
  void *pv_sum;
  PROGRESSBAR_DECL;
  UInt16 index, uh_attr, uh_date, uh_num_records;

  if (self->vh_accounts == NULL)
    return;

  ps_accounts = MemHandleLock(self->vh_accounts);

  // On initialise la somme dans la monnaie du compte et le nombre
  // d'opérations du compte, car ces deux là vont être incrémentés
  // plus bas
  ps_cur = ps_accounts;
  for (index = self->uh_num_items; index-- > 0; ps_cur++)
  {
    ps_cur->l_account_sum = 0;
    ps_cur->uh_num_op = 0;
    ps_cur->uh_selected = 0;
  }

  oTransactions = [oMaTirelire transaction];

  db = [oTransactions db];
  ps_db_prefs = oTransactions->ps_prefs;

  switch (ps_db_prefs->ul_sum_type)
  {
  case VIEW_TODAY:
  case VIEW_DATE:
  case VIEW_TODAY_PLUS:
    pv_sum = &&date;
    break;
  case VIEW_WORST:		// Marche pour les prop. compte car tjs pointé
    pv_sum = &&worst;
    break;
  case VIEW_CHECKED:
    pv_sum = &&checked;
    break;
  case VIEW_MARKED:
    pv_sum = &&marked;
    break;
  case VIEW_CHECKNMARKED:
    pv_sum = &&checknmarked;
    break;
  default:		// VIEW_ALL
    pv_sum = &&add;
    break;
  }


  uh_date = [oTransactions sumDate:-1];	// -1 == prend le type des préférences

  index = uh_num_records = DmNumRecords(db);

  PROGRESSBAR_BEGIN(uh_num_records, strProgressBarAccountsBalances);
  uh_num_records--;

  // Pour chaque opération
  while (index-- > 0)
  {
    pv_item = DmQueryRecord(db, index);	// PG
    if (pv_item != NULL)
    {
      ps_tr = MemHandleLock(pv_item);

      DmRecordInfo(db, index, &uh_attr, NULL, NULL);
      uh_attr &= dmRecAttrCategoryMask;
      ps_cur = &ps_accounts[self->rua_id2account[uh_attr]];

      // Un compte
      if (DateToInt(ps_tr->s_date) == 0)
      {
	// On ajoute toujours le solde initial à la somme globale sauf
	// pour les marqués où il faut que "l'opération" le soit
	if (ps_db_prefs->ul_sum_type != VIEW_MARKED
	    || ((struct s_account_prop*)ps_tr)->ui_acc_marked)
	  ps_cur->l_account_sum += ps_tr->l_amount;

	// On garde l'ID de la devise du compte
	ps_cur->uh_currency = ((struct s_account_prop*)ps_tr)->ui_acc_currency;

	// Sélectionné ?
	if (ps_db_prefs->uh_selected_accounts & (1 << uh_attr))
	  ps_cur->uh_selected = 1;
      }
      // Une opération
      else
      {
	ps_cur->uh_num_op++;

	goto *pv_sum;

    date:
	if (uh_date >= (ps_tr->ui_rec_value_date
			? DateToInt(value_date_extract(ps_tr))
			: DateToInt(ps_tr->s_date)))
	  goto add;
	goto next;

    worst:
	if (ps_tr->ui_rec_checked || ps_tr->l_amount < 0)
	  goto add;
	goto next;

    checked:
	if (ps_tr->ui_rec_checked)
	  goto add;
	goto next;

    marked:
	if (ps_tr->ui_rec_marked)
	  goto add;
	goto next;

    checknmarked:
	if (ps_tr->ui_rec_checked || ps_tr->ui_rec_marked)
	{
      add:
	  ps_cur->l_account_sum += ps_tr->l_amount;
	}

    next:
	;
      }

      MemHandleUnlock(pv_item);
    }

    PROGRESSBAR_INLOOP(uh_num_records - index, 50); // OK
  }

  PROGRESSBAR_END;

  MemHandleUnlock(self->vh_accounts);

  // On passe à papa qui va convertir les sommes de chaque compte dans
  // la monnaie globale
  [super computeEachEntrySum];
}


//
// Pour chaque compte :
// - initialisation l_sum
- (void)computeEachEntryConvertSum
{
  if (self->vh_accounts != NULL)
  {
    Currency *oCurrencies;
    struct s_account *ps_account;
    struct s_currency *ps_global_currency, *ps_account_currency;
    UInt16 index, uh_currency;

    // La devise d'affichage a probablement changé
    uh_currency = ((SumListForm*)self->oForm)->uh_currency;

    oCurrencies = [oMaTirelire currency];

    ps_global_currency = [oCurrencies getId:uh_currency];
    ps_account_currency = NULL;

    ps_account = MemHandleLock(self->vh_accounts);

    for (index = self->uh_num_items; index-- > 0; ps_account++)
    {
      // La monnaie du compte est la même que la monnaie générale
      if (ps_account->uh_currency == uh_currency)
	ps_account->l_sum = ps_account->l_account_sum;
      // Monnaies différentes
      else
      {
	if (ps_account_currency == NULL
	    || ps_account->uh_currency != ps_account_currency->ui_id)
	{
	  [oCurrencies getFree:ps_account_currency];
	  ps_account_currency = [oCurrencies getId:ps_account->uh_currency];
	}

	ps_account->l_sum = currency_convert_amount(ps_account->l_account_sum,
						    ps_account_currency,
						    ps_global_currency);
      }
    }

    [oCurrencies getFree:ps_global_currency];
    if (ps_account_currency != NULL)
      [oCurrencies getFree:ps_account_currency];

    MemHandleUnlock(self->vh_accounts);
  }

  // On passe la main à papa qui va calculer la somme globale
  [super computeEachEntryConvertSum];
}


//
// - initialise self->l_sum
- (void)computeSum
{
  t_amount l_sum = 0;

  if (self->vh_accounts != NULL)
  {
    struct s_account *ps_accounts = MemHandleLock(self->vh_accounts);
    UInt16 uh_index, uh_comp;

    // Si sum_type == ALL (0)        => -1 ==> 0xffff (XOR 1 != 0 / XOR 0 != 0)
    // Si sum_type == SELECT (1)     => 0
    // Si sum_type == NON_SELECT (2) => 1
    uh_comp = [oMaTirelire transaction]->ps_prefs->ul_accounts_sel_type - 1;

    for (uh_index = self->uh_num_items; uh_index-- > 0; ps_accounts++)
      if (uh_comp ^ ps_accounts->uh_selected)
	l_sum += ps_accounts->l_sum;

    MemHandleUnlock(self->vh_accounts);
  }

  self->l_sum = l_sum;
}


- (void)initColumns
{
  self->pf_line_draw = __trans_draw_account;

  self->uh_flags = SCROLLLIST_BOTTOP | SCROLLLIST_FULL;

  [super initColumns];
}


//
// Un clic long vient d'être détecté sur la ligne uh_row
// Renvoie le WinHandle correspondant à la zone à restaurer.
// - uh_row est la ligne de la table qui a subit le clic long ;
// - pp_top_left est l'adresse à laquelle le coin supérieur gauche de
//   la zone sauvée doit être stocké (le champ y est initialisé aux
//   coordonnées du stylet pressé à l'appel) ;
- (WinHandle)longClicOnRow:(UInt16)uh_row topLeftIn:(PointType*)pp_win
{
  struct s_account *ps_account;
  RectangleType s_rect;
  Int16 h_x;

  // Position en X
  // On est appelé depuis le clavier
  if (pp_win == NULL)
    h_x = -1;			// Au centre de l'écran
  else
    h_x = pp_win->x;

  // Position en Y de la ligne sélectionnée
  [self getRow:uh_row bounds:&s_rect];

  switch ([self->oForm contextPopupList:AccountsListContextMenu
	       x:h_x y:s_rect.topLeft.y + s_rect.extent.y
	       selEntry:0]) // Toujours sélection de la première entrée
  {
  case 0:			// Propriétés...
    ps_account = MemHandleLock(self->vh_accounts);
    ps_account += TblGetRowID(self->pt_table, uh_row);

    // XXX Pas très propre XXX
    ((AccountsListForm*)self->oForm)->h_account = ps_account->uh_cat_id;

    MemHandleUnlock(self->vh_accounts);

    FrmPopupForm(AccountPropFormIdx);
    break;

  case 1:			// Ouvrir...
    [self shortClicOnRow:uh_row from:0 to:0];
    break;

  default:
    break;
  }

  // Ici on vient d'ouvrir un popup déjà refermé, donc rien à restaurer => NULL
  return SCROLLLIST_FAKE_WINHANDLE;
}


// Renvoie true si le clic a été traité
- (Boolean)shortClicOnLabelOfRow:(UInt16)uh_row xPos:(UInt16)uh_x
{
  struct s_db_prefs *ps_db_prefs = [oMaTirelire transaction]->ps_prefs;
  struct s_account *ps_account;

  ps_account = MemHandleLock(self->vh_accounts);
  ps_account += TblGetRowID(self->pt_table, uh_row);

  // On modifie les préférences de la base pour en changer le compte
  // par défaut
  ps_db_prefs->ul_cur_category = ps_account->uh_cat_id;

  MemHandleUnlock(self->vh_accounts);

  [(AccountsListForm*)self->oForm gotoFormViaUpdate:TransListFormIdx];

  return true;
}


//
// Renvoie -1 si rien n'a bougé
// Renvoie 1 si la somme a été sélectionnée (passage de 0 à 1)
// Renvoie 3 si pareil mais qu'il faut redessiner la somme complètement
// Renvoie 0 si la somme a été désélectionnée (passage de 1 à 0)
- (Int16)shortClicOnSumOfRow:(UInt16)uh_row xPos:(UInt16)uh_x
		      amount:(t_amount*)pl_amount
{
  struct s_db_prefs *ps_db_prefs;
  struct s_account *ps_account;
  Boolean b_new_select_state;

  ps_account = MemHandleLock(self->vh_accounts);
  ps_account += TblGetRowID(self->pt_table, uh_row);

  b_new_select_state = (ps_account->uh_selected ^= 1);

  // Il faut sauvegarder cet état dans les préférences de la base
  ps_db_prefs = [oMaTirelire transaction]->ps_prefs;

  if (b_new_select_state)
    ps_db_prefs->uh_selected_accounts |= (1 << ps_account->uh_cat_id);
  else
    ps_db_prefs->uh_selected_accounts &= ~(1 << ps_account->uh_cat_id);

  *pl_amount = ps_account->l_sum;

  MemHandleUnlock(self->vh_accounts);

  return b_new_select_state;
}


// La somme l_amount vient de changer d'état en b_selected
// Il faut peut-être modifier self->l_sum et si c'est le cas, il faut
// renvoyer true.
// Renvoie true si la somme doit être rafaichie
- (Boolean)addAmount:(t_amount)l_amount selected:(Boolean)b_selected
{
  struct s_db_prefs *ps_db_prefs = [oMaTirelire transaction]->ps_prefs;

  if (ps_db_prefs->ul_accounts_sel_type != ACCOUNTS_SUM_ALL)
  {
    if ((ps_db_prefs->ul_accounts_sel_type == ACCOUNTS_SUM_NON_SELECT)
	^ b_selected)
      self->l_sum += l_amount;
    else
      self->l_sum -= l_amount;

    return true;
  }

  return false;
}


//
// Sélection par le clavier sur la ligne uh_row
- (void)clicOnRow:(UInt16)uh_row
{
  // On re-sélectionne la ligne
  [self selectRow:uh_row];

  // On affiche le menu contextuel...
  [self longClicOnRow:uh_row topLeftIn:NULL];

  // Désélection de la ligne
  [self unselectRow:uh_row];
}


- (UInt16)_changeHandFillIncObjs:(UInt16*)puh_objs
		 withoutDontDraw:(Boolean)b_without_dont_draw
{
  UInt16 uh_list_full = self->uh_num_items == MAX_ACCOUNTS;
  UInt16 uh_updown_arrows = 0;
  UInt16 uh_nb_objs = 1 + 1 + 1; // Popup + devise + somme

  switch ([oMaTirelire transaction]->ps_prefs->ul_sum_type)
  {
  default:
    if (b_without_dont_draw == false)
    {
      uh_updown_arrows = SCROLLLIST_CH_DONT_DRAW;
    case VIEW_TODAY:
    case VIEW_DATE:
    case VIEW_TODAY_PLUS:
      *puh_objs++ = bmpDateUp | uh_updown_arrows;
      *puh_objs++ = SumListDateUp | uh_updown_arrows;
      *puh_objs++ = bmpDateDown | uh_updown_arrows;
      *puh_objs++ = SumListDateDown | uh_updown_arrows;
      uh_nb_objs += 4;
    }
    break;
  }

  if (b_without_dont_draw == false || uh_list_full == 0)
  {
    *puh_objs++ = AccountsListNew | uh_list_full;
    uh_nb_objs++;
  }

  if (b_without_dont_draw == false)
  {
    *puh_objs++ = SumListSumTypeList | SCROLLLIST_CH_DONT_DRAW;
    *puh_objs++ = SumListCurrencyList | SCROLLLIST_CH_DONT_DRAW;

    uh_nb_objs += 2;
  }

  *puh_objs++ = SumListSumTypePopup;

  *puh_objs++ = SumListCurrency;
  *puh_objs = SumListSum;

  return uh_nb_objs;
}


- (void)changeSumFilter:(UInt16)uh_sum_filter
{
  struct s_db_prefs *ps_db_prefs = [oMaTirelire transaction]->ps_prefs;

  if (uh_sum_filter != ps_db_prefs->ul_accounts_sel_type)
  {
    ps_db_prefs->ul_accounts_sel_type = uh_sum_filter;

    [self computeSum];
    [self displaySum];
  }
}

@end
