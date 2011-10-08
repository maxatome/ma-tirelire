/* -*- objc -*-
 * MaTiForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Thu Aug 28 19:47:07 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Nov  2 17:50:14 2006
 * Update Count    : 11
 * Status          : Unknown, Use with caution!
 */

#ifndef	__MATIFORM_H__
#define	__MATIFORM_H__

#include "BaseForm.h"

#include "Transaction.h"


#ifndef EXTERN_MATIFORM
# define EXTERN_MATIFORM extern
#endif

@interface MaTiForm : BaseForm
{
  // Événement arrivés durant l'affichage de ce formulaire, à
  // transmettre à Papa
  UInt32 ui_update_mati_list;
  UInt16 uh_update_prefs;

  UInt16 uh_last_focus_idx;
}

// Barre de titre contenant un popup
#define POPUP_SPACE_WIDTH	5 // Largeur du bitmap en espaces ' '
- (void)displayPopupBitmap;
- (void)displayPopupTitle:(Char*)pa_title maxWidth:(UInt16)uh_max_width;

- (void)pasteInField:(UInt16)uh_fld_id;

// Types values
#define STMT_NUM_POPUP_TYPE_KEEP_CANCEL		0
#define STMT_NUM_POPUP_TYPE_KEEP_ANOTHER	1
#define STMT_NUM_POPUP_TYPE_LIST_ANOTHER	2
- (UInt32)statementNumberPopup:(UInt16)uh_type list:(UInt16)uh_list
			  posx:(UInt16)uh_x posy:(UInt16)uh_y
		    currentNum:(UInt32)ui_current_num;
// Return values
#define STMT_NUM_POPUP_KEEP	0
#define STMT_NUM_POPUP_ANOTHER	-1
#define STMT_NUM_POPUP_CANCEL	-1 // CANCEL & ANOTHER can not be in same popup
#define STMT_NUM_POPUP_DO_NOTHING -2

- (void)DBasesPopupList:(UInt16)uh_list in:(MemHandle*)ppv_db_list
	calledAsSubMenu:(Boolean)b_is_sub_menu;
- (void)DBasesChangeTo:(Char*)pa_db_name len:(UInt16)uh_db_name_len
		  same:(Boolean)b_current_db;

- (void)accountsPopupList:(UInt16)uh_list in:(MemHandle*)ppv_popup_accounts
		     from:(Transaction*)oTransactions
	  calledAsSubMenu:(Boolean)b_is_sub_menu;

- (void)gotoFormViaUpdate:(UInt16)uh_form_id;

////////////////////////////////////////////////////////////////////////
//
// Gestion des codes d'update
//
#define frmMaTiUpdateCodeMask		0xf000 // 4 bits
#define frmMaTiUpdateCodeShift		12
#define frmMaTiUpdateSubcodeMask	0x0fff // 12 bits
#define frmMaTiUpdateTotalMask		(frmMaTiUpdateCodeMask\
					 |frmMaTiUpdateSubcodeMask)
#define UPD_CODE(code)			((code) & frmMaTiUpdateCodeMask)
#define UPD_SUBCODE(code)		((code) & frmMaTiUpdateSubcodeMask)
#define UPD_ALLCODE(code)		((code) & frmMaTiUpdateTotalMask)
#define UPD_UPPERCODE(code)		((code) & ~frmMaTiUpdateTotalMask)

//
// Les codes
//
// Permet de faire un FrmGotoForm proprement (l'ID du form est dans le subcode)
#define frmMaTiUpdateGotoForm		(1 << frmMaTiUpdateCodeShift)

// Une liste a changé
#define frmMaTiUpdateList		(2 << frmMaTiUpdateCodeShift)
# define frmMaTiUpdateListCurrencies	0x001 // La liste des devises a changé
# define frmMaTiUpdateListDesc		0x002 // La liste des desc a changé
# define frmMaTiUpdateListModes		0x004 // La liste des modes a changé
# define frmMaTiUpdateListTypes		0x008 // La liste des types a changé
# define frmMaTiUpdateListDBases	0x010 // La liste des bases a changé
# define frmMaTiUpdateListAccounts	0x020 // La liste des comptes a changé
# define frmMaTiUpdateListTransactions	0x040 // Ajout/Suppr/Modif opération
# define frmMaTiUpdateListSumTypes	0x080 // La liste des types de somme...
# define frmMaTiChangeAccount		0x100 // Chgt de compte pour AccListFrm

// Une préférence a changé
#define frmMaTiUpdatePrefs		(3 << frmMaTiUpdateCodeShift)
# define frmMaTiUpdatePrefsScrList	0x01 // Mode gaucher/droit. ET/OU fonte
# define frmMaTiUpdatePrefsColors	0x02 // Couleur(s) changée(s)
# define frmMaTiUpdatePrefsBold		0x04 // Gras changé

// Spécial TransForm, il faut recalculer la date de fin de répétition
// Pas besoin de sous code pour ce cas...
#define frmMaTiUpdateTransForm		(4 << frmMaTiUpdateCodeShift)
# define frmMaTiUpdateTransFormRepeat	 0x001 // Recal. date fin de répétition
# define frmMaTiUpdateTransFormSplits	 0x002 // Changement sous-opération
# define frmMaTiUpdateTransFormSplitsDiff 0x004 // Le reste vient de changer

// Spécial Clearing*Form
#define frmMaTiUpdateClearingForm	(5 << frmMaTiUpdateCodeShift)
# define frmMaTiUpdateClearingFormClose	 0x001 // Ferme les forms d'intro/liste
# define frmMaTiUpdateClearingFormUpdate 0x002 // Recalcul dans form d'intro
					       // ou pointage dans liste
# define frmMaTiUpdateClearingFormAuto	 0x004 // Lance le pointage auto

// Spécial MiniStatsForm
#define frmMaTiUpdateMiniStatsForm	(6 << frmMaTiUpdateCodeShift)

////////////////////////////////////////////////////////////////////////
//
// Cas très spéciaux pour les passages de messages entre
// Edit{Desc,Mode,Type,Currency}From et les *ListForm correspondants
//
#define frmMaTiUpdateEdit2List		    0x4000 // the list changed
# define frmMaTiUpdateEdit2ListDeletedItem  0x2000 // an item was removed
# define frmMaTiUpdateEdit2ListNewItem	    0x1000 // a new item was added
# define frmMaTiUpdateEdit2ListNewItemAfter 0x0800 // idem but just after cur
# define frmMaTiUpdateEdit2ListAfterMove    0x0400 // update only after moves
# define frmMaTiUpdateEdit2ListRedraw	    0x0200 // Redraw list
# define frmMaTiUpdateEdit2ListNewId	    0x00ff // when new type, contain ID

@end

// Last statement num typed in an account session (0 if none)
// used by TransListForm and TransForm
EXTERN_MATIFORM UInt32 gui_last_stmt_num;

#endif	/* __MATIFORM_H__ */
