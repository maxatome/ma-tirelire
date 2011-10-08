/* 
 * CustomScrollList.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Ven aoû  5 22:15:25 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Dec 11 17:22:33 2007
 * Update Count    : 40
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: CustomScrollList.m,v $
 * Revision 1.8  2008/01/14 17:09:32  max
 * Switch to new mcc.
 *
 * Revision 1.7  2006/11/04 23:48:01  max
 * Use FOREACH_SPLIT* macros.
 * Add -initStatsSearch: and -searchFree: methods.
 * Correct debits/credits criteria handling.
 *
 * Revision 1.6  2006/10/05 19:08:51  max
 * Custom* search is now generic here.
 *
 * Revision 1.5  2006/06/28 09:41:41  max
 * s/pt_frm/oForm/g attribute.
 *
 * Revision 1.4  2005/10/11 19:11:53  max
 * -shortClic* methods deported to SumScrollList.
 * Use generic SumScrollList -shortClic* methods.
 *
 * Revision 1.3  2005/10/06 19:48:12  max
 * Add -accounts method to help to determine the currency to use in scrolllist.
 *
 * Revision 1.2  2005/09/02 17:23:08  max
 * -initStatsAccountsCurrencyCache init now ALL accounts currencies.
 *
 * Revision 1.1  2005/08/20 13:06:34  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_CUSTOMSCROLLLIST
#include "CustomScrollList.h"

#include "MaTirelire.h"
#include "Currency.h"
#include "CustomListForm.h"

#include "ProgressBar.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


@implementation CustomScrollList

- (CustomScrollList*)free
{
  if (self->vh_infos != NULL)
    MemHandleFree(self->vh_infos);

  return [super free];
}


- (void)initRecordsCount
{
  // On initialise la devise du formulaire nous contenant
  [self initFormCurrency];

  [super initRecordsCount];
}


// Par défaut, les comptes sélectionnés dans les stats
- (UInt16)accounts
{
  return [oMaTirelire transaction]->ps_prefs->rs_stats[0].uh_checked_accounts;
}


//
// Initialise l'attribut rua_accounts_curr en fonction des comptes
// renvoyés par -accounts
// Renvoie la devise utilisée par le plus grand nombre de ces comptes
- (UInt16)initAccountsCurrencyCache
{
  Transaction *oTransactions = [oMaTirelire transaction];
  UChar rua_all_curr[NUM_CURRENCIES];
  UInt16 index, uh_accounts, uh_curr;
  UInt16 uh_max_accounts_curr = 0, uh_max_accounts_val = 0;

  MemSet(rua_all_curr, sizeof(rua_all_curr), '\0');

  uh_accounts = [self accounts];

  for (index = MAX_ACCOUNTS; index-- > 0; )
    if (uh_accounts & (1 << index))
    {
      uh_curr = [oTransactions accountCurrency:index];

      self->rua_accounts_curr[index] = uh_curr;

      // On recherche la devise la plus utilisée
      rua_all_curr[uh_curr]++;
      if (rua_all_curr[uh_curr] > uh_max_accounts_val)
      {
	uh_max_accounts_curr = uh_curr;
	uh_max_accounts_val = rua_all_curr[uh_curr];
      }
    }

  return uh_max_accounts_curr;
}


//
// Initialise l'attribut rua_accounts_curr en fonction des comptes
// sélectionné dans les stats
// Initialise l'attribut uh_currency du formulaire nous contenant
- (void)initFormCurrency
{
  UInt16 uh_currency = [self initAccountsCurrencyCache];
  UInt16 uh_form_currency = ((SumListForm*)self->oForm)->uh_currency;

  // Attribut devise non encore initialisé, ou bien devise inexistante
  if (uh_form_currency == -1
      || [[oMaTirelire currency] getCachedIndexFromID:uh_form_currency]
      == ITEM_FREE_ID)
    ((CustomListForm*)self->oForm)->uh_currency = uh_currency;
}


- (UInt16)_changeHandFillIncObjs:(UInt16*)puh_objs
		 withoutDontDraw:(Boolean)b_without_dont_draw
{
  UInt16 uh_nb_objs = 2 + 1 + 1 + 1; // Back + popup + devise + somme

  if (b_without_dont_draw == false)
  {
    *puh_objs++ = CustomListList | SCROLLLIST_CH_DONT_DRAW;
    *puh_objs++ = SumListCurrencyList | SCROLLLIST_CH_DONT_DRAW;

    uh_nb_objs += 2;
  }

  *puh_objs++ = bmpBack;
  *puh_objs++ = CustomListQuit;

  *puh_objs++ = CustomListPopup;
  *puh_objs++ = SumListCurrency;
  *puh_objs = SumListSum;

  return uh_nb_objs;
}


//
// Clic simple (ou sélection par le clavier) sur la ligne uh_row
- (void)clicOnRow:(UInt16)uh_row
{
  // Équivalent à un clic sur la description
  [self shortClicOnRow:uh_row from:0 to:-1];
}


- (void)changeSumFilter:(UInt16)uh_sum_filter
{
  if (uh_sum_filter != self->uh_sum_filter)
  {
    self->uh_sum_filter = uh_sum_filter;

    [self computeSum];
    [self displaySum];
  }
}


// Renvoie true si la somme doit être rafaichie
- (Boolean)addAmount:(t_amount)l_amount selected:(Boolean)b_selected
{
  if (self->uh_sum_filter != CLIST_SUM_ALL)
  {
    if ((self->uh_sum_filter == CLIST_SUM_NON_SELECT) ^ b_selected)
      self->l_sum += l_amount;
    else
      self->l_sum -= l_amount;

    return true;
  }

  return false;
}


- (void)selectChange:(Int16)h_action
{
  switch (self->uh_sum_filter)
  {
  case CLIST_SUM_ALL:
    goto refresh;	       // Rien à faire, la somme ne change pas

  case CLIST_SUM_SELECT:
    if (h_action == CLIST_SELECT_CLEAR) // Plus rien n'est sélectionné
    {
      self->l_sum = 0;
      goto refresh;
    }
    break;

  case CLIST_SUM_NON_SELECT:
    if (h_action > CLIST_SELECT_CLEAR) // Tout est sélectionné
    {
      self->l_sum = 0;
      goto refresh;
    }
    break;
  }

  // Pour les autres cas, on recalcule tout...
  [self computeSum];

 refresh:
  [self redrawList];		// Ré-affiche la somme
}


// Par défaut on ne fait rien juste avant de quitter
- (Boolean)beforeQuitting
{
  return true;
}


////////////////////////////////////////////////////////////////////////
//
// Recherche générique d'opérations
//
////////////////////////////////////////////////////////////////////////

#define __SEARCH_TEST_OK	1
#define __SEARCH_TEST_FAILED	0

#define __SEARCH_PREPARE_LABELS_OP(test_label, failed_label)	\
  ({								\
    *ppv_previous = &&test_label;				\
								\
    ppv_previous = &ppv_label[__SEARCH_TEST_OK];		\
    ppv_label[__SEARCH_TEST_FAILED] = &&failed_label;		\
    ppv_label += 2;						\
  })

#define __SEARCH_TEST(test) ({ ppv_label += 2; goto *ppv_label[test]; })

#define __SEARCH_TEST_TYPE(test)					\
  /* Opération avec ventilation */					\
  if (s_infos.ps_tr->ui_rec_splits)					\
  {									\
    FOREACH_SPLIT_DECL; /* __uh_num et ps_cur_split */			\
    t_amount l_splits_sum = 0, l_types_sum = 0, l_abs_amount;		\
    UInt16 __uh_cur_type; /* utilisé dans "test" */			\
    Boolean b_ok = false;						\
									\
    options_extract((struct s_transaction*)s_infos.ps_tr,&s_infos.s_options); \
									\
    /* On parcourt toutes les sous-opérations */			\
    FOREACH_SPLIT(&s_infos.s_options)					\
    {									\
      __uh_cur_type = ps_cur_split->ui_type;				\
      if (test)								\
      {									\
	if (b_dont_compute_amount)					\
	  __SEARCH_TEST(1);						\
									\
	b_ok = true;							\
	l_types_sum += ps_cur_split->l_amount;				\
      }									\
									\
      l_splits_sum += ps_cur_split->l_amount;				\
    }									\
									\
    /* l_abs_amount est abs(montant de l'op dans sa propre monnaie) */	\
    if (s_infos.ps_tr->ui_rec_currency)					\
    {									\
      l_abs_amount = s_infos.s_options.ps_currency->l_currency_amount;	\
									\
      /* Désormais le montant de l'opération est bien dans la */	\
      /* monnaie de l'opération */					\
      b_must_update_amount = false;					\
      s_infos.l_amount = l_abs_amount; /* Au cas où b_dont_compute_amount */ \
    }									\
    else								\
      l_abs_amount = s_infos.l_amount;					\
									\
    if (l_abs_amount < 0)						\
      l_abs_amount = - l_abs_amount;					\
									\
    /* Montant restant */						\
    l_abs_amount -= l_splits_sum;					\
									\
    /* S'il y a une ventilation avec un reste nul, le type de */	\
    /* l'opération n'est pris en compte que si le type n'est pas */	\
    /* "Unfiled". */							\
    /* Donc s'il n'y a pas de reste ET que le type est "Unfiled", on */	\
    /* ignore. */							\
    if (s_infos.ps_tr->ui_rec_type != TYPE_UNFILED || l_abs_amount > 0)	\
    {									\
      __uh_cur_type = s_infos.ps_tr->ui_rec_type;			\
      if (test)								\
      {									\
	if (b_dont_compute_amount)					\
	  __SEARCH_TEST(1);						\
									\
	b_ok = true;							\
	l_types_sum += l_abs_amount;					\
      }									\
    }									\
									\
    if (b_ok)								\
    {									\
      s_infos.l_amount = s_infos.l_amount < 0 ? - l_types_sum : l_types_sum; \
									\
      /* Au moins un type a été trouvé */				\
      __SEARCH_TEST(1);							\
    }									\
    else								\
      /* Aucun type n'a été trouvé... */				\
      __SEARCH_TEST(0);							\
  }									\
  /* Opération sans ventilation */					\
  else									\
  {									\
    UInt16 __uh_cur_type = s_infos.ps_tr->ui_rec_type;			\
    __SEARCH_TEST(test);						\
  }


