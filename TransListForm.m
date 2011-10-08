/* 
 * TransListForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Tue Mar 23 19:45:26 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Dec  7 18:17:45 2007
 * Update Count    : 74
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: TransListForm.m,v $
 * Revision 1.18  2008/01/14 15:43:29  max
 * Switch to new mcc.
 *
 * Revision 1.17  2006/10/05 19:08:55  max
 * Handle new MiniStatsForm.
 *
 * Revision 1.16  2006/06/28 09:41:32  max
 * SumScrollList +newInForm: prototype changed.
 * Now call SumScrollList -updateWithoutRedraw.
 *
 * Revision 1.15  2006/06/23 13:24:53  max
 * No more need of fiveway.h with PalmSDK installed.
 * Add new Palm 5-way handling.
 *
 * Revision 1.14  2006/04/25 08:47:44  max
 * Don't take into account vchrHardPower char in hard keys handling.
 * Redraws reworked (continue).
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 * -warningOverdrawn: prototype changed.
 *
 * Revision 1.13  2005/11/19 16:56:36  max
 * Redraws reworked.
 * New RepeatsListForm screen can be called via menu.
 * When transforming flagged to checked with statement number handling
 * enabled in account properties, statement number is queried via
 * StatementNumForm dialog.
 *
 * Revision 1.12  2005/10/11 19:12:07  max
 * ClearingIntroForm called from menu.
 * TransForm macros shortcuts deported to SumListForm.m.
 *
 * Revision 1.11  2005/10/06 19:48:19  max
 * Add SearchForm.
 *
 * Revision 1.10  2005/08/20 13:07:10  max
 * Now use +newInForm: method of SumScrollList.
 * Flagged screen is now implemented.
 * No need to treat frmMaTiUpdateListCurrencies here.
 * Don't display the overdrawn account alert when a frmGotoEvent is pending.
 *
 * Revision 1.9  2005/05/18 20:00:04  max
 * uh_overdrawn attibute can now have 3 states, so overdrawn account
 * feature changed.
 *
 * Revision 1.8  2005/05/08 12:13:07  max
 * Stats menu entry calls StatsForm.
 * Move accounts popup list management to MaTiForm.m
 *
 * Revision 1.7  2005/03/27 15:38:27  max
 * Can now go to accounts databases list screen.
 *
 * Revision 1.6  2005/03/20 22:28:28  max
 * Add overdrawn account management
 * Add alarm management
 *
 * Revision 1.5  2005/03/02 19:02:46  max
 * Add PurgeForm call.
 * Add progress bars for slow operations.
 *
 * Revision 1.4  2005/02/21 20:43:35  max
 * Add InvertPage & InvertAll menu entries.
 *
 * Revision 1.3  2005/02/19 17:09:46  max
 * Some menu entries implemented.
 * Go to first/next buttons are working now with long clic
 * configuration popup menu.
 * If M2 is bound to a hard key, this hard key cycles accounts.
 * Add "DB properties" entry in the accounts popup menu.
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

#include <Common/System/palmOneNavigator.h>

#define EXTERN_TRANSLISTFORM
#include "TransListForm.h"

#include "MaTirelire.h"

#include "CustomListForm.h"
#include "TransScrollList.h"
#include "MiniStatsForm.h"

#include "ProgressBar.h"

#include "alarm.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX

#include "graph_defs.h"

#define TopIconsWidth	(6 + 10 + 11 + 11 + 11) // 6 = marge avec le titre
#define MaxTitleWidth	(160 - TopIconsWidth)

// Dans PalmResize/resize.c
extern void UniqueUpdateForm(UInt16 formID, UInt16 code);


@implementation TransListForm

- (TransListForm*)free
{
  // Libération de la liste des comptes (marche même si NULL)
  // On passe par la méthode de classe, car il se peut que
  // [oMaTirelire transaction] vaille nil dans le cas où le passage à
  // une nouvelle base, via le menu des bases, a échoué
  [Transaction classPopupListFree:self->pv_popup_accounts];

  return [super free];
}


- (Boolean)open
{
  struct s_mati_prefs *ps_prefs;
  struct s_db_prefs *ps_db_prefs;

  // No last statement number at this time
  gui_last_stmt_num = 0;

  self->oList = (SumScrollList*)[TransScrollList newInForm:(BaseForm*)self];

  ps_db_prefs = [[oMaTirelire transaction] getPrefs];

  ps_prefs = [oMaTirelire getPrefs];

  // Nom de la base + nom du compte dans le titre
  [self displayPopupTitle:NULL maxWidth:MaxTitleWidth];

  // Type de somme
  [self sumTypeWidgetChange];

  // Le cadenas
  CtlSetValue([self objectPtrId:TransListToggleCheck],
	      ps_db_prefs->ul_check_locked);

  [super open];

  // On affiche le bitmap du popup
  [self displayPopupBitmap];

  // Gestion du découvert
  [self warningOverdrawn:true];

  // Au prochain lancement on reviendra sur cet écran...
  ps_prefs->ul_first_form = FIRST_FORM_TRANS;

  return true;
}


#define POPUP_TITLE_SEP		'/'
#define POPUP_TITLE_ACC_PERCENT	80 // % de la place pour le nom du compte
- (void)displayPopupTitle:(Char*)pa_db_name maxWidth:(UInt16)uh_max_width
{
  Transaction *oTransactions = [oMaTirelire transaction];
  Char ra_account_name[dmCategoryLength];
  Char ra_tmp[POPUP_SPACE_WIDTH + dmDBNameLength + dmCategoryLength];
  Char *pa_cur;
  FontID uh_cur_font;
  UInt16 uh_db_len, uh_account_len;
  UInt16 uh_db_width, uh_account_width, uh_add_width;

  // Le nom de la base
  pa_db_name = db_list_visible_name([oMaTirelire getPrefs]->ra_last_db);

  // Le nom du compte
  CategoryGetName(oTransactions->db, [oTransactions getPrefs]->ul_cur_category,
		  ra_account_name);

  uh_db_len = StrLen(pa_db_name);
  uh_account_len = StrLen(ra_account_name);

  uh_cur_font = FntSetFont(boldFont);

  uh_db_width = FntCharsWidth(pa_db_name, uh_db_len);
  uh_account_width = FntCharsWidth(ra_account_name, uh_account_len);
  uh_add_width = (FntCharWidth(' ') * POPUP_SPACE_WIDTH
		  + FntCharWidth(POPUP_TITLE_SEP));

  MemSet(ra_tmp, POPUP_SPACE_WIDTH, ' ');
  pa_cur = &ra_tmp[POPUP_SPACE_WIDTH];

  // On recopie le nom de la base
  MemMove(pa_cur, pa_db_name, uh_db_len);

  // Le tout ne contient pas
  if (uh_db_width + uh_account_width + uh_add_width > uh_max_width)
  {
    UInt16 uh_max_part_width;

    // Taille réservée pour le nom du compte
    uh_max_part_width = ((uh_max_width - uh_add_width)
			 * POPUP_TITLE_ACC_PERCENT) / 100;

    // Le nom de la base est si petit, qu'il peut en avoir plus
    if (uh_db_width + uh_add_width < uh_max_width - uh_max_part_width)
      uh_max_part_width = uh_max_width - (uh_db_width + uh_add_width);

    // Le nom du compte ne contient pas dans sa place imposée
    if (uh_account_width > uh_max_part_width)
    {
      truncate_name(ra_account_name, &uh_account_len, uh_max_part_width,
		    ra_account_name);

      uh_account_width = FntCharsWidth(ra_account_name, uh_account_len);
    }

    // Il faut réduire le nom de la base
    uh_max_part_width = uh_max_width - uh_add_width - uh_account_width;
    if (uh_db_width > uh_max_part_width)
      truncate_name(pa_cur, &uh_db_len, uh_max_part_width, pa_cur);
  }

  FntSetFont(uh_cur_font);

  // Le séparateur
  pa_cur += uh_db_len;
  *pa_cur++ = POPUP_TITLE_SEP;

  // Le compte
  MemMove(pa_cur, ra_account_name, uh_account_len + 1); // Avec \0

  FrmCopyTitle(self->pt_frm, ra_tmp);
}


- (void)redrawForm
{
  [super redrawForm];

  // On affiche le bitmap du popup
  [self displayPopupBitmap];
}


- (Boolean)menu:(UInt16)uh_id
{
  if ([super menu:uh_id])
    return true;

  switch (uh_id)
  {
  case TransListMenuClearing:
    FrmPopupForm(ClearingIntroFormIdx);
    break;

  case TransListMenuClearDel:
    FrmPopupForm(PurgeFormIdx);
    break;

  case TransListMenuViewRepeats:
    FrmPopupForm(RepeatsListFormIdx);
    break;

  case TransListMenuAllDel:
    if (self->oList->uh_num_items > 1 && FrmAlert(alertDeleteAll) != 0)
    {
      Transaction *oTransactions = [oMaTirelire transaction];
      MemHandle vh_rec;
      PROGRESSBAR_DECL;
      UInt16 uh_account = oTransactions->ps_prefs->ul_cur_category;
      UInt16 uh_record_num = 0, uh_reschedule_alarm = 0;
      Boolean b_delete, b_use_conduit;

      // Pour la barre de progression
      b_use_conduit = oTransactions->ps_prefs->ul_remove_type;

      PROGRESSBAR_BEGIN(DmNumRecords(oTransactions->db),
			strProgressBarDeleteAllInAccount);

      while ((vh_rec = DmQueryNextInCategory(oTransactions->db,	// PG
					     &uh_record_num,
					     uh_account)) != NULL)
      {
	// Pas les propriétés du compte...
	b_delete = DateToInt(((struct s_transaction*)MemHandleLock(vh_rec))
			     ->s_date) != 0;
	MemHandleUnlock(vh_rec);

	if (b_delete)
	{
	  // Pas de suppression des liens
	  uh_reschedule_alarm	// Alarme OK
	    |= [oTransactions deleteId:((UInt32)uh_record_num
					| TR_DEL_MANAGE_ALARM
					| TR_DEL_DONT_RESCHED_ALARM)];

	  // Si l'opération est supprimée immédiatement
	  if (b_use_conduit == false)
	  {
	    PROGRESSBAR_DECMAX;
	    goto next_all_del;	// On n'incrémente pas...
	  }
	}

	uh_record_num++;

    next_all_del:
	PROGRESSBAR_INLOOP(uh_record_num, 50); // XXX normalement avant ++
      }

      PROGRESSBAR_END;

      // Redraw
      [self->oList update];	// OK

      // On place la prochaine alarme, car elle vient d'être
      // désactivée par un des -deleteId: qui ont précédé
      if (uh_reschedule_alarm & TR_DEL_MUST_RESCHED_ALARM)
	alarm_schedule_all();
    }
    break;

    // Propriétés du compte
  case TransListMenuProperties:
    FrmPopupForm(AccountPropFormIdx);
    break;

    // Propriété de la base
  case TransListMenuDBProperties:
    FrmPopupForm(DBasePropFormIdx);
    break;

  case TransListMenuAccounts:
    [self gotoFormViaUpdate:AccountsListFormIdx];
    break;

  case TransListMenuDBases:
    [self gotoFormViaUpdate:DBasesListFormIdx];
    break;

  case TransListMenuMark:
    FrmPopupForm(SearchFormIdx);
    break;

  case TransListMenuMarkPage:
  case TransListMenuUnmarkPage:
    [(TransScrollList*)
      self->oList
      flagUnflag:(uh_id == TransListMenuUnmarkPage
		  ? SCROLLLIST_FLAG_UNFLAG | SCROLLLIST_FLAG_PAGE
		  : SCROLLLIST_FLAG_FLAG | SCROLLLIST_FLAG_PAGE)];
    break;

  case TransListMenuUnmarkAll:
    [(TransScrollList*)self->oList flagUnflag:SCROLLLIST_FLAG_UNFLAG];
    break;

  case TransListMenuInvertPage:
  case TransListMenuInvertAll:
    [(TransScrollList*)
      self->oList
      flagUnflag:(uh_id == TransListMenuInvertPage
		  ? SCROLLLIST_FLAG_INVERT | SCROLLLIST_FLAG_PAGE
		  : SCROLLLIST_FLAG_INVERT)];
    break;

  case TransListMenuMarkedToChecked:
    if (self->oList->uh_num_items > 0 && FrmAlert(alertMarkedToChecked) != 0)
    {
      Transaction *oTransactions = [oMaTirelire transaction];
      struct s_account_prop *ps_prop;
      Boolean b_stmt_num;

      ps_prop = [oTransactions accountProperties:ACCOUNT_PROP_CURRENT
			       index:NULL];
      b_stmt_num = ps_prop->ui_acc_stmt_num;
      MemPtrUnlock(ps_prop);

      // Gestion des numéros de relevé
      if (b_stmt_num)
	FrmPopupForm(StatementNumFormIdx);
      // Sans gestion de numéro de relevé...
      else
      {
	// Au moins une opération a été modifiée
	if ([oTransactions changeFlaggedToChecked:0])
	{
	  // Redraw
	  [self->oList redrawList];

	  // On ne recalcule la somme que si le type de somme le nécessite...
	  switch (oTransactions->ps_prefs->ul_sum_type)
	  {
	    // les types de sommes qui dépendent des marqués OU des
	    // pointés Pas VIEW_CHECKNMARKED, puisque dans ce cas la
	    // somme ne change pas
	  case VIEW_WORST:
	  case VIEW_CHECKED:
	  case VIEW_MARKED:
	    [self->oList computeSum];
	    [self->oList displaySum];
	    break;
	  }
	}
      }
    }
    break;

  case TransListMemuMarkView:
    FrmPopupForm(CustomListFormIdx | CLIST_SUBFORM_TRANS_FLAGGED);
    break;

  case TransListMenuMarkDel:
    if (self->oList->uh_num_items > 1 && FrmAlert(alertDeleteMarked) != 0)
    {
      Transaction *oTransactions = [oMaTirelire transaction];
      MemHandle vh_rec;
      struct s_transaction *ps_tr;
      PROGRESSBAR_DECL;
      UInt16 uh_account = oTransactions->ps_prefs->ul_cur_category;
      UInt16 uh_record_num = 0, uh_rechedule_alarm = 0;
      Boolean b_delete, b_one_deleted = false, b_use_conduit;

      // Pour la barre de progression
      b_use_conduit = oTransactions->ps_prefs->ul_remove_type;

      PROGRESSBAR_BEGIN(DmNumRecords(oTransactions->db),
			strProgressBarDeleteFlagged);

      while ((vh_rec = DmQueryNextInCategory(oTransactions->db,	// PG
					     &uh_record_num,
					     uh_account)) != NULL)
      {
	ps_tr = MemHandleLock(vh_rec);

	// Pas un compte ET opération marquée
	b_delete = (DateToInt(ps_tr->s_date) != 0
		    && (ps_tr->ui_rec_flags & RECORD_MARKED) != 0);

	MemHandleUnlock(vh_rec);

	if (b_delete)
	{
	  // Suppression des liens : identique au bouton "Suppression"
	  uh_rechedule_alarm	// Alarme OK
	    |= [oTransactions deleteId:(uh_record_num
					| TR_DEL_XFER_LINK_TOO
					| TR_DEL_MANAGE_ALARM
					| TR_DEL_DONT_RESCHED_ALARM)];
	  b_one_deleted = true;

	  // Si l'opération est supprimée immédiatement
	  if (b_use_conduit == false)
	  {
	    PROGRESSBAR_DECMAX;	// XXX Devrait être appelé 2 fois si Xfer...
	    goto next_flag_del;	// On n'incrémente pas...
	  }
	}

	uh_record_num++;

    next_flag_del:
	PROGRESSBAR_INLOOP(uh_record_num, 50); // XXX normalement avant ++
      }

      PROGRESSBAR_END;

      // Au moins une opération a été supprimée
      if (b_one_deleted)
      {
	// Redraw
	[self->oList update];	// OK
      
	// On place la prochaine alarme, car elle vient d'être
	// désactivée par un des -deleteId: qui ont précédé
	if (uh_rechedule_alarm & TR_DEL_MUST_RESCHED_ALARM)
	  alarm_schedule_all();
      }
    }
    break;

  case TransListMenuGotoFirstNotChecked ... TransListMenuGotoDate:
    [self->oList goto:(uh_id - TransListMenuGotoBase
		       + SCROLLLIST_GOTO_FIRST_BASE)];
    break;

  case TransListMenuStats:
    FrmPopupForm(StatsFormIdx);
    break;

  case TransListMenuMiniStats:
    FrmPopupForm(MiniStatsFormIdx);
    break;

  default:
    return false;
  }

  return true;
}


static void __ctl_select(ControlType *ps_ctl, Boolean b_selected)
{
  CtlSetValue(ps_ctl, b_selected);

  CtlDrawControl(ps_ctl);

  // Sur les OS <= 3.1 il faut redessiner 2 fois pour avoir le bon effet...
  if (oMaTirelire->ul_rom_version <= 0x03103000)
    CtlDrawControl(ps_ctl);
}


- (Boolean)ctlEnter:(struct ctlEnter *)ps_enter
{
  switch (ps_enter->controlID)
  {
  case TransListGotoFirst:
  case TransListGotoNext:
  {
    ControlType *ps_ctl = [self objectPtrId:ps_enter->controlID];
    RectangleType s_bounds;
    UInt32 ui_last_tick;
    UInt16 x, y;
    Boolean b_selected = false, b_pen_down = true;

    FrmGetObjectBounds(self->pt_frm,
		       FrmGetObjectIndex(self->pt_frm, ps_enter->controlID),
		       &s_bounds);

    ui_last_tick = TimGetTicks();

    while (EvtGetPen(&x, &y, &b_pen_down), b_pen_down)
    {
      // Si le stylet n'est pas dans la case
      if (RctPtInRectangle(x, y, &s_bounds) == false)
      {
	// La case est sélectionnée
	if (b_selected)
	{
	  // Désélection de la case
	  b_selected = false;

	  __ctl_select(ps_ctl, 0);
	}
      }
      // Stylet dans la case
      else
      {
	// La case n'est pas sélectionnée
	if (b_selected == false)
	{
	  ui_last_tick = TimGetTicks();

	  /* Sélection de la case */
	  b_selected = true;

	  __ctl_select(ps_ctl, 1);
	}
	// Case déjà sélectionnée, on regarde s'il faut afficher les infos
	// c'est à dire si 1/2 seconde s'est écoulée
	else if (TimGetTicks() - ui_last_tick >= (SysTicksPerSecond() >> 1))
	{
	  ListType *pt_list = [self objectPtrId:TransListPrefsFirstNextList];
	  UInt16 uh_choice;

	  LstSetSelection(pt_list, oMaTirelire->s_prefs.ul_firstnext_action);

	  uh_choice = LstPopupList(pt_list);
	  if (uh_choice == noListSelection)
	  {
	    __ctl_select(ps_ctl, 0);
	    return false;
	  }

	  // On sauve dans les préférences
	  oMaTirelire->s_prefs.ul_firstnext_action = uh_choice;

	  break;		// b_selected == true => CtlHitControl à suivre
	}
      }
    }

    if (b_selected)
    {
      __ctl_select(ps_ctl, 0);

      CtlHitControl(ps_ctl);
    }
  }
  return true;
  }

  return [super ctlEnter:ps_enter];
}


