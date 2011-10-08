/* 
 * SumListForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Jeu nov 18 21:55:19 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Jan 22 11:45:45 2008
 * Update Count    : 38
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: SumListForm.m,v $
 * Revision 1.14  2008/02/01 17:22:34  max
 * Now use macros computeAgainEachEntrySum and
 * computeAgainEachEntryConvertSum.
 *
 * Revision 1.13  2008/01/14 15:58:52  max
 * Switch to new mcc.
 * backspaceChr and chrEscape equal to "Back" button press.
 *
 * Revision 1.12  2006/11/04 23:48:19  max
 * TransFormCallFull() changes.
 *
 * Revision 1.11  2006/06/28 09:47:44  max
 * Fix comment typo when using mcc.
 *
 * Revision 1.10  2006/06/28 09:42:04  max
 * Rework TransForm call when <0-9,.> char typed in list.
 *
 * Revision 1.9  2006/06/19 12:24:09  max
 * AboutForm calls from menu are now handled by MaTiForm.
 *
 * Revision 1.8  2006/04/25 08:47:23  max
 * Correct bug when screen is resized in full screen.
 *
 * Revision 1.7  2005/11/19 16:56:34  max
 * Redraws reworked.
 * -dateSet:date:format: can now have super class behavior if date button
 * is not SumListSumTypePopup.
 *
 * Revision 1.6  2005/10/11 19:12:03  max
 * Now handle TransForm shortcuts.
 * Export feature added to generic menu handler.
 *
 * Revision 1.5  2005/10/06 20:23:54  max
 * s/-computeAllRepeats/-computeAllRepeats:/ and force.
 *
 * Revision 1.4  2005/08/20 13:07:05  max
 * Updates are now genericaly managed by MaTiForm.
 * Currencies popup can now be managed here.
 *
 * Revision 1.3  2005/03/20 22:28:24  max
 * Add -sumTypeChange for subclasses use
 *
 * Revision 1.2  2005/02/19 17:10:17  max
 * Sum copy & repeats computation imported.
 *
 * Revision 1.1  2005/02/09 22:57:23  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_SUMLISTFORM
#include "SumListForm.h"

#include <PalmOSGlue/FrmGlue.h>
#include <PalmOSGlue/CtlGlue.h>

#include "MaTirelire.h"
#include "DescModesListForm.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


@implementation SumListForm

- (SumListForm*)free
{
  // Dans le cas où on a un popup des devises (marche même si NULL)
  [[oMaTirelire currency] popupListFree:self->pv_popup_currencies];

  [self->oList free];

  return [super free];
}


- (Boolean)menu:(UInt16)uh_id
{
  // La sélection d'un item dans le menu annule la sélection courante
  [self->oList deselectLine];

  // Est-ce vraiment nécessaire ??? XXXX
  if ([super menu:uh_id])
    return true;

  switch (uh_id)
  {
  case SumListMenuCopy:
  {
    FieldType *pt_field;
    UInt16 uh_start, uh_end;

    pt_field = [self objectPtrId:SumListSum];

    FldGetSelection(pt_field, &uh_start, &uh_end);

    // Pas de sélection : on sélectionne tout le champ
    if (uh_start == uh_end)
      FldSetSelection(pt_field, 0, FldGetTextLength(pt_field));

    // Copie
    FldCopy(pt_field);

    // On ré-annule la sélection si on n'en avait pas avant
    if (uh_start == uh_end)
      FldSetSelection(pt_field, 0, 0);
  }
  break;

  case SumListMenuTypes:
    FrmPopupForm(TypesListFormIdx);
    break;

  case SumListMenuModes:
    FrmPopupForm(ModesListFormIdx);
    break;

  case SumListMenuDesc:
    FrmPopupForm(DescListFormIdx);
    break;

  case SumListMenuCurr:
    FrmPopupForm(CurrenciesListFormIdx);
    break;

  case SumListMenuPrefs:
    FrmPopupForm(PrefsFormIdx);
    break;

  case SumListMenuRepeat:
    if ([[oMaTirelire transaction] computeAllRepeats:true onMaxDays:0])
      [self->oList update];	// OK
    break;

  case SumListExport:
    if ([self->oList exportFormat:NULL])
      FrmPopupForm(ExportFormIdx);
    else
      FrmAlert(alertNotImplementedXXX);
    break;

  default:
    return false;
  }

  return true;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case SumListScrollTop:
    [self->oList goto:SCROLLLIST_GOTO_TOP];
    break;

  case SumListScrollBottom:
    [self->oList goto:SCROLLLIST_GOTO_BOTTOM];
    break;

  case SumListFull:
    [self->oList changeFullZoneInc:12];
    break;

  case SumListSumTypePopup:
  {
    ListType *pt_list = [self objectPtrId:SumListSumTypeList];
    UInt16 uh_index;

    uh_index = LstPopupList(pt_list);
    if (uh_index != noListSelection)
    {
      Transaction *oTransactions = [oMaTirelire transaction];
      struct s_db_prefs *ps_db_prefs = oTransactions->ps_prefs;

      // Le type de somme a changé
      if (uh_index != ps_db_prefs->ul_sum_type
	  // OU BIEN On était en mode "incrément"
	  || ps_db_prefs->ul_sum_at_date)
      {
	if (uh_index > VIEW_LAST)
	{
	  Boolean b_change_for_today;

	  // On replace la sélection sur la somme courante
	  LstSetSelection(pt_list, ps_db_prefs->ul_sum_type);

	  // Boîte d'édition des dates VIEW_DATE & VIEW_TODAY_PLUS
	  if (uh_index == VIEW_SELECT_DATES)
	  {
	    FrmPopupForm(SumDatesFormIdx);
	    break;
	  }

	  // Date particulière (VIEW_SELECT_AT_DATE)

	  b_change_for_today = false;

	  // Pas encore en mode incrément décrément
	  if (ps_db_prefs->ul_sum_at_date == 0)
	  {
	    DateType s_date;

	    DateToInt(s_date) = [oTransactions sumDate:-1];

	    if (DateToInt(s_date) == 0)
	    {
	      DateSecondsToDate(TimGetSeconds(), &s_date);
	      b_change_for_today = true;
	    }

	    ps_db_prefs->s_sum_date = s_date;
	  }

	  // Choix d'une date
	  if ([self dateInc:SumListSumTypePopup
		    date:&ps_db_prefs->s_sum_date
		    pressedButton:SumListSumTypePopup
		    format:0] == false)
	    break;

	  // On passe en mode incrément décrément
	  ps_db_prefs->ul_sum_at_date = 1;

	  // Il faut changer le type de somme si ce n'est pas une date
	  if (b_change_for_today)
	  {
	    // Si le type de somme n'est pas une date, on bascule
	    // sur aujourd'hui
	    ps_db_prefs->ul_sum_type = VIEW_TODAY;
	    LstSetSelection(pt_list, VIEW_TODAY);
	  }

	  if (b_change_for_today
	      || self->ra_at_date[SUM_LIST_DATE_LEN - 2] != SUM_LIST_DATE_STAR)
	  {
	    // Quelle que soit l'entrée sélectionnée, on réinitialise
	    // notre buffer à date...
	    self->ra_at_date[SUM_LIST_DATE_LEN - 2] = SUM_LIST_DATE_STAR;

	    [self sumTypeWidgetChange];
	  }
	}
	else
	{
	  // On annule le possible mode incrément décrément
	  ps_db_prefs->ul_sum_at_date = 0;

	  // Quelle que soit l'entrée sélectionnée, on réinitialise
	  // notre buffer à date...
	  self->ra_at_date[SUM_LIST_DATE_LEN - 2] = '\0';

	  ps_db_prefs->ul_sum_type = uh_index;
	  DateToInt(ps_db_prefs->s_sum_date)= [oTransactions sumDate:uh_index];

	  [self sumTypeWidgetChange];
	}

	[self->oList computeAgainEachEntrySum];
	[self->oList redrawList];

	// Le type de somme vient de changer
	[self sumTypeChange];
      }
    }
  }
  break;

  // Change la devise d'affichage
  case SumListCurrency:
    [self changeCurrency];
    break;

  default:
    return false;
  }

  return true;
}


- (void)sumTypeChange
{
  // Rien à faire par défaut
}


- (Boolean)ctlRepeat:(struct ctlRepeat *)ps_repeat
{
  switch (ps_repeat->controlID)
  {
  case SumListDateUp:
  case SumListDateDown:
  {
    struct s_db_prefs *ps_db_prefs = [oMaTirelire transaction]->ps_prefs;

    // On n'est pas encore en mode incrément décrément
    if (ps_db_prefs->ul_sum_at_date == 0)
    {
      ps_db_prefs->ul_sum_at_date = 1;

      DateToInt(ps_db_prefs->s_sum_date)
	= [[oMaTirelire transaction] sumDate:-1];
    }

    [self dateInc:SumListSumTypePopup date:&ps_db_prefs->s_sum_date
	  pressedButton:ps_repeat->controlID
	  format:0];

    [self->oList computeAgainEachEntrySum];
    [self->oList redrawList];
  }
  break;
  }

  // On retourne toujours false sinon la répétition s'arrête
  return false;
}


- (Boolean)sclRepeat:(struct sclRepeat *)ps_repeat
{
  [self->oList deselectLine];

  [self->oList scroll:ps_repeat->newValue - ps_repeat->value];
  return false;			// Oui c'est bien false qu'il faut retourner
}


- (Boolean)tblEnter:(EventType*)e
{
  return [self->oList tblEnter:e];
}


- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key
{
  if ([self->oList keyDown:ps_key])
    return true;

  switch (ps_key->chr)
  {
    // Le bouton de sortie, s'il existe...
  case backspaceChr:
  case chrEscape:
  {
    UInt16 uh_index;

    uh_index = FrmGetObjectIndex(self->pt_frm, SumListBack);
    if (uh_index != frmInvalidObjectId
	&& FrmGetObjectType(self->pt_frm, uh_index) == frmControlObj
	&& FrmGlueGetObjectUsable(self->pt_frm, uh_index))
      CtlHitControl(FrmGetObjectPtr(self->pt_frm, uh_index));
  }
  break;
  }

  return false;
}


- (void)sumFieldRepos
{
  RectangleType s_rect_prev, s_rect_next, s_rect_sum;
  UInt16 uh_sum_idx, uh_prev_idx, uh_next_idx;

  uh_sum_idx = FrmGetObjectIndex(self->pt_frm, SumListSum);

  // Le précédent
  uh_prev_idx = uh_sum_idx - 1;
  if (FrmGetObjectType(self->pt_frm, uh_prev_idx) == frmListObj)
    uh_prev_idx--;

  FrmGetObjectBounds(self->pt_frm, uh_prev_idx, &s_rect_prev);

  // Le suivant
  uh_next_idx = uh_sum_idx + 1;
  
  FrmGetObjectBounds(self->pt_frm, uh_next_idx, &s_rect_next);

  // Si on est en mode gaucher et que l'objet à notre droite est le
  // bouton FULL, il faut prendre le bord droit de l'écran comme
  // référence...
  if (self->oList->uh_left_handed
      && FrmGetObjectId(self->pt_frm, uh_next_idx) == SumListFull)
  {
    UInt16 uh_x, uh_dummy;

    WinGetDisplayExtent(&uh_x, &uh_dummy);

    s_rect_next.topLeft.x = uh_x;
  }

  FrmGetObjectBounds(self->pt_frm, uh_sum_idx, &s_rect_sum);

  s_rect_sum.topLeft.x = s_rect_prev.topLeft.x + s_rect_prev.extent.x + 1;
  s_rect_sum.extent.x = s_rect_next.topLeft.x - s_rect_sum.topLeft.x;

  // Si l'objet à droite de la somme n'est pas l'icône FULL, on compte
  // une bordure de 1 pixel en moins
  if (FrmGetObjectId(self->pt_frm, uh_next_idx) != SumListFull)
    s_rect_sum.extent.x--;

  FrmSetObjectBounds(self->pt_frm, uh_sum_idx, &s_rect_sum);

  // Si on a un popup des devises, il faut faire une parade pour un
  // problème d'effacement partiel du bouton full en mode droitier...
  if (self->uh_form_drawn
      && (self->uh_subclasses_flags & SUMLISTFORM_HAS_CURRENCIES_POPUP)
      && self->oList->uh_left_handed == 0)
    CtlDrawControl([self objectPtrId:SumListFull]);
}


//
// Change la valeur de toutes les dates du menu
- (void)sumTypeWidgetReinit:(ListType*)pt_list
{
  Transaction *oTransactions = [oMaTirelire transaction];
  struct s_misc_infos *ps_infos = &oMaTirelire->s_misc_infos;
  UInt16 ruh_items[] = { VIEW_TODAY, VIEW_DATE, VIEW_TODAY_PLUS }, *puh_item;
  UInt16 index;
  DateType s_date;

  for (index = 0, puh_item = ruh_items;
       index < sizeof(ruh_items)/sizeof(ruh_items[0]);
       index++, puh_item++)
  {
    DateToInt(s_date) = [oTransactions sumDate:*puh_item];
    infos_short_date(ps_infos, s_date,
		     LstGetSelectionText(pt_list, *puh_item));
  }
}


//
// Met à jour le bouton popup de la liste des types de somme
- (void)sumTypeWidgetChange
{
  struct s_db_prefs *ps_db_prefs;
  ListType *pt_list;
  Char *pa_label;
  UInt16 uh_popup_idx, uh_popup_x, uh_popup_y, uh_up_x, uh_dummy;

  ps_db_prefs = [oMaTirelire transaction]->ps_prefs;

  pt_list = [self objectPtrId:SumListSumTypeList];

  if (self->uh_form_drawn)
  {
    // On cache les flèches d'incrément/décrément
    [self hideId:bmpDateUp];
    [self hideId:SumListDateUp];
    [self hideId:bmpDateDown];
    [self hideId:SumListDateDown];

    // On cache le champ de la somme qui va peut-être être redimensionné
    [self hideId:SumListSum];
  }
  // Dans le -open (FrmDrawForm() pas encore appelé)
  else
  {
    LstSetDrawFunction(pt_list, list_line_draw);

    // Mise à jour des champs de date de la liste
    [self sumTypeWidgetReinit:pt_list];
  }

  if (ps_db_prefs->ul_sum_at_date)
  {
    pa_label = self->ra_at_date;
    infos_short_date(&oMaTirelire->s_misc_infos,
		     ps_db_prefs->s_sum_date, pa_label);

    pa_label[SUM_LIST_DATE_LEN - 2] = '*';
  }
  else
    pa_label = LstGetSelectionText(pt_list, ps_db_prefs->ul_sum_type);

  CtlSetLabel([self objectPtrId:SumListSumTypePopup], pa_label);

  // L'entrée dans la liste doit être sélectionnée pour la forme
  LstSetSelection(pt_list, ps_db_prefs->ul_sum_type);

  uh_popup_idx = FrmGetObjectIndex(self->pt_frm, SumListSumTypePopup);
  FrmGetObjectPosition(self->pt_frm, uh_popup_idx, &uh_popup_x, &uh_popup_y);
  FrmGetObjectPosition(self->pt_frm,
		       FrmGetObjectIndex(self->pt_frm, SumListDateUp),
		       &uh_up_x, &uh_dummy);

  switch (ps_db_prefs->ul_sum_type)
  {
    // Il faut décaler le bouton de popup après les flèches
  case VIEW_TODAY:
  case VIEW_DATE:
  case VIEW_TODAY_PLUS:
    uh_up_x += 8;
    break;

    // Il faut décaler le popup à la place des flèches (au moins)
  default:
    uh_up_x++;
    break;
  }

  if (uh_popup_x != uh_up_x)
  {
    if (self->uh_form_drawn)
      [self hideIndex:uh_popup_idx];

    FrmSetObjectPosition(self->pt_frm, uh_popup_idx, uh_up_x, uh_popup_y);

    if (self->uh_form_drawn)
      [self showIndex:uh_popup_idx];
  }

  // On redimensionne le champ de la somme
  [self sumFieldRepos];

  // Il faut dessiner
  if (self->uh_form_drawn)
  {
    switch (ps_db_prefs->ul_sum_type)
    {
    case VIEW_TODAY:
    case VIEW_DATE:
    case VIEW_TODAY_PLUS:
      // On fait apparaître les flèches d'incrément/décrément
      [self showId:bmpDateUp];
      [self showId:SumListDateUp];
      [self showId:bmpDateDown];
      [self showId:SumListDateDown];
      break;
    }

    // On refait apparaître le champ de la somme
    [self showId:SumListSum];
  }
  // Dans le -open (FrmDrawForm() pas encore appelé)
  else
  {
    switch (ps_db_prefs->ul_sum_type)
    {
    case VIEW_TODAY:
    case VIEW_DATE:
    case VIEW_TODAY_PLUS:
      break;

    default:
      // On cache les flèches d'incrément/décrément
      [self hideId:bmpDateUp];
      [self hideId:SumListDateUp];
      [self hideId:bmpDateDown];
      [self hideId:SumListDateDown];
      break;
    }
  }
}


// Appelée par -update: avec code frmRedrawUpdateCode
- (void)redrawForm
{
  // La DIA a bougé...
  if (self->uh_display_changed)
  {
    self->uh_form_drawn = false;

    // Si on est en mode gaucher, il faut remettre en place
    if (oMaTirelire->s_prefs.ul_left_handed)
    {
      // Comme il y a eu redessin, on est repassé automatiquement en
      // mode droitier
      self->oList->uh_left_handed = false; // XXX Donc on force XXX

      [self->oList changeHand:true redraw:true];
    }

    // Si on était en mode plein écran, il faut remettre en place
    if (self->oList->uh_full)
    {
      // Comme il y a eu redessin, on est repassé automatiquement en
      // mode écran réduit
      self->oList->uh_full = 0;	// XXX Donc on force XXX

      [self->oList changeFullZoneInc:12];
    }
    else
      [self->oList reinitItemHeight:[oMaTirelire getFontHeight] bounds:NULL];

    // On repositionne la somme et son type
    [self sumTypeWidgetChange];

    self->uh_form_drawn = true;
  }

  [super redrawForm];
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  switch (UPD_CODE(ps_update->updateCode))
  {
  case frmMaTiUpdatePrefs:
    // On est passé en mode gaucher ou on a changé de fonte...
    if (ps_update->updateCode & frmMaTiUpdatePrefsScrList)
    {
      // Soit on change le mode droitier/gaucher, soit la fonte contenue
      // dans la table change
      [self->oList updateHand:oMaTirelire->s_prefs.ul_left_handed
	   height:[oMaTirelire getFontHeight]];
    }
    // On a changé la couleur
    else if (ps_update->updateCode & (frmMaTiUpdatePrefsColors
				      | frmMaTiUpdatePrefsBold))
      // On efface le contenu de la liste, le redraw de retour sur
      // notre écran fera le reste
      TblEraseTable(self->oList->pt_table);
    break;

  case frmMaTiUpdateList:
    // Au moins une des 2 dates mobiles de la liste des types de somme a
    // changé
    if (ps_update->updateCode & frmMaTiUpdateListSumTypes)
    {
      struct s_db_prefs *ps_db_prefs = [oMaTirelire transaction]->ps_prefs;
      ListType *pt_list = [self objectPtrId:SumListSumTypeList];

      // Modification de la liste des types de somme
      [self sumTypeWidgetReinit:pt_list];

      // Si le type de somme en cours est un des deux modifiés, il
      // faut refaire les somme et modifier le popup...
      if (ps_db_prefs->ul_sum_at_date == 0)
	switch (ps_db_prefs->ul_sum_type)
	{
	case VIEW_DATE:
	case VIEW_TODAY_PLUS:
	  CtlSetLabel([self objectPtrId:SumListSumTypePopup],
		      LstGetSelectionText(pt_list, ps_db_prefs->ul_sum_type));

	  [self->oList computeAgainEachEntrySum];

	  // On remplace la somme
	  [self->oList displaySum];

	  // On efface le contenu de la liste, le redraw de retour sur
	  // note écran fera le reste
	  TblEraseTable(self->oList->pt_table);
	  break;
	}
    }

    // La liste des devises a changé
    if ((self->uh_subclasses_flags & SUMLISTFORM_HAS_CURRENCIES_POPUP)
	&& (ps_update->updateCode & frmMaTiUpdateListCurrencies))
      [self updateCurrenciesList];
    break;
  }

  return [super callerUpdate:ps_update];
}


//
// uh_date_id est l'ID du SELECTORTRIGGER contenant la date.
// puh_date est un pointeur sur un DateType contenant la date à positionner.
- (void)dateSet:(UInt16)uh_date_id date:(DateType)s_date
	 format:(DateFormatType)e_format
{
  if (uh_date_id == SumListSumTypePopup)
  {
    struct s_db_prefs *ps_db_prefs = [oMaTirelire transaction]->ps_prefs;
    Boolean b_already_stared;

    b_already_stared = (self->ra_at_date[SUM_LIST_DATE_LEN - 2] == '*');

    infos_short_date(&oMaTirelire->s_misc_infos, s_date, self->ra_at_date);

    if (ps_db_prefs->ul_sum_at_date)
      self->ra_at_date[SUM_LIST_DATE_LEN - 2] = SUM_LIST_DATE_STAR;

    // Il n'y avait pas l'étoile le coup d'avant
    if (b_already_stared == false && ps_db_prefs->ul_sum_at_date)
      [self sumTypeWidgetChange];
    else
      CtlSetLabel([self objectPtrId:SumListSumTypePopup], self->ra_at_date);
  }
  else
    [super dateSet:uh_date_id date:s_date format:e_format];
}


- (void)reloadCurrenciesPopup
{
  Currency *oCurrency = [oMaTirelire currency];

  [oCurrency popupListFree:self->pv_popup_currencies];

  // La devise à utiliser, il faut vérifier qu'elle existe encore
  if ([oCurrency getCachedIndexFromID:self->uh_currency] == ITEM_FREE_ID)
    self->uh_currency = [oCurrency referenceId];

  self->pv_popup_currencies
    = [oCurrency popupListInit:SumListCurrencyList
		 form:self->pt_frm
		 Id:self->uh_currency | ITEM_ADD_EDIT_LINE
		 forAccount:(char*)1];
}


// À appeler avec la devise désirée à la réception d'un
// frmMaTiUpdateListCurrencies
- (void)updateCurrenciesList
{
  [self hideId:SumListSum];

  [self reloadCurrenciesPopup];

  [self sumFieldRepos];

  [self->oList computeAgainEachEntryConvertSum];
  [self->oList redrawList];

  [self showId:SumListSum];
}


// À appeler lors d'un clic sur le popup des devises
- (void)changeCurrency
{
  UInt16 uh_currency;

  [self hideId:SumListSum];

  uh_currency = [[oMaTirelire currency] popupList:self->pv_popup_currencies];

  if (uh_currency != noListSelection)
  {
    if (uh_currency == ITEM_EDIT)
      // On lance la boîte d'édition des devises...
      FrmPopupForm(CurrenciesListFormIdx);
    else
    {
      self->uh_currency = uh_currency;

      [self sumFieldRepos];

      [self->oList computeAgainEachEntryConvertSum];
      [self->oList redrawList];
    }
  }

  [self showId:SumListSum];
}


- (Boolean)transFormShortcut:(struct _KeyDownEventType *)ps_key
		      listID:(UInt16)uh_list
			args:(struct s_trans_form_args*)ps_args
{
  if (ps_key->chr >= ' ' && ps_key->chr <= 0xff)
  {
    Desc *oDesc = [oMaTirelire desc];
    VoidHand pv_popup_macros;
    struct s_desc_popup_infos s_desc_infos;
    UInt16 uh_desc_idx;

    s_desc_infos.uh_account
      = [oMaTirelire transaction]->ps_prefs->ul_cur_category;
    s_desc_infos.uh_flags = DESC_AT_SCREEN_BOTTOM;
    s_desc_infos.ra_shortcut[0] = ps_key->chr;
    s_desc_infos.ra_shortcut[1] = '\0';

    pv_popup_macros = [oDesc popupListInit:uh_list
			     form:self->pt_frm
			     infos:&s_desc_infos];

    uh_desc_idx = [oDesc popupList:pv_popup_macros autoReturn:true];

    [oDesc popupListFree:pv_popup_macros];

    if (uh_desc_idx != noListSelection)
    {
      [self->oList deselectLine];

      TransFormCall(*ps_args,
		    0,
		    1, uh_desc_idx,	// pre_desc
		    0, 0,		// copy
		    -1);
      return true;
    }
  }

  switch (ps_key->chr)
  {
    // Nouvelle opération
  case '+':
  case '-':
    [self->oList deselectLine];
    TransFormCall(*ps_args,
		  ps_key->chr == '+',
		  0, 0,		// pre_desc
		  0, 0,		// copy
		  -1);		// no record index
    return true;

    // Nouvelle opération (débit) avec chiffre pré-saisi
  case '.': case ',': case '0' ... '9':
    [self->oList deselectLine];
    TransFormCallFull(*ps_args,
		      0,		// débit
		      0,		// is_pre_desc
		      1, ps_key->chr,	// is_shortcut, shortcut
		      0, 0,		// copy
		      0,		// focus_stmt
		      -1,		// no record index
		      -1);		// no split index
    return true;
  }

  return false;
}

@end
