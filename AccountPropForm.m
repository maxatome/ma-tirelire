/* 
 * AccountPropForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mar oct 12 21:07:48 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jul  6 14:39:40 2007
 * Update Count    : 22
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: AccountPropForm.m,v $
 * Revision 1.15  2008/01/14 17:09:32  max
 * Switch to new mcc.
 *
 * Revision 1.14  2006/11/04 23:47:52  max
 * Use StatsTransFlaggedScrollList instead of StatsTransScrollList.
 * Use -selTriggerSignChange: to handle automatic amounts signs.
 *
 * Revision 1.13  2006/10/05 19:08:41  max
 * Add a "Transaction" tab and the "keep last date" option.
 *
 * Revision 1.12  2006/06/23 13:24:43  max
 * Now call -focusObject: instead of FrmSetFocus() to set focus to a field.
 *
 * Revision 1.11  2006/04/25 08:41:24  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 * -ctlSelect: calls now super one to handle tabs clicks.
 * Don't take into account vchrHardPower char in hard keys handling.
 *
 * Revision 1.10  2005/11/19 16:51:36  max
 * Add alertMemErrNotEnoughSpace alert box.
 *
 * Revision 1.9  2005/08/20 13:06:37  max
 * Can now be called from the flagged list screen.
 * Flag state now appears in account properties.
 * Updates are now genericaly managed by MaTiForm.
 *
 * Revision 1.8  2005/05/18 19:59:58  max
 * Add -beforeOpen method.
 * Implement frmGotoEvent event.
 *
 * Revision 1.7  2005/05/08 12:12:47  max
 * sizeof(struct s_account_prop) gives one byte than needed, so use
 * ACCOUNT_PROP_SIZE macro instead.
 *
 * Revision 1.6  2005/03/27 15:38:18  max
 * sizeof(struct s_account_prop) gives not the real size of the
 * struct. So use ACCOUNT_PROP_SIZE instead.
 *
 * Revision 1.5  2005/03/02 19:02:32  max
 * Swap buttons in alertAccountChangeCurrency
 *
 * Revision 1.4  2005/02/21 20:44:55  max
 * Cheques number mandatory if at least one chequebook defined.
 *
 * Revision 1.3  2005/02/19 17:12:52  max
 * Account properties can now be called from everywhere.
 *
 * Next/previous account navigation revisited (via pageDownChr/pageUpChr
 * key).
 *
 * If M2 is bound to a hard key, this hard key cycles accounts as
 * pageDownChr.
 *
 * Revision 1.2  2005/02/13 00:06:17  max
 * Change prototype of -keyFilter:for:
 * It allows to detect and not block special keys in numeric fields.
 * Now the Select key of the 5-way works everywhere...
 *
 * Revision 1.1  2005/02/09 22:57:21  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_ACCOUNTPROPFORM
#include "AccountPropForm.h"

#include "MaTirelire.h"

#include "Transaction.h"
#include "AccountsListForm.h"
#include "CustomListForm.h"
#include "StatsTransFlaggedScrollList.h"

#include "float.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


@implementation AccountPropForm

- (AccountPropForm*)free
{
  [[oMaTirelire currency] popupListFree:self->pv_popup_currencies];

  return [super free];
}


- (Int16)editedAccount
{
  // Liste des comptes
  if ([(Object*)self->oPrevForm->oIsa isKindOf:AccountsListForm])
    return ((AccountsListForm*)self->oPrevForm)->h_account;

  // Liste des marqués
  if ([(Object*)self->oPrevForm->oIsa isKindOf:CustomListForm]
      && [(Object*)((CustomListForm*)self->oPrevForm)->oList->oIsa
		   isKindOf:StatsTransFlaggedScrollList])
    return ((StatsTransScrollList*)
	    ((CustomListForm*)self->oPrevForm)->oList)->u.uh_edited_account;

  // Autre classe : le compte courant
  return [oMaTirelire transaction]->ps_prefs->ul_cur_category;
}


- (AccountPropForm*)init
{
  self->uh_tabs_num = 4;

  return [super init];
}


- (Boolean)extractAndSave
{
  Transaction *oTransactions = [oMaTirelire transaction];
  struct s_account_prop *ps_account;
  Char ra_account_name[dmCategoryLength];
  Int16 h_category_index;
  UInt16 uh_account, uh_size, uh_note_size, uh_cheques_by_cbook;
  UInt16 uh_field_cb, uh_cb_index;
  Boolean b_change_currency = false;

  h_category_index = [self editedAccount];

  // Le nom du compte ne doit pas être vide
  if ([self checkField:AccountPropName flags:FLD_CHECK_VOID
	    resultIn:ra_account_name fieldName:strAccountPropName] == false)
    return false;

  // Vérification de la disponibilité du nom du compte
  uh_account = CategoryFind(oTransactions->db, ra_account_name);

  // New
  if (h_category_index < 0)
  {
    Char ra_tmp[dmCategoryLength];

    if (uh_account != dmAllCategories)
    {
      FrmAlert(alertAccountAlreadyExists);
      return false;
    }

    // On recherche le premier compte dispo
    for (uh_account = 0; uh_account < MAX_ACCOUNTS; uh_account++)
    {
      CategoryGetName(oTransactions->db, uh_account, ra_tmp);
      if (ra_tmp[0] == '\0')
	break;
    }

    if (uh_account == MAX_ACCOUNTS)
    {
      // XXX
      return false;
    }
  }
  // Edit
  else
  {
    if (uh_account != dmAllCategories && uh_account != h_category_index)
    {
      FrmAlert(alertAccountAlreadyExists);
      return false;
    }

    uh_account = h_category_index;
  }

  uh_note_size = FldGetTextLength([self objectPtrId:AccountPropNote]);
  uh_size = ACCOUNT_PROP_SIZE + uh_note_size; // \0 is in struct

  NEW_PTR(ps_account, uh_size, return false);

  MemSet(ps_account, ACCOUNT_PROP_SIZE, '\0');

  // On sauve le contenu du formulaire...
  ps_account->ui_acc_checked = 1;	// Toujours pointé...

  // Le marquage
  ps_account->ui_acc_marked = CtlGetValue([self objectPtrId:AccountPropFlag]);

  //
  // Onglet "Général"
  //
  // Devise du compte
  ps_account->ui_acc_currency
    = [[oMaTirelire currency] popupListGet:self->pv_popup_currencies];

  // La devise a changé ?
  if (h_category_index >= 0
      && self->h_orig_currency != ps_account->ui_acc_currency)
  {
    if (FrmAlert(alertAccountChangeCurrency) == 0)
      goto error;

    b_change_currency = true;
  }

  // Solde de départ
  if ([self checkField:AccountPropInitialBalance
	    flags:FLD_CHECK_VOID|FLD_SELTRIGGER_SIGN|FLD_TYPE_FDWORD
	    resultIn:&ps_account->l_amount
	    fieldName:strAccountPropInitialBalance] == false)
    goto error;

  // Gestion des numéros de relevé
  ps_account->ui_acc_stmt_num
    = CtlGetValue([self objectPtrId:AccountPropStatements]);

  // Alerte si compte à découvert
  ps_account->ui_acc_warning
    = CtlGetValue([self objectPtrId:AccountPropOverdrawnWarning]);

  // Seuil de découvert
  if ([self checkField:AccountPropOverdrawnThreshold
	    flags:FLD_CHECK_VOID|FLD_SELTRIGGER_SIGN|FLD_TYPE_FDWORD
	    resultIn:&ps_account->l_overdraft_thresold
	    fieldName:strAccountPropOverdrawnThreshold] == false)
    goto error;

  // Seuil de renflouement
  if ([self checkField:AccountPropNonOverdrawnThreshold
	    flags:FLD_CHECK_VOID|FLD_SELTRIGGER_SIGN|FLD_TYPE_FDWORD
	    resultIn:&ps_account->l_non_overdraft_thresold
	    fieldName:strAccountPropNonOverdrawnThreshold] == false)
    goto error;

  if (ps_account->l_non_overdraft_thresold < ps_account->l_overdraft_thresold)
  {
    FrmAlert(alertAccountPropInvalidOverdrawnThreshold);
    goto error;
  }

  //
  // Onglet "Opération"
  //

  // Conserver la dernière date saisie
  ps_account->ui_acc_take_last_date
    = CtlGetValue([self objectPtrId:AccountPropKeepLastDate]);


  //
  // Onglet "Chéquiers"
  //

  // Liste des chéquiers en cours
  for (uh_field_cb = AccountPropChequebook1, uh_cb_index = 0;
       uh_field_cb <= AccountPropChequebook4;
       uh_field_cb++)
  {
    if ([self checkField:uh_field_cb
	      flags:(FLD_CHECK_VOID|FLD_CHECK_NULL|FLD_TYPE_DWORD
		     |FLD_CHECK_NOALERT)
	      resultIn:&ps_account->rui_check_books[uh_cb_index]
	      fieldName:FLD_NO_NAME])
      uh_cb_index++;
  }

  // Chèques par chéquier (peut être 0 si pas de chéquier dans ce compte)
  if ([self checkField:AccountPropNumCheques
	    flags:(uh_cb_index > 0
		   ? FLD_CHECK_VOID|FLD_CHECK_NULL|FLD_TYPE_WORD
		   : FLD_TYPE_WORD)
	    resultIn:&uh_cheques_by_cbook
	    fieldName:strAccountPropNumCheques] == false)
    goto error;
  if (uh_cheques_by_cbook >= (1 << 6))
    uh_cheques_by_cbook = (1 << 6) - 1;
  ps_account->ui_acc_cheques_by_cbook = uh_cheques_by_cbook;

  //
  // Onglet "Infos"
  //
  // N° de compte
  [self checkField:AccountPropAccountNum flags:FLD_CHECK_NONE
	resultIn:ps_account->ra_number fieldName:FLD_NO_NAME];

  // Notes
  if (uh_note_size > 0)
    MemMove(ps_account->ra_note,
	    FldGetTextPtr([self objectPtrId:AccountPropNote]),
	    uh_note_size);
  ps_account->ra_note[uh_note_size] = '\0';


  // Sauvegarde des propriétés...
  if ([oTransactions save:ps_account size:uh_size
		     asId:&self->uh_account_index
		     asNew:h_category_index < 0] == false)
  {
    // XXX
    goto error;
  }

  // On mets le nouvel enregistrement dans la bonne catégorie
  if (h_category_index < 0)
    [oTransactions setCategory:uh_account forId:self->uh_account_index];

  // La devise a changé ?
  if (b_change_currency)
    [oTransactions account:uh_account changeCurrency:self->h_orig_currency];

  MemPtrFree(ps_account);

  // On peut renommer ou créer le compte
  CategorySetName(oTransactions->db, uh_account, ra_account_name);

  return true;

 error:
  if (ps_account != NULL)
    MemPtrFree(ps_account);

  return false;
}


- (void)fillWithAccount:(Int16)h_category_index
{
  Char ra_title[dmCategoryLength];
  Currency *oCurrencies = [oMaTirelire currency];
  struct s_account_prop s_prop;

  // New
  if (h_category_index < 0)
  {
    [self hideId:AccountPropDelete];

    // Le titre
    SysCopyStringResource(ra_title, strTitleNewAccountProp);

    //
    // Valeurs par défaut
    //

    MemSet(&s_prop, sizeof(s_prop), '\0');
    s_prop.ui_acc_cheques_by_cbook = 25; // Par défaut 25 chèques / chéquier
    s_prop.ui_acc_currency = [oCurrencies referenceId];

    // Pas de devise originale
    self->h_orig_currency = -1;
  }
  // Edit
  else
  {
    Transaction *oTransactions = [oMaTirelire transaction];
    struct s_account_prop *ps_prop;
    UInt16 index;

    ps_prop = [oTransactions accountProperties:h_category_index
			     index:&self->uh_account_index];

    MemMove(&s_prop, ps_prop, sizeof(s_prop));

    // La note
    [self replaceField:AccountPropNote withSTR:ps_prop->ra_note len:-1];

    MemPtrUnlock(ps_prop);

    // La devise originale
    self->h_orig_currency = s_prop.ui_acc_currency;

    // Le nom du compte
    CategoryGetName(oTransactions->db, h_category_index, ra_title);
    [self replaceField:AccountPropName withSTR:ra_title len:-1];

    // Le marquage
    CtlSetValue([self objectPtrId:AccountPropFlag], s_prop.ui_acc_marked);

    //
    // Général
    //
    // Gestion des numéros de relevé
    CtlSetValue([self objectPtrId:AccountPropStatements],
		s_prop.ui_acc_stmt_num);

    // Alerte si découvert
    CtlSetValue([self objectPtrId:AccountPropOverdrawnWarning],
		s_prop.ui_acc_warning);

    //
    // Opération
    //
    // Conserver la dernière date saisie
    CtlSetValue([self objectPtrId:AccountPropKeepLastDate],
		s_prop.ui_acc_take_last_date);

    //
    // Chéquiers
    //
    // Liste des chéquiers en cours
    for (index = 0; index < NUM_CHECK_BOOKS; index++)
      [self replaceField:(REPLACE_FIELD_EXT | AccountPropChequebook1) + index
	    withSTR:(Char*)s_prop.rui_check_books[index]
	    len:REPL_FIELD_DWORD | REPL_FIELD_EMPTY_IF_NULL];

    //
    // Infos
    //
    // Numéro de compte
    [self replaceField:AccountPropAccountNum withSTR:s_prop.ra_number len:-1];
  }

  FrmCopyTitle(self->pt_frm, ra_title);

  //
  // Général
  //
  // Devise du compte
  if (self->pv_popup_currencies == NULL)
    self->pv_popup_currencies
      = [oCurrencies popupListInit:AccountPropDeviseList
		     form:self->pt_frm
		     Id:(UInt16)s_prop.ui_acc_currency | ITEM_ADD_EDIT_LINE
		     forAccount:(char*)1];
  else
    [oCurrencies popupList:self->pv_popup_currencies
		 setSelection:(UInt16)s_prop.ui_acc_currency];

  // Solde de départ
  [self replaceField:REPLACE_FIELD_EXT | AccountPropInitialBalance
	withSTR:(Char*)s_prop.l_amount
	len:REPL_FIELD_FDWORD | REPL_FIELD_SELTRIGGER_SIGN];

  // Découvert
  [self replaceField:REPLACE_FIELD_EXT | AccountPropOverdrawnThreshold
	withSTR:(Char*)s_prop.l_overdraft_thresold
	len:REPL_FIELD_FDWORD | REPL_FIELD_SELTRIGGER_SIGN];

  // Renflouement
  [self replaceField:REPLACE_FIELD_EXT | AccountPropNonOverdrawnThreshold
	withSTR:(Char*)s_prop.l_non_overdraft_thresold
	len:REPL_FIELD_FDWORD | REPL_FIELD_SELTRIGGER_SIGN];

  //
  // Chéquiers
  //
  // Cheques per cheques book (si aucun, on ne remplit pas le champ)
  [self replaceField:REPLACE_FIELD_EXT | AccountPropNumCheques
	withSTR:(Char*)s_prop.ui_acc_cheques_by_cbook
	len:REPL_FIELD_DWORD | REPL_FIELD_EMPTY_IF_NULL];

  [self fieldUpdateScrollBar:AccountPropNoteScrollbar
	fieldPtr:[self objectPtrId:AccountPropNote]
	setScroll:true];
}


- (void)beforeOpen
{
  Int16 h_category_index;

  // Si on ne vient pas de la liste des comptes, on ne peut pas supprimer
  if ([(Object*)self->oPrevForm->oIsa isKindOf:AccountsListForm] == false)
    [self hideId:AccountPropDelete];

  h_category_index = [self editedAccount];

  [self fillWithAccount:h_category_index];

  // Si on est en mode gaucher, il faut inverser la note avec la barre
  // de scroll (quand on vient du -open)
  if ([oMaTirelire getPrefs]->ul_left_handed)
    [self swapLeft:AccountPropNote rightOnes:AccountPropNoteScrollbar, 0];
}


- (Boolean)open
{
  // Inits...
  [self beforeOpen];

  [super open];

  // On place le focus sur le nom du compte
  [self focusObject:AccountPropName];

  return true;
}


- (Boolean)goto:(struct frmGoto *)ps_goto
{
  FieldType *pt_field;

  // On annule l'indication de GotoEvent
  oMaTirelire->b_goto_event_pending = false;

  // Inits...
  [self beforeOpen];

  // Dans un onglet
  self->uh_tabs_current = TAB_ID_TO_NUM(ps_goto->matchFieldNum);

  [super open];

  pt_field = [self objectPtrId:ps_goto->matchFieldNum];
  if (pt_field != NULL)
  {
    /* Si c'est la description on la scrolle */
    if (ps_goto->matchFieldNum == AccountPropNote)
    {
      UInt16 uh_max_value, uh_scroll_pos, uh_text_height, uh_field_height;

      FldSetScrollPosition(pt_field, ps_goto->matchPos);

      FldGetScrollValues(pt_field, &uh_scroll_pos,
			 &uh_text_height, &uh_field_height);

      if (uh_text_height > uh_field_height)
	uh_max_value = uh_text_height - uh_field_height;
      else if (uh_scroll_pos)
	uh_max_value = uh_scroll_pos;
      else
	uh_max_value = 0;

      SclSetScrollBar([self objectPtrId:AccountPropNoteScrollbar],
		      uh_scroll_pos, 0, uh_max_value, uh_field_height - 1);
    }

    // On sélectionne tout...
    if ((Int16)ps_goto->matchPos < 0)
      FldSetSelection(pt_field, 0, FldGetTextLength(pt_field));
    // On sélectionne la bonne partie
    else
      FldSetSelection(pt_field, ps_goto->matchPos,
		      ps_goto->matchPos + ps_goto->matchLen);
  }

  return true;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  if ([super ctlSelect:ps_select])
    return true;

  switch (ps_select->controlID)
  {
  case AccountPropDevise:
    if ([[oMaTirelire currency] popupList:self->pv_popup_currencies]
	== ITEM_EDIT)
      // On lance la boîte d'édition des devises...
      FrmPopupForm(CurrenciesListFormIdx);
    break;

  case AccountPropInitialBalanceSign:
  case AccountPropOverdrawnThresholdSign:
  case AccountPropNonOverdrawnThresholdSign:
    [self selTriggerSignChange:ps_select];
    break;

  case AccountPropOK:
    if ([self extractAndSave] == false)
      break;

  end_with_update:
    self->ui_update_mati_list
      |= (frmMaTiUpdateList | frmMaTiUpdateListAccounts);

  case AccountPropCancel:
    [self returnToLastForm];
    break;

  case AccountPropDelete:
    if (FrmAlert(alertAccountDelete) != 0)
    {
      // Suppression effective du compte
      [[oMaTirelire transaction] deleteAccount:[self editedAccount]];
      goto end_with_update;
    }
    break;

  default:
    return false;
  }

  return true;
}