- (Boolean)ctlSelect:(struct ctlSelect*)ps_select
{
  if ([super ctlSelect:ps_select])
    return true;

  switch (ps_select->controlID)
  {
  case TransListCredit:
  case TransListDebit:
    [self->oList deselectLine];
    TransFormCall(self->s_trans_form,
		  ps_select->controlID == TransListCredit,
		  0, 0,		// pre_desc
		  0, 0,		// copy
		  -1);
    break;

  case TransListMiniStats:
    FrmPopupForm(MiniStatsFormIdx);
    break;

  case TransListToggleCheck:
    [oMaTirelire transaction]->ps_prefs->ul_check_locked = ps_select->on;
    break;

  case TransListGotoFirst:
  case TransListGotoNext:
    [self->oList goto:(ps_select->controlID == TransListGotoFirst
		       ? SCROLLLIST_GOTO_FIRST_BASE : SCROLLLIST_GOTO_NEXT_BASE)
		      + oMaTirelire->s_prefs.ul_firstnext_action];
    break;

  default:
    return false;
  }

  return true;
}


- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key
{
  if ([super keyDown:ps_key])
    return true;

  // Touche spéciale
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
	Transaction *oTransactions = [oMaTirelire transaction];
	UInt16 uh_next;

	// Il y a un prochain compte
	uh_next = [oTransactions selectNextAccount:true
				 of:oTransactions->ps_prefs->ul_cur_category];
	if (uh_next != dmAllCategories)
	{
	  oTransactions->ps_prefs->ul_cur_category = uh_next;
	  [self gotoFormViaUpdate:TransListFormIdx];
	  return true;
	}
      }
      break;

    case vchrNavChange:		// OK (only 5-way T|T)
      if (ps_key->modifiers & autoRepeatKeyMask)
	break;

      // On regarde le navigator pour dérouler le menu des comptes
      if ((ps_key->keyCode & (navBitsAll | navChangeBitsAll))
	  == (navBitRight | navChangeRight))
      {
	[self penDown:NULL];
	return true;
      }
      break;

      // De NavDirectionHSPressed()
    case vchrRockerRight:
      if (ps_key->modifiers & commandKeyMask)
      {
	[self penDown:NULL];
	return true;
      }
      break;
    }

    return false;
  }

  // On recherche si une macro existe avec ce raccourci
  return [self transFormShortcut:ps_key listID:TransListDescList
	       args:&self->s_trans_form];
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  switch (UPD_CODE(ps_update->updateCode))
  {
    Boolean b_list_erase, b_force_redraw;

  case frmMaTiUpdateList:
    // Il y a eu un changement de compte dans TransForm
    if (ps_update->updateCode & frmMaTiChangeAccount)
    {
      [self gotoFormViaUpdate:TransListFormIdx];

      // Dans ce cas précis, on se fout des autres flags puisqu'on va
      // complètement redémarrer le formulaire
      goto done;
    }

    b_list_erase = false;
    b_force_redraw = false;

    // Les propriétés de la base OU du compte ont changé
    if (ps_update->updateCode & (frmMaTiUpdateListDBases
				 | frmMaTiUpdateListAccounts))
    {
      // Nom de la base + nom du compte dans le titre
      [self displayPopupTitle:NULL maxWidth:MaxTitleWidth];

      b_list_erase = true;
    }

    // La liste des comptes a changé (les propriétés du compte courant
    // ont changé)
    if (ps_update->updateCode & frmMaTiUpdateListAccounts)
    {
      // Libération de la liste des comptes (marche même si NULL,
      // normalement jamais à NULL puisque AccountsPropForm a été
      // appelé de là)
      [[oMaTirelire transaction] popupListFree:self->pv_popup_accounts];
      self->pv_popup_accounts = NULL;

      // On réinitialise la somme
      [self->oList computeSum];
      [self->oList displaySum];

      // b_list_erase déjà à true avec le précédent test (les
      // propriétés de la base OU du compte ont changé)

      // Gestion du découvert
      b_force_redraw = [self warningOverdrawn:false];
    }

    // Une opération a été ajoutée ou supprimée ou modifiée
    if (ps_update->updateCode & frmMaTiUpdateListTransactions)
    {
      UInt16 uh_index;

      uh_index = (ps_update->updateCode >> 16);
      if (uh_index > 0)
	// Il faut que l'opération, que l'on vient d'éditer, soit visible
	[self->oList setCurrentItem:uh_index | SCROLLLIST_CURRENT_DONT_RELOAD];

      [self->oList updateWithoutRedraw];

      b_list_erase = true;

      // Gestion du découvert
      b_force_redraw = [self warningOverdrawn:false];
    }

    // Les types ont changé, il faut juste rafraîchir la liste car
    // parfois le type est présent en lieu et place de la description
    if (b_list_erase || (ps_update->updateCode & frmMaTiUpdateListTypes))
    {
      // On efface le contenu de la liste, le redraw de retour sur
      // notre écran fera le reste
      TblEraseTable(self->oList->pt_table);

      // Il y a eu l'affichage de la boîte d'alerte de découvert, il
      // faut redessiner
      if (b_force_redraw)
	UniqueUpdateForm(FrmGetFormId(self->pt_frm), frmRedrawUpdateCode);
    }

    break;
  }

 done:
  return [super callerUpdate:ps_update];
}


