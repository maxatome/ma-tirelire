/* 
 * TransForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mon May 12 23:28:00 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb  1 17:20:03 2008
 * Update Count    : 368
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: TransForm.m,v $
 * Revision 1.27  2008/02/01 17:31:40  max
 * Use new attribute rb_goto_buttons[] to handle PREV/NEXT.
 * s/WinPrintf/alert_error_str/g
 *
 * Revision 1.26  2008/01/14 15:51:36  max
 * Switch to new mcc.
 * Handle signed splits.
 * New -initTypesPopup:forAccount:.
 * Delete -typesPopupFlags.
 * -expandMacro:with: now correctly handle sign.
 * New %~ macro token prefix.
 * New %V macro token.
 * Verify transfer link before displaying it.
 *
 * Revision 1.25  2006/11/04 23:48:23  max
 * Use FOREACH_SPLIT* macros.
 * Minor changes.
 * self->oSplits could be bad initialized when changing to another
 * transaction: corrected.
 * Goto event handle goto on splits.
 * Redraw problems occured when not in the first tab and changing to
 * another transaction: corrected.
 *
 * Revision 1.24  2006/10/05 19:09:02  max
 * Handle "keep last date" account properties option.
 *
 * Revision 1.23  2006/07/03 15:03:28  max
 * Add -resetButtonNext: method.
 * Now can correct transaction amount when splits sum is too big.
 * Save transaction even when only the account change.
 * oTransactions->ps_prefs->ul_cur_category only modified when coming
 * from TransListForm.
 * Statement num management now use transaction account instead of
 * oTransactions->ps_prefs->ul_cur_category.
 *
 * Revision 1.22  2006/06/30 08:12:36  max
 * Handle correctly Treo600 navigator API.
 *
 * Revision 1.21  2006/06/28 09:47:44  max
 * Fix comment typo when using mcc.
 *
 * Revision 1.20  2006/06/28 09:42:16  max
 * Rework TransForm call when <0-9,.> char typed in list.
 * Add shortcut to the TransForm calling procedure.
 * Add -gotoNext: method.
 * Really save only when the transaction contents change.
 * Verify current tab before showing any object.
 * Add prev/next buttons, menu items and page UP/DOWN handling.
 *
 * Revision 1.19  2006/06/23 15:34:29  max
 * Delete TransMenu*NotCheck and TransMenu*Flag menu entries.
 *
 * Revision 1.18  2006/06/23 13:25:23  max
 * No more need of fiveway.h with PalmSDK installed.
 * Now call -focusObject: instead of FrmSetFocus() to set focus to a field.
 * Set the Palm Nav mode to FocusMode.
 * Select one item in the repeat end popup menu.
 *
 * Revision 1.17  2006/06/19 12:24:13  max
 * In splits list, display type when description is empty.
 * AboutForm calls from menu are now handled by MaTiForm.
 *
 * Revision 1.16  2006/04/25 08:47:33  max
 * Add -isXfer: and -typesPopupFlags methods.
 * Add splits handling (many methods).
 * Now handle type sign.
 * -beforeOpen now called first in -open.
 * Redraws reworked (continue).
 * Possible bug when changing the date/time then switching to the linked
 * transaction. Corrected.
 * Handle new frmMaTiUpdateTransForm* flags.
 *
 * Revision 1.15  2005/11/19 16:56:35  max
 * Can be called from the new RepeatsListForm screen.
 * Tab navigation via T|T 5-way moved in BaseForm.m
 *
 * Revision 1.14  2005/10/11 19:12:06  max
 * Handle ClearingListForm caller.
 * Handle uh_internal_flag in s_transaction flags.
 *
 * Revision 1.13  2005/08/31 19:43:11  max
 * In currency tab, add a second rate line.
 *
 * Revision 1.12  2005/08/31 19:38:53  max
 * *** empty log message ***
 *
 * Revision 1.11  2005/08/20 13:07:09  max
 * Can now be called from stats results or flagged screen.
 * Prepare switching to 64 bits amounts.
 * Updates are now genericaly managed by MaTiForm.
 * Reload modes, types and descriptions when changing account.
 * No longer refer to oTransactions->ps_prefs->ul_cur_category but to the
 * transaction account instead.
 * Reset the pending frmGotoEvent.
 *
 * Revision 1.10  2005/05/18 20:00:03  max
 * Add -beforeOpen method.
 * Implement frmGotoEvent event.
 *
 * Revision 1.9  2005/05/08 12:13:06  max
 * Currencies management reworked:
 * - now the main sum never change when another currency is selected;
 * - re-selection of the same currency updates currency tab contents.
 *
 * Revision 1.8  2005/03/27 15:38:26  max
 * Xfer option unique ID restricted to 24 bits.
 * Number of occurences prefixed by a 0 are re-computed.
 *
 * Revision 1.7  2005/03/20 22:28:26  max
 * Add alarm management
 * Auto-cheque number method reworked
 * Auto-cheque selection now select the first "auto-cheque" mode
 * When copying a transaction with "original" date, copy the valuable
 * date too if present.
 * Statement management popup: clicking outside now cancel (un)clearing
 * Changing occurences field contents updates the repeat end date at the
 * same time
 * Left and right keys of the 5-way navigator now cycle tabs
 *
 * The conversion specifications, in macros, can now contain optional
 * field, as follows: %-Z, %-nZ, %+Z, or %+nZ, where `n' is a number (1
 * or 2 digits) and Z is one of D, T, M, m, Y or d.
 * For example:
 * - %M is replaced by the full month name of the transaction;
 * - %-2M is replaced by the full month name of the transaction less two;
 * - %+2M is replaced by the full month name of the transaction plus two;
 * - %-M is same as %-1M;
 * - %+M is same as %+1M;
 *
 * For %D, the optional number represents days and for %T, it represents
 * hours.
 *
 * Revision 1.6  2005/03/02 19:54:30  max
 * OpCurrencyAmount was not keyFilter:'ed. Corrected.
 *
 * Revision 1.5  2005/03/02 19:02:45  max
 * -checkNumAuto now returns true when a cheque number is filled.
 * Add progress bars for slow operations.
 * Add "2 years" repeat choice.
 * Swap buttons in alertTransactionDelete.
 *
 * Macros descriptions can now contain conversion specifications. A
 * conversion specification consists of a percent sign % and one other
 * character. The conversion specifications are copied to the buffer
 * after expansion as follows:
 * - %D is replaced by the date of the transaction in short format;
 * - %T is replaced by the time of the transaction;
 * - %M is replaced by the full month name of the transaction;
 * - %m is replaced by the month of the transaction as a decimal number;
 * - %Y is replaced by the year of the transaction;
 * - %d is replaced by the day of the transaction;
 * - %A is replaced by the account name of the transaction;
 * - %B is replaced by the database name of the transaction;
 * - %x is replaced by the transfer account name of the transaction;
 * - %X is replaced by "AAA -> BBB" where AAA is the account of the
 *   transaction and BBB is the transfert account if the transaction is a
 *   debit, or the inverse if the transaction is a credit.
 * - %% is replaced by a single %
 *
 * Revision 1.4  2005/02/21 20:43:53  max
 * Add auto statement number management when clearing.
 * Add auto cheque number management.
 *
 * Revision 1.3  2005/02/19 17:10:02  max
 * Menu added.
 *
 * Revision 1.2  2005/02/13 00:06:18  max
 * Change prototype of -keyFilter:for:
 * It allows to detect and not block special keys in numeric fields.
 * Now the Select key of the 5-way works everywhere...
 *
 * Revision 1.1  2005/02/09 22:57:23  max
 * First import.
 *
 * ==================== RCS ==================== */

#include <PalmOSGlue/FrmGlue.h>
#include <PalmOSGlue/TxtGlue.h>
#include <Common/System/HsNavCommon.h>
#include <68k/System/HsNav.h>
#include <Common/System/palmOneNavigator.h>

#define EXTERN_TRANSFORM
#include "TransForm.h"

#include "MaTirelire.h"
#include "TransListForm.h"
#include "TypesListForm.h"
#include "DescModesListForm.h"
#include "CustomListForm.h"
#include "StatsTransScrollList.h"
#include "ClearingListForm.h"
#include "RepeatsListForm.h"

#include "ProgressBar.h"

#include "alarm.h"
#include "float.h"

#include "graph_defs.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX

//
// Pour chaque ligne de la liste de ventilation
static void __splits_list_draw(Int16 h_line, RectangleType *prec_bounds,
			       Char **ppa_lines)
{
  TransForm *oTransForm = (TransForm*)ppa_lines;
  MemHandle pv_split;
  struct s_rec_one_sub_transaction *ps_split;
  t_amount l_amount;
  Char ra_buf[1 + AMOUNT_LEN + 1];
  UInt16 uh_save_font, uh_len, uh_width;
  Int16 h_width;
  Boolean b_colored = false;

  // 42 = largeur de -99999,99 dans la fonte std
  // (36 pour 99999 en bold et 37 pour 99,99M en bold)
  uh_width = prec_bounds->extent.x - 42;

  if (h_line == 0)
  {
    Char ra_remain[64];

    uh_save_font = FntSetFont(boldFont);

    SysCopyStringResource(ra_remain, strOpFormSplitsRemain);

    uh_len = StrLen(ra_remain);
    h_width = prepare_truncating(ra_remain, &uh_len, uh_width);
    WinDrawTruncatedChars(ra_remain, uh_len,
			  prec_bounds->topLeft.x, prec_bounds->topLeft.y,
			  h_width);

    // La différence
    [oTransForm checkField:OpAmount flags:FLD_TYPE_FDWORD
		resultIn:&l_amount fieldName:FLD_NO_NAME];

    l_amount -= oTransForm->l_splits_sum;
  }
  else
  {
    uh_save_font = FntSetFont(stdFont);

    pv_split = [oTransForm->oSplits fetch:h_line - 1];
    ps_split = MemHandleLock(pv_split);

    // Le label doit être le type
    if ([oMaTirelire transaction]->ps_prefs->ul_splits_label
	|| ps_split->ra_desc[0] == '\0') // OU BIEN description vide
    {
      Char *pa_label = [[oMaTirelire type] fullNameOfId:ps_split->ui_type
					   len:&uh_len truncatedTo:uh_width];

      WinDrawChars(pa_label, uh_len,
		   prec_bounds->topLeft.x, prec_bounds->topLeft.y);

      MemPtrFree(pa_label);
    }
    else
    {
      uh_len = StrLen(ps_split->ra_desc);
      h_width = prepare_truncating(ps_split->ra_desc, &uh_len, uh_width);
      WinDrawTruncatedChars(ps_split->ra_desc, uh_len,
			    prec_bounds->topLeft.x, prec_bounds->topLeft.y,
			    h_width);
    }

    // La somme
    l_amount = ps_split->l_amount;

    MemHandleUnlock(pv_split);
  }

  // Si ce montant est négatif (en fait opposé du signe de
  // l'opération), il faut le colorier en la couleur des débits
  if (l_amount < 0 && oMaTirelire->uh_color_enabled)
  {
    struct s_mati_prefs *ps_prefs = &oMaTirelire->s_prefs;
    IndexedColorType a_color;
	
    if (ps_prefs->uh_list_flags & USER_DEBIT_COLOR)
    {
      a_color = ps_prefs->ra_colors[COLOR_DEBIT];

      // Si la couleur de débit...
      //  ...n'est pas la même que celle du fond des listes
      if (a_color != UIColorGetTableEntryIndex(UIObjectFill)
	  // NI QUE celle du fond sélectionné des listes
	  && a_color != UIColorGetTableEntryIndex(UIObjectSelectedFill))
      {
	WinPushDrawState();

	WinSetTextColor(a_color);

	b_colored = true;	    
      }
    }
  }

  // Comme la somme des montants des sous-opérations est égale à la
  // valeur absolue du montant de l'opération, si ce dernier est
  // négatif alors il faut afficher l'opposé du montant de chaque
  // sous-opération :
  //
  // Exemple 1 (opération crédit) :
  // opération +100	Affichage
  //    ss-op1  20	20
  //    ss-op2  50	50
  //    ss-op3  30	30
  //
  // Exemple 2 (opération débit) :
  // opération -100	Affichage
  //    ss-op1  20	-20
  //    ss-op2  50	-50
  //    ss-op3  30	-30
  if (oTransForm->s_trans.uh_op_type == OP_DEBIT)
    l_amount = - l_amount;

  switch (l_amount < 0 ? - l_amount : l_amount)
  {
  case 0 ... 9999999:		/* entre <0, 100000< euros */
    /* Sans les centimes et en gras */
    Str100FToA(ra_buf, l_amount, &uh_len, float_dec_separator());
    FntSetFont(stdFont);
    break;

  case 10000000 ... 99999999:	/* entre <100000, 1000000< euros */
    /* Sans les centimes et en gras */
    StrIToA(ra_buf, l_amount / 100);
    uh_len = StrLen(ra_buf);
    FntSetFont(boldFont);
    break;

    /* Au dessus d'un million en valeur absolue */
  default:
    /* Abréviation sur le million en gras */
    Str100FToA(ra_buf, l_amount / 1000000, &uh_len, float_dec_separator());
#define ABBREV_MILLION	"M"
    MemMove(&ra_buf[uh_len], ABBREV_MILLION, sizeof(ABBREV_MILLION));
    uh_len += sizeof(ABBREV_MILLION) - 1;
    FntSetFont(boldFont);
    break;
  }

  WinDrawChars(ra_buf, uh_len,
	       prec_bounds->topLeft.x + prec_bounds->extent.x
	       - FntCharsWidth(ra_buf, uh_len),
	       prec_bounds->topLeft.y);

  if (b_colored)
    WinPopDrawState();

  FntSetFont(uh_save_font);
}


@implementation TransForm

- (TransForm*)free
{
  Transaction *oTransactions = [oMaTirelire transaction];

  // Libération des deux listes de comptes
  [oTransactions popupListFree:self->pv_popup_accounts];
  [oTransactions popupListFree:self->pv_popup_xfer_accounts];

  // Libération des devises
  [[oMaTirelire currency] popupListFree:self->pv_popup_currencies];

  // Libération des types
  [[oMaTirelire type] popupListFree:self->pv_popup_types];

  // Libération des modes
  [[oMaTirelire mode] popupListFree:self->pv_popup_modes];

  // Libération des macros
  [[oMaTirelire desc] popupListFree:self->pv_popup_desc];

  // La ventilation
  if (self->oSplits != nil)
    [[self->oSplits freeContents] free];

  return [super free];
}


- (struct s_trans_form_args*)editedTrans
{
  // Liste des opérations
  if ([(Object*)self->oPrevForm->oIsa isKindOf:TransListForm])
    return [(TransListForm*)self->oPrevForm transFormArgs];

  // Liste des marqués OU résultat des stats
  if ([(Object*)self->oPrevForm->oIsa isKindOf:CustomListForm]
      && [(Object*)((CustomListForm*)self->oPrevForm)->oList->oIsa
		   isKindOf:StatsTransScrollList])
    return &((StatsTransScrollList*)
	     ((CustomListForm*)self->oPrevForm)->oList)->u.s_trans_form;

  // Écran de pointage
  if ([(Object*)self->oPrevForm->oIsa isKindOf:ClearingListForm])
    return &((ClearingListForm*)self->oPrevForm)->s_trans_form;

  // Écran des répétitions
   if ([(Object*)self->oPrevForm->oIsa isKindOf:RepeatsListForm])
    return &((RepeatsListForm*)self->oPrevForm)->s_trans_form;

  // Autre ? XXX
  return NULL;
}


- (TransForm*)init
{
  self->uh_tabs_num = 4;
  self->uh_tabs_space = 1;

  return [super init];
}


