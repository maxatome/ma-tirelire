/* 
 * Transaction.m -- 
 * 
 * Author          : Maxime Soulé
 * Created On      : Mon May 31 21:57:29 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb  1 17:39:14 2008
 * Update Count    : 191
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: Transaction.m,v $
 * Revision 1.24  2008/02/01 17:30:02  max
 * s/WinPrintf/alert_error_str|winprintf/g
 *
 * Revision 1.23  2008/01/14 13:18:44  max
 * Switch to new mcc.
 * Handle signed splits.
 * Can now -computeAllRepeats: on a number of days different from
 * preferences one.
 * -deleteId: now takes care of possibly orphaned linked transactions.
 * In LstSetSelection calls s/noListSelection/0/.
 * Clean some unused functions.
 *
 * Revision 1.22  2006/11/04 23:48:27  max
 * Use FOREACH_SPLIT* macros.
 *
 * Revision 1.21  2006/10/05 19:09:04  max
 * Typo.
 *
 * Revision 1.20  2006/07/04 11:49:16  max
 * Add splits_parse_new() & splits_parse_free().
 *
 * Revision 1.19  2006/06/19 12:24:28  max
 * s/-validRecord:correct:/-validRecord:correct:types:modes:currencies:/
 * -validRecord:correct:types:modes:currencies: now adds inexistant
 * types, modes and currencies.
 * -validRecord:correct:types:modes:currencies: don't delete splits
 * anymore when transaction amount is lower than 0.
 * Bug in -addCurrencyOption:forId: for splitted transactions corrected.
 * -getLastStatementNumber now search 200 transactions backward.
 * options_check_extract() now check each split.
 *
 * Revision 1.18  2006/04/25 08:48:00  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 * s/sub_tr/splits/gi;
 * Add splits handling.
 * Correct -save:size:asId:account:xferAccount: insertion position search.
 *
 * Revision 1.17  2005/11/19 16:56:39  max
 * Add -changeFlaggedToChecked: method to transform flagged to checked
 * with statement number handling.
 * Add repeat_expand_note() and repeat_num_occurences() to help handling
 * future transactions available in the new RepeatsListForm screen.
 * Changing transaction date didn't move transaction to the right
 * place. Corrected.
 *
 * Revision 1.16  2005/10/11 19:12:10  max
 * -accountCurrency: can now take ACCOUNT_PROP_CURRENT as account value.
 * Last statement search imported from MaTiForm in -getLastStatementNumber method.
 *
 * Revision 1.15  2005/10/06 20:24:02  max
 * s/-computeAllRepeats/-computeAllRepeats:/
 *
 * Revision 1.14  2005/10/06 19:48:20  max
 * match() now have a b_exact argument.
 * -computeRepeatsOfId: returns false when ul_auto_repeat is false.
 *
 * Revision 1.13  2005/09/02 17:23:10  max
 * Correct transactions date sort.
 *
 * Revision 1.12  2005/08/31 19:43:12  max
 * Sorts are now handled by two functions transaction_val_date_cmp() and
 * transaction_std_cmp() instead of transaction_cmp() old one.
 * Withdrawal date sort reworked. Now the withdrawal date is taken first
 * (as before) then the transaction date (new), then the transaction
 * time.
 * Add -sortByValueDate: method.
 *
 * Revision 1.11  2005/08/31 19:38:53  max
 * *** empty log message ***
 *
 * Revision 1.10  2005/08/20 13:07:14  max
 * Prepare switching to 64 bits amounts.
 * s/__trans_draw_record/trans_draw_record/g.
 * __list_accounts_draw() don't change pointed coordinates anymore.
 *
 * Revision 1.9  2005/05/18 20:00:07  max
 * All do_on_each_transaction() compatible methods modified to take an
 * UInt32 instead of an UInt16 as first argument.
 * Add -findRecord: method and find_on_each_transaction() function to
 * support Palm Find feature.
 * do_on_each_transaction() now terminates if the method returns (UInt32)-1.
 *
 * Revision 1.8  2005/05/08 12:13:09  max
 * -getPrefs method deals with new and old (v1/v0) DBase preferences format.
 * Account records correction code set time to 0.
 * Fix typos in account correction code.
 * Correct checked accounts drawing in __list_accounts_draw().
 * Take into account of the accounts popup width.
 * Correct/implement checked accounts management.
 * Add +classPopupListFree: method to free popup list without the help of
 * a Transaction object.
 * do_on_each_transaction() now don't try to open an already opened DBase.
 *
 * Revision 1.7  2005/03/27 15:38:29  max
 * Add records correction methods -valid...
 * Xfer option unique ID restricted to 24 bits.
 * Add the ability to clone databases
 * Alarms are re-computed after a database cloning.
 * options_edit() now use an enum.
 * Add options_check_extract(), same as options_extract() but with bounds
 * checking.
 * Sort implemented.
 *
 * Revision 1.6  2005/03/20 22:28:31  max
 * Add alarm management
 *
 * Revision 1.5  2005/03/02 19:02:50  max
 * -accountProperties:index: can now return -recordGetAtId:'ed pointer.
 * Add progress bars for slow operations.
 * -deleteId: now relies on "Use conduit" database preferences instead of
 * Ma Tirelire one.
 * In account deletion, check whether modified transactions are not
 * account properties.
 *
 * Revision 1.4  2005/02/22 22:14:26  max
 * When changing an account currency, xfer transactions into the same
 * account were not correctly released. Corrected.
 *
 * Revision 1.3  2005/02/21 20:43:05  max
 * Add add/delete statement number option method.
 *
 * Revision 1.2  2005/02/19 17:08:55  max
 * Repeats now implements auto increment num or month.
 * New method to find the previous/next account of another one.
 * Accounts popup menu now accepts 2 ending entries.
 *
 * Revision 1.1  2005/02/09 22:57:23  max
 * First import.
 *
 * ==================== RCS ==================== */

#include <PalmOSGlue/TxtGlue.h>

#define EXTERN_TRANSACTION
#include "Transaction.h"

#include "BaseForm.h"		// list_line_draw_line

#include "MaTirelire.h"
#include "ProgressBar.h"
#include "TransScrollList.h"	// trans_draw_record

#include "alarm.h"
#include "float.h"
#include "misc.h"
#include "graph_defs.h"

#include "ids.h"
#include "objRsc.h"		// XXX
#include "MaTirelireDefsAuto.h"	// Pour strLongMonths et strShortMonths


//
// In each accounts database, in the sort block
struct s_db_sortinfos
{
  DateType s_last_repeat_date;	// Date of the last global repeat computation
};


@implementation Transaction

- (Transaction*)free
{
  // On sauve les préférences courantes de la base avant de la détruire...
  [self savePrefs];

  return [super free];
}


+ (Transaction*)open:(Char*)pa_db_name
{
  Transaction *oDB;
  UInt32 ui_creator, ui_type;
  LocalID ul_id;

  ul_id = DmFindDatabase(0, pa_db_name);
  if (ul_id == 0)
    return nil;

  // On vérifie que c'est bien une de nos bases
  if (DmDatabaseInfo(0, ul_id,
		     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		     &ui_type, &ui_creator)
      || ui_creator != MaTiCreatorID
      || ui_type != MaTiAccountsType)
    return nil;

  oDB = [self alloc];

  if ([oDB initWithCardNo:0 withID:ul_id] == nil)
  {
    alert_error_str("Error opening '%s': 0x%x", pa_db_name, DmGetLastErr());
    return [oDB free];
  }

  return oDB;
}


- (Boolean)seekRecord:(UInt16*)puh_index offset:(UInt16)uh_offset
	    direction:(UInt16)uh_direction
{
  DmSeekRecordInCategory(self->db, puh_index, uh_offset, uh_direction,
			 [self getPrefs]->ul_cur_category);

  return DmGetLastErr() == 0;
}


- (Char*)loadAccountName
{
  CategoryGetName(self->db, self->ps_prefs->ul_cur_category,
		  self->ra_account_name);
  if (self->ra_account_name[0] == '\0')
  {
    self->ps_prefs->ul_cur_category = dmAllCategories;
    self->ps_prefs->ul_show_all_cat = true;

    return NULL;		// Compte par défaut non trouvé
  }

  return self->ra_account_name;
}


- (struct s_db_prefs*)getPrefs
{
  if (self->ps_prefs == NULL)
  {
    UInt16 uh_note_size = 0;

    [self appInfoBlockLoad:(void**)&self->ps_prefs size:&uh_note_size
	  flags:INFOBLK_CATEGORIES | INFOBLK_PTRNEW];

    // Adaptation en fonction de la version
    if (self->ps_prefs->ul_version < MATI_DB_PREFS_VERSION)
    {
      struct s_db_prefs_0 *ps_prefs_0 = (struct s_db_prefs_0*)self->ps_prefs;

      uh_note_size -= sizeof(struct s_db_prefs_0);

      NEW_PTR(self->ps_prefs, sizeof(struct s_db_prefs) + uh_note_size,
	      // XXX ERREUR FATALE ICI XXX
	      return NULL);

      // Les anciennes préférences
      MemMove(self->ps_prefs, ps_prefs_0, sizeof(*ps_prefs_0));

      // Les nouvelles
      MemSet(self->ps_prefs->rs_stats, sizeof(self->ps_prefs->rs_stats), '\0');

      // La note, toujours en fin
      MemMove(self->ps_prefs->ra_note, ps_prefs_0->ra_note, uh_note_size);

      // On libère les anciennes préférences
      MemPtrFree(ps_prefs_0);
    }

    self->ps_prefs->ul_version = MATI_DB_PREFS_VERSION;

    // Adaptations au vol
    if (self->ps_prefs->ul_sum_todayplus == 0)
      self->ps_prefs->ul_sum_todayplus = 1;

    if (self->ps_prefs->ul_sum_date == 0)
      self->ps_prefs->ul_sum_date = 1;
  }

  return self->ps_prefs;
}


- (Boolean)savePrefs
{
  Boolean b_ret;

  if (self->ps_prefs == NULL)
    return false;

  b_ret = [self appInfoBlockSave:self->ps_prefs
		size:DBITEM_DEFCAT_SET(0, MemPtrSize(self->ps_prefs))] == 0;

  // On libère la zone quoiqu'il arrive...
  MemPtrFree(self->ps_prefs);
  self->ps_prefs = NULL;

  return b_ret;
}


- (UInt16)sumDate:(Int16)h_sum_type
{
  DateType s_date;

  if (h_sum_type < 0)
  {
    // Somme à une date donnée...
    if (self->ps_prefs->ul_sum_at_date)
      return DateToInt(self->ps_prefs->s_sum_date);

    h_sum_type = self->ps_prefs->ul_sum_type;
  }

  switch (h_sum_type)
  {
  case VIEW_TODAY:
    DateSecondsToDate(TimGetSeconds(), &s_date);
    break;

  case VIEW_DATE:
  {
    UInt16 uh_true_day;

    DateSecondsToDate(TimGetSeconds(), &s_date);

    // Vrai jour en fonction du nombre de jours dans le mois
    uh_true_day = DaysInMonth(s_date.month, s_date.year + firstYear);
    if (self->ps_prefs->ul_sum_date < uh_true_day)
      uh_true_day = self->ps_prefs->ul_sum_date;

    // Aujourd'hui >= à la date de la somme => mois suivant...
    if (s_date.day >= uh_true_day)
    {
      if (++s_date.month == 13)
      {
        s_date.month = 1;
        s_date.year++;
      }
    }
    s_date.day = uh_true_day;
  }
  break;

  case VIEW_TODAY_PLUS:
    DateSecondsToDate(TimGetSeconds() + (self->ps_prefs->ul_sum_todayplus
                                         * (24UL * 60UL * 60UL)),
                      &s_date);
    break;

    // La somme n'est pas fonction du jour...
  default:
    return 0;    
  }

  return DateToInt(s_date);
}


// Renvoie un pointeur locké sur les propriétés du compte passé.
// Crée les propriétés du compte si elle n'existent pas encore.
// 
// Si le flag ACCOUNT_PROP_RECORDGET est présent, renvoie un pointeur
// locké avec -recordGetAtId:, sur lequel il faudra appeler
// -recordRelease:
// Sinon il faut appeler MemPtrUnlock quand on n'a plus besoin du pointeur
//
// Si le flag ACCOUNT_PROP_CURRENT est présent, ouvre le compte
// présent dans les préférences.
- (struct s_account_prop*)accountProperties:(UInt16)uh_account
				      index:(UInt16*)puh_index
{
  MemHandle pv_prop;
  UInt16 uh_index = 0;
  Boolean b_record_get = false;

  if (uh_account & ACCOUNT_PROP_RECORDGET)
  {
    uh_account &= ~ACCOUNT_PROP_RECORDGET;
    b_record_get = true;
  }

  if (uh_account & ACCOUNT_PROP_CURRENT)
    uh_account = self->ps_prefs->ul_cur_category;

  pv_prop = DmQueryNextInCategory(self->db, &uh_index, uh_account);// No PG
  if (pv_prop == NULL)
  {
    struct s_account_prop s_prop;

    MemSet(&s_prop, sizeof(s_prop), '\0');
    s_prop.ui_acc_checked = 1;		 // Toujours pointé...
    s_prop.ui_acc_cheques_by_cbook = 25; // Par défaut 25 chèques / chéquier
    s_prop.ui_acc_currency = [[oMaTirelire currency] referenceId];

    uh_index = dmMaxRecordIndex; // Nouvel enregistrement
    if ([self save:(struct s_transaction*)&s_prop size:sizeof(s_prop)
	      asId:&uh_index account:uh_account xferAccount:-1] == false)
    {
      // XXX
    }

    if (b_record_get)
      goto record_get;

    pv_prop = DmQueryRecord(self->db, uh_index);
  }

  if (puh_index != NULL)
    *puh_index = uh_index;

  if (b_record_get)
  {
 record_get:
    return [self recordGetAtId:uh_index];
  }

  return MemHandleLock(pv_prop);
}


// Renvoie la devise du compte passé en paramètre
// (comme on appelle -accountProperties:index: le compte existe toujours)
//
// Si le flag ACCOUNT_PROP_CURRENT est présent, ouvre le compte
// présent dans les préférences.
- (UInt16)accountCurrency:(UInt16)uh_account
{
  struct s_account_prop *ps_prop;
  UInt16 uh_currency;

  if (uh_account & ACCOUNT_PROP_CURRENT)
    uh_account = self->ps_prefs->ul_cur_category;

  ps_prop = [self accountProperties:uh_account index:NULL];
  uh_currency = ps_prop->ui_acc_currency;
  MemPtrUnlock(ps_prop);

  return uh_currency;
}


// La monnaie du compte vient de changer, on parcourt toutes les
// opérations (y compris les propriétés du compte) et on convertit le
// montant (pour les propriétés les seuils de découvert sont aussi
// convertis) de l'ancienne devise (passée en paramètre) à la nouvelle
// devise (qui vient d'être enregistrée dans les propriétés du
// compte).
- (Boolean)account:(UInt16)uh_account changeCurrency:(UInt16)uh_old_currency
{
  Currency *oCurrencies;
  struct s_account_prop *ps_account_prop;
  struct s_currency *ps_old_currency, *ps_new_currency;
  struct s_transaction *ps_tr;
  PROGRESSBAR_DECL;
  struct s_rec_options s_options;
  t_amount l_old_sum, l_new_sum, l_amount, l_old_amount;
  UInt16 uh_new_currency, uh_record_num;

  oCurrencies = [oMaTirelire currency];

  // On charge la devise du compte
  uh_new_currency = [self accountCurrency:uh_account];

  // La devise ne change pas => il n'y a rien à faire
  if (uh_new_currency == uh_old_currency)
    return true;

  ps_old_currency = [oCurrencies getId:uh_old_currency];
  if (ps_old_currency == NULL)
  {
    // L'ancienne devise n'existe pas => le compte reste tel quel avec
    // la devise qui a changé...
    // XXX boite d'alerte ??? XXX
    return true;		// true ????
  }

  ps_new_currency = [oCurrencies getId:uh_new_currency];
  if (ps_new_currency == NULL)
  {
    // Le compte est avec une devise qui n'existe pas !!!!
    // XXX boite d'alerte ??? XXX
    [oCurrencies getFree:ps_old_currency];
    return false;		// Erreur !
  }

  l_old_sum = l_new_sum = 0;

  PROGRESSBAR_BEGIN(DmNumRecords(self->db),
		    strProgressBarChangeAccountCurrency);

  // Pour chaque opération  
  uh_record_num = 0;
  while (DmQueryNextInCategory(self->db,&uh_record_num,uh_account) != NULL)//PG
  {
    ps_tr = [self recordGetAtId:uh_record_num];
    if (ps_tr != NULL)
    {
      l_old_sum += ps_tr->l_amount; // Commun aux propriétés et aux opérations

      // Conversion
      l_old_amount = ps_tr->l_amount; // Pour opération avec devise + bas
      l_amount = currency_convert_amount(l_old_amount,
					 ps_old_currency, ps_new_currency);

      l_new_sum += l_amount;

      DmWrite(ps_tr, offsetof(struct s_transaction, l_amount),
	      &l_amount, sizeof(l_amount));

      // Propriétés de compte
      if (DateToInt(ps_tr->s_date) == 0)
      {
	ps_account_prop = (struct s_account_prop*)ps_tr;

	// Seuil de découvert
	l_amount = currency_convert_amount
	  (ps_account_prop->l_overdraft_thresold,
	   ps_old_currency, ps_new_currency);

	DmWrite(ps_tr, offsetof(struct s_account_prop, l_overdraft_thresold),
		&l_amount, sizeof(l_amount));

	// Seuil de non-découvert
	l_amount = currency_convert_amount
	  (ps_account_prop->l_non_overdraft_thresold,
	   ps_old_currency, ps_new_currency);

	DmWrite(ps_tr,offsetof(struct s_account_prop,l_non_overdraft_thresold),
		&l_amount, sizeof(l_amount));

	goto release_then_continue;
      }

      // Opération avec transfert vers une opération
      if ((ps_tr->ui_rec_flags & (RECORD_XFER|RECORD_XFER_CAT))
	       == RECORD_XFER)
      {
	UInt16 uh_link_account, uh_link_index, uh_link_currency;

	options_extract(ps_tr, &s_options);

	// L'enregistrement lié
	if (DmFindRecordByID(self->db,
			     s_options.ps_xfer->ul_id, &uh_link_index) == 0)
	{
	  DmRecordInfo(self->db, uh_link_index, &uh_link_account, NULL, NULL);

	  uh_link_account &= dmRecAttrCategoryMask;

	  // Il s'agit d'un transfert dans le même compte
	  if (uh_link_account == uh_account)
	  {
	remove_currency_option:
	    [self recordRelease:true];

	    // Au cas où, on supprime la partie devise (qui ne
	    // devrait pas être présente) des deux opérations)
	    [self deleteCurrencyOption:uh_link_index];
	    [self deleteCurrencyOption:uh_record_num];
	  }
	  // Transfert vers un autre compte
	  else
	  {
	    uh_link_currency = [self accountCurrency:uh_link_account];

	    // La nouvelle devise du compte est la même que celle du
	    // compte de l'opération liée
	    if (uh_new_currency == uh_link_currency)
	    {
	      // On supprime la partie devise des deux opérations
	      goto remove_currency_option;
	    }
	    // Les deux comptes n'ont pas la même monnaie, il faut
	    // créer ou modifier l'option devise dans chaque opération
	    else
	    {
	      struct s_transaction *ps_link_tr;
	      struct s_rec_currency s_currency;

	      MemSet(&s_currency, sizeof(s_currency), '\0');

	      // L'opération liée
	      s_currency.l_currency_amount = ps_tr->l_amount;
	      [self recordRelease:true];
	      s_currency.ui_currency = uh_new_currency;

	      [self addCurrencyOption:&s_currency forId:uh_link_index];

	      // Notre opération
	      ps_link_tr = [self getId:uh_link_index];
	      s_currency.l_currency_amount = ps_link_tr->l_amount;
	      [self getFree:ps_link_tr];
	      s_currency.ui_currency = uh_link_currency;

	      [self addCurrencyOption:&s_currency forId:uh_record_num];
	    }
	  }

	  goto done;
	}
	// Enregistrement lié pas trouvé...!!!
	else
	{
	  // ??? Suppression de la partie Xfer avec avertissement user ???
	  // XXX
	}
      }
      // Opération avec devise...
      else if (ps_tr->ui_rec_currency)
      {
	options_extract(ps_tr, &s_options);

	// Cette opération a une devise qui est la nouvelle devise du
	// compte. Du coup on inverse...
	if (s_options.ps_currency->ui_currency == uh_new_currency)
	{
	  struct s_rec_currency s_cur;

	  MemSet(&s_cur, sizeof(s_cur), '\0');
	  s_cur.l_currency_amount = l_old_amount;
	  s_cur.ui_currency = ps_old_currency->ui_id;

	  DmWrite(ps_tr, (Char*)s_options.ps_currency - (Char*)ps_tr,
		  &s_cur, sizeof(s_cur));

	  goto release_then_continue;
	}
      }

      // Il s'agit d'une opération ventilée, il faut mettre à jour
      // toute la ventilation et l'ajuster...
      if (ps_tr->ui_rec_splits)
      {
	t_amount l_new_splits_sum;
	FOREACH_SPLIT_DECL;	// __uh_num et ps_cur_split

	options_extract(ps_tr, &s_options);

	// On parcourt toutes les sous-opérations et on convertit leur
	// montant dans la nouvelle monnaie
	l_new_splits_sum = 0;
	FOREACH_SPLIT(&s_options)
	{
	  l_amount = currency_convert_amount(ps_cur_split->l_amount,
					     ps_old_currency, ps_new_currency);

	  l_new_splits_sum += l_amount;

	  DmWrite(ps_tr, (Char*)&ps_cur_split->l_amount - (Char*)ps_tr,
		  &l_amount, sizeof(l_amount));
	}

	// S'il y a une devise, les sous-op sont aussi dans cette devise
	if (ps_tr->ui_rec_currency)
	  l_amount = s_options.ps_currency->l_currency_amount;
	// Sinon montant de l'opération
	else
	  l_amount = ps_tr->l_amount;

	if (l_amount < 0)
	  l_amount = - l_amount;

	// La somme des sous-opérations converties est supérieure à la
	// valeur absolue du montant de l'opération : c'est un
	// problème...
	if (l_new_splits_sum > l_amount)
	{
	  // Il faut répartir la différence dans les sous-opérations
	  l_new_splits_sum -= l_amount;

	  FOREACH_SPLIT(&s_options)
	  {
	    l_amount = ps_cur_split->l_amount;

	    // Cette sous-opération peut absorber la différence restante
	    if (l_amount >= l_new_splits_sum)
	    {
	      l_amount -= l_new_splits_sum;
	      l_new_splits_sum = 0;
	    }
	    // Cette sous-opération ne peut pas absorber la différence
	    // entièrement
	    else
	    {
	      l_new_splits_sum -= l_amount;
	      l_amount = 0;
	    }

	    DmWrite(ps_tr, (Char*)&ps_cur_split->l_amount - (Char*)ps_tr,
		    &l_amount, sizeof(l_amount));

	    if (l_new_splits_sum == 0)
	      break;
	  }
	}
      }

  release_then_continue:
      [self recordRelease:true];
  done:
      ;
    }

    PROGRESSBAR_INLOOP(uh_record_num, 25); // OK

    uh_record_num++;
  }

  PROGRESSBAR_END;

  // La somme convertie doit correspondre
  l_old_sum = currency_convert_amount(l_old_sum,
				      ps_old_currency, ps_new_currency);
  if (l_old_sum != l_new_sum)
  {
    // Ça ne correspond pas, on va créer une opération factice
    // contenant la différence constatée
    DateTimeType s_datetime;
    Char ra_buf[sizeof(struct s_transaction) + 64];
    UInt16 uh_buf_len;

    ps_tr = (struct s_transaction*)ra_buf;
    MemSet(ps_tr, sizeof(*ps_tr), '\0');

    TimSecondsToDateTime(TimGetSeconds(), &s_datetime);

    ps_tr->s_date.month	  = s_datetime.month;
    ps_tr->s_date.day	  = s_datetime.day;
    ps_tr->s_date.year	  = s_datetime.year - firstYear;
    ps_tr->s_time.hours	  = s_datetime.hour;
    ps_tr->s_time.minutes = s_datetime.minute;
    ps_tr->l_amount = l_old_sum - l_new_sum;
    ps_tr->ui_rec_checked = 1;

    SysCopyStringResource(ps_tr->ra_note, strConvAccountCurrencyRound);
    uh_buf_len = sizeof(struct s_transaction) + StrLen(ps_tr->ra_note) + 1;

    uh_record_num = dmMaxRecordIndex; // Nouvelle opération
    if ([self save:ps_tr size:uh_buf_len asId:&uh_record_num
	      account:uh_account xferAccount:-1] == false)
    {
      // XXX
    }
  }

  [oCurrencies getFree:ps_new_currency];
  [oCurrencies getFree:ps_old_currency];
  
  return true;
}


