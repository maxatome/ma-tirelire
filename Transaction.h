/* -*- objc -*-
 * Transaction.h -- 
 * 
 * Author          : Maxime Soulé
 * Created On      : Mon May 31 21:57:36 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Wed Dec 12 10:28:23 2007
 * Update Count    : 48
 * Status          : Unknown, Use with caution!
 */

#ifndef	__TRANSACTION_H__
#define	__TRANSACTION_H__

#include "BaseForm.h"
#include "Type.h"
#include "Mode.h"
#include "Currency.h"

#include "structs.h"


#ifndef EXTERN_TRANSACTION
# define EXTERN_TRANSACTION extern
#endif


#define MAX_ACCOUNTS	dmRecNumCategories


#define COMMON_HEADER	\
  DateType	s_date;		/* Date */ \
  TimeType	s_time;		/* Heure */ \
  t_amount	l_amount	/* Somme en centimes */ \


union u_acc_flags
{
  struct
  {
    UInt32 ui_checked:1;        // Always 1, correspond to checked trans.
    UInt32 ui_marked:1;		// Enregistrement marqué
    UInt32 ui_warning:1;	// Warning if overdrawn account
    UInt32 ui_stmt_num:1;	// Gestion des numéros de relevé
    UInt32 ui_currency:8;	// Account currency
    UInt32 ui_cheques_by_cbook:6;// Number of cheques by chequebook
    UInt32 ui_take_last_date:1;	// When creating new record, take last date
    UInt32 ui_reserved:13;	// -31 Reserved... */
  } s_bit;

#define ACCOUNT_CHECKED		 0x80000000
#define ACCOUNT_MARKED		 0x40000000
#define ACCOUNT_WARNING		 0x20000000
#define ACCOUNT_STMT_NUM	 0x10000000
#define ACCOUNT_CURRENCY	 0x0ff00000
#define ACCOUNT_CHEQUES_BY_CBOOK 0x000fc000
#define ACCOUNT_TAKE_LAST_DATE	 0x00002000
#define ACCOUNT_RESERVED	 0x00001fff
  UInt32		ui_all;
};

//
// For each account, first record has this type
struct s_account_prop
{
  COMMON_HEADER;
  
  /* Flags */
  union u_acc_flags u_flags;

#define ui_acc_checked		u_flags.s_bit.ui_checked
#define ui_acc_marked		u_flags.s_bit.ui_marked
#define	ui_acc_warning		u_flags.s_bit.ui_warning
#define ui_acc_stmt_num		u_flags.s_bit.ui_stmt_num
#define ui_acc_currency		u_flags.s_bit.ui_currency
#define	ui_acc_cheques_by_cbook	u_flags.s_bit.ui_cheques_by_cbook
#define ui_acc_take_last_date	u_flags.s_bit.ui_take_last_date
#define	ui_acc_reserved		u_flags.s_bit.ui_reserved

#define ui_acc_flags		u_flags.ui_all

  t_amount l_overdraft_thresold;
  t_amount l_non_overdraft_thresold;

#define NUM_CHECK_BOOKS	4
  UInt32 rui_check_books[NUM_CHECK_BOOKS];

  Char	ra_number[24];

  Char 	ra_note[1];		// Pour le \0
};

// On passe par là car sizeof(struct s_account_prop) donne 62 au lieu
// de 61 à cause du ra_note[1] de fin
#define ACCOUNT_PROP_SIZE	(offsetof(struct s_account_prop, ra_note) + 1)