- (Boolean)extractAndSave
{
  Transaction *oTransactions = [oMaTirelire transaction];
  struct s_transaction *ps_tr;
  Char *pa_desc;
  void *pv_option;
  t_amount l_real_amount;	// Used for splits sum
  t_amount l_real_xfer_amount;	// Used for splits sum & transfers
  Int32 l_xfer_id = -1;		// Used for splits & transfers

  UInt32 ui_check_num, ui_stmt_num;
  Boolean b_check_num, b_xfer, b_stmt_num, b_return;

  UInt16 uh_size = sizeof(struct s_transaction), uh_splits_size = 0;
  UInt16 uh_desc_len = 1;		/* \0 de la description */
  UInt16 uh_repeat, uh_saved_rec, uh_amounts_flags;
  UInt16 uh_new_account;
  Int16 h_xfer_account; // = -1;

  // Erreur retournée par défaut
  b_return = false;
  self->uh_really_saved = 0;

  ////////////////////////////////////////////////////////////////////////
  //
  // Calcul de la taille de l'enregistrement
  //

  // La date de valeur
  if (DateToInt(self->s_date) != DateToInt(self->s_value_date))
    uh_size += sizeof(struct s_rec_value_date);

  // Le numéro de chèque
  b_check_num = [self checkField:OpCheckNum
		      flags:FLD_CHECK_NOALERT|FLD_TYPE_DWORD|FLD_CHECK_VOID
		      resultIn:&ui_check_num
		      fieldName:FLD_NO_NAME];
  if (b_check_num)
    uh_size += sizeof(struct s_rec_check_num);

  // La répétition, s'il y a au moins une occurence à venir
  uh_repeat = 0;
  if ([self repeatNumOccurences] != 0)
  {
    uh_repeat = LstGetSelection([self objectPtrId:OpRepeatList]);
    uh_size += sizeof(struct s_rec_repeat);
  }

  // Le transfert, h_xfer_account n'est initialisé que si on a affaire
  // à un popup de comptes de transfert
  b_xfer = [self isXfer:&h_xfer_account];

  if (b_xfer)
    uh_size += sizeof(struct s_rec_xfer);

  // Numéro de relevé
  b_stmt_num = [self checkField:OpStatementNum
		     flags:FLD_CHECK_NOALERT|FLD_TYPE_DWORD|FLD_CHECK_VOID
		     resultIn:&ui_stmt_num
		     fieldName:FLD_NO_NAME];
  if (b_stmt_num)
    uh_size += sizeof(struct s_rec_stmt_num);

  // La devise
  if (self->uh_empty_currency == false)
    uh_size += sizeof(struct s_rec_currency);

  // La ventilation
  if (self->oSplits != nil)
  {
    MemHandle pv_split;
    struct s_rec_one_sub_transaction *ps_split;
    UInt16 uh_index = [self->oSplits size];

    uh_size += sizeof(struct s_rec_sub_transaction);

    while (uh_index-- > 0)
    {
      pv_split = [self->oSplits fetch:uh_index];
      ps_split = MemHandleLock(pv_split);

      uh_splits_size += sizeof(struct s_rec_one_sub_transaction);
      uh_splits_size += StrLen(ps_split->ra_desc) + 1;	// \0
      if (uh_splits_size & 1)
	uh_splits_size++;

      MemHandleUnlock(pv_split);
    }

    uh_size += uh_splits_size;
  }

  // La description et sa taille
  pa_desc = FldGetTextPtr([self objectPtrId:OpDesc]);
  if (pa_desc == NULL)
  {
    pa_desc = "";
    uh_size++;			/* \0 */
  }
  else
  {
    uh_desc_len += StrLen(pa_desc); /* le \0 est déjà compté */
    uh_size += uh_desc_len;
  }

  ////////////////////////////////////////////////////////////////////////
  //
  // Remplissage
  //
  NEW_PTR(ps_tr, uh_size, return false);

  MemSet(ps_tr, uh_size, '\0');

  // Pour l'ajout des options
  pv_option = ps_tr->ra_note;

  // Alarme
  ps_tr->ui_rec_alarm = CtlGetValue([self objectPtrId:OpAlarm]);
  // Vérification de la validité de l'alarme
  if (ps_tr->ui_rec_alarm)
  {
    DateTimeType s_rec_date;

    s_rec_date.second = 0;
    s_rec_date.minute = self->s_time.minutes;
    s_rec_date.hour = self->s_time.hours;
    s_rec_date.day = self->s_date.day;
    s_rec_date.month = self->s_date.month;
    s_rec_date.year = self->s_date.year + firstYear;
    if (TimDateTimeToSeconds(&s_rec_date) <= TimGetSeconds() + 60)
    {
      if (FrmAlert(alertAlarmBeforeToday) == 0) /* Modifier */
	goto end;

      /* Supprimer l'alarme */
      ps_tr->ui_rec_alarm = 0;
    }
  }

  // Date
  ps_tr->s_date = self->s_date;

  // Heure
  ps_tr->s_time = self->s_time;

  // Sauvegarde des date et heure pour la prochaine opération (ce sera
  // le cas seulement si le flag ui_acc_take_last_date est mis dans
  // les propriétés du compte ET si on vient de l'écran de la liste
  // des opérations)
  if ([(Object*)self->oPrevForm->oIsa isKindOf:TransListForm])
  {
    ((TransListForm*)self->oPrevForm)->s_last_new_op_date = self->s_date;
    ((TransListForm*)self->oPrevForm)->s_last_new_op_time = self->s_time;
  }

  // Montant de l'opération (si une devise est présente, doit être != 0)
  uh_amounts_flags
    = (self->uh_empty_currency == false
       ? FLD_CHECK_VOID|FLD_CHECK_NULL|FLD_SELTRIGGER_SIGN|FLD_TYPE_FDWORD
       : FLD_CHECK_VOID|FLD_SELTRIGGER_SIGN|FLD_TYPE_FDWORD);
  if ([self checkField:OpAmount
	    flags:uh_amounts_flags
	    resultIn:&ps_tr->l_amount
	    fieldName:strOpFormErrorDebitLabel + self->s_trans.uh_op_type]
      == false)
    goto end;

  // Marqué ou non
  ps_tr->ui_rec_marked = CtlGetValue([self objectPtrId:OpPerso]);

  // Mode de paiement
  ps_tr->ui_rec_mode = [[oMaTirelire mode] popupListGet:self->pv_popup_modes];

  // Type d'opération
  ps_tr->ui_rec_type = [[oMaTirelire type] popupListGet:self->pv_popup_types];

  // Pointé ou non
  ps_tr->ui_rec_checked = CtlGetValue([self objectPtrId:OpChecked]);
  
  // On repositionne si besoin le internal flag
  ps_tr->ui_rec_internal_flag = self->uh_internal_flag;

  // Si on vient de l'écran de pointage, le internal flag ne doit pas
  // être repositionné si l'opération est désormais pointée
  // puisqu'elle va disparaître de la liste au retour de cet écran
  if ([(Object*)self->oPrevForm->oIsa isKindOf:ClearingListForm])
  {
    if (ps_tr->ui_rec_checked)
      ps_tr->ui_rec_internal_flag = 0;
  }

  ////////////////////////////////////////////////////////////////////////
  //
  // Les options
  //
  // Date de valeur
  if (DateToInt(self->s_date) != DateToInt(self->s_value_date))
  {
    ps_tr->ui_rec_value_date = 1;

    ((struct s_rec_value_date*)pv_option)->s_value_date = self->s_value_date;

    pv_option += sizeof(struct s_rec_value_date);
  }

  // Numéro de chèque
  if (b_check_num)
  {
    ps_tr->ui_rec_check_num = 1;

    ((struct s_rec_check_num*)pv_option)->ui_check_num = ui_check_num;

    pv_option += sizeof(struct s_rec_check_num);
  }

  // Répétition
  if (uh_repeat)
  {
    struct s_rec_repeat *ps_repeat;
    //    1 semaine, 2 semaines, 1 mois, fin de mois, 2, 3, 4, 6, 12 et 24 mois
    UInt8 rua_freq[] = { 1, 2, 1, 1, 2, 3, 4, 6, 12, 24 };

    ps_tr->ui_rec_repeat = 1;
    ps_repeat = pv_option;

    switch (uh_repeat)
    {
    case 1 ... 2:		/* REPEAT_WEEKLY */
      ps_repeat->uh_repeat_type = REPEAT_WEEKLY;
      break;
    case 4:			/* REPEAT_MONTHLY_END */
      ps_repeat->uh_repeat_type = REPEAT_MONTHLY_END;
      break;
    default:			/* 3, 5 ... 10: REPEAT_MONTHLY */
      ps_repeat->uh_repeat_type = REPEAT_MONTHLY;
      break;
    }

    ps_repeat->uh_repeat_freq = rua_freq[uh_repeat - 1];

    // Date de fin de répétition
    ps_repeat->s_date_end = self->s_repeat_end_date;

    pv_option += sizeof(struct s_rec_repeat);
  }

  // Transfert
  if (b_xfer)
  { 
    ps_tr->ui_rec_xfer = 1;

    // Le transfert existe déjà, l'enregistrement lié ne change pas...
    if (self->uh_op_flags & OP_FORM_XFER)
    {
      if (self->uh_op_flags & OP_FORM_XFER_CAT)
	ps_tr->ui_rec_xfer_cat = 1;
      else
	l_xfer_id = self->ul_xfer_id;

      ((struct s_rec_xfer*)pv_option)->ul_id = self->ul_xfer_id;
      ((struct s_rec_xfer*)pv_option)->ul_reserved = 0;
    }

    // Si le transfert n'existe pas encore, l'ID sera rempli après coup

    pv_option += sizeof(struct s_rec_xfer);
  }
  
  // Numéro de relevé
  if (b_stmt_num)
  {
    ps_tr->ui_rec_stmt_num = 1;

    ((struct s_rec_stmt_num*)pv_option)->ui_stmt_num = ui_stmt_num;

    // New last statement number
    gui_last_stmt_num = ui_stmt_num;

    pv_option += sizeof(struct s_rec_stmt_num);
  }

  // To check splits sum below...
  l_real_amount = ps_tr->l_amount; // Used for splits sum
  if (l_real_amount < 0)
    l_real_amount = - l_real_amount; // We always want > 0 sum here
  l_real_xfer_amount = l_real_amount;

  // Devise
  if (self->uh_empty_currency == false)
  {
    struct s_rec_currency *ps_currency;
    t_amount l_tmp_amount;

    ps_tr->ui_rec_currency = 1;
    ps_currency = pv_option;

    if ([self checkField:OpCurrencyAmount
	      flags:FLD_CHECK_VOID|FLD_CHECK_NULL|FLD_TYPE_FDWORD
	      resultIn:&l_tmp_amount
	      fieldName:strOpFormErrorCurrencyAmount] == false)
      goto end;

    // Même signe que le montant...
    ps_currency->l_currency_amount = ps_tr->l_amount;

    l_real_xfer_amount = l_tmp_amount; // Always > 0 here (used for splits sum)
    if (ps_tr->l_amount < 0)
      l_tmp_amount = - l_tmp_amount;

    ps_tr->l_amount = l_tmp_amount;

    ps_currency->ui_currency
      = [[oMaTirelire currency] popupListGet:self->pv_popup_currencies];

    pv_option += sizeof(struct s_rec_currency);
  }

  // La ventilation
  if (self->oSplits != nil)
  {
    MemHandle pv_split;
    struct s_rec_sub_transaction *ps_base_split;
    struct s_rec_one_sub_transaction *ps_orig_split, *ps_final_split;
    UInt16 uh_index, uh_cur_size;

    // Vérification de la ventilation
    if (l_real_amount != self->l_splits_sum)
    {
      if (l_real_amount > self->l_splits_sum)
      {
	// Juste un warning
	if (FrmAlert(alertOpFormSplitsWarning) != 0)
	  goto end;
      }
      else
      {
	t_amount l_split_sum;

	// C'est une erreur !!!
	if (FrmAlert(alertOpFormSplitsError) != 0)
	  goto end;

	//
	// On corrige la somme de l'opération
	l_split_sum = self->l_splits_sum;
	if (ps_tr->l_amount < 0)
	  l_split_sum = - l_split_sum;

	// Dans la devise
	if (self->uh_empty_currency == false)
	{
	  struct s_rec_currency *ps_currency = pv_option;

	  ps_currency--;

	  ps_tr->l_amount
	    = currency_convert_amount2(l_split_sum,
				       ps_currency->l_currency_amount,
				       ps_tr->l_amount);
	  ps_currency->l_currency_amount = l_split_sum;
	}
	// Juste la somme de l'opération
	else
	  ps_tr->l_amount = l_split_sum;
      }
    }

    ps_tr->ui_rec_splits = 1;

    ps_base_split = pv_option;
    pv_option += sizeof(struct s_rec_sub_transaction);

    ps_base_split->uh_num = [self->oSplits size];
    ps_base_split->uh_size = uh_splits_size;

    ps_final_split = pv_option;
    for (uh_index = 0; uh_index < ps_base_split->uh_num; uh_index++)
    {
      pv_split = [self->oSplits fetch:uh_index];

      uh_cur_size = MemHandleSize(pv_split);

      ps_orig_split = MemHandleLock(pv_split);

      MemMove(ps_final_split, ps_orig_split, uh_cur_size);

      // La prochaine structure doit démarrer sur un multiple de 2
      if (uh_cur_size & 1)
      {
	((Char*)ps_final_split)[uh_cur_size] = '\0';
	uh_cur_size++;
      }

      MemHandleUnlock(pv_split);

      (Char*)ps_final_split += uh_cur_size;
    }

    pv_option = ps_final_split;
  }

  // Il y a une opération en transfert qui existe déjà, il faut
  // vérifier la conformité
  if (l_xfer_id >= 0
      && DmFindRecordByID(oTransactions->db, l_xfer_id, &uh_saved_rec) == 0)
  {
    struct s_transaction *ps_xfer_tr;

    ps_xfer_tr = [oTransactions getId:uh_saved_rec];

    // Il faut récupérer la somme des sous-opérations de l'opération liée
    if (ps_xfer_tr->ui_rec_splits)
    {
      struct s_rec_options s_options;
      FOREACH_SPLIT_DECL; // __uh_num et ps_cur_split
      t_amount l_splits_sum = 0;

      options_extract(ps_xfer_tr, &s_options);

      // On parcourt toutes les sous-opérations
      FOREACH_SPLIT(&s_options)
	l_splits_sum += ps_cur_split->l_amount;

      [oTransactions getFree:ps_xfer_tr];

      // Il faut que la somme des sous-opérations de l'opération liée
      // continue à coller avec le (possible) nouveau montant de
      // l'opération
      if (l_real_xfer_amount !=  l_splits_sum)
      {
	if (l_real_xfer_amount > l_splits_sum)
	{
	  // Juste un warning
	  if (FrmAlert(alertOpFormSplitsXferWarning) != 0)
	    goto end;
	}
	else
	{
	  // C'est une erreur !!!
	  FrmAlert(alertOpFormSplitsXferError);
	  goto end;
	}
      }
    }
    else
      [oTransactions getFree:ps_xfer_tr];
  }

  // La description
  MemMove(pv_option, pa_desc, uh_desc_len);

  uh_new_account = [oTransactions popupListGet:self->pv_popup_accounts];

  // On ne sauve que si l'opération change
  if (self->s_trans.h_edited_rec >= 0)
  {
    MemHandle pv_rec;
    UInt16 uh_rec_account;
    Boolean b_change = false;

    uh_saved_rec = self->s_trans.h_edited_rec;

    // On regarde si le compte ne change pas
    DmRecordInfo(oTransactions->db, uh_saved_rec, &uh_rec_account, NULL, NULL);
    uh_rec_account &= dmRecAttrCategoryMask;
    if (uh_rec_account == uh_new_account)
    {
      // On regarde si le contenu de l'opération change
      pv_rec = DmQueryRecord(oTransactions->db, uh_saved_rec);
      if (MemHandleSize(pv_rec) == uh_size)
      {
	b_change = MemCmp(MemHandleLock(pv_rec), ps_tr, uh_size) != 0;
	MemHandleUnlock(pv_rec);

	// Pas de changement
	if (b_change == false)
	{
	  b_return = true;
	  goto end;
	}
      }
    }
  }
  else
    uh_saved_rec = dmMaxRecordIndex;

  // On peut sauvegarder...
  b_return = [oTransactions save:ps_tr size:uh_size
			    asId:&uh_saved_rec
			    account:uh_new_account
			    xferAccount:h_xfer_account];

  if (b_return)
  {
    // S'il y a des répétitions, on les calcule tout de suite
    [oTransactions computeRepeatsOfId:uh_saved_rec];

    // Il y a un numéro de chèque, on regarde s'il fait partie des
    // chéquiers du compte
    if (b_check_num)
    {
      struct s_account_prop *ps_prop;
      UInt32 rui_chequebooks[4], ui_cur;
      UInt16 uh_account_id, uh_chequebook, uh_num_cheques;

      ps_prop = [oTransactions accountProperties:uh_new_account
			       index:&uh_account_id];
      MemMove(rui_chequebooks, ps_prop->rui_check_books,
	      sizeof(ps_prop->rui_check_books));
      uh_num_cheques = ps_prop->ui_acc_cheques_by_cbook;
      MemPtrUnlock(ps_prop);

      ui_cur = 0;
      for (uh_chequebook = 0; uh_chequebook < 4; uh_chequebook++)
      {
	ui_cur = rui_chequebooks[uh_chequebook];

	if (ui_cur == 0)
	  break;

	// Le numéro de chèque est dans un chéquier
	if (ui_check_num >= rui_chequebooks[uh_chequebook]
	    && ui_check_num < rui_chequebooks[uh_chequebook] + uh_num_cheques)
	{
	  // Le numéro de chèque est LE dernier du chéquier : on supprime...
	  if (ui_check_num
	      == rui_chequebooks[uh_chequebook] + uh_num_cheques - 1)
	  {
	    MemMove(&rui_chequebooks[uh_chequebook],
		    &rui_chequebooks[uh_chequebook + 1],
		    sizeof(rui_chequebooks[0]) * (4 - uh_chequebook - 1));
	    rui_chequebooks[3] = 0;
	    goto chequebook_update;
	  }

	  goto chequebook_done;
	}
      }

      // Pas trouvé de chéquier correspondant

      // S'il s'agit d'un nouvelle opération
      if ((self->s_trans.h_edited_rec < 0
	   // OU BIEN (opération éditée) que le numéro de chèque change
	   || ui_check_num != self->ui_orig_check_num)
	  // ET que l'utilisateur veut créer un nouveau chéquier avec...
	  && FrmAlert(alertNewChequebook) == 0)
      {
	// La liste des chéquiers est pleine, on supprime arbitrairement le 1er
	if (uh_chequebook == 4)
	{
	  MemMove(&rui_chequebooks[0], &rui_chequebooks[1],
		  sizeof(rui_chequebooks[0]) * 3);
	  uh_chequebook--;
	}

	rui_chequebooks[uh_chequebook] = ui_check_num;

  chequebook_update:
	// Sauvegarde la liste des chéquiers
	ps_prop = [oTransactions recordGetAtId:uh_account_id];

	DmWrite(ps_prop, offsetof(struct s_account_prop, rui_check_books),
		rui_chequebooks, sizeof(rui_chequebooks));

	[oTransactions recordRelease:true];
      }

  chequebook_done:
      ;
    }

    // Il faut placer la prochaine alarme
    // S'il s'agit d'une création AVEC flag d'alarme
    if ((self->s_trans.h_edited_rec < 0 && ps_tr->ui_rec_alarm)
	// OU BIEN s'il s'agit d'une édition
	|| self->s_trans.h_edited_rec >= 0)
    {
      if (alarm_schedule_transaction(oTransactions->db, uh_saved_rec, false))
	alarm_schedule_all();
    }

    self->s_trans.h_edited_rec = uh_saved_rec;

    self->ui_update_mati_list |= (frmMaTiUpdateList
				  | frmMaTiUpdateListTransactions);

    self->uh_really_saved = 1;
  }

 end:
  MemPtrFree(ps_tr);

  return b_return;
}


- (UInt16)loadRecord
{
  Transaction *oTransactions = [oMaTirelire transaction];

  // Nouvel enregistrement
  if (self->s_trans.h_edited_rec < 0)
  {
    struct s_account_prop *ps_prop;

    // L'internal flag est toujours à 0 pour une nouvelle opération
    self->uh_internal_flag = 0;

    // Le compte actuel
    self->uh_account = oTransactions->ps_prefs->ul_cur_category;

    ps_prop = [oTransactions accountProperties:self->uh_account index:NULL];

    // Date de la dernière opération enregistrée
    if (ps_prop->ui_acc_take_last_date
	&& [(Object*)self->oPrevForm->oIsa isKindOf:TransListForm]
	&& DateToInt(((TransListForm*)self->oPrevForm)->s_last_new_op_date))
    {
      self->s_date = ((TransListForm*)self->oPrevForm)->s_last_new_op_date;
      self->s_time = ((TransListForm*)self->oPrevForm)->s_last_new_op_time;
    }
    // Aujourd'hui
    else
    {
      DateTimeType s_datetime;

      TimSecondsToDateTime(TimGetSeconds(), &s_datetime);

      self->s_date.year = s_datetime.year - firstYear;
      self->s_date.month = s_datetime.month;
      self->s_date.day = s_datetime.day;

      self->s_time.hours = s_datetime.hour;
      self->s_time.minutes = s_datetime.minute;
    }

    // La devise du compte par défaut
    self->uh_currency = ps_prop->ui_acc_currency;

    MemPtrUnlock(ps_prop);

    // La date de valeur initialisée à aujourd'hui aussi...
    self->s_value_date = self->s_date;

    // Le premier mode par défaut
    self->uh_mode = ITEM_SELECT_FIRST;

    // Le type "Non classé" par défaut
    self->uh_type = TYPE_UNFILED;

    // Initialisation des transferts : "Sans"
    self->h_xfer_account = -1;
    [self initXferAccountsListSelected:ACC_POPUP_FIRST];

    // Le type de répétition à "Jamais"
    [self initRepeat:0];

    // Onglet devise vide
    [self emptyCurrencyTab];

    // La ventilation (on annonce que la liste est vide, ce qui doit
    // être caché l'est déjà puisque ce n'est pas le premier onglet)
    LstSetListChoices([self objectPtrId:OpSplitList], (Char**)self, 1);
  }
  // Chargement d'un enregistrement
  else
  {
    struct s_transaction *ps_tr;
    struct s_rec_options s_options;

    ps_tr = [oTransactions getId:self->s_trans.h_edited_rec];

    // On conserve le internal flag pour le repositionner à la sauvegarde
    self->uh_internal_flag = ps_tr->ui_rec_internal_flag;

    // Initialisation en fonction du contenu de l'opération
    [self initFromTrans:ps_tr id:self->s_trans.h_edited_rec
	  options:&s_options];

    // Transfert
    if (ps_tr->ui_rec_xfer)
    {
      self->ul_xfer_id = s_options.ps_xfer->ul_id;

      // L'enregistrement n'existe plus, on n'a que l'index de la catégorie
      if (ps_tr->ui_rec_xfer_cat)
      {
	self->uh_op_flags |= OP_FORM_XFER|OP_FORM_XFER_CAT;
	self->h_xfer_account = self->ul_xfer_id;
      }
      // On recherche la catégorie de l'enregistrement lié
      else
      {
	UInt16 uh_index;

	// Normalement ça marche toujours... */
	if (DmFindRecordByID(oTransactions->db,
			     self->ul_xfer_id, &uh_index) != 0)
	  goto xfer_less;

	self->uh_op_flags &= ~OP_FORM_XFER_CAT;
	self->uh_op_flags |= OP_FORM_XFER;

	DmRecordInfo(oTransactions->db, uh_index, &self->h_xfer_account,
		     NULL, NULL);
	self->h_xfer_account &= dmRecAttrCategoryMask;
      }

      // On rend visible le bouton de suppression de transfert + icone
      if (self->uh_tabs_current == 1)
      {
	[self showId:bmpTrash];
	[self showId:OpXferDel];
      }

      // Si on vient du même écran, il est possible que le popup des
      // comptes de transfert soit déjà construit alors qu'on n'en
      // veut pas ici
      if (self->pv_popup_xfer_accounts != NULL)
      {
	[oTransactions popupListFree:self->pv_popup_xfer_accounts];
	self->pv_popup_xfer_accounts = NULL;
      }
    }
    else
    {
  xfer_less:
      // Pas de transfert
      self->h_xfer_account = -1;
      [self initXferAccountsListSelected:ACC_POPUP_FIRST];
    }

    // La date de valeur (ici et pas dans -initFromTrans:id:options:
    // car elle n'est pas copiée lors d'une copie d'opération)
    if (ps_tr->ui_rec_value_date)
      self->s_value_date = s_options.ps_value_date->s_value_date;
    else
      self->s_value_date = self->s_date;

    [oTransactions getFree:ps_tr];
  }

  return [self fillForm];
}


- (void)copyId:(UInt16)uh_id sameDate:(Boolean)b_same
{
  Transaction *oTransactions = [oMaTirelire transaction];
  struct s_transaction *ps_tr;
  struct s_rec_options s_options;
  UInt16 uh_link_account;

  ps_tr = [oTransactions getId:uh_id];

  // L'internal flag est toujours à 0 pour une nouvelle opération
  self->uh_internal_flag = 0;

  // Utilisation de l'opération pour l'initialisation
  [self initFromTrans:ps_tr id:uh_id options:&s_options];

  // Date d'aujourd'hui
  if (b_same == false)
  {
    DateTimeType s_datetime;

    /* La date d'aujourd'hui */
    TimSecondsToDateTime(TimGetSeconds(), &s_datetime);

    self->s_date.year = s_datetime.year - firstYear;
    self->s_date.month = s_datetime.month;
    self->s_date.day = s_datetime.day;

    self->s_time.hours = s_datetime.hour;
    self->s_time.minutes = s_datetime.minute;

    // Plus de date de valeur (seulement si la date de l'opération
    // n'est pas la même que celle de l'opération originale)
    self->s_value_date = self->s_date;
  }
  // Même date que l'original
  else
  {
    if (ps_tr->ui_rec_value_date)
      self->s_value_date = s_options.ps_value_date->s_value_date;
    else
      self->s_value_date = self->s_date;
  }

  // Le bouton du compte de transfert doit lister les comptes
  // Il y a un transfert, il faut sélectionner la bonne entrée !
  uh_link_account = ACC_POPUP_FIRST;
  if (ps_tr->ui_rec_xfer)
  {
    UInt32 ul_id = s_options.ps_xfer->ul_id;

    if (ps_tr->ui_rec_xfer_cat)
      uh_link_account = ul_id;
    else
    {
      UInt16 uh_index;

      /* Normalement ça marche toujours... */
      if (DmFindRecordByID(oTransactions->db, ul_id, &uh_index) == 0)
      {
	DmRecordInfo(oTransactions->db, uh_index, &uh_link_account, NULL,NULL);
	uh_link_account &= dmRecAttrCategoryMask;
      }
    }
  }

  // On place le nom du compte dans le bouton et on le sélectionne
  // dans le popup
  self->h_xfer_account = -1;
  [self initXferAccountsListSelected:uh_link_account];

  [oTransactions getFree:ps_tr];

  // Remplissage du formulaire (avec le popup de répétition initialisé)
  [self fillForm];
}


- (void)initRepeat:(UInt16)uh_repeat
{
  // Popup de répétition
  ListType *pt_lst = [self objectPtrId:OpRepeatList];
  LstSetSelection(pt_lst, uh_repeat);
  CtlSetLabel([self objectPtrId:OpRepeatPopup],
	      LstGetSelectionText(pt_lst, uh_repeat));
}