//
// Renvoie le nombre de comptes dont la devise passée en paramètre est
// la devise
//
// XXX
// À refaire avec boucle sur les MAX_ACCOUNTS - 1 premiers enregistremants
// avec sortie dès que ps_tr->s_date != 0
// XXX
- (UInt16)numAccountCurrency:(UInt32)ui_currency
{
  MemHandle pv_prop;
  Char ra_account_name[dmCategoryLength];
  UInt16 uh_account, uh_record_num;
  UInt16 uh_num_accounts = 0;

  for (uh_account = 0; uh_account < MAX_ACCOUNTS; uh_account++)
  {
    CategoryGetName(self->db, uh_account, ra_account_name);
    if (ra_account_name[0] != '\0')
    {
      uh_record_num = 0;

      pv_prop = DmQueryNextInCategory(self->db, &uh_record_num,	// No PG here
				      uh_account);
      if (pv_prop != NULL)
      {
	if (((struct s_account_prop*)MemHandleLock(pv_prop))->ui_acc_currency
	    == ui_currency)
	  uh_num_accounts++;

	MemHandleUnlock(pv_prop);
      }
    }
  }

  return uh_num_accounts;
}


// Renvoie dmAllCategories si aucun compte n'a matché
// L'index du premier compte sinon...
- (UInt16)firstAccountMatching:(Char*)pa_search
{
  Char ra_final_account[dmCategoryLength], ra_account[dmCategoryLength];
  UInt16 index, uh_account_idx, uh_search_len;

  uh_search_len = StrLen(pa_search);

  uh_account_idx = dmAllCategories;

  // Cherche le compte
  for (index = 0; index < MAX_ACCOUNTS; index++)
  {
    CategoryGetName(self->db, index, ra_account);

    // Compte existant
    if (ra_account[0] != '\0'
	//  Premier test compatible avec M1
	&& (StrNCaselessCompare(ra_account, pa_search, uh_search_len) == 0
	    // Deuxième test avec wildcard...
	    || match(pa_search, ra_account, true)))
    {
      if (uh_account_idx == dmAllCategories
	  // Pour respecter l'ordre alphabétique
	  || StrCaselessCompare(ra_account, ra_final_account) < 0)
      {
	// Nouveau compte en tête
	MemMove(ra_final_account, ra_account, dmCategoryLength);
	uh_account_idx = index;
      }
    }
  }

  return uh_account_idx;
}


- (UInt16)selectNextAccount:(Boolean)b_next of:(UInt16)uh_cur_account
{
  Char ra_cur_account[dmCategoryLength];
  Char ra_before_account[dmCategoryLength];
  Char ra_after_account[dmCategoryLength];
  Char ra_account[dmCategoryLength];
  UInt16 index;
  UInt16 uh_before_account = dmAllCategories;
  UInt16 uh_after_account = dmAllCategories;

  // Le compte courant
  CategoryGetName(self->db, uh_cur_account, ra_cur_account);

  // On parcourt les comptes
  for (index = 0; index < MAX_ACCOUNTS; index++)
    // Pas le compte courant
    if (index != uh_cur_account)
    {
      CategoryGetName(self->db, index, ra_account);

      if (ra_account[0] != '\0')
      {
	// Ce compte est après le compte courant
	if (StrCaselessCompare(ra_account, ra_cur_account) > 0)
	{
	  // Il n'y a pas encore de prochain compte
	  if (uh_after_account == dmAllCategories
	      // OU BIEN ce compte précède (si b_next == true)
	      //                ou suit (si b_next == false)
	      //         le compte d'après déjà trouvé
	      || (StrCaselessCompare(ra_account, ra_after_account)>0) ^ b_next)
	  {
	    MemMove(ra_after_account, ra_account, dmCategoryLength);
	    uh_after_account = index;
	  }
	}
	// Ce compte est avant le compte courant
	else
	{
	  // Il n'y a pas encore de premier compte
	  if (uh_before_account == dmAllCategories
	      // OU BIEN ce compte précède (si b_next == true)
	      //                ou suit (si b_next == false)
	      //         le compte d'avant déjà trouvé
	      || (StrCaselessCompare(ra_account, ra_before_account)>0)^ b_next)
	  {
	    MemMove(ra_before_account, ra_account, dmCategoryLength);
	    uh_before_account = index;
	  }
	}
      }
    }

  if (b_next)
  {
    // Pas de prochain compte, on prend le premier compte...
    if (uh_after_account == dmAllCategories)
      uh_after_account = uh_before_account; // Peut valoir dmAllCategories
  }
  else
  {
    // Il y a un compte précédent, on prépare le retour (s'il n'y a
    // pas de compte précédent on prendra automatiquement le dernier,
    // puis que uh_after_account n'est pas touché dans ce cas)
    if (uh_before_account != dmAllCategories)
      uh_after_account = uh_before_account;
  }

  return uh_after_account;
}


// Retire, de chaque opération, la partie devise si cette dernière a
// comme devise celle passée en paramètre.
// *** Cette méthode ne doit être appelée que l'orsqu'on est sûr que
// *** cette devise n'est pas la devise principale d'un compte.
// Renvoie le nombre d'opérations modifiées
- (UInt16)removeCurrency:(UInt32)uh_currency
{
  MemHandle pv_item;
  struct s_transaction *ps_tr;
  struct s_rec_options s_options;
  Char *pa_buf = NULL;
  UInt16 index, uh_size = 0, uh_num_deleted = 0;

  for (index = DmNumRecords(self->db); index-- > 0; )
  {
    pv_item = DmQueryRecord(self->db, index);
    if (pv_item != NULL)
    {
      ps_tr = MemHandleLock(pv_item);

      // Pas les propriétés d'un compte MAIS AVEC une devise
      if (DateToInt(ps_tr->s_date) != 0 && ps_tr->ui_rec_currency)
      {
	options_extract(ps_tr, &s_options);

	// Cette opération a cette devise !
	if (s_options.ps_currency->ui_currency == uh_currency)
	{
	  // Taille de la zone située après la devise
	  uh_size = (s_options.pa_note
		     - (Char*)(s_options.ps_currency + 1)
		     + StrLen(s_options.pa_note) + 1); // Dont \0

	  NEW_PTR(pa_buf, uh_size, ({ MemHandleUnlock(pv_item); return 0; }));

	  MemMove(pa_buf, s_options.ps_currency + 1, uh_size);
	}
      }

      MemHandleUnlock(pv_item);

      if (pa_buf != NULL)
      {
	union u_rec_flags u_flags;
	UInt16 uh_offset;

	uh_offset = (Char*)s_options.ps_currency - (Char*)ps_tr;

	ps_tr = [self recordResizeId:index newSize:uh_offset + uh_size];
	if (ps_tr == NULL)
	{
	  // MemPtrFree(pa_buf);
	  // pa_buf = NULL;
	  // XXX
	}

	DmWrite(ps_tr, uh_offset, pa_buf, uh_size);

	MemPtrFree(pa_buf);
	pa_buf = NULL;

	// On retire la devise des flags
	u_flags = ps_tr->u_flags;
	u_flags.s_bit.ui_currency = 0;
	DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
		&u_flags, sizeof(u_flags));

	[self recordRelease:true];

	uh_num_deleted++;
      }
    }
  }

  return uh_num_deleted;
}


- (UInt16)removeType:(UInt32)ui_type
{
  MemHandle pv_item;
  struct s_transaction *ps_tr;
  UInt16 index, uh_num_deleted = 0;

  for (index = DmNumRecords(self->db); index-- > 0; )
  {
    pv_item = DmQueryRecord(self->db, index);
    if (pv_item != NULL)
    {
      ps_tr = MemHandleLock(pv_item);

      // Pas les propriétés d'un compte
      if (DateToInt(ps_tr->s_date) != 0)
      {
	struct s_rec_options s_options;
	FOREACH_SPLIT_DECL; // __uh_num et ps_cur_split
	UInt16 uh_num_sub_types = 0;

	// Il y a des sous-opérations à regarder
	if (ps_tr->ui_rec_splits)
	{
	  options_extract(ps_tr, &s_options);

	  // On parcourt toutes les sous-opérations
	  FOREACH_SPLIT(&s_options)
	    if (ps_cur_split->ui_type == ui_type)
	      uh_num_sub_types++;
	}

	// Le type principal correspond
	if (ps_tr->ui_rec_type == ui_type || uh_num_sub_types > 0)
	{
	  void *ps_rec;
	  union u_rec_flags u_flags;

	  u_flags = ps_tr->u_flags;

	  MemHandleUnlock(pv_item);

	  ps_rec = [self recordGetAtId:index];

	  // Le type principal correspond
	  if (u_flags.s_bit.ui_type == ui_type)
	  {
	    u_flags.s_bit.ui_type = TYPE_UNFILED;
	    DmWrite(ps_rec, offsetof(struct s_transaction, u_flags),
		    &u_flags, sizeof(u_flags));
	  }

	  // Il y a une ou plusieurs sous-opérations qui ont ce type
	  if (uh_num_sub_types > 0)
	  {
	    UInt32 ui_tmp;

	    options_extract(ps_rec, &s_options);

	    // On parcourt toutes les sous-opérations
	    ps_cur_split = NULL;
	    do
	    {
	      // OK
	      ps_cur_split = sub_trans_next_extract(s_options.ps_splits,
						    ps_cur_split);

	      if (ps_cur_split->ui_type == ui_type)
	      {
		ui_tmp = *(UInt32*)ps_cur_split;
		((struct s_rec_one_sub_transaction*)&ui_tmp)->ui_type
		  = TYPE_UNFILED;

		DmWrite(ps_rec, (Char*)ps_cur_split - (Char*)ps_rec,
			&ui_tmp, sizeof(ui_tmp));

		uh_num_sub_types--;
	      }
	    }
	    while (uh_num_sub_types > 0);
	  }

	  [self recordRelease:true];

	  uh_num_deleted++;

	  continue;
	}
      }

      MemHandleUnlock(pv_item);
    }
  }

  return uh_num_deleted;
}


- (UInt16)removeMode:(UInt32)ui_mode
{
  MemHandle pv_item;
  struct s_transaction *ps_tr;
  UInt16 index, uh_num_deleted = 0;

  for (index = DmNumRecords(self->db); index-- > 0; )
  {
    pv_item = DmQueryRecord(self->db, index);
    if (pv_item != NULL)
    {
      ps_tr = MemHandleLock(pv_item);

      // Pas les propriétés d'un compte MAIS AVEC le bon mode
      if (DateToInt(ps_tr->s_date) != 0 && ps_tr->ui_rec_mode == ui_mode)
      {
	void *ps_rec;
	union u_rec_flags u_flags;

	u_flags = ps_tr->u_flags;

	MemHandleUnlock(pv_item);

	ps_rec = [self recordGetAtId:index];

	u_flags.s_bit.ui_mode = MODE_UNKNOWN;
	DmWrite(ps_rec, offsetof(struct s_transaction, u_flags),
		&u_flags, sizeof(u_flags));

	[self recordRelease:true];

	uh_num_deleted++;
      }
      else
	MemHandleUnlock(pv_item);
    }
  }

  return uh_num_deleted;
}


// On ôte l'info de transfert sur l'enregistrement
- (Boolean)deleteXferOption:(UInt16)uh_index
{
  MemHandle pv_rec;
  struct s_transaction *ps_tr;

  pv_rec = DmQueryRecord(self->db, uh_index);
  if (pv_rec == NULL)
    return false;

  ps_tr = MemHandleLock(pv_rec);

  if (ps_tr->ui_rec_xfer)
  {
    struct s_rec_options s_options;
    Char *pa_buf;
    union u_rec_flags u_flags;
    UInt16 uh_size, uh_offset;

    options_extract(ps_tr, &s_options);

    // Taille de la zone située après l'info de transfert
    uh_size = (s_options.pa_note - (Char*)(s_options.ps_xfer + 1)
	       + StrLen(s_options.pa_note) + 1); // Dont \0

    NEW_PTR(pa_buf, uh_size, goto end);

    MemMove(pa_buf, s_options.ps_xfer + 1, uh_size);

    MemHandleUnlock(pv_rec);

    // Juste différence de pointeur pas besoin de lock ici
    uh_offset = (Char*)s_options.ps_xfer - (Char*)ps_tr;

    ps_tr = [self recordResizeId:uh_index newSize:uh_offset + uh_size];

    DmWrite(ps_tr, uh_offset, pa_buf, uh_size);

    // On retire le xfer des flags
    u_flags = ps_tr->u_flags;
    u_flags.ui_all &= ~(RECORD_XFER | RECORD_XFER_CAT);
    DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
	    &u_flags, sizeof(u_flags));

    [self recordRelease:true];

    MemPtrFree(pa_buf);

    return true;
  }

 end:
  MemHandleUnlock(pv_rec);

  return false;
}


- (Boolean)changeXferOption:(UInt32)ul_id forId:(UInt16)uh_index
{
  struct s_transaction *ps_tr;
  struct s_rec_options s_options;
  union u_rec_flags u_flags;

  ps_tr = [self recordGetAtId:uh_index];
  if (ps_tr == NULL)
    return false;

  u_flags = ps_tr->u_flags;

  // Il n'y a pas de partie Xfer
  if (u_flags.s_bit.ui_xfer == 0)
  {
    [self recordRelease:false];
    return false;
  }

  if (ul_id & CHANGE_XFER_OPTION_CATEGORY)
  {
    ul_id &= ~CHANGE_XFER_OPTION_CATEGORY;

    if (u_flags.s_bit.ui_xfer_cat)
      goto dont_change_flags;

    u_flags.s_bit.ui_xfer_cat = 1;
  }
  else
  {
    if (u_flags.s_bit.ui_xfer_cat == 0)
      goto dont_change_flags;

    u_flags.s_bit.ui_xfer_cat = 0;
  }

  // Le bit ui_xfer_cat change de valeur
  DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
	  &u_flags, sizeof(u_flags));

 dont_change_flags:
  options_extract(ps_tr, &s_options);

  // Mise en place de la devise passée en paramètre
  DmWrite(ps_tr, (Char*)s_options.ps_xfer - (Char*)ps_tr,
	  &ul_id, sizeof(struct s_rec_xfer));

  [self recordRelease:true];

  return true;
}


// On ôte l'info de devise de l'enregistrement
- (Boolean)deleteCurrencyOption:(UInt16)uh_index
{
  MemHandle pv_rec;
  struct s_transaction *ps_tr;

  pv_rec = DmQueryRecord(self->db, uh_index);
  if (pv_rec == NULL)
    return false;

  ps_tr = MemHandleLock(pv_rec);

  if (ps_tr->ui_rec_currency)
  {
    struct s_rec_options s_options;
    Char *pa_buf;
    union u_rec_flags u_flags;
    UInt16 uh_size, uh_offset;

    options_extract(ps_tr, &s_options);

    // Taille de la zone située après l'info de devise
    uh_size = (s_options.pa_note - (Char*)(s_options.ps_currency + 1)
	       + StrLen(s_options.pa_note) + 1); // Dont \0

    NEW_PTR(pa_buf, uh_size, goto end);

    MemMove(pa_buf, s_options.ps_currency + 1, uh_size);

    MemHandleUnlock(pv_rec);

    // Juste différence de pointeur pas besoin de lock ici
    uh_offset = (Char*)s_options.ps_currency - (Char*)ps_tr;

    ps_tr = [self recordResizeId:uh_index newSize:uh_offset + uh_size];

    DmWrite(ps_tr, uh_offset, pa_buf, uh_size);

    // On retire la devise des flags
    u_flags = ps_tr->u_flags;
    u_flags.s_bit.ui_currency = 0;
    DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
	    &u_flags, sizeof(u_flags));

    [self recordRelease:true];

    MemPtrFree(pa_buf);

    return true;
  }

 end:
  MemHandleUnlock(pv_rec);

  return false;
}


- (Boolean)addCurrencyOption:(struct s_rec_currency*)ps_curr_option
		       forId:(UInt16)uh_index
{
  MemHandle pv_rec;
  struct s_transaction *ps_tr;
  struct s_rec_options s_options;

  pv_rec = DmQueryRecord(self->db, uh_index);
  if (pv_rec == NULL)
    return false;

  ps_tr = MemHandleLock(pv_rec);

  // Il faut modifier la partie devise
  if (ps_tr->ui_rec_currency)
  {
    MemHandleUnlock(pv_rec);

    ps_tr = [self recordGetAtId:uh_index];
    if (ps_tr == NULL)
      return false;
  }
  else
  {
    Char *pa_buf;
    union u_rec_flags u_flags;
    UInt16 uh_size, uh_total_size;

    options_extract(ps_tr, &s_options);

    uh_size = StrLen(s_options.pa_note) + 1; // Avec \0
    uh_total_size = s_options.pa_note - (Char*)ps_tr + uh_size;

    // On prend en compte les sous-opérations car c'est la seule
    // option qui suit l'option de devise
    if (s_options.ps_splits != NULL)
      uh_size += sizeof(*s_options.ps_splits) + s_options.ps_splits->uh_size;

    // On alloue une zone correspondant à toutes les options qui
    // suivent celle qu'on veut supprimer
    NEW_PTR(pa_buf, uh_size, ({ MemHandleUnlock(pv_rec); return false; }));

    MemMove(pa_buf, (Char*)ps_tr + uh_total_size - uh_size, uh_size);
    u_flags = ps_tr->u_flags;

    MemHandleUnlock(pv_rec);

    uh_total_size += sizeof(struct s_rec_currency);

    ps_tr = [self recordResizeId:uh_index newSize:uh_total_size];
    if (ps_tr == NULL)
    {
      MemPtrFree(pa_buf);
      return false;
    }

    // On crée la place pour l'option devise
    DmWrite(ps_tr, uh_total_size - uh_size, pa_buf, uh_size);

    MemPtrFree(pa_buf);

    // Désormais il y a une option devise
    u_flags.s_bit.ui_currency = 1;
    DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
	    &u_flags, sizeof(u_flags));
  }

  options_extract(ps_tr, &s_options);

  // Mise en place de la devise passée en paramètre
  DmWrite(ps_tr, (Char*)s_options.ps_currency - (Char*)ps_tr,
	  ps_curr_option, sizeof(struct s_rec_currency));

  [self recordRelease:true];

  return true;
}


- (Boolean)deleteRepeatOption:(UInt16)uh_index
{
  MemHandle pv_rec;
  struct s_transaction *ps_tr;

  pv_rec = DmQueryRecord(self->db, uh_index);
  if (pv_rec == NULL)
    return false;

  ps_tr = MemHandleLock(pv_rec);

  if (ps_tr->ui_rec_repeat)
  {
    struct s_rec_options s_options;
    Char *pa_buf;
    union u_rec_flags u_flags;
    UInt16 uh_size, uh_offset;

    options_extract(ps_tr, &s_options);

    // Taille de la zone située après l'info de répétition
    uh_size = (s_options.pa_note - (Char*)(s_options.ps_repeat + 1)
	       + StrLen(s_options.pa_note) + 1); // Dont \0

    NEW_PTR(pa_buf, uh_size, ({ MemHandleUnlock(pv_rec); return false; }));

    MemMove(pa_buf, s_options.ps_repeat + 1, uh_size);

    MemHandleUnlock(pv_rec);

    // Juste différence de pointeur pas besoin de lock ici
    uh_offset = (Char*)s_options.ps_repeat - (Char*)ps_tr;

    ps_tr = [self recordResizeId:uh_index newSize:uh_offset + uh_size];

    DmWrite(ps_tr, uh_offset, pa_buf, uh_size);

    // On retire la devise des flags
    u_flags = ps_tr->u_flags;
    u_flags.s_bit.ui_repeat = 0;
    DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
	    &u_flags, sizeof(u_flags));

    [self recordRelease:true];

    MemPtrFree(pa_buf);

    return true;
  }

  MemHandleUnlock(pv_rec);

  return false;
}