union u_rec_flags
{
  struct
  {
#ifdef __m68k__
    UInt32	ui_checked:1;	// 0	Opération effectuée
    UInt32	ui_marked:1;	// 1	Enregistrement marqué
    UInt32	ui_alarm:1;	// 2	Alarme positionnée...
    UInt32	ui_mode:5;	// 3-7	Mode de paiement (CB, chèque...)
    UInt32	ui_type:8;	// 8-15	Type d'opération (ski, EDF...)
    UInt32	ui_value_date:1;// 16	Date de valeur présente ou non
    UInt32	ui_check_num:1;	// 17	N° de chèque présent ou non
    UInt32	ui_repeat:1;	// 18	Opération avec répétition
    UInt32	ui_xfer:1;	// 19	Si cet enr. est un transfert
    UInt32	ui_xfer_cat:1;	// 20	Contient la cat et pas le uniqueID
    UInt32	ui_stmt_num:1;	// 21	Numéro de relevé ou non
    UInt32	ui_currency:1;	// 22	Une devise est présente
    UInt32	ui_splits:1;	// 23	Ventilation présente ou non
    UInt32	ui_reserved:7;	// 24-30 Réservé... */
    UInt32	ui_internal_flag:1; // 31 usage interne uniquement
#else
# error "Little endian not yet supported"
#endif
  } s_bit;

#ifdef __m68k__
# define RECORD_CHECKED		0x80000000
# define RECORD_MARKED		0x40000000
# define RECORD_ALARM		0x20000000
# define RECORD_MODE_MASK	0x1f000000
# define RECORD_MODE_SHIFT	24
# define RECORD_TYPE_MASK	0x00ff0000
# define RECORD_TYPE_SHIFT	16
# define RECORD_VALUE_DATE	0x00008000
# define RECORD_CHECK_NUM	0x00004000
# define RECORD_REPEAT		0x00002000
# define RECORD_XFER		0x00001000
# define RECORD_XFER_CAT	0x00000800
# define RECORD_STMT_NUM	0x00000400
# define RECORD_CURRENCY	0x00000200
# define RECORD_SPLITS		0x00000100
# define RECORD_RESERVED	0x000000fe
# define RECORD_INTERNAL_FLAG	0x00000001
#else
# error "Little endian not yet supported"
#endif
  UInt32	ui_all;
};

//
// For each transaction
struct s_transaction
{
  COMMON_HEADER;

  /* Flags */
  union u_rec_flags u_flags;

#define ui_rec_checked		u_flags.s_bit.ui_checked
#define ui_rec_marked		u_flags.s_bit.ui_marked
#define ui_rec_alarm		u_flags.s_bit.ui_alarm
#define ui_rec_mode		u_flags.s_bit.ui_mode
#define ui_rec_type		u_flags.s_bit.ui_type
#define ui_rec_value_date	u_flags.s_bit.ui_value_date
#define ui_rec_check_num	u_flags.s_bit.ui_check_num
#define ui_rec_repeat		u_flags.s_bit.ui_repeat
#define ui_rec_xfer		u_flags.s_bit.ui_xfer
#define ui_rec_xfer_cat		u_flags.s_bit.ui_xfer_cat
#define ui_rec_stmt_num		u_flags.s_bit.ui_stmt_num
#define ui_rec_currency		u_flags.s_bit.ui_currency
#define ui_rec_splits		u_flags.s_bit.ui_splits
#define ui_rec_reserved		u_flags.s_bit.ui_reserved
#define ui_rec_internal_flag	u_flags.s_bit.ui_internal_flag

#define ui_rec_flags		u_flags.ui_all

  Char          ra_note[0];	/* Dans l'ordre :
				 *  - Date de valeur (facultatif)
				 *  - N° chèque (facultatif)
				 *  - Répétition (facultatif)
				 *  - Transfert (facultatif)
				 *  - N° de relevé (facultatif)
				 *  - Devise (facultatif)
				 *  - Sous-opération(s) (facultatif)
				 *  - Description
				 */
};


// Si ui_rec_value_date
struct s_rec_value_date
{
  DateType s_value_date;	// Date de valeur
};

// Si ui_rec_check_num
struct s_rec_check_num
{
  UInt32   ui_check_num;	// Numéro du chèque
};

// Si ui_rec_repeat
struct s_rec_repeat
{
  UInt16   uh_repeat_type:2;	/* mois, fin de mois */
#define REPEAT_MONTHLY		0
#define REPEAT_MONTHLY_END	1
#define REPEAT_WEEKLY		2
#define REPEAT_TYPE_LAST	REPEAT_WEEKLY
  UInt16   uh_repeat_freq:6;	/* Tous les... */
  UInt16   uh_reserved:8;
  DateType s_date_end;		/* 0 si infini */
};

// Si ui_rec_xfer ou ui_rec_xfer_cat
struct s_rec_xfer
{
  UInt32    ul_reserved:8;	// (en tête par compatibilité)
  UInt32    ul_id:24;  // uniqueID OU ID de catégorie (si ui_xfer_cat)
};

// Si ui_rec_stmt_num
struct s_rec_stmt_num
{
  UInt32   ui_stmt_num;		// Numéro du relevé
};

// Si ui_rec_currency
struct s_rec_currency
{
  t_amount l_currency_amount;	// Montant dans la devise
  UInt32   ui_currency:8;	// ID de la devise
  UInt32   ui_reserved:24;	// Réservé...
};