- (Boolean)penDown:(EventType*)e
{
  // Pas besoin de FrmPointInTitle(), car si screenX <= 12 alors
  // forcément on est dans le titre...
  if (e == NULL || (e->screenX <= 12 && e->screenY <= 14))
  {
    [self accountsPopupList:TransListAccounts
	  in:&self->pv_popup_accounts
	  from:[oMaTirelire transaction]
	  calledAsSubMenu:false];
    return true;
  }

  return false;
}


- (void)transactionDateEdit:(UInt16)uh_rec_index
{
  Transaction *oTransactions = [oMaTirelire transaction];
  MemHandle vh_rec;
  struct s_transaction *ps_tr, *ps_new;
  DateType s_old_date;
  UInt16 uh_size;

  vh_rec = DmQueryRecord(oTransactions->db, uh_rec_index); // PAS DE TEST
  ps_tr = MemHandleLock(vh_rec);
  uh_size = MemHandleSize(vh_rec);

  NEW_PTR(ps_new, uh_size, return);

  MemMove(ps_new, ps_tr, uh_size);
  s_old_date = ps_tr->s_date;

  MemHandleUnlock(vh_rec);

  if ([self dateSelect:OpDate date:&ps_new->s_date]
      && DateToInt(ps_new->s_date) != DateToInt(s_old_date))
  {
    UInt16 uh_new_index = uh_rec_index;

    if ([oTransactions save:ps_new size:uh_size asId:&uh_new_index
		       account:-1 xferAccount:-1] == false)
    {
      // XXX
    }
    else
    {
      // Gestion de l'alarme
      if (alarm_schedule_transaction(oTransactions->db, uh_new_index, false))
	alarm_schedule_all();

      // Si l'opération est à répéter, on tente tout de suite
      if ([oTransactions computeRepeatsOfId:uh_new_index])
      {
	// Au moins une opération en plus

	// L'enregistrement a changé de position
	if (uh_new_index != uh_rec_index)
	  [self->oList
	       setCurrentItem:uh_new_index | SCROLLLIST_CURRENT_DONT_RELOAD];

	[self->oList updateWithoutRedraw];
      }
      // Pas d'opération en plus...
      else
      {
	// L'enregistrement a changé de position
	if (uh_new_index != uh_rec_index)
	  [self->oList setCurrentItem:uh_new_index];
      }
    }
  }

  MemPtrFree(ps_new);

  // On redessine le formulaire
  UniqueUpdateForm(FrmGetFormId(self->pt_frm), frmRedrawUpdateCode);
}


