/* 
 * SearchForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mar oct  4 22:16:45 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jul  6 14:45:56 2007
 * Update Count    : 62
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: SearchForm.m,v $
 * Revision 1.9  2008/01/14 16:25:42  max
 * Switch to new mcc.
 * Add >= and <= operators.
 *
 * Revision 1.8  2006/12/16 16:56:47  max
 * Introduce "Action" popup instead of 2 not really useful checkboxes.
 *
 * Revision 1.7  2006/11/04 23:48:13  max
 * Can now search over amounts.
 * Use FOREACH_SPLIT* macros.
 * Minor changes.
 *
 * Revision 1.6  2006/10/05 19:08:59  max
 * The two dates can now be bound (choice saved in stats preferences as
 * other fields are).
 * Accounts selection differ a tiny bit.
 *
 * Revision 1.5  2006/07/06 15:47:16  max
 * Allow type searchs in splits.
 *
 * Revision 1.4  2006/07/05 15:29:39  max
 * Now search types in splits.
 *
 * Revision 1.3  2006/06/23 13:24:43  max
 * Now call -focusObject: instead of FrmSetFocus() to set focus to a field.
 *
 * Revision 1.2  2005/10/11 19:11:59  max
 * Set focus after [super open].
 * Non valuable date search now works correctly.
 * Cheque 2 can be > to cheque 1 in cheque range.
 *
 * Revision 1.1  2005/10/06 19:48:34  max
 * First import.
 *
 * ==================== RCS ==================== */

#include <PalmOSGlue/TxtGlue.h>

#define EXTERN_SEARCHFORM
#include "SearchForm.h"

#include "CustomListForm.h"

#include "MaTirelire.h"
#include "Type.h"
#include "Mode.h"

#include "ProgressBar.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX

// Index des opérateurs sur le montant dans la liste
#define AMOUNT_LIST_IDX_EQ	0
#define AMOUNT_LIST_IDX_GT	1
#define AMOUNT_LIST_IDX_LT	2
#define AMOUNT_LIST_IDX_IT	3
#define AMOUNT_LIST_IDX_GTE	4 // Opérateurs non présents dans la liste...
#define AMOUNT_LIST_IDX_LTE	5 // ...mais (>= = {X) et (<= = X})

@implementation SearchForm

- (SearchForm*)free
{
  [[oMaTirelire mode] popupListFree:self->pv_popup_modes];
  [[oMaTirelire type] popupListFree:self->pv_popup_types];

  return [super free];
}