- (Boolean)sclRepeat:(struct sclRepeat *)ps_repeat
{
  [self fieldScrollBar:AccountPropNoteScrollbar
	linesToScroll:ps_repeat->newValue - ps_repeat->value update:false];

  return false;
}


- (Boolean)fldChanged:(struct fldChanged *)ps_fld_changed
{
  if (ps_fld_changed->fieldID == AccountPropNote)
  {
    [self fieldUpdateScrollBar:AccountPropNoteScrollbar
	  fieldPtr:ps_fld_changed->pField
	  setScroll:false];
    return true;
  }

  return false;
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  // La liste des devises a changé...
  if (UPD_ALLCODE(ps_update->updateCode)
      == (frmMaTiUpdateList | frmMaTiUpdateListCurrencies))
  {
    Currency *oCurrencies = [oMaTirelire currency];
    UInt16 uh_selected_currency;

    // On détruit, puis reconstruit la liste des devises...
    [oCurrencies popupListFree:self->pv_popup_currencies];

    if (self->h_orig_currency < 0)
      uh_selected_currency = [oCurrencies referenceId];
    else
      uh_selected_currency = self->h_orig_currency;

    self->pv_popup_currencies
      = [oCurrencies popupListInit:AccountPropDeviseList
		     form:self->pt_frm
		     Id:uh_selected_currency | ITEM_ADD_EDIT_LINE
		     forAccount:(char*)1];
  }

  return [super callerUpdate:ps_update];
}


- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key
{
  UInt16 fld_id;

  // On laisse la main à Papa pour gérer les déplacements entre champs...
  if ([super keyDown:ps_key])
    return true;

  if (ps_key->modifiers & virtualKeyMask)
  {
    switch (ps_key->chr)
    {
      // La touche directe
    case hardKeyMin ... hardKeyMax:
    case calcChr:
      // Passage au prochain compte
      if ((ps_key->modifiers & poweredOnKeyMask) == 0
	  // Sauf s'il s'agit du bouton d'allumage
	  && ps_key->chr != vchrHardPower)
      {
	ps_key->chr = pageDownChr;
	goto next_account;
      }
      break;

      // Les touches HAUT / BAS : compte précédent / seulement si Papa
      // est la liste des comptes
    case pageDownChr:
    case pageUpChr:
  next_account:
      if ([(Object*)self->oPrevForm->oIsa isKindOf:AccountsListForm])
      {
	// Si on n'est pas en phase de création
	if (((AccountsListForm*)self->oPrevForm)->h_account >= 0
	    // ET QUE la sauvegarde a fonctionné
	    && [self extractAndSave])
	{
	  UInt16 uh_next_account;

	  uh_next_account
	    = [[oMaTirelire transaction]
		selectNextAccount:ps_key->chr == pageDownChr
		of:((AccountsListForm*)self->oPrevForm)->h_account];

	  if (uh_next_account != dmAllCategories)
	  {
	    ((AccountsListForm*)self->oPrevForm)->h_account
	      = uh_next_account;

	    [self fillWithAccount:uh_next_account];
	    return true;      // Dans ce cas on considère comme traité
	  }
	}
      }
      break;
    }

    return false;		// On considère comme non traité
  }

  fld_id = FrmGetFocus(self->pt_frm);

  if (fld_id != noFocus)
  {
    UInt16 uh_id = FrmGetObjectId(self->pt_frm, fld_id);

    switch (uh_id)
    {
    case AccountPropInitialBalance:
    case AccountPropOverdrawnThreshold:
    case AccountPropNonOverdrawnThreshold:
      return [self keyFilter:KEY_FILTER_FLOAT | KEY_SELTRIGGER_SIGN | fld_id
		   for:ps_key];

    case AccountPropNumCheques:
    case AccountPropChequebook1 ... AccountPropChequebook4:
      return [self keyFilter:KEY_FILTER_INT | fld_id for:ps_key];
    }
  }

  return false;
}

@end