- (void)transactionTimeEdit:(UInt16)uh_rec_index
{
  Transaction *oTransactions = [oMaTirelire transaction];
  MemHandle vh_rec;
  struct s_transaction *ps_tr, *ps_new;
  TimeType s_old_time;
  UInt16 uh_size;
  Boolean b_dialog3;

  vh_rec = DmQueryRecord(oTransactions->db, uh_rec_index); // PAS DE TEST
  ps_tr = MemHandleLock(vh_rec);
  uh_size = MemHandleSize(vh_rec);

  NEW_PTR(ps_new, uh_size, return);

  MemMove(ps_new, ps_tr, uh_size);
  s_old_time = ps_tr->s_time;

  MemHandleUnlock(vh_rec);

  b_dialog3 = [oMaTirelire getPrefs]->ul_time_select3;

  if ([self timeSelect:OpTime time:&ps_new->s_time dialog3:b_dialog3]
      && TimeToInt(ps_new->s_time) != TimeToInt(s_old_time))
  {
    UInt16 uh_new_index = uh_rec_index;

    if ([oTransactions save:ps_new size:uh_size asId:&uh_new_index
		       account:-1 xferAccount:-1] == false)
    {
      // XXX
    }
    else
    {
      // Gestion de l'alarme
      if (alarm_schedule_transaction(oTransactions->db, uh_new_index, false))
	alarm_schedule_all();

      // L'enregistrement a changé de position
      if (uh_new_index != uh_rec_index)
	[self->oList setCurrentItem:uh_new_index];
    }
  }

  MemPtrFree(ps_new);

  // On redessine le formulaire
  UniqueUpdateForm(FrmGetFormId(self->pt_frm), frmRedrawUpdateCode);
}


