/* -*- objc -*-
 * MaTirelire.h -- 
 * 
 * Author          : Max Root
 * Created On      : Sun Jan  5 21:14:46 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jun 23 11:38:48 2006
 * Update Count    : 4
 * Status          : Unknown, Use with caution!
 */

#ifndef	__MATIRELIRE_H__
#define	__MATIRELIRE_H__

#include "Application.h"

#include "Mode.h"
#include "Type.h"
#include "Desc.h"
#include "Currency.h"
#include "Transaction.h"

#include "misc.h"
#include "structs.h"

#ifndef EXTERN_MATIRELIRE
# define EXTERN_MATIRELIRE extern
#endif

struct s_mati_fonts
{
  FontID uh_list_font;
  FontID uh_list_bold_font;
};

@interface MaTirelire : Application
{
  struct s_mati_prefs s_prefs;

  Mode *oModes;
  Type *oTypes;
  Desc *oDesc;
  Currency *oCurrencies;
  Transaction *oTransactions;

  // Gestion du timeout/code d'accès
  UInt32 ul_last_event;
  UInt32 ul_timeout_sec;
  UInt32 ul_initial_wait_for;
  UInt32 ul_timeout_access_code;
  Boolean b_db_access_code;

  Boolean b_goto_event_pending;

  // FontBucket
  FmType s_fb;
  struct s_mati_fonts s_fonts;

  // Infos qui vont servir souvent durant l'exécution du programme
  struct s_misc_infos s_misc_infos;
}

- (void)gotoFirstFormWithDB:(SysAppLaunchCmdOpenDBType*)cmdPBP;

- (void)passwordReinit;

#define PW_DBASE_RETRY	3	// Nbre de redemandes de psswd de base à faire
#define PW_RTOFORM	0x0001	// Il y a un formulaire sous nous
#define PW_WAITOK	0x0002	// Ne retourne que si le pw est bon OU Stop
#define PW_RETURNCODE	0x0004	// Renvoie le code dans le 1er argument qui
				// sera pour le coup l'adresse d'un UInt32
				// -1 est renvoyé si Stop, sinon true
#define PW_FORMAT	0x0008	// uh_label est un format avec ...
//
// Renvoie 1 si code bon, 0 si code mauvais et -1 si appStopEvent
- (Int16)passwordDialogCode:(UInt32)ul_code
		      label:(UInt16)uh_label
		      flags:(UInt16)uh_flags, ...;

- (Int16)passwordChange:(UInt32)ul_access_code
	    currentCode:(UInt32*)pul_current_code;

- (Boolean)passwordCheckDBaseCode;

- (struct s_mati_prefs*)getPrefs;

- (FmType*)getFontBucket;
- (Boolean)changeFont:(FmFontID)ui_new_font;
- (FmFontID)getBoldFont:(FmFontID)ui_font;
- (struct s_mati_fonts*)getFonts;
- (UInt16)getFontHeight;

- (Mode*)mode;
- (Type*)type;
- (Desc*)desc;
- (Currency*)currency;

- (Transaction*)newTransaction:(Transaction*)oNewTransactions;
- (void)freeTransaction;
- (Transaction*)transaction;

- (Boolean)checkAndCorrectDBs;

@end

#define oMaTirelire ((MaTirelire*)oApplication)

EXTERN_MATIRELIRE void display_title_popup(void);

#endif	/* __MATIRELIRE_H__ */