#define DEBUG_VALID 1
- (Boolean)validRecord:(UInt16)uh_index correct:(Boolean)b_correct
		 types:(Type*)oTypes
		 modes:(Mode*)oModes
	    currencies:(Currency*)oCurrencies
{
  __label__ delete_record;
  __label__ end;
  MemHandle vh_rec = DmQueryRecord(self->db, uh_index);
#define ps_new_acc	((struct s_account_prop*)ps_new)
  struct s_transaction *ps_tr = NULL, *ps_new = NULL;
  Char *pa_desc;
  UInt16 uh_cur_size, uh_new_size;

  Boolean b_ret = false;

  void copy_rec(void)
  {
    if (ps_new == NULL)		// Pas encore recopié...
    {
      b_ret = true;

      // On est juste en phase d'observation...
      if (b_correct == false)
      {
	MemHandleUnlock(vh_rec);
	goto end;
      }

      NEW_PTR(ps_new, uh_new_size, goto delete_record);

      MemMove(ps_new, ps_tr, uh_new_size);

      // Account case...
      if (DateToInt(ps_new->s_date) == 0)
	TimeToInt(ps_new->s_time) = 0;
    }
  }

  void must_be_corrected(void)
  {
    [MaTirelire appli]->s_prefs.ul_db_must_be_corrected = 1;
  }

  void check_currency(UInt16 uh_currency)
  {
    if ([oCurrencies getCachedIndexFromID:uh_currency] != ITEM_FREE_ID)
      return;

    if (b_correct)
    {
      Char ra_buffer[sizeof(struct s_currency) + CURRENCY_NAME_MAX_LEN];
      Char ra_format[CURRENCY_NAME_MAX_LEN];
      struct s_currency *ps_currency = (struct s_currency*)ra_buffer;
      UInt16 uh_size, uh_id = dmMaxRecordIndex;

      SysCopyStringResource(ra_format, strAutoCreatedCurrencyName);

      MemSet(ps_currency, sizeof(struct s_currency), '\0');

      ps_currency->ui_id = uh_currency;
      ps_currency->d_reference_amount = 1.;
      ps_currency->d_currency_amount = 1.;
      uh_size = StrPrintF(ps_currency->ra_name, ra_format, uh_currency);

      uh_size += sizeof(struct s_currency) + 1; // \0
      [oCurrencies save:ps_currency size:uh_size asId:&uh_id
		   asNew:ITEM_NEW_WITH_ID];
    }
    else
      must_be_corrected();
  }

  void check_type(UInt16 uh_type)
  {
    if (uh_type != TYPE_UNFILED
	&& [oTypes getCachedIndexFromID:uh_type] == ITEM_FREE_ID)
    {
      if (b_correct)
      {
	Char ra_buffer[sizeof(struct s_type) + TYPE_NAME_MAX_LEN];
	Char ra_format[TYPE_NAME_MAX_LEN];
	struct s_type *ps_type = (struct s_type*)ra_buffer;
	UInt16 uh_size, uh_id = dmMaxRecordIndex;

	SysCopyStringResource(ra_format, strAutoCreatedTypeName);

	MemSet(ps_type, sizeof(struct s_type), '\0');

	ps_type->ui_id = uh_type;
	ps_type->ui_parent_id = TYPE_UNFILED;
	ps_type->ui_brother_id = TYPE_UNFILED;
	ps_type->ui_sign_depend = TYPE_ALL;
	uh_size = StrPrintF(ps_type->ra_name, ra_format, uh_type);

	uh_size += sizeof(struct s_type) + 1; // \0
	[oTypes save:ps_type size:uh_size asId:&uh_id asNew:ITEM_NEW_WITH_ID];
      }
      else
	must_be_corrected();
    }
  }

  if (vh_rec == NULL)
    return false;

  // Taille de l'enregistrement
  uh_cur_size = MemHandleSize(vh_rec);

  ////////////////////////////////////////////////
  // Trop petit pour la structure de base + le \0
  if (uh_cur_size < sizeof(struct s_transaction) + 1)
  {
#ifdef DEBUG_VALID
    if (b_correct)
      winprintf("Record #%d too small: %d < %d. DELETE record.",
		uh_index,
		uh_cur_size, (UInt16)sizeof(struct s_transaction) + 1);
#endif
 delete_record:
    if (b_correct)
    {
      if (ps_new != NULL)
	MemPtrFree(ps_new);

      if (ps_tr != NULL)
	MemHandleUnlock(vh_rec);

      // Destruction
      DmRemoveRecord(self->db, uh_index);
    }
    return true;
  }

  ps_tr = MemHandleLock(vh_rec);

  ////////////////////////////////////////////////////////////////////////
  //
  // Propriétés d'un compte
  if (DateToInt(ps_tr->s_date) == 0)
  {
    struct s_account_prop *ps_prop;
    UInt16 uh_cur_cb, uh_new_cb;
    Boolean b_cb_modified;

    ///////////////////////////////////////////////////////////////////
    // Vérification par rapport à la taille (2ème passe car maintenant
    // on sait que ce sont les propriétés d'un compte)
    if (uh_cur_size < ACCOUNT_PROP_SIZE) // \0 de la note inclus
    {
#ifdef DEBUG_VALID
    if (b_correct)
      winprintf("Account #%d record too small: %d < %d. "
		"DELETE account record.",
		uh_index, uh_cur_size, (UInt16)ACCOUNT_PROP_SIZE);
#endif
      goto delete_record;
    }

    ps_prop = (struct s_account_prop*)ps_tr;

    /////////////////////////////
    // La note doit finir par \0
    pa_desc = ps_prop->ra_note;
    uh_new_size = ACCOUNT_PROP_SIZE - 1; // Sans le \0 inclus
    while (uh_new_size < uh_cur_size && *pa_desc != '\0')
    {
      uh_new_size++;
      pa_desc++;
    }

    if (uh_new_size < uh_cur_size)
      uh_new_size++;		/* C'est bon on a le \0 */
    else
    {
#ifdef DEBUG_VALID
      if (b_correct)
	winprintf("Account #%d NUL note char not found, add it: %d >= %d. "
		  "Correct OK.",
		  uh_index, uh_new_size, uh_cur_size);
#endif

      // On n'a pas le \0 de la description : on le force sur le dernier car.
      copy_rec();
      pa_desc = (Char *)ps_new_acc;
      pa_desc[uh_new_size - 1] = '\0';
    }

    ///////////////////////////////////////////////////////////
    // reserved doit être à 0 et l'opération doit être pointée
    if (ps_prop->ui_acc_reserved || ps_prop->ui_acc_checked == 0)
    {
#ifdef DEBUG_VALID
      if (b_correct)
	winprintf("Account #%d reserved = %lu / cleared = %lu. Correct OK.",
		  uh_index, ps_prop->ui_acc_reserved, ps_prop->ui_acc_checked);
#endif

      copy_rec();
      ps_new_acc->ui_acc_reserved = 0;
      ps_new_acc->ui_acc_checked = 1;
    }

    /////////////////////////////////////////////
    // Seuils de découvert/renflouement ordonnés
    if (ps_prop->l_overdraft_thresold > ps_prop->l_non_overdraft_thresold)
    {
#ifdef DEBUG_VALID
      if (b_correct)
	winprintf("Account #%d invalid thresholds: %ld > %ld. Correct OK.",
		  uh_index, ps_prop->l_overdraft_thresold,
		  ps_prop->l_non_overdraft_thresold);
#endif

      copy_rec();
      ps_new_acc->l_overdraft_thresold = ps_prop->l_non_overdraft_thresold;
      ps_new_acc->l_non_overdraft_thresold = ps_prop->l_overdraft_thresold;
    }

    ////////////////////////////////////
    // Pas de trou dans rui_check_books
    b_cb_modified = false;
    for (uh_cur_cb = 0, uh_new_cb = 0; uh_cur_cb < NUM_CHECK_BOOKS;uh_cur_cb++)
      if (ps_prop->rui_check_books[uh_cur_cb] != 0)
      {
	if (uh_cur_cb > uh_new_cb)
	{
#ifdef DEBUG_VALID
	  if (b_correct)
	    winprintf("Account #%d hole in chequebooks: %d = %d. Correct OK.",
		      uh_index, uh_new_cb, uh_cur_cb);
#endif

	  copy_rec();
	  ps_new_acc->rui_check_books[uh_new_cb]
	    = ps_prop->rui_check_books[uh_cur_cb];

	  b_cb_modified = true;
	}

	uh_new_cb++;
      }

    if (b_cb_modified)
      for (; uh_new_cb < NUM_CHECK_BOOKS; uh_new_cb++)
	ps_new_acc->rui_check_books[uh_new_cb] = 0;

    //////////////////////////////////////////
    // Numéro de compte doit être fini par \0
    for (uh_cur_cb = 0, pa_desc = ps_prop->ra_number;
	 uh_cur_cb < sizeof(ps_prop->ra_number) && *pa_desc != '\0';
	 uh_cur_cb++, pa_desc++)
      ;

    if (uh_cur_cb == sizeof(ps_prop->ra_number))
    {
#ifdef DEBUG_VALID
      if (b_correct)
	winprintf("Account #%d account # without NUL char. Correct OK.",
		  uh_index);
#endif

      copy_rec();
      ps_new_acc->ra_number[sizeof(ps_prop->ra_number) - 1] = '\0';
    }

    // La monnaie du compte doit exister
    check_currency(ps_prop->ui_acc_currency);
  }
  ////////////////////////////////////////////////////////////////////////
  //
  // Une opération
  else
  {
    struct s_rec_options s_options, s_new_options;

    // Pour ne le remplir qu'une fois, on se sert de pa_note pour
    // savoir si la structure a déjà été initialisée ou non (comme
    // options_edit())
    s_new_options.pa_note = NULL;

    // Problème de taille
    if (options_check_extract(ps_tr, uh_cur_size, &s_options) == false)
    {
#ifdef DEBUG_VALID
      if (b_correct)
      {
	// Au niveau des sous-opérations : pas la place
	if (s_options.pa_note == NULL && s_options.ps_splits != NULL)
	{
	  UInt16 uh_offset = (((Char*)s_options.ps_splits - (Char*)ps_tr)
			      + sizeof(struct s_rec_sub_transaction));
	  winprintf("#%d sub-tr out of transaction: %d <= %d + %d. "
		    "DELETE transaction.",
		    uh_index, uh_cur_size, uh_offset,
		    uh_cur_size <= uh_offset ? 0: s_options.ps_splits->uh_size);
	}
	// Au niveau de la note : pas la place
	else
	  winprintf("#%d no room for the NUL note char: %d >= %d. "
		    "DELETE transaction.",
		    uh_index,
		    (UInt16)((Char*)s_options.pa_note - (Char*)ps_tr),
		    uh_cur_size);
      }
#endif
      goto delete_record;
    }

    // On vérifie la présence du type
    check_type(ps_tr->ui_rec_type);

    // On vérifie la présence du mode
    if (ps_tr->ui_rec_mode != MODE_UNKNOWN
	&& [oModes getCachedIndexFromID:ps_tr->ui_rec_mode] == ITEM_FREE_ID)
    {
      if (b_correct)
      {
	Char ra_buffer[sizeof(struct s_mode) + MODE_NAME_MAX_LEN];
	Char ra_format[MODE_NAME_MAX_LEN];
	struct s_mode *ps_mode = (struct s_mode*)ra_buffer;
	UInt16 uh_size, uh_id = dmMaxRecordIndex;

	SysCopyStringResource(ra_format, strAutoCreatedModeName);

	MemSet(ps_mode, sizeof(struct s_mode), '\0');

	ps_mode->ui_id = ps_tr->ui_rec_mode;
	uh_size = StrPrintF(ps_mode->ra_name, ra_format,(UInt16)ps_mode->ui_id);

	uh_size += sizeof(struct s_mode) + 1;
	[oModes save:ps_mode size:uh_size asId:&uh_id asNew:ITEM_NEW_WITH_ID];
      }
      else
	must_be_corrected();
    }

    //////////////////
    // La description
    pa_desc = s_options.pa_note;
    uh_new_size = pa_desc - (Char *)ps_tr; // Taille sans la note

    // Ici le options_check_extract() précédant nous assure que la
    // note est accessible
    while (uh_new_size < uh_cur_size && *pa_desc != '\0')
    {
      uh_new_size++;
      pa_desc++;
    }

    if (uh_new_size < uh_cur_size)
      uh_new_size++;		/* C'est bon on a le \0 */
    else
    {
#ifdef DEBUG_VALID
      if (b_correct)
	winprintf("#%d NUL note char not found, add it: %d >= %d. Correct OK.",
		  uh_index, uh_new_size, uh_cur_size);
#endif

      // On n'a pas le \0 de la description : on le force sur le dernier car.
      copy_rec();
      pa_desc = (Char *)ps_new;
      pa_desc[uh_new_size - 1] = '\0';
    }

    ///////////////////
    // Les répétitions
    if (ps_tr->ui_rec_repeat)
    {
      struct s_rec_repeat *ps_repeat = s_options.ps_repeat;

      // Répétition incorrecte...
      if (ps_repeat->uh_repeat_type > REPEAT_TYPE_LAST
	  || ps_repeat->uh_repeat_freq == 0
	  || ps_repeat->uh_reserved != 0)
      {
#ifdef DEBUG_VALID
	if (b_correct)
	  winprintf("#%d bad repeat info (type=%d, freq=%d, res=%d). "
		    "Delete repeat info.",
		    uh_index, ps_repeat->uh_repeat_type,
		    ps_repeat->uh_repeat_freq, ps_repeat->uh_reserved);
#endif
	// On vire la répétition
	copy_rec();

	uh_new_size = options_edit(ps_new, &s_new_options, NULL, OPT_REPEAT);
      }
    }

    //////////////////
    // Les transferts
    if (ps_tr->ui_rec_xfer)
    {
      UInt32 ul_id = s_options.ps_xfer->ul_id;
      UInt16 uh_link_index;

      // Pointe sur une catégorie
      if (ps_tr->ui_rec_xfer_cat)
      {
	Char ra_name[dmCategoryLength];

	if (ul_id < dmRecNumCategories
	    && (CategoryGetName(self->db, ul_id, ra_name), ra_name[0] != '\0'))
	  goto xfer_ok;

	// Problème, la catégorie n'existe pas (ou plus peu importe)
      }
      // Pointe sur une opération (unique ID possible)
      else if (ul_id != 0
	       && DmFindRecordByID(self->db, ul_id, &uh_link_index) == 0)
      {
	MemHandle vh_link_rec;
      
	// Notre unique ID
	DmRecordInfo(self->db, uh_index, NULL, &ul_id, NULL);

	// Il faut vérifier que l'enregistrement lié pointe bien sur nous
	vh_link_rec = DmQueryRecord(self->db, uh_link_index);
	if (vh_link_rec != NULL)
	{
	  struct s_transaction *ps_link_rec;
	  struct s_rec_options s_link_options;

	  ps_link_rec = MemHandleLock(vh_link_rec);

	  // Les options sont accessibles
	  if (options_check_extract(ps_link_rec, MemHandleSize(vh_link_rec),
				    &s_link_options)
	      // ET l'option Xfer est présente (sans xfer_cat)
	      && ps_link_rec->ui_rec_xfer && ps_link_rec->ui_rec_xfer_cat == 0
	      // ET le ID correspond...
	      && s_link_options.ps_xfer->ul_id == ul_id)
	  {
	    MemHandleUnlock(vh_link_rec);
	    goto xfer_ok;
	  }

	  MemHandleUnlock(vh_link_rec);
	}

	// Le ID ne correspond pas (ou pas de lien)
      }

      if (1)
      {
#ifdef DEBUG_VALID
	if (b_correct)
	  winprintf("#%d bad xfer. Delete xfer part.", uh_index);
#endif

	// Ici l'info de transfert est erronée il faut la virer
	copy_rec();

	uh_new_size = options_edit(ps_new, &s_new_options, NULL, OPT_XFER);
      }
      else
      {
    xfer_ok:
	//////////////////////////
	// reserved doit être à 0
	if (s_options.ps_xfer->ul_reserved != 0)
	{
#ifdef DEBUG_VALID
	  if (b_correct)
	    winprintf("#%d non null reserved xfer. Correct OK.", uh_index);
#endif

	  copy_rec();

	  options_extract(ps_new, &s_new_options);
	  s_new_options.ps_xfer->ul_reserved = 0;
	}
      }
    }
    // Si pas de transfert, alors le bit xfer_cat ne doit pas être présent
    else if (ps_tr->ui_rec_xfer_cat)
    {
#ifdef DEBUG_VALID
      if (b_correct)
	winprintf("#%d xfer_cat without xfer. Correct OK.", uh_index);
#endif

      copy_rec();
      ps_new->ui_rec_xfer_cat = 0;
    }

    ////////////
    // La devise
    if (ps_tr->ui_rec_currency)
      check_currency(s_options.ps_currency->ui_currency);

    ///////////////////////
    // Les sous-opérations
    if (ps_tr->ui_rec_splits)
    {
      struct s_rec_sub_transaction *ps_base_splits = s_options.ps_splits;
      UInt16 uh_sub_num;

      uh_sub_num = ps_base_splits->uh_num;

      // Pas de sous-opération
      if (uh_sub_num == 0
	  // OU BIEN pas la place pour toutes les sous-opérations au minimum
	  || ps_base_splits->uh_size
	  <= uh_sub_num * sizeof(struct s_rec_one_sub_transaction))
      {
#ifdef DEBUG_VALID
	if (b_correct)
	  winprintf("#%d sub-tr bad size: num=%d size=%d. "
		    "Delete sub-tr part.",
		    uh_index, uh_sub_num, ps_base_splits->uh_size);
#endif

	// On considère que les sous-op sont erronées : on les vire
    delete_sub_tr:
	copy_rec();

	uh_new_size = options_edit(ps_new, &s_new_options, NULL, OPT_SPLITS);
      }
      else
      {
	struct s_rec_one_sub_transaction *ps_cur_split;
	t_amount l_sub_amount = 0, l_abs_amount;
	Int16 h_sub_remain_size;
	Boolean b_reserved_not_null = (ps_base_splits->uh_reserved != 0);

	// La somme en positif
	l_abs_amount = ps_tr->l_amount;
	if (l_abs_amount < 0)
	  l_abs_amount = - l_abs_amount;

	ps_cur_split = (struct s_rec_one_sub_transaction*)(ps_base_splits + 1);
	h_sub_remain_size = s_options.pa_note - (Char*)ps_cur_split;

	while (h_sub_remain_size > sizeof(struct s_rec_one_sub_transaction)
	       && uh_sub_num-- > 0)
	{
	  // À noter que la somme d'une sous-opération peut être négative

	  l_sub_amount += ps_cur_split->l_amount;

	  if (ps_cur_split->ui_reserved != 0)
	    b_reserved_not_null = true;

	  h_sub_remain_size -= sizeof(struct s_rec_one_sub_transaction);

	  pa_desc = ps_cur_split->ra_desc;

	  while (h_sub_remain_size > 0 && *pa_desc != '\0')
	  {
	    h_sub_remain_size--;
	    pa_desc++;
	  }

	  if (*pa_desc == '\0')
	  {
	    // On passe le \0
	    pa_desc++;
	    h_sub_remain_size--;

	    if ((UInt32)pa_desc & 0x1UL)
	    {
	      pa_desc++;
	      h_sub_remain_size--;
	    }

	    // On vérifie l'existence du type
	    check_type(ps_cur_split->ui_type);

	    ps_cur_split = (struct s_rec_one_sub_transaction*)pa_desc;
	  }
	  // Sinon h_sub_remain_size == 0
	  else
	  {
#ifdef DEBUG_VALID
	    if (b_correct)
	      winprintf("#%d sub-tr too small (remain=%d): sub-op %d."
			"Delete sub-tr part.",
			uh_index, h_sub_remain_size,
			ps_base_splits->uh_num - uh_sub_num);
#endif
	    goto delete_sub_tr;
	  }
	}

	// Il reste des octets OU BIEN des sous-opérations
	if (h_sub_remain_size != 0 && uh_sub_num != 0)
	{
#ifdef DEBUG_VALID
	  if (b_correct)
	    winprintf("#%d truncated sub-tr: remain=%d bytes / %d sub-tr. "
		      "Delete sub-tr part.",
		      uh_index, h_sub_remain_size, uh_sub_num);
#endif
	  goto delete_sub_tr;
	}

	// La somme des sous-opérations est plus grande que la valeur
	// absolue de celle de l'opération
	if (l_sub_amount > l_abs_amount)
	{
#ifdef DEBUG_VALID
	  if (b_correct)
	    winprintf("#%d sub-trs amount > tr: tr=abs(%ld) sub-trs=%ld. "
		      "Delete sub-tr part.",
		      uh_index, ps_tr->l_amount, ps_cur_split->l_amount);
#endif
	  goto delete_sub_tr;
	}

	// Au moins un champ reserved non nul, on les met tous à 0...
	if (b_reserved_not_null)
	{
	  UInt16 __uh_num;	// Pour FOREACH_SPLIT

#ifdef DEBUG_VALID
	  if (b_correct)
	    winprintf("#%d sub-tr at least one reserved != 0. Correct OK.",
		      uh_index);
#endif

	  copy_rec();

	  options_extract(ps_new, &s_new_options);

	  s_options.ps_splits->uh_reserved = 0;

	  FOREACH_SPLIT(&s_options)
	    ps_cur_split->ui_reserved = 0;
	}
      }
    } // if (ui_rec_splits)

    //////////////////////////
    // reserved doit être à 0
    if (ps_tr->ui_rec_reserved)
    {
#ifdef DEBUG_VALID
      if (b_correct)
	winprintf("#%d reserved = %lu. Correct OK.",
		  uh_index, ps_tr->ui_rec_reserved);
#endif

      copy_rec();
      ps_new->ui_rec_reserved = 0;
    }
  }

  MemHandleUnlock(vh_rec);

  // La taille a changé...
  if (uh_cur_size != uh_new_size)
  {
    if (b_correct == false)
      // Pas la peine d'aller plus loin
      return true;

#ifdef DEBUG_VALID
    if (uh_cur_size == 62 && uh_new_size == 61)
      winprintf("Account record #%d resized due to a bug in a "
		"previous version. No problem here.", uh_index);
    else
      winprintf("Record #%d resized (from %d to %d bytes). "
		"Amount remains the same.",
		uh_index, uh_cur_size, uh_new_size);
#endif

    DmResizeRecord(self->db, uh_index, uh_new_size);
    b_ret = true;
  }

  // Il faut réécrire l'enregistrement
  if (ps_new != NULL)
  {
    ps_tr = [self recordGetAtId:uh_index];
    if (ps_tr != NULL)
    {
      DmWrite(ps_tr, 0, ps_new, uh_new_size);

      [self recordRelease:true];
    }

    MemPtrFree(ps_new);
  }

 end:
  return b_ret;
}