// Si ui_rec_splits
struct s_rec_sub_transaction
{
  UInt16   uh_num:8;		// Nombre de sous-opérations à suivre
  UInt16   uh_reserved:8;	// Réservé...
  UInt16   uh_size;		// Taille en octets des sous-opérations
				// qui suivent
};

struct s_rec_one_sub_transaction
{
  UInt32   ui_type:8;		// Type de la sous-opération
  UInt32   ui_reserved:24;	// Réservé
  t_amount l_amount;		// Somme en centimes ds la monnaie de l'op
				// positive si même signe que l'op, <0 sinon
  Char     ra_desc[0];		// Description
};


//
// Function options_edit
enum e_options_edit
{
  OPT_VALUE_DATE	= 0,
  OPT_CHECK_NUM		= 1,
  OPT_REPEAT		= 2,
  OPT_XFER		= 3,
  OPT_STMT_NUM		= 4,
  OPT_CURRENCY		= 5,
  OPT_SPLITS		= 6,
  OPT_NOTE		= 7
};


//
// Functions options_edit, options_extract, options_check_extract
struct s_rec_options
{
  struct s_rec_value_date	*ps_value_date;	// Toujours la 1ère option
  struct s_rec_check_num	*ps_check_num;
  struct s_rec_repeat		*ps_repeat;
  struct s_rec_xfer		*ps_xfer;
  struct s_rec_stmt_num		*ps_stmt_num;
  struct s_rec_currency		*ps_currency;
  struct s_rec_sub_transaction	*ps_splits; // Toujours juste avant la
					    // note car de longueur
					    // variable
  Char				*pa_note;
};


@interface Transaction : DBItem
{
  struct s_db_prefs *ps_prefs;

  Char ra_account_name[dmCategoryLength];
}

+ (Transaction*)open:(Char*)pa_db_name;

- (Char*)loadAccountName;

- (struct s_db_prefs*)getPrefs;
- (Boolean)savePrefs;

- (Boolean)seekRecord:(UInt16*)puh_index offset:(UInt16)uh_offset
	    direction:(UInt16)uh_direction;

- (UInt16)sumDate:(Int16)h_sum_type;

#define ACCOUNT_PROP_RECORDGET	0x8000
#define ACCOUNT_PROP_CURRENT	0x4000
- (struct s_account_prop*)accountProperties:(UInt16)uh_account
				      index:(UInt16*)puh_index;
- (UInt16)accountCurrency:(UInt16)uh_account;

- (Boolean)account:(UInt16)uh_account changeCurrency:(UInt16)uh_old_currency;
- (UInt16)numAccountCurrency:(UInt32)uh_currency;

- (UInt16)firstAccountMatching:(Char*)pa_account;
- (UInt16)selectNextAccount:(Boolean)b_next of:(UInt16)uh_cur_account;

- (UInt16)removeCurrency:(UInt32)ui_currency;
- (UInt16)removeType:(UInt32)ui_type;
- (UInt16)removeMode:(UInt32)ui_mode;

// Flags à passer en même temps que l'index à -deleteId:
//
// Pour supprimer l'opération liée (si elle existe) en même temps que
// l'opération passée en paramètre
#define TR_DEL_XFER_LINK_TOO		0x20000000
// Si opération liée, supprime l'option Xfer de l'opération liée
// (utilisé lors de la suppression d'un compte)
#define TR_DEL_XFER_LINK_PART		0x10000000
// Mise à jour de l'alarme via alarm_schedule_transaction(true) pour
// l'opération et son éventuel lien. Appel de alarm_schedule_all() si
// l'alarme a disparu.
#define TR_DEL_MANAGE_ALARM		0x08000000
// Si l'alarme de l'appli vient d'être retirée, n'appelle pas
// alarm_schedule_all(), mais renvoie TR_DEL_MUST_RESCHED_ALARM
#define TR_DEL_DONT_RESCHED_ALARM	0x04000000

// Valeur renvoyée par -deleteId: lorsque le flag
// TR_DEL_DONT_RESCHED_ALARM et que l'alarme vient d'être désactivée.
#define TR_DEL_MUST_RESCHED_ALARM	0x0100

- (Boolean)deleteXferOption:(UInt16)uh_index;
#define CHANGE_XFER_OPTION_CATEGORY	0x80000000
- (Boolean)changeXferOption:(UInt32)ul_id forId:(UInt16)uh_index;

- (Boolean)deleteCurrencyOption:(UInt16)uh_index;
- (Boolean)addCurrencyOption:(struct s_rec_currency*)ps_curr_option
		       forId:(UInt16)uh_index;