- (struct s_trans_form_args*)transFormArgs
{
  return &self->s_trans_form;
}


- (Boolean)warningOverdrawn:(Boolean)b_reset
{
  Transaction *oTransactions = [oMaTirelire transaction];
  struct s_account_prop *ps_prop;
  Boolean b_displayed = false;

  ps_prop = [oTransactions accountProperties:ACCOUNT_PROP_CURRENT index:NULL];

  // Le compte est à découvert !
  if (self->oList->l_sum < ps_prop->l_overdraft_thresold)
  {
    // On n'a pas encore affiché la boîte OU arrivée sur nouveau compte
    if (self->uh_overdrawn != TLIST_OD_OVERDRAWN || b_reset)
    {
      if (ps_prop->ui_acc_warning
	  // Pas d'événement Goto en cours
	  && oMaTirelire->b_goto_event_pending == false)
      {
	FrmAlert(alertOverdrawnAccount);
	b_displayed = true;
      }

      self->uh_overdrawn = TLIST_OD_OVERDRAWN;
    }
  }
  // Le compte n'est plus à découvert
  else if (self->oList->l_sum >= ps_prop->l_non_overdraft_thresold)
  {
    // On n'a pas encore affiché la boîte
    if (self->uh_overdrawn != TLIST_OD_NON_OVERDRAWN)
    {
      // Si arrivée sur nouveau compte on ne dit rien
      if (ps_prop->ui_acc_warning && b_reset == false
	  // Pas d'événement Goto en cours
	  && oMaTirelire->b_goto_event_pending == false)
      {
	FrmAlert(alertNoOverdrawnAccount);
	b_displayed = true;
      }

      self->uh_overdrawn = TLIST_OD_NON_OVERDRAWN;
    }
  }
  // Entre les deux...
  else
    self->uh_overdrawn = TLIST_OD_BETWEEN;

  MemPtrUnlock(ps_prop);

  return b_displayed;
}


- (void)sumTypeChange
{
  [self warningOverdrawn:false];
}

@end