//
// Initialise le contenu du formulaire en fonction du contenu de l'instance
- (UInt16)fillForm
{
  Transaction *oTransactions = [oMaTirelire transaction];
  Mode *oModes = [oMaTirelire mode];
  Type *oTypes = [oMaTirelire type];
  Currency *oCurrencies = [oMaTirelire currency];
  Char ra_account_name[dmCategoryLength];
  UInt16 uh_focus = OpAmount;
  UInt16 uh_mode_flags = (ITEM_ADD_UNKNOWN_LINE | ITEM_ADD_EDIT_LINE);

  // Il y a un transfert (sinon le popup est déjà rempli)
  if (self->h_xfer_account >= 0)
  {
    CategoryGetName(oTransactions->db, self->h_xfer_account, ra_account_name);
    [self fillLabel:OpXferPopup withSTR:ra_account_name];
  }

  // Débit ou crédit
  [self setCredit:self->s_trans.uh_op_type];

  // S'il s'agit d'un nouvel enregistrement (et pas d'une copie)
  if (self->s_trans.h_edited_rec < 0)
  {
    // Pas de bouton de déplacement
    [self hideId:OpPrev];
    [self hideId:OpNext];
    self->rb_goto_buttons[0] = false;
    self->rb_goto_buttons[1] = false;

    // On rend invisible le bouton de suppression
    [self hideId:OpDelete];

    // Description à pré-remplir
    if (self->s_trans.uh_is_pre_desc)
    {
      uh_focus = [self expandMacro:self->s_trans.uh_param
		       with:[oMaTirelire desc]];
      self->s_trans.uh_is_pre_desc = 0;	// Évite les problèmes plus tard
    }
  }
  // Si on édite un enregistrement (pas une copie)
  else
  {
    [self resetButtonNext:true];
    [self resetButtonNext:false];

    if (self->s_trans.uh_copy == 0)
      // Il se peut que le mode n'existe pas, mais c'est pas grave...
      uh_mode_flags |= ITEM_CAN_NOT_EXIST;
  }

  // Le compte actuel
  CategoryGetName(oTransactions->db, self->uh_account, ra_account_name);

  // Liste des comptes
  [self initAccountsList];

  // La liste des modes
  if (self->pv_popup_modes != NULL)
    [oModes popupList:self->pv_popup_modes setSelection:self->uh_mode];
  else
    self->pv_popup_modes = [oModes popupListInit:OpModeList
				   form:self->pt_frm
				   Id:self->uh_mode | uh_mode_flags
				   forAccount:ra_account_name];

  // S'il s'agit d'un nouvel enregistrement (et pas d'une copie)
  if (self->s_trans.h_edited_rec < 0)
  {
    // Si le mode n'a pas été changé par la macro, il faut aller le récupérer
    if (self->uh_mode == ITEM_SELECT_FIRST)
      self->uh_mode = [oModes popupListGet:self->pv_popup_modes];

    // On cherche dans le mode sélectionné s'il y a une date de valeur
    // Ça permet au mode par défaut de contenir un raccourci...
    [self expandMode:self->uh_mode with:oModes];
  }

  // La liste des types
  if (self->pv_popup_types != NULL)
    [oTypes popupList:self->pv_popup_types setSelection:self->uh_type];
  else
    [self initTypesPopup:self->uh_type forAccount:ra_account_name];

  // La liste des devises
  if (self->pv_popup_currencies != NULL)
    [oCurrencies popupList:self->pv_popup_currencies
		 setSelection:self->uh_currency];
  else
    self->pv_popup_currencies = [oCurrencies
				  popupListInit:OpDeviseList
				  form:self->pt_frm
				  Id:self->uh_currency | ITEM_ADD_EDIT_LINE
				  forAccount:(Char*)-1];

  // L'onglet devise n'est pas vide
  if (self->uh_empty_currency == false)
  {
    // On ne met pas en place la devise dans le popup, ça vient d'être
    // fait, mais on calcule le taux...
    [self changeCurrencyTo:(CHG_CURRENCY_DONT_SET_POPUP
			    | CHG_CURRENCY_COMPUTE_RATE
			    | self->uh_currency)];
  }

  // On détermine le cas dans lequel on se trouve...
  [self freezeCurrency:[self case] >= TRANSFORM_CASE_3];

  // La barre de scroll sur la description
  [self fieldUpdateScrollBar:OpScrollbar
        fieldPtr:[self objectPtrId:OpDesc]
        setScroll:true];

  // Date (on appelle la méthode de la classe mère, car on ne veut pas
  // du comportement de la méthode de notre classe à cet endroit)
  [super dateSet:OpDate date:self->s_date
	 format:(DateFormatType)PrefGetPreference(prefLongDateFormat)];

  // Heure
  [self timeSet:OpTime time:self->s_time
	format:(TimeFormatType)PrefGetPreference(prefTimeFormat)];

  // La date de valeur
  [self setValueDate];

  return uh_focus;
}


- (void)resetButtonNext:(Boolean)b_next
{
  SumScrollList *oSclList;
  Char ra_button[] = "X";
  UInt16 uh_button = OpPrev + b_next;
  Boolean b_enabled;

  // On est forcément appelé par un écran de liste
  oSclList = ((SumListForm*)self->oPrevForm)->oList;

  b_enabled = [oSclList getTransaction:self->s_trans.h_edited_rec
			next:b_next updateList:false] >= 0;
  ra_button[0] = symbol7ScrollUpDisabled + b_next - b_enabled * 2;
  CtlSetEnabled([self objectPtrId:uh_button], b_enabled);
  [self fillLabel:uh_button withSTR:ra_button];

  // Nouvel état du bouton
  self->rb_goto_buttons[b_next] = b_enabled;
}


//
// Initialise le popup des types
- (void)initTypesPopup:(UInt16)uh_type forAccount:(Char*)pa_account_name
{
  Type *oTypes = [oMaTirelire type];
  Char ra_account_name[dmCategoryLength];

  if (self->pv_popup_types != NULL)
    [oTypes popupListFree:self->pv_popup_types];

  uh_type |= TYPE_ADD_EDIT_LINE;

  if ((uh_type & (TYPE_FLAG_SIGN_DEBIT | TYPE_FLAG_SIGN_CREDIT)) == 0)
  {
    // Il y a un transfert, pas de type signé
    if ([self isXfer:NULL])
      uh_type |= TYPE_FLAG_SIGN_NONE;
    // Crédit
    else if (self->s_trans.uh_op_type)
      uh_type |= TYPE_FLAG_SIGN_CREDIT;
    // Débit
    else
      uh_type |= TYPE_FLAG_SIGN_DEBIT;
  }

  // Le compte actuel
  if (pa_account_name == NULL)
  {
    pa_account_name = ra_account_name;
    CategoryGetName([oMaTirelire transaction]->db, self->uh_account,
		    ra_account_name);
  }

  self->pv_popup_types = [oTypes popupListInit:OpTypeList
				 form:self->pt_frm Id:uh_type
				 forAccount:pa_account_name];
}


- (void)setCredit:(Boolean)b_credit
{
  Char ra_buf[16];
  RectangleType s_bounds;
  UInt16 uh_but_idx;
  Int16 h_old_width;
  FontID uh_save_font;

  // Le titre
  SysStringByIndex(strOpFormDebCredTitle, b_credit, ra_buf, sizeof(ra_buf));
  FrmCopyTitle(self->pt_frm, ra_buf);

  // Le label
  SysStringByIndex(strOpFormDebCredLabel, b_credit, ra_buf, sizeof(ra_buf));

  // Le label du bouton est toujours centré, pour bien le caler à
  // droite, il faut recalculer sa largeur et le repositionner (car le
  // RIGHTALIGN n'a pas l'air de fonctionner, au moins sur OS <= 3.1)
  uh_but_idx = FrmGetObjectIndex(self->pt_frm, OpDebCredLabel);
  [self hideIndex:uh_but_idx];
  FrmGetObjectBounds(self->pt_frm, uh_but_idx, &s_bounds);

  h_old_width = s_bounds.extent.x;

  uh_save_font = FntSetFont(boldFont);
  s_bounds.extent.x = FntCharsWidth(ra_buf, StrLen(ra_buf)) + 4;
  FntSetFont(uh_save_font);

  s_bounds.topLeft.x -= (Int16)s_bounds.extent.x - h_old_width;

  FrmSetObjectBounds(self->pt_frm, uh_but_idx, &s_bounds);

  [self fillLabel:OpDebCredLabel withSTR:ra_buf];

  [self showIndex:uh_but_idx];

  // Le label du signe
  [self fillLabel:OpDebCredSign withSTR:b_credit ? "+" : "-"];

  // On met le focus sur le champ si le formulaire est déjà dessiné
  if (self->uh_form_drawn)
  {
    [self focusObject:OpAmount];

    if (self->uh_tabs_current == 3)
      // Pour nous-mêmes
      [self sendCallerUpdate:(frmMaTiUpdateTransForm
			      | frmMaTiUpdateTransFormSplitsDiff)];
  }

  // On garde pour la sauvegarde
  self->s_trans.uh_op_type = b_credit;
}


//
// Initialise la liste des comptes de transfert en sélectionnant
// h_selected_account et en retirant de la liste self->uh_account.
// Si h_selected_account == self->uh_account, c'est l'entrée "Sans"
// qui est sélectionnée.
// Si h_selected_account < 0, le compte de Xfer courant est pris
- (void)initXferAccountsListSelected:(Int16)h_selected_account
{
  Transaction *oTransactions;
  struct s_tr_accounts_list s_infos;

  // Il n'y a pas de liste des Xfer
  if (self->h_xfer_account >= 0)
    return;

  oTransactions = [oMaTirelire transaction];

  // On re-sélectionne le même compte qu'à présent
  if (h_selected_account < 0)
  {
    if (self->pv_popup_xfer_accounts != NULL)
      h_selected_account
	= [oTransactions popupListGet:self->pv_popup_xfer_accounts];
    else
      h_selected_account = ACC_POPUP_FIRST;
  }

  self->uh_op_flags &= ~(OP_FORM_XFER|OP_FORM_XFER_CAT);

  // On cache le bouton de suppression de transfert et son icone
  [self hideId:bmpTrash];
  [self hideId:OpXferDel];

  self->h_xfer_account = -1;

  // Préparation de la liste des comptes de transfert
  MemSet(&s_infos, sizeof(s_infos), '\0');
  s_infos.h_skip_account = self->uh_account;

  // Même compte, on sélectionne l'entrée "Sans"
  if (h_selected_account == self->uh_account)
    h_selected_account = ACC_POPUP_FIRST;

  // On place le mot "Sans" comme première entrée de la liste
  SysCopyStringResource(s_infos.ra_first_item, strOpFormNoXfer);

  // Préparation du couple popup/liste avec la sélection par défaut
  [oTransactions popupListFree:self->pv_popup_xfer_accounts];

  self->pv_popup_xfer_accounts
    = [oTransactions popupListInit:OpXferList
		     form:(BaseForm*)self
		     infos:&s_infos
		     selectedAccount:h_selected_account];
}


//
// Renvoie true si l'opération possède un compte de transfert
// false sinon
// *ph_xfer_account est changé uniquement dans le cas d'un compte en
// cours de sélection, sinon il vaut toujours -1
- (Boolean)isXfer:(Int16*)ph_xfer_account
{
  Int16 h_xfer_account = -1;
  Boolean b_ret = true;

  // Compte de transfert pas encorefixé
  if (self->pv_popup_xfer_accounts != NULL)
  {
    // Compte de transfert en cours de sélection
    h_xfer_account = [[oMaTirelire transaction]
		       popupListGet:self->pv_popup_xfer_accounts];
    if (h_xfer_account == ACC_POPUP_FIRST)
    {
      b_ret = false;
      h_xfer_account = -1;
    }
  }

  if (ph_xfer_account != NULL)
    *ph_xfer_account = h_xfer_account;

  return b_ret;
}


//
// Initialise la liste des comptes en sélectionnant self->uh_account
// et en retirant de la liste l'éventuel compte de transfert (sauf si
// les 2 sont égaux).
- (void)initAccountsList
{
  Transaction *oTransactions = [oMaTirelire transaction];
  struct s_tr_accounts_list s_infos;

  MemSet(&s_infos, sizeof(s_infos), '\0');
  s_infos.h_skip_account = self->h_xfer_account;

  // On libère...
  [oTransactions popupListFree:self->pv_popup_accounts];

  // Si on a un popup des comptes
  if (self->pv_popup_xfer_accounts != NULL)
  {
    UInt16 uh_xfer_account;

    uh_xfer_account= [oTransactions popupListGet:self->pv_popup_xfer_accounts];

    // Ce n'est pas l'entrée "Sans"
    if (uh_xfer_account != ACC_POPUP_FIRST)
    {
      // Le compte de transfert actuel n'est pas le compte courant
      if (uh_xfer_account != self->uh_account)
	s_infos.h_skip_account = uh_xfer_account;
      // C'est le même, il faut reconstruire la liste des comptes de
      // transfert en sélectionnant l'entrée "Sans"
      else
	[self initXferAccountsListSelected:ACC_POPUP_FIRST];
    }
  }

  // Normalement les deux comptes sont forcément différents, mais on
  // n'est pas à l'abri d'une connerie sauvée dans la base...
  if (s_infos.h_skip_account == self->uh_account)
    s_infos.h_skip_account = -1;

  // On reconstruit la liste des comptes...
  self->pv_popup_accounts = [oTransactions popupListInit:OpCategoryList
					   form:(BaseForm*)self
					   infos:&s_infos
					   selectedAccount:self->uh_account];
}


//
// Initialisation de l'instance avec le contenu d'une opération
- (void)initFromTrans:(struct s_transaction*)ps_tr id:(UInt16)uh_id
	      options:(struct s_rec_options*)ps_options
{
  Transaction *oTransactions = [oMaTirelire transaction];
  ListType *pt_list;
  t_amount l_amount;

  DmRecordInfo(oTransactions->db, uh_id, &self->uh_account, NULL, NULL);
  self->uh_account &= dmRecAttrCategoryMask;

  // Alarme
  CtlSetValue([self objectPtrId:OpAlarm], ps_tr->ui_rec_alarm);

  // Date / heure
  self->s_date = ps_tr->s_date;
  self->s_time = ps_tr->s_time;

  // Les options de l'opération
  options_extract(ps_tr, ps_options);

  // La somme de l'opération
  if (ps_tr->ui_rec_currency)
  {
    // Avec devise...
    self->uh_currency = ps_options->ps_currency->ui_currency;
    l_amount = ps_options->ps_currency->l_currency_amount;

    //
    // Tab 4
    //
    // On traite l'onglet devise à cet endroit

    // La somme de l'onglet devise, est la somme dans la monnaie du compte
    [self replaceField:REPLACE_FIELD_EXT | OpCurrencyAmount
	  withSTR:(Char*)ps_tr->l_amount len:REPL_FIELD_FDWORD];

    // L'onglet devise va être rempli
    [self fillCurrencyTab:false];
  }
  // Sans devise
  else
  {
    // La devise du compte par défaut
    self->uh_currency = [oTransactions accountCurrency:self->uh_account];

    l_amount = ps_tr->l_amount;

    // Onglet devise vide
    [self emptyCurrencyTab];
  }

  // Débit crédit
  self->s_trans.uh_op_type = l_amount >= 0;

  [self replaceField:REPLACE_FIELD_EXT | OpAmount
	withSTR:(Char*)l_amount len:REPL_FIELD_FDWORD];

  // La description
  [self replaceField:OpDesc withSTR:ps_options->pa_note len:-1];


  //
  // Tab 1
  //
  // Marqué ou non
  CtlSetValue([self objectPtrId:OpPerso], ps_tr->ui_rec_marked);

  // Mode de paiement
  self->uh_mode = ps_tr->ui_rec_mode;

  // Type d'opération
  self->uh_type = ps_tr->ui_rec_type;

  // Numéro de chèque
  self->ui_orig_check_num
    = ps_tr->ui_rec_check_num ? ps_options->ps_check_num->ui_check_num : 0;
  [self replaceField:REPLACE_FIELD_EXT | OpCheckNum
	withSTR:(Char*)self->ui_orig_check_num
	len:REPL_FIELD_DWORD | REPL_FIELD_EMPTY_IF_NULL];

  // Numéro de relevé
  [self replaceField:REPLACE_FIELD_EXT | OpStatementNum
	withSTR:(Char*)(ps_tr->ui_rec_stmt_num
			? ps_options->ps_stmt_num->ui_stmt_num : 0)
	len:REPL_FIELD_DWORD | REPL_FIELD_EMPTY_IF_NULL];

  // Pointé ou non
  CtlSetValue([self objectPtrId:OpChecked], ps_tr->ui_rec_checked);


  //
  // Tab 2
  //
  if (ps_tr->ui_rec_repeat)
  {
    struct s_rec_repeat *ps_repeat = ps_options->ps_repeat;
    UInt16 uh_repeat;

    switch (ps_repeat->uh_repeat_type)
    {
    case REPEAT_WEEKLY:
      if (ps_repeat->uh_repeat_freq > 1)
	uh_repeat = 2;		/* Toutes les 2 semaines */
      else
	uh_repeat = 1;		/* Toutes les semaines */
      break;

    case REPEAT_MONTHLY_END:
      uh_repeat = 4;
      break;

    default:			/* REPEAT_MONTHLY */
      switch (ps_repeat->uh_repeat_freq)
      {
      case 2:  uh_repeat = 5; break;	/* Tous les 2 mois */
      case 3:  uh_repeat = 6; break;	/* Tous les 3 mois */
      case 4:  uh_repeat = 7; break;	/* Tous les 4 mois */
      case 6:  uh_repeat = 8; break;	/* Tous les 6 mois */
      case 12: uh_repeat = 9; break;	/* Tous les 12 mois */
      case 24: uh_repeat = 10; break;	/* Tous les 24 mois */
      default: uh_repeat = 3; break;	/* Tous les mois par défaut */
      }
      break;
    }

    // Init du popup (il faut le laisser là, car le
    // -dateSet:date:format:, plus bas, a besoin que le choix dans la
    // liste soit initialisé)
    [self initRepeat:uh_repeat];

    // Date de fin
    self->s_repeat_end_date = ps_repeat->s_date_end;

    // Pas de date de fin
    if (DateToInt(ps_repeat->s_date_end) == 0)
    {
      [self fillLabel:OpRepeatEndDate
	    withSTR:LstGetSelectionText([self objectPtrId:OpRepeatChoices],
					1)];

      // Flèches d'{in,dé}crément de date + date
      // Nombre d'occurrences
      [self repeatNoDate];
    }
    // Date de fin
    else
    {
      // Mise à jour de la date avec calcul du nombre d'occurrences
      [self dateSet:OpRepeatEndDate date:self->s_repeat_end_date format:0];

      // Si on est sur l'onglet "Répétition", on fait apparaître les
      // widgets nécessaires
      if (self->uh_tabs_current == 2)
	[self repeatShow:true];
    }
  }
  // Pas de répétition
  else
    [self initRepeat:0];


  //
  // Tab 3
  //
  // La ventilation
  if (self->oSplits != nil)
    self->oSplits = [[self->oSplits freeContents] free];
  self->l_splits_sum = 0;

  pt_list = [self objectPtrId:OpSplitList];

  if (ps_tr->ui_rec_splits)
  {
    MemHandle pv_split;
    struct s_rec_one_sub_transaction *ps_new_split;
    FOREACH_SPLIT_DECL; // __uh_num et ps_cur_split
    UInt16 uh_size;

    self->oSplits = [Array new];

    // On parcourt toutes les sous-opérations
    FOREACH_SPLIT(ps_options)
    {
      uh_size = sizeof(*ps_cur_split) + StrLen(ps_cur_split->ra_desc) + 1;// \0

      NEW_HANDLE(pv_split, uh_size, continue);

      if ([self->oSplits push:pv_split] == false)
      {
	MemHandleFree(pv_split);
	NEW_ERROR((UInt32)-1, continue);
      }

      ps_new_split = MemHandleLock(pv_split);

      MemMove(ps_new_split, ps_cur_split, uh_size);

      self->l_splits_sum += ps_new_split->l_amount;

      MemHandleUnlock(pv_split);
    }

    // On met en place les choix avant de changer la sélection
    LstSetListChoices(pt_list, (Char**)self, [self->oSplits size] + 1);

    // On trie les sous-opérations conformément au choix de l'utilisateur
    LstSetSelection(pt_list, 1);
    [self sortSplitsResel:false]; // Sans resélectionner d'entrée

    // On repositionne les boutons
    [self reposSplitsButtons];

    // La différence sera OK, puisque tout le formulaire va être redessiné
  }
  else
  {
    // On met en place les choix avant de changer la sélection
    LstSetListChoices(pt_list, (Char**)self, 1);

    LstSetSelection(pt_list, noListSelection); // OK
  }


  //
  // Tab 4
  //
  // L'onglet devise a été traité plus haut et sera fini dans -fillForm
}


#define splitTabContents(show) \
	SET_SHOW(OpSplitEdit,	show), \
	SET_SHOW(OpSplitLabel,	show), \
	SET_SHOW(OpSplitSortBy,	show), \
	SET_SHOW(OpSplitSort,	show), \
	0

#define currencyTabContentsWithoutNone(show) \
	SET_SHOW(OpCurrencyInAccount,	      show), \
	SET_SHOW(OpCurrencyAmount,	      show), \
	SET_SHOW(OpCurrencyAccountCurrency1,  show), \
	SET_SHOW(OpCurrencyRateLabel,	      show), \
	\
	SET_SHOW(OpCurrency1Num,	      show), \
	SET_SHOW(OpCurrency1Currency,	      show), \
	SET_SHOW(OpCurrency1Equals,	      show), \
	SET_SHOW(OpCurrency1Rate,	      show), \
	SET_SHOW(OpCurrency1AccountCurrency2, show), \
	\
	SET_SHOW(OpCurrency2Num,	      show), \
	SET_SHOW(OpCurrency2Currency,	      show), \
	SET_SHOW(OpCurrency2Equals,	      show), \
	SET_SHOW(OpCurrency2Rate,	      show), \
	SET_SHOW(OpCurrency2AccountCurrency2, show)

#define currencyTabContents(curr_show, none_show) \
	currencyTabContentsWithoutNone(curr_show), \
	SET_SHOW(OpCurrencyNone, none_show), \
	0