//
// Renvoie true s'il faut éliminer les montants nuls
- (Boolean)searchFrom:(UInt16)uh_from amount:(Boolean)b_dont_compute_amount
{
  DmOpenRef db;
  MemHandle pv_item;
  PROGRESSBAR_DECL;
  struct s_search_infos s_infos;

  void *rrv_labels[4 /* nbre de tests */][2];
  void **ppv_label = rrv_labels[0];
  void *pv_start = NULL;
  void **ppv_previous = &pv_start;
  void *pv_date_test = NULL;	// Spécial test de date (init pour warning GCC)

  UInt16 index, uh_num_records;
  Boolean b_must_update_amount, b_test_update_amount;

  MemSet(rrv_labels, sizeof(rrv_labels), '\0');

  //
  // Chargement des critères de recherche
  [(CustomListForm*)self->oForm initStatsSearch:&s_infos.s_search_criteria];

  // La devise du compte + init du pointeur sur la devise temporaire
  b_test_update_amount = [self searchInit:&s_infos];

  //
  // Compilation des tests
  //

  // La date (test 1)
  if (b_test_update_amount)
  {
    // Jamais de propriétés de compte ici

    // Il faut essayer d'aller chercher la date de valeur
    if (s_infos.s_search_criteria.b_val_date)
      pv_date_test = &&__do_val_date_test;
    else
      pv_date_test = &&__after_val_date_test;

    __SEARCH_PREPARE_LABELS_OP(date, free_next);
  }

  // Seulement les débits ou les crédits ? (test 2)
  // s_infos.s_search_criteria.uh_on (les montants nuls passent toujours) :
  // - 1 sur les débits uniquement
  // - 2 sur les crébits uniquement
  // - 3 pour n'importe quel montant
  switch (s_infos.s_search_criteria.uh_on)
  {
  case 1:			// sur les débits uniquement
    __SEARCH_PREPARE_LABELS_OP(debits_only, free_next);
    break;
  case 2:			// sur les crébits uniquement
    __SEARCH_PREPARE_LABELS_OP(credits_only, free_next);
    break;
  }

  // Des flags ? (test 3)
  if (s_infos.s_search_criteria.ui_rec_flags_mask != 0)
    __SEARCH_PREPARE_LABELS_OP(flags, free_next);

  // Plusieurs types (test 4)
  if (s_infos.s_search_criteria.pul_types != NULL)
    __SEARCH_PREPARE_LABELS_OP(many_types, free_next);
  // Un seul type (test 4)
  else if (s_infos.s_search_criteria.h_one_type >= 0)
    __SEARCH_PREPARE_LABELS_OP(one_type, free_next);

  *ppv_previous = &&ok;

  //
  // Recherche
  s_infos.oTransactions = [oMaTirelire transaction];
  db = [s_infos.oTransactions db];
  uh_num_records = DmNumRecords(db);

  PROGRESSBAR_BEGIN(uh_num_records, strProgressBarStats);

  // Pour chaque opération
  for (index = uh_from; index < uh_num_records; index++)
  {
    pv_item = DmQueryRecord(db, index);	// PG
    if (pv_item == NULL)
      goto next;

    // Compte de l'opération
    DmRecordInfo(db, index, &s_infos.uh_account, NULL, NULL);
    s_infos.uh_account &= dmRecAttrCategoryMask;

    // Ce compte n'est pas demandé
    if ((s_infos.s_search_criteria.uh_accounts
	 & (1 << s_infos.uh_account)) == 0)
      goto next;

    s_infos.ps_tr = MemHandleLock(pv_item);

    // Montant de l'opération dans la monnaie du compte
    s_infos.l_amount = s_infos.ps_tr->l_amount;

    // Il faut mettre à jour s_infos.l_amount en la monnaie de l'op dès
    // que possible
    b_must_update_amount
      = b_test_update_amount && s_infos.ps_tr->ui_rec_currency;

    // Permet de savoir ques s_options n'est pas encore initialisé
    s_infos.s_options.pa_note = NULL;

    ppv_label = rrv_labels[0];
    ppv_label -= 2;

    ////////////////////////////////////////////////////////////////////////
    // Ici commencent les tests
    goto *pv_start;

 date:
    // Date de l'opération
    s_infos.uh_date = DateToInt(s_infos.ps_tr->s_date);

    // Pas de propriétés de compte ici
    if (s_infos.uh_date == 0)
      __SEARCH_TEST(0);

    goto *pv_date_test;	// __do_val_date_test OU BIEN __after_val_date_test

 __do_val_date_test:
    if (s_infos.ps_tr->ui_rec_value_date)
      s_infos.uh_date = DateToInt(value_date_extract(s_infos.ps_tr));

 __after_val_date_test:
    __SEARCH_TEST(s_infos.uh_date >= s_infos.s_search_criteria.uh_beg_date
		  && s_infos.uh_date <= s_infos.s_search_criteria.uh_end_date);

 debits_only:
    __SEARCH_TEST(s_infos.l_amount <= 0);

 credits_only:
    __SEARCH_TEST(s_infos.l_amount >= 0);

 flags:
    __SEARCH_TEST((s_infos.ps_tr->ui_rec_flags
		   & s_infos.s_search_criteria.ui_rec_flags_mask)
		  == s_infos.s_search_criteria.ui_rec_flags_value);

 many_types:
    __SEARCH_TEST_TYPE(BIT_ISSET(__uh_cur_type,
				 s_infos.s_search_criteria.pul_types) != 0);

one_type:
    __SEARCH_TEST_TYPE(__uh_cur_type == s_infos.s_search_criteria.h_one_type);

 ok:
    // Si l'opération a une devise dont le montant est encore inconnu
    // (sinon il a déjà été mis a jour dans la ventilation)
    if (b_must_update_amount)
    {
      options_extract((struct s_transaction*)s_infos.ps_tr,&s_infos.s_options);
      s_infos.l_amount = s_infos.s_options.ps_currency->l_currency_amount;
    }

    s_infos.index = index;	// On passe l'index de opération

    // L'opération correspond aux critères de recherche, il faut sans
    // doute convertir le montant de l'opération dans la monnaie du
    // formulaire
    if ([self searchMatch:&s_infos])
    {
      MemHandleUnlock(pv_item);
      break;
    }

free_next:
    MemHandleUnlock(pv_item);

next:
    PROGRESSBAR_INLOOP(index, 50); // OK
  }

  PROGRESSBAR_END;

  [self searchFree:&s_infos];

  return s_infos.s_search_criteria.b_ignore_nulls;
}


