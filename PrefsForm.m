/* 
 * PrefsForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sam mar 27 15:17:35 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Feb 21 16:49:32 2006
 * Update Count    : 5
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: PrefsForm.m,v $
 * Revision 1.6  2006/04/25 08:47:13  max
 * Add lock on auto-off feature.
 * -ctlSelect: calls now super one to handle tabs clicks.
 *
 * Revision 1.5  2005/11/19 16:56:19  max
 * Redraws reworked.
 *
 * Revision 1.4  2005/10/16 21:44:05  max
 * Delete "Action of UP/DOWN keys in edit" preference.
 *
 * Revision 1.3  2005/08/20 13:06:57  max
 * Updates are now genericaly managed by MaTiForm.
 *
 * Revision 1.2  2005/05/08 12:13:05  max
 * No more special management for access code timeout settings, because
 * each accounts DBase can have its own access code.
 * So delete -_displayTimeout: method.
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_PREFSFORM
#include "PrefsForm.h"

#include "MaTirelire.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


@implementation PrefsForm

- (void)extractAndSave
{
  struct s_mati_prefs *ps_prefs = [oMaTirelire getPrefs];
  UInt16 uh_old_left_handed;

  //
  // General Tab
  //

  // Spécial gaucher
  uh_old_left_handed = ps_prefs->ul_left_handed;
  ps_prefs->ul_left_handed = CtlGetValue([self objectPtrId:PrefsLeftHanded]);
  if (uh_old_left_handed != ps_prefs->ul_left_handed)
    // La barre de scroll change de coté, il faut updater les listes
    self->uh_update_prefs = frmMaTiUpdatePrefs | frmMaTiUpdatePrefsScrList;

  // Auto sélection des champs numériques
  ps_prefs->ul_select_focused_num_flds
    = CtlGetValue([self objectPtrId:PrefsSelectFocusedNumFlds]);

  // Code d'accès
  ps_prefs->ul_access_code = self->ul_current_code;

  // Auto-arrêt
  ps_prefs->ul_timeout = LstGetSelection([self objectPtrId:PrefsTimeoutList]);

  // Auto lock on power off
  ps_prefs->ul_auto_lock_on_power_off
    = CtlGetValue([self objectPtrId:PrefsAutoLockOnPowerOff]);

  [oMaTirelire passwordReinit];


  //
  // Lists Tab
  //
  // Fonte des listes
  if ([oMaTirelire changeFont:self->ui_tmp_font])
    // Une fonte a changé, il faut updater les listes
    self->uh_update_prefs |= frmMaTiUpdatePrefs | frmMaTiUpdatePrefsScrList;

  // Les couleurs et attributs
  if (MemCmp(ps_prefs->ra_colors, self->ra_colors, sizeof(self->ra_colors)))
  {
    MemMove(ps_prefs->ra_colors, self->ra_colors, sizeof(self->ra_colors));

    self->uh_update_prefs |= frmMaTiUpdatePrefs | frmMaTiUpdatePrefsColors;
  }

  if (CtlGetValue([self objectPtrId:PrefsBoldRepeat]))
    self->uh_list_flags |= USER_REPEAT_BOLD;
  else
    self->uh_list_flags &= ~USER_REPEAT_BOLD;

  if (CtlGetValue([self objectPtrId:PrefsBoldXfer]))
    self->uh_list_flags |= USER_XFER_BOLD;
  else
    self->uh_list_flags &= ~USER_XFER_BOLD;

  if (ps_prefs->uh_list_flags != self->uh_list_flags)
  {
    ps_prefs->uh_list_flags = self->uh_list_flags;

    self->uh_update_prefs |= frmMaTiUpdatePrefs | frmMaTiUpdatePrefsBold;
  }

  //
  // Transaction Tab
  //
  // Les descriptions remplacent
  ps_prefs->ul_replace_desc = CtlGetValue([self objectPtrId:PrefsDesc]);

  // Action des icones premier/suivant
  ps_prefs->ul_firstnext_action
    = LstGetSelection([self objectPtrId:PrefsFirstNextList]);

  // Le type de boîte de sélection de l'heure
  ps_prefs->ul_time_select3 = CtlGetValue([self objectPtrId:PrefsTimeBox]);

  [oMaTirelire savePrefs];
}


- (void)_changeCode
{
  Char ra_label[16 + 1];

  SysCopyStringResource(ra_label, self->ul_current_code
			? strPrefsCodeEnable : strPrefsCodeDisable);

  [self fillLabel:PrefsCode withSTR:ra_label];
}


- (void)_displayFontName
{
  FmFontInfoType s_infos;

  FmGetFontInfo([oMaTirelire getFontBucket], self->ui_tmp_font, &s_infos);

  StrPrintF(self->ra_font_name, "%s-%s-%d",
	    s_infos.fontName, s_infos.fontStyle, (UInt16)s_infos.fontSize);

  CtlSetLabel([self objectPtrId:PrefsListFontName], self->ra_font_name);
}


- (void)_colorRedraw:(UInt16)indexes
{
  RectangleType s_bounds;
  UInt16 index;
  IndexedColorType e_sel_fill, e_obj_fore;

  WinPushDrawState();

  FntSetFont(stdFont);
  WinSetPatternType(blackPattern);

  e_sel_fill = UIColorGetTableEntryIndex(UIObjectSelectedFill);
  e_obj_fore = UIColorGetTableEntryIndex(UIObjectForeground);

#define SAMPLE_TEXT	"MaTirelire"

  for (index = 0; index < 4; index++)
    if (indexes & (1 << index))
    {
      FrmGetObjectBounds(self->pt_frm,
			 FrmGetObjectIndex(self->pt_frm, PrefsColor + index),
			 &s_bounds);

      WinSetDrawMode(winPaint);
      WinSetTextColor((self->uh_list_flags & (1 << index))
		      ? self->ra_colors[index]
		      : UIColorGetTableEntryIndex(UIObjectForeground));
      WinSetBackColor(UIColorGetTableEntryIndex(UIFieldBackground));

      // Partie non sélectionnée
      WinEraseRectangle(&s_bounds, 0);
      WinDrawChars(SAMPLE_TEXT, sizeof(SAMPLE_TEXT) - 1,
		   s_bounds.topLeft.x + 1, s_bounds.topLeft.y);

      // Partie sélectionnée (on fait la même chose que dans la
      // méthode -selectRow: de ScrollList.m)
      s_bounds.topLeft.x += PrefsColorButtonWidth - 12;
      s_bounds.extent.x = 12;

      WinInvertRectangleColor(&s_bounds);
    }

  WinPopDrawState();
}


- (Boolean)open
{
  struct s_mati_prefs *ps_prefs = [oMaTirelire getPrefs];
  ListType *pt_lst;
  UInt16 index;

  //
  // General Tab
  //
  // Spécial gaucher
  CtlSetValue([self objectPtrId:PrefsLeftHanded], ps_prefs->ul_left_handed);

  // Auto sélection des champs numériques
  CtlSetValue([self objectPtrId:PrefsSelectFocusedNumFlds],
	      ps_prefs->ul_select_focused_num_flds);

  
  // Code
  self->ul_current_code = ps_prefs->ul_access_code;
  [self _changeCode];

  // Auto-arrêt (on initialise même si pas encore de code, ce sera fait)
  pt_lst = [self objectPtrId:PrefsTimeoutList];
  LstSetSelection(pt_lst, ps_prefs->ul_timeout);
  CtlSetLabel([self objectPtrId:PrefsTimeoutPopup],
	      LstGetSelectionText(pt_lst, ps_prefs->ul_timeout));

  // Auto lock on power off
  CtlSetValue([self objectPtrId:PrefsAutoLockOnPowerOff],
	      ps_prefs->ul_auto_lock_on_power_off);

  //
  // Lists tab
  //
  // Fonte des listes
  self->ui_tmp_font = ps_prefs->ui_list_font;
  [self _displayFontName];

  // Couleurs
  MemMove(self->ra_colors, ps_prefs->ra_colors, sizeof(self->ra_colors));
  self->uh_list_flags = ps_prefs->uh_list_flags;

  CtlSetValue([self objectPtrId:PrefsBoldRepeat],
	      self->uh_list_flags & USER_REPEAT_BOLD);
  CtlSetValue([self objectPtrId:PrefsBoldXfer],
	      self->uh_list_flags & USER_XFER_BOLD);

  // On refera apparaître ces boutons et labels au besoin plus bas
  for (index = PrefsColor; index <= PrefsColorResetLast; index++)
    [self hideId:index];

  //
  // Transaction Tab
  //
  // Les descriptions remplacent
  CtlSetValue([self objectPtrId:PrefsDesc], ps_prefs->ul_replace_desc);

  // Action des icones premier/suivant
  pt_lst = [self objectPtrId:PrefsFirstNextList];
  LstSetSelection(pt_lst, ps_prefs->ul_firstnext_action);
  CtlSetLabel([self objectPtrId:PrefsFirstNextPopup],
	      LstGetSelectionText(pt_lst, ps_prefs->ul_firstnext_action));

  // Les deux gadgets suivants servent à désigner les bitmaps qui les
  // précèdent comme faisant partie du même onglet...
  FrmSetGadgetData(self->pt_frm,
		   FrmGetObjectIndex(self->pt_frm, PrefsFirstNextBmp1),
		   TAB_GADGET_MAGIC);
  FrmSetGadgetData(self->pt_frm,
		   FrmGetObjectIndex(self->pt_frm, PrefsFirstNextBmp2),
		   TAB_GADGET_MAGIC);

  // Le type de boîte de sélection de l'heure, que l'on cache de suite
  // car il n'est ni sur l'onglet no 1, ni géré automatiquement car il
  // dépend de la version de l'OS...
  CtlSetValue([self objectPtrId:PrefsTimeBox], ps_prefs->ul_time_select3);
  [self hideId:PrefsTimeBox];

  // Il y a 3 onglets
  self->uh_tabs_num = 3;

  return [super open];
}


- (Boolean)ctlEnter:(struct ctlEnter *)ps_enter
{
  switch (ps_enter->controlID)
  {
  case PrefsColor ... PrefsColorLast:
  {
    UInt16 index = ps_enter->controlID - PrefsColor;
    IndexedColorType a_color;

    a_color = (self->uh_list_flags & (1 << index))
      ? self->ra_colors[index]
      : UIColorGetTableEntryIndex(UIObjectForeground);

    if (UIPickColor(&a_color, NULL, UIPickColorStartPalette, NULL, NULL))
    {
      self->ra_colors[index] = a_color;

      // On fait apparaître le bouton "Réinit"
      [self showId:PrefsColorReset + index];

      index = (1 << index);

      self->uh_list_flags |= index;
    }

    // Tout le temps un redraw total, car il arrive qu'après
    // UIPickColor l'OS ne soit pas capable de redessiner le
    // formulaire sans pour autant nous envoyer de redraw...
    [self redrawForm];
  }
  return true;
  }

  return [super ctlEnter:ps_enter];
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  if ([super ctlSelect:ps_select])
    return true;

  switch (ps_select->controlID)
  {
  case PrefsColorReset ... PrefsColorResetLast:
  {
    UInt16 index = ps_select->controlID - PrefsColorReset;

    self->ra_colors[index] = 0;

    // On fait disparaître le bouton "Réinit"
    [self hideId:PrefsColorReset + index];

    index = (1 << index);

    self->uh_list_flags &= ~index;
    [self _colorRedraw:index];
  }
  break;

  case PrefsListFontName:
    // Utilise FontSelect qui n'est disponible qu'avec un OS>=3
    if (oMaTirelire->ul_rom_version >= 0x03003000)
    {
      if (FmSelectFont([oMaTirelire getFontBucket], &self->ui_tmp_font))
	[self _displayFontName];
    }
    break;

  case PrefsCode:
#define prefs_ul_access_code	[oMaTirelire getPrefs]->ul_access_code
    if ([oMaTirelire passwordChange:prefs_ul_access_code
		     currentCode:&self->ul_current_code] == 0)
      // On change le libellé du bouton ET on fait {ap,dis}paraître
      // les widgets timeout
      [self _changeCode];
#undef prefs_ul_access_code
    break;

  case PrefsSave:
    [self extractAndSave];

    // On continue sur cancel

  case PrefsCancel:
    [self returnToLastForm];
    break;

  default:
    return false;
  }

  return true;
}


- (void)tabsHide:(UInt16)uh_cur_tab
{
  // On cache l'onglet courant
  if (uh_cur_tab == 0)
    switch (self->uh_tabs_current)
    {
    case 2:
      if (oMaTirelire->uh_color_enabled)
      {
	UInt16 index;

	// On efface tous les boutons et labels hors tab...
	for (index = PrefsColor; index <= PrefsColorResetLast; index++)
	  [self hideId:index];
      }
      break;

    case 3:
      // La boîte de sélection de l'heure disparaît
      [self hideId:PrefsTimeBox];
      break;
    }

  [super tabsHide:uh_cur_tab];
}


- (void)tabsShow:(UInt16)uh_cur_tab
{
  [super tabsShow:uh_cur_tab];

  switch (uh_cur_tab)
  {
  case baseTab2:
    if (oMaTirelire->uh_color_enabled)
    {
      UInt16 index;

      for (index = PrefsColor; index <= PrefsColorLabelLast; index++)
	[self showId:index];

      // On ne fait apparaître le bouton "Réinit" seulement pour les
      // couleurs redéfinies
      for (; index <= PrefsColorResetLast; index++)
	if (self->uh_list_flags & (1 << (index - PrefsColorReset)))
	  [self showId:index];

      // 0xffff comme ça le jour où on gèrera les 8 couleurs ça marchera direct
      [self _colorRedraw:-1];
    }
    break;

  case baseTab3:
    // Version du système >= 3.1 : la boîte de sélection de l'heure...
    if (oMaTirelire->ul_rom_version >= 0x03103000)
      // ... apparaît sur l'onglet 2
      [self showId:PrefsTimeBox];
    break;
  }
}


// Appelée par -update: avec code frmRedrawUpdateCode
- (void)redrawForm
{
  [super redrawForm];

  if (self->uh_tabs_current == 2)
    [self _colorRedraw:-1];
}

@end