- (void)emptyCurrencyTab
{
  self->uh_empty_currency = true;

  // Si on est dans l'onglet des devises, il faut cacher...
  if (self->uh_tabs_current == 4)
  {
    UInt16 ruh_objs[] = { currencyTabContents(0, 1) };

    [self showHideIds:ruh_objs];
  }
}


- (void)fillCurrencyTab:(Boolean)b_show
{
  self->uh_empty_currency = false;

  // Si on est dans l'onglet des devises, il faut cacher...
  if (self->uh_tabs_current == 4)
  {
    // Tout le monde réapparaît sauf OpCurrencyNone
    // OU BIEN Tout le monde disparaît
    UInt16 uh_all_show = b_show;
    UInt16 ruh_objs[] = { currencyTabContents(uh_all_show, 0) };

    [self showHideIds:ruh_objs];
  }
}


static Int16 _splits_amount_cmp(struct s_rec_one_sub_transaction *ps1,
				struct s_rec_one_sub_transaction *ps2,
				Type *oTypes)
{
  if (ps1->l_amount < ps2->l_amount)
    return -1;

  return ps1->l_amount > ps2->l_amount;
}


static Int16 _splits_desc_cmp(struct s_rec_one_sub_transaction *ps1,
			      struct s_rec_one_sub_transaction *ps2,
			      Type *oTypes)
{
  return StrCaselessCompare(ps1->ra_desc, ps2->ra_desc);
}


static Int16 _splits_type_cmp(struct s_rec_one_sub_transaction *ps1,
			      struct s_rec_one_sub_transaction *ps2,
			      Type *oTypes)
{
  Char *pa1, *pa2;
  Int16 h_ret;

  pa1 = [oTypes fullNameOfId:ps1->ui_type len:NULL];
  pa2 = [oTypes fullNameOfId:ps2->ui_type len:NULL];

  h_ret = StrCaselessCompare(pa1, pa2);

  MemPtrFree(pa2);
  MemPtrFree(pa1);

  return h_ret;
}

typedef Int16 (*tf_splits_cmp)(struct s_rec_one_sub_transaction*,
			       struct s_rec_one_sub_transaction*,
			       Type*);

- (void)sortSplitsResel:(Boolean)b_resel
{
  const tf_splits_cmp rpf_sort[] =
  {
    _splits_desc_cmp,
    _splits_type_cmp,
    _splits_amount_cmp,
  };
  ListType *pt_list = [self objectPtrId:OpSplitList];
  MemHandle pv_cur = NULL;
  struct s_db_prefs *ps_db_prefs = [oMaTirelire transaction]->ps_prefs;

  if (b_resel)
  {
    Int16 index = LstGetSelection(pt_list);
    if (index > 0)		// Car 0 est la somme restante
      pv_cur = [self->oSplits fetch:index - 1];
  }
  
  [self->oSplits sortFunc:(tf_array_cmp)rpf_sort[ps_db_prefs->ul_splits_sort]
       param:(Int32)[oMaTirelire type]];

  if (pv_cur != NULL)
    LstSetSelection(pt_list, [self->oSplits find:pv_cur] + 1);
}


- (void)reposSplitsButtons
{
  ListType *pt_list;
  struct s_db_prefs *ps_db_prefs = [oMaTirelire transaction]->ps_prefs;
  RectangleType s_bounds;
  UInt16 uh_obj, index;
  Int16 h_diff_x;

  // Ancienne largeur du bouton contenant le choix du label
  index = FrmGetObjectIndex(self->pt_frm, OpSplitLabel);
  FrmGetObjectBounds(self->pt_frm, index, &s_bounds);
  h_diff_x = - (Int16)s_bounds.extent.x;

  pt_list = [self objectPtrId:OpSplitSortByChoices];

  if (self->uh_form_drawn && self->uh_tabs_current == 3)
  {
    [self hideId:OpSplitSortBy];
    [self hideId:OpSplitSort];
  }

  CtlSetLabel([self objectPtrId:OpSplitLabel],
	      LstGetSelectionText(pt_list, ps_db_prefs->ul_splits_label));

  // Nouvelle largeur du bouton contenant le choix du label
  FrmGetObjectBounds(self->pt_frm, index, &s_bounds);
  h_diff_x += s_bounds.extent.x;

  CtlSetLabel([self objectPtrId:OpSplitSort],
	      LstGetSelectionText(pt_list, ps_db_prefs->ul_splits_sort));

  // On repositionne le label "par", le bouton du tri et la liste
  // déroulante du tri
  for (uh_obj = OpSplitSortBy; uh_obj <= OpSplitSortByChoices; uh_obj++)
  {
    index = FrmGetObjectIndex(self->pt_frm, uh_obj);
    FrmGetObjectBounds(self->pt_frm, index, &s_bounds);
    s_bounds.topLeft.x += h_diff_x;
    FrmSetObjectBounds(self->pt_frm, index, &s_bounds);
  }

  if (self->uh_form_drawn && self->uh_tabs_current == 3)
  {
    [self showId:OpSplitSortBy];
    [self showId:OpSplitSort];
  }
}


- (void)computeSplitsSum
{
  self->l_splits_sum = 0;

  if (self->oSplits)
  {
    MemHandle pv_split;
    struct s_rec_one_sub_transaction *ps_split;
    UInt16 index;

    index = [self->oSplits size];
    while (index-- > 0)
    {
      pv_split = [self->oSplits fetch:index];
      ps_split = MemHandleLock(pv_split);

      self->l_splits_sum += ps_split->l_amount;

      MemHandleUnlock(pv_split);
    }
  }
}


- (void)redrawSplits
{
  ListType *pt_list = [self objectPtrId:OpSplitList];

  LstEraseList(pt_list);
  LstDrawList(pt_list);
}


- (void)convertField:(UInt16)uh_from_field fromCurrency:(UInt16)uh_from_curr
	     toField:(UInt16)uh_to_field toCurrency:(UInt16)uh_to_curr
{
  t_amount l_amount;

  // Champ FROM vide (ou pas un nombre), on vide le champ TO
  if ([self checkField:uh_from_field
	    flags:FLD_CHECK_NOALERT|FLD_TYPE_FDWORD|FLD_CHECK_VOID
	    resultIn:&l_amount
	    fieldName:FLD_NO_NAME] == false)
  {
    [self replaceField:uh_to_field withSTR:NULL len:0];
    return;
  }

  // On remet FROM en place si jamais il y avait plus de 2 chiffres
  // après la virgule par exemple...
  if (uh_from_field != uh_to_field) // Seulement si FROM et TO diffèrent...
    [self replaceField:REPLACE_FIELD_EXT | uh_from_field
	  withSTR:(Char*)l_amount len:REPL_FIELD_FDWORD];

  // On n'a pas la même devise
  if (uh_from_curr != uh_to_curr)
  {
    UInt16 uh_error;

    uh_error = [[oMaTirelire currency] convertAmount:&l_amount
				       fromId:uh_from_curr
				       toId:uh_to_curr];

    if (uh_error != 0)
    {
      // uh_error == 1 => la 1ère devise n'existe pas
      // uh_error == 2 => la 2ème devise n'existe pas
      // XXX
      l_amount = 0;		// XXX
    }
  }

  [self replaceField:REPLACE_FIELD_EXT | uh_to_field
	withSTR:(Char*)l_amount len:REPL_FIELD_FDWORD];
}


//
// XXX Avant cette méthode il faut faire disparaître la ligne du taux
- (void)changeCurrencyTo:(UInt16)uh_new_curr
{
  Currency *oCurrencies = [oMaTirelire currency];
  struct s_currency *ps_currency;
  UInt16 uh_currency, uh_compute_rate;

  // Calcul du taux à la fin ?
  uh_compute_rate = uh_new_curr & CHG_CURRENCY_COMPUTE_RATE;
  uh_new_curr &= ~CHG_CURRENCY_COMPUTE_RATE;

  // La devise est déjà comme il faut dans le popup des devise
  if (uh_new_curr & (CHG_CURRENCY_DONT_SET_POPUP | CHG_CURRENCY_DONT_CHANGE))
    uh_new_curr &= ~CHG_CURRENCY_DONT_SET_POPUP;
  // On sélectionne la nouvelle devise dans la liste
  else
    [oCurrencies popupList:self->pv_popup_currencies
		 setSelection:uh_new_curr];

  // L'onglet de la devise est vide, inutile d'aller plus loin
  if (self->uh_empty_currency)
    return;

  // Devise du compte
  uh_currency = [[oMaTirelire transaction] accountCurrency:self->uh_account];

  ps_currency = [oCurrencies getId:uh_currency];
  [self fillLabel:OpCurrencyAccountCurrency1 withSTR:ps_currency->ra_name];
  [self fillLabel:OpCurrency1AccountCurrency2 withSTR:ps_currency->ra_name];
  [self fillLabel:OpCurrency2Currency withSTR:ps_currency->ra_name];
  [oCurrencies getFree:ps_currency];

  // Devise de l'opération
  if ((uh_new_curr & CHG_CURRENCY_DONT_CHANGE) == 0)
  {
    ps_currency = [oCurrencies getId:uh_new_curr];
    [self fillLabel:OpCurrency1Currency withSTR:ps_currency->ra_name];
    [self fillLabel:OpCurrency2AccountCurrency2 withSTR:ps_currency->ra_name];
    [oCurrencies getFree:ps_currency];
  }

  // Calcul du nouveau taux
  if (uh_compute_rate)
    [self computeCurrencyRate];
}


- (void)freezeCurrency:(Boolean)b_freeze
{
  self->uh_frozen_currency = b_freeze;
}


- (void)computeCurrencyRate
{
  double d_account_amount, d_curr_amount;
  RectangleType s_rect_left, s_rect_right;
  UInt16 uh_obj, uh_obj_idx, uh_base_obj;

  // Somme dans la monnaie du compte (dans l'onglet devise)
  [self checkField:OpCurrencyAmount flags:FLD_TYPE_DOUBLE
	resultIn:&d_account_amount fieldName:FLD_NO_NAME];

  // Somme dans la devise
  [self checkField:OpAmount flags:FLD_TYPE_DOUBLE
	resultIn:&d_curr_amount	fieldName:FLD_NO_NAME];

  // Une des deux sommes est à 0
  if (d_account_amount == 0 || d_curr_amount == 0)
  {
    // Premier taux
    [self fillLabel:OpCurrency1Rate withSTR:"?"];
    [self fillLabel:OpCurrency1Num withSTR:"?"];

    // Deuxième taux
    [self fillLabel:OpCurrency2Rate withSTR:"?"];
    [self fillLabel:OpCurrency2Num withSTR:"?"];
  }
  // Les deux sommes sont remplies, on peut calculer...
  else
  {
    double d_last_value, d_factor;
    Char ra_num[DOUBLE_STR_SIZE];

    // Premier taux
    for (d_factor = 1.; ;)
    {
      d_last_value = d_factor * d_account_amount / d_curr_amount;

      if (d_last_value >= 1. || d_factor == 1000000.)
	break;

      d_factor *= 10.;
    }

    StrIToA(ra_num, (UInt16)d_factor);
    [self fillLabel:OpCurrency1Num withSTR:ra_num];

    StrDoubleToA(ra_num, d_last_value, NULL, float_dec_separator(), 9);
    [self fillLabel:OpCurrency1Rate withSTR:ra_num];

    // Deuxième taux
    for (d_factor = 1.; ;)
    {
      d_last_value = d_factor * d_curr_amount / d_account_amount;

      if (d_last_value >= 1. || d_factor == 1000000.)
	break;

      d_factor *= 10.;
    }

    StrIToA(ra_num, (UInt16)d_factor);
    [self fillLabel:OpCurrency2Num withSTR:ra_num];

    StrDoubleToA(ra_num, d_last_value, NULL, float_dec_separator(), 9);
    [self fillLabel:OpCurrency2Rate withSTR:ra_num];
  }

  // Redispose les objets sur les lignes du taux
  for (uh_base_obj = OpCurrency1Num; uh_base_obj <= OpCurrency2Num;
       uh_base_obj += OpCurrency2Num - OpCurrency1Num)
  {
    FrmGetObjectBounds(self->pt_frm,
		       FrmGetObjectIndex(self->pt_frm, uh_base_obj),
		       &s_rect_left);

    for (uh_obj = uh_base_obj + 1; // OpCurrency?Num + 1
	 // tant que <= OpCurrency?AccountCurrency2;
	 uh_obj <= uh_base_obj +(OpCurrency1AccountCurrency2 - OpCurrency1Num);
	 uh_obj++)
    {
      uh_obj_idx = FrmGetObjectIndex(self->pt_frm, uh_obj);

      FrmGetObjectBounds(self->pt_frm, uh_obj_idx, &s_rect_right);

      s_rect_right.topLeft.x
	= s_rect_left.topLeft.x + s_rect_left.extent.x + 2;

      // OpCurrency?Rate est un SELECTORTRIGGER donc avec un bord
      // extérieur, on le décale alors de 1. L'objet qui le suit subit
      // la même chose (comme c'est le dernier ça permet de faire un
      // seul test).
      if (uh_obj >= uh_base_obj + (OpCurrency1Rate - OpCurrency1Num))
	s_rect_right.topLeft.x++;

      FrmSetObjectBounds(self->pt_frm, uh_obj_idx, &s_rect_right);

      MemMove(&s_rect_left, &s_rect_right, sizeof(s_rect_right));
    }
  }

  // Il faut faire réapparaître toute la ligne du taux
  [self fillCurrencyTab:true];
}


- (UInt16)expandMacro:(UInt16)uh_desc with:(Desc*)oDesc
{
  Transaction *oTransactions = [oMaTirelire transaction];
  struct s_desc *ps_desc;
  Char ra_account_name[dmCategoryLength];
  UInt16 uh_account, uh_xfer_account, uh_focus = OpAmount;
  Boolean b_change_type = false;
  Boolean b_sign_changed = false;

  ps_desc = [oDesc getId:uh_desc];

  // Le signe
  if (ps_desc->ui_sign > 0)
  {
    Boolean b_credit = ps_desc->ui_sign - 1;

    // Si le signe change
    if (b_credit ^ self->s_trans.uh_op_type)
    {
      [self setCredit:b_credit];

      // Si le formulaire a déjà été dessiné (-open terminé)
      if (self->uh_form_drawn)
      {
	b_change_type = true;
	b_sign_changed = true;
      }

      self->s_trans.uh_op_type = b_credit;
    }
  }

  // Il y a un nombre
  if (ps_desc->ra_amount[0] != '\0')
  {
    [self replaceField:OpAmount withSTR:ps_desc->ra_amount len:-1];

    // Si le nombre commence par 0, le curseur doit être à gauche
    if (ps_desc->ra_amount[0] == '0')
      FldSetInsPtPosition([self objectPtrId:OpAmount], 0);

    // La somme change, il faut mettre à jour l'onglet ventilation
    if (self->uh_tabs_current == 3)
      // Pour nous-mêmes
      [self sendCallerUpdate:(frmMaTiUpdateTransForm
			      | frmMaTiUpdateTransFormSplitsDiff)];
  }

  // Le mode de paiement
  if (ps_desc->ui_is_mode)
    // Le déploiement du mode doit se faire après cette méthode
    self->uh_mode = ps_desc->ui_mode;

  // Le type d'opération
  if (ps_desc->ui_is_type)
  {
    self->uh_type = ps_desc->ui_type;

    // Si le formulaire a déjà été dessiné (-open terminé)
    if (self->uh_form_drawn)
      b_change_type = true;
  }

  // Notre compte
  uh_account = dmAllCategories;
  if (ps_desc->ra_account[0] != '\0')
    uh_account = [oTransactions firstAccountMatching:ps_desc->ra_account];

  // Le compte de transfert
  uh_xfer_account = dmAllCategories;
  if (ps_desc->ra_xfer[0] != '\0')
    uh_xfer_account = [oTransactions firstAccountMatching:ps_desc->ra_xfer];

  // La macro contient un compte
  if (uh_account != dmAllCategories)
  {
    UInt16 uh_old_account = self->uh_account;

    self->uh_account = uh_account;

    // Si on vient de la liste des opérations
    if ([(Object*)self->oPrevForm->oIsa isKindOf:TransListForm])
    {
      oTransactions->ps_prefs->ul_cur_category = uh_account;
      self->ui_update_mati_list |= (frmMaTiUpdateList | frmMaTiChangeAccount);
    }

    // No more last statement number just after account change
    gui_last_stmt_num = 0;

    // L'opération n'a pas déjà un compte de transfert, on peut le changer
    if (self->h_xfer_account < 0)
    {
      // On ne modifie la liste des comptes de transfert, que s'il y
      // avait un compte de transfert dans la macro
      if (ps_desc->ra_xfer[0] != '\0')
      {
	UInt16 uh_old_xfer_account = 0; // Avoid uninitialized warning

	if (self->uh_form_drawn)
	  uh_old_xfer_account
	    = [oTransactions popupListGet:self->pv_popup_xfer_accounts];

	// Entrée "Sans" => on n'a pas trouvé le compte...
	if (uh_xfer_account == dmAllCategories)
	  uh_xfer_account = ACC_POPUP_FIRST;
	// On est encore dans le -open
	else if (self->uh_form_drawn == false)
	{
	  // La devise doit être celle du compte de transfert
	  self->uh_currency = [oTransactions accountCurrency:uh_xfer_account];

	  // Si elle diffère de celle du compte, l'onglet devise doit
	  // être rempli
	  if (self->uh_currency != [oTransactions accountCurrency:uh_account])
	    [self fillCurrencyTab:false];
	}

	// Ici ce n'est pas en fonction de self->uh_form_drawn, car dans
	// tous les cas la liste est déjà construite
	[self initXferAccountsListSelected:uh_xfer_account];

	if (self->uh_form_drawn)
	  [self justChangedXferAccountFrom:uh_old_xfer_account
		to:uh_xfer_account];
      }
    }

    // Si le formulaire a déjà été dessiné (-open terminé)
    if (self->uh_form_drawn)
    {
      [self initAccountsList];

      if (uh_old_account != uh_account)
      {
	Mode *oModes = [oMaTirelire mode];

	[self justChangedAccountFrom:uh_old_account to:uh_account];

	CategoryGetName(oTransactions->db, uh_account, ra_account_name);

	// Il faut recharger les descriptions, modes et types en
	// fonction du nouveau compte
	[oModes popupListFree:self->pv_popup_modes];
	self->pv_popup_modes = [oModes popupListInit:OpModeList
				       form:self->pt_frm
				       Id:(self->uh_mode
					   | ITEM_ADD_UNKNOWN_LINE
					   | ITEM_ADD_EDIT_LINE)
				       forAccount:ra_account_name];

	[self initTypesPopup:self->uh_type forAccount:ra_account_name];

	b_change_type = false; // Inutile de sélectionner le nouveau type + bas

	// Inutile de reconstruire tout de suite la liste des
	// descriptions, elle le sera à son prochain déploiement
	[oDesc popupListFree:self->pv_popup_desc];
	self->pv_popup_desc = NULL;
      }
    }
  }
  // L'opération n'a pas déjà un compte de transfert
  // ET la macro a un compte de transfert
  else if (self->h_xfer_account < 0 && ps_desc->ra_xfer[0] != '\0')
  {
    UInt16 uh_old_xfer_account = 0; // Avoid uninitialized warning

    if (self->uh_form_drawn)
      uh_old_xfer_account
	= [oTransactions popupListGet:self->pv_popup_xfer_accounts];

    // Entrée "Sans" => on n'a pas trouvé le compte...
    if (uh_xfer_account == dmAllCategories)
      uh_xfer_account = ACC_POPUP_FIRST;
    // On est encore dans le -open
    else if (self->uh_form_drawn == false)
    {
      // La devise doit être celle du compte de transfert
      self->uh_currency = [oTransactions accountCurrency:uh_xfer_account];

      // Si elle diffère de celle du compte, l'onglet devise doit
      // être rempli
      if (self->uh_currency !=[oTransactions accountCurrency:self->uh_account])
	[self fillCurrencyTab:false];

      // Le popup des types doit être recalculé sans les types signés
      [self initTypesPopup:self->uh_type | TYPE_FLAG_SIGN_NONE forAccount:NULL];

      b_change_type = false; // Inutile de sélectionner le nouveau type + bas
    }

    // Ici ce n'est pas en fonction de self->uh_form_drawn, car dans
    // tous les cas la liste est déjà construite
    [self initXferAccountsListSelected:uh_xfer_account];

    if (self->uh_form_drawn)
      [self justChangedXferAccountFrom:uh_old_xfer_account to:uh_xfer_account];
  }

  // La description
  if (ps_desc->ra_desc[0] != '\0')
    if ([self expandDesc:ps_desc inField:OpDesc])
      uh_focus = OpDesc;

  // Numéro de chèque auto ?
  if (ps_desc->ui_cheque_num)
    [self checkNumAuto];

  // Auto-validation ???
  if (ps_desc->ui_auto_valid)
    CtlHitControl([self objectPtrId:OpOK]);

  [oDesc getFree:ps_desc];

  if (b_change_type)
  {
    // Si le signe vient de changer, on reconstruit tout le popup des types
    if (b_sign_changed)
      [self initTypesPopup:self->uh_type forAccount:NULL];
    else
      [[oMaTirelire type] popupList:self->pv_popup_types
			  setSelection:self->uh_type];
  }

  /* Le focus
   * - dans le champ somme par défaut
   * - dans le champ desc si le dernier caractère inséré est un espace
   */

  return uh_focus;
}


