/* 
 * structs.h -- 
 * 
 * Author          : Max Root
 * Created On      : Fri Jan 10 23:19:56 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Mar 23 10:22:22 2006
 * Update Count    : 6
 * Status          : Unknown, Use with caution!
 */

#ifndef	__STRUCTS_H__
#define	__STRUCTS_H__

#include "FontBucket.h"

#ifndef EXTERN_STRUCTS
# define EXTERN_STRUCTS extern
#endif

//
// In the system preferences
struct s_mati_prefs
{
  UInt32 ul_no_beta_alert:1;	// No alert box signaling beta software
  UInt32 ul_db_must_be_corrected:1; // Une BD a au - une opération foireuse
  UInt32 ul_replace_desc:1;	// Description remplacée dans op_form
  UInt32 ul_XXX1:1;		// Free to use...
  UInt32 ul_auto_lock_on_power_off:1; // Lock auto à l'extinction
  UInt32 ul_time_select3:1;	// Boîte de sélection de l'heure OS3
  UInt32 ul_left_handed:1;	// Barre de scroll à gauche
#define PW_TIMEOUT_NONE		0
#define PW_TIMEOUT_30S		1
#define PW_TIMEOUT_60S		2
#define PW_TIMEOUT_120S		3
#define PW_TIMEOUT_300S		4
  UInt32 ul_timeout:3;		// Temps d'inactivité au bout du quel le code
				// d'accès est redemandé
#define DM_REMOVE_RECORD	0 // Suppression immédiate
#define DM_DELETE_RECORD	1 // Suppression à la prochaine synchro (cond.)
  UInt32 ul_remove_type:1;	// DmRemoveRecord or DmDeleteRecord
				// for types, modes and desc DB
  UInt32 ul_XXX2:2;		// Free to use...
#define FIRSTNEXT_NOT_CHECKED	0
#define FIRSTNEXT_NOT_FLAGGED	1
#define FIRSTNEXT_NOT_CHK_FLG	2
#define FIRSTNEXT_FLAGGED	3
  UInt32 ul_firstnext_action:2;	// Action des icones premier/suivant
#define FIRST_FORM_DBASES	0
#define FIRST_FORM_ACCOUNTS	1
#define FIRST_FORM_TRANS	2
#define FIRST_FORM_XXX		3
  UInt32 ul_first_form:3;	// Formulaire à afficher au lancement
				// de l'appli
  UInt32 ul_select_focused_num_flds:1; // Sélectionne le contenu des champs
				       // numériques qui obtiennent le focus
  UInt32 ul_clearing_sum:1;	// Écran de pointage : Pointés/Reste
  UInt32 ul_clearing_sort:3;	// Écran de pointage : type de tri
  UInt32 ul_reserved:9;

  UInt32 ul_access_code;	// Code d'accès à l'application

  Char ra_last_db[dmDBNameLength]; // Nom de la dernière base utilisée

  FmFontID	ui_list_font;	   // Fonte dans les listes
  FmFontID	ui_list_bold_font; // Version "grasse"

#define COLOR_REPEAT		0
#define COLOR_XFER		1
#define COLOR_CREDIT		2
#define COLOR_DEBIT		3
#define COLOR_CURRENCY		4
#define COLOR_RESERVED2		5
#define COLOR_RESERVED3		6
#define COLOR_RESERVED4		7
  IndexedColorType ra_colors[8];
#define USER_REPEAT_COLOR	0x0001 /* Repeat color user defined */
#define USER_XFER_COLOR		0x0002 /* Xfer color user defined */
#define USER_CREDIT_COLOR	0x0004 /* Credit color user defined */
#define USER_DEBIT_COLOR	0x0008 /* Debit color user defined */
#define USER_CURRENCY_COLOR	0x0010 /* Currency color user defined */
#define USER_RESERVED2_COLOR	0x0020
#define USER_RESERVED3_COLOR	0x0040
#define USER_RESERVED4_COLOR	0x0080
#define USER_XFER_BOLD		0x0100 /* Xfer are in bold face */
#define USER_REPEAT_BOLD	0x0200 /* Repeats are in bold face */
#define USER_CURRENCY_ULINE	0x0400 /* Currency amounts are underlined */
  UInt16 uh_list_flags;
};


//
// Stats prefs
struct s_stats_prefs
{
  DateType rs_date[2];

#define STATS_MENU_NONE		0
#define STATS_MENU_CUR_MONTH	1
#define STATS_MENU_LAST_MONTH	2
#define STATS_MENU_LAST2_MONTH	3
#define STATS_MENU_CUR_YEAR	4
#define STATS_MENU_LAST_YEAR	5
#define STATS_MENU_ALL		6
  UInt32   ui_menu_choice:3;	// Choix dans le menu, rs_date ne compte pas
#define STATS_MENU_WEEK_POS	6
  UInt32   ui_week_bounds:1;	// Seulement si ui_menu_choice != NONE
#define STATS_BY_TYPE		0
#define STATS_BY_MODE		1
#define STATS_BY_WEEK		2
#define STATS_BY_BIWEEK		3
#define STATS_BY_MONTH		4
#define STATS_BY_QUARTER	5
#define STATS_BY_YEAR		6
  UInt32   ui_by:4;		// Par (type, mode, semaine, ...)
  UInt32   ui_type_any:1;
  UInt32   ui_type:8;
  UInt32   ui_mode_any:1;
  UInt32   ui_mode:5;
#define STATS_ON_ALL		0
#define STATS_ON_DEBITS		1
#define STATS_ON_CREDITS	2
#define STATS_ON_FLAGGED	3
  UInt32   ui_on:2;		// Sur toutes les op, débits, crédits, marqués
  UInt32   ui_val_date:1;	// En fonction de la date de valeur
  UInt32   ui_ignore_nulls:1;	// Ignorer les montants nuls
  UInt32   ui_type_children:1;	// Inclut les fils du type sélectionné
  UInt32   ui_dates_bound:1;	// Les deux dates sont liées
  UInt32   ui_reserved:3;	// Toujours à 0