- (UInt16)validDB:(UInt32)ui_correct
{
  UInt16 index, uh_incorrect_num = 0;
  MaTirelire *oLocalMaTirelire = [MaTirelire appli];
  Type *oTypes = [oLocalMaTirelire type];
  Mode *oModes = [oLocalMaTirelire mode];
  Currency *oCurrencies = [oLocalMaTirelire currency];

  for (index = DmNumRecords(self->db); index-- > 0; )
    if ([self validRecord:index correct:ui_correct
	      types:oTypes
	      modes:oModes
	      currencies:oCurrencies])
    {
      uh_incorrect_num++;

      // On ne peut pas corriger, on le fera au prochain lancement
      if (ui_correct == 0)
      {
	// On ne prend pas la variable globale, car on peut être
	// appelé alors qu'elle n'est pas accessible
	oLocalMaTirelire->s_prefs.ul_db_must_be_corrected = 1;

	break;
      }
    }

  // On trie les enregistrements
  if (ui_correct)
  {
    [self getPrefs];

    [self sortByValueDate:self->ps_prefs->ul_sort_type];

    // On libère la zone quoiqu'il arrive...
    MemPtrFree(self->ps_prefs);
    self->ps_prefs = NULL;
  }

  return uh_incorrect_num;
}


- (void)sortByValueDate:(Boolean)b_by_value_date
{
  DmQuickSort(self->db,
	      b_by_value_date
	      ? (DmComparF*)transaction_val_date_cmp
	      : (DmComparF*)transaction_std_cmp,
	      0);
}


- (UInt32)getLastStatementNumber
{
  MemHandle pv_item;
  struct s_transaction *ps_tr;
  UInt32 ui_current_num = 0;
  UInt16 index, uh_num, uh_account;

  uh_account = self->ps_prefs->ul_cur_category;

  // On revient de 200 opérations en arrière pas plus
  uh_num = 200;

  // Recherche du dernier numéro de relevé dans la base
  ui_current_num = 0;
  index = dmMaxRecordIndex;
  while (DmSeekRecordInCategory(self->db, &index, 1, dmSeekBackward,
				uh_account) == errNone)
  {
    pv_item = DmQueryRecord(self->db, index);
    if (pv_item != NULL)
    {
      ps_tr = MemHandleLock(pv_item);

      // Les propriétés d'un compte OU BIEN opération avec un numéro de relevé
      if (DateToInt(ps_tr->s_date) == 0 || ps_tr->ui_rec_stmt_num)
      {
	// Si c'est les propriétés d'un compte, on ne va pas plus loin
	if (DateToInt(ps_tr->s_date) != 0)
	{
	  struct s_rec_options s_options;
	  options_extract(ps_tr, &s_options);
	  ui_current_num = s_options.ps_stmt_num->ui_stmt_num;
	}

	uh_num = 1; // Avec ça on va s'arrêter juste après le MemHandleUnlock
      }

      MemHandleUnlock(pv_item);

      // On n'a pas trouvé de numéro de relevé sur les 50 dernières
      // opérations, on arrête là...
      if (--uh_num == 0)
	break;
    }      
  }

  return ui_current_num;
}


- (Boolean)findRecord:(struct s_tr_find_params*)ps_find_params
{
  FindParamsPtr ps_sys_find_params;
  MemHandle pv_item;
  struct s_transaction *ps_tr;
  struct s_account_prop *ps_prop;
  struct s_rec_options s_options;
  FOREACH_SPLIT_DECL; // __uh_num et ps_cur_split
  UInt32 ui_pos;
  UInt16 uh_num, index, uh_check, uh_split = 0;

  UInt16 uh_field = 0, uh_match_len = 0;
  Boolean b_done = false;

  ps_sys_find_params = ps_find_params->ps_sys_find_params;

  uh_num = DmNumRecords(self->db);
  for (index = ps_sys_find_params->recordNum; index < uh_num; index++)
  {
    // On ne recherche pas tout d'un coup au cas où l'utilisateur veut
    // interrompre la recherche
    // Tous les 32 enregistrements
    if ((index & 0x001f) == 0 && EvtSysEventAvail(true))
    {
      // Stop the search process
      ps_sys_find_params->more = true;
      return true;
    }

    pv_item = DmQueryRecord(self->db, index);
    if (pv_item != NULL)
    {
      ui_pos = -1;

      ps_tr = MemHandleLock(pv_item);

      // Propriétés d'un compte
      if (DateToInt(ps_tr->s_date) == 0)
      {
	ps_prop = (struct s_account_prop*)ps_tr;

	// Recherche d'un nombre AVEC égalité stricte
	if (ps_find_params->b_find_num && ps_find_params->h_sign == 0)
	{
	  // Pas de signe présent
	  if (ps_find_params->b_signed == false)
	  {
	    // Les numéros de chèque
	    for (uh_check = 0; uh_check < NUM_CHECK_BOOKS; uh_check++)
	    {
	      if (ps_prop->rui_check_books[uh_check] == 0)
		break;

	      if (ps_prop->rui_check_books[uh_check]
		  == ps_find_params->ui_int_num)
	      {
		uh_field = AccountPropChequebook1 + uh_check;
		goto found;
	      }
	    }
	  }

	  // Le solde initial (toujours en égalité exacte)
	  if (ps_prop->l_amount == ps_find_params->l_amount
	      // OU BIEN la recherche est signée ET on regarde l'opposé
	      || (ps_find_params->b_signed
		  && ps_prop->l_amount == - ps_find_params->l_amount))
	  {
	    uh_field = AccountPropInitialBalance;
	    goto found;
	  }
	}

	// Recherche de la chaîne

	// Dans le numéro de compte
	if (TxtGlueFindString(ps_prop->ra_number,
			      ps_sys_find_params->strToFind,
			      &ui_pos, &uh_match_len))
	{
	  uh_field = AccountPropAccountNum;
	  goto found;
	}

	// Dans la note
	if (TxtGlueFindString(ps_prop->ra_note,
			      ps_sys_find_params->strToFind,
			      &ui_pos, &uh_match_len))
	{
	  LocalID ui_lid;
	  UInt32 ui_custom;
	  UInt16 uh_card_no;

	  uh_field = AccountPropNote;

      found:
	  [self getCardNo:&uh_card_no andID:&ui_lid];

	  // Add the match to the find paramter block, if there is no
	  // room to display the match the following function will
	  // return true.
	  ui_custom = uh_match_len;
	  if (uh_field == OpSplitList)
	    ui_custom |= (UInt32)uh_split << 16; // Index de la sous-op

	  b_done = FindSaveMatch(ps_sys_find_params,
				 index,		// recordNum
				 ui_pos,	// matchPos
				 uh_field,	// fieldNum
				 ui_custom,	// matchCustom
				 uh_card_no, ui_lid);

	  if (b_done == false)
	  {
	    struct s_infos_from_find s_find;
	    RectangleType s_bounds;

	    // Get the bounds of the region where we will draw the results.
	    FindGetLineBounds(ps_sys_find_params, &s_bounds);

	    s_find.oTransactions = self;
	    s_find.ps_tr = ps_tr;
	    s_find.uh_db_idx = index; // Sert pour les propriétés du compte

	    trans_draw_record(&s_find, 0, 1, &s_bounds);

	    ps_sys_find_params->lineNumber++;
	  }
	}
      }
      // Une opération
      else
      {
	options_extract(ps_tr, &s_options);

	// Un nombre
	if (ps_find_params->b_find_num)
	{
	  // Égalité stricte
	  if (ps_find_params->h_sign == 0)
	  {
	    // Le signe est fixé
	    if (ps_find_params->b_signed)
	    {
	      // La somme exactement
	      if (ps_tr->l_amount == ps_find_params->l_amount)
	      {
		uh_field = OpAmount;
		goto found;
	      }

	      // Les sous-opérations
	      if (ps_tr->ui_rec_splits)
	      {
		FOREACH_SPLIT(&s_options)
		{
		  // La somme de toutes les sous-op est égale à la
		  // valeur absolue du montant de l'opération, donc si
		  // on a un débit, il faut inverser le signe de
		  // chaque sous-op avant de le comparer
		  if ((ps_tr->l_amount < 0
		       ? - ps_cur_split->l_amount : ps_cur_split->l_amount)
		      == ps_find_params->l_amount)
		  {
		    uh_field = EditSplitAmount;
		    uh_split = s_options.ps_splits->uh_num - __uh_num - 1;
		    goto found;
		  }
		}
	      }
	    }
	    // Signe libre (ps_find_params->l_amount forcément positif)
	    else
	    {
	      // La somme en positif ou négatif
	      if (ps_tr->l_amount == ps_find_params->l_amount
		  || ps_tr->l_amount == - ps_find_params->l_amount)
	      {
		uh_field = OpAmount;
		goto found;
	      }

	      // La somme dans la devise en positif ou négatif
	      if (ps_tr->ui_rec_currency
		  && (s_options.ps_currency->l_currency_amount
		      == ps_find_params->l_amount
		      || s_options.ps_currency->l_currency_amount
		      == - ps_find_params->l_amount))
	      {
		uh_field = OpCurrencyAmount;
		goto found;
	      }

	      // Le numéro de chèque si présent
	      if (ps_tr->ui_rec_check_num
		  && (s_options.ps_check_num->ui_check_num
		      == ps_find_params->ui_int_num))
	      {
		uh_field = OpCheckNum;
		goto found;
	      }

	      // Le numéro de relevé si présent
	      if (ps_tr->ui_rec_stmt_num
		  && (s_options.ps_stmt_num->ui_stmt_num
		      == ps_find_params->ui_int_num))
	      {
		uh_field = OpStatementNum;
		goto found;
	      }

	      // Les sous-opérations (uniquement pour l'égalité stricte)
	      if (ps_tr->ui_rec_splits)
	      {
		FOREACH_SPLIT(&s_options)
		{
		  // La somme de toutes les sous-op est égale à la
		  // valeur absolue du montant de l'opération, donc
		  // des sous-op peuvent être négatives
		  if (ABS(ps_cur_split->l_amount) == ps_find_params->l_amount)
		  {
		    uh_field = EditSplitAmount;
		    uh_split = s_options.ps_splits->uh_num - __uh_num - 1;
		    goto found;
		  }
		}
	      }	// splits
	    }
	  }
	  // Supérieur/Inférieur avec signe
	  else if (ps_find_params->b_signed)
	  {
	    // >+100	ok si S > 100
	    // >-100	ok si S appartient à ]-100; 0[
	    if (ps_find_params->h_sign > 0)
	    {
	      // La somme
	      if (ps_tr->l_amount > ps_find_params->l_amount
		  && (ps_find_params->l_amount > 0
		      || ps_tr->l_amount < 0))
	      {
		uh_field = OpAmount;
		goto found;
	      }

	      // La somme dans la devise
	      if (ps_tr->ui_rec_currency
		  && (s_options.ps_currency->l_currency_amount
		      > ps_find_params->l_amount
		      && (ps_find_params->l_amount > 0
			  || s_options.ps_currency->l_currency_amount < 0)))
	      {
		uh_field = OpCurrencyAmount;
		goto found;
	      }
	    }
	    // <+100	ok si S appartient à ]0; 100[
	    // <-100	ok si S < -100
	    else
	    {
	      // La somme
	      if (ps_tr->l_amount < ps_find_params->l_amount
		  && (ps_find_params->l_amount < 0
		      || ps_tr->l_amount > 0))
	      {
		uh_field = OpAmount;
		goto found;
	      }

	      // La somme dans la devise
	      if (ps_tr->ui_rec_currency
		  && (s_options.ps_currency->l_currency_amount
		      < ps_find_params->l_amount
		      && (ps_find_params->l_amount < 0
			  || s_options.ps_currency->l_currency_amount > 0)))
	      {
		uh_field = OpCurrencyAmount;
		goto found;
	      }	      
	    }
	  }
	  // Supérieur/Inférieur sans signe
	  else
	  {
	    t_amount l_abs_amount, l_abs_cur_amount = 0;

	    if (ps_tr->l_amount < 0)
	    {
	      l_abs_amount = - ps_tr->l_amount;

	      if (ps_tr->ui_rec_currency)
		l_abs_cur_amount = - s_options.ps_currency->l_currency_amount;
	    }
	    else
	    {
	      l_abs_amount = ps_tr->l_amount;

	      if (ps_tr->ui_rec_currency)
		l_abs_cur_amount = s_options.ps_currency->l_currency_amount;
	    }

	    // Inférieur à
	    if (ps_find_params->h_sign < 0)
	    {
	      // La somme
	      if (l_abs_amount < ps_find_params->l_amount)
	      {
		uh_field = OpAmount;
		goto found;
	      }

	      // La somme dans la devise
	      if (ps_tr->ui_rec_currency
		  && l_abs_cur_amount < ps_find_params->l_amount)
	      {
		uh_field = OpCurrencyAmount;
		goto found;
	      }

	      // Numéro de chèque si présent
	      if (ps_tr->ui_rec_check_num
		  && (s_options.ps_check_num->ui_check_num
		      < ps_find_params->ui_int_num))
	      {
		uh_field = OpCheckNum;
		goto found;
	      }

	      // Le numéro de relevé si présent
	      if (ps_tr->ui_rec_stmt_num
		  && (s_options.ps_stmt_num->ui_stmt_num
		      < ps_find_params->ui_int_num))
	      {
		uh_field = OpStatementNum;
		goto found;
	      }
	    }
	    // Supérieur à
	    else
	    {
	      // La somme
	      if (l_abs_amount > ps_find_params->l_amount)
	      {
		uh_field = OpAmount;
		goto found;
	      }

	      // La somme dans la devise
	      if (ps_tr->ui_rec_currency
		  && l_abs_cur_amount > ps_find_params->l_amount)
	      {
		uh_field = OpCurrencyAmount;
		goto found;
	      }

	      // Numéro de chèque si présent
	      if (ps_tr->ui_rec_check_num
		  && (s_options.ps_check_num->ui_check_num
		      > ps_find_params->ui_int_num))
	      {
		uh_field = OpCheckNum;
		goto found;
	      }

	      // Le numéro de relevé si présent
	      if (ps_tr->ui_rec_stmt_num
		  && (s_options.ps_stmt_num->ui_stmt_num
		      > ps_find_params->ui_int_num))
	      {
		uh_field = OpStatementNum;
		goto found;
	      }
	    }
	  }
	} // Un nombre

	// Recherche de la chaîne

	// Dans la note
	if (TxtGlueFindString(s_options.pa_note,
			      ps_sys_find_params->strToFind,
			      &ui_pos, &uh_match_len))
	{
	  uh_field = OpDesc;
	  goto found;
	}

	// Dans chaque sous-opération (uniquement description)
	if (ps_tr->ui_rec_splits)
	{
	  FOREACH_SPLIT(&s_options)
	  {
	    if (TxtGlueFindString(ps_cur_split->ra_desc,
				  ps_sys_find_params->strToFind,
				  &ui_pos, &uh_match_len))
	    {
	      uh_field = EditSplitDesc;
	      uh_split = s_options.ps_splits->uh_num - __uh_num - 1;
	      goto found;
	    }
	  }
	}
      }

      MemHandleUnlock(pv_item);

      if (b_done)
	break;
    }
  }

  return b_done;
}


// XXX TransForm.m/-repeatNumOccurences devrait utiliser cette fonction
Int16 repeat_num_occurences(struct s_rec_repeat *ps_repeat,
			    DateType s_orig_date, DateType s_new_date)
{
  UInt16 uh_occur;

  // La date de l'opération est supérieure à la date de fin
  if (DateToInt(s_orig_date) > DateToInt(s_new_date))
    return 0;

  switch (ps_repeat->uh_repeat_type)
  {
    // Toutes les N semaines
  case REPEAT_WEEKLY:
    uh_occur = (UInt16)((DateToDays(s_new_date) - DateToDays(s_orig_date))
			/ ((UInt32)ps_repeat->uh_repeat_freq * 7UL));
    break;

    // Tous les N mois
  case REPEAT_MONTHLY:
  case REPEAT_MONTHLY_END:
  {
    UInt16 uh_diff_year, uh_diff_month, uh_month_div;

    uh_diff_year = s_new_date.year - s_orig_date.year;

    if (uh_diff_year == 0)
      uh_diff_month = s_new_date.month - s_orig_date.month;
    else
      uh_diff_month = (12 - s_orig_date.month + s_new_date.month
		       + 12 * (uh_diff_year - 1));

    uh_month_div = 1;

    // À la fin de chaque mois
    if (ps_repeat->uh_repeat_type == REPEAT_MONTHLY_END)
    {
      if (uh_diff_month > 0 && (s_new_date.day < DaysInMonth(s_new_date.month,
							     s_new_date.year)))
	uh_diff_month--;
    }
    // Tous les N mois, le même jour
    else
    {
      if (uh_diff_month > 0 && s_new_date.day < s_orig_date.day)
	uh_diff_month--;

      uh_month_div = ps_repeat->uh_repeat_freq;
    }

    uh_occur = uh_diff_month / uh_month_div;
  }
  break;

  default:
    return 0;
  }

  return uh_occur;
}


Char *repeat_expand_note(Char *pa_note, UInt16 *puh_size,
			 UInt16 uh_inc, Boolean b_in_place)
{
  __label__ abort;
  Char *pa_base = pa_note;
  Char *pa_num;
  // Taille de la note \0 compris
  UInt16 uh_base_size = (puh_size == NULL) ? StrLen(pa_note) + 1 : *puh_size;
  UInt16 uh_size = uh_base_size;

  void alloc_returned_note(UInt16 uh_add)
  {
    // + uh_add au pire pour les caractères en plus
    Char *pa_new;

    NEW_PTR(pa_new, uh_base_size + uh_add, goto abort);

    // On recopie la note (\0 compris)
    MemMove(pa_new, pa_base, uh_base_size);

    pa_num = pa_new + (pa_num - pa_base);
    pa_note = pa_new + (pa_note - pa_base);

    pa_base = pa_new;
    b_in_place = true;
  }

  // On regarde s'il y a un index à incrémenter dans la description
  // (NN) ou (NN/...
  while ((pa_note = StrChr(pa_note, '(')) != NULL)
  {
    UInt16 uh_num = 0;
    UInt16 uh_mul = 1;
    UInt16 uh_wchr_len;
    WChar wa_chr;

    pa_note += TxtGlueGetNextChar(pa_note, 0, NULL);
    pa_num = pa_note;

    for (;;)
    {
      uh_wchr_len = TxtGlueGetNextChar(pa_note, 0, &wa_chr);
      pa_note += uh_wchr_len;

      switch (wa_chr)
      {
      case '0' ... '9':
	// Too big number
	if (uh_mul == 10000)
	  goto abort;

	uh_num *= 10;
	uh_num += wa_chr - '0';

	uh_mul *= 10;
	break;

      case ')':
      case '/':
	// No char between the 2 parenthesis
	if (uh_mul == 1)
	  goto abort;

	// On ne peut pas modifier sur place, il faut faire une recopie
	if (b_in_place == false)
	  alloc_returned_note(5);

	uh_num += uh_inc;

	// The increment add at least a char, so we have to shift
	// right the note end
	if (uh_num >= uh_mul)
	{
	  UInt16 uh_shift = 0;

	  // Il faut décaler de 1 c'est sûr, mais peut-être faut-il
	  // décaler encore plus. C'est ce qu'on recherche ici.
	  // Si 99 => 100 : shift=0
	  // Si 8  => 124 : shift=1
	  // Si 8  => 23  : shift=0
	  uh_mul *= 10;
	  while (uh_num > uh_mul)
	  {
	    uh_mul *= 10;
	    uh_shift++;
	  }

	  MemMove(pa_note + uh_shift, pa_note - 1,
		  StrLen(pa_note) + 1 + 1); // With (')' or '/') and '\0'

	  uh_size += 1 + uh_shift;
	}

	StrUInt32ToA(pa_num, uh_num, &uh_mul);
	pa_num[uh_mul] = wa_chr; // Override the \0

	// continue => repeat_inc_done

      case '\0':
	goto repeat_inc_done;

      default:
	// We are just after the opening parenthesis, test to see
	// if a month follows
	if (uh_mul == 1)
	{
	  // En mode TxtGlueFindString ajoute 164 octets de code
#define REPEAT_TXTGLUEFINDSTRING	0
	  Char ra_month[32];
	  Char ra_find[REPEAT_TXTGLUEFINDSTRING ? 32 : sizeof(WChar)*2];
#if REPEAT_TXTGLUEFINDSTRING
	  UInt32 ui_pos;
#else
	  UInt16 uh_month_match_len;
#endif
	  UInt16 uh_month_list, index, uh_find_len;
	  Int16 h_month_len;
	  WChar wa_close;

	  for (uh_month_list = strLongMonths;
	       uh_month_list <= strShortMonths;
	       uh_month_list++)
	  {
	    for (index = 0; index < 12; index++)
	    {
	      SysStringByIndex(uh_month_list, index,
			       ra_month, sizeof(ra_month));

#if REPEAT_TXTGLUEFINDSTRING
	      TxtGluePrepFindString(ra_month, ra_find, sizeof(ra_find));

	      if (TxtGlueFindString(pa_note - uh_wchr_len,
				    ra_find, &ui_pos, &uh_find_len)
		  && ui_pos == 0)
#else
		h_month_len = StrLen(ra_month);
	      if (TxtGlueCaselessCompare(pa_note - uh_wchr_len,
					 StrLen(pa_note - uh_wchr_len),
					 &uh_find_len,
					 ra_month, h_month_len,
					 &uh_month_match_len) == 0
		  || h_month_len == uh_month_match_len)
#endif
	      {
		// if (TxtGlueGetChar(pa_note,
		//			  uh_find_len - uh_wchr_len) == ')')
		// Mais 124 octets de plus...

		TxtGlueGetNextChar(pa_note, uh_find_len - uh_wchr_len,
				   &wa_close);
		if (wa_close == ')')
		{
		  index += uh_inc;
		  index %= 12;

		  SysStringByIndex(uh_month_list, index,
				   ra_month, sizeof(ra_month));

		  // Le premier caractère du mois est en majuscule
		  if (TxtCharIsUpper(wa_chr))
		  {
		    // TxtGlueGetChar(pa_note, 0) mais 122 octets de plus
		    TxtGlueGetNextChar(pa_note, 0, &wa_chr);

		    // Le 2ème car. est en majuscule, on passe tout en maj
		    if (TxtCharIsUpper(wa_chr))
		      TxtGlueUpperStr(ra_month, sizeof(ra_month) - 1);
		  }
		  // Le 1er car. est en minuscule, on DE-capitalise
		  // car la liste des mois est capitalisée
		  // TxtGlueLowerChar ne gère pas les caractères multi
		  // alors on est obligé de gérer ça à la main...
		  else
		  {
		    UInt16 uh_up_size, uh_low_size;

		    uh_up_size = TxtGlueGetNextChar(ra_month, 0, &wa_chr);

		    TxtGlueSetNextChar(ra_find, 0, wa_chr);
		    ra_find[uh_up_size] = '\0';
		    TxtGlueLowerStr(ra_find, sizeof(ra_find) - 1);

		    uh_low_size = TxtGlueGetNextChar(ra_find, 0, &wa_chr);

		    if (uh_up_size != uh_low_size)
		      MemMove(ra_month + uh_low_size,
			      ra_month + uh_up_size,
			      StrLen(ra_month + uh_up_size) + 1); // \0

		    TxtGlueSetNextChar(ra_month, 0, wa_chr);
		  }

		  h_month_len = StrLen(ra_month);

		  pa_note -= uh_wchr_len;

		  // On ne peut pas modifier sur place, il faut faire
		  // une recopie
		  if (b_in_place == false)
		    alloc_returned_note(30);

		  MemMove(pa_note + h_month_len, pa_note + uh_find_len,
			  StrLen(pa_note + uh_find_len) + 1); // With \0

		  MemMove(pa_note, ra_month, h_month_len);

		  uh_size -= (Int16)uh_find_len - h_month_len;

		  goto repeat_inc_done;
		}
	      }
	    } // for (index)
	  }	// for (uh_month_list)
	}
	goto abort;
      }
    }

abort:
    ;
  }
 repeat_inc_done:

  if (puh_size != NULL)
    *puh_size = uh_size;

  return pa_base;
}