//
// Renvoie true si le focus doit être positionné sur ce champ
//
// %-n agit sur :
// - T (n est en heures)
// - m et M
// - Y
// - d et D (n est en jours)
//
// %~ agit sur :
// - T (heures, si minutes > 30 alors heure suivante)
// - m et M (si jour > 15, alors mois suivant)
// - Y (si mois > 6, alors année suivante)
// - d et D (si heure > 12, alors un jour de plus)
- (Boolean)expandDesc:(struct s_desc*)ps_desc inField:(UInt16)uh_id
{
  Transaction *oTransactions = [oMaTirelire transaction];
  FieldType *pt_field = [oFrm objectPtrId:uh_id]; // Dans formulaire courant
  Char *pa_last, *pa_cur, *pa_esc;
  Char ra_esc[36 + 1];
  WChar wa_chr;
  UInt16 uh_size;
  Boolean b_focus = false;

  pa_last = pa_cur = ps_desc->ra_desc;

  // Il faut vider le champ avant l'insertion...
  if (oMaTirelire->s_prefs.ul_replace_desc)
    [oFrm replaceField:uh_id withSTR:NULL len:0]; // Dans formulaire courant

  for (;;)
  {
    uh_size = TxtGlueGetNextChar(pa_cur, 0, &wa_chr);
    if (wa_chr == '\0')
    {
  desc_end:
      if (pa_cur != pa_last)
      {
	uh_size = pa_cur - pa_last;
	FldInsert(pt_field, pa_last, uh_size);

	// Si le dernier caractère est un espace, focus dans ce champ
	uh_size--;
	if (pa_last[uh_size] == ' ' || pa_last[uh_size] == '\n')
	  b_focus = true;
      }
      break;
    }

    pa_cur += uh_size;

    if (wa_chr == '%')
    {
      Int16 h_inc = 0;
      Boolean b_closest = false;

      pa_esc = pa_cur - uh_size;

      uh_size = TxtGlueGetNextChar(pa_cur, 0, &wa_chr);
      pa_cur += uh_size;

  again:
      switch (wa_chr)
      {
      case '~':
	if (b_closest == false)
	{
	  b_closest = true;

	  uh_size = TxtGlueGetNextChar(pa_cur, 0, &wa_chr);
	  pa_cur += uh_size;

	  goto again;
	}
	break;

      case '-':
      case '+':
	if (h_inc == 0)
	{
	  h_inc = (wa_chr == '-') ? -1 : 1;

	  uh_size = TxtGlueGetNextChar(pa_cur, 0, &wa_chr);
	  pa_cur += uh_size;

	  if (wa_chr >= '1' && wa_chr <= '9')
	  {
	    h_inc *= wa_chr - '0';

	    uh_size = TxtGlueGetNextChar(pa_cur, 0, &wa_chr);
	    pa_cur += uh_size;

	    // 2 chiffres au max...
	    if (wa_chr >= '0' && wa_chr <= '9')
	    {
	      h_inc *= 10;

	      wa_chr -= '0';
	      if (h_inc < 0)
		h_inc -= wa_chr;
	      else
		h_inc += wa_chr;

	      uh_size = TxtGlueGetNextChar(pa_cur, 0, &wa_chr);
	      pa_cur += uh_size;
	    }
	  }

	  goto again;
	}
	break;

      case 'T':		// Heure de l'opération
	h_inc += self->s_time.hours;
	if (h_inc < 0)
	  h_inc += 24;

	// L'heure la plus proche
	if (b_closest && self->s_time.minutes > 30)
	  h_inc++;

	h_inc %= 24;

	TimeToAscii(h_inc, self->s_time.minutes,
		    (TimeFormatType)PrefGetPreference(prefTimeFormat),
		    ra_esc);
	goto desc_insert;

      case 'm':		// Mois en chiffres
      case 'M':		// Mois en toutes lettres
	h_inc += self->s_date.month - 1;
	if (h_inc < 0)
	  h_inc += 12;

	// Le mois le plus proche
	if (b_closest && self->s_date.day > 15)
	  h_inc++;

	h_inc %= 12;

	if (wa_chr == 'm')
	  StrIToA(ra_esc, h_inc + 1);
	else
	  SysStringByIndex(strLongMonths, h_inc, ra_esc, sizeof(ra_esc));
	goto desc_insert;

      case 'Y':		// Année (4 chiffres)
	// L'année la plus proche
	if (b_closest && self->s_date.month > 6)
	  h_inc++;

	StrIToA(ra_esc, self->s_date.year + firstYear + h_inc);
	goto desc_insert;

      case 'd':		// Jour
      case 'D':		// Date de l'opération
      {
	DateType s_date = self->s_date;

	// Le jour le plus proche
	if (b_closest && self->s_time.hours > 12)
	  h_inc++;

	DateAdjust(&s_date, h_inc);

	if (wa_chr == 'd')
	  StrIToA(ra_esc, s_date.day);
	else
	  DateToAscii(s_date.month, s_date.day, s_date.year + firstYear,
		      (DateFormatType)PrefGetPreference(prefDateFormat),
		      ra_esc);
      }
      goto desc_insert;

      case 'A':		// Nom du compte de l'opération
	CategoryGetName(oTransactions->db, self->uh_account, ra_esc);
	goto desc_insert;

      case 'B':		// Base contenant le compte de l'opération
	StrCopy(ra_esc, oMaTirelire->s_prefs.ra_last_db);
	goto desc_insert;

      case 'x':		// Juste le compte de transfert
      case 'X':		// Transfert "AAA -> BBB" en fonction du signe
      {
	UInt16 uh_from, uh_to, uh_xfer;

	if (self->pv_popup_xfer_accounts != NULL)
	{
	  uh_xfer= [oTransactions popupListGet:self->pv_popup_xfer_accounts];
	  if (uh_xfer == ACC_POPUP_FIRST)
	  {
	    ra_esc[0] = '\0';
	    goto desc_insert;
	  }
	}
	else
	  uh_xfer = self->h_xfer_account;

	// Juste le compte de transfert
	if (wa_chr == 'x')
	{
	  CategoryGetName(oTransactions->db, uh_xfer, ra_esc);
	  goto desc_insert;
	}

	// Crédit => xfer -> compte
	if (self->s_trans.uh_op_type)
	{
	  uh_from = uh_xfer;
	  uh_to = self->uh_account;
	}
	// Débit => compte -> xfer
	else
	{
	  uh_to = uh_xfer;
	  uh_from = self->uh_account;
	}

	CategoryGetName(oTransactions->db, uh_from, ra_esc);
	StrCat(ra_esc, " -> ");
	CategoryGetName(oTransactions->db, uh_to, &ra_esc[StrLen(ra_esc)]);
      }
      goto desc_insert;

      case '%':
	ra_esc[0] = '%';
	ra_esc[1] = '\0';

    desc_insert:
	if (pa_esc != pa_last)
	  FldInsert(pt_field, pa_last, pa_esc - pa_last);

	FldInsert(pt_field, ra_esc, StrLen(ra_esc));
	pa_last = pa_cur;
	break;

      // Paste current text clipboard contents
      case 'V':
      {
	MemHandle pv_clipboard;
	UInt16 uh_len;

	if (pa_esc != pa_last)
	  FldInsert(pt_field, pa_last, pa_esc - pa_last);

	pv_clipboard = ClipboardGetItem(clipboardText, &uh_len);
	if (pv_clipboard != NULL)
	{
	  if (uh_len > 0)
	    FldInsert(pt_field, MemHandleLock(pv_clipboard), uh_len);
	  MemHandleUnlock(pv_clipboard);
	}

	pa_last = pa_cur;
      }
      break;

      case '\0':
	pa_cur -= uh_size;
	goto desc_end;
      }
    }
  } // for (;;)

  return b_focus;
}


- (void)expandMode:(UInt16)uh_mode with:(Mode*)oModes
{
  struct s_mode *ps_mode;
  DateType s_new_date;

  ps_mode = [oModes getId:uh_mode];
  if (ps_mode == NULL)
    return;

  self->uh_mode = uh_mode;

  // Si le formulaire a déjà été dessiné (-open terminé)
  if (self->uh_form_drawn)
    [oModes popupList:self->pv_popup_modes setSelection:uh_mode];

  // Il y a un raccourci sur date de valeur
  DateToInt(s_new_date) = 0;

  switch (ps_mode->ui_value_date)
  {
    // ZZ jours en plus ou en moins par rapport à la date de l'opération
  case MODE_VAL_DATE_PLUS_DAYS:
  case MODE_VAL_DATE_MINUS_DAYS:
  {
    Int16 h_inc;

    h_inc = ps_mode->ui_first_val;

    if (ps_mode->ui_value_date == MODE_VAL_DATE_MINUS_DAYS)
      h_inc = - h_inc;

    DateDaysToDate(DateToDays(self->s_date) + h_inc, &s_new_date);
  }
  break;

  case MODE_VAL_DATE_CUR_MONTH:
  case MODE_VAL_DATE_NEXT_MONTH:
  {
    UInt16 uh_days_in_month;

    s_new_date = self->s_date;

    if (ps_mode->ui_value_date == MODE_VAL_DATE_NEXT_MONTH)
      s_new_date.month++;	// Mois suivant

    // Si on est après la date limite dans le mois, le débit est en
    // mois + 2 si prochain mois, et en mois + 1 si mois courant
    if (s_new_date.day > ps_mode->ui_first_val)
      s_new_date.month++;

    // On est passé à l'année suivante...
    if (s_new_date.month > 12)
    {
      s_new_date.month %= 12;	// Au pire on dépasse de 2 mois (14)
      s_new_date.year++;
    }

    // Le jour fixe ne doit pas dépasser la fin du mois
    uh_days_in_month = DaysInMonth(s_new_date.month, s_new_date.year);
    s_new_date.day = (ps_mode->ui_debit_date >= uh_days_in_month)
      ? uh_days_in_month : ps_mode->ui_debit_date;
  }
  break;
  }

  [oModes getFree:ps_mode];

  if (DateToInt(s_new_date) != 0)
  {
    self->s_value_date = s_new_date;

    // Si le formulaire a déjà été dessiné (-open terminé)
    if (self->uh_form_drawn)
      [self setValueDate];
  }
}


- (void)setValueDate
{
  if (DateToInt(self->s_date) == DateToInt(self->s_value_date))
  {
    Char ra_label[14 + 1];

    SysCopyStringResource(ra_label, strOpNoValueDate);

    [self fillLabel:OpValueDate withSTR:ra_label];
  }
  else
    [super dateSet:OpValueDate
	   date:self->s_value_date
	   format:(DateFormatType)PrefGetPreference(prefLongDateFormat)];
}


- (Boolean)checkNumAuto
{
  Transaction *oTransactions = [oMaTirelire transaction];
  MemHandle vh_item;
  struct s_transaction *ps_tr;
  struct s_account_prop *ps_prop;
  PROGRESSBAR_DECL;
  struct s_rec_options s_options;
  UInt32 rui_chequebooks[4][2], ui_cheque_num;
  UInt16 uh_account, uh_num_chequebook, uh_chequebook, index;


  uh_account = self->uh_account;

  // Les chéquiers et leurs intervalles
  ps_prop = [oTransactions accountProperties:uh_account index:&index];
  for (uh_num_chequebook = 0; uh_num_chequebook < 4; uh_num_chequebook++)
  {
    ui_cheque_num = ps_prop->rui_check_books[uh_num_chequebook];

    if (ui_cheque_num == 0)
      break;

    rui_chequebooks[uh_num_chequebook][0] = ui_cheque_num;
    rui_chequebooks[uh_num_chequebook][1]
      = ui_cheque_num + ps_prop->ui_acc_cheques_by_cbook - 1;
  }
  MemPtrUnlock(ps_prop);

  // Pas de chéquier sur ce compte...
  if (uh_num_chequebook == 0)
  {
    FrmAlert(alertNoChequebook);
    return false;
  }

  PROGRESSBAR_BEGIN(DmNumRecords(oTransactions->db),
		    strProgressBarAutoChequeSearch);

  while (uh_num_chequebook > 0
	 && (index++, vh_item = DmQueryNextInCategory(oTransactions->db, // PG
						      &index,
						      uh_account)) != NULL)
  {
    ps_tr = MemHandleLock(vh_item);

    // Pas besoin de tester qu'on est sur les propriétés d'un compte,
    // on les a passés au début de la méthode
    if (ps_tr->ui_rec_check_num)
    {
      options_extract(ps_tr, &s_options);

      ui_cheque_num = s_options.ps_check_num->ui_check_num;

      // Pour chaque chéquier
      for (uh_chequebook = 0; uh_chequebook < uh_num_chequebook;
	   uh_chequebook++)
	if (ui_cheque_num >= rui_chequebooks[uh_chequebook][0]
	    && ui_cheque_num <= rui_chequebooks[uh_chequebook][1])
	{
	  // Dernier chèque du chéquier, on retire le chéquier...
	  if (ui_cheque_num == rui_chequebooks[uh_chequebook][1])
	  {
	    if (uh_chequebook < uh_num_chequebook - 1)
	      MemMove(&rui_chequebooks[uh_chequebook],
		      &rui_chequebooks[uh_chequebook + 1],
		      sizeof(rui_chequebooks[0])
		      * (uh_num_chequebook - uh_chequebook - 1));

	    uh_num_chequebook--;
	    uh_chequebook--;	// Va être réincrémenté dans le for(;;)
	  }
	  else
	    rui_chequebooks[uh_chequebook][0] = ui_cheque_num + 1;
	}
    }

    MemHandleUnlock(vh_item);

    PROGRESSBAR_INLOOP(index, 40); // OK
  }

  PROGRESSBAR_END;

  if (uh_num_chequebook == 0)
  {
    // Tous les chéquiers ont leur dernier chèque déjà fait...

    FrmAlert(alertFilledChequebooks);
    return false;
  }

  // Un seul chéquier...
  if (uh_num_chequebook == 1)
    ui_cheque_num = rui_chequebooks[0][0];
  // Le popup avec les chéquiers...
  else
  {
    Char *rpa_text[uh_num_chequebook];
    ListType *pt_list;
    RectangleType s_rect;
    Char ra_num_cheques[uh_num_chequebook][10 + 1];
    UInt16 uh_len, uh_width, uh_largest, uh_list;

    uh_largest = 0;
    for (uh_chequebook = 0; uh_chequebook < uh_num_chequebook; uh_chequebook++)
    {
      StrUInt32ToA(ra_num_cheques[uh_chequebook],
		   rui_chequebooks[uh_chequebook][0],
		   &uh_len);
      uh_width = FntCharsWidth(ra_num_cheques[uh_chequebook], uh_len);
      if (uh_width > uh_largest)
	uh_largest = uh_width;

      rpa_text[uh_chequebook] = ra_num_cheques[uh_chequebook];
    }

    uh_list = FrmGetObjectIndex(self->pt_frm, OpNumList);
    pt_list = FrmGetObjectPtr(self->pt_frm, uh_list);

    LstSetListChoices(pt_list, rpa_text, uh_num_chequebook);
    LstSetHeight(pt_list, uh_num_chequebook);
    LstSetSelection(pt_list, 0); // On sélectionne la première entrée

    // On remet la liste à la bonne position (avec une largeur adéquate)
    FrmGetObjectBounds(self->pt_frm, uh_list, &s_rect);
    s_rect.extent.x = uh_largest + LIST_MARGINS_NO_SCROLL;
    FrmGetObjectPosition(self->pt_frm,
			 FrmGetObjectIndex(self->pt_frm, OpCheckNumAuto),
			 &s_rect.topLeft.x, &s_rect.topLeft.y);
    FrmSetObjectBounds(self->pt_frm, uh_list, &s_rect);

    index = LstPopupList(pt_list);
    if (index == noListSelection)
      return false;

    ui_cheque_num = rui_chequebooks[index][0];
  }

  // Mise en place de ui_cheque_num dans le champ numéro de chèque...
  [self replaceField:REPLACE_FIELD_EXT | OpCheckNum
	withSTR:(Char*)ui_cheque_num
	len:REPL_FIELD_DWORD | REPL_FIELD_EMPTY_IF_NULL];

  return true;
}


- (void)dateSet:(UInt16)uh_date_id date:(DateType)s_date
	 format:(DateFormatType)e_format
{
  switch (uh_date_id)
  {
  case OpDate:
  {
    DateType s_old_date = self->s_date;

    self->s_date = s_date;

    // La date de l'opération étaient égales avant : elles doivent le rester
    if (DateToInt(s_old_date) == DateToInt(self->s_value_date))
      self->s_value_date = s_date;
    // Elles n'étaient pas égales, mais le sont désormais
    else if (DateToInt(s_date) == DateToInt(self->s_value_date))
      [self setValueDate];

    // Si la date de l'opération devient supérieure à la date de fin
    // de répétition, on décale la date de fin de répétition
    if (DateToInt(self->s_repeat_end_date) != 0)
    {
      if (DateToInt(self->s_repeat_end_date) < DateToInt(self->s_date))
      {
	self->s_repeat_end_date = self->s_date;

	// Récursif, mais sur la date repeat
	[self dateSet:OpRepeatEndDate date:self->s_repeat_end_date format:0];
      }
      // On met à jour les occurences de répétition
      else
	[self repeatUpdateOccurrences];
    }
  }
  break;

    // Cas particulier pour la date de valeur
  case OpValueDate:
    [self setValueDate];
    return;

  case OpRepeatEndDate:
    // La date de fin de répétition ne peut pas être antérieure à la
    // date de l'opération
    if (DateToInt(s_date) < DateToInt(self->s_date))
    {
      // XXX Alerte ? XXX
      return;
    }

    self->s_repeat_end_date = s_date;

    // On calcule le nombre d'occurrences
    [self repeatUpdateOccurrences];
    break;
  }

  [super dateSet:uh_date_id date:s_date
	 format:PrefGetPreference(prefLongDateFormat)];
}


//
// Calcule le cas dans lequel on se trouve
- (UInt16)case
{
  Transaction *oTransactions = [oMaTirelire transaction];
  UInt16 uh_currency, uh_xfer_currency, uh_account_currency;
  UInt16 uh_xfer_account;


  // Devise actuellement sélectionnée
  uh_currency
    = [[oMaTirelire currency] popupListGet:self->pv_popup_currencies];

  // Monnaie du compte courant
  uh_account_currency = [oTransactions accountCurrency:self->uh_account];

  // On n'a pas de popup des comptes, donc on a un compte de transfert
  if (self->pv_popup_xfer_accounts == NULL)
  {
    uh_xfer_account = self->h_xfer_account;

 with_xfer_account:
    uh_xfer_currency = [oTransactions accountCurrency:uh_xfer_account];

    if (uh_currency != uh_account_currency)
    {
      // !!! Pas normal !!!!
    }

    // Les deux comptes ont la même devise
    if (uh_account_currency == uh_xfer_currency)
      self->uh_case = TRANSFORM_CASE_4;
    else
      self->uh_case = TRANSFORM_CASE_3;
  }
  // On a un popup des comptes de transfert
  else
  {
    uh_xfer_account= [oTransactions popupListGet:self->pv_popup_xfer_accounts];

    // Il y a un compte de transfert
    if (uh_xfer_account != ACC_POPUP_FIRST)
      goto with_xfer_account;

    // Pas de compte de transfert ici...

    // Même devise que celle du compte courant
    if (uh_currency == uh_account_currency)
      self->uh_case = TRANSFORM_CASE_1;
    else
      self->uh_case = TRANSFORM_CASE_2;
  }

  return self->uh_case;
}


- (void)justChangedAccountFrom:(UInt16)uh_old_account to:(UInt16)uh_new_account
{
  Transaction *oTransactions;
  UInt16 uh_old_currency, uh_new_currency;

  // Rien à faire
  if (uh_old_account == uh_new_account)
    return;

  oTransactions = [oMaTirelire transaction];

  uh_old_currency = [oTransactions accountCurrency:uh_old_account];
  uh_new_currency = [oTransactions accountCurrency:uh_new_account];

  self->uh_account = uh_new_account;

  switch (self->uh_case)
  {
    // Compte : OLD => NEW / Xfer = Sans / Devise = OLD
  case TRANSFORM_CASE_1:
    // La devise change en la monnaie du compte
    [self changeCurrencyTo:uh_new_currency];

    // Reste cas 1
    break;

    // Compte : OLD => NEW / Xfer = Sans / Devise = X
  case TRANSFORM_CASE_2:
  {
    UInt16 uh_currency = [[oMaTirelire currency]
			   popupListGet:self->pv_popup_currencies];

    // La monnaie du nouveau compte est identique à la devise
    if (uh_new_currency == uh_currency)
    {
      // L'onglet devise est vidé
      [self emptyCurrencyTab];

      // Devient cas 1
      self->uh_case = TRANSFORM_CASE_1;
    }
    // La devise reste différente de la monnaie du nouveau compte
    else
    {
      // L'onglet est déjà rempli, mais on appelle cette méthode pour
      // cacher les objets avant la mise à jour
      [self fillCurrencyTab:false];

      // La somme de l'onglet devise est recalculée en fonction de la
      // somme de l'opération qui est dans la devise X
      [self convertField:OpAmount fromCurrency:uh_currency
	    toField:OpCurrencyAmount toCurrency:uh_new_currency];

      // La monnaie du compte vient de changer (mais pas la devise,
      // donc on va juste modifier les libellés de la monnaie du
      // compte dans l'onglet des devises)
      // Avec recalcul du taux
      [self changeCurrencyTo:(CHG_CURRENCY_DONT_CHANGE
			      | CHG_CURRENCY_COMPUTE_RATE)];

      // Reste cas 2
    }
  }
  break;

  // Compte : OLD => NEW / Xfer = XFER / Devise = XFER
  // ** Normalement NEW ne peut pas valoir XFER **
  case TRANSFORM_CASE_3:
  {
    UInt16 uh_currency = [[oMaTirelire currency]
			   popupListGet:self->pv_popup_currencies];

    // La monnaie du nouveau compte est identique à la devise/XFER
    if (uh_new_currency == uh_currency)
    {
      // L'onglet devise est vidé
      [self emptyCurrencyTab];

      // Devient cas 4
      self->uh_case = TRANSFORM_CASE_4;
    }
    // Monnaies différentes
    else
    {
      // L'onglet est déjà rempli, mais on appelle cette méthode pour
      // cacher les objets avant la mise à jour
      [self fillCurrencyTab:false];

      // La somme de l'onglet devise est recalculée en fonction de la
      // somme de l'opération qui est dans la devise XFER
      [self convertField:OpAmount fromCurrency:uh_currency
	    toField:OpCurrencyAmount toCurrency:uh_new_currency];

      // La monnaie du compte vient de changer (mais pas la devise,
      // donc on va juste modifier les libellés de la monnaie du
      // compte dans l'onglet des devises)
      // Avec recalcul du taux
      [self changeCurrencyTo:(CHG_CURRENCY_DONT_CHANGE
			      | CHG_CURRENCY_COMPUTE_RATE)];

      // Reste cas 3
    }
  }
  break;

  // Compte : OLD => NEW / Xfer = XFER / Devise = XFER = OLD
  // ** Normalement NEW ne peut pas valoir XFER **
  case TRANSFORM_CASE_4:
    // La monnaie du nouveau compte change
    if (uh_old_currency != uh_new_currency)
    {
      // L'onglet devise va être rempli
      [self fillCurrencyTab:false];

      // La somme de l'onglet devise est recalculée en fonction de la
      // somme de l'opération qui est dans la devise OLD
      [self convertField:OpAmount fromCurrency:uh_old_currency
	    toField:OpCurrencyAmount toCurrency:uh_new_currency];

      // La monnaie du compte vient de changer (mais pas la devise,
      // donc on va juste modifier les libellés de la monnaie du
      // compte dans l'onglet des devises)
      // Avec recalcul du taux
      [self changeCurrencyTo:(CHG_CURRENCY_DONT_CHANGE
			      | CHG_CURRENCY_COMPUTE_RATE)];

      // Devient cas 3
      self->uh_case = TRANSFORM_CASE_3;
    }
    // Sinon reste cas 4
    break;

  default:
    alert_error_str("from %u to %u impossible case %u!",
		    uh_old_account, uh_new_account, self->uh_case);
    return;
  }

  // La liste des xfer est reconstruite sans self->uh_account
  if (self->pv_popup_xfer_accounts != NULL)
    [self initXferAccountsListSelected:-1];
}