  UInt16   uh_checked_accounts;
};


//
// In each accounts database, in the info block after categories
struct s_db_prefs
{
  UInt32 ul_access_code;	// Code to access database

#define MATI_DB_PREFS_VERSION	1
  UInt32 ul_version:4;		// Last version is 1
  UInt32 ul_cur_category:4;	// Current category
  UInt32 ul_show_all_cat:1;	// All categories are visible XXX
#define DM_REMOVE_RECORD	0
#define DM_DELETE_RECORD	1
  UInt32 ul_remove_type:1;	// DmRemoveRecord or DmDeleteRecord
  UInt32 ul_deny_find:1;	// [Dis]allow global find feature in this DB
#define SORT_BY_DATE		0
#define SORT_BY_VALUE_DATE	1
  //#define SORT_BY_XXX		2 -> 7 // Reserved for future use
  UInt32 ul_sort_type:3;	// Sort type : by [value] date
  UInt32 ul_list_date:1;	// 1 if list date is value date, 0 else
  UInt32 ul_check_locked:1;	// Checking and Flagging are locked
  UInt32 ul_auto_repeat:1;	// Compute repeats automaticaly
  UInt32 ul_repeat_days:7;	// Repeat interval
  UInt32 ul_list_type:1;	// 1 if list descritpion is type, 0 else
#define SPLIT_LABEL_DESC	0
#define SPLIT_LABEL_TYPE	1
  UInt32 ul_splits_label:1;	// In trans form, splits label: 0=desc, 1=type
#define SPLIT_SORT_DESC		0
#define SPLIT_SORT_TYPE		1
#define SPLIT_SORT_AMOUNT	2
  UInt32 ul_splits_sort:2;	// Trans form, splits sort by: desc/type/amount
  UInt32 ul_reserved1:4;	// Réservé

#define VIEW_ALL		0
#define VIEW_WORST		1
#define VIEW_TODAY		2
#define VIEW_CHECKED		3
#define VIEW_MARKED		4
#define VIEW_CHECKNMARKED	5
#define VIEW_DATE		6
#define VIEW_TODAY_PLUS		7
#define VIEW_LAST		VIEW_TODAY_PLUS
#define VIEW_SELECT_DATES	(VIEW_LAST + 1)
#define VIEW_SELECT_AT_DATE	(VIEW_LAST + 2)
  //#define VIEW_XXX		8 -> 15 // Reserved for future use
  UInt32 ul_sum_type:4;		// Sum type
  UInt32 ul_sum_date:5;		/* Somme le X du mois */
  UInt32 ul_sum_todayplus:5;	/* Somme aujourd'hui + X jours */
  UInt32 ul_sum_at_date:1;	// cf. s_sum_date field below
#define ACCOUNTS_SUM_ALL	0
#define ACCOUNTS_SUM_SELECT	1
#define ACCOUNTS_SUM_NON_SELECT	2
#define ACCOUNTS_SUM_XXX	3
  UInt32 ul_accounts_sel_type:2; // Type de sélection dans l'écran des comptes
  UInt32 ul_accounts_currency:8; // Monnaie utilisée dans l'écran des comptes
  UInt32 ul_reserved2:7;	// Réservé

  UInt16 uh_selected_accounts;	// Bit a 1 si le compte est
				// sélectionné dans l'écran des
				// comptes

  DateType s_sum_date;		// Sum at a date. Only if ul_sum_at_date

#define DB_PREFS_STATS_NUM	14
  struct s_stats_prefs	rs_stats[DB_PREFS_STATS_NUM]; // Choix dans les stats

  Char ra_note[0];		// Note (NUL terminated)...
};

// Préférences de la version 0
struct s_db_prefs_0
{
  UInt32 ul_access_code;	// Code to access database

  UInt32 ul_version:4;
  UInt32 ul_cur_category:4;	// Current category
  UInt32 ul_show_all_cat:1;	// All categories are visible XXX
  UInt32 ul_remove_type:1;	// DmRemoveRecord or DmDeleteRecord
  UInt32 ul_deny_find:1;	// [Dis]allow global find feature in this DB
  UInt32 ul_sort_type:3;	// Sort type : by [value] date
  UInt32 ul_list_date:1;	// 1 if list date is value date, 0 else
  UInt32 ul_check_locked:1;	// Checking and Flagging are locked
  UInt32 ul_auto_repeat:1;	// Compute repeats automaticaly
  UInt32 ul_repeat_days:7;	// Repeat interval
  UInt32 ul_reserved1:8;	// Reste 12 bits à pourvoir

  UInt32 ul_sum_type:4;		// Sum type
  UInt32 ul_sum_date:5;		/* Somme le X du mois */
  UInt32 ul_sum_todayplus:5;	/* Somme aujourd'hui + X jours */
  UInt32 ul_sum_at_date:1;	// cf. s_sum_date field below
  UInt32 ul_accounts_sel_type:2; // Type de sélection dans l'écran des comptes
  UInt32 ul_accounts_currency:8; // Monnaie utilisée dans l'écran des comptes
  UInt32 ul_reserved2:7;	// Reste 15 bits à pourvoir

  UInt16 uh_selected_accounts;	// Bit a 1 si le compte est
				// sélectionné dans l'écran des
				// comptes

  DateType s_sum_date;		// Sum at a date. Only if ul_sum_at_date

  Char ra_note[0];		// Note (NUL terminated)...
};

#endif	/* __STRUCTS_H__ */