//
// Renvoie l'index de l'opération créée si l'opération a été répétée,
// 0 sinon
- (UInt16)updateRepeatOfId:(UInt16)index onMaxDays:(UInt32)ui_max_days
{
  MemHandle vh_rec;
  struct s_transaction *ps_tr;
  UInt16 uh_repeated_index = 0;

  vh_rec = DmQueryRecord(self->db, index);
  if (vh_rec == NULL)
    return 0;

  ps_tr = MemHandleLock(vh_rec);

  // Propriétés de compte...
  if (DateToInt(ps_tr->s_date) == 0)
    goto done;

  /* Cet enregistrement doit être répété */
  if (ps_tr->ui_rec_repeat)
  {
    struct s_rec_options s_options;
    struct s_rec_repeat *ps_repeat;
    UInt32 ui_next_days;
    DateType s_next_date;

    options_extract(ps_tr, &s_options);

    ps_repeat = s_options.ps_repeat;

    /* Calcul de la date du futur enregistrement */
    s_next_date = ps_tr->s_date;
    switch (ps_repeat->uh_repeat_type)
    {
    case REPEAT_WEEKLY:
      // Prochaine date en jours
      ui_next_days = DateToDays(s_next_date) + ps_repeat->uh_repeat_freq * 7;

      // Le prochain jour
      DateDaysToDate(ui_next_days, &s_next_date);
      break;

    case REPEAT_MONTHLY:
    case REPEAT_MONTHLY_END:
    default:
    {
      UInt16 uh_new_month, uh_days;

      /* X mois de plus (l'année peut changer...) */
      uh_new_month
	= (s_next_date.month - 1 + ps_repeat->uh_repeat_freq) % 12 + 1;

      s_next_date.year +=
	ps_repeat->uh_repeat_freq / 12 + (uh_new_month < s_next_date.month);

      s_next_date.month = uh_new_month;

      /* Nombre de jours dans ce mois */
      uh_days = DaysInMonth(s_next_date.month, s_next_date.year + firstYear);

      /* Le dernier jour de chaque mois */
      if (ps_repeat->uh_repeat_type == REPEAT_MONTHLY_END
	  /* OU BIEN jour invalide pour ces mois/année */
	  || s_next_date.day > uh_days)
	s_next_date.day = uh_days;

      // Prochaine date en jours
      ui_next_days = DateToDays(s_next_date);
    }
    break;
    }	/* switch (ps_repeat->uh_repeat_type) */

    /* S'il y a une date de fin de répétition */
    if (DateToInt(ps_repeat->s_date_end) != 0
	/* ET que cette date est avant la date suivante */
	&& DateToDays(ps_repeat->s_date_end) < ui_next_days)
    {
      // On ôte l'info...
      if ([self deleteRepeatOption:index] == false)
	FrmAlert(alertCantSave);

      goto done;
    }

    /* Date suivante trop lointaine */
    if (ui_next_days > ui_max_days)
      goto done;
    
    /* Il y a répétition
     * - On crée un nouvel enregistrement avec la date changée
     *   ET la même info de répétition
     * - On sauve l'enregistrement courant sans son info de répétition
     */
    {
      struct s_transaction *ps_new_tr;
      UInt16 uh_size;
      UInt16 uh_link_index;
      UInt16 uh_category;
      Int16 h_xfer_category;

      /* Chargement de la catégorie de l'enregistrement */
      DmRecordInfo(self->db, index, &uh_category, NULL, NULL);
      uh_category &= dmRecAttrCategoryMask;

      /*
       * Sauvegarde du nouvel enregistrement avec l'info de répétition
       */

      uh_size = MemHandleSize(vh_rec);

      // + 30 en cas d'incrément (N) => (NN) ou (mois) => (mois plus long)
      NEW_PTR(ps_new_tr, uh_size + 30, goto done);

      MemMove(ps_new_tr, ps_tr, uh_size);

      /* On n'a plus besoin du chunk original */
      MemHandleUnlock(vh_rec); /* Il faut libérer le chunk avant... */
      vh_rec = NULL;		 /* Pour éviter de le re-libérer */

      options_extract(ps_new_tr, &s_options);

      // Suppression du numéro de relevé
      if (ps_new_tr->ui_rec_stmt_num)
      {
	options_edit(ps_new_tr, &s_options, NULL, OPT_STMT_NUM);
	uh_size -= sizeof(struct s_rec_stmt_num);
      }

      // Suppression du numéro de chèque
      if (ps_new_tr->ui_rec_check_num)
      {
	options_edit(ps_new_tr, &s_options, NULL, OPT_CHECK_NUM);
	uh_size -= sizeof(struct s_rec_check_num);
      }

      // Suppression de la date de valeur
      if (ps_new_tr->ui_rec_value_date)
      {
	options_edit(ps_new_tr, &s_options, NULL, OPT_VALUE_DATE);
	uh_size -= sizeof(struct s_rec_value_date);
      }

      /* Cet enregistrement contient un transfert */
      h_xfer_category = -1;
      uh_link_index = dmMaxRecordIndex; // Opération liée
      if (ps_new_tr->ui_rec_xfer)
      {
	// ID de categorie
	if (ps_new_tr->ui_rec_xfer_cat)
	{
	  h_xfer_category = s_options.ps_xfer->ul_id;
	  ps_new_tr->ui_rec_xfer_cat = 0; // On va pointer vers une opér.
	}
	// Unique ID
	else if (DmFindRecordByID(self->db, s_options.ps_xfer->ul_id,
				  &uh_link_index) == 0)
	{
	  DmRecordInfo(self->db, uh_link_index, &h_xfer_category, NULL, NULL);
	  h_xfer_category &= dmRecAttrCategoryMask;
	}
      }

      // Changement de la date ET pas pointé, ni marqué
      ps_new_tr->s_date = s_next_date;
      ps_new_tr->ui_rec_flags &= ~(RECORD_CHECKED|RECORD_MARKED);

      // On regarde s'il y a un index à incrémenter dans la description
      // (NN) ou (NN/ ou bien un mois (janvier)...
      repeat_expand_note(s_options.pa_note, &uh_size, 1, true);

      // Sauvegarde, sans gestion particulière de l'alarme, puisque si
      // l'opération à répéter a le flag d'alarme, alors elle échoiera
      // forcément avant ses répétitions.
      uh_repeated_index = dmMaxRecordIndex;
      if ([self save:ps_new_tr size:uh_size
		asId:&uh_repeated_index
		account:uh_category
		xferAccount:h_xfer_category] == false)
      {
	FrmAlert(alertCantSave);
	MemPtrFree(ps_new_tr);

	return 0;		// Pas goto done, car le Unlock est déjà fait
      }

      MemPtrFree(ps_new_tr);

      /*
       * On retire l'info de répétition de l'enregistrement courant
       * puis on le sauvegarde...
       */
      [self deleteRepeatOption:index];

      /* Si l'enregistrement répété est un transfert, on ôte l'info
	 de transfert sur son lien. Ainsi lorsqu'on arrivera dessus,
	 rien ne se passera. */
      if (uh_link_index != dmMaxRecordIndex)
	[self deleteRepeatOption:uh_link_index];
    }
  }

 done:
  if (vh_rec)
    MemHandleUnlock(vh_rec);

  return uh_repeated_index;
}


//
// Calcule toutes les répétitions découlant de l'opération d'index uh_index
- (Boolean)computeRepeatsOfId:(UInt16)uh_index
{
  UInt32 ui_max_days;
  UInt16 uh_alert_modulo = 32;
  UInt16 uh_num = 0;
  DateType s_today;

  // Cette méthode ne fonctionne que lorsque l'exécution des
  // répétitions automatique est activée dans les préférences de la
  // base
  if (self->ps_prefs->ul_auto_repeat == 0)
    return false;

  DateSecondsToDate(TimGetSeconds(), &s_today);
  ui_max_days = DateToDays(s_today) + self->ps_prefs->ul_repeat_days;

  while ((uh_index = [self updateRepeatOfId:uh_index onMaxDays:ui_max_days]) >0)
  {
    uh_num++;

    if (uh_num % uh_alert_modulo == 0)
    {
      if (FrmAlert(alertTooManyRepeats) == 0)
	break;

      // On avertit de moins en moins souvent
      uh_alert_modulo <<= 1;
    }
  }

  return uh_num > 0;
}


//
// Calcule les répétitions de toutes les opérations de la base
- (Boolean)computeAllRepeats:(Boolean)b_force onMaxDays:(UInt32)ui_max_days
{
  struct s_db_sortinfos s_db_sortinfos;
  UInt16 uh_blk_size = sizeof(struct s_db_sortinfos);
  UInt16 uh_loop;
  DateType s_today;

  DateSecondsToDate(TimGetSeconds(), &s_today);

  [self sortInfoBlockLoad:(void**)&s_db_sortinfos size:&uh_blk_size
	flags:INFOBLK_DIRECTZONE];

  uh_loop = 0;

  // On force le calcul des répétitions
  if (b_force
      // OU BIEN la dernière fois qu'on a calculé les répétitions ce
      // n'était pas aujourd'hui
      || DateToInt(s_db_sortinfos.s_last_repeat_date) < DateToInt(s_today))
  {
    UInt16 uh_num;
    UInt16 uh_alert_modulo = 8;
    UInt16 uh_min_index = 0, uh_cur_min_index;
    UInt16 uh_new_index;
    UInt16 index, uh_num_records;

    if (ui_max_days == 0)
      ui_max_days = DateToDays(s_today) + self->ps_prefs->ul_repeat_days;

    for (;;)
    {
      PROGRESSBAR_DECL;

      // On parcourt les éléments de la fin vers le début... */
      uh_num = 0;
      uh_cur_min_index = uh_min_index;
      index = uh_num_records = DmNumRecords(self->db);

      PROGRESSBAR_BEGIN(uh_num_records - uh_cur_min_index,
			strProgressBarRepeats, uh_loop + 1);
      uh_num_records--;

      for (; index-- > uh_cur_min_index; )
      {
	uh_new_index = [self updateRepeatOfId:index onMaxDays:ui_max_days];
	if (uh_new_index > 0)
	{
	  uh_num++;

	  if (uh_new_index < uh_min_index)
	    uh_min_index = uh_new_index;
	}

	PROGRESSBAR_INLOOP(uh_num_records - index, 50);	// OK
      }

      PROGRESSBAR_END;

      uh_loop++;

      if (uh_num == 0)
	break;

      if (uh_loop % uh_alert_modulo == 0)
      {
	if (FrmAlert(alertTooManyRepeats) == 0)
	  break;

	// On avertit de moins en moins souvent
	uh_alert_modulo <<= 1;
      }
    }

    // Pour ne pas recommencer aujourd'hui...
    s_db_sortinfos.s_last_repeat_date = s_today;
    [self sortInfoBlockSave:&s_db_sortinfos size:sizeof(s_db_sortinfos)];
  }

  return uh_loop > 0;
}


// On ôte l'info de numéro de relevé de l'enregistrement
- (Boolean)deleteStmtNumOption:(UInt16)uh_index
{
  MemHandle pv_rec;
  struct s_transaction *ps_tr;

  pv_rec = DmQueryRecord(self->db, uh_index);
  if (pv_rec == NULL)
    return false;

  ps_tr = MemHandleLock(pv_rec);

  if (ps_tr->ui_rec_stmt_num)
  {
    struct s_rec_options s_options;
    Char *pa_buf;
    union u_rec_flags u_flags;
    UInt16 uh_size, uh_offset;

    options_extract(ps_tr, &s_options);

    // Taille de la zone située après l'info de numéro de relevé
    uh_size = (s_options.pa_note - (Char*)(s_options.ps_stmt_num + 1)
	       + StrLen(s_options.pa_note) + 1); // Dont \0

    NEW_PTR(pa_buf, uh_size, ({ MemHandleUnlock(pv_rec); return false; }));

    MemMove(pa_buf, s_options.ps_stmt_num + 1, uh_size);

    MemHandleUnlock(pv_rec);

    // Juste différence de pointeur pas besoin de lock ici
    uh_offset = (Char*)s_options.ps_stmt_num - (Char*)ps_tr;

    ps_tr = [self recordResizeId:uh_index newSize:uh_offset + uh_size];

    DmWrite(ps_tr, uh_offset, pa_buf, uh_size);

    // On retire le numéro de relevé des flags
    u_flags = ps_tr->u_flags;
    u_flags.s_bit.ui_stmt_num = 0;
    DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
	    &u_flags, sizeof(u_flags));

    [self recordRelease:true];

    MemPtrFree(pa_buf);

    return true;
  }

  MemHandleUnlock(pv_rec);

  return false;
}


- (Boolean)addStmtNumOption:(UInt32)ui_stmt_num forId:(UInt16)uh_index
{
  MemHandle pv_rec;
  struct s_transaction *ps_tr;
  struct s_rec_options s_options;

  pv_rec = DmQueryRecord(self->db, uh_index);
  if (pv_rec == NULL)
    return false;

  ps_tr = MemHandleLock(pv_rec);

  // Il faut modifier la partie numéro de relevé
  if (ps_tr->ui_rec_stmt_num)
  {
    MemHandleUnlock(pv_rec);

    ps_tr = [self recordGetAtId:uh_index];
    if (ps_tr == NULL)
      return false;
  }
  else
  {
    Char *pa_buf;
    union u_rec_flags u_flags;
    UInt16 uh_size, uh_total_size;

    options_extract(ps_tr, &s_options);

    uh_size = StrLen(s_options.pa_note) + 1; // Avec \0
    uh_total_size = s_options.pa_note - (Char*)ps_tr + uh_size;

    // On prend en compte la devise car elle suit l'option de numéro
    // de relevé
    if (s_options.ps_currency != NULL)
      uh_size += sizeof(*s_options.ps_currency);

    // On prend en compte les sous-opérations car elles suivent
    // l'option de numéro de relevé
    if (s_options.ps_splits != NULL)
      uh_size += sizeof(*s_options.ps_splits) + s_options.ps_splits->uh_size;

    // On alloue une zone correspondant à toutes les options qui
    // suivent celle qu'on veut supprimer
    NEW_PTR(pa_buf, uh_size, ({ MemHandleUnlock(pv_rec); return false; }));

    MemMove(pa_buf, (Char*)ps_tr + uh_total_size - uh_size, uh_size);
    u_flags = ps_tr->u_flags;

    MemHandleUnlock(pv_rec);

    uh_total_size += sizeof(ui_stmt_num);

    ps_tr = [self recordResizeId:uh_index newSize:uh_total_size];
    if (ps_tr == NULL)
    {
      MemPtrFree(pa_buf);
      return false;
    }

    // On crée la place pour l'option devise
    DmWrite(ps_tr, uh_total_size - uh_size, pa_buf, uh_size);

    MemPtrFree(pa_buf);

    // Désormais il y a une option numéro de relevé
    u_flags.s_bit.ui_stmt_num = 1;
    DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
	    &u_flags, sizeof(u_flags));
  }

  options_extract(ps_tr, &s_options);

  // Mise en place de la devise passée en paramètre
  DmWrite(ps_tr, (Char*)s_options.ps_stmt_num - (Char*)ps_tr,
	  &ui_stmt_num, sizeof(ui_stmt_num));

  [self recordRelease:true];

  return true;
}


// Si ui_stmt_num == 0, pas de numéro de relevé ajouté
- (Boolean)changeFlaggedToChecked:(UInt32)ui_stmt_num
{
  struct s_transaction *ps_tr;
  PROGRESSBAR_DECL;
  UInt32 ui_flags;
  UInt16 uh_account = self->ps_prefs->ul_cur_category;
  UInt16 uh_record_num = 0;
  Boolean b_modified, b_one_modified = false;

  PROGRESSBAR_BEGIN(DmNumRecords(self->db), strProgressBarFlaggedToCleared);

  while (DmQueryNextInCategory(self->db, &uh_record_num, uh_account) != NULL)
  {
    // Marche même si l'opération est les propriétés du compte
    ps_tr = [self recordGetAtId:uh_record_num];
    if (ps_tr != NULL)
    {
      b_modified = ps_tr->ui_rec_marked;
      if (b_modified)
      {
	ui_flags = ps_tr->ui_rec_flags;
	ui_flags &= ~RECORD_MARKED;
	ui_flags |= RECORD_CHECKED;

	DmWrite(ps_tr, offsetof(struct s_transaction, ui_rec_flags),
		&ui_flags, sizeof(ui_flags));

	b_one_modified = true;
      }

      [self recordRelease:b_modified];

      // Il y a un numéro de relevé à mettre en place ET on vient de
      // pointer l'opération
      if (ui_stmt_num != 0 && b_modified)
	[self addStmtNumOption:ui_stmt_num forId:uh_record_num];
    }

    PROGRESSBAR_INLOOP(uh_record_num, 50); // OK

    uh_record_num++;	/* Suivant */
  }

  PROGRESSBAR_END;

  return b_one_modified;
}


////////////////////////////////////////////////////////////////////////
//
// Saving item
//
////////////////////////////////////////////////////////////////////////

- (UInt16)getSavePositionFor:(struct s_transaction*)ps_tr at:(UInt16)uh_index
{
  MemHandle pv_rec;
  struct s_transaction *ps_cur;
  DmComparF *pf_cmp;
  UInt16 uh_last_num, uh_num;

  // En fonction du tri choisi
  if ([self getPrefs]->ul_sort_type == SORT_BY_DATE)
    pf_cmp = (DmComparF*)transaction_std_cmp;
  else
    pf_cmp = (DmComparF*)transaction_val_date_cmp;

  // Modification d'un enregistrement : si la date est restée la même
  // l'enregistrement garde la même place...
  if (uh_index != dmMaxRecordIndex)
  {
    pv_rec = DmQueryRecord(self->db, uh_index); /* PAS DE TEST */
    ps_cur = MemHandleLock(pv_rec);

    // Les date/heure n'ont pas bougé
    if (pf_cmp(ps_cur, ps_tr, 0, NULL, NULL, NULL) == 0)
    {
      MemHandleUnlock(pv_rec);
      return uh_index;
    }

    MemHandleUnlock(pv_rec);
  }

  uh_last_num = uh_num = DmNumRecords(self->db);

  while (uh_num-- > 0)
  {
    if (uh_num != uh_index
        && (pv_rec = DmQueryRecord(self->db, uh_num)) != NULL)
    {
      ps_cur = MemHandleLock(pv_rec);

      if (pf_cmp(ps_cur, ps_tr, 0, NULL, NULL, NULL) < 0)
      {
	MemHandleUnlock(pv_rec);
	break;
      }

      MemHandleUnlock(pv_rec);
    }

    uh_last_num--;
  }

  return uh_last_num;
}