//
// Renvoie true si cette liste peut avoir une monnaie changeante
// (popup de monnaie en bas à droite du formulaire). À noter que dans
// ce cas, on n'a jamais de propriétés de compte
- (Boolean)searchInit:(struct s_search_infos*)ps_infos
{
  ps_infos->oCurrencies = [oMaTirelire currency];
  ps_infos->ps_form_currency
    = [ps_infos->oCurrencies getId:((CustomListForm*)self->oForm)->uh_currency];
  ps_infos->ps_other_currency = NULL;

  return true;
}


- (void)searchFree:(struct s_search_infos*)ps_infos
{
  [ps_infos->oCurrencies getFree:ps_infos->ps_form_currency];
  [ps_infos->oCurrencies getFree:ps_infos->ps_other_currency];  
}



//
// L'opération a passé tous les tests avec succès.
//
// ps_infos->l_amount est le montant retenu de l'opération, dans la
// monnaie de l'opération.
//
// Si ps_infos->ps_tr->ui_rec_currency != 0, alors ps_infos->s_options
// contient les infos des options, sinon il se peut qu'il ne soit pas
// initialisé.
//
// Si l'opération n'a pas de devise, ps_infos->l_amount est dans la
// monnaie du compte.
//
// ps_infos->uh_account est le compte de l'opération.
//
// Retourne true si la recherche de -searchFrom:amount: doit s'achever
- (Boolean)searchMatch:(struct s_search_infos*)ps_infos
{
  UInt16 uh_acc_currency, uh_form_currency;

  uh_form_currency = ps_infos->ps_form_currency->ui_id;
  uh_acc_currency = self->rua_accounts_curr[ps_infos->uh_account];

  // La monnaie du compte est la même que celle du formulaire
  if (uh_acc_currency == uh_form_currency)
  {
    // L'opération a une devise donc les infos ont été initialisées
    if (ps_infos->ps_tr->ui_rec_currency)
    {
      // On convertit dans la monnaie du formulaire, qui est aussi
      // la monnaie du compte, donc avec le taux inhérent à
      // l'opération elle-même
      ps_infos->l_amount = currency_convert_amount2
	(ps_infos->l_amount,
	 ps_infos->s_options.ps_currency->l_currency_amount,
	 ps_infos->ps_tr->l_amount);
    }
  }
  // La monnaie du compte n'est pas la même que celle du formulaire
  else
  {
    // L'opération a une devise donc les infos ont été initialisées
    if (ps_infos->ps_tr->ui_rec_currency)
    {
      // Devise différente de celle du formulaire
      if (ps_infos->s_options.ps_currency->ui_currency != uh_form_currency)
      {
	// Il faut convertir la somme de la monnaie de l'opération
	// dans la monnaie du formulaire
	if (ps_infos->ps_other_currency == NULL
	    || (ps_infos->ps_other_currency->ui_id
		!= ps_infos->s_options.ps_currency->ui_currency))
	{
	  [ps_infos->oCurrencies getFree:ps_infos->ps_other_currency];

	  ps_infos->ps_other_currency
	    = [ps_infos->oCurrencies
		       getId:ps_infos->s_options.ps_currency->ui_currency];
	}

	goto convert_amount;
      }
      // Sinon ps_infos->l_amount est déjà dans la monnaie du formulaire
      // puisque c'est aussi celle de l'opération
    }
    // L'opération n'a pas de devise
    else
    {
      // Il faut convertir la somme de la monnaie du compte
      // dans la monnaie du formulaire
      if (ps_infos->ps_other_currency == NULL
	  || ps_infos->ps_other_currency->ui_id != uh_acc_currency)
      {
	[ps_infos->oCurrencies getFree:ps_infos->ps_other_currency];
	ps_infos->ps_other_currency
	  = [ps_infos->oCurrencies getId:uh_acc_currency];
      }

  convert_amount:
      ps_infos->l_amount = currency_convert_amount(ps_infos->l_amount,
						   ps_infos->ps_other_currency,
						   ps_infos->ps_form_currency);
    }
  }

  return false;
}

@end