- (void)justChangedXferAccountFrom:(UInt16)uh_old_account
				to:(UInt16)uh_new_account
{
  Transaction *oTransactions;
  UInt16 uh_old_currency, uh_new_currency, uh_account_currency;

  // Rien à faire
  if (uh_old_account == uh_new_account)
    return;

  oTransactions = [oMaTirelire transaction];

  // Si le compte de transfert est "Sans", prend la monnaie du compte courant
  uh_old_currency
    = uh_old_account == ACC_POPUP_FIRST ? self->uh_account : uh_old_account;
  uh_old_currency = [oTransactions accountCurrency:uh_old_currency];

  // Si le compte de transfert est "Sans", prend la monnaie du compte courant
  uh_new_currency
    = uh_new_account == ACC_POPUP_FIRST ? self->uh_account : uh_new_account;
  uh_new_currency = [oTransactions accountCurrency:uh_new_currency];

  // Monnaie du compte
  uh_account_currency = [oTransactions accountCurrency:self->uh_account];

  switch (self->uh_case)
  {
    // Compte = COMPTE / Xfer : Sans => NEW / Devise = COMPTE
  case TRANSFORM_CASE_1:
    // Les deux comptes partagent la même devise (uh_old_devise est
    // forcément la monnaie du compte courant dans le cas 1)
    if (uh_new_currency == uh_old_currency)
    {
      // Pas besoin de vider l'onglet devise, car dans le cas 1 il est
      // déjà vide

      // Devient cas 4
      self->uh_case = TRANSFORM_CASE_4;
    }
    // Les devises diffèrent
    else
    {
      // L'onglet devise va être rempli
      [self fillCurrencyTab:false];

      // La somme de l'onglet devise est convertie dans la devise du compte
      [self convertField:OpAmount fromCurrency:uh_new_currency
	    toField:OpCurrencyAmount toCurrency:uh_account_currency];

      // La devise change en la devise du nouveau compte de transfert
      // Avec recalcul du taux
      [self changeCurrencyTo:CHG_CURRENCY_COMPUTE_RATE | uh_new_currency];

      // Devient cas 3
      self->uh_case = TRANSFORM_CASE_3;
    }

    // La devise ne peut plus changer
    [self freezeCurrency:true];
    break;

    // Compte = COMPTE / Xfer : Sans => NEW / Devise = X
  case TRANSFORM_CASE_2:
    // Si la monnaie du nouveau compte de transfert est la même que
    // celle du compte courant qui est uh_old_currency puisque
    // uh_old_account == ACC_POPUP_FIRST dans ce cas
    if (uh_new_currency == uh_old_currency)
    {
      // L'onglet devise est vidé
      [self emptyCurrencyTab];

      // La devise change en la monnaie du compte de transfert
      [self changeCurrencyTo:uh_new_currency];

      // Devient cas 4
      self->uh_case = TRANSFORM_CASE_4;
    }
    else
    {
      UInt16 uh_currency = [[oMaTirelire currency]
			     popupListGet:self->pv_popup_currencies];

      // La devise du nouveau compte de Xfer est différente de la
      // devise en cours
      if (uh_new_currency != uh_currency)
      {
	// L'onglet est déjà rempli, mais on appelle cette méthode pour
	// cacher les objets avant la mise à jour
	[self fillCurrencyTab:false];

	// La somme de l'opération est convertie dans la devise du compte
	[self convertField:OpAmount fromCurrency:uh_new_currency
	      toField:OpCurrencyAmount toCurrency:uh_account_currency];

	// La devise change en la monnaie du compte de transfert
	// Avec recalcul du taux
	[self changeCurrencyTo:CHG_CURRENCY_COMPUTE_RATE | uh_new_currency];
      }

      // Devient cas 3
      self->uh_case = TRANSFORM_CASE_3;
    }

    // La devise ne peut plus changer
    [self freezeCurrency:true];
    break;

    // Compte = COMPTE / Xfer : OLD => NEW / Devise = OLD
    // ** Normalement NEW ne peut pas valoir COMPTE **
  case TRANSFORM_CASE_3:
    // Plus de compte de transfert
    if (uh_new_account == ACC_POPUP_FIRST)
    {
      // La devise peut à nouveau changer
      [self freezeCurrency:false];

      // Devient cas 2
      self->uh_case = TRANSFORM_CASE_2;
    }
    // Le nouveau compte de transfert a la même monnaie que le compte courant
    else if (uh_new_currency == uh_account_currency)
    {
      // L'onglet devise est vidé
      [self emptyCurrencyTab];

      // La devise devient la même que la monnaie du compte
      [self changeCurrencyTo:uh_new_currency];

      // Devient cas 4
      self->uh_case = TRANSFORM_CASE_4;
    }
    // Les monnaies du compte courant et du compte de transfert sont
    // différentes, ET la monnaie du compte de transfert est
    // différente de l'ancienne devise
    else if (uh_new_currency != uh_old_currency)
    {
  case_3:
      // L'onglet est déjà rempli, mais on appelle cette méthode pour
      // cacher les objets avant la mise à jour
      [self fillCurrencyTab:false];

      // La somme de l'opération est convertie dans la monnaie du compte
      [self convertField:OpAmount fromCurrency:uh_new_currency
	    toField:OpCurrencyAmount toCurrency:uh_account_currency];

      // La devise devient la même que la monnaie du compte de transfert
      // Avec recalcul du taux
      [self changeCurrencyTo:CHG_CURRENCY_COMPUTE_RATE | uh_new_currency];

      // Reste cas 3
    }
    // Sinon reste cas 3
    break;

    // Compte = COMPTE / Xfer : OLD => NEW / Devise = COMPTE = OLD
  case TRANSFORM_CASE_4:
    // Plus de compte de transfert
    if (uh_new_account == ACC_POPUP_FIRST)
    {
      // La devise peut à nouveau changer
      [self freezeCurrency:false];

      // La devise reste telle quelle... Ça permet de revenir
      // facilement en arrière.

      // Devient cas 2
      self->uh_case = TRANSFORM_CASE_2;
    }
    // Le nouveau compte de transfert n'a pas la même monnaie que le
    // compte courant (qui est l'ancienne monnaie puisque dans ce cas
    // tout le monde a la même monnaie)
    else if (uh_new_currency != uh_old_currency)
    {
      // Devient cas 3
      self->uh_case = TRANSFORM_CASE_3;

      goto case_3;
    }
    // Sinon reste cas 4
    break;

  default:
    alert_error_str("from %u to %u impossible case %u!",
		    uh_old_account, uh_new_account, self->uh_case);
    break;
  }

  // La liste des comptes est reconstruite sans le nouveau compte de transfert
  [self initAccountsList];
}


- (void)justChangedCurrencyFrom:(UInt16)uh_old_currency
			     to:(UInt16)uh_new_currency
{
  UInt16 uh_account_currency;

  uh_account_currency
    = [[oMaTirelire transaction] accountCurrency:self->uh_account];

  switch (self->uh_case)
  {
    // Compte = COMPTE / Xfer = Sans / Devise : COMPTE/OLD => NEW
  case TRANSFORM_CASE_1:
    // La devise ne change pas => reste cas 1
    if (uh_old_currency == uh_new_currency)
      break;

    // Devient cas 2
    self->uh_case = TRANSFORM_CASE_2;

    goto case_2;

    // Compte = COMPTE / Xfer = Sans / Devise : OLD => NEW
    // OLD peut être égal à NEW
  case TRANSFORM_CASE_2:
    // On repasse sur la devise du compte courant
    if (uh_new_currency == uh_account_currency)
    {
      // L'onglet devise est vidé
      [self emptyCurrencyTab];

      // Devient cas 1
      self->uh_case = TRANSFORM_CASE_1;
    }
    else
    {
  case_2:
      // L'onglet est déjà rempli (sauf si on vient de
      // TRANSFORM_CASE_1), mais on appelle cette méthode pour cacher
      // les objets avant la mise à jour
      [self fillCurrencyTab:false];

      // La somme de l'onglet devise prend la valeur de la somme de
      // l'opération dans la monnaie du compte
      [self convertField:OpAmount fromCurrency:uh_new_currency
	    toField:OpCurrencyAmount toCurrency:uh_account_currency];

      // La devise vient de changer (donc pas besoin de la
      // repositionner dans le popup, c'est déjà fait)
      // Avec recalcul du taux
      [self changeCurrencyTo:(CHG_CURRENCY_DONT_SET_POPUP
			      | CHG_CURRENCY_COMPUTE_RATE
			      | uh_new_currency)];

      // Reste cas 2
    }
    break;

    // Compte = COMPTE / Xfer = XFER / Devise : XFER/OLD => NEW
  case TRANSFORM_CASE_3:	// Impossible
    // Compte = COMPTE / Xfer = XFER / Devise : XFER/COMPTE/OLD => NEW
  case TRANSFORM_CASE_4:	// Impossible
  default:
    alert_error_str("from %u to %u impossible case %u!",
		    uh_old_currency, uh_new_currency, self->uh_case);
    break;
  }
}


- (Boolean)menu:(UInt16)uh_id
{
  if ([super menu:uh_id])
    return true;

  switch (uh_id)
  {
  case TransMenuPrev:
  case TransMenuNext:
    [self gotoNext:uh_id - TransMenuPrev];
    break;

  case MenuTransFormCopy:
  {
    UInt16 uh_date_action, uh_id_to_copy;

    // Sauvegarde de l'opération courante
    if ([self extractAndSave] == false)
      break;

    // On demande l'attitude à adopter pour la date
    uh_date_action = FrmAlert(alertCopy);
    if (uh_date_action == 2)
      break;			// Annuler

    uh_id_to_copy = self->s_trans.h_edited_rec;
    self->s_trans.h_edited_rec = -1; // C'est une nouvelle opération

    [self copyId:uh_id_to_copy sameDate:uh_date_action];

    // Focus sur la somme
    [self focusObject:OpAmount];

    // Dessin du formulaire
    [self redrawForm];
  }
  break;

  case TransMenuModes:
    FrmPopupForm(ModesListFormIdx);
    break;

  case TransMenuDesc:
    FrmPopupForm(DescListFormIdx);
    break;

  case TransMenuTypes:
    // Car TypesListForm appelle la méthode -getInfos
    self->ui_infos = (TYPE_LIST_DEFAULT_ID |
		      [[oMaTirelire type] popupListGet:self->pv_popup_types]);

    // On lance la boîte d'édition des types...
    FrmPopupForm(TypesListFormIdx);
    break;

  case TransMenuCurr:
    // On lance la boîte d'édition des devises...
    FrmPopupForm(CurrenciesListFormIdx);
    break;

  default:
    return false;
  }

  return true;
}


- (void)beforeOpen
{
  struct s_db_prefs *ps_db_prefs = [oMaTirelire transaction]->ps_prefs;

  // On passe le formulaire en mode focus car il n'est pas modal
  if (oMaTirelire->uh_palmnav_available) // == PALM_NAV_FRM)
    FrmSetNavState(self->pt_frm, kFrmNavStateFlagsObjectFocusMode);

  // Si on est en mode gaucher, il faut inverser la note avec la barre
  // de scroll (quand on vient du -open)
  if ([oMaTirelire getPrefs]->ul_left_handed)
    [self swapLeft:OpDesc rightOnes:OpScrollbar, 0];

  // Les deux gadgets suivants servent à désigner les bitmaps qui les
  // précèdent comme faisant partie du même onglet...
  FrmSetGadgetData(self->pt_frm,
		   FrmGetObjectIndex(self->pt_frm, OpValueDateUpBmp),
		   TAB_GADGET_MAGIC);
  FrmSetGadgetData(self->pt_frm,
		   FrmGetObjectIndex(self->pt_frm, OpValueDateDownBmp),
		   TAB_GADGET_MAGIC);

  // Dans l'onglet de ventilation
  LstSetDrawFunction([self objectPtrId:OpSplitList], __splits_list_draw);
  LstSetSelection([self objectPtrId:OpSplitSortByChoices],
		  ps_db_prefs->ul_splits_sort);
}


- (Boolean)open
{
  UInt16 uh_focus;

  // Inits de base
  [self beforeOpen];

  MemMove(&self->s_trans, [self editedTrans], sizeof(self->s_trans));

  // On veut une copie de l'enregistrement courant
  if (self->s_trans.uh_copy)
  {
    UInt16 uh_copy_id = self->s_trans.h_edited_rec;

    self->s_trans.h_edited_rec = -1; // Car il s'agit d'un nouvel
				     // enregistrement...

    [self copyId:uh_copy_id sameDate:self->s_trans.uh_copy_date];

    // Focus sur la somme...
    uh_focus = OpAmount;
  }
  // Chargement de l'opération courante OU nouvelle opération
  else
    uh_focus = [self loadRecord];

  // Focus on statement number field
  if (self->s_trans.uh_focus_stmt)
  {
    FieldType *pt_field = [self objectPtrId:OpStatementNum];

    // Sélectionne le champ numéro de relevé
    FldSetSelection(pt_field, 0, FldGetTextLength(pt_field));

    self->s_trans.uh_focus_stmt = 0;
    uh_focus = OpStatementNum;
  }

  if (self->s_trans.h_split >= 0)
    // Il faut basculer sur l'onglet de la ventilation
    self->uh_tabs_current = 3;

  [super open];

  // On place le focus...
  [self focusObject:uh_focus];

  // Il faut directement aller sur une sous-opération...
  if (self->s_trans.h_split >= 0)
  {
    self->h_split_index = self->s_trans.h_split;
    self->s_trans.h_split = -1;

    FrmPopupForm(EditSplitFormIdx);
  }
  else
  {
    // Un caractère a été tapé dans l'écran précédent, on le réémet
    // maintenant juste après avoir positionné le focus
    if (self->s_trans.uh_is_shortcut != '\0')
    {
      EventType s_event;

      MemSet(&s_event, sizeof(s_event), '\0');
      s_event.eType = keyDownEvent;
      s_event.data.keyDown.chr = self->s_trans.uh_param;

      EvtAddEventToQueue(&s_event);
    }
  }

  return true;
}