/*
 * Renvoie true si sauvegarde ok, false sinon
 *				SAUVEGARDE
 *		   v-------------+      +--------v
 *		nouveau			      existant
 *	   v-----+   +-----v		v-----+    +-----v
 *    1.avec xfer     2.sans xfer    avec xfer	    6.sans xfer
 *				v-----+     +-----v
 *			    existant	     5.nouveau
 *		       v-----+    +-----v
 *	     3.encore présent	  4.enr lié absent
 *         3.1.uniqueID inconnu
 *
 * ps_tr	  : pointeur sur les données à sauver
 * uh_size	  : taille des données à sauver
 * puh_index	  : pointeur sur la position, contenu modifié au retour
 *		    (dmMaxRecordIndex si nouvelle opération)
 * h_account	  : catégorie de l'enregistrement (-1 si pas de changement)
 * h_xfer_account : catégorie de l'enregistrement lié (-1 sauf pour cas 1 & 5)
 */
- (Boolean)save:(struct s_transaction*)ps_tr size:(UInt16)uh_size
	   asId:(UInt16*)puh_index
	account:(Int16)h_account xferAccount:(Int16)h_xfer_account
{
  struct s_rec_options s_options;
  UInt16 uh_index;
  Boolean b_new;

  b_new = (*puh_index == dmMaxRecordIndex);

  // Recherche de la position d'insertion
  uh_index = [self getSavePositionFor:ps_tr at:*puh_index];

  // Modification d'enregistrement ET changement de place
  if (b_new == false && *puh_index != uh_index)
  {
    DmMoveRecord(self->db, *puh_index, uh_index);
    if (uh_index > *puh_index)
      --uh_index;
  }

  if ([super save:ps_tr size:uh_size asId:&uh_index asNew:b_new] == false)
  {
    // XXX
    return false;
  }

  if (h_account >= 0)
    [self setCategory:h_account forId:uh_index];
  else
  {
    // On n'a pas le compte de l'opération, on le récupère...
    DmRecordInfo(self->db, uh_index, &h_account, NULL, NULL);
    h_account &= dmRecAttrCategoryMask;
  }

  // Il y a un transfert (cas 1, 3, 4, 5), ça se complique
  // Si cas 4, il n'y a rien à faire, l'enregistrement lié n'existe plus
  if ((ps_tr->ui_rec_flags & (RECORD_XFER|RECORD_XFER_CAT)) == RECORD_XFER)
  {
    struct s_transaction *ps_tr_link;
    UInt16 uh_currency, uh_link_currency;
    UInt16 uh_link_index, uh_link_size;

    // Devise du compte de l'opération sauvée
    uh_currency = [self accountCurrency:h_account];

    options_extract(ps_tr, &s_options);

    // Cas 1, il faut créer l'enregistrement lié
    //		 Cas 5, il faut créer l'enregistrement lié aussi
    if (b_new || h_xfer_account >= 0)
    {
      void *pv_add;
      UInt32 ul_id;

      // Devise du compte de l'opération liée
      uh_link_currency = [self accountCurrency:h_xfer_account];

      uh_link_size = uh_size;

      // On ne copie pas la date de valeur
      if (ps_tr->ui_rec_value_date)
	uh_link_size -= sizeof(struct s_rec_value_date);

      // On ne copie pas le numéro de chèque
      if (ps_tr->ui_rec_check_num)
	uh_link_size -= sizeof(struct s_rec_check_num);

      // On ne copie pas le numéro de relevé
      if (ps_tr->ui_rec_stmt_num)
	uh_link_size -= sizeof(struct s_rec_stmt_num);

      // Il n'y a pas encore de devise...
      if (ps_tr->ui_rec_currency == 0)
      {
	// mais il va y en avoir une
	if (uh_currency != uh_link_currency)
	  uh_link_size += sizeof(struct s_rec_currency);
      }
      // Il y a une devise, mais elle va disparaître
      else if (uh_currency == uh_link_currency)
	uh_link_size -= sizeof(struct s_rec_currency);

      // On ne copie pas les sous-opérations
      if (ps_tr->ui_rec_splits)
	uh_link_size -= (sizeof(struct s_rec_sub_transaction)
			 + s_options.ps_splits->uh_size);

      NEW_PTR(ps_tr_link, uh_link_size, return false /* XXX */);

      // La base de l'opération est la même (à peu de choses près)
      MemMove(ps_tr_link, ps_tr, sizeof(*ps_tr));

      // L'alarme, le pointage/marquage, l'alarme, la date de valeur,
      // le no de chèque et le numéro de relevé disparaissent. Il n'y
      // a pas de sous-opérations dans le cas d'un transfert.
      ps_tr_link->ui_rec_flags &= ~(RECORD_CHECKED|RECORD_MARKED|RECORD_ALARM
				    |RECORD_VALUE_DATE|RECORD_CHECK_NUM
				    |RECORD_STMT_NUM|RECORD_SPLITS
				    |RECORD_INTERNAL_FLAG);

      pv_add = ps_tr_link->ra_note;

      // On a une info de répétition : on la recopie
      if (ps_tr->ui_rec_repeat)
      {
	MemMove(pv_add, s_options.ps_repeat, sizeof(struct s_rec_repeat));
	pv_add += sizeof(struct s_rec_repeat);
      }

      // L'info de transfert : toujours présente évidemment
      DmRecordInfo(self->db, uh_index, NULL, &ul_id, NULL);
      ((struct s_rec_xfer*)pv_add)->ul_id = ul_id;
      ((struct s_rec_xfer*)pv_add)->ul_reserved = 0;
      pv_add += sizeof(struct s_rec_xfer);

      // La devise des deux comptes est la même
      if (uh_currency == uh_link_currency)
      {
	// Bizarre on a laissé passé une devise !!!
	// Il ne devrait pas y avoir de devise présente dans le cas où
	// les 2 comptes ont la même
	if (ps_tr->ui_rec_currency)
	{
	  // On la supprime
	  [self deleteCurrencyOption:uh_index];
	  alert_error_str("delete currency coz xfer has same (1,5 case)");
	}

	ps_tr_link->ui_rec_currency = 0; // Pas de devise...

	// La somme liée devient l'opposé de la somme originale
	ps_tr_link->l_amount = - ps_tr->l_amount;
      }
      // La devise des deux comptes n'est pas la même, il faut
      // rajouter l'option devise
      else
      {
	Currency *oCurrencies = [oMaTirelire currency];
	struct s_rec_currency *ps_link_currency;

	// L'opération originale a déjà une devise
	if (ps_tr->ui_rec_currency)
	{
	  // La devise de l'opération originale ne correspond pas à la
	  // devise du compte à lier : ce n'est pas normal !!!
	  // On corrige la partie devise pour que ça colle...
	  if (s_options.ps_currency->ui_currency != uh_link_currency)
	  {
	    if ([oCurrencies
		  convertAmount:&s_options.ps_currency->l_currency_amount
		  fromId:s_options.ps_currency->ui_currency
		  toId:uh_link_currency] != 0)
	    {
	      // La devise de l'opération originale n'existe pas (à
	      // priori il s'agit d'elle car uh_link_currency est une
	      // devise principale de compte, donc elle existe
	      // forcément)
	      alert_error_str("Unknown currency %d (or %d?) (1,5 case)",
			      (UInt16)s_options.ps_currency->ui_currency,
			      uh_link_currency);
	      goto new_currency_1;
	    }

	    s_options.ps_currency->ui_currency = uh_link_currency;

	    // On sauve les modifications
	    [self addCurrencyOption:s_options.ps_currency forId:uh_index];
	  }

	  // La somme liée devient l'opposé de la devise
	  ps_tr_link->l_amount = - s_options.ps_currency->l_currency_amount;
	}
	// Il faut créer la devise chez tout le monde
	else
	{
	  struct s_rec_currency s_currency;

      new_currency_1:
	  MemSet(&s_currency, sizeof(s_currency), '\0');

	  // Ici les devises existent forcément : devises principales de compte
	  s_currency.l_currency_amount = ps_tr->l_amount;
	  [oCurrencies convertAmount:&s_currency.l_currency_amount
		       fromId:uh_currency
		       toId:uh_link_currency];

	  s_currency.ui_currency = uh_link_currency;

	  // On sauve les modifications dans l'opération originale
	  [self addCurrencyOption:&s_currency forId:uh_index];

	  // La somme de l'opération liée devient l'opposé de la devise
	  ps_tr_link->l_amount = - s_currency.l_currency_amount;
	  ps_tr_link->ui_rec_currency = 1; // Il y a une devise !!!
	}

	// La partie devise de l'opération liée
	ps_link_currency = pv_add;

	MemSet(ps_link_currency, sizeof(*ps_link_currency), '\0');
	
	ps_link_currency->l_currency_amount = - ps_tr->l_amount;
	ps_link_currency->ui_currency = uh_currency;

	pv_add += sizeof(struct s_rec_currency);
      }

      //
      // La note... (avec \0)
      MemMove(pv_add, s_options.pa_note, StrLen(s_options.pa_note) + 1);

      // On sauvegarde l'opération liée
      uh_link_index = uh_index + 1;
      [super save:ps_tr_link size:uh_link_size asId:&uh_link_index asNew:true];

      [self setCategory:h_xfer_account forId:uh_link_index];

      // On demande le unique ID du lien
      DmRecordInfo(self->db, uh_link_index, NULL, &ul_id, NULL);

      // Modification dans l'enregistrement original
      [self changeXferOption:ul_id forId:uh_index];

      MemPtrFree(ps_tr_link);
    } // Fin cas 1 et 5
    // Cas 3, il faut modifier l'enregistrement lié
    else if (DmFindRecordByID(self->db,
			      s_options.ps_xfer->ul_id, &uh_link_index) == 0)
    {
      struct s_transaction *ps_tr_link, *ps_new_link;
      struct s_rec_options s_link_options;

      // Chargement du contenu du lien
      ps_tr_link = [self getId:uh_link_index];
      if (ps_tr_link == NULL)
      {
	alert_error_str("delete xfer coz id %ld / idx %d not loadable",
			s_options.ps_xfer->ul_id, uh_link_index);
	goto delete_xfer_option;
      }

      uh_link_size = MemPtrSize(ps_tr_link);

      // En pire cas, il y aura assez de place
      NEW_PTR(ps_new_link, uh_link_size + uh_size - sizeof(*ps_tr),
	      return false /* XXX */);

      // Recopie de l'enregistrement lié
      MemMove(ps_new_link, ps_tr_link, uh_link_size);

      [self getFree:ps_tr_link];

      // Compte de l'opération liée
      DmRecordInfo(self->db, uh_link_index, &h_xfer_account, NULL, NULL);
      h_xfer_account &= dmRecAttrCategoryMask;

      // Devise du compte de l'opération liée
      uh_link_currency = [self accountCurrency:h_xfer_account];

      // Modification de la date et de l'heure
      ps_new_link->s_date = ps_tr->s_date;
      ps_new_link->s_time = ps_tr->s_time;

      // options_edit() appelera automatiquement options_extract()
      s_link_options.pa_note = NULL;

      // Info de répétition ? Si absente, s_options.ps_repeat vaut NULL
      options_edit(ps_new_link, &s_link_options,
		   s_options.ps_repeat, OPT_REPEAT);

      // Modification des flags mode et type
      ps_new_link->ui_rec_mode = ps_tr->ui_rec_mode;
      ps_new_link->ui_rec_type = ps_tr->ui_rec_type;

      // La devise des deux comptes est la même
      if (uh_currency == uh_link_currency)
      {
	// Bizarre on a laissé passé une devise !!!
	// Il ne devrait pas y avoir de devise présente dans le cas où
	// les 2 comptes ont la même
	if (ps_tr->ui_rec_currency)
	{
	  // On la supprime
	  [self deleteCurrencyOption:uh_index];
	  alert_error_str("delete currency coz xfer has same (3 case)");
	}

	// Pas de devise dans le lien non plus
	options_edit(ps_new_link, &s_link_options, NULL, OPT_CURRENCY);

	// La somme liée devient l'opposé de la somme originale
	ps_new_link->l_amount = - ps_tr->l_amount;
      }
      // La devise des deux comptes n'est pas la même, il faut
      // rajouter l'option devise
      else
      {
	Currency *oCurrencies = [oMaTirelire currency];
	struct s_rec_currency s_currency;

	MemSet(&s_currency, sizeof(s_currency), '\0');

	// L'opération originale a déjà une devise
	if (ps_tr->ui_rec_currency)
	{
	  // La devise de l'opération originale ne correspond pas à la
	  // devise du compte à lier : ce n'est pas normal !!!
	  // On corrige la partie devise pour que ça colle...
	  if (s_options.ps_currency->ui_currency != uh_link_currency)
	  {
	    if ([oCurrencies
		  convertAmount:&s_options.ps_currency->l_currency_amount
		  fromId:s_options.ps_currency->ui_currency
		  toId:uh_link_currency] != 0)
	    {
	      // La devise de l'opération originale n'existe pas (à
	      // priori il s'agit d'elle car uh_link_currency est une
	      // devise principale de compte, donc elle existe
	      // forcément)
	      alert_error_str("Unknown currency %d (or %d?) (3 case)",
			      (UInt16)s_options.ps_currency->ui_currency,
			      uh_link_currency);
	      goto new_currency_2;
	    }

	    s_options.ps_currency->ui_currency = uh_link_currency;

	    // On sauve les modifications
	    [self addCurrencyOption:s_options.ps_currency forId:uh_index];
	  }

	  // La somme liée devient l'opposé de la devise
	  ps_new_link->l_amount = - s_options.ps_currency->l_currency_amount;
	}
	// Il faut créer la devise chez tout le monde
	else
	{
      new_currency_2:
	  // Ici les devises existent forcément : devises principales de compte
	  s_currency.l_currency_amount = ps_tr->l_amount;
	  [oCurrencies convertAmount:&s_currency.l_currency_amount
		       fromId:uh_currency
		       toId:uh_link_currency];

	  s_currency.ui_currency = uh_link_currency;

	  // On sauve les modifications dans l'opération originale
	  [self addCurrencyOption:&s_currency forId:uh_index];

	  // La somme de l'opération liée devient l'opposé de la devise
	  ps_new_link->l_amount = - s_currency.l_currency_amount;
	}

	// La partie devise de l'opération liée
	s_currency.l_currency_amount = - ps_tr->l_amount;
	s_currency.ui_currency = uh_currency;

	options_edit(ps_new_link, &s_link_options, &s_currency, OPT_CURRENCY);
      }

      // Modification de la note
      uh_link_size = options_edit(ps_new_link, &s_link_options,
				  s_options.pa_note, OPT_NOTE);

      [super save:ps_new_link size:uh_link_size
	     asId:&uh_link_index asNew:false];

      MemPtrFree(ps_new_link);

      // Si l'original a changé de place, l'opération liée doit le suivre...
      if (*puh_index != uh_index)
      {
	UInt16 uh_new_pos;

	// On conserve l'ordre : le lien était après l'original
	if (uh_link_index > *puh_index)
	{
	  uh_new_pos = uh_index + 1; // Juste après

	  // L'ancienne position était avant l'original maintenant
	  if (uh_link_index <= uh_index)
	    uh_index--;
	}
	// Le lien était avant l'original
	else
	{
	  uh_new_pos = uh_index; // Juste avant

	  // L'ancienne position était après l'original maintenant
	  if (uh_link_index >= uh_index)
	    uh_index++;
	}

	DmMoveRecord(self->db, uh_link_index, uh_new_pos);
      }
    }
    // Cas 3.1, Enregistrement lié non trouvé
    else
    {
      alert_error_str("delete xfer coz unknown id %ld",
		      s_options.ps_xfer->ul_id);

      // On supprime l'option Xfer
  delete_xfer_option:
      [self deleteXferOption:uh_index];
    }
  }
  // else : Cas 2, 4, 6 ok

  // On sauve l'index de l'enregistrement
  *puh_index = uh_index;

  return true;
}


- (Transaction*)clone:(Char*)pa_clone_name
{
  Transaction *oTransactions;

  oTransactions = [super clone:pa_clone_name];

  // Il faut recalculer les alarmes
  if (oTransactions != nil)
    alarm_schedule_all();

  return oTransactions;
}


////////////////////////////////////////////////////////////////////////
//
// Deleting item
//
////////////////////////////////////////////////////////////////////////

//
// Si le flag TRANS_DELETE_ID_LINK_TOO est présent, supprime également
// l'opération liée s'il s'agit d'un transfert.
// Renvoie le nombre d'opérations supprimées dans le compte de
// l'opération uh_index (donc 2 si l'opération liée se trouve dans le
// même compte)
- (Int16)deleteId:(UInt32)ui_index
{
  MemHandle pv_prop;
  struct s_transaction *ps_tr;
  UInt16 uh_deleted = 1;
  UInt16 uh_index;
  UInt32 ui_delete_mode;
  Boolean b_no_more_alarm = false;

  // Le mode de suppression dépend des préférences de la base...
  if (self->ps_prefs->ul_remove_type == DM_REMOVE_RECORD)
    ui_delete_mode = DBITEM_DEL_REMOVE;
  else
    ui_delete_mode = DBITEM_DEL_DELETE;

  uh_index = ui_index & 0xffff;

  pv_prop = DmQueryRecord(self->db, uh_index);
  if (pv_prop != NULL)
  {
    ps_tr = MemHandleLock(pv_prop);

    // Pas les propriétés d'un compte
    if (DateToInt(ps_tr->s_date) != 0)
    {
      // Opération liée avec une autre opération
      if ((ps_tr->ui_rec_flags & (RECORD_XFER|RECORD_XFER_CAT)) == RECORD_XFER)
      {
	struct s_rec_options s_options;
	UInt16 uh_link_index;

	options_extract(ps_tr, &s_options);

	// Il faut trouver le lien !!!
	if (DmFindRecordByID(self->db,
			     s_options.ps_xfer->ul_id, &uh_link_index) == 0)
	{
	  // Il faut supprimer le lien
	  if (ui_index & TR_DEL_XFER_LINK_TOO)
	  {
	    UInt16 uh_orig_cat, uh_link_cat;

	    // On regarde la catégorie de l'enregistrement qu'on va supprimer
	    // si c'est la même que celle du lien, le nombre d'enregistrements
	    // supprimés renvoyé sera 2
	    DmRecordInfo(self->db, uh_index, &uh_orig_cat, NULL, NULL);
	    DmRecordInfo(self->db, uh_link_index, &uh_link_cat, NULL, NULL);
	    if ((uh_orig_cat & dmRecAttrCategoryMask)
		== (uh_link_cat & dmRecAttrCategoryMask))
	      uh_deleted++;

	    // Il faut gérer les alarmes...
	    if (ui_index & TR_DEL_MANAGE_ALARM)
	      b_no_more_alarm |= alarm_schedule_transaction(self->db,
							    uh_link_index,
							    true);

	    if ([super deleteId:ui_delete_mode | uh_link_index] > 0)
	    {
	      // L'opération a été réellement supprimée (DmRemoveRecord)

	      // Si le lien est avant, l'index de l'original doit être
	      // décrémenté car l'enregistrement est enlevé de la base ce
	      // qui n'est pas le cas de DmDeleteRecord
	      if (uh_link_index < uh_index)
		uh_index--;
	    }
	  }
	  // Il faut modifier le lien pour lui supprimer son option
	  // transfert (flag utilisé lors de la suppression d'un compte)
	  else if (ui_index & TR_DEL_XFER_LINK_PART)
	  {
	    if ([self deleteXferOption:uh_link_index] == false)
	    {
	      // XXX
	    }
	  }
	  // Il faut modifier le lien pour le faire pointer sur la
	  // catégorie de l'original
	  else
	  {
	    struct s_transaction *ps_link_tr;
	    union u_rec_flags u_flags;
	    UInt32 ul_id;
	    UInt16 uh_attr;

	    // Catégorie de l'original
	    DmRecordInfo(self->db, uh_index, &uh_attr, NULL, NULL);
	    ul_id = (uh_attr & dmRecAttrCategoryMask);

	    ps_link_tr = [self recordGetAtId:uh_link_index];
	    if (ps_link_tr != NULL)
	    {
	      options_extract(ps_link_tr, &s_options);

	      // On écrit la catégorie de transfert
	      DmWrite(ps_link_tr, (Char*)s_options.ps_xfer - (Char*)ps_link_tr,
		      &ul_id, sizeof(ul_id));

	      // On met le flag "transfert sur catégorie"
	      u_flags = ps_link_tr->u_flags;
	      u_flags.s_bit.ui_xfer_cat = 1;
	      DmWrite(ps_link_tr, offsetof(struct s_transaction, u_flags),
		      &u_flags, sizeof(u_flags));

	      [self recordRelease:true];
	    }
	  }
	}
      }

      // S'il faut gérer les alarmes, MAIS que le flag d'alarme n'est
      // pas présent, ça ne servira à rien d'appeler
      // alarm_schedule_transaction() 10 lignes plus bas
      if (ps_tr->ui_rec_alarm == 0)
	ui_index &= ~TR_DEL_MANAGE_ALARM;
    }

    MemHandleUnlock(pv_prop);

    // Il faut gérer les alarmes...
    if (ui_index & TR_DEL_MANAGE_ALARM)
      b_no_more_alarm |= alarm_schedule_transaction(self->db, uh_index, true);
  }

  [super deleteId:ui_delete_mode | uh_index];

  // La dernière alarme a disparu, il faut rechercher la nouvelle
  if (b_no_more_alarm)
  {
    if (ui_index & TR_DEL_DONT_RESCHED_ALARM)
      return TR_DEL_MUST_RESCHED_ALARM | uh_deleted;

    alarm_schedule_all();
  }

  return uh_deleted;
}