- (Boolean)deleteRepeatOption:(UInt16)uh_index;
- (Boolean)computeAllRepeats:(Boolean)b_force onMaxDays:(UInt32)ui_max_days;
- (Boolean)computeRepeatsOfId:(UInt16)index;
- (UInt16)updateRepeatOfId:(UInt16)index onMaxDays:(UInt32)ui_max_days;

- (Boolean)deleteStmtNumOption:(UInt16)uh_index;
- (Boolean)addStmtNumOption:(UInt32)ui_stmt_num forId:(UInt16)uh_index;

- (Boolean)changeFlaggedToChecked:(UInt32)ui_stmt_num;

- (void)deleteAccount:(UInt16)uh_account;

- (UInt16)getSavePositionFor:(struct s_transaction*)ps_tr at:(UInt16)uh_index;
- (Boolean)save:(struct s_transaction*)ps_tr size:(UInt16)uh_size
	   asId:(UInt16*)puh_index
	account:(Int16)h_account xferAccount:(Int16)h_xfer_account;

- (UInt16)validDB:(UInt32)ui_correct;
- (Boolean)validRecord:(UInt16)index
	       correct:(Boolean)b_correct
		 types:(Type*)oTypes
		 modes:(Mode*)oModes
	    currencies:(Currency*)oCurrencies;

- (void)sortByValueDate:(Boolean)b_by_value_date;

- (UInt32)getLastStatementNumber;

struct s_tr_find_params
{
  FindParamsPtr ps_sys_find_params;

  // Variables globales
  t_amount l_amount;		// Somme en 100F
  UInt32   ui_int_num;		// Nombre positif 32 bits (XXX Int32 XXX ^^^)
  Int16    h_sign;		// -1 si préfixe < / 1 si préfixe > / 0 sinon
  Boolean  b_find_num;		// La chaîne à rechercher est un nombre
  Boolean  b_signed;		// true si préfixe + ou - (si false l_am. >= 0)
};

- (Boolean)findRecord:(struct s_tr_find_params*)ps_find_params;

// Pour -listBuildForAccount:num:largest:
struct s_tr_accounts_list
{
  Int16  h_skip_account;	// Si >= 0, ID compte à ne pas mettre en liste
  UInt16 uh_checked_accounts;	// Si != 0, mode checkbox
  UInt16 uh_before_last;	// Si != 0, idx chaîne à mettre en avant der.
  UInt16 uh_last;		// Si != 0, idx chaîne à mettre en fin
  // Si [0] != '\0', chaîne à mettre en tête de la liste
  Char   ra_first_item[dmDBNameLength + 1]; // + 1 pour le '>'
};

#define ACC_POPUP_FIRST		MAX_ACCOUNTS
#define ACC_POPUP_BEFORE_LAST	(MAX_ACCOUNTS + 1)
#define ACC_POPUP_LAST		(MAX_ACCOUNTS + 2)
- (VoidHand)popupListInit:(UInt16)uh_list_id
		     form:(BaseForm*)oForm
		    infos:(struct s_tr_accounts_list*)ps_infos
	  selectedAccount:(UInt16)uh_account;

- (UInt16)popupList:(VoidHand)pv_list firstIsValid:(Boolean)b_first_valid;
- (UInt16)popupListGet:(VoidHand)pv_list;
- (void)popupList:(VoidHand)pv_list setSelection:(UInt16)uh_id;
- (void)popupListFree:(VoidHand)pv_list;
+ (void)classPopupListFree:(VoidHand)pv_list;

struct __s_accounts_popup_list;

- (void)_popupListInit:(struct __s_accounts_popup_list*)ps_list
		 infos:(struct s_tr_accounts_list*)ps_infos;
- (void)_popupListSetLabel:(struct __s_accounts_popup_list*)ps_list;
- (void)_popupListSetSelection:(struct __s_accounts_popup_list*)ps_list;

@end

struct __s_list_accounts_buf
{
  __STRUCT_DBITEM_LIST_BUF(Transaction);

  UInt16 uh_checked_accounts;	// Si != 0, mode checkbox
  UInt16 uh_checked_width;	// Si mode checkbox

  UInt8  rua_accounts_id[MAX_ACCOUNTS];

  // Si [0] != '\0', chaîne à mettre en tête de la liste
  Char   ra_first_item[dmDBNameLength];
  // Si [0] != '\0', chaîne à mettre en avant dernière position dans la liste
  Char   ra_before_last_item[dmDBNameLength]; // 
  // Si [0] != '\0', chaîne à mettre en fin de liste
  Char   ra_last_item[dmDBNameLength]; // 
};