- (Boolean)open
{
  Transaction *oTransactions = [oMaTirelire transaction];
  ListType *pt_list;
  Char ra_account_name[dmCategoryLength];
  DateTimeType s_datetime;

  // Les dates
  self->e_format = (DateFormatType)PrefGetPreference(prefDateFormat);
  TimSecondsToDateTime(TimGetSeconds(), &s_datetime);
  self->rs_date[0].day = s_datetime.day;
  self->rs_date[0].month = s_datetime.month;
  self->rs_date[0].year = s_datetime.year - firstYear;
  self->rs_date[1] = self->rs_date[0];

  [self dateSet:SearchBegDate date:self->rs_date[0] format:self->e_format];
  [self dateSet:SearchEndDate date:self->rs_date[1] format:self->e_format];

  // Le nom du compte courant
  CategoryGetName(oTransactions->db, oTransactions->ps_prefs->ul_cur_category,
		  ra_account_name);

  // Liste des types
  self->pv_popup_types = [[oMaTirelire type] popupListInit:SearchTypeList
					     form:self->pt_frm
					     Id:ITEM_ANY | TYPE_ADD_ANY_LINE
					     forAccount:ra_account_name];

  // Liste des modes
  self->pv_popup_modes = [[oMaTirelire mode] popupListInit:SearchModeList
					     form:self->pt_frm
					     Id:(ITEM_ANY
						 | ITEM_ADD_UNKNOWN_LINE
						 | ITEM_ADD_ANY_LINE)
					     forAccount:ra_account_name];

  // Montant : { A - B } par défaut
  pt_list = [self objectPtrId:SearchAmountList];
  LstSetSelection(pt_list, AMOUNT_LIST_IDX_IT);
  CtlSetLabel([self objectPtrId:SearchAmountPopup],
	      LstGetSelectionText(pt_list, AMOUNT_LIST_IDX_IT));

  // N° de relevé
  pt_list = [self objectPtrId:SearchStatementList];
  LstSetSelection(pt_list, 0);
  CtlSetLabel([self objectPtrId:SearchStatementPopup],
	      LstGetSelectionText(pt_list, 0));

  // Critères
  pt_list = [self objectPtrId:SearchOpList];
  LstSetSelection(pt_list, 0);
  CtlSetLabel([self objectPtrId:SearchOpPopup],
	      LstGetSelectionText(pt_list, 0));

  // Action
  pt_list = [self objectPtrId:SearchActionList];
  LstSetSelection(pt_list, 0);
  CtlSetLabel([self objectPtrId:SearchActionPopup],
	      LstGetSelectionText(pt_list, 0));

  [super open];

  // On place le focus sur le premier champ de la boîte
  [self focusObject:SearchDescValue];

  return true;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case SearchBegDate:
  case SearchEndDate:
    [self dateInc:ps_select->controlID
	  date:&self->rs_date[ps_select->controlID == SearchEndDate]
	  pressedButton:ps_select->controlID format:self->e_format];
    break;

  case SearchTypePopup:
    [[oMaTirelire type] popupList:self->pv_popup_types];
    break;

  case SearchModePopup:
    [[oMaTirelire mode] popupList:self->pv_popup_modes];
    break;

  case SearchAmountPopup:
  {
    ListType *pt_list = [self objectPtrId:SearchAmountList];
    UInt16 index;

    index = LstPopupList(pt_list);
    if (index != noListSelection)
    {
      Boolean b_show = (index == AMOUNT_LIST_IDX_IT);
      UInt16 ruh_objs[] =
      {
	SET_SHOW(SearchAmountBetween, b_show),
	SET_SHOW(SearchAmount2Sign, b_show),
	SET_SHOW(SearchAmount2, b_show),
	SET_SHOW(SearchAmountEnd, b_show),
	0,
      };

      [self showHideIds:ruh_objs];

      CtlSetLabel(ps_select->pControl, LstGetSelectionText(pt_list, index));
    }
  }
  break;

  case SearchAmount1Sign:
  case SearchAmount2Sign:
    [self selTriggerSignChange:ps_select];
    break;

  case SearchSearch:
    [self search];
    break;

  case SearchCancel:
    [self returnToLastForm];
    break;

  default:
    return false;
  }

  return true;
}


- (Boolean)ctlRepeat:(struct ctlRepeat *)ps_repeat
{
  UInt16 uh_button;

  switch (ps_repeat->controlID)
  {
  case SearchBegDateUp:
  case SearchBegDateDown:
    uh_button = SearchBegDate;
    break;

  case SearchEndDateUp:
  case SearchEndDateDown:
    uh_button = SearchEndDate;
    break;

  default:
    return false;
  }

  [self dateInc:uh_button date:&self->rs_date[uh_button == SearchEndDate]
	pressedButton:ps_repeat->controlID format:self->e_format];

  // On retourne toujours false sinon la répétition s'arrête
  return false;
}


- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key
{
  UInt16 fld_id;

  // On laisse la main à Papa pour gérer les déplacements entre champs
  // et les touches spéciales...
  if ([super keyDown:ps_key])
    return true;

  fld_id = FrmGetFocus(self->pt_frm);

  if (fld_id != noFocus)
    switch (FrmGetObjectId(self->pt_frm, fld_id))
    {
    case SearchChequeNumFrom:
    case SearchChequeNumTo:
    case SearchStatementNum:
      if ([self keyFilter:KEY_FILTER_INT | fld_id for:ps_key] == true)
	return true;
      break;

    case SearchAmount1:
    case SearchAmount2:
      if ([self keyFilter:KEY_FILTER_FLOAT | fld_id for:ps_key] == true)
	return true;
      break;
    }

  return false;
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  if (UPD_CODE(ps_update->updateCode) == frmMaTiUpdateList)
  {
    Transaction *oTransactions = [oMaTirelire transaction];
    Char ra_account_name[dmCategoryLength];
    UInt16 uh_id;

    CategoryGetName(oTransactions->db,
		    oTransactions->ps_prefs->ul_cur_category, ra_account_name);

    // La liste des types a changé
    if (ps_update->updateCode & frmMaTiUpdateListTypes)
    {
      Type *oTypes = [oMaTirelire type];

      uh_id = [oTypes popupListGet:self->pv_popup_types];

      [oTypes popupListFree:self->pv_popup_types];

      // On vient d'effacer le type actuellement sélectionné
      if (uh_id < TYPE_UNFILED
	  && [oTypes getCachedIndexFromID:uh_id] == ITEM_FREE_ID)
	uh_id = ITEM_ANY;

      self->pv_popup_types = [oTypes popupListInit:SearchTypeList
				     form:self->pt_frm
				     Id:(uh_id | TYPE_ADD_ANY_LINE)
				     forAccount:ra_account_name];
    }

    // La liste des modes a changé
    if (ps_update->updateCode & frmMaTiUpdateListModes)
    {
      Mode *oModes = [oMaTirelire mode];

      uh_id = [oModes popupListGet:self->pv_popup_modes];

      [oModes popupListFree:self->pv_popup_modes];

      // On vient d'effacer le mode actuellement sélectionné
      if (uh_id < MODE_UNKNOWN
	  && [oModes getCachedIndexFromID:uh_id] == ITEM_FREE_ID)
	uh_id = ITEM_ANY;

      self->pv_popup_modes
	= [oModes popupListInit:SearchModeList
		  form:self->pt_frm
		  Id:(uh_id | ITEM_ADD_UNKNOWN_LINE | ITEM_ADD_ANY_LINE)
		  forAccount:ra_account_name];
    }
  }

  return [super callerUpdate:ps_update];
}


- (UInt16)dateIsBound:(UInt16)uh_date_id date:(DateType**)pps_date
{
  if (CtlGetValue([self objectPtrId:SearchDatesBound]))
  {
    if (uh_date_id == SearchBegDate)
    {
      *pps_date = &self->rs_date[1];
      return SearchEndDate;
    }

    *pps_date = &self->rs_date[0];
    return SearchBegDate;
  }

  return 0;
}