//
// Supprime le compte et toutes ses opérations de la base
- (void)deleteAccount:(UInt16)uh_account
{
  MemHandle pv_prop;
  struct s_transaction *ps_tr;
  PROGRESSBAR_DECL;
  UInt16 uh_index = 0, uh_total, uh_reschedule_alarm = 0;
  Boolean b_use_conduit;

  // Pour la barre de progression
  b_use_conduit = self->ps_prefs->ul_remove_type;

  uh_total = DmNumRecords(self->db);

  PROGRESSBAR_BEGIN((UInt32)uh_total * 2, strProgressBarDeleteAccount1);

  // Pour chaque opération (on n'incrémente jamais uh_index puisqu'on
  // supprime au fur et à mesure)
  while (DmQueryNextInCategory(self->db, &uh_index, uh_account) != NULL) // PG
  {
    // Alarme OK
    uh_reschedule_alarm |= [self deleteId:((UInt32)uh_index
					   | TR_DEL_XFER_LINK_PART
					   | TR_DEL_MANAGE_ALARM
					   | TR_DEL_DONT_RESCHED_ALARM)];

    PROGRESSBAR_INLOOP(uh_index, 25); // OK

    // Si l'opération est supprimée immédiatement : pas d'inc. de index
    if (b_use_conduit == false)
    {
      // Comme on fait deux passes avec la même barre de progression,
      // la suppression d'un enregistrement => 2 en moins...
      PROGRESSBAR_DECMAX_VAL(2);
      uh_total--;
    }
    else
      uh_index++;
  }

  // Suppression du compte du AppInfoBlock
  CategorySetName(self->db, uh_account, NULL);

  // On parcourt toutes les opérations pour supprimer les liens
  // restant vers ce compte (via xfer_cat)
  PROGRESSBAR_LABEL(strProgressBarDeleteAccount2);

  for (uh_index = 0; uh_index < uh_total; uh_index++)
  {
    pv_prop = DmQueryRecord(self->db, uh_index);
    if (pv_prop != NULL)
    {
      ps_tr = MemHandleLock(pv_prop);

      // Pas une propriété de compte ET opération liée à un compte
      if (DateToInt(ps_tr->s_date) != 0 && ps_tr->ui_rec_xfer_cat)
      {
	struct s_rec_options s_options;

	options_extract(ps_tr, &s_options);

	// Opération liée à CE compte qui est maintenant supprimé !
	if (s_options.ps_xfer->ul_id == uh_account)
	{
	  MemHandleUnlock(pv_prop);

	  // On supprime l'option xfer de cette opération
	  if ([self deleteXferOption:uh_index] == false)
	  {
	    // XXX
	  }

	  goto next;
	}
      }

      MemHandleUnlock(pv_prop);
    }

 next:
    PROGRESSBAR_INLOOP((UInt32)uh_total + (UInt32)uh_index, 25); // OK
  }

  PROGRESSBAR_END;

  // On place la prochaine alarme, car elle vient d'être
  // désactivée par un des -deleteId: qui ont précédé
  if (uh_reschedule_alarm & TR_DEL_MUST_RESCHED_ALARM)
    alarm_schedule_all();
}


static Int16 _accounts_list_id_compare(UInt8 *pua_acc1, UInt8 *pua_acc2,
				       Int32 l_db)
{
  Char ra_acc1[dmCategoryLength], ra_acc2[dmCategoryLength];
  DmOpenRef db = (DmOpenRef)l_db;

  CategoryGetName(db, *pua_acc1, ra_acc1);
  CategoryGetName(db, *pua_acc2, ra_acc2);

  return StrCaselessCompare(ra_acc1, ra_acc2);
}

- (Char**)listBuildInfos:(void*)pv_infos num:(UInt16*)puh_num
		 largest:(UInt16*)puh_largest
{
  struct s_tr_accounts_list *ps_infos = pv_infos;
  struct __s_list_accounts_buf *ps_buf;
  Char ra_account[dmCategoryLength];
  UInt16 index, uh_num, uh_width, uh_largest, uh_len;

  NEW_PTR(ps_buf, sizeof(*ps_buf), return NULL);

  MemSet(ps_buf, sizeof(*ps_buf), '\0');

  // Cas de la liste de checkbox
  ps_buf->uh_checked_width = 0;
  if (ps_infos->uh_checked_accounts)
  {
    FontID uh_save_font = FntSetFont(symbol11Font);

    ps_buf->uh_checked_width = FntCharWidth(symbolCheckboxOn) + 5;

    FntSetFont(uh_save_font);

    ps_buf->uh_checked_accounts = ps_infos->uh_checked_accounts;
  }

  uh_largest = 0;
  uh_num = 0;

  // Les ID des comptes
  for (index = 0; index < MAX_ACCOUNTS; index++)
    if (index != ps_infos->h_skip_account)
    {
      CategoryGetName(self->db, index, ra_account);
      if (ra_account[0] != '\0')
      {
	ps_buf->rua_accounts_id[uh_num++] = index;

	uh_width = (ps_buf->uh_checked_width
		    + FntCharsWidth(ra_account, StrLen(ra_account)));
	if (uh_width > uh_largest)
	  uh_largest = uh_width;
      }
    }

  ps_buf->oItem = self;
  ps_buf->uh_num_rec_entries = uh_num;
  ps_buf->uh_is_right_margin = 0;

  // On trie par ordre alphabetique
  SysInsertionSort(ps_buf->rua_accounts_id, uh_num,
		   sizeof(ps_buf->rua_accounts_id[0]),
		   (CmpFuncPtr)_accounts_list_id_compare, (Int32)self->db);

  // Première ligne
  if (ps_infos->ra_first_item[0] != '\0')
  {
    uh_len = StrLen(ps_infos->ra_first_item);

    uh_width = FntCharsWidth(ps_infos->ra_first_item, uh_len);
    if (uh_width > uh_largest)
      uh_largest = uh_width;

    MemMove(ps_buf->ra_first_item, ps_infos->ra_first_item, uh_len + 1); // \0

    uh_num++;
  }

  // Dernière ligne
  if (ps_infos->uh_last > 0)
  {
    // S'il y a une ligne en dernière position, il y a peut-être une
    // en avant dernière ?
    if (ps_infos->uh_before_last > 0)
    {
      load_and_fit(ps_infos->uh_before_last,
		   ps_buf->ra_before_last_item, &uh_largest);
      uh_num++;
    }

    load_and_fit(ps_infos->uh_last, ps_buf->ra_last_item, &uh_largest);
    uh_num++;
  }

  if (uh_num == 0)
  {
    MemPtrFree(ps_buf);
    ps_buf = NULL;
  }

  *puh_num = uh_num;
  *puh_largest = uh_largest;

  return (Char**)ps_buf;
}


static void __list_accounts_draw(Int16 h_line, RectangleType *prec_bounds,
				 Char **ppa_lines)
{
  RectangleType s_bounds;
  struct __s_list_accounts_buf *ps_buf;
  Char *pa_account;
  Int16  h_upperline = 0;

  ps_buf = (struct __s_list_accounts_buf*)ppa_lines;

  // Ce popup a une entrée avant les comptes
  if (ps_buf->ra_first_item[0] != '\0')
  {
    // On doit justement afficher cette première ligne : "Any" entry
    if (h_line == 0)
    {
      pa_account = ps_buf->ra_first_item;

      // Un séparateur en dessous seulement si au moins un compte
      // suit....  (ça peut être le cas dans TransForm pour le popup
      // des comptes de transfert s'il n'y a qu'un compte dans la
      // base)
      if (ps_buf->uh_num_rec_entries > 0)
	h_upperline = -1;

      goto draw_it;
    }

    // Sinon on déc. l'index pour coller au tableau de correspondance idx->id
    h_line--;
  }

  if (h_line >= ps_buf->uh_num_rec_entries)
  {
    pa_account = ps_buf->ra_last_item;

    if (h_line == ps_buf->uh_num_rec_entries)
    {
      h_upperline = 1;		// Un séparateur au dessus (systématique)

      // Il y a une avant dernière ligne...
      if (ps_buf->ra_before_last_item[0] != '\0')
	pa_account = ps_buf->ra_before_last_item;
    }

    goto draw_it;
  }
  // L'entrée sélectionnée est un compte
  else
  {
    Char ra_account[dmCategoryLength];
    UInt16 uh_account_id;

    uh_account_id = ps_buf->rua_accounts_id[h_line];

    // Il faut dessiner une checkbox en debut de ligne
    if (ps_buf->uh_checked_accounts)
    {
      FontID uh_old_font;
      Char a_cbox = (ps_buf->uh_checked_accounts & (1 << uh_account_id)) != 0;

      uh_old_font = FntSetFont(symbol11Font);
      WinDrawChars(&a_cbox, 1, prec_bounds->topLeft.x, prec_bounds->topLeft.y);
      FntSetFont(uh_old_font);

      // On ne modifie pas directement les données pointées car sur
      // certains OS (au moins 2.0), elles ne sont pas remises à neuf
      // d'une ligne sur l'autre
      s_bounds.topLeft.x = prec_bounds->topLeft.x + ps_buf->uh_checked_width;
      s_bounds.topLeft.y = prec_bounds->topLeft.y;
      s_bounds.extent.x = prec_bounds->extent.x - ps_buf->uh_checked_width;
      s_bounds.extent.y = prec_bounds->extent.y;

      prec_bounds = &s_bounds;
    }

    CategoryGetName(ps_buf->oItem->db, uh_account_id, ra_account);

    pa_account = ra_account;

 draw_it:
    list_line_draw(0, prec_bounds, &pa_account);
  }

  if (h_upperline)
    list_line_draw_line(prec_bounds, h_upperline);
}


- (ListDrawDataFuncPtr)listDrawFunction
{
  return __list_accounts_draw;
}


// h_account :
// - 0 - 15 compte à sélectionner
// - -1     première entrée si ra_first_item[0], aucune sinon
- (VoidHand)popupListInit:(UInt16)uh_list_id
		     form:(BaseForm*)oForm
		    infos:(struct s_tr_accounts_list*)ps_infos
	  selectedAccount:(UInt16)uh_account
{
  VoidHand pv_list;
  struct __s_accounts_popup_list *ps_list;
  RectangleType s_rect;

  NEW_HANDLE(pv_list, sizeof(struct __s_accounts_popup_list), return NULL);

  ps_list = MemHandleLock(pv_list);

  ps_list->oForm = oForm;

  ps_list->uh_list_idx = FrmGetObjectIndex(oForm->pt_frm, uh_list_id);
  ps_list->uh_popup_idx = FrmGetObjectIndex(oForm->pt_frm, uh_list_id - 1);
  if (ps_list->uh_popup_idx == frmInvalidObjectId
      || FrmGetObjectType(oForm->pt_frm, ps_list->uh_popup_idx)
         != frmControlObj)
    ps_list->uh_popup_idx = 0;

  ps_list->uh_id = uh_account;	// ACC_POPUP_FIRST si première entrée

  ps_list->pt_list = FrmGetObjectPtr(oForm->pt_frm, ps_list->uh_list_idx);

  // Initialisation de la liste
  [self _popupListInit:ps_list infos:ps_infos];

  // On charge la largeur max du popup
  // Coordonnées du popup
  if (ps_list->uh_popup_idx != 0)
  {
    FrmGetObjectBounds(oForm->pt_frm, ps_list->uh_popup_idx, &s_rect);
    // -15 à gauche pour le "v" ET -3 à droite pour les espaces de fin
    ps_list->uh_popup_width = s_rect.extent.x - 15 - 3;
  }

  // Le label du popup
  [self _popupListSetLabel:ps_list];

  // Sélectionne l'item correspondant à l'ID
  [self _popupListSetSelection:ps_list];

  // Le callback de remplissage de la liste
  LstSetDrawFunction(ps_list->pt_list, __list_accounts_draw);

  MemHandleUnlock(pv_list);

  return pv_list;
}


- (UInt16)popupList:(VoidHand)pv_list firstIsValid:(Boolean)b_first_valid
{
  struct __s_accounts_popup_list *ps_list;
  UInt16 uh_item, uh_saved_id;

  ps_list = MemHandleLock(pv_list);

  uh_saved_id = ps_list->uh_id;

  uh_item = LstPopupList(ps_list->pt_list);

  // Il y a une sélection
  if (uh_item != noListSelection)
  {
    // Si on a une première entrée
    if (ps_list->ps_buf->ra_first_item[0] != '\0')
    {
      // Et en plus c'est celle là qu'on vient de sélectionner !
      if (uh_item == 0)
      {
	uh_item = ACC_POPUP_FIRST;

	// La première entrée est une entrée valide (sélectionnable)
	if (b_first_valid)
	  goto commit;
	  
	// Il faut resélectionner la bonne entrée pour la prochaine ouverture
	[self _popupListSetSelection:ps_list];

	goto end;
      }

      uh_item--;
    }

    // On vient de sélectionner un compte
    if (uh_item < ps_list->ps_buf->uh_num_rec_entries)
    {
      uh_item = ps_list->ps_buf->rua_accounts_id[uh_item];

      // Si on est en mode checkbox
      if (ps_list->ps_buf->uh_checked_accounts)
      {
	UInt16 uh_actual = ps_list->ps_buf->uh_checked_accounts;

	if (uh_actual & (1 << uh_item))
	{
	  uh_actual &= ~(1 << uh_item);

	  // On ne peut pas tout désactiver
	  if (uh_actual == 0)
	    uh_actual = ps_list->ps_buf->uh_checked_accounts;
	}
	else
	  uh_actual |= (1 << uh_item);

	ps_list->ps_buf->uh_checked_accounts = uh_actual;

	LstSetSelection(ps_list->pt_list, 0); // Sélection de la 1ère entrée

	// Pour passer le if () qui suit le commit:....
	uh_saved_id = -1;
      }
    }
    // Le dernier ou l'avant-dernier...
    else
    {
      // Il y a un avant dernier et c'est lui
      if (uh_item == ps_list->ps_buf->uh_num_rec_entries
	  && ps_list->ps_buf->ra_before_last_item[0] != '\0')
	uh_item = ACC_POPUP_BEFORE_LAST;
      // Sinon c'est le dernier
      else
	uh_item = ACC_POPUP_LAST;

      // Il faut resélectionner la bonne entrée pour la prochaine ouverture
      [self _popupListSetSelection:ps_list];

      goto end;
    }

 commit:
    if (uh_item != uh_saved_id)
    {
      ps_list->uh_id = uh_item;

      // Label du popup
      [self _popupListSetLabel:ps_list];
    }
  }

 end:
  MemHandleUnlock(pv_list);

  return uh_item;
}


//
// Retourne l'ID sélectionné ou (item unknown) ou ITEM_ANY
- (UInt16)popupListGet:(VoidHand)pv_list
{
  struct __s_accounts_popup_list *ps_list;
  UInt16 uh_id;

  ps_list = MemHandleLock(pv_list);

  if (ps_list->ps_buf->uh_checked_accounts != 0)
    uh_id = ps_list->ps_buf->uh_checked_accounts;
  else
    uh_id = ps_list->uh_id;

  MemHandleUnlock(pv_list);

  return uh_id;
}


//
// Au type de la structure près, identique à la même méthode de DBItemId
- (void)popupList:(VoidHand)pv_list setSelection:(UInt16)uh_id
{
  struct __s_accounts_popup_list *ps_list;

  ps_list = MemHandleLock(pv_list);

  if (ps_list->ps_buf->uh_checked_accounts != 0)
  {
    UInt16 index = ps_list->ps_buf->uh_num_rec_entries;
    UInt16 uh_all_accounts = 0;

    // On garde juste les comptes présents
    while (index-- > 0)
      uh_all_accounts |= 1 << ps_list->ps_buf->rua_accounts_id[index];

    ps_list->ps_buf->uh_checked_accounts = uh_id & uh_all_accounts;

    // On ne peut pas tout désactiver
    if (ps_list->ps_buf->uh_checked_accounts == 0)
      ps_list->ps_buf->uh_checked_accounts
	= 1 << ps_list->ps_buf->rua_accounts_id[0];
  }
  else
  {
    ps_list->uh_id = uh_id;
    [self _popupListSetSelection:ps_list];
  }

  [self _popupListSetLabel:ps_list];

  MemHandleUnlock(pv_list);
}


//
// Libère tout ce qui a été alloué...
- (void)popupListFree:(VoidHand)pv_list
{
  [self->oIsa classPopupListFree:pv_list];
}


//
// Libère tout ce qui a été alloué...
+ (void)classPopupListFree:(VoidHand)pv_list
{
  if (pv_list != NULL)
  {
    struct __s_accounts_popup_list *ps_list = MemHandleLock(pv_list);

    MemPtrFree(ps_list->ps_buf);

    MemHandleUnlock(pv_list);

    MemHandleFree(pv_list);
  }
}


- (void)_popupListInit:(struct __s_accounts_popup_list*)ps_list
		 infos:(struct s_tr_accounts_list*)ps_infos
{
  RectangleType s_rect;
  UInt16 uh_largest, uh_screen_width, uh_dummy;

  ps_list->ps_buf =
    (struct __s_list_accounts_buf*)[self listBuildInfos:ps_infos
					 num:&ps_list->uh_num
					 largest:&uh_largest];

  LstSetHeight(ps_list->pt_list, ps_list->uh_num);

  uh_largest += LIST_MARGINS_NO_SCROLL;

  // On initialise la liste et on regarde s'il y a ou non une flèche
  // de scroll dans la marge de droite
  if ([self rightMarginList:ps_list->pt_list num:ps_list->uh_num
	    in:(struct __s_list_dbitem_buf*)ps_list->ps_buf selItem:-1])
    uh_largest += LIST_MARGINS_WITH_SCROLL - LIST_MARGINS_NO_SCROLL;

  // On s'adapte à la largeur de l'écran
  WinGetDisplayExtent(&uh_screen_width, &uh_dummy);
  if (uh_largest > uh_screen_width - LIST_EXTERNAL_BORDERS)
    uh_largest = uh_screen_width - LIST_EXTERNAL_BORDERS;

  // On remet la liste à la bonne position (avec une largeur adéquate)
  FrmGetObjectBounds(ps_list->oForm->pt_frm, ps_list->uh_list_idx, &s_rect);
  s_rect.extent.x = uh_largest;
  FrmSetObjectBounds(ps_list->oForm->pt_frm, ps_list->uh_list_idx, &s_rect);
}


- (void)_popupListSetLabel:(struct __s_accounts_popup_list*)ps_list
{
  // Seulement si il y a effectivement un bouton popup...
  if (ps_list->uh_popup_idx > 0)
  {
    if (ps_list->ps_buf->uh_checked_accounts != 0)
    {
      struct
      {
	Char ra_name[dmCategoryLength];
	UInt16 uh_len:4;
	UInt16 uh_truncate:1;
	UInt16 uh_width:11;
      } rs_accounts[MAX_ACCOUNTS], *ps_account;
      UInt16 index, uh_num_accounts, uh_largest, uh_checked_accounts;
      UInt16 uh_total_width, uh_total_len, uh_sep_width, uh_ell_width;
      Char *pa_final, a_ell;

      uh_checked_accounts = ps_list->ps_buf->uh_checked_accounts;

      uh_sep_width = FntCharWidth(',');

      a_ell = ellipsis(&uh_ell_width);

      uh_total_width = - uh_sep_width;
      uh_total_len = 0;		// Pas -1 car ici on compte le \0 de fin
      uh_num_accounts = 0;
      uh_largest = 0;
      ps_account = rs_accounts;
      for (index = 0; index < MAX_ACCOUNTS; index++)
	if (uh_checked_accounts & (1 << index))
	{
	  CategoryGetName(self->db, index, ps_account->ra_name);

	  ps_account->uh_len = StrLen(ps_account->ra_name);
	  ps_account->uh_truncate = 0;
	  ps_account->uh_width = FntCharsWidth(ps_account->ra_name,
					       ps_account->uh_len);

	  uh_total_width += ps_account->uh_width + uh_sep_width;
	  uh_total_len += ps_account->uh_len + 1; // + 1 pour la ',' ou le \0

	  if (ps_account->uh_len > uh_largest)
	    uh_largest = ps_account->uh_len;

	  ps_account++;
	  uh_num_accounts++;
	}

      // On trie les comptes dans l'ordre alphabétique
      if (uh_num_accounts > 1)
	SysInsertionSort(rs_accounts, uh_num_accounts,
			 sizeof(rs_accounts[0]),
			 (CmpFuncPtr)sort_string_compare, 0);

      if (uh_total_width <= ps_list->uh_popup_width)
	goto ok;

      // Un seul c'est plus facile
      if (uh_num_accounts == 1)
      {
	truncate_name(rs_accounts[0].ra_name, &uh_largest,
		      ps_list->uh_popup_width, rs_accounts[0].ra_name);

	rs_accounts[0].uh_len = uh_largest;
	uh_total_width = 0;	// La réduction vient d'être faite
      }
      else
      {
	UInt16 uh_char_width;
	WChar wa_prev;

	do
	{
	  // Pour chaque compte, on réduit jusqu'à que tout rentre...
	  ps_account = rs_accounts;
	  for (index = uh_num_accounts; index-- > 0; ps_account++)
	    // Le nom du compte doit être tronqué
	    if (ps_account->uh_len >= uh_largest)
	    {
	      uh_char_width = TxtGlueGetPreviousChar(ps_account->ra_name,
						     ps_account->uh_len,
						     &wa_prev);
	      ps_account->uh_len -= uh_char_width;
	      uh_total_len -= uh_char_width;

	      // Il n'y a pas encore de '...'
	      if (ps_account->uh_truncate == 0)
	      {
		uh_total_len++;
		uh_total_width += uh_ell_width;
		ps_account->uh_truncate = 1;
	      }

	      uh_total_width -= ps_account->uh_width;
	      ps_account->uh_width = FntCharsWidth(ps_account->ra_name,
						   ps_account->uh_len);
	      uh_total_width += ps_account->uh_width;

	      // POPUPTRIGGER STR(100) ID StatsFromAccountsPopup
	      if (uh_total_width <= ps_list->uh_popup_width
		  && uh_total_len <= 100 + 1) // + 1 car \0 est dans total_len
		goto ok;
	    }
	}
	while (--uh_largest > 3); // On laisse au moins 3 caractère / compte
      }
  ok:
      // On utilise la zone des comptes pour tout regrouper
      ps_account = rs_accounts;

      pa_final = ps_account->ra_name;

      // Toujours pas la place, on affiche juste le nombre de comptes
      if (uh_total_width > ps_list->uh_popup_width)
      {
	Char *pa_format = rs_accounts[MAX_ACCOUNTS / 2].ra_name;

	SysCopyStringResource(pa_format, strStatsNAccounts);
	StrPrintF(pa_final, pa_format, uh_num_accounts);
      }
      // On concatène les comptes
      else
      {
	index = 0;
	goto dont_copy_first;
	for (; index < uh_num_accounts; index++, ps_account++)
	{
	  MemMove(pa_final, ps_account->ra_name, ps_account->uh_len);
      dont_copy_first:

	  pa_final += ps_account->uh_len;

	  if (ps_account->uh_truncate)
	    *pa_final++ = a_ell;

	  *pa_final++ = ',';
	}

	pa_final[-1] = '\0';
      }

      [ps_list->oForm fillLabel:FrmGetObjectId(ps_list->oForm->pt_frm,
					       ps_list->uh_popup_idx)
	      withSTR:rs_accounts[0].ra_name];
    }
    else
    {
      Char ra_account[dmCategoryLength], *pa_entry;

      // Première entrée
      if (ps_list->uh_id >= ACC_POPUP_FIRST)
	pa_entry = ps_list->ps_buf->ra_first_item;
      else
      {
	CategoryGetName(self->db, ps_list->uh_id, ra_account);
	pa_entry = ra_account;
      }

      [ps_list->oForm fillLabel:FrmGetObjectId(ps_list->oForm->pt_frm,
					       ps_list->uh_popup_idx)
	      withSTR:pa_entry];
    }
  }
}