struct __s_accounts_popup_list
{
  BaseForm *oForm;
  ListType *pt_list;
  struct __s_list_accounts_buf *ps_buf;
  UInt16 uh_list_idx;		// Index de la liste dans le formulaire
  UInt16 uh_popup_idx;		// Index du popup dans le formulaire
  UInt16 uh_popup_width;	// Largeur en pixels du popup
  UInt16 uh_id;			// ID du compte actuellement sélectionné
  UInt16 uh_num;		// Nombre total d'entrées
};


#define value_date_extract(ps_rec) \
		(((struct s_rec_value_date*)ps_rec->ra_note)->s_value_date)
EXTERN_TRANSACTION void options_extract(struct s_transaction *ps_tr,
					struct s_rec_options *ps_options);
EXTERN_TRANSACTION Boolean options_check_extract(struct s_transaction *ps_tr,
						 UInt16 uh_size,
						 struct s_rec_options *ps_opt);

UInt16 options_edit(struct s_transaction *ps_tr,
		    struct s_rec_options *ps_options,
		    void *pv_contents,
		    enum e_options_edit e_option_index);

EXTERN_TRANSACTION struct s_rec_one_sub_transaction *sub_trans_next_extract
	(struct s_rec_sub_transaction *ps_base_sub_tr,
	 struct s_rec_one_sub_transaction *ps_last_sub_tr);

#define FOREACH_SPLIT_DECL				\
	struct s_rec_one_sub_transaction *ps_cur_split; \
	UInt16 __uh_num

#define FOREACH_SPLIT(ps_options)					\
	for (ps_cur_split = NULL, __uh_num = (ps_options)->ps_splits->uh_num; \
	     __uh_num-- > 0						\
	     && (ps_cur_split = sub_trans_next_extract((ps_options)->ps_splits,\
						       ps_cur_split)) != NULL;)

EXTERN_TRANSACTION struct s_splits_parse_base *splits_parse_new
	(struct s_transaction *ps_tr, struct s_rec_options *ps_options,
	 UInt32 *pul_types, UInt16 uh_to_currency);

EXTERN_TRANSACTION void splits_parse_free(struct s_splits_parse_base *ps_splits);

EXTERN_TRANSACTION UInt32 do_on_each_transaction(UInt16 (*pf_method)
						 (Transaction*, UInt32),
						 UInt32 ui_value);

EXTERN_TRANSACTION void find_on_each_transaction(struct s_tr_find_params *ps);

EXTERN_TRANSACTION Int16 transaction_val_date_cmp(struct s_transaction *ps_tr1,
						  struct s_transaction *ps_tr2,
						  Int16 h_dummy,
						  SortRecordInfoPtr rec1,
						  SortRecordInfoPtr rec2,
						  MemHandle appInfoH);

EXTERN_TRANSACTION Int16 transaction_std_cmp(struct s_transaction *ps_tr1,
					     struct s_transaction *ps_tr2,
					     Int16 h_dummy,
					     SortRecordInfoPtr rec1,
					     SortRecordInfoPtr rec2,
					     MemHandle appInfoH);

EXTERN_TRANSACTION Char *repeat_expand_note(Char *pa_note, UInt16 *puh_size,
					    UInt16 uh_inc, Boolean b_in_place);

EXTERN_TRANSACTION Int16 repeat_num_occurences(struct s_rec_repeat *ps_repeat,
					       DateType s_orig_date,
					       DateType s_new_date);

//
// Cas d'opération liées par un transfert
//
// date		identique
// heure	identique
// somme	opposée et convertie dans la devise du compte
// 
// checked	indépendant
// marked	indépendant
// alarm	indépendant
// mode		identique	(À VOIR)
// type		identique	(À VOIR)
//
// value_date	indépendant
// check_num	indépendant
// repeat	identique
// xfer		toujours présent
// xfer_cat	présent si opération absente dans le compte de transfert
// stmt_num	indépendant
// currency	si les 2 comptes n'ont pas la même monnaie
//		  devise avec la monnaie du compte de transfert
//		sinon
//		  impossible (car ça n'a pas de sens)
// splits	indépendant, mais la somme des sous-opérations de chacune ne
//		doit pas excéder la somme de l'autre (en plus de la
//		sienne, comme c'est le cas pour une opération sans
//		transfert)
//

#endif	/* __TRANSACTION_H__ */