- (void)search
{
  Transaction *oTransactions = [oMaTirelire transaction];
  struct s_transaction *ps_tr;
  PROGRESSBAR_DECL;
  union u_rec_flags u_flags;
  UInt16 index, uh_num, uh_account, uh_total, uh_action;
  Boolean b_dirty;

  uh_account = oTransactions->ps_prefs->ul_cur_category;

  uh_total = DmNumRecords(oTransactions->db);

  uh_action = LstGetSelection([self objectPtrId:SearchActionList]);

  // Il faut d'abord démarquer toutes les opérations
  if (uh_action == 1)
  {
    uh_num = 0;
    index = 0;

    // Démarquage
    PROGRESSBAR_BEGIN(uh_total, strProgressBarSearchUnflagAll);

    while (DmQueryNextInCategory(oTransactions->db, &index, uh_account))
    {
      ps_tr = [oTransactions recordGetAtId:index];
      if (ps_tr != NULL)
      {
	b_dirty = ps_tr->ui_rec_marked;

	if (b_dirty)
	{
	  u_flags = ps_tr->u_flags;
	  u_flags.s_bit.ui_marked = 0;

	  DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
		  &u_flags, sizeof(u_flags));
	  uh_num++;
	}

	[oTransactions recordRelease:b_dirty];
      }

      PROGRESSBAR_INLOOP(index, 50); // OK

      index++;			// Suivant
    }

    PROGRESSBAR_END;

    // On vient de démarquer au moins une opération, il faut le signaler à Papa
    if (uh_num > 0)
      self->ui_update_mati_list
	|= (frmMaTiUpdateList | frmMaTiUpdateListTransactions);
  }

  uh_num = 0;
  index = 0;

  //
  // Recherche
  {
    Type *oTypes = [oMaTirelire type];
    UInt32 rul_types[BYTESFORBITS(NUM_TYPES)];
    UInt32 ui_rec_flags_mask, ui_rec_flags_value;
    UInt32 ui_cheque1, ui_cheque2, ui_stmt_num;
    struct s_rec_options s_options;
    void *rrv_labels[7][2], **ppv_label;
    void *pv_start, *pv_after_options, **ppv_previous;
    Char *pa_wildcard;
    t_amount l_amount1, l_amount2;
    UInt16 uh_op, uh_tmp, uh_beg_date, uh_end_date, uh_unique_type;
    Boolean b_flag, b_options = false;

    // Inits to avoid GCC warnings
    pv_after_options = NULL;
    pa_wildcard = NULL;
    uh_beg_date = uh_end_date = 0;
    // ***************************

    // Faut-il marquer/démarquer les propriétés du compte
    b_dirty = false;

#define TEST_OK		1
#define TEST_FAILED	0

#define TEST(test) ({ ppv_label += 2; goto *ppv_label[test]; })

#define PREVIOUS_LABEL(label) *ppv_previous = &&label

#define PREPARE_OP				    \
    if (uh_op > 0) /* OU || OU inversé */	    \
    {						    \
      ppv_label[TEST_OK] = &&ok;		    \
      ppv_previous = &ppv_label[TEST_FAILED];	    \
    }						    \
    else /* ET */				    \
    {						    \
      ppv_previous = &ppv_label[TEST_OK];	    \
      ppv_label[TEST_FAILED] = &&next;		    \
    }						    \
    ppv_label += 2

#define PREPARE_LABELS_OP(label)		\
    ({						\
      PREVIOUS_LABEL(label);			\
      PREPARE_OP;				\
    })

    pv_start = NULL;
    ppv_previous = &pv_start;
    ppv_label = rrv_labels[0];

    // Opérateur de liaison de critères
    uh_op = LstGetSelection([self objectPtrId:SearchOpList]);

    // Intervalle de date
    if (CtlGetValue([self objectPtrId:SearchDates]))
    {
      uh_beg_date = DateToInt(self->rs_date[0]);
      uh_end_date = DateToInt(self->rs_date[1]);
      if (uh_beg_date > uh_end_date)
      {
	uh_beg_date = uh_end_date;
	uh_end_date = DateToInt(self->rs_date[0]);
      }

      // En fonction de la date de valeur
      if (CtlGetValue([self objectPtrId:SearchValueDate]))
      {
	b_options = true;
	pv_start = &&val_date_it;
      }
      else
	pv_start = &&date_it;

      // La suite dépend de l'opérateur utilisé
      PREPARE_OP;
    }

    ui_rec_flags_value = ui_rec_flags_mask = 0;

    // Au moins un type
    uh_unique_type = [oTypes popupListGet:self->pv_popup_types];
    if (uh_unique_type != ITEM_ANY)
    {
      // Avec toute sa descendance
      if (CtlGetValue([self objectPtrId:SearchTypeChildren]))
      {
	[oTypes setBitFamily:rul_types forType:uh_unique_type];

	PREVIOUS_LABEL(many_types);
      }
      // Seulement un unique type
      else
	PREVIOUS_LABEL(one_type);

      PREPARE_OP;
    }

    // Un mode
    uh_tmp = [[oMaTirelire mode] popupListGet:self->pv_popup_modes];
    if (uh_tmp != ITEM_ANY)
    {
      ui_rec_flags_mask |= RECORD_MODE_MASK;
      ui_rec_flags_value |= ((UInt32)uh_tmp << RECORD_MODE_SHIFT);
    }

    // Un type et/ou un mode et/ou un autre flag
    if (ui_rec_flags_mask != 0)
      PREPARE_LABELS_OP(flags);

    // Wildcard sur la description
    if (CtlGetValue([self objectPtrId:SearchDesc])
	&& (pa_wildcard
	    = FldGetTextPtr([self objectPtrId:SearchDescValue])) != NULL
	&& *pa_wildcard != '\0')
    {
      Char *pa_cur;
      WChar wa_chr;

      b_options = true;

      // On analyse la recherche pour voir s'il s'agit d'un wildcard ou non
      pa_cur = pa_wildcard + TxtGlueGetNextChar(pa_wildcard, 0, &wa_chr);
      switch (wa_chr)
      {
      case '!':
      case '^':
	PREVIOUS_LABEL(desc_wildcard);
	break;

      default:
	for (;;)
	{
	  switch (wa_chr)
	  {
	  case '\0':
	    PREVIOUS_LABEL(desc);
	    goto desc_done;

	  case '\\':
	  case '*':
	  case '?':
	    PREVIOUS_LABEL(desc_wildcard);
	    goto desc_done;
	  }

	  pa_cur += TxtGlueGetNextChar(pa_cur, 0, &wa_chr);
	}
	// Jamais atteint
      }

  desc_done:
      PREPARE_OP;
    }

    // Montant
    if (CtlGetValue([self objectPtrId:SearchAmount]))
    {
      UInt16 uh_amount_op;
      Boolean b_amount1, b_amount2;

      uh_amount_op = LstGetSelection([self objectPtrId:SearchAmountList]);

      b_amount1 = [self checkField:SearchAmount1
			flags:(FLD_CHECK_NOALERT|FLD_CHECK_VOID
			       |FLD_SELTRIGGER_SIGN|FLD_TYPE_FDWORD)
			resultIn:&l_amount1 fieldName:FLD_NO_NAME];

      if (uh_amount_op == AMOUNT_LIST_IDX_IT)
      {
	b_amount2 = [self checkField:SearchAmount2
			  flags:(FLD_CHECK_NOALERT|FLD_CHECK_VOID
				 |FLD_SELTRIGGER_SIGN|FLD_TYPE_FDWORD)
			  resultIn:&l_amount2 fieldName:FLD_NO_NAME];
	if (b_amount2 == false)
	  uh_amount_op = AMOUNT_LIST_IDX_GTE; // Pas de borne supérieure => '>='
	else if (b_amount1 == false)
	{
	  b_amount1 = true;
	  l_amount1 = l_amount2;
	  uh_amount_op = AMOUNT_LIST_IDX_LTE; // Pas de borne inférieure => '<='
	}
      }

      // Il faut au moins le premier montant
      if (b_amount1)
      {
	switch (uh_amount_op)
	{
	case AMOUNT_LIST_IDX_EQ: // '='
	  PREVIOUS_LABEL(amount_eq);
	  break;

	case AMOUNT_LIST_IDX_GT: // '>'
	  PREVIOUS_LABEL(amount_gt);
	  break;

	case AMOUNT_LIST_IDX_GTE: // '>='
	  PREVIOUS_LABEL(amount_gte);
	  break;

	case AMOUNT_LIST_IDX_LT: // '<'
	  PREVIOUS_LABEL(amount_lt);
	  break;

	case AMOUNT_LIST_IDX_LTE: // '>='
	  PREVIOUS_LABEL(amount_lte);
	  break;

	case AMOUNT_LIST_IDX_IT: // { 1 - 2 }
	  if (l_amount1 > l_amount2)
	  {
	    t_amount l_tmp = l_amount2;
	    l_amount2 = l_amount1;
	    l_amount1 = l_tmp;
	  }

	  PREVIOUS_LABEL(amount_it);
	  break;
	}

	PREPARE_OP;
      }
    }

    // Numéro de chèque
    if (CtlGetValue([self objectPtrId:SearchChequeNum]))
    {
      Boolean b_chq1, b_chq2;

      b_options = true;

      b_chq1 = [self checkField:SearchChequeNumFrom
		     flags:FLD_CHECK_NOALERT|FLD_TYPE_DWORD|FLD_CHECK_VOID
		     resultIn:&ui_cheque1 fieldName:FLD_NO_NAME];

      b_chq2 = [self checkField:SearchChequeNumTo
		     flags:FLD_CHECK_NOALERT|FLD_TYPE_DWORD|FLD_CHECK_VOID
		     resultIn:&ui_cheque2 fieldName:FLD_NO_NAME];

      // Au moins un numéro de chèque
      if (b_chq1 || b_chq2)
      {
	// Le premier numéro est vide, donc on prend le second
	if (b_chq1 == false)
	{
	  ui_cheque1 = ui_cheque2;
	  b_chq2 = false;
	}

	// Un seul numéro de chèque
	if (b_chq2 == false)
	  PREVIOUS_LABEL(cheque);
	// Intervalle de numéros de chèque
	else
	{
	  if (ui_cheque1 > ui_cheque2)
	  {
	    UInt32 ui_tmp = ui_cheque2;
	    ui_cheque2 = ui_cheque1;
	    ui_cheque1 = ui_tmp;
	  }
	  PREVIOUS_LABEL(cheque_it);
	}

	PREPARE_OP;
      }
    }

    // Numéro de relevé
    if (CtlGetValue([self objectPtrId:SearchStatement])
	&& [self checkField:SearchStatementNum
		 flags:FLD_CHECK_NOALERT|FLD_TYPE_DWORD|FLD_CHECK_VOID
		 resultIn:&ui_stmt_num fieldName:FLD_NO_NAME])
    {
      b_options = true;

      switch (LstGetSelection([self objectPtrId:SearchStatementList]))
      {
      case 0:			// Juste le ...
	PREVIOUS_LABEL(only_stmt);
	break;
      case 1:			// À partir du ...
	PREVIOUS_LABEL(from_stmt);
	break;
      default:			// Jusqu'au ...
	b_dirty = true;		// Il faut marquer les propriétés du compte
	PREVIOUS_LABEL(until_stmt);
	break;
      }

      PREPARE_OP;
    }

    // S'il y a au moins un critère
    if (pv_start != NULL)
    {
      // Action à effectuer : marquage ou démarquage
      b_flag = (uh_action != 2);

      // Lorsque tous les tests auront été effectué
      if (uh_op == 1)		// OU : Aucun n'a réussi => échec
	*ppv_previous = &&next;
      else			// OU inversé : Aucun n'a réussi => OK
	*ppv_previous = &&ok;	// ET : Tous ont réussi => OK

      // S'il y a des options à charger
      if (b_options)
      {
	pv_after_options = pv_start;
	pv_start = &&load_options;
      }

      PROGRESSBAR_BEGIN(uh_total, strProgressBarSearch);

      // Les propriétés du compte. Il faut les sauter, sauf pour le
      // cas d'une recherche "jusqu'au numéro de relevé" qui a mis
      // b_dirty à true plus haut
      ps_tr = (struct s_transaction*)
	[oTransactions accountProperties:uh_account | ACCOUNT_PROP_RECORDGET
		       index:&index];
      if (b_dirty && ps_tr->ui_rec_marked != b_flag)
	goto ok;
      else
	goto next;

      while (DmQueryNextInCategory(oTransactions->db, &index, uh_account))
      {
	ps_tr = [oTransactions recordGetAtId:index];
	if (ps_tr != NULL)
	{
	  b_dirty = false;

	  // Déjà marqué ou démarqué, inutile de chercher plus loin
	  if (ps_tr->ui_rec_marked == b_flag)
	    goto next;

	  ppv_label = rrv_labels[0];
	  ppv_label -= 2;

	  goto *pv_start;

      load_options:
	  options_extract(ps_tr, &s_options);
	  goto *pv_after_options;

      val_date_it:
	  uh_tmp = ps_tr->ui_rec_value_date
	    ? DateToInt(value_date_extract(ps_tr))
	    : DateToInt(ps_tr->s_date);
	  TEST(uh_tmp >= uh_beg_date && uh_tmp <= uh_end_date);

      date_it:
	  uh_tmp = DateToInt(ps_tr->s_date);
	  TEST(uh_tmp >= uh_beg_date && uh_tmp <= uh_end_date);

      many_types:
	  if (ps_tr->ui_rec_splits)
	  {
	    FOREACH_SPLIT_DECL; // __uh_num et ps_cur_split

	    if (b_options == false)
	      options_extract(ps_tr, &s_options);

	    // On parcourt toutes les sous-opérations
	    FOREACH_SPLIT(&s_options)
	    {
	      // Le type de cette sous-opération correspond, c'est OK
	      if (BIT_ISSET(ps_cur_split->ui_type, rul_types))
		TEST(1);
	    }
	  }

	  // Le type de l'opération OU le reste (qui peut être nul) si
	  // ventilation
	  TEST(BIT_ISSET(ps_tr->ui_rec_type, rul_types) != 0);

      one_type:
	  if (ps_tr->ui_rec_splits)
	  {
	    FOREACH_SPLIT_DECL; // __uh_num et ps_cur_split

	    if (b_options == false)
	      options_extract(ps_tr, &s_options);

	    // On parcourt toutes les sous-opérations
	    FOREACH_SPLIT(&s_options)
	    {
	      // Le type de cette sous-opération correspond, c'est OK
	      if (ps_cur_split->ui_type == uh_unique_type)
		TEST(1);
	    }
	  }

	  // Le type de l'opération OU le reste (qui peut être nul) si
	  // ventilation
          TEST(ps_tr->ui_rec_type == uh_unique_type);

      flags:
	  TEST((ps_tr->ui_rec_flags & ui_rec_flags_mask) == ui_rec_flags_value);

      desc_wildcard:
	  TEST(match(pa_wildcard, s_options.pa_note, false));

      desc:
	  TEST(StrStr(s_options.pa_note, pa_wildcard) != NULL);

      amount_eq:
	  TEST(ps_tr->l_amount == l_amount1);

      amount_gt:
	  TEST(ps_tr->l_amount > l_amount1);

      amount_lt:
	  TEST(ps_tr->l_amount < l_amount1);

      amount_gte:
	  TEST(ps_tr->l_amount >= l_amount1);

      amount_lte:
	  TEST(ps_tr->l_amount <= l_amount1);

      amount_it:
	  TEST(ps_tr->l_amount >= l_amount1 && ps_tr->l_amount <= l_amount2);

      cheque:
	  TEST(ps_tr->ui_rec_check_num
	       && s_options.ps_check_num->ui_check_num == ui_cheque1);

      cheque_it:
	  TEST(ps_tr->ui_rec_check_num
	       && s_options.ps_check_num->ui_check_num >= ui_cheque1
	       && s_options.ps_check_num->ui_check_num <= ui_cheque2);

      only_stmt:
	  TEST(ps_tr->ui_rec_stmt_num
	       && s_options.ps_stmt_num->ui_stmt_num == ui_stmt_num);

      from_stmt:
	  TEST(ps_tr->ui_rec_stmt_num
	       && s_options.ps_stmt_num->ui_stmt_num >= ui_stmt_num);

      until_stmt:
	  TEST(ps_tr->ui_rec_stmt_num
	       && s_options.ps_stmt_num->ui_stmt_num <= ui_stmt_num);

      ok:
	  b_dirty = true;

	  u_flags = ps_tr->u_flags;
	  u_flags.s_bit.ui_marked = b_flag;

	  DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
		  &u_flags, sizeof(u_flags));
	  uh_num++;

      next:
	  [oTransactions recordRelease:b_dirty];
	}

	PROGRESSBAR_INLOOP(index, 25); // OK

	index++;			// Suivant
      }

      PROGRESSBAR_END;
    }
  }

  // Aucune opération trouvée
  if (uh_num == 0)
    FrmAlert(alertSearchNone);
  // Au moins une opération trouvée & marquée
  else
  {
    Char ra_num[5 + 1];

    StrIToA(ra_num, uh_num);

    if (FrmCustomAlert(alertSearchMany, ra_num, " ", " ") == 1)
      FrmPopupForm(CustomListFormIdx | CLIST_SUBFORM_TRANS_FLAGGED);

    // Au moins une opération a été marquée, il faut le dire à Papa
    self->ui_update_mati_list
      |= (frmMaTiUpdateList | frmMaTiUpdateListTransactions);
  }
}

@end
