/* -*- objc -*-
 * TransForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mon May 12 23:28:06 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb  1 18:32:41 2008
 * Update Count    : 39
 * Status          : Unknown, Use with caution!
 */

#ifndef	__TRANSFORM_H__
#define	__TRANSFORM_H__

#include "Array.h"
#include "MaTiForm.h"
#include "Transaction.h"
#include "Mode.h"
#include "Desc.h"

#ifndef EXTERN_TRANSFORM
# define EXTERN_TRANSFORM extern
#endif

#define TransFormPopupFill(args, type, is_pre_desc, is_shortcut, param, \
			   copy, copy_date, focus_stmt, edited_rec,	\
			   split_idx)					\
  args = (struct s_trans_form_args) { type, is_pre_desc, is_shortcut, param, \
				      copy, copy_date, focus_stmt, 0,	\
				      edited_rec, split_idx }

#define TransFormCall(args, type, is_pre_desc, param,	\
		      copy, copy_date, edited_rec)	\
  TransFormCallFull(args, type, is_pre_desc, 0, param,	\
		    copy, copy_date, 0, edited_rec, -1)

#define TransFormSplitCall(args, type, is_pre_desc, param,		\
		           copy, copy_date, edited_rec, split_idx)	\
  TransFormCallFull(args, type, is_pre_desc, 0, param,			\
		    copy, copy_date, 0, edited_rec, split_idx)

#define TransFormCallFull(args, type, is_pre_desc, is_shortcut, param,	\
			  copy, copy_date, focus_stmt, edited_rec,	\
			  split_idx)					\
  TransFormPopupFill(args, type, is_pre_desc, is_shortcut, param,	\
		     copy, copy_date, focus_stmt, edited_rec, split_idx); \
  FrmPopupForm(OpFormIdx)


struct s_trans_form_args
{
#define OP_DEBIT        0
#define OP_CREDIT       1
  UInt16 uh_op_type:1;		// Type d'opération en cours (débit/crédit)

  UInt16 uh_is_pre_desc:1;	// Description par raccourci
  UInt16 uh_is_shortcut:1;	// On est appelé par un raccourci
  UInt16 uh_param:8;	        // Index de la description par raccourci
				// OU BIEN code ASCII du caractère raccourci

  UInt16 uh_copy:1;		// On veut une copie de l'opération
  UInt16 uh_copy_date:1;	// On veut garder la même date si copie

  UInt16 uh_focus_stmt:1;	// On veut le focus sur le numéro de relevé

  UInt16 uh_reserved:2;		// Réservé pour de futurs usages

  Int16 h_edited_rec;		// Index de l'opération éditée (-1 == nouveau)
  Int16 h_split;		// Index de la sous-opération à charger
};

@interface TransForm : MaTiForm
{
  struct s_trans_form_args s_trans;

  // Les sous-opérations
  Array *oSplits;
  t_amount l_splits_sum;

  DateType s_date;
  TimeType s_time;
  DateType s_value_date;
  DateType s_repeat_end_date;

  UInt16 uh_account;		// Compte actuel de l'opération
  Int16  h_xfer_account;	// Compte de transfert (ou -1 si "Sans")
  UInt32 ul_xfer_id;		// ID de l'enr. lié OU de la catégorie

  UInt32 ui_orig_check_num;	// > 0 si édition d'une op. avec n° de chèque

  VoidHand pv_popup_types;
  VoidHand pv_popup_modes;
  VoidHand pv_popup_currencies;

  VoidHand pv_popup_desc;

  VoidHand pv_popup_accounts;
  VoidHand pv_popup_xfer_accounts;

  // À VOIR XXX
#define OP_FORM_XFER		0x0001
#define OP_FORM_XFER_CAT	0x0002
  UInt16 uh_op_flags;
  UInt16 uh_mode;
  UInt16 uh_type;
  UInt16 uh_currency;		// Sert uniquement à l'init du form

  // Différents cas en fonction des Compte/Xfer/Devise
  //				     Compte	Xfer	Devise
#define TRANSFORM_CASE_1	1 // A		Sans	A (onglet devise vide)
#define TRANSFORM_CASE_2	2 // A		Sans	X
#define TRANSFORM_CASE_3	3 // A		B	B
#define TRANSFORM_CASE_4	4 // A		B	D=A=B
  UInt16 uh_case:3;
  UInt16 uh_empty_currency:1;	// Onglet de la devise vide (même monnaie cpte)
  UInt16 uh_frozen_currency:1;	// La devise ne peut pas changer

  UInt16 uh_internal_flag:1;	// Il faut positionner ce flag à la sauvegarde

  UInt16 uh_really_saved:1;	// set by -extractAndSave

  Int16 h_split_index;		// Index de la sous-op éditée (-1 si nouv)

  Boolean rb_goto_buttons[2];	// État des boutons goto ^/v
}

- (struct s_trans_form_args*)editedTrans;

- (Boolean)extractAndSave;
- (UInt16)loadRecord;
- (void)copyId:(UInt16)uh_id sameDate:(Boolean)b_same;
- (void)gotoNext:(UInt16)uh_next;

- (void)beforeOpen;

- (void)initRepeat:(UInt16)uh_repeat;
- (UInt16)fillForm;
- (void)setCredit:(Boolean)b_credit;
- (void)resetButtonNext:(Boolean)b_next;
- (void)initFromTrans:(struct s_transaction*)ps_tr id:(UInt16)uh_id
	      options:(struct s_rec_options*)ps_options;

- (UInt16)expandMacro:(UInt16)uh_desc with:(Desc*)oDesc;
- (Boolean)expandDesc:(struct s_desc*)ps_desc inField:(UInt16)uh_id;
- (void)expandMode:(UInt16)uh_mode with:(Mode*)oModes;
- (void)setValueDate;
- (Boolean)checkNumAuto;

- (void)repeatShow:(Boolean)b_repeat;
- (void)repeatNoDate;
- (UInt16)repeatNumOccurences;
- (void)repeatUpdateOccurrences;
- (void)repeatUpdateEndDate;

- (void)tabsHideSpecialTab:(UInt16)uh_tab;

- (void)initAccountsList;
- (void)initXferAccountsListSelected:(Int16)h_selected_account;
- (Boolean)isXfer:(Int16*)ph_xfer_account;
- (void)initTypesPopup:(UInt16)uh_type forAccount:(Char*)pa_account;

- (void)emptyCurrencyTab;
- (void)fillCurrencyTab:(Boolean)b_show;

- (void)sortSplitsResel:(Boolean)b_resel;
- (void)reposSplitsButtons;
- (void)computeSplitsSum;
- (void)redrawSplits;

- (void)convertField:(UInt16)uh_from_field fromCurrency:(UInt16)uh_from_curr
	     toField:(UInt16)uh_to_field toCurrency:(UInt16)uh_to_curr;

#define CHG_CURRENCY_DONT_SET_POPUP	0x8000
#define CHG_CURRENCY_DONT_CHANGE	0x4000
#define CHG_CURRENCY_COMPUTE_RATE	0x2000
- (void)changeCurrencyTo:(UInt16)uh_new_curr;

- (void)freezeCurrency:(Boolean)b_freeze;
- (void)computeCurrencyRate;

- (UInt16)case;
- (void)justChangedAccountFrom:(UInt16)uh_old_acc to:(UInt16)uh_new_acc;
- (void)justChangedXferAccountFrom:(UInt16)uh_old_acc to:(UInt16)uh_new_acc;
- (void)justChangedCurrencyFrom:(UInt16)uh_old_curr to:(UInt16)uh_new_curr;

@end

#endif	/* __TRANSFORM_H__ */