- (Boolean)goto:(struct frmGoto *)ps_goto
{
  FieldType *pt_field;

  // On annule l'indication de GotoEvent
  oMaTirelire->b_goto_event_pending = false;

  TransFormPopupFill(self->s_trans, 0, 0, 0, 0, 0, 0, 0, ps_goto->recordNum,
		     -1);	// On ne s'occupe pas de l'idx de split ici...

  // Inits de base
  [self beforeOpen];

  [self loadRecord];

  // Dans un onglet
  self->uh_tabs_current = TAB_ID_TO_NUM(ps_goto->matchFieldNum);

  [super open];

  // Ça a été trouvé dans une sous-opération, on appelle le formulaire
  if (ps_goto->matchFieldNum == EditSplitAmount
      || ps_goto->matchFieldNum == EditSplitDesc)
  {
    EventType s_event;

    s_event.eType = frmLoadEvent;
    s_event.data.frmLoad.formID = EditSplitFormIdx;
    EvtAddEventToQueue(&s_event);

    s_event.eType = frmGotoEvent;
    MemMove(&s_event.data.frmGoto, ps_goto, sizeof(*ps_goto));
    s_event.data.frmGoto.formID = EditSplitFormIdx;
    EvtAddEventToQueue(&s_event);
  }
  // Si ça n'a pas été trouvé dans une sous-opération
  else
  {
    pt_field = [self objectPtrId:ps_goto->matchFieldNum];
    if (pt_field != NULL)
    {
      /* Si c'est la description on la scrolle */
      if (ps_goto->matchFieldNum == OpDesc)
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

	SclSetScrollBar([self objectPtrId:OpScrollbar],
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
  }

  return true;
}


//
// If uh_next == 0 then goto prev...
// Renvoie true s'il y a un suivant OU BIEN si erreur à la sauvegarde,
// puisqu'à ce stade on ne sais pas encore s'il y a un suivant ou non
// false, si pas de suivant (donc si nouvelle opération)
- (void)gotoNext:(UInt16)uh_next
{
  Transaction *oTransactions;
  UInt16 uh_prev_account, uh_next_account;
  Int16 h_next_index;

  // Si nouvelle opération, pas de suivant
  if (self->s_trans.h_edited_rec < 0)
    return;		 // Ici les boutons sont forcément déjà cachés

  // Si le bouton est grisé, on ne va pas plus loin
  if (self->rb_goto_buttons[uh_next] == false)
    return;

  // On sauve d'abord l'opération
  if ([self extractAndSave] == false)
    return;	      // On ne sait pas encore s'il y a suivant ou non

  uh_next = (uh_next != 0);
  h_next_index = [((SumListForm*)oFrm->oPrevForm)
		   ->oList
		   getTransaction:self->s_trans.h_edited_rec
		   next:uh_next
		   updateList:self->uh_really_saved];

  if (h_next_index < 0)
  {
    // Le bouton est actif alors qu'il n'y a pas de suivant ou de
    // précédent. Cela peut arriver lors d'un changement de compte et
    // qu'on arrive sur un compte ou il n'y a effectivement pas de
    // suivant ou de précédent.
    if (self->rb_goto_buttons[uh_next])
    {
      Char ra_button[] = { symbol7ScrollUpDisabled + uh_next, '\0' };
      UInt16 uh_button = OpPrev + uh_next;

      CtlSetEnabled([self objectPtrId:uh_button], false);
      [self fillLabel:uh_button withSTR:ra_button];

      self->rb_goto_buttons[uh_next] = false;
    }

    // On en profite pour vérifier l'autre bouton en demandant à la liste
    [self resetButtonNext:!uh_next];

    return;
  }

  oTransactions = [oMaTirelire transaction];

  // On détruit les liste des descriptions, modes et types car ils
  // peuvent dépendre du nom du compte et celui-ci peut changer d'une
  // opération à l'autre dans les écrans des stats par exemple
  [[oMaTirelire desc] popupListFree:self->pv_popup_desc];
  self->pv_popup_desc = NULL;

  [[oMaTirelire mode] popupListFree:self->pv_popup_modes];
  self->pv_popup_modes = NULL;

  [[oMaTirelire type] popupListFree:self->pv_popup_types];
  self->pv_popup_types = NULL;

  // Au cas où, on supprime également la liste des comptes de xfer
  [oTransactions popupListFree:self->pv_popup_xfer_accounts];
  self->pv_popup_xfer_accounts = NULL;

  // Comptes de la précédente opération et de la suivante
  DmRecordInfo(oTransactions->db, self->s_trans.h_edited_rec, &uh_prev_account,
	       NULL, NULL);
  uh_prev_account &= dmRecAttrCategoryMask;

  DmRecordInfo(oTransactions->db, h_next_index, &uh_next_account, NULL, NULL);
  uh_next_account &= dmRecAttrCategoryMask;

  // Changement de compte
  if (uh_prev_account != uh_next_account)
  {
    // Si on vient de la liste des opérations
    if ([(Object*)self->oPrevForm->oIsa isKindOf:TransListForm])
    {
      oTransactions->ps_prefs->ul_cur_category = uh_next_account;
      self->ui_update_mati_list |= (frmMaTiUpdateList | frmMaTiChangeAccount);
    }

    // No more last statement number just after account change
    gui_last_stmt_num = 0;
  }

  self->s_trans.h_edited_rec = h_next_index;
  [self loadRecord];

  // Si on est sur un onglet différent du premier
  if (self->uh_tabs_current != 1)
  {
    [self tabsHide:0];		// Cache l'onglet courant...
    [self tabsDraw:TAB_NUM_TO_ID(self->uh_tabs_current) drawLines:false];
    [self tabsShow:TAB_NUM_TO_ID(self->uh_tabs_current)];
  }

  // Dessin du formulaire
  [self redrawForm];
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  if ([super ctlSelect:ps_select])
    return true;

  switch (ps_select->controlID)
  {
  case OpPrev:
  case OpNext:
    [self gotoNext:ps_select->controlID - OpPrev]; // 0=prev, other=next
    break;

    // Compte de l'opération
  case OpCategoryPopup:
  {
    Transaction *oTransactions = [oMaTirelire transaction];
    UInt16 uh_old_account, uh_account;

    // Compte actuellement sélectionné
    uh_old_account = self->uh_account;

    uh_account = [oTransactions popupList:self->pv_popup_accounts
				firstIsValid:false]; // Pas de 1ère entrée ici
    if (uh_account != noListSelection)
    {
      // Si le compte change il faut reconstruire les popups des
      // descriptions, modes et types en fonction du nouveau compte
      if (uh_account != self->uh_account)
      {
	Mode *oModes = [oMaTirelire mode];
	Char ra_account_name[dmCategoryLength];
	UInt16 uh_old_choice;

	self->uh_account = uh_account;

	// Si on vient de la liste des opérations
	if ([(Object*)self->oPrevForm->oIsa isKindOf:TransListForm])
	{
	  oTransactions->ps_prefs->ul_cur_category = uh_account;
	  self->ui_update_mati_list |= (frmMaTiUpdateList
					| frmMaTiChangeAccount);
	}

	// No more last statement number just after account change
	gui_last_stmt_num = 0;

	// Inutile de reconstruire la liste des descriptions, elle le
	// sera au déploiement du popup
	[[oMaTirelire desc] popupListFree:self->pv_popup_desc];
	self->pv_popup_desc = NULL;

	// Le compte actuel
	CategoryGetName(oTransactions->db, uh_account, ra_account_name);

	// Le mode de paiement...
	uh_old_choice = [oModes popupListGet:self->pv_popup_modes];
	[oModes popupListFree:self->pv_popup_modes];
	self->pv_popup_modes = [oModes popupListInit:OpModeList
				       form:self->pt_frm
				       Id:(uh_old_choice
					   | ITEM_ADD_UNKNOWN_LINE
					   | ITEM_ADD_EDIT_LINE)
				       forAccount:ra_account_name];

	// On signale le changement
	[self justChangedAccountFrom:uh_old_account to:uh_account];

	// Le type d'opération
	[self initTypesPopup:[[oMaTirelire type]
			       popupListGet:self->pv_popup_types]
	      forAccount:ra_account_name];
      }
    }
  }
  break;

    // Date de l'opération
  case OpDate:
  {
    DateType s_date = self->s_date;
    [self dateInc:OpDate date:&s_date pressedButton:OpDate format:0];
  }
  break;

    // Heure de l'opération
  case OpTime:
#define b_time_select3	[oMaTirelire getPrefs]->ul_time_select3
    if ([self timeSelect:OpTime time:&self->s_time dialog3:b_time_select3])
      [self timeSet:OpTime time:self->s_time
	    format:(TimeFormatType)PrefGetPreference(prefTimeFormat)];
#undef b_time_select3

    // Tout le temps un redraw total, car il arrive qu'après la boîte
    // de changement d'heure l'écran soit laissé vide
    [self redrawForm];
    break;

    // Popup des descriptions
  case OpDescPopup:
  {
    Desc *oDesc = [oMaTirelire desc];
    UInt16 uh_desc;

    // Liste pas encore construite
    if (self->pv_popup_desc == NULL)
    {
      struct s_desc_popup_infos s_infos;

      s_infos.uh_account = self->uh_account;
      s_infos.uh_flags = DESC_ADD_EDIT_LINE;
      s_infos.ra_shortcut[0] = '\0';

      self->pv_popup_desc = [oDesc popupListInit:OpDescList
				   form:self->pt_frm
				   infos:&s_infos];
    }

    uh_desc = [oDesc popupList:self->pv_popup_desc autoReturn:false];

    switch (uh_desc)
    {
    case noListSelection:
      break;

    case DESC_EDIT:
      FrmPopupForm(DescListFormIdx);
      break;

    default:
    {
      UInt16 uh_focus, uh_save_mode = self->uh_mode;

      self->uh_mode = -1;
      uh_focus = [self expandMacro:uh_desc with:oDesc];

      // La macro a demandé à changer le mode de paiement
      if (self->uh_mode != -1)
	[self expandMode:self->uh_mode with:[oMaTirelire mode]];
      else
	self->uh_mode = uh_save_mode;

      [self focusObject:uh_focus];
    }
    break;
    }
  }
  break;

    // Label "Débit :" / "Crédit :"
  case OpDebCredLabel:
    ps_select->pControl = [self objectPtrId:OpDebCredSign];

    // On continue sur le signe du montant...

    // Signe du montant
  case OpDebCredSign:
    [self setCredit:(CtlGetLabel(ps_select->pControl))[0] == '-'];

    [self initTypesPopup:[[oMaTirelire type]
			   popupListGet:self->pv_popup_types]
	  forAccount:NULL];
    break;

  // Devise de l'opération
  case OpDevise:
    if (self->uh_frozen_currency == 0)
    {
      Currency *oCurrencies = [oMaTirelire currency];
      UInt16 uh_old_currency, uh_currency;

      uh_old_currency = [oCurrencies popupListGet:self->pv_popup_currencies];

      uh_currency = [oCurrencies popupList:self->pv_popup_currencies];

      switch (uh_currency)
      {
      case noListSelection:
	break;

      case ITEM_EDIT:
	// On lance la boîte d'édition des devises...
	FrmPopupForm(CurrenciesListFormIdx);
	break;

      default:
	[self justChangedCurrencyFrom:uh_old_currency to:uh_currency];

	// On passe sur l'onglet "Devise"
	[self clicOnTab:OpTab4];
	break;
      }
    }
    break;

    // Sauvegarde de l'opération
  case OpOK:
    if ([self extractAndSave] == false)
      break;

    self->ui_update_mati_list &= frmMaTiUpdateTotalMask;
    // frmMaTiUpdateList | frmMaTiUpdateListTransactions déjà présents
    self->ui_update_mati_list |= ((UInt32)self->s_trans.h_edited_rec << 16);

    // Continue...

    // Abandon des changements
  case OpCancel:
    [self returnToLastForm];
    break;

    // Suppression de l'opération
  case OpDelete:
    // On demande confirmation
    if (FrmAlert(alertTransactionDelete) != 0)
    {
      // Suppression effective de l'opération avec gestion des alarmes
      [[oMaTirelire transaction] deleteId:((UInt32)self->s_trans.h_edited_rec
					   | TR_DEL_XFER_LINK_TOO
					   | TR_DEL_MANAGE_ALARM)];

      // Pas (ou plus) d'index d'enregistrement
      self->ui_update_mati_list &= frmMaTiUpdateTotalMask;
      self->ui_update_mati_list |= (frmMaTiUpdateList
				    | frmMaTiUpdateListTransactions);

      [self returnToLastForm];
    }
    break;

    /////////////////////////////////////////////////////////////////
    // Onglet Essentiel

    // Mode de paiement
  case OpModePopup:
  {
    Mode *oModes = [oMaTirelire mode];
    UInt16 uh_mode = [oModes popupList:self->pv_popup_modes];

    switch (uh_mode)
    {
    case noListSelection:
      break;

    case ITEM_EDIT:
      // On lance la boîte d'édition des modes...
      FrmPopupForm(ModesListFormIdx);
      break;

    default:
      [self expandMode:uh_mode with:oModes];
      break;
    }
  }
  break;

    // Chèque auto
  case OpCheckNumAuto:
    if ([self checkNumAuto])
    {
      Mode *oModes = [oMaTirelire mode];
      Int16 h_mode;

      // On recherche s'il y a un mode à sélectionner automatiquement
      h_mode = [oModes popupListGetAutoChequeMode:self->pv_popup_modes];
      if (h_mode >= 0)
	[oModes popupList:self->pv_popup_modes setSelection:h_mode];
    }
    break;

    // Date de valeur
  case OpValueDate:
    [self dateInc:OpValueDate date:&self->s_value_date
	  pressedButton:OpValueDate format:0];
    break;

    // Type d'opération
  case OpTypePopup:
  {
    UInt16 uh_type = [[oMaTirelire type] popupList:self->pv_popup_types];

    if (uh_type != noListSelection && (uh_type & ITEM_EDIT))
    {
      // Car TypesListForm appelle la méthode -getInfos
      self->ui_infos = TYPE_LIST_DEFAULT_ID | (uh_type & ~ITEM_EDIT);

      // On lance la boîte d'édition des types...
      FrmPopupForm(TypesListFormIdx);
    }
  }
  break;

  // Pointage
  case OpChecked:
  {
    Transaction *oTransactions = [oMaTirelire transaction];
    struct s_account_prop *ps_prop;
    UInt16 uh_account;
    Boolean b_stmt_num;

    // Compte de l'opération
    uh_account = [oTransactions popupListGet:self->pv_popup_accounts];

    // Statement num management ?
    ps_prop = [oTransactions accountProperties:uh_account index:NULL];
    b_stmt_num = ps_prop->ui_acc_stmt_num;
    MemPtrUnlock(ps_prop);

    // Yes, we have to manage the statement number
    if (b_stmt_num)
    {
      UInt32 ui_cur_stmt_num, ui_stmt_num = 0;
      Coord uh_x, uh_y;
      Boolean b_old_cleared_state;

      // Le bouton est déjà dans le nouvel état
      b_old_cleared_state = CtlGetValue(ps_select->pControl) == 0;

      // Le numéro de relevé actuel
      [self checkField:OpStatementNum flags:FLD_CHECK_NOALERT|FLD_TYPE_DWORD
	    resultIn:&ui_cur_stmt_num fieldName:FLD_NO_NAME];

      // Cleared checkbox position
      FrmGetObjectPosition(self->pt_frm,
			   FrmGetObjectIndex(self->pt_frm, OpChecked),
			   &uh_x, &uh_y);

      // Cleared transaction
      if (b_old_cleared_state)
      {
	// A statement number is present
	if (ui_cur_stmt_num != 0)
	{
	  // ( Keep, Cancel ) noListSelection==DoNothing
	  ui_stmt_num = [self statementNumberPopup:
				STMT_NUM_POPUP_TYPE_KEEP_CANCEL
			      list:OpNumList posx:uh_x posy:uh_y
			      currentNum:ui_cur_stmt_num];
	}
      }
      // Non-cleared transaction
      else
      {
	// A statement number is present
	if (ui_cur_stmt_num != 0)
	{
	  // ( Keep, Another... ) noListSelection==DoNothing
	  ui_stmt_num =
	    [self statementNumberPopup:STMT_NUM_POPUP_TYPE_KEEP_ANOTHER
		  list:OpNumList posx:uh_x posy:uh_y
		  currentNum:ui_cur_stmt_num];

	  if (ui_stmt_num == STMT_NUM_POPUP_ANOTHER)
	  {
	    FieldType *pt_field = [self objectPtrId:OpStatementNum];

	    // Sélectionne le champ numéro de relevé
	    FldSetSelection(pt_field, 0, FldGetTextLength(pt_field));

	    goto another_stmt_num;
	  }
	}
	// No statement number
	else
	{
	  // ( (last num, )? (current#, next#, )? Another... )
	  // noListSelection==DoNothing
	  ui_stmt_num = [self statementNumberPopup:
				STMT_NUM_POPUP_TYPE_LIST_ANOTHER
			      list:OpNumList posx:uh_x posy:uh_y currentNum:0];

	  if (ui_stmt_num == STMT_NUM_POPUP_ANOTHER)
	  {
	another_stmt_num:
	    // Le no ne change pas tout de suite
	    ui_stmt_num = STMT_NUM_POPUP_KEEP;

	    [self focusObject:OpStatementNum];
	  }
	}
      } // Non-cleared transaction

      // Clic à l'extérieur de la liste => on ne fait rien (on inverse
      // ce qui vient d'être fait automatiquement)
      if (ui_stmt_num == STMT_NUM_POPUP_DO_NOTHING)
	CtlSetValue(ps_select->pControl, b_old_cleared_state);
      // Update the statement number field
      else if (ui_stmt_num != STMT_NUM_POPUP_KEEP)
      {
	if (ui_stmt_num == STMT_NUM_POPUP_CANCEL)
	  ui_stmt_num = 0;

	[self replaceField:REPLACE_FIELD_EXT | OpStatementNum
	      withSTR:(Char*)ui_stmt_num
	      len:REPL_FIELD_DWORD | REPL_FIELD_EMPTY_IF_NULL];
      }
    } // Statement number management
  }
  return false;			// On laisse l'OS gérer le flag

    // Compte de transfert
  case OpXferPopup:
  {
    Transaction *oTransactions = [oMaTirelire transaction];

    // Il faut afficher l'enregistrement lié
    if (self->uh_op_flags & OP_FORM_XFER)
    {
      // L'enregistrement n'existe plus
      if (self->uh_op_flags & OP_FORM_XFER_CAT)
	FrmAlert(alertOpFormXferNoRec);
      else
      {
	UInt16 uh_link_index;

	if (DmFindRecordByID(oTransactions->db,
			     self->ul_xfer_id, &uh_link_index) == 0
	    && DmQueryRecord(oTransactions->db, uh_link_index) != NULL)
	{
	  UInt16 uh_category;

	  if ([self extractAndSave] == false)
	    break;

	  // On recherche à nouveau l'opération au cas où la
	  // sauvegarde précédente aurait changé sa position
	  DmFindRecordByID(oTransactions->db,
			   self->ul_xfer_id, &uh_link_index);

	  // La liste des comptes de transfert n'existe pas ici

	  // On détruit les liste des descriptions, modes et types car
	  // ils peuvent dépendre du nom du compte
	  [[oMaTirelire desc] popupListFree:self->pv_popup_desc];
	  self->pv_popup_desc = NULL;

	  [[oMaTirelire mode] popupListFree:self->pv_popup_modes];
	  self->pv_popup_modes = NULL;

	  [[oMaTirelire type] popupListFree:self->pv_popup_types];
	  self->pv_popup_types = NULL;

	  // Si on vient de la liste des opérations
	  if ([(Object*)self->oPrevForm->oIsa isKindOf:TransListForm])
	  {
	    // Changement de catégorie
	    DmRecordInfo(oTransactions->db, uh_link_index, &uh_category,
			 NULL, NULL);
	    uh_category &= dmRecAttrCategoryMask;

	    oTransactions->ps_prefs->ul_cur_category = uh_category;
	    self->ui_update_mati_list |= (frmMaTiUpdateList
					  | frmMaTiChangeAccount);
	  }

	  // No more last statement number as account changed
	  gui_last_stmt_num = 0;

	  self->s_trans.h_edited_rec = uh_link_index;
	  [self loadRecord];

	  // Dessin du formulaire
	  [self redrawForm];
	}
      }
    }
    else
    {
      UInt16 uh_old_account, uh_new_account;

      uh_old_account
	= [oTransactions popupListGet:self->pv_popup_xfer_accounts];

      // La 1ère entrée est "Sans" donc firstIsValid:true
      uh_new_account = [oTransactions popupList:self->pv_popup_xfer_accounts
				      firstIsValid:true];
      if (uh_new_account != noListSelection
	  && uh_new_account != uh_old_account)
      {
	//
	// On signale le changement
	[self justChangedXferAccountFrom:uh_old_account to:uh_new_account];

	//
	// Il faut reconstruire les types
	[self initTypesPopup:[[oMaTirelire type]
			       popupListGet:self->pv_popup_types]
	      forAccount:NULL];
      }
    }
  }
  break;

    // Suppression du lien de transfert
  case OpXferDel:
    if (FrmAlert(alertOpFormXferDel) > 0)
    {
      Transaction *oTransactions;

      if ([self extractAndSave] == false)
	break;

      oTransactions = [oMaTirelire transaction];

      // On ôte l'info de transfert sur l'enregistrement lié s'il
      // existe encore !!!
      if ((self->uh_op_flags & OP_FORM_XFER_CAT) == 0)
      {
	UInt16 uh_index;

	if (DmFindRecordByID(oTransactions->db,
			     self->ul_xfer_id, &uh_index) == 0)
	  [oTransactions deleteXferOption:uh_index];
      }

      // On ôte l'info de transfert sur l'enregistrement courant
      [oTransactions deleteXferOption:self->s_trans.h_edited_rec];

      // On recharge l'opération
      [self loadRecord];

      // On redessine le formulaire
      [self redrawForm];
    }
    break;

    /////////////////////////////////////////////////////////////////
    // Onglet Répétition

    // Fréquence de répétition
  case OpRepeatPopup:
  {
    ListType *pt_list;
    UInt16 uh_old_repeat, uh_new_repeat;

    pt_list = [self objectPtrId:OpRepeatList];

    uh_old_repeat = LstGetSelection(pt_list);

    uh_new_repeat = LstPopupList(pt_list);
    if (uh_new_repeat != noListSelection && uh_new_repeat != uh_old_repeat)
    {
      // Maintenant il n'y a PLUS de répétition
      if (uh_new_repeat == 0)
	// Cache la ligne "Fin :" ... dont ^v et les occurrences
	[self tabsHideSpecialTab:2];
      // On a une répétition
      else
      {
	// Avant il n'y avait PAS de répétition
	if (uh_old_repeat == 0)
	{
	  // Pas encore de date de fin
	  DateToInt(self->s_repeat_end_date) = 0;
	  [self fillLabel:OpRepeatEndDate
		withSTR:LstGetSelectionText([self objectPtrId:OpRepeatChoices],
					    1)];

	  // Fait apparaître la ligne "Fin :" ... sans ^v
	  [self repeatShow:true];
	}

	// Il faut calculer le nouveau nombre d'occurrences
	[self repeatUpdateOccurrences];
      }

      // On change le label du popup
      CtlSetLabel(ps_select->pControl,
		  LstGetSelectionText(pt_list, uh_new_repeat));
    }
  }
  break;

    // Date de fin de répétition
  case OpRepeatEndDate:
  {
    ListType *pt_list = [self objectPtrId:OpRepeatChoices];
    DateType s_date = self->s_repeat_end_date;
    Boolean b_no_date_before = DateToInt(s_date) == 0;

    // S'il n'y avait pas de date sélectionnée, on pré-sélectionne
    // "Sans fin" sinon "Choisir une date..."
    LstSetSelection(pt_list, b_no_date_before);

    switch (LstPopupList(pt_list))
    {
      // Choix date
    case 0:
      if (b_no_date_before)
	s_date = self->s_date;

      [self dateInc:OpRepeatEndDate date:&s_date
	    pressedButton:OpRepeatEndDate format:0];

      // Il n'y avait pas de date avant ET il y en a maintenant
      if (b_no_date_before && DateToInt(s_date) != 0)
	[self repeatShow:true];
      break;

    // Sans fin
    case 1:
      if (b_no_date_before == false)
      {
	DateToInt(self->s_repeat_end_date) = 0;
	[self fillLabel:OpRepeatEndDate
	      withSTR:LstGetSelectionText(pt_list, 1)];

	// Flèches d'{in,dé}crément de date + date
	// Nombre d'occurrences
	[self repeatNoDate];

	// On n'efface pas le contenu du champ OpRepeatTimes, comme ça
	// si on clique sur "Fonction des occurrences" on pourra
	// revenir dans l'état précédent...
      }
      break;

      // Fonction des occurrences
    case 2:
      [self repeatUpdateEndDate];
      break;
    }
  }
  break;

  case OpRepeatTimesLabel:
    [self repeatUpdateEndDate];
    break;

    /////////////////////////////////////////////////////////////////
    // Onglet Ventilation

  case OpSplitCreate:
    if (self->oSplits == nil || [self->oSplits size] < 0xff)
    {
      self->h_split_index = -1;
      FrmPopupForm(EditSplitFormIdx);
    }
    break;

  case OpSplitEdit:
    self->h_split_index = LstGetSelection([self objectPtrId:OpSplitList]) - 1;
    FrmPopupForm(EditSplitFormIdx);
    break;

  case OpSplitLabel:
    [oMaTirelire transaction]->ps_prefs->ul_splits_label ^= 1;

    // On repositionne les boutons
    [self reposSplitsButtons];

    // Il faut redessiner la liste
    [self redrawSplits];
    break;

  case OpSplitSort:
  {
    ListType *pt_list = [self objectPtrId:OpSplitSortByChoices];
    struct s_db_prefs *ps_db_prefs = [oMaTirelire transaction]->ps_prefs;
    UInt16 index;

    index = LstPopupList(pt_list);
    if (index != noListSelection && index != ps_db_prefs->ul_splits_sort)
    {
      ps_db_prefs->ul_splits_sort = index;

      // On repositionne les boutons
      [self reposSplitsButtons];

      // On trie
      [self sortSplitsResel:true];

      // Il faut redessiner la liste
      [self redrawSplits];
    }
  }
  break;

    /////////////////////////////////////////////////////////////////
    // Onglet Devise

    // Rafraichissement du taux de change
  case OpCurrency1Rate:
  case OpCurrency2Rate:
  {
    Boolean b_notnull_amount, b_notnull_curr;
    t_amount l_dummy;

    [self fillCurrencyTab:false];

    // Montant de l'opération dans la monnaie du compte
    b_notnull_amount = [self checkField:OpCurrencyAmount
			     flags:(FLD_CHECK_NOALERT|FLD_TYPE_FDWORD
				    |FLD_CHECK_VOID|FLD_CHECK_NULL)
			     resultIn:&l_dummy
			     fieldName:FLD_NO_NAME];

    // Montant de l'opération dans la devise
    b_notnull_curr = [self checkField:OpAmount
			   flags:(FLD_CHECK_NOALERT|FLD_TYPE_FDWORD
				  |FLD_CHECK_VOID|FLD_CHECK_NULL)
			   resultIn:&l_dummy
			   fieldName:FLD_NO_NAME];

    // Si un seul des deux montants est vide ou nul, on va recalculer
    // sa valeur en fonction du taux de la devise dans la base des
    // devises
    if (b_notnull_amount ^ b_notnull_curr)
    {
      UInt16 uh_from_field, uh_from_curr;
      UInt16 uh_to_field, uh_to_curr;
      UInt16 uh_account_curr, uh_currency;

      // La monnaie du compte
      uh_account_curr
	= [[oMaTirelire transaction] accountCurrency:self->uh_account];

      // La devise actuellement sélectionnée
      uh_currency = [[oMaTirelire currency]
		      popupListGet:self->pv_popup_currencies];

      // Le montant de l'opération dans la devise est vide ou nul
      if (b_notnull_amount)
      {
	uh_from_field = OpCurrencyAmount;
	uh_from_curr = uh_account_curr;

	uh_to_field = OpAmount;
	uh_to_curr = uh_currency;
      }
      // Le montant de l'opération dans la monnaie du compte est vide ou nul
      else
      {
	uh_from_field = OpAmount;
	uh_from_curr = uh_currency;

	uh_to_field = OpCurrencyAmount;
	uh_to_curr = uh_account_curr;
      }

      [self convertField:uh_from_field fromCurrency:uh_from_curr
	    toField:uh_to_field toCurrency:uh_to_curr];

      // Ici pas besoin de mettre à jour la différence dans l'onglet
      // de "Ventilation" puisqu'on est forcément dans l'onglet
      // "Devise"
    }

    [self computeCurrencyRate];
  }
  break;

  default:
    return false;
  }

  return true;
}


- (Boolean)lstSelect:(struct lstSelect *)ps_list_select
{
  if (ps_list_select->listID == OpSplitList)
  {
    if (ps_list_select->selection == 0)
      [self hideId:OpSplitEdit];
    else
      [self showId:OpSplitEdit];
  }

  return false;
}


- (Boolean)sclRepeat:(struct sclRepeat *)ps_repeat
{
  [self fieldScrollBar:OpScrollbar
	linesToScroll:ps_repeat->newValue - ps_repeat->value update:false];

  return false;
}


- (Boolean)fldChanged:(struct fldChanged *)ps_fld_changed
{
  if (ps_fld_changed->fieldID == OpDesc)
  {
    [self fieldUpdateScrollBar:OpScrollbar fieldPtr:ps_fld_changed->pField
          setScroll:false];
    return true;
  }

  return false;
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  UInt16 uh_tmp;

  switch (UPD_CODE(ps_update->updateCode))
  {
    Char ra_account_name[dmCategoryLength];

  case frmMaTiUpdateList:
    // La liste des descriptions a changé
    if (ps_update->updateCode & frmMaTiUpdateListDesc)
    {
      // Inutile de reconstruire la liste des descriptions, elle le
      // sera au déploiement du popup
      [[oMaTirelire desc] popupListFree:self->pv_popup_desc];
      self->pv_popup_desc = NULL;
    }

    // La liste des devises a changé
    if (ps_update->updateCode & frmMaTiUpdateListCurrencies)
    {
      Currency *oCurrencies = [oMaTirelire currency];

      uh_tmp = [oCurrencies popupListGet:self->pv_popup_currencies];
      [oCurrencies popupListFree:self->pv_popup_currencies];
      self->pv_popup_currencies = [oCurrencies
				    popupListInit:OpDeviseList
				    form:self->pt_frm
				    Id:uh_tmp | ITEM_ADD_EDIT_LINE
				    forAccount:(Char*)-1];
    }

    if (ps_update->updateCode &(frmMaTiUpdateListModes|frmMaTiUpdateListTypes))
      CategoryGetName([oMaTirelire transaction]->db,
		      self->uh_account, ra_account_name);

    // La liste des modes a changé
    if (ps_update->updateCode & frmMaTiUpdateListModes)
    {
      Mode *oModes = [oMaTirelire mode];

      uh_tmp = [oModes popupListGet:self->pv_popup_modes];
      [oModes popupListFree:self->pv_popup_modes];
      self->pv_popup_modes = [oModes popupListInit:OpModeList
				     form:self->pt_frm
				     Id:(uh_tmp
					 | ITEM_ADD_UNKNOWN_LINE
					 | ITEM_ADD_EDIT_LINE)
				     forAccount:ra_account_name];
    }

    // La liste des types a changé
    if (ps_update->updateCode & frmMaTiUpdateListTypes)
    {
      Type *oTypes = [oMaTirelire type];

      [self initTypesPopup:[oTypes popupListGet:self->pv_popup_types]
	    forAccount:ra_account_name];

      // Si il y a une ventilation, il faut parcourir les
      // sous-opérations pour vérifier que chaque type existe toujours
      if (self->oSplits != nil)
      {
	MemHandle pv_split;
	struct s_db_prefs *ps_db_prefs;
	struct s_rec_one_sub_transaction *ps_split;
	UInt16 index, *puh_types;
	Boolean b_change = false;

	puh_types = [oTypes cacheLock];

	index = [self->oSplits size];
	while (index-- > 0)
	{
	  pv_split = [self->oSplits fetch:index];
	  ps_split = MemHandleLock(pv_split);

	  if (ps_split->ui_type != TYPE_UNFILED
	      && puh_types[ps_split->ui_type] == ITEM_FREE_ID)
	  {
	    ps_split->ui_type = TYPE_UNFILED;
	    b_change = true;
	  }

	  MemHandleUnlock(pv_split);
	}

	[oTypes cacheUnlock];

	ps_db_prefs = [oMaTirelire transaction]->ps_prefs;

	// Il n'y aura changement que si le label est le type
	b_change &= ps_db_prefs->ul_splits_label;

	// Si les sous-opérations sont triées par type, il faut les retrier
	if (ps_db_prefs->ul_splits_sort == SPLIT_SORT_TYPE)
	{
	  [self sortSplitsResel:true];
	  b_change = true;
	}

	// Il faut redessiner la liste
	if (b_change && self->uh_tabs_current == 3)
	  [self redrawSplits];
      }
    }
    break;

  case frmMaTiUpdateTransForm:
    // Il faut recalculer la date de fin de répétition
    if (ps_update->updateCode & frmMaTiUpdateTransFormRepeat)
      [self repeatUpdateEndDate];

    // Il faut refabriquer la liste de la ventilation
    if (ps_update->updateCode & frmMaTiUpdateTransFormSplits)
    {
      ListType *pt_list;
      UInt16 uh_size = self->oSplits != nil ? [self->oSplits size] : 0;

      pt_list = [self objectPtrId:OpSplitList];
      LstSetListChoices(pt_list, (Char**)self, uh_size + 1);

      // Normalement, ici on est forcément sur l'onglet "Ventilation"
      if (self->uh_tabs_current == 3)
      {
	UInt16 uh_show = uh_size != 0;
	UInt16 ruh_objs[] = { splitTabContents(uh_show) };

	[self showHideIds:ruh_objs];
      }

      if (uh_size > 0)
      {
	LstSetSelection(pt_list, self->h_split_index + 1);
	[self sortSplitsResel:true];

	[self reposSplitsButtons];
      }
      else
	LstSetSelection(pt_list, noListSelection); // OK

      // Il faut recalculer la somme des sous-opérations
      [self computeSplitsSum];

      // La liste va normalement être redessinée avec le redessin du
      // formulaire
      // XXX À VOIR XXX
    }

    // La somme restante vient de changer
    if (ps_update->updateCode & frmMaTiUpdateTransFormSplitsDiff)
      [self redrawSplits];

    break;
  }

  return [super callerUpdate:ps_update];
}


- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key
{
  UInt16 fld_id;

  // On laisse la main à Papa pour gérer les déplacements entre champs
  // et les touches spéciales...
  if ([super keyDown:ps_key])
    return true;

  // Special key
  if (ps_key->modifiers & virtualKeyMask)
  {
    switch (ps_key->chr)
    {
    case vchrNavChange:		// OK (only 5-way T|T)
      if (ps_key->modifiers & autoRepeatKeyMask)
	return false;

      if ((ps_key->keyCode & (navBitsAll | navChangeBitsAll))
	  == navChangeSelect)
      {
	CtlHitControl([self objectPtrId:OpOK]);
	return true;
      }
      break;

    case pageUpChr:
    case pageDownChr:
      if (oMaTirelire->uh_palmnav_available == PALM_NAV_NONE)
      {
	[self gotoNext:ps_key->chr - pageUpChr]; // 0=prev, other=next
	return true;
      }
      break;
    }

    return false;		// Ça sert à rien d'aller plus loin...
  }

  fld_id = FrmGetFocus(self->pt_frm);

  if (fld_id != noFocus)
  {
    UInt16 uh_id = FrmGetObjectId(self->pt_frm, fld_id);

    switch (uh_id)
    {
    case OpAmount:
    {
      Boolean b_credit = ps_key->chr == '+';
      if (b_credit || ps_key->chr == '-')
      {
	ControlType *ps_ctl = [self objectPtrId:OpDebCredSign];

	// On simule l'appui sur le signe s'il est différent
	if (CtlGetLabel(ps_ctl)[0] != ps_key->chr)
	  CtlHitControl(ps_ctl);

	return true;
      }

      if ([self keyFilter:KEY_FILTER_FLOAT | fld_id for:ps_key])
	return true;

      // Il faut mettre à jour l'onglet ventilation
      if (self->uh_tabs_current == 3)
	// Pour nous-mêmes
	[self sendCallerUpdate:(frmMaTiUpdateTransForm
				| frmMaTiUpdateTransFormSplitsDiff)];
      return false;

    case OpCurrencyAmount:
      return [self keyFilter:KEY_FILTER_FLOAT | fld_id for:ps_key];
    }

    case OpCheckNum:
    case OpStatementNum:
    case OpRepeatTimes:
      if ([self keyFilter:KEY_FILTER_INT | fld_id for:ps_key] == true)
	return true;

      if (uh_id == OpRepeatTimes)
	// Pour nous-mêmes
	[self sendCallerUpdate:(frmMaTiUpdateTransForm
				| frmMaTiUpdateTransFormRepeat)];

      break;
    }
  }

  return false;
}


//
// Un coller vient d'avoir lieu...
- (void)pasteInField:(UInt16)uh_fld_id
{
  switch (FrmGetObjectId(self->pt_frm, uh_fld_id))
  {
    // Dans le champ "Somme"
  case OpAmount:
    // AVEC l'onglet "Ventilation" actif
    if (self->uh_tabs_current == 3)
      // On met à jour la liste...
      [self redrawSplits];
    break;

    // Il faut recalculer la date de fin de répétition
  case OpRepeatTimes:
    [self repeatUpdateEndDate];
    break;
  }
}


- (Boolean)ctlRepeat:(struct ctlRepeat *)ps_repeat
{
  DateType s_date;

  // Le format est toujours à 0 car comme on a redéfini
  // -dateSet:date:format: il est mis à la bonne valeur labas
  switch (ps_repeat->controlID)
  {
  case OpDateUp:
  case OpDateDown:
    s_date = self->s_date;
    [self dateInc:OpDate date:&s_date
	  pressedButton:ps_repeat->controlID format:0];
    break;

  case OpValueDateUp:
  case OpValueDateDown:
    [self dateInc:OpValueDate date:&self->s_value_date
	  pressedButton:ps_repeat->controlID format:0];
    break;

  case OpRepeatEndDateUp:
  case OpRepeatEndDateDown:
    if (DateToInt(self->s_repeat_end_date) != 0)
    {
      s_date = self->s_repeat_end_date;
      [self dateInc:OpRepeatEndDate date:&s_date
	    pressedButton:ps_repeat->controlID format:0];
    }
    break;
  }

  // On retourne toujours false sinon la répétition s'arrête
  return false;
}


////////////////////////////////////////////////////////////////////////
//
// Gestion particulière des onglets
//
////////////////////////////////////////////////////////////////////////

- (void)repeatShow:(Boolean)b_repeat
{
  // Si l'opération est une répétition
  if (b_repeat)
  {
    // Label de fin de répétition
    [self showId:OpRepeatEndsAt];

    // S'il y a une date de fin de répétition
    if (DateToInt(self->s_repeat_end_date) != 0)
    {
      [self showIndex:FrmGetObjectIndex(self->pt_frm,
					OpRepeatEndDateUpBmp) - 1];
      [self showIndex:FrmGetObjectIndex(self->pt_frm,
					OpRepeatEndDateDownBmp) - 1];
      [self showId:OpRepeatEndDateUp];
      [self showId:OpRepeatEndDateDown];

      // Nombre d'occurrences
      [self showId:OpRepeatTimes];
      [self showId:OpRepeatTimesLabel];
    }

    // Label de fin (peut-être "Sans")
    [self showId:OpRepeatEndDate];
  }
}


- (void)repeatNoDate
{
  // Flèches d'{in,dé}crément de date + date
  [self hideIndex:
	  FrmGetObjectIndex(self->pt_frm, OpRepeatEndDateUpBmp) - 1];
  [self hideIndex:
	  FrmGetObjectIndex(self->pt_frm, OpRepeatEndDateDownBmp) - 1];
  [self hideId:OpRepeatEndDateUp];
  [self hideId:OpRepeatEndDateDown];

  // Nombre d'occurrences
  [self hideId:OpRepeatTimes];
  [self hideId:OpRepeatTimesLabel];
}


- (UInt16)repeatNumOccurences
{
  UInt16 uh_occur, uh_repeat;

  uh_repeat = LstGetSelection([self objectPtrId:OpRepeatList]);

  // La date de l'opération est supérieure à la date de fin
  if (DateToInt(self->s_date) > DateToInt(self->s_repeat_end_date))
  {
    // Normalement on a uniquement ce cas quand on n'a pas de date de fin
    if (DateToInt(self->s_repeat_end_date) == 0
	&& uh_repeat >= 1
	&& uh_repeat <= 10)
    {
      // Arbitrairement on renvoie -1, ça n'est utile que pour la
      // méthode -extractAndSave...
      return -1;
    }

    return 0;
  }

  switch (uh_repeat)
  {
    // Toutes les N semaines
  case 1:			// Toutes les semaines
  case 2:			// Toutes les 2 semaines
    uh_occur = (UInt16)((DateToDays(self->s_repeat_end_date)
			 - DateToDays(self->s_date))
			/ ((UInt32)uh_repeat * 7UL));
    break;

    // Tous les N mois
  case 3 ... 10:
  {
    UInt16 uh_diff_year, uh_diff_month, uh_month_div;

    uh_diff_year = self->s_repeat_end_date.year - self->s_date.year;

    if (uh_diff_year == 0)
      uh_diff_month = self->s_repeat_end_date.month - self->s_date.month;
    else
      uh_diff_month = (12 - self->s_date.month
		       + self->s_repeat_end_date.month
		       + 12 * (uh_diff_year - 1));

    uh_month_div = 1;

    // À la fin de chaque mois
    if (uh_repeat == 4)
    {
      if (uh_diff_month > 0 && (self->s_repeat_end_date.day
				< DaysInMonth(self->s_repeat_end_date.month,
					      self->s_repeat_end_date.year)))
	uh_diff_month--;
    }
    // Tous les N mois, le même jour
    else
    {
      if (uh_diff_month > 0
	  && self->s_repeat_end_date.day < self->s_date.day)
	uh_diff_month--;

      switch (uh_repeat)
      {
      case 5: uh_month_div = 2; break;
      case 6: uh_month_div = 3; break;
      case 7: uh_month_div = 4; break;
      case 8: uh_month_div = 6; break;
      case 9: uh_month_div = 12; break;
      case 10: uh_month_div = 24; break;
      }
    }

    uh_occur = uh_diff_month / uh_month_div;
  }
  break;

  default:
    return 0;
  }

  return uh_occur;
}


- (void)repeatUpdateOccurrences
{
  Char *pa_field;
  UInt16 uh_occur, uh_old_occur;

  uh_occur = [self repeatNumOccurences];

  // Sans fin, pas de nombre d'occurences à mettre à jour...
  if (uh_occur == -1)
    return;

  // Le nombre n'était pas présent
  if ([self checkField:OpRepeatTimes
	    flags:FLD_TYPE_WORD|FLD_CHECK_VOID|FLD_CHECK_NOALERT
	    resultIn:&uh_old_occur fieldName:FLD_NO_NAME] == false
      // OU BIEN il change
      || uh_old_occur != uh_occur
      // OU BIEN il commence par '0...' MAIS n'est pas juste "0"
      //         (ça arrive lorsque 0 est seul dans le champ, et qu'on
      //          saisit un nouveau chiffre)
      || ((pa_field = FldGetTextPtr([self objectPtrId:OpRepeatTimes]),
	   pa_field[0]) == '0'
	  && pa_field[1] != '\0'))
  {
    // On le met en place
    [self replaceField:REPLACE_FIELD_EXT | OpRepeatTimes
	  withSTR:(Char*)(UInt32)uh_occur len:REPL_FIELD_DWORD];
  }
}


- (void)repeatUpdateEndDate
{
  UInt16 uh_occur;

  // On calcule la date de fin en fonction des occurrences
  if ([self checkField:OpRepeatTimes flags:FLD_TYPE_WORD
	    resultIn:&uh_occur fieldName:FLD_NO_NAME])
  {
    UInt16 uh_repeat;

    uh_repeat = LstGetSelection([self objectPtrId:OpRepeatList]);

    self->s_repeat_end_date = self->s_date;

    switch (uh_repeat)
    {
      // Toutes les N semaines
    case 1:			// Toutes les semaines
    case 2:			// Toutes les 2 semaines
      DateAdjust(&self->s_repeat_end_date,
		 (UInt32)uh_occur * ((UInt32)uh_repeat * 7UL));
      break;

      // Tous les N mois
    case 3 ... 9:
    {
      UInt16 uh_diff_month, uh_month_div;

      uh_month_div = 1;

      switch (uh_repeat)
      {
      case 5: uh_month_div = 2; break;
      case 6: uh_month_div = 3; break;
      case 7: uh_month_div = 4; break;
      case 8: uh_month_div = 6; break;
      case 9: uh_month_div = 12; break;
      }

      // Nombre de mois à ajouter
      uh_diff_month = uh_occur * uh_month_div;

      self->s_repeat_end_date.year += uh_diff_month / 12;
      uh_diff_month %= 12;

      if (self->s_repeat_end_date.month + uh_diff_month > 12)
      {
	uh_diff_month -= 12 - self->s_repeat_end_date.month;
	self->s_repeat_end_date.year++;

	self->s_repeat_end_date.month = uh_diff_month;
      }
      else
	self->s_repeat_end_date.month += uh_diff_month;

      // À la fin de chaque mois
      if (uh_repeat == 4)
	self->s_repeat_end_date.day
	  = DaysInMonth(self->s_repeat_end_date.month,
			self->s_repeat_end_date.year);
    }
    break;
    }

    [self dateSet:OpRepeatEndDate date:self->s_repeat_end_date
	  format:0];

    // Il n'y avait pas de date avant ET il y en a maintenant
    if (FrmGlueGetObjectUsable(self->pt_frm,
			       FrmGetObjectIndex(self->pt_frm,
						 OpRepeatEndDateUp)) == false)
      [self repeatShow:true];
  }
}


- (void)tabsHideSpecialTab:(UInt16)uh_tab
{
  switch (uh_tab)
  {
    // Main
  case 1:
    // Le bouton de suppression de lien (et son bitmap)
    [self hideId:bmpTrash];
    [self hideId:OpXferDel];
    break;

    // Repeat
  case 2:
    // Label de fin de répétition
    [self hideId:OpRepeatEndsAt];

    // Flèches d'{in,dé}crément de date + date
    // Nombre d'occurrences
    [self repeatNoDate];

    [self hideId:OpRepeatEndDate];
    break;

    // Splits / Ventilation
  case 3:
  {
    UInt16 ruh_objs[] = { splitTabContents(0) };
    [self showHideIds:ruh_objs];
  }
  break;

    // Currency
  case 4:
  {
    UInt16 ruh_objs[] = { currencyTabContents(0, 0) };
    [self showHideIds:ruh_objs];
  }
  break;
  }
}


- (void)tabsHide:(UInt16)uh_cur_tab
{
  // On cache l'onglet courant
  if (uh_cur_tab == 0)
    [self tabsHideSpecialTab:self->uh_tabs_current];
  // On cache tout sauf l'onglet passé en paramètre
  else
  {
    UInt16 uh_tab, uh_not_tab;

    uh_not_tab = TAB_ID_TO_NUM(uh_cur_tab);

    for (uh_tab = self->uh_tabs_num; uh_tab > 0; uh_tab--)
      if (uh_tab != uh_not_tab)
	[self tabsHideSpecialTab:uh_tab];
  }

  return [super tabsHide:uh_cur_tab];
}



- (void)tabsShow:(UInt16)uh_cur_tab
{
  switch (uh_cur_tab)
  {
    // Main
  case baseTab1:
    // Si l'opération est un transfert
    if (self->h_xfer_account >= 0)
    {
      // Le bouton de suppression de lien (et son bitmap)
      [self showId:bmpTrash];
      [self showId:OpXferDel];
    }
    break;

    // Repeat
  case baseTab2:
    [self repeatShow:LstGetSelection([self objectPtrId:OpRepeatList]) > 0];
    break;

    // Splits / Ventilation
  case baseTab3:
    if (self->oSplits != nil)
    {
      UInt16 ruh_objs[] = { splitTabContents(1) };
      [self showHideIds:ruh_objs];
    }
    break;

    // Currency
  case baseTab4:
    // L'onglet de la devise est vide
    if (self->uh_empty_currency)
      [self showId:OpCurrencyNone];
    // Il y a une devise en cours
    else
    {
      UInt16 ruh_objs[] = { currencyTabContentsWithoutNone(1), 0 };
      [self showHideIds:ruh_objs];
    }
    break;
  }

  return [super tabsShow:uh_cur_tab];
}


// Permet à la méthode -checkField:... de basculer sur le bon onglet
// en cas d'erreur sur un champ éditable
- (UInt16)tabsGetTabForId:(UInt16)uh_obj
{
  if (uh_obj == OpCurrencyAmount)
    return TAB_NUM_TO_ID(4);

  return [super tabsGetTabForId:uh_obj];
}

@end