//
// En fonction de l'item sélectionné, sélectionne la bonne entrée dans
// la liste
- (void)_popupListSetSelection:(struct __s_accounts_popup_list*)ps_list
{
  UInt16 uh_item = 0;

  if (ps_list->ps_buf->uh_checked_accounts != 0)
    uh_item = noListSelection;
  else if (ps_list->uh_id < ACC_POPUP_FIRST)
  {
    UInt8 *pua_list2id;
    UInt16 uh_num_accounts = ps_list->ps_buf->uh_num_rec_entries;

    pua_list2id = ps_list->ps_buf->rua_accounts_id;

    for (uh_item = 0; uh_item < uh_num_accounts; uh_item++, pua_list2id++)
      if (*pua_list2id == ps_list->uh_id)
      {
	// Il y a une première entrée qu'il faut passer
	if (ps_list->ps_buf->ra_first_item[0] != '\0')
	  uh_item++;
	break;
      }
  }

  LstSetSelection(ps_list->pt_list, uh_item);
}

@end


void options_extract(struct s_transaction *ps_trans,
		     struct s_rec_options *ps_options)
{
  void *pv_base = ps_trans->ra_note;

  MemSet(ps_options, sizeof(*ps_options), '\0');

  // Date de valeur
  if (ps_trans->ui_rec_value_date)
  {
    ps_options->ps_value_date = pv_base;
    pv_base += sizeof(struct s_rec_value_date);
  }

  // Numéro de chèque
  if (ps_trans->ui_rec_check_num)
  {
    ps_options->ps_check_num = pv_base;
    pv_base += sizeof(struct s_rec_check_num);
  }

  // Répétition
  if (ps_trans->ui_rec_repeat)
  {
    ps_options->ps_repeat = pv_base;
    pv_base += sizeof(struct s_rec_repeat);
  }

  // Transfert
  if (ps_trans->ui_rec_xfer)
  {
    ps_options->ps_xfer = pv_base;
    pv_base += sizeof(struct s_rec_xfer);
  }

  // Numéro de relevé
  if (ps_trans->ui_rec_stmt_num)
  {
    ps_options->ps_stmt_num = pv_base;
    pv_base += sizeof(struct s_rec_stmt_num);
  }

  // Devise
  if (ps_trans->ui_rec_currency)
  {
    ps_options->ps_currency = pv_base;
    pv_base += sizeof(struct s_rec_currency);
  }

  // Sous-opérations, structure de base
  if (ps_trans->ui_rec_splits)
  {
    ps_options->ps_splits = pv_base;
    pv_base += (sizeof(struct s_rec_sub_transaction)
		+ ps_options->ps_splits->uh_size);
  }

  // Et pour finir, la description...
  ps_options->pa_note = pv_base;
}


Boolean options_check_extract(struct s_transaction *ps_trans,
			      UInt16 uh_size, struct s_rec_options *ps_options)
{
  void *pv_base = ps_trans->ra_note;

  // Pas la place de lire la structure de base...
  if (uh_size < sizeof(struct s_transaction))
    return false;

  MemSet(ps_options, sizeof(*ps_options), '\0');

  // Date de valeur
  if (ps_trans->ui_rec_value_date)
  {
    ps_options->ps_value_date = pv_base;
    pv_base += sizeof(struct s_rec_value_date);
  }

  // Numéro de chèque
  if (ps_trans->ui_rec_check_num)
  {
    ps_options->ps_check_num = pv_base;
    pv_base += sizeof(struct s_rec_check_num);
  }

  // Répétition
  if (ps_trans->ui_rec_repeat)
  {
    ps_options->ps_repeat = pv_base;
    pv_base += sizeof(struct s_rec_repeat);
  }

  // Transfert
  if (ps_trans->ui_rec_xfer)
  {
    ps_options->ps_xfer = pv_base;
    pv_base += sizeof(struct s_rec_xfer);
  }

  // Numéro de relevé
  if (ps_trans->ui_rec_stmt_num)
  {
    ps_options->ps_stmt_num = pv_base;
    pv_base += sizeof(struct s_rec_stmt_num);
  }

  // Devise
  if (ps_trans->ui_rec_currency)
  {
    ps_options->ps_currency = pv_base;
    pv_base += sizeof(struct s_rec_currency);
  }

  // Sous-opérations, structure de base
  if (ps_trans->ui_rec_splits)
  {
    struct s_rec_one_sub_transaction *ps_split;
    Char *pa_desc;
    UInt16 uh_offset, uh_num;

    ps_options->ps_splits = pv_base;

    // Y a t'il la place pour les sous-opérations ?
    uh_offset
      = (pv_base - (void*)ps_trans) + sizeof(struct s_rec_sub_transaction);

    // Pas la place de lire le header des sous-opérations
    if (uh_size <= uh_offset
	// Pas la place pour lire toutes les sous-opérations
	|| uh_size <= uh_offset + ps_options->ps_splits->uh_size
	// Taille et nombre de sous-op pas concordants
	|| (ps_options->ps_splits->uh_size
	    < (ps_options->ps_splits->uh_num
	       * (sizeof(struct s_rec_one_sub_transaction) + 1))))
      return false;

    // Il faut vérifier chaque sous-opération
    ps_split = pv_base + sizeof(struct s_rec_sub_transaction);

    pv_base += (sizeof(struct s_rec_sub_transaction)
		+ ps_options->ps_splits->uh_size);

    for (uh_num = ps_options->ps_splits->uh_num; uh_num-- > 0; )
    {
      pa_desc = ps_split->ra_desc;

      for (;;)
      {
	// On vient de dépasser l'espace alloué aux sous-op
	if ((void*)pa_desc >= pv_base)
	  return false;

	// Fin de la description, on peut passer à l'opération suivante
	if (*pa_desc++ == '\0')
	{
	  if ((UInt32)pa_desc & 0x1UL)
	    pa_desc++;
	  break;
	}
      }

      ps_split = (struct s_rec_one_sub_transaction*)pa_desc;
    }

    if ((void*)ps_split != pv_base)
      alert_error_str("splits hole: %lu bytes",
		      (UInt32)pv_base - (UInt32)ps_split);
  }

  // Et pour finir, la description...
  ps_options->pa_note = pv_base;

  // Même pas la place pour le \0 de la note
  if (uh_size <= pv_base - (void*)ps_trans)
    return false;

  return true;
}


struct s_rec_option_infos
{
  UInt32 ui_mask;
  Int16  h_size;
};

//
// Si pv_contents == NULL, retrait de l'option si existante
// Si pv_contents != NULL, modification OU insertion de l'option
//
// ps_options est toujours à jour au sortir de cette fonction.
// Si ps_options->pa_note, options_extract() est appelé automatiquement.
//
// Il est supposé qu'il y a toujours la place nécessaire dans ps_tr
// pour n'importe quelle insertion.
//
// Renvoie la taille totale de l'opération.
UInt16 options_edit(struct s_transaction *ps_tr,
		    struct s_rec_options *ps_options,
		    void *pv_contents,
		    enum e_options_edit e_option_index)
{
  const struct s_rec_option_infos rs_opt_infos[] =
    {
      { RECORD_VALUE_DATE,	     sizeof(struct s_rec_value_date) },
      { RECORD_CHECK_NUM, 	     sizeof(struct s_rec_check_num) },
      { RECORD_REPEAT,    	     sizeof(struct s_rec_repeat) },
      { RECORD_XFER|RECORD_XFER_CAT, sizeof(struct s_rec_xfer) },
      { RECORD_STMT_NUM,  	     sizeof(struct s_rec_stmt_num) },
      { RECORD_CURRENCY,  	     sizeof(struct s_rec_currency) },
      { RECORD_SPLITS,    	     -1 },
      { 0,		  	     -1 } // Note
    };
  const struct s_rec_option_infos *ps_infos;
  void **ppv_options = (void**)ps_options;
  void *pv_insert_pos;
  UInt16 uh_note_len;
  Int16 h_opt_size = ps_infos->h_size;

  if (e_option_index > OPT_NOTE)
    return 0;

  if (ps_options->pa_note == NULL)
    options_extract(ps_tr, ps_options);

  ps_infos = &rs_opt_infos[e_option_index];

  // Longueur de la note
  uh_note_len = StrLen(ps_options->pa_note) + 1; // Avec le \0

  // Longueur de l'option
  h_opt_size = ps_infos->h_size;
  if (h_opt_size < 0)
    switch (e_option_index)
    {
      // Les sous-opérations ont une taille variable
    case OPT_SPLITS:
      h_opt_size = ps_options->ps_splits ? ps_options->ps_splits->uh_size : 0;
      break;
      // La note a une taille variable
    default:
    case OPT_NOTE:
      h_opt_size = uh_note_len;
      break;
    }

  pv_insert_pos = ppv_options[e_option_index];

  //
  // Suppression de l'option
  //
  if (pv_contents == NULL)
  {
    // L'option est effectivement là
    if (pv_insert_pos != NULL)
    {
      // Cas particulier pour vider la note comme elle est après
      // toutes les options Il doit toujours rester un \0 à la fin.
      if (e_option_index == OPT_NOTE)
      {
	ps_options->pa_note[0] = '\0';
	uh_note_len = 1;
      }
      // Les autres options...
      else
      {
	Char *pa_after_option;

	pa_after_option = (Char*)pv_insert_pos + h_opt_size;

	MemMove(pv_insert_pos, pa_after_option,
		ps_options->pa_note - pa_after_option + uh_note_len);

	// L'option vient de disparaître
	ps_tr->u_flags.ui_all &= ~ps_infos->ui_mask;
      }
    } // option présente
  }
  //
  // Ajout de l'option
  //
  else
  {
    Char *pa_after_option;
    UInt32 ui_mask = ps_infos->ui_mask;
    Int16 h_opt_new_size = h_opt_size;

    switch (e_option_index)
    {
      // Les sous-opérations ont une taille variable
    case OPT_SPLITS:
      h_opt_new_size = ((struct s_rec_sub_transaction*)pv_contents)->uh_size;
      break;

      // L'option transfert manipule 2 bits
    case OPT_XFER:
      // Transfert vers un compte : xfer + xfer_cat
      if (*(UInt32*)pv_contents & CHANGE_XFER_OPTION_CATEGORY)
	*(UInt32*)pv_contents &= ~CHANGE_XFER_OPTION_CATEGORY;
      // Opération liée : xfer
      else
      {
	ps_tr->ui_rec_xfer_cat = 0;
	ui_mask = RECORD_XFER;
      }
      break;

    default:
      break;
    }

    // L'option est déjà là
    if (pv_insert_pos != NULL)
    {
      // Cas particulier pour la note
      if (e_option_index == OPT_NOTE)
      {
	uh_note_len = StrLen((Char*)pv_contents) + 1; // Avec le \0

	MemMove(ps_options->pa_note, pv_contents, uh_note_len);

	goto end;
      }

      // N'importe quelle autre option
      // La zone de l'option change de taille, il faut décaler la
      // fin (pour l'instant ça ne peut être le cas que pour les
      // sous-opérations).
      if (h_opt_new_size != h_opt_size)
      {
	pa_after_option = (Char*)pv_insert_pos + h_opt_size;

	MemMove((Char*)pv_insert_pos + h_opt_new_size,
		pa_after_option,
		ps_options->pa_note - pa_after_option + uh_note_len);
      }
    }
    // L'option n'est pas encore là, il faut l'insérer
    else			// Ici ça ne peut *jamais* être OPT_NOTE
    {
      UInt16 uh_index;

      pv_insert_pos = ps_tr + 1;

      for (uh_index = 0; uh_index < e_option_index; uh_index++)
      {
	if (ppv_options[uh_index] != NULL)
	{
	  Int16 h_cur_size = rs_opt_infos[uh_index].h_size;

	  if (h_cur_size < 0)
	    if (uh_index == OPT_SPLITS)
	      h_cur_size = ps_options->ps_splits->uh_size;

	  pv_insert_pos = (Char*)ppv_options[uh_index] + h_cur_size;
	}
      }

      // Il faut décaler les options et la description qui suivent
      // pour permettre l'insertion
      pa_after_option = (Char*)pv_insert_pos + h_opt_new_size;

      MemMove(pa_after_option, pv_insert_pos,
	      ps_options->pa_note - pa_after_option + uh_note_len);
    } // option déjà là / absente

    MemMove(pv_insert_pos, pv_contents, h_opt_new_size);

    // L'option est désormais présente (laisser ici, car l'option XFER
    // peut avoir besoin de modifier le masque malgré le fait que
    // l'option soit déjà présente).
    ps_tr->u_flags.ui_all |= ui_mask;

end:
    ;
  }

  options_extract(ps_tr, ps_options);

  return ps_options->pa_note - (Char*)ps_tr + uh_note_len;
}


struct s_rec_one_sub_transaction *sub_trans_next_extract
	(struct s_rec_sub_transaction *ps_base_splits,
	 struct s_rec_one_sub_transaction *ps_last_splits)
{
  Char *pa_end;

  if (ps_last_splits == NULL)
    return (struct s_rec_one_sub_transaction*)(ps_base_splits + 1);

  pa_end = ps_last_splits->ra_desc;

  // On se place sur le premier multiple de 2 suivant le \0 de la fin
  // de la description      \0
  pa_end += StrLen(pa_end) + 1 + 1;
  (UInt32)pa_end &= ~0x1UL;

  return (struct s_rec_one_sub_transaction*)pa_end;
}


UInt32 do_on_each_transaction(UInt16 (*pf_method)(Transaction*, UInt32),
			      UInt32 ui_value)
{
  Transaction *oCurTransaction, *oCurOpened;
  MemHandle hdl_dbs;
  SysDBListItemType *ps_db;
  UInt32 ui_dbases_trans = 0;
  LocalID ui_opened_lid = 0;
  UInt16 uh_opened_card_no = 0;
  UInt16 uh_num_dbs, index, uh_num_method;

  if (SysCreateDataBaseList(MaTiAccountsType, MaTiCreatorID,
			    &uh_num_dbs, &hdl_dbs, false)
      && uh_num_dbs > 0)
  {
    // A-t-on une base de comptes déjà ouverte ?
    oCurOpened = [[MaTirelire appli] transaction];
    if (oCurOpened != nil)
      [oCurOpened getCardNo:&uh_opened_card_no andID:&ui_opened_lid];

    ps_db = MemHandleLock(hdl_dbs);

    for (index = 0; index < uh_num_dbs; index++, ps_db++)
    {
      if (oCurOpened != nil
	  && ps_db->dbID == ui_opened_lid
	  && ps_db->cardNo == uh_opened_card_no)
	oCurTransaction = oCurOpened;
      else
	oCurTransaction = [Transaction open:ps_db->name];

      if (oCurTransaction != NULL)
      {
	// Big hack... due to the inexistence of @selector in mcc
	uh_num_method = pf_method(oCurTransaction, ui_value);

	if (uh_num_method > 0)
	{
	  // Il faut terminer ici...
	  if (uh_num_method == -1)
	    index = uh_num_dbs;
	  else
	  {
	    ui_dbases_trans += uh_num_method;
	    ui_dbases_trans += 0x10000;
	  }
	}

	if (oCurTransaction != oCurOpened)
	  [oCurTransaction free];
      }
    }

    MemHandleUnlock(hdl_dbs);
    MemHandleFree(hdl_dbs);
  }

  return ui_dbases_trans;
}


void find_on_each_transaction(struct s_tr_find_params *ps_find_params)
{
  Transaction *oCurTransaction, *oCurOpened;
  MemHandle hdl_dbs;
  SysDBListItemType *ps_db;
  LocalID ui_opened_lid = 0;
#define FIND_DBASE_HEADER	"MT2 - "
  Char ra_header[sizeof(FIND_DBASE_HEADER) - 1 + dmDBNameLength];
  Char ra_db_name[dmDBNameLength];
  UInt16 uh_opened_card_no = 0;
  UInt16 uh_num_dbs, index;

  if (SysCreateDataBaseList(MaTiAccountsType, MaTiCreatorID,
			    &uh_num_dbs, &hdl_dbs, false)
      && uh_num_dbs > 0)
  {
    MemMove(ra_header, FIND_DBASE_HEADER, sizeof(FIND_DBASE_HEADER) - 1);

    // A-t-on une base de comptes déjà ouverte ?
    oCurOpened = [[MaTirelire appli] transaction];
    if (oCurOpened != nil)
      [oCurOpened getCardNo:&uh_opened_card_no andID:&ui_opened_lid];

    ps_db = MemHandleLock(hdl_dbs);

    // Sort the list alphabeticaly to be sure it's the same order that
    // when last called
    SysInsertionSort(ps_db, uh_num_dbs, sizeof(*ps_db),
		     (CmpFuncPtr)sort_string_compare, 0);

    index = 0;

#define FIND_FEATURE_ID	0xf14d

    if (ps_find_params->ps_sys_find_params->continuation)
    {
      UInt32 ui_index;

      // Recherche la feature et initialise index avec
      if (FtrGet(MaTiCreatorID, FIND_FEATURE_ID, &ui_index) == 0)
	index = ui_index;
    }

    ps_db += index;

    for (; index < uh_num_dbs; index++, ps_db++)
    {
      if (oCurOpened != nil
	  && ps_db->dbID == ui_opened_lid
	  && ps_db->cardNo == uh_opened_card_no)
	oCurTransaction = oCurOpened;
      else
	oCurTransaction = [Transaction open:ps_db->name];

      if (oCurTransaction != NULL)
      {
	// Si la base est actuellement ouverte dans l'appli
	if (oCurTransaction == oCurOpened
	    // OU BIEN si la recherche dans cette base est autorisée...
	    || [oCurTransaction getPrefs]->ul_deny_find == 0)
	{
	  [oCurTransaction getName:ra_db_name];
	  StrCopy(&ra_header[sizeof(FIND_DBASE_HEADER) - 1],
		  db_list_visible_name(ra_db_name));

	  // On affiche le header avec le nom de la base
	  if (FindDrawHeader(ps_find_params->ps_sys_find_params, ra_header)
	      // Puis on recherche tous les enregistrements de la base
	      || [oCurTransaction findRecord:ps_find_params])
	  {
	    // Il faut s'interrompre en cours de route...

	    // On sauve l'index de la base dans la feature
	    FtrSet(MaTiCreatorID, FIND_FEATURE_ID, index);

	    // Il faut s'arrêter là
	    index = uh_num_dbs;
	  }
	  else
	  {
	    // Pour les prochaines bases, il faudra commencer au 1er
	    // enregistrement
	    ps_find_params->ps_sys_find_params->recordNum = 0;
	  }
	}

	if (oCurTransaction != oCurOpened)
	  [oCurTransaction free];
      }
    }

    MemHandleUnlock(hdl_dbs);
    MemHandleFree(hdl_dbs);

    // Destruction de l'éventuelle feature
    if (ps_find_params->ps_sys_find_params->more == false)
      FtrUnregister(MaTiCreatorID, FIND_FEATURE_ID);
  }
}


Int16 transaction_val_date_cmp(struct s_transaction *ps_tr1,
			       struct s_transaction *ps_tr2,
			       Int16 h_dummy,
			       SortRecordInfoPtr rec1SortInfo,
			       SortRecordInfoPtr rec2SortInfo,
			       MemHandle appInfoH)
{
  UInt32 ui_date1, ui_date2;

  ui_date1 = DateToInt(ps_tr1->s_date);
  ui_date2 = DateToInt(ps_tr2->s_date);

  // Si pas propriétés de compte, on regarde s'il y a une date de valeur
  if (ui_date1 != 0)
  {
    if (ps_tr1->ui_rec_value_date)
      ui_date1 |= ((UInt32)DateToInt(value_date_extract(ps_tr1)) << 16);
    else
      ui_date1 |= (ui_date1 << 16);
  }

  // Si pas propriétés de compte, on regarde s'il y a une date de valeur
  if (ui_date2 != 0)
  {
    if (ps_tr2->ui_rec_value_date)
      ui_date2 |= ((UInt32)DateToInt(value_date_extract(ps_tr2)) << 16);
    else
      ui_date2 |= (ui_date2 << 16);
  }

  if (ui_date1 > ui_date2)
    return 1;

  if (ui_date1 < ui_date2)
    return -1;

  // Les dates sont égales, on regarde l'heure
  return (Int16)TimeToInt(ps_tr1->s_time) - (Int16)TimeToInt(ps_tr2->s_time);
}


Int16 transaction_std_cmp(struct s_transaction *ps_tr1,
			  struct s_transaction *ps_tr2,
			  Int16 h_dummy,
			  SortRecordInfoPtr rec1SortInfo,
			  SortRecordInfoPtr rec2SortInfo,
			  MemHandle appInfoH)
{
  UInt16 uh_date1, uh_date2;

  uh_date1 = DateToInt(ps_tr1->s_date);
  uh_date2 = DateToInt(ps_tr2->s_date);

  if (uh_date1 > uh_date2)
    return 1;

  if (uh_date1 < uh_date2)
    return -1;

  // Les dates sont égales, on regarde l'heure
  return (Int16)TimeToInt(ps_tr1->s_time) - (Int16)TimeToInt(ps_tr2->s_time);
}
