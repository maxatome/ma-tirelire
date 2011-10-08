/* 
 * MaTiForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Thu Aug 28 19:47:05 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Dec 21 14:13:21 2007
 * Update Count    : 31
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: MaTiForm.m,v $
 * Revision 1.14  2008/01/14 16:55:00  max
 * Switch to new mcc.
 * Correct screen refreshing bug.
 * Statement number popup now select the first entry.
 *
 * Revision 1.13  2006/12/16 16:56:45  max
 * Grow some string buffer for italian language.
 *
 * Revision 1.12  2006/10/05 19:08:54  max
 * Add -DBasesChangeTo:len:same: method.
 * Database change now use new -DBasesChangeTo:len:same: method.
 *
 * Revision 1.11  2006/06/28 09:41:57  max
 * Keep ui_update_mati_list & uh_update_prefs only if form has parent.
 *
 * Revision 1.10  2006/06/23 13:25:10  max
 * Add comment.
 *
 * Revision 1.9  2006/06/19 12:23:57  max
 * Now handle AboutForm calls from menu.
 *
 * Revision 1.8  2006/04/25 08:46:53  max
 * Add -pasteInField: method + handling of it.
 * Redraws reworked (continue).
 * Add DEBUG_UPDATE #ifdef to debug redraws.
 *
 * Revision 1.7  2005/11/19 16:56:28  max
 * Now paste function works correctly in numeric fields. Numbers
 * containing spaces, foreign decimal separator or signs can now be
 * pasted.
 * -returnToLastForm now send always a redraw event to previous form.
 *
 * Revision 1.6  2005/10/11 19:11:55  max
 * Last statement search deported to Transaction.
 *
 * Revision 1.5  2005/08/20 13:06:53  max
 * Updates are now genericaly managed by MaTiForm.
 *
 * Revision 1.4  2005/05/08 12:12:59  max
 * Add -DBasesPopupList:in:calledAsSubMenu: method to display generic
 * accounts DBases popup list with right arrows for accounts sub-menus.
 * Add -accountsPopupList:in:from:calledAsSubMenu: method to display
 * generic accounts popup list with right arrows for accounts DBases
 * sub-menus.
 *
 * Revision 1.3  2005/03/20 22:28:21  max
 * Statement management popup:
 * - clicking outside now cancel (un)clearing
 * - LstSetDrawFunction() now called
 * - stop statement number search when first found
 *
 * Revision 1.2  2005/02/21 20:44:42  max
 * Add auto statement number popup management.
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#include <PalmOSGlue/TxtGlue.h>

#define EXTERN_MATIFORM
#include "MaTiForm.h"

#include "MaTirelire.h"

#include "float.h"
#include "misc.h"

#include "ids.h"
#include "graph_defs.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


@implementation MaTiForm

//
// Menu standard pour les écrans n'en ayant pas de spécifique...
- (Boolean)menu:(UInt16)uh_id
{
  UInt16 uh_fld_id;
  FieldType *pt_fld = NULL;

  //
  // La boîte d'infos...
  if (uh_id == DefaultMenuAbout)
  {
    FrmPopupForm(AboutFormIdx);
    return true;
  }

  uh_fld_id = FrmGetFocus(self->pt_frm);

  if (uh_fld_id != noFocus
      && FrmGetObjectType(self->pt_frm, uh_fld_id) == frmFieldObj)
    pt_fld = FrmGetObjectPtr(self->pt_frm, uh_fld_id);

  switch (uh_id)
  {
  case DefaultMenuUndo:
    if (pt_fld != NULL)
      FldUndo(pt_fld);
    break;

  case DefaultMenuCut:
    if (pt_fld != NULL)
      FldCut(pt_fld);
    break;

  case DefaultMenuCopy:
    if (pt_fld != NULL)
      FldCopy(pt_fld);
    break;

  case DefaultMenuPaste:
    if (pt_fld != NULL)
    {
      FieldAttrType s_attr;

      FldGetAttributes(pt_fld, &s_attr);

      // Champ numérique : on va coller caractère par caractère
      if (s_attr.numeric && s_attr.usable && s_attr.visible && s_attr.editable)
      {
	MemHandle pv_clip;
	Char *pa_clip;
	UInt16 uh_len, index;
	WChar wa_chr;

	pv_clip = ClipboardGetItem(clipboardText, &uh_len);
	if (pv_clip != NULL && uh_len != 0)
	{
	  pa_clip = MemHandleLock(pv_clip);

	  for (index = 0; index < uh_len; )
	  {
	    index += TxtGlueGetNextChar(pa_clip, index, &wa_chr);
	    switch (wa_chr)
	    {
	    case '.': case ',':
	      // Il faut mettre le séparateur décimal autorisé ici,
	      // sinon on va avoir des problèmes dans -keyFilter:for:
	      if (float_dec_separator() != wa_chr)
		wa_chr ^= 0x02;
	      // Continue...
	    case '0' ... '9':
	    case '+': case '-':
	      EvtEnqueueKey(wa_chr, 0, 0);
	      break;
	    }
	  }

	  MemHandleUnlock(pv_clip);
	}
      }
      else
	FldPaste(pt_fld);

      [self pasteInField:uh_fld_id];
    }
    break;

  case DefaultMenuSelectAll:
    if (pt_fld != NULL)
      FldSetSelection(pt_fld, 0, FldGetTextLength(pt_fld));
    break;

  default:
    return false;
  }

  return true;
}


- (void)pasteInField:(UInt16)uh_fld_id
{
  // Rien à faire ici...
}



////////////////////////////////////////////////////////////////////////
//
// Barre de titre contenant un popup
//
////////////////////////////////////////////////////////////////////////

- (void)displayPopupBitmap
{
  MemHandle pv_bmp;
  BitmapType *ps_bmp;
  Boolean b_no_color = oMaTirelire->uh_color_enabled == 0;
  IndexedColorType e_old_fore = 0, e_old_back = 0;

  pv_bmp = DmGetResource('Tbmp', bmpPopup + b_no_color);
  ps_bmp = MemHandleLock(pv_bmp);

  if (b_no_color == false)
  {
    e_old_fore = WinSetForeColor(UIColorGetTableEntryIndex(UIFormFill));
    e_old_back = WinSetBackColor(UIColorGetTableEntryIndex(UIFormFrame));
  }

  WinDrawBitmap(ps_bmp, 3, 6);

  if (b_no_color == false)
  {
    WinSetForeColor(e_old_fore);
    WinSetBackColor(e_old_back);
  }

  MemHandleUnlock(pv_bmp);
  DmReleaseResource(pv_bmp);
}


// uh_max_width = largeur de tout le titre, espaces préfixés compris
- (void)displayPopupTitle:(Char*)pa_title maxWidth:(UInt16)uh_max_width
{
  UInt16 uh_title_len = StrLen(pa_title);
  FontID uh_cur_font;
  // Il faut POPUP_SPACE_WIDTH espaces en tête du titre pour placer le
  // bitmap du popup
  Char ra_tmp[POPUP_SPACE_WIDTH + uh_title_len + 1]; // + \0 de fin

  MemSet(ra_tmp, POPUP_SPACE_WIDTH, ' ');
  MemMove(&ra_tmp[POPUP_SPACE_WIDTH], pa_title, uh_title_len + 1);
  uh_title_len += POPUP_SPACE_WIDTH;

  uh_cur_font = FntSetFont(boldFont);
  truncate_name(ra_tmp, &uh_title_len, uh_max_width, ra_tmp);
  FntSetFont(uh_cur_font);

  // Si la coupure a eu lieu en plein dans le bitmap => normalement on
  // fait tout pour que ça n'arrive pas
  // if (uh_title_len <= POPUP_SPACE_WIDTH) ra_tmp[0] = '\0'; ???

  FrmCopyTitle(self->pt_frm, ra_tmp);
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  switch (UPD_CODE(ps_update->updateCode))
  {
    // Cas provoqué par la méthode -gotoFormViaUpdate:
  case frmMaTiUpdateGotoForm:
  {
    FormType *pt_frm = self->pt_frm;

    [self close];

    FrmEraseForm(pt_frm);
    FrmDeleteForm(pt_frm);

    FrmGotoForm(UPD_SUBCODE(ps_update->updateCode));

#ifdef DEBUG_UPDATE
    DrawPrintf("Go- 0x%x (%lx) ", guh_pending_events, ps_update->updateCode);
#endif

    // On supprime le possible (mais improbable) flag PENDING_EVENT_UPDATE
    guh_pending_events--;
    guh_pending_events &= ~PENDING_EVENT_UPDATE;

#ifdef DEBUG_UPDATE
    DrawPrintf("Go+ 0x%x             ", guh_pending_events);
#endif

    return true;		// Toujours, car le form n'existe plus ici
  }

  // On conserve les flags d'update pour les faire passer à Papa avant
  // de quitter (voir -returnToLastForm)
  case frmMaTiUpdateList:
    // Il faut remplacer la partie haute si celle de l'événement que
    // l'on reçoit est != de 0
    if (self->oPrevForm != nil)
    {
      self->ui_update_mati_list &= frmMaTiUpdateTotalMask;
      self->ui_update_mati_list |= ps_update->updateCode;
    }
    break;

    // On conserve les flags d'update pour les faire passer à Papa avant
    // de quitter (voir -returnToLastForm)
  case frmMaTiUpdatePrefs:
    if (self->oPrevForm != nil)
      self->uh_update_prefs |= ps_update->updateCode;
    break;
  }

  return [super callerUpdate:ps_update];
}


// À utiliser en conjonction avec la méthode -update: pour faire un
// FrmGotoForm() sans craindre de problème.
- (void)gotoFormViaUpdate:(UInt16)uh_form_id
{
  // On fait le passage au prochain formulaire dans le update pour
  // éviter les problèmes...
  EventType e_user;
  struct frmCallerUpdate *ps_update;

  MemSet(&e_user, sizeof(e_user), 0);

  e_user.eType = frmCallerUpdateEvent;

  ps_update = (struct frmCallerUpdate*)&e_user.data;
  ps_update->formID = FrmGetFormId(self->pt_frm);
  ps_update->updateCode = uh_form_id | frmMaTiUpdateGotoForm;

  EvtAddEventToQueue(&e_user);

  // Un nouvel événement callerUpdate est en route...
  guh_pending_events++;
}


- (void)returnToLastForm
{
  // Dans PalmResize/resize.c
  extern void UniqueUpdateForm(UInt16 formID, UInt16 code);

  // Juste avant de revenir sur Papa, on lui transmet les flags
  // d'update qu'on a nous même reçu
  if (self->oPrevForm != nil
      && (self->uh_update_prefs != 0 || self->ui_update_mati_list != 0))
  {
    EventType e_user;
    struct frmCallerUpdate *ps_update;

    MemSet(&e_user, sizeof(e_user), 0);

    e_user.eType = frmCallerUpdateEvent;

    ps_update = (struct frmCallerUpdate*)&e_user.data;
    ps_update->formID = FrmGetFormId(self->oPrevForm->pt_frm);

    // Les préférences ont changé...
    if (self->uh_update_prefs != 0)
    {
      ps_update->updateCode = self->uh_update_prefs;
      EvtAddEventToQueue(&e_user);

      // Un nouvel événement callerUpdate est en route...
      guh_pending_events++;

#ifdef DEBUG_UPDATE
      DrawPrintf("M1+ 0x%x (%lx) ", guh_pending_events, ps_update->updateCode);
#endif
    }

    // Au moins une liste a changé...
    if (self->ui_update_mati_list != 0)
    {
      ps_update->updateCode = self->ui_update_mati_list;
      EvtAddEventToQueue(&e_user);

      // Un nouvel événement callerUpdate est en route...
      guh_pending_events++;

#ifdef DEBUG_UPDATE
      DrawPrintf("M2+ 0x%x (%lx) ", guh_pending_events, ps_update->updateCode);
#endif
    }
  }

  // On rafraîchit toujours l'écran sur lequel on va retourner
#ifdef DEBUG_UPDATE
  DrawPrintf("RD 0x%x ", guh_pending_events);
#endif
  UniqueUpdateForm(FrmGetFormId(FrmGetFirstForm()), frmRedrawUpdateCode);

  [super returnToLastForm];
}


- (Boolean)fldEnter:(struct fldEnter*)ps_fld_enter
{
  if ([oMaTirelire getPrefs]->ul_select_focused_num_flds)
  {
    UInt16 uh_fld_idx;

    uh_fld_idx = FrmGetObjectIndex(self->pt_frm, ps_fld_enter->fieldID);

    if (uh_fld_idx != self->uh_last_focus_idx)
    {
      FieldAttrType s_attr;

      self->uh_last_focus_idx = uh_fld_idx;

      FldGetAttributes(ps_fld_enter->pField, &s_attr);

      if (s_attr.numeric)
      {
	FldSetSelection(ps_fld_enter->pField, 0,
			FldGetTextLength(ps_fld_enter->pField));

	// On appelle FrmSetFocus() pour faire apparaître le curseur
	// (le focus est déjà sur le champ, mais si on n'appelle pas
	// FrmSetFocus() le curseur n'apparaît pas)
	FrmSetFocus(self->pt_frm, uh_fld_idx); // OK pas de -focusObject: ici

	return true;
      }
    }
  }

  return false;
}


- (UInt32)statementNumberPopup:(UInt16)uh_type list:(UInt16)uh_list
			  posx:(UInt16)uh_x
			  posy:(UInt16)uh_y
		    currentNum:(UInt32)ui_current_num
{
  Char ra_format[47 + 1];
  Char *rpa_text[4];
  Char rra_items[3][47 - 3 + 10 + 1]; // 3=>%lu 10=>UInt32 1=>\0
  Char ra_last_line[47 + 1];
  ListType *pt_list;
  RectangleType s_rect;
  UInt16 index, uh_num, uh_choice, uh_width, uh_largest;

  // ( (last num, )? (current#, next#, )? Another... )
  // noListSelection==No statement number
  if (uh_type == STMT_NUM_POPUP_TYPE_LIST_ANOTHER)
  {
    // Dernier numéro de relevé
    ui_current_num = [[oMaTirelire transaction] getLastStatementNumber];

    uh_num = 0;

    SysCopyStringResource(ra_format, strStatementNumNumber);

    if (gui_last_stmt_num != 0
	&& (ui_current_num == 0
	    || (gui_last_stmt_num != ui_current_num
		&& gui_last_stmt_num != ui_current_num + 1)))
    {
      // strStatementNumNumber + gui_last_stmt_num
      StrPrintF(rra_items[0], ra_format, gui_last_stmt_num);
      rpa_text[0] = rra_items[0];
      uh_num++;
    }

    if (ui_current_num != 0)
    {
      // strStatementNumNumber + numéro_trouvé
      StrPrintF(rra_items[uh_num], ra_format, ui_current_num);
      rpa_text[uh_num] = rra_items[uh_num];
      uh_num++;

      // strStatementNumNumber + (numéro_trouvé + 1)
      StrPrintF(rra_items[uh_num], ra_format, ui_current_num + 1);
      rpa_text[uh_num] = rra_items[uh_num];
      uh_num++;
    }
  }
  // ( Keep, Cancel ) noListSelection==Keep (STMT_NUM_POPUP_TYPE_KEEP_CANCEL)
  // ( Keep, Another ) noListSelection==Keep (STMT_NUM_POPUP_TYPE_KEEP_ANOTHER)
  else
  {
    SysCopyStringResource(ra_format, strStatementNumKeep);
    StrPrintF(rra_items[0], ra_format, ui_current_num);
    rpa_text[0] = rra_items[0];

    uh_num = 1;
  }

  // strStatementNumCancel OU BIEN strStatementNumAnother
  SysCopyStringResource(ra_last_line,
			uh_type == STMT_NUM_POPUP_TYPE_KEEP_CANCEL
			? strStatementNumCancel : strStatementNumAnother);
  rpa_text[uh_num++] = ra_last_line;

  uh_list = FrmGetObjectIndex(self->pt_frm, uh_list);
  pt_list = FrmGetObjectPtr(self->pt_frm, uh_list);

  LstSetListChoices(pt_list, rpa_text, uh_num);
  LstSetHeight(pt_list, uh_num);
  LstSetSelection(pt_list, 0);	// On sélectionne la première entrée
  LstSetDrawFunction(pt_list, list_line_draw);

  uh_largest = 0;
  for (index = uh_num; index-- > 0; )
  {
    uh_width = FntCharsWidth(rpa_text[index], StrLen(rpa_text[index]));
    if (uh_width > uh_largest)
      uh_largest = uh_width;
  }

  // On remet la liste à la bonne position (avec une largeur adéquate)
  FrmGetObjectBounds(self->pt_frm, uh_list, &s_rect);
  s_rect.extent.x = uh_largest + LIST_MARGINS_NO_SCROLL;
  s_rect.topLeft.x = uh_x;
  s_rect.topLeft.y = uh_y;
  FrmSetObjectBounds(self->pt_frm, uh_list, &s_rect);

  uh_choice = LstPopupList(pt_list);
  if (uh_choice == noListSelection)
    return STMT_NUM_POPUP_DO_NOTHING;

  // Dernier choix : Cancel OU Another...
  if (uh_choice == uh_num - 1)
    return STMT_NUM_POPUP_ANOTHER; // == STMT_NUM_POPUP_CANCEL

  // Un numéro de relevé précis

  // Liste des numéros ( (last num, )? (current#, next#, )? Another... )
  if (uh_type == STMT_NUM_POPUP_TYPE_LIST_ANOTHER)
  {
    // Il y avait une première entrée : dernier numéro de saisi
    // Soit ( last num, current#, next#, Another... ) => 4
    // Soit ( last num, Another... ) => 2
    if (uh_num == 4 || uh_num == 2)
    {
      // C'est justement cette première entrée qui a été sélectionnée
      if (uh_choice == 0)
	return gui_last_stmt_num;

      uh_choice--;
    }

    // Suivant du numéro courant...
    if (uh_choice > 0)
      ui_current_num++;
  }

  return ui_current_num;
}


//
// (>) présents ssi pas un sous-menu de accountsPopupList
//
//  Base1         >
// #Base2#########>#
//  Base3         >
// -----------------
//  Prop de la base
//  Gérer les bases
//
- (void)DBasesPopupList:(UInt16)uh_list in:(MemHandle*)ppv_db_list
	calledAsSubMenu:(Boolean)b_is_sub_menu
{
  ListType *pt_list;
  Char **ppa_list;
  SysDBListItemType *ps_dbs;
  UInt16 index, uh_list_idx, uh_num, uh_largest, uh_cur_dbase, uh_db_name_len;
  Boolean b_just_built = false;

  uh_list_idx = FrmGetObjectIndex(self->pt_frm, uh_list);
  pt_list = FrmGetObjectPtr(self->pt_frm, uh_list_idx);

  // La liste n'est pas encore construite
  if (*ppv_db_list == NULL)
  {
    *ppv_db_list = db_list_new(MaTiCreatorID, MaTiAccountsType,
			       &uh_num, &uh_largest,
			       strAccountsListDBProp,
			       strAccountsListEditDBs,
			       b_is_sub_menu == false);
    b_just_built = true;

    LstSetHeight(pt_list, uh_num);
    LstSetDrawFunction(pt_list, list_line_draw);
  }
  else
    uh_num = LstGetNumberOfItems(pt_list);

  ppa_list = MemHandleLock(*ppv_db_list);
  ps_dbs = (SysDBListItemType*)
    ((Char*)&ppa_list[uh_num] + DB_LIST_LAST_ENTRY_MAXLEN * 2);
  LstSetListChoices(pt_list, ppa_list, uh_num);

  // La liste vient d'être construite, il faut continuer les inits
  if (b_just_built)
  {
    RectangleType s_rect;
    UInt16 uh_screen_width, uh_dummy;

    uh_largest += LIST_MARGINS_NO_SCROLL;
    // Il va y avoir une flèche de scroll
    if (LstGetVisibleItems(pt_list) != uh_num)
      uh_largest += LIST_MARGINS_WITH_SCROLL - LIST_MARGINS_NO_SCROLL;

    // On s'adapte à la largeur de l'écran
    WinGetDisplayExtent(&uh_screen_width, &uh_dummy);
    if (uh_largest > uh_screen_width - LIST_EXTERNAL_BORDERS)
      uh_largest = uh_screen_width - LIST_EXTERNAL_BORDERS;

    FrmGetObjectBounds(self->pt_frm, uh_list_idx, &s_rect);
    s_rect.extent.x = uh_largest;
    FrmSetObjectBounds(self->pt_frm, uh_list_idx, &s_rect);
  }

  // On sélectionne la base courante (-2 car il y a 2 lignes en + à la fin)
  for (uh_cur_dbase = uh_num - 2; uh_cur_dbase-- > 0; )
  {
    uh_db_name_len = StrLen(ps_dbs[uh_cur_dbase].name);

    // Si on n'est pas un sous-menu, il y a un '>' à la fin de chaque ligne
    if (b_is_sub_menu == false)
      uh_db_name_len--;

    if (StrNCompare(ps_dbs[uh_cur_dbase].name,
		    oMaTirelire->s_prefs.ra_last_db, uh_db_name_len) == 0)
    {
      LstSetSelection(pt_list, uh_cur_dbase);
      break;
    }
  }

  index = LstPopupList(pt_list);
  if (index != noListSelection)
  {
    // Entrée "DB properties..." (ne peut pas être sélectionné si sous-menu)
    if (index == uh_num - 2)
      FrmPopupForm(DBasePropFormIdx);
    // Entrée "Manage DBs..." (ne peut pas être sélectionné si sous-menu)
    else if (index == uh_num - 1)
      [self gotoFormViaUpdate:DBasesListFormIdx];
    // A database...
    else
    {
      SysDBListItemType *ps_db = &ps_dbs[index];
      Boolean b_current_db;

      uh_db_name_len = StrLen(ps_db->name);

      // Si on n'est pas un sous-menu, il y a un '>' à la fin de chaque ligne
      if (b_is_sub_menu == false)
	uh_db_name_len--;

      b_current_db = (StrNCompare(ps_db->name,
				  oMaTirelire->s_prefs.ra_last_db,
				  uh_db_name_len) == 0);

      // Cascade du sous-menu seulement si on n'est pas déjà le sous-menu...
      if (b_is_sub_menu == false)
      {
	RectangleType s_rect;
	UInt16 uh_x, uh_dummy;
	Boolean b_dummy;

	// Coordonnées de la liste
	FrmGetObjectBounds(self->pt_frm,
			   FrmGetObjectIndex(self->pt_frm, uh_list),
			   &s_rect);

	EvtGetPen(&uh_x, &uh_dummy, &b_dummy);

	if (uh_x > s_rect.topLeft.x + s_rect.extent.x - 10)
	{
	  Transaction *oTransactions, *oMaTiTransactions;
	  MemHandle pv_accounts_list = NULL;

	  if (b_current_db)
	    oTransactions = [oMaTirelire transaction];
	  else
	  {
	    oTransactions = [Transaction alloc];

	    if ([oTransactions initWithCardNo:ps_db->cardNo
			       withID:ps_db->dbID] == nil)
	    {
	      [oTransactions free];
	      return;
	    }
	  }

	  // Ici on utilise toujours AccountsListAccounts puisque le
	  // seul cas où on n'est pas un sous-menu ne peut intervenir
	  // que dans AccountsListForm
	  [self accountsPopupList:AccountsListAccounts in:&pv_accounts_list
		from:oTransactions calledAsSubMenu:true];

	  // Marche même si pv_accounts_list == NULL

	  // On passe par la méthode de classe, car il se peut que
	  // [oMaTirelire transaction] vaille nil dans le cas où le
	  // passage à une nouvelle base a échoué
	  [Transaction classPopupListFree:pv_accounts_list];

	  // La base actuellement ouverte (peut être nil si
	  // l'ouverture a échouée, par mauvais mot de passe par
	  // exemple)
	  oMaTiTransactions = [oMaTirelire transaction];

	  // S'il n'y a pas (plus) de base contenue dans oMaTirelire,
	  // c'est qu'elle vient d'être libérée dans
	  // -accountsPopupList:..., donc rien à faire ici
	  if (oMaTiTransactions != nil
	      // Pas b_current_db == false car la base par défaut
	      // contenue dans oMaTirelire peut avoir changé dans
	      // -accountsPopupList:...
	      && oTransactions != oMaTiTransactions)
	    [oTransactions free];

	  return;
	}
      }

      if (b_current_db == false || b_is_sub_menu)
	[self DBasesChangeTo:ps_db->name len:uh_db_name_len same:b_current_db];
    }
  }

  MemHandleUnlock(*ppv_db_list);
} // DBasesPopupList


- (void)DBasesChangeTo:(Char*)pa_db_name len:(UInt16)uh_db_name_len
		  same:(Boolean)b_current_db
{
  UInt16 uh_form = DBasesListFormIdx;

  // On modifie les préférences générales avant de repasser la
  // main à ce formulaire
  MemMove(oMaTirelire->s_prefs.ra_last_db, pa_db_name, uh_db_name_len);
  oMaTirelire->s_prefs.ra_last_db[uh_db_name_len] = '\0';

  // Nouvelle base
  if ([oMaTirelire newTransaction:nil] != nil
      // AVEC le bon code d'accès si on vient de changer de base
      && (b_current_db || [oMaTirelire passwordCheckDBaseCode]))
    uh_form = AccountsListFormIdx;

  [self gotoFormViaUpdate:uh_form];
}


//
//  Base          >  (>) absent si sous-menu de DBasePopupList
// -----------------
//  Compte1
// #Compte2#########
//  Compte3
// ----------------- vv ssi pas un sous-menu de DBasePopupList
//  Prop du compte
//  Prop de la base
//
- (void)accountsPopupList:(UInt16)uh_list in:(MemHandle*)ppv_popup_accounts
		     from:(Transaction*)oTransactions
	  calledAsSubMenu:(Boolean)b_is_sub_menu
{
  Char ra_db_name[dmDBNameLength];
  UInt16 uh_id, uh_form;

  if (*ppv_popup_accounts == NULL)
  {
    struct s_tr_accounts_list s_infos;

    s_infos.h_skip_account = -1;
    s_infos.uh_checked_accounts = 0;

    // Nom de la base
    StrCopy(s_infos.ra_first_item,
	    db_list_visible_name([oTransactions getName:ra_db_name]));

    // Si on est dans un sous-menu c'est qu'on vient d'ici, donc on ne
    // remet pas la flèche de sous-menu
    if (b_is_sub_menu)
    {
      s_infos.uh_before_last = 0;
      s_infos.uh_last = 0;
    }
    else
    {
      StrCat(s_infos.ra_first_item, ">");

      s_infos.uh_before_last = strTransListAccountProp;
      s_infos.uh_last = strAccountsListDBProp;
    }

    *ppv_popup_accounts =
      [oTransactions popupListInit:uh_list
		     form:(BaseForm*)self
		     infos:&s_infos
		     selectedAccount:[oTransactions getPrefs]->ul_cur_category];
    if (*ppv_popup_accounts == NULL)
      return;
  }

  // En cas d'erreur on rebasculera sur l'écran de la liste des bases
  uh_form = DBasesListFormIdx;

  uh_id = [oTransactions popupList:*ppv_popup_accounts
			 firstIsValid:false];
  switch (uh_id)
  {
  case noListSelection:
    return;

    // Gestion des comptes de la base...
  case ACC_POPUP_FIRST:
    // Cascade du sous-menu seulement si on n'est pas déjà le sous-menu...
    if (b_is_sub_menu == false)
    {
      RectangleType s_rect;
      UInt16 uh_x, uh_dummy;
      Boolean b_dummy;

      // Coordonnées de la liste
      FrmGetObjectBounds(self->pt_frm,
			 FrmGetObjectIndex(self->pt_frm, uh_list),
			 &s_rect);

      EvtGetPen(&uh_x, &uh_dummy, &b_dummy);

      if (uh_x > s_rect.topLeft.x + s_rect.extent.x - 10)
      {
	MemHandle pv_db_list = NULL;

	// Ici on utilise toujours TransListDBases puisque le seul cas
	// où on n'est pas un sous-menu ne peut intervenir que dans
	// TransListForm
	[self DBasesPopupList:TransListDBases in:&pv_db_list
	      calledAsSubMenu:true];

	if (pv_db_list != NULL)
	  MemHandleFree(pv_db_list);

	return;
      }
    }
    else
    {
      // Quand on est dans un sous-menu ET qu'il s'agit de la base
      // courante, on ne fait rien car on est déjà dans
      // AccountsListForm dans ce cas.
       if ([oMaTirelire transaction] == oTransactions)
	 return;
    
       [oMaTirelire newTransaction:oTransactions];

       // Vérification du code d'accès
       if ([oMaTirelire passwordCheckDBaseCode] == false)
	 break;
    }

    uh_form = AccountsListFormIdx;
    break;

  // Propriétés du compte (ne peut pas être sélectionné dans un sous-menu)
  case ACC_POPUP_BEFORE_LAST:
    FrmPopupForm(AccountPropFormIdx);
    return;

    // Propriété de la base (ne peut pas être sélectionné dans un sous-menu)
  case ACC_POPUP_LAST:
    FrmPopupForm(DBasePropFormIdx);
    return;

    // Sélection d'un compte
  default:
    // On est toujours dans la même base
    if (oTransactions == [oMaTirelire transaction])
    {
      // Si on est pas dans un sous-menu ET que le compte ne change
      // pas, on arrête ici
      if (b_is_sub_menu == false
	  && uh_id == oTransactions->ps_prefs->ul_cur_category)
	return;

      oTransactions->ps_prefs->ul_cur_category = uh_id;
    }
    // La base des comptes n'est pas celle en cours
    else
    {
      oTransactions->ps_prefs->ul_cur_category = uh_id;

      [oMaTirelire newTransaction:oTransactions];

      // Vérification du code d'accès
      if ([oMaTirelire passwordCheckDBaseCode] == false)
	break;
    }

    uh_form = TransListFormIdx;
    break;
  }

  [self gotoFormViaUpdate:uh_form];
} // accountsPopupList

@end
