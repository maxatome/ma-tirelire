/* 
 * TransScrollList.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Dim mar 28 19:32:11 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Jan 22 16:18:26 2008
 * Update Count    : 117
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: TransScrollList.m,v $
 * Revision 1.24  2008/03/16 15:00:15  max
 * On color devices, amounts are now always colored using COLOR_DEBIT or
 * COLOR_CREDIT when they are defined.
 *
 * Revision 1.23  2008/02/01 17:30:43  max
 * Be more generic in -scrollRootAdjusted:
 *
 * Revision 1.22  2008/01/21 18:28:13  max
 * Correct a mistake introduced in last commit..
 *
 * Revision 1.21  2008/01/16 17:12:28  max
 * Unused var...
 *
 * Revision 1.20  2008/01/14 15:42:22  max
 * Switch to new mcc.
 * Handle signed splits.
 * Long clic: empty split descriptions are not displayed.
 *
 * Revision 1.19  2006/12/16 16:56:49  max
 * Put a split icon in front of description when needed.
 *
 * Revision 1.18  2006/11/04 23:48:25  max
 * Valuable date and flagged triangles are now high density compliant.
 * Handle changes in struct s_stats_trans_draw.
 * trans_draw_record() no longer convert amounts, but handle splits.
 * Long clic can now display first splits (used in transactions list) or
 * only one split (used in statistics).
 * TransFormCallFull() changes.
 *
 * Revision 1.17  2006/10/05 19:09:03  max
 * s/Int32/t_amount/g
 *
 * Revision 1.16  2006/07/03 15:03:40  max
 * Add comment.
 *
 * Revision 1.15  2006/06/28 09:41:41  max
 * s/pt_frm/oForm/g attribute.
 *
 * Revision 1.14  2006/04/25 08:47:50  max
 * s/ps_sub_tr/ps_splits/g;
 * Redraws reworked (continue).
 *
 * Revision 1.13  2005/11/19 16:56:38  max
 * trans_draw_longclic_frame() and trans_draw_record() calling
 * conventions changed to handle future transactions available in the new
 * RepeatsListForm screen and "type instead of description" database
 * option.
 *
 * Revision 1.12  2005/10/16 21:44:08  max
 * Add -getItem:next: to handle moves in list from TransForm. Not yet enabled.
 *
 * Revision 1.11  2005/10/14 22:37:31  max
 * trans_draw_record() can now display mode, type or cheque number at
 * the left of the description.
 *
 * Revision 1.10  2005/10/11 19:12:08  max
 * Handle b_select_with_internal_flag when drawing transactions from
 * ClearingScrollList.
 * Populate generic -getLastVisibleItem.
 * Optimize sum computation.
 *
 * Revision 1.9  2005/10/03 20:32:28  max
 * Checked drawing in statistics and flagged screens was incorrect in
 * left handed mode. Corrected.
 *
 * Revision 1.8  2005/08/28 10:02:38  max
 * When a transaction doesn't have a description, display its type instead.
 * Some minor changes to long clic handling.
 *
 * Revision 1.7  2005/08/20 13:07:12  max
 * Prepare switching to 64 bits amounts.
 * s/__trans_draw_record/trans_draw_record/g.
 * Add trans_draw_longclic_frame() called by -longClicOnRow:topLeftIn:.
 * Add __draw_left_checked().
 * trans_draw_record() now can display transactions issued from the stats
 * or flagged screen.
 * End of -flagUnflag: reworked to display overdrawn account alert.
 *
 * Revision 1.6  2005/05/18 20:00:05  max
 * __trans_draw_record() is no longer static and is now fully able to
 * draw records issued from the Palm Find feature.
 *
 * Revision 1.5  2005/03/20 22:28:29  max
 * Add alarm management
 * Add overdrawn account management
 * Statement management popup: clicking outside now cancel (un)clearing
 *
 * Revision 1.4  2005/03/02 19:02:48  max
 * Add SCROLLLIST_GOTO_DATE flag to -goto: method.
 * Add progress bars for slow operations.
 * Add "N years" repeat info.
 * Swap buttons in alertTransactionDelete.
 *
 * Revision 1.3  2005/02/21 20:43:18  max
 * Bug for goto:*NEXT* corrected.
 * Add flag invert feature.
 * Add auto statement number management when clearing.
 *
 * Revision 1.2  2005/02/19 17:09:19  max
 * All "go to" types implemented.
 * Long clic implemented on transaction lines.
 * Flag/unflag method added.
 *
 * Revision 1.1  2005/02/09 22:57:23  max
 * First import.
 *
 * ==================== RCS ==================== */

#include <Unix/unix_stdarg.h>

#define EXTERN_TRANSSCROLLLIST
#include "TransScrollList.h"

#include "MaTirelire.h"

#include "TransListForm.h"

#include "StatsTransScrollList.h"
#include "ProgressBar.h"

#include "float.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX

// Dans PalmResize/resize.c
extern void UniqueUpdateForm(UInt16 formID, UInt16 code);

#define DRAW_ALREADY_SELECTED	0x0001
#define DRAW_COLORED		0x0002
#define DRAW_HI_DENSITY		0x0004

/*
 *         =         \
 *        ==          \ uh_depth
 *       ===          /
 *      ==== <- uh_y /
 *         ^--- uh_x
 */
static void __draw_marked(UInt16 uh_x, UInt16 uh_y,
			  UInt16 uh_depth, UInt16 uh_flags)
{
  UInt16 uh_other_x = uh_x - uh_depth;
  void hi_density_aliasing(void)
  {
    if (uh_flags & DRAW_HI_DENSITY)
    {
      UInt16 uh_x1, uh_x2, uh_y1, uh_y2, uh_old_coord;

      // ## = un pixel en densité normale 
      // ## /
      //
      // o = un pixel en double densité
      //
      //       o <- uh_y1
      //      ##
      //     o##
      //    ####
      //   o####
      //  ###### <,
      // o###### <- uh_y <- uh_y2
      // ^    ^^-- uh_x
      // |     ^-- uh_x1
      // +- uh_x2

      uh_old_coord = WinSetCoordinateSystem(kCoordinatesNative);

      uh_x1 = WinScaleCoord(uh_x + 1, false) - 1;
      uh_y1 = WinScaleCoord(uh_y - uh_depth + 1, false) - 1;

      uh_x2 = WinScaleCoord(uh_other_x + 1, false) - 1;
      uh_y2 = WinScaleCoord(uh_y + 1, false) - 1;

      WinDrawLine(uh_x1, uh_y1, uh_x2, uh_y2);

      WinSetCoordinateSystem(uh_old_coord);
    }
  }

  // Ici on suppose que les couleurs d'arrière et de 1er plan sont correctes
  if (uh_flags & DRAW_COLORED)
  {
    IndexedColorType e_old;

    e_old = WinSetForeColor(UIColorGetTableEntryIndex
			    ((uh_flags & DRAW_ALREADY_SELECTED)
			     ? UIFieldBackground : UIObjectSelectedFill));
    hi_density_aliasing();
    do
    {
      WinDrawLine(++uh_other_x, uh_y, uh_x, uh_y);
      uh_y--;
    }
    while (uh_other_x < uh_x);

    WinSetForeColor(e_old);
  }
  else
  {
    hi_density_aliasing();
    do
    {
      WinInvertLine(++uh_other_x, uh_y, uh_x, uh_y);
      uh_y--;
    }
    while (uh_other_x < uh_x);
  }
}


/*
 *      =            \
 *      ==            \ uh_depth
 *      ===           /
 *      ==== <- uh_y /
 *      ^--- uh_x
 *
 * Utilisé pour les dates de valeur et dans l'écran des stats pour
 * noter les pointés
 */
static void __draw_left_checked(UInt16 uh_x, UInt16 uh_y,
				UInt16 uh_depth, UInt16 uh_flags)
{
  UInt16 uh_other_x = uh_x + uh_depth;
  void hi_density_aliasing(void)
  {
    if (uh_flags & DRAW_HI_DENSITY)
    {
      UInt16 uh_x1, uh_x2, uh_y1, uh_y2, uh_old_coord;

      // ## = un pixel en densité normale 
      // ## /
      //
      // o = un pixel en double densité
      //
      // o	 <- uh_y1
      // ##
      // ##o
      // ####
      // ####o v--- uh_x2
      // ######  <,
      // ######o <- uh_y <- uh_y2
      // ^^--- uh_x
      // ^---- uh_x1

      uh_old_coord = WinSetCoordinateSystem(kCoordinatesNative);

      uh_x1 = WinScaleCoord(uh_x, false);
      uh_y1 = WinScaleCoord(uh_y - uh_depth + 1, false) - 1;

      uh_x2 = WinScaleCoord(uh_other_x, false);
      uh_y2 = WinScaleCoord(uh_y + 1, false) - 1;

      WinDrawLine(uh_x1, uh_y1, uh_x2, uh_y2);

      WinSetCoordinateSystem(uh_old_coord);
    }
  }

  // Ici on suppose que les couleurs d'arrière et de 1er plan sont correctes
  if (uh_flags & DRAW_COLORED)
  {
    IndexedColorType e_old;

    e_old = WinSetForeColor(UIColorGetTableEntryIndex
			    ((uh_flags & DRAW_ALREADY_SELECTED)
			     ? UIFieldBackground
			     : UIObjectSelectedFill));
    hi_density_aliasing();
    do
    {
      WinDrawLine(--uh_other_x, uh_y, uh_x, uh_y);
      uh_y--;
    }
    while (uh_other_x > uh_x);

    WinSetForeColor(e_old);
  }
  else
  {
    hi_density_aliasing();
    do
    {
      WinInvertLine(--uh_other_x, uh_y, uh_x, uh_y);
      uh_y--;
    }
    while (uh_other_x > uh_x);
  }
}


//
// h_col :
//  0	TransListForm
// -1	Stats, pointage et répétitions
//  1	Find
void trans_draw_record(void *pv_table, Int16 h_row, Int16 h_col,
		       RectangleType *prec_bounds)
{
  MaTirelire *oLocalMaTirelire;
  Transaction *oTransactions;
  MemHandle vh_rec = NULL;
  t_amount l_amount = 0;	// Pour éviter un warning de GCC
  struct s_transaction *ps_op;
  struct s_misc_infos *ps_infos;
  struct s_mati_prefs *ps_prefs;
  struct s_rec_options s_options;
  Char ra_buf[dmCategoryLength]; // dmCategoryLength > (10 + 1)
  RectangleType s_rect;
  DmOpenRef db;
  UInt16 uh_db_idx;
  UInt16 uh_x, uh_icon_width, uh_len, uh_tri_depth, uh_win_flags = 0;
  UInt16 uh_add_to_desc = TRANS_DRAW_ADD_NONE;
  Int16 h_width, h_override_type = -1;
  FontID uh_save_font, uh_bold_font, uh_std_font;
  DateType s_date;
  IndexedColorType a_color = 0, a_amount_color = 0;
  Boolean b_bold = false;
  Boolean b_account;
  Boolean b_force_select = false; // Pour les stats
  Boolean b_force_non_flagged = false; // Pour les stats
  Boolean b_display_split = false; // Pour les stats (affichage d'une sous-op)
  Boolean b_repeat_screen = false, b_future = false; // Répétitions

  DateToInt(s_date) = 0;
  s_options.pa_note = NULL;

  //
  // Callback de dessin de la table : dans TransListForm et dans les stats
  if (h_col <= 0)
  {
    oLocalMaTirelire = oMaTirelire;
    oTransactions = [oLocalMaTirelire transaction];

    db = oTransactions->db;

    //
    // Si on vient des stats, de l'écran de pointage ou des répétitions
    if (h_col < 0)
    {
      struct s_stats_trans_draw *ps_draw = pv_table;

      uh_db_idx = ps_draw->uh_rec_index;
      b_force_non_flagged = ps_draw->uh_non_flagged;
      b_repeat_screen = ps_draw->uh_repeat_screen;
      s_date = ps_draw->s_date;

      vh_rec = DmQueryRecord(db, uh_db_idx);
      ps_op = MemHandleLock(vh_rec);

      if (b_repeat_screen)
	b_future = (DateToInt(ps_op->s_date) != DateToInt(s_date));

      // Faut-il sélectionner la somme ?
      b_force_select = ps_draw->uh_select_with_internal_flag
	? ps_op->ui_rec_internal_flag : ps_draw->uh_selected;

      // Ajout à la description
      uh_add_to_desc = ps_draw->uh_add_to_desc;

      l_amount = ps_draw->uh_another_amount
	? ps_draw->l_amount : ps_op->l_amount;

      //
      // On doit afficher une sous-opération (ps_op->ui_rec_splits
      // forcément à 1, c'est vérifié par l'appelant)
      if (ps_draw->h_split >= 0)
      {
	FOREACH_SPLIT_DECL;	// __uh_num et ps_cur_split
	Int16 h_split = ps_draw->h_split;

	options_extract((struct s_transaction*)ps_op, &s_options);

	// Une sous-opération particulière
	if (h_split < TRANS_DRAW_SPLIT_REMAIN)
	{
	  FOREACH_SPLIT(&s_options)
	  {
	    if (h_split-- == 0)
	    {
	      s_options.pa_note = ps_cur_split->ra_desc;
	      h_override_type = ps_cur_split->ui_type;
	      break;
	    }
	  }
	}

	// Il faut mettre un indicateur en début de ligne
	b_display_split = true;
      }

      // Ici l_amount est dans la monnaie du formulaire, c'est bon...
    }
    else
    {
      uh_db_idx = TblGetRowID((TableType*)pv_table, h_row);

      vh_rec = DmQueryRecord(db, uh_db_idx);
      ps_op = MemHandleLock(vh_rec);
    }

    uh_tri_depth =
      ((SumScrollList*)((SumListForm*)oFrm)->oList)->uh_tbl_item_height;

    uh_std_font = oLocalMaTirelire->s_fonts.uh_list_font;
    uh_bold_font = oLocalMaTirelire->s_fonts.uh_list_bold_font;

    ps_infos = &oLocalMaTirelire->s_misc_infos;
  }
  // Dessin dans la visualisation des résultats de la recherche globale
  // !!! PAS LE DROIT AUX VARIABLES GLOBALES DANS CE CAS !!!
  else
  {
    struct s_infos_from_find *ps_from_find = pv_table;

    oLocalMaTirelire = [MaTirelire appli];
    oTransactions = ps_from_find->oTransactions;
    ps_op = ps_from_find->ps_tr;
    ps_infos = &ps_from_find->s_infos;
    uh_db_idx = ps_from_find->uh_db_idx;

    uh_tri_depth = FntLineHeight();;

    uh_std_font = stdFont;
    uh_bold_font = boldFont;

    init_misc_infos(ps_infos, stdFont, boldFont);

    db = oTransactions->db;
  }

  uh_tri_depth += 2;
  uh_tri_depth /= 3;

  // Quand on ne vient pas des stats, le montant à afficher est celui
  // de l'opération
  if (h_col >= 0)
    l_amount = ps_op->l_amount;

  ps_prefs = &oLocalMaTirelire->s_prefs;

  // Propriétés du compte OU opération ?
  b_account = DateToInt(ps_op->s_date) == 0;


  ////////////////////////////////////////////////////////////////////////
  //
  // Couleur / Haute densité / Gras
  //
  // Haute densité ?
  if (oLocalMaTirelire->uh_high_density)
    uh_win_flags = DRAW_HI_DENSITY;

  // Couleur
  if (oLocalMaTirelire->uh_color_enabled)
  {
    IndexedColorType a_default_color;

    WinPushDrawState();

    // La couleur de fond n'est pas la même dans les résultats d'une
    // recherche système
    WinSetBackColor(UIColorGetTableEntryIndex(h_col > 0 ? UIDialogFill
					      : UIFieldBackground));
    a_color = a_amount_color = a_default_color
      = UIColorGetTableEntryIndex(UIObjectForeground);

    if (b_account == false)
    {
      // Une répétition
      if (ps_op->ui_rec_repeat)
      {
	if (ps_prefs->uh_list_flags & USER_REPEAT_COLOR)
	  a_color = a_amount_color = ps_prefs->ra_colors[COLOR_REPEAT];

	if (ps_prefs->uh_list_flags & USER_REPEAT_BOLD)
	  b_bold = true;
      }

      // Un transfert
      if (ps_op->ui_rec_xfer)
      {
	if (a_color == a_default_color // Pas encore en couleur
	    && ps_prefs->uh_list_flags & USER_XFER_COLOR)
	  a_color = a_amount_color = ps_prefs->ra_colors[COLOR_XFER];

	if (ps_prefs->uh_list_flags & USER_XFER_BOLD)
	  b_bold = true;
      }
    }

    // Un débit
    if (l_amount < 0)
    {
      // Il y a une couleur pour les débits
      if (ps_prefs->uh_list_flags & USER_DEBIT_COLOR)
      {
	a_amount_color = ps_prefs->ra_colors[COLOR_DEBIT];

	if (a_color == a_default_color) // Pas encore en couleur
	  a_color = a_amount_color;
      }
    }
    // Un crédit (ou somme nulle)
    else
    {
      // Il y a une couleur pour les crédits
      if (ps_prefs->uh_list_flags & USER_CREDIT_COLOR)
      {
	a_amount_color = ps_prefs->ra_colors[COLOR_CREDIT];

	if (a_color == a_default_color) // Pas encore en couleur
	  a_color = a_amount_color;
      }
    }

    WinSetTextColor(a_color);

    uh_win_flags |= DRAW_COLORED;
  }
  // Noir & blanc
  else if (b_account == false)
  {
    // Une répétition en gras OU un transfert en gras
    b_bold =
      (ps_op->ui_rec_repeat && (ps_prefs->uh_list_flags & USER_REPEAT_BOLD))
      || (ps_op->ui_rec_xfer && (ps_prefs->uh_list_flags & USER_XFER_BOLD));
  }

  uh_x = prec_bounds->topLeft.x;


  ////////////////////////////////////////////////////////////////////////
  //
  // Propriétés de compte
  if (b_account)
  {
    UInt16 uh_attr;

    uh_save_font = FntSetFont(uh_std_font);

    //
    // Nom du compte
    //
    DmRecordInfo(db, uh_db_idx, &uh_attr, NULL, NULL);

    CategoryGetName(db, uh_attr & dmRecAttrCategoryMask, ra_buf);

    uh_len = StrLen(ra_buf);
    h_width = prepare_truncating(ra_buf, &uh_len,
				 prec_bounds->extent.x
				 - ps_infos->uh_amount_width);
    WinDrawTruncatedChars(ra_buf, uh_len, uh_x, prec_bounds->topLeft.y,
			  h_width);
  }
  ////////////////////////////////////////////////////////////////////////
  //
  // Une opération
  else
  {
    Char *pa_note;

    if (DateToInt(s_date) == 0)
    {
      if (oTransactions->ps_prefs->ul_list_date && ps_op->ui_rec_value_date)
	s_date = value_date_extract(ps_op);
      else
	s_date = ps_op->s_date;
    }

    //
    // Date
    //
    infos_short_date(ps_infos, s_date, ra_buf);

    // Enregistrement plus vieux qu'aujourd'hui
    if (DateToInt(s_date) < DateToInt(ps_infos->s_today))
    {
      uh_save_font = FntSetFont(uh_bold_font);
      WinDrawChars(ra_buf, 5, uh_x, prec_bounds->topLeft.y);
      FntSetFont(uh_std_font);
    }
    // Enregistrement d'aujourd'hui
    else if (DateToInt(s_date) == DateToInt(ps_infos->s_today))
    {
      s_rect = *prec_bounds;

      s_rect.extent.x = ps_infos->uh_date_width;

      uh_save_font = FntSetFont(uh_bold_font);
      WinDrawChars(ra_buf, 5, uh_x, prec_bounds->topLeft.y);

      // Reverse video
      if (uh_win_flags & DRAW_COLORED)
	WinInvertRectangleColor(&s_rect);
      else
	WinInvertRectangle(&s_rect, 0);

      FntSetFont(uh_std_font);
    }
    // Enregistrement du futur
    else
    {
      uh_save_font = FntSetFont(uh_std_font);
      WinDrawChars(ra_buf, 5, uh_x, prec_bounds->topLeft.y);
    }

    //
    // Une date de valeur est présente
    if (ps_op->ui_rec_value_date)
      __draw_left_checked(uh_x,
			  prec_bounds->topLeft.y + prec_bounds->extent.y - 1,
			  uh_tri_depth,
			  uh_win_flags
			  | (DateToInt(s_date)==DateToInt(ps_infos->s_today)));

    uh_x += ps_infos->uh_date_width + 1;

    //
    // Une ou plusieurs icônes avant la note
    uh_icon_width = 0;

    //
    // Icône de split avant la note (dans ce cas, on ne s'occupe pas
    // de la répétition ni de l'alarme)
    if (b_display_split)
    {
      FntSetFont(symbolFont);
      WinDrawChars("\023", 1, uh_x, prec_bounds->topLeft.y);
      uh_icon_width = FntCharWidth('\023') + 1;
    }
    else
    {
      //
      // Icône de répétition avant la note
      if (b_repeat_screen == false && ps_op->ui_rec_repeat)
      {
	FntSetFont(symbolFont);
	WinDrawChars("\025", 1, uh_x, prec_bounds->topLeft.y);
	uh_icon_width = FntCharWidth('\025') + 1;
      }

      //
      // Icône d'alarme avant la note
      if (ps_op->ui_rec_alarm)
      {
	FntSetFont(symbolFont);
	WinDrawChars("\024", 1, uh_x + uh_icon_width, prec_bounds->topLeft.y);
	uh_icon_width += FntCharWidth('\024') + 1;
      }

      //
      // Icône de ventilation avant la note
      if (ps_op->ui_rec_splits)
      {
	FntSetFont(symbolFont);
	WinDrawChars("\011", 1, uh_x + uh_icon_width, prec_bounds->topLeft.y);
	uh_icon_width += FntCharWidth('\011') + 1;
      }
    }

    uh_x += uh_icon_width;

    //
    // La note...
    //
    FntSetFont(b_bold ? uh_bold_font : uh_std_font);

    if (s_options.pa_note == NULL)
      options_extract(ps_op, &s_options);
    pa_note = s_options.pa_note;

    uh_icon_width = (prec_bounds->extent.x - ps_infos->uh_date_width
		     - uh_icon_width - ps_infos->uh_amount_width);

    // Il faut faire un ajout devant la description
    if (uh_add_to_desc != TRANS_DRAW_ADD_NONE)
    {
      switch (uh_add_to_desc)
      {
      case TRANS_DRAW_ADD_MODE:
      {
	Mode *oModes = [oLocalMaTirelire mode];
	struct s_mode *ps_mode = [oModes getId:ps_op->ui_rec_mode];
	UInt16 uh_tmp_width = (uh_icon_width >> 1);

	uh_len = StrLen(ps_mode->ra_name);
	h_width = prepare_truncating(ps_mode->ra_name, &uh_len,
				     *pa_note == '\0'
				     ? uh_icon_width : uh_tmp_width);
	WinDrawTruncatedChars(ps_mode->ra_name, uh_len,
			      uh_x, prec_bounds->topLeft.y,
			      h_width);

	[oModes getFree:ps_mode];

	if (*pa_note == '\0')
	  goto desc_done;

	uh_tmp_width += 3;
	uh_icon_width -= uh_tmp_width;
	uh_x += uh_tmp_width;
      }
      break;

      // Dans ce cas on écrit le type sans sa parenté
      case TRANS_DRAW_ADD_TYPE:
	// On ajoute le type en tête seulement si on n'affiche pas
	// tout le temps le type !!!
	if (oTransactions->ps_prefs->ul_list_type == 0)
	{
	  Type *oTypes = [oLocalMaTirelire type];
	  struct s_type *ps_type = [oTypes getId:ps_op->ui_rec_type];
	  UInt16 uh_tmp_width = (uh_icon_width >> 1);

	  uh_len = StrLen(ps_type->ra_name);
	  h_width = prepare_truncating(ps_type->ra_name, &uh_len,
				       *pa_note == '\0'
				       ? uh_icon_width : uh_tmp_width);
	  WinDrawTruncatedChars(ps_type->ra_name, uh_len,
				uh_x, prec_bounds->topLeft.y,
				h_width);

	  [oTypes getFree:ps_type];

	  if (*pa_note == '\0')
	    goto desc_done;

	  uh_tmp_width += 3;
	  uh_icon_width -= uh_tmp_width;
	  uh_x += uh_tmp_width;
	}
	break;

      case TRANS_DRAW_ADD_CHEQUE:
	if (ps_op->ui_rec_check_num)
	{
	  UInt16 uh_ell_width;

	  StrUInt32ToA(ra_buf, s_options.ps_check_num->ui_check_num, &uh_len);

	  h_width = prepare_truncating(ra_buf, &uh_len, uh_icon_width);
	  WinDrawTruncatedChars(ra_buf, uh_len, uh_x, prec_bounds->topLeft.y,
			    h_width);

	  // Si le numéro de chèque a été tronqué, il n'y a plus de
	  // place pour la description
	  if (h_width >= 0)
	    goto desc_done;

	  // S'il ne reste pas assez de place pour ne serait-ce que
	  // '...', on n'affiche pas la description
	  h_width = FntCharsWidth(ra_buf, uh_len) + 3;
	  ellipsis(&uh_ell_width);
	  if (uh_icon_width - uh_ell_width <= h_width)
	    goto desc_done;

	  uh_icon_width -= h_width;
	  uh_x += h_width;
	}
	break;
      }
    }

    // Il n'y a pas de note, on met le type à la place
    //			 OU BIEN toujours le type à la place de la description
    if (*pa_note == '\0' || oTransactions->ps_prefs->ul_list_type)
    {
      pa_note = [[oLocalMaTirelire type]
		  fullNameOfId:(h_override_type < 0 ? ps_op->ui_rec_type
				: h_override_type)
		  len:&uh_len
		  truncatedTo:uh_icon_width];
      WinDrawChars(pa_note, uh_len, uh_x, prec_bounds->topLeft.y);
      MemPtrFree(pa_note);
    }
    else
    {
      Boolean b_free_note = false;

      uh_len = StrLen(pa_note);

      // Opération dans le futur avec répétition
      if (b_future && ps_op->ui_rec_repeat)
      {
	uh_len++;		// Il faut inclure le \0 de fin
	pa_note = repeat_expand_note(pa_note, &uh_len,
				     repeat_num_occurences(s_options.ps_repeat,
							   ps_op->s_date,
							   s_date),
				     false);

	b_free_note = (pa_note != s_options.pa_note);
	uh_len--;
      }

      h_width = prepare_truncating(pa_note, &uh_len, uh_icon_width);
      WinDrawTruncatedChars(pa_note, uh_len, uh_x, prec_bounds->topLeft.y,
			    h_width);

      if (b_free_note)
	MemPtrFree(pa_note);
    }
desc_done:
    ;
  }

  ////////////////////////////////////////////////////////////////////////
  //
  // La somme
  if (a_amount_color != a_color)
    WinSetTextColor(a_amount_color);

  switch (l_amount < 0 ? - l_amount : l_amount)
  {
  case 0 ... 9999999:		/* entre <0, 100000< euros */
    /* On garde les centimes */
    Str100FToA(ra_buf, l_amount, &uh_len, ps_infos->a_dec_separator);
    FntSetFont(uh_std_font);
    break;

  case 10000000 ... 99999999:	/* entre <100000, 1000000< euros */
    /* Sans les centimes et en gras */
    StrIToA(ra_buf, l_amount / 100);
    uh_len = StrLen(ra_buf);
    FntSetFont(uh_bold_font);
    break;

    /* Au dessus d'un million en valeur absolue */
  default:
    /* Abréviation sur le million en gras */
    Str100FToA(ra_buf, l_amount / 1000000, &uh_len,
	       ps_infos->a_dec_separator);
#define ABBREV_MILLION	"M"
    MemMove(&ra_buf[uh_len], ABBREV_MILLION, sizeof(ABBREV_MILLION));
    uh_len += sizeof(ABBREV_MILLION) - 1;
    FntSetFont(uh_bold_font);
    break;
  }

  WinDrawChars(ra_buf, uh_len,
	       prec_bounds->topLeft.x + prec_bounds->extent.x
	       - FntCharsWidth(ra_buf, uh_len),
	       prec_bounds->topLeft.y);


  ////////////////////////////////////////////////////////////////////////
  //
  // Sélection de la somme
  //
  // Liste d'opérations dans les stats, mais pas l'écran des répétitions
  if (h_col < 0 && b_repeat_screen == false)
  {
    // Cette entrée a sa somme sélectionnée (attention pas pointée !)
    if (b_force_select)
    {
      s_rect = *prec_bounds;
      s_rect.topLeft.x += s_rect.extent.x - ps_infos->uh_amount_width;
      s_rect.extent.x = ps_infos->uh_amount_width;

      if (uh_win_flags & DRAW_COLORED)
	WinInvertRectangleColor(&s_rect);
      else
	WinInvertRectangle(&s_rect, 0);
    }

    // Le pointage est quant à lui noté par un triangle en bas à
    // gauche de la somme
    if (ps_op->ui_rec_checked)
      __draw_left_checked(prec_bounds->topLeft.x
			  + prec_bounds->extent.x - ps_infos->uh_amount_width,
			  prec_bounds->topLeft.y + prec_bounds->extent.y - 1,
			  uh_tri_depth, uh_win_flags | b_force_select);
  }
  // Autres
  else
  {
    // Opération pointée AVEC la date de l'opération inchangée (au cas
    // où on est dans l'écran des répétitions avec une opération
    // future)
    if (ps_op->ui_rec_checked && b_future == false)
    {
      s_rect = *prec_bounds;
      s_rect.topLeft.x += s_rect.extent.x - ps_infos->uh_amount_width;
      s_rect.extent.x = ps_infos->uh_amount_width;

      if (uh_win_flags & DRAW_COLORED)
	WinInvertRectangleColor(&s_rect);
      else
	WinInvertRectangle(&s_rect, 0);

      // Pour le marquage qui suit...
      b_force_select = true;
    }
  }

  ////////////////////////////////////////////////////////////////////////
  //
  // Opération marquée
  if (ps_op->ui_rec_marked && b_force_non_flagged == false)
    __draw_marked(prec_bounds->topLeft.x + prec_bounds->extent.x - 1,
		  prec_bounds->topLeft.y + prec_bounds->extent.y - 1,
		  uh_tri_depth, uh_win_flags | b_force_select);

  if (vh_rec != NULL)
    MemHandleUnlock(vh_rec);

  if (uh_win_flags & DRAW_COLORED)
    WinPopDrawState();
  else
    FntSetFont(uh_save_font);
}


WinHandle trans_draw_longclic_frame(Transaction *oTransactions,
				    PointType *pp_win,
				    UInt16 uh_rec_index, UInt16 uh_flags, ...)
{
  Type *oTypes = [oMaTirelire type];
  struct s_transaction *ps_tr;
  struct s_rec_options s_options;
  Char *pa_note;
  WinHandle win_handle;
  RectangleType rec_win;
  t_amount l_amount;
  Char ra_format[64];
  Char ra_date[longDateStrLength], ra_time[timeStringLength];
  Char ra_tmp[longDateStrLength + timeStringLength + sizeof(ra_format)];
  UInt16 uh_lines, uh_lines_orig, uh_desc_lines, uh_hfont, uh_save_font, uh_type;
  UInt16 uh_indent_note = 0, uh_num_splits_lines;
  DateType s_date;
  Boolean b_stats = (uh_flags & TRANS_DRAW_LONGCLIC_STATS) != 0;
  Boolean b_split = (uh_flags & TRANS_DRAW_LONGCLIC_SPLIT) != 0;
  Boolean b_future = false;
  Boolean b_free_note = false;

  ps_tr = [oTransactions getId:uh_rec_index];

  s_date = ps_tr->s_date;

  // Propriétés de compte
  if (DateToInt(s_date) == 0)
  {
    // Pas de clic long pour les propriétés de compte XXX

    [oTransactions getFree:ps_tr];
    return NULL;
  }

  l_amount = ps_tr->l_amount;

  options_extract(ps_tr, &s_options);

  // Calcul du nombre de lignes
  //	      Si on est dans les stats, il faut le nom du compte
  uh_lines = (b_stats
	      /* Date et Somme[, par Mode] */
	      + 2
	      /* Information de répétition */
	      + ps_tr->ui_rec_repeat
	      /* Information de transfert */
	      + ps_tr->ui_rec_xfer
	      // Devise
	      + ps_tr->ui_rec_currency);

  pa_note = s_options.pa_note;
  uh_type = ps_tr->ui_rec_type;

  // Il faut afficher les infos d'une opération qui n'existe pas encore
  if (uh_flags & TRANS_DRAW_LONGCLIC_FUTURE)
  {
    va_list ap;

    va_start(ap, uh_flags);

    DateToInt(s_date) = va_arg(ap, UInt16);

    if (ps_tr->ui_rec_repeat)
    {
      pa_note = repeat_expand_note(pa_note, NULL,
				   repeat_num_occurences(s_options.ps_repeat,
							 ps_tr->s_date, s_date),
				   false);
      b_free_note = (pa_note != s_options.pa_note);
    }
    b_future = true;

    va_end(ap);
  }
  else
  {
    if (b_split)
    {
      FOREACH_SPLIT_DECL;	// ps_cur_split et __uh_num
      t_amount l_splits_sum;
      va_list ap;
      Int16 h_split;

      va_start(ap, uh_flags);

      h_split = va_arg(ap, Int16);

      // Le reste de l'opération
      if (h_split >= TRANS_DRAW_SPLIT_REMAIN)
      {
	l_splits_sum = 0;

	FOREACH_SPLIT(&s_options)
	  l_splits_sum += ps_cur_split->l_amount;

	if (l_amount < 0)
	  l_splits_sum = - l_splits_sum;

	l_amount -= l_splits_sum;
      }
      // Une sous-opération particulière
      else
      {
	FOREACH_SPLIT(&s_options)
	  if (h_split-- == 0)
	  {
	    l_amount = l_amount < 0
	      ? - ps_cur_split->l_amount : ps_cur_split->l_amount;

	    pa_note = ps_cur_split->ra_desc;
	    uh_type =  ps_cur_split->ui_type;
	    break;
	  }
      }

      FntSetFont(symbolFont);
      uh_indent_note = FntCharWidth('\023') + 3;
      FntSetFont(stdFont);

      va_end(ap);
    }

    //		 Information de date de valeur
    uh_lines += (ps_tr->ui_rec_value_date
		 // Numéro de chèque
		 + ps_tr->ui_rec_check_num
		 // Numéro de relevé
		 + ps_tr->ui_rec_stmt_num);
  }

  // Type
  uh_lines += (uh_type != TYPE_UNFILED);

  // Sous-opérations (seulement si on n'affiche pas une sous-op)
  uh_num_splits_lines = 0;
  if (b_split == false && ps_tr->ui_rec_splits)
  {
    FOREACH_SPLIT_DECL;	// ps_cur_split et __uh_num

    uh_lines += 1;		// Ligne d'en-tête
    uh_num_splits_lines = s_options.ps_splits->uh_num;

    FOREACH_SPLIT(&s_options)
    {
      // Si la description n'est pas vide...
      if (is_empty(ps_cur_split->ra_desc) == false)
	uh_num_splits_lines++;
    }
  }


  // Au moins une ligne de description
  WinGetWindowExtent(&rec_win.extent.x, &uh_hfont); // uh_hfont == dummy

  uh_save_font = FntSetFont(stdFont);

  uh_desc_lines = is_empty(pa_note)
    ? 0
    : FldCalcFieldHeight(pa_note, rec_win.extent.x - 3 - 2 - uh_indent_note);

  uh_hfont = FntLineHeight();

  uh_lines += uh_desc_lines + uh_num_splits_lines;
  uh_lines_orig = uh_lines;
  win_handle = DrawFrame(pp_win, &uh_lines, uh_hfont, &rec_win,
			 oMaTirelire->uh_color_enabled);
  if (win_handle != NULL)
  {
    struct s_misc_infos *ps_infos;
    Char *pa_cur;
    UInt16 uh_left_align, uh_y, uh_len, uh_rec_account;

    ps_infos = &oMaTirelire->s_misc_infos;

    // Moins de lignes affichables que prévu, on réajuste
    if (uh_lines < uh_lines_orig)
    {
      UInt16 uh_diff_lines = uh_lines_orig - uh_lines;

      // Il y a des sous-opérations à afficher
      if (uh_num_splits_lines > 0)
      {
	// On supprime des sous-opérations
	while (uh_diff_lines > 1)
	{
	  uh_num_splits_lines -= 2;
	  uh_diff_lines -= 2;
	}

	// La description ne pourra pas absorber la dernière ligne de
	// différence, puisqu'elle est vide, on retire donc une
	// sous-opération supplémentaire (XXX ça nous fera une ligne
	// vide à la fin des sous-opérations... XXX)
	if (uh_diff_lines > 0 && uh_desc_lines == 0)
	{
	  uh_num_splits_lines -= 2;
	  uh_diff_lines -= 2;
	}
      }

      uh_desc_lines -= uh_diff_lines;
    }

    uh_left_align = rec_win.topLeft.x;
    uh_y = rec_win.topLeft.y;

    // Le compte de l'opération
    DmRecordInfo(oTransactions->db, uh_rec_index, &uh_rec_account, NULL, NULL);
    uh_rec_account &= dmRecAttrCategoryMask;

    // On est dans les stats, il faut le nom du compte
    if (b_stats)
    {
      CategoryGetName(oTransactions->db, uh_rec_account, ra_tmp);

      FntSetFont(boldFont);
      WinDrawChars(ra_tmp, StrLen(ra_tmp), uh_left_align, uh_y);
      FntSetFont(stdFont);

      uh_y += uh_hfont;
    }

    // Date
    SysCopyStringResource(ra_format, strTransListDateTime);
    DateToAscii(s_date.month, s_date.day, s_date.year + firstYear,
		(DateFormatType)PrefGetPreference(prefLongDateFormat),
		ra_date);
    TimeToAscii(ps_tr->s_time.hours, ps_tr->s_time.minutes,
		(TimeFormatType)PrefGetPreference(prefTimeFormat), ra_time);
    uh_len = StrPrintF(ra_tmp, ra_format, ra_date, ra_time);
    WinDrawChars(ra_tmp, uh_len, uh_left_align, uh_y);

    if (ps_tr->ui_rec_alarm)	// Icône d'alarme
    {
      uh_len = FntCharsWidth(ra_tmp, uh_len) + 2;
      FntSetFont(symbolFont);
      WinDrawChars("\024", 1, uh_left_align + uh_len, uh_y);
      FntSetFont(stdFont);
    }

    // Date de valeur
    if (b_future == false && ps_tr->ui_rec_value_date)
    {
      SysCopyStringResource(ra_format, strTransListValuationDate);
      DateToAscii(s_options.ps_value_date->s_value_date.month,
		  s_options.ps_value_date->s_value_date.day,
		  s_options.ps_value_date->s_value_date.year + firstYear,
		  (DateFormatType)PrefGetPreference(prefLongDateFormat),
		  ra_date);

      uh_y += uh_hfont;
      uh_len = StrPrintF(ra_tmp, ra_format, ra_date);
      WinDrawChars(ra_tmp, uh_len, uh_left_align, uh_y);
    }

    // Symbole de sous-opération précédant la note
    if (uh_indent_note > 0)
    {
      FntSetFont(symbolFont);
      WinDrawChars("\023", 1, uh_left_align, uh_y + uh_hfont);
      FntSetFont(stdFont);
    }

    // La note
    pa_cur = pa_note;
    while (uh_desc_lines-- > 0)
    {
      uh_y += uh_hfont;
      uh_len = FldWordWrap(pa_cur, rec_win.extent.x - 3 - 2 - uh_indent_note);
      if (uh_len > 0)
      {
	WinDrawChars(pa_cur, uh_len - (pa_cur[uh_len - 1] == '\n'),
		     uh_left_align + uh_indent_note, uh_y);
	pa_cur += uh_len;
      }
    }

    // La somme en gras
    uh_y += uh_hfont;
    FntSetFont(boldFont);
    Str100FToA(ra_tmp,
	       ps_tr->ui_rec_currency
	       ? s_options.ps_currency->l_currency_amount
	       : l_amount,
	       &uh_len, ps_infos->a_dec_separator);
    WinDrawChars(ra_tmp, uh_len, uh_left_align, uh_y);
    rec_win.topLeft.x += FntCharsWidth(ra_tmp, uh_len);
    FntSetFont(stdFont);

    // La devise
    {
      Currency *oCurrencies = [oMaTirelire currency];
      UInt16 uh_currency, uh_account_currency;

      uh_account_currency = [oTransactions accountCurrency:uh_rec_account];

      if (ps_tr->ui_rec_currency)
	uh_currency = s_options.ps_currency->ui_currency;
      // Monnaie du compte
      else
	uh_currency = uh_account_currency;

      pa_cur = [oCurrencies fullNameOfId:uh_currency len:&uh_len];
      if (pa_cur != NULL)
      {
	WinDrawChars(pa_cur, uh_len, rec_win.topLeft.x, uh_y);
	rec_win.topLeft.x += FntCharsWidth(pa_cur, uh_len);
	MemPtrFree(pa_cur);
      }

      // Il y a une devise, on affiche dans la monnaie du compte
      if (uh_currency != uh_account_currency)
      {
	uh_y += uh_hfont;

	Str100FToA(ra_tmp, ps_tr->l_amount, &uh_len,ps_infos->a_dec_separator);
	WinDrawChars(ra_tmp, uh_len, uh_left_align, uh_y);

	rec_win.topLeft.x = uh_left_align + FntCharsWidth(ra_tmp, uh_len);

	pa_cur = [oCurrencies fullNameOfId:uh_account_currency len:&uh_len];
	if (pa_cur != NULL)
	{
	  WinDrawChars(pa_cur, uh_len, rec_win.topLeft.x, uh_y);
	  rec_win.topLeft.x += FntCharsWidth(pa_cur, uh_len);
	  MemPtrFree(pa_cur);
	}
      }
    }

    // Le mode de paiement
    if (ps_tr->ui_rec_mode != MODE_UNKNOWN)
    {
      // Le séparateur
      SysCopyStringResource(ra_tmp, strTransListSepAmountMode);
      uh_len = StrLen(ra_tmp);
      WinDrawChars(ra_tmp, uh_len, rec_win.topLeft.x, uh_y);
      rec_win.topLeft.x += FntCharsWidth(ra_tmp, uh_len);

      // Le mode de paiement
      pa_cur = [[oMaTirelire mode] fullNameOfId:ps_tr->ui_rec_mode len:&uh_len];
      if (pa_cur != NULL)
      {
	WinDrawChars(pa_cur, StrLen(pa_cur), rec_win.topLeft.x, uh_y);
	MemPtrFree(pa_cur);
      }
    }

    // Le numéro du chèque
    if (b_future == false && ps_tr->ui_rec_check_num)
    {
      uh_y += uh_hfont;

      StrIToA(ra_date, s_options.ps_check_num->ui_check_num);
      SysCopyStringResource(ra_format, strTransListCheckNum);
      uh_len = StrPrintF(ra_tmp, ra_format, ra_date);
      WinDrawChars(ra_tmp, uh_len, uh_left_align, uh_y);
    }

    // Le numéro de relevé
    if (b_future == false && ps_tr->ui_rec_stmt_num)
    {
      uh_y += uh_hfont;

      StrIToA(ra_date, s_options.ps_stmt_num->ui_stmt_num);
      SysCopyStringResource(ra_format, strTransListStatementNum);
      uh_len = StrPrintF(ra_tmp, ra_format, ra_date);
      WinDrawChars(ra_tmp, uh_len, uh_left_align, uh_y);
    }

    // Les informations de répétition
    if (ps_tr->ui_rec_repeat)
    {
      struct s_rec_repeat *ps_repeat;
      UInt16 uh_rsc, uh_freq;
      Boolean b_format = false;

      uh_y += uh_hfont;

      ps_repeat = s_options.ps_repeat;

      uh_freq = ps_repeat->uh_repeat_freq;

      switch (ps_repeat->uh_repeat_type)
      {
      case REPEAT_WEEKLY:
	if (uh_freq == 1)
	  uh_rsc = strTransListRepeatWeekly;
	else
	{
	  uh_rsc = strTransListRepeatNweekly;
	  b_format = true;
	}
	break;

      case REPEAT_MONTHLY_END:
	uh_rsc = strTransListRepeatMonthlyEnd;
	break;

      default:			/* REPEAT_MONTHLY */
	switch (uh_freq)
	{
	case 1:			/* Tous les mois */
	  uh_rsc = strTransListRepeatMonthly;
	  break;

	case 12:		/* Tous les ans */
	  uh_rsc = strTransListRepeatAnnually;
	  break;

	case 2 * 12:		/* Tous les X ans */
	case 3 * 12:
	case 4 * 12:
	case 5 * 12:
	  uh_rsc = strTransListRepeatNannually;
	  uh_freq /= 12;
	  b_format = true;
	  break;

	default:		/* Tous les X mois */
	  uh_rsc = strTransListRepeatNmonthly;
	  b_format = true;
	  break;
	}
	break;
      }

      // Format en fonction de la répétition
      if (b_format)
      {
	SysCopyStringResource(ra_format, uh_rsc);
	StrPrintF(ra_tmp, ra_format, uh_freq);
      }
      else
	SysCopyStringResource(ra_tmp, uh_rsc);

      WinDrawChars(ra_tmp, StrLen(ra_tmp), uh_left_align, uh_y);

      // XXX Date de fin de répétition XXXX
    }

    // Les informations de transfert
    if (ps_tr->ui_rec_xfer)
    {
      UInt32 ul_id = s_options.ps_xfer->ul_id;

      uh_y += uh_hfont;

      /* On a le unique ID du lien */
      if (ps_tr->ui_rec_xfer_cat == 0)
      {
	UInt16 uh_index, uh_category;

	// Il faut que le unique ID soit possible
	if (ul_id == 0
	    || ul_id > 0xffffffUL
	    || DmFindRecordByID(oTransactions->db, ul_id,&uh_index) != 0)
	  goto link_cat_not_found;

	DmRecordInfo(oTransactions->db, uh_index, &uh_category,
		     NULL, NULL);
	ul_id = (uh_category & dmRecAttrCategoryMask);
      }

      /* Affichage */
      CategoryGetName(oTransactions->db, (UInt16)ul_id, ra_tmp);
      if (ra_tmp[0] != '\0')
      {
	SysCopyStringResource(ra_format,
			      ps_tr->l_amount > 0
			      ? strTransListXferFrom : strTransListXferTo);
	uh_len = StrLen(ra_format);
	WinDrawChars(ra_format, uh_len, uh_left_align, uh_y);

	/* Le nom du compte en gras */
	rec_win.topLeft.x = uh_left_align + FntCharsWidth(ra_format, uh_len);
	FntSetFont(boldFont);
	WinDrawChars(ra_tmp, StrLen(ra_tmp), rec_win.topLeft.x, uh_y);
	FntSetFont(stdFont);
      }
      else
      {
    link_cat_not_found:
	SysCopyStringResource(ra_tmp,
			      ps_tr->l_amount > 0
			      ? strTransListXferFromUnknown
			      : strTransListXferToUnknown);
	WinDrawChars(ra_tmp, StrLen(ra_tmp), uh_left_align, uh_y);
      }
    }

    // Le type
    if (uh_type != TYPE_UNFILED)
    {
      UInt16 uh_max_width = rec_win.extent.x - 3 - 2;

      uh_y += uh_hfont;

      SysCopyStringResource(ra_format, strTransListType);

      uh_max_width -= FntCharsWidth(ra_format, StrLen(ra_format));
      uh_max_width += FntCharsWidth("%s", 2); // on a un format...

      pa_cur = [oTypes fullNameOfId:uh_type
		       len:&uh_len truncatedTo:uh_max_width];
      uh_len = StrPrintF(ra_tmp, ra_format, pa_cur  ? : "?");
      if (pa_cur != NULL)
	MemPtrFree(pa_cur);

      WinDrawChars(ra_tmp, uh_len, uh_left_align, uh_y);
    }

    // Les sous-opérations (seulement si on n'affiche pas une sous-opération)
    if (b_split == false && ps_tr->ui_rec_splits)
    {
      FOREACH_SPLIT_DECL;	// ps_cur_split et __uh_num

      uh_y += uh_hfont;

      SysCopyStringResource(ra_format, strTransListNumSplits);

      uh_len = StrPrintF(ra_tmp, ra_format, s_options.ps_splits->uh_num);

      WinDrawChars(ra_tmp, uh_len, uh_left_align, uh_y);

      if (uh_num_splits_lines > 0)
      {
	UInt16 uh_indent, uh_len, uh_tmp_width;
	UInt16 uh_max_width = rec_win.extent.x - 3 - 2;
	Int16 h_width;

	FntSetFont(symbolFont);
	uh_indent = FntCharWidth('\023') + 3;

	uh_max_width -= uh_indent;

	FOREACH_SPLIT(&s_options)
	{
	  uh_y += uh_hfont;

	  // Ligne 1 : Le symbole de split...
	  FntSetFont(symbolFont);
	  WinDrawChars("\023", 1, uh_left_align, uh_y);

	  // ...et la description (une seule ligne)
	  if (is_empty(ps_cur_split->ra_desc) == false)
	  {
	    FntSetFont(stdFont);
	    uh_len = StrLen(ps_cur_split->ra_desc);
	    h_width = prepare_truncating(ps_cur_split->ra_desc, &uh_len,
					 uh_max_width);
	    WinDrawTruncatedChars(ps_cur_split->ra_desc, uh_len,
				  uh_left_align + uh_indent, uh_y, h_width);

	    uh_y += uh_hfont;
	  }

	  // Ligne 2 : Le montant en gras sans la devise...
	  FntSetFont(boldFont);
	  Str100FToA(ra_tmp, ps_tr->l_amount < 0
		     ? - ps_cur_split->l_amount : ps_cur_split->l_amount,
		     &uh_len, ps_infos->a_dec_separator);
	  WinDrawChars(ra_tmp, uh_len, uh_left_align + uh_indent, uh_y);

	  uh_tmp_width = FntCharsWidth(ra_tmp, uh_len);

	  // ...une virgule de séparation
	  FntSetFont(stdFont);
	  WinDrawChars(", ", 2, uh_left_align + uh_indent + uh_tmp_width, uh_y);
	  uh_tmp_width += FntCharsWidth(", ", 2);

	  // ...et le type
	  pa_cur = [oTypes fullNameOfId:ps_cur_split->ui_type
			   len:&uh_len truncatedTo:uh_max_width - uh_tmp_width];
	  if (pa_cur != NULL)
	  {
	    WinDrawChars(pa_cur, uh_len,
			 uh_left_align + uh_indent + uh_tmp_width, uh_y);
	    MemPtrFree(pa_cur);
	  }

	  uh_num_splits_lines -= 2;
	  if (uh_num_splits_lines == 0)
	    break;
	}
      }
    }

    // Sauvé par DrawFrame()
    if (oMaTirelire->uh_color_enabled)
      WinPopDrawState();
  }

  // Si la description avait été recopiée pour une opération dans le futur
  if (b_free_note)
    MemPtrFree(pa_note);

  FntSetFont(uh_save_font);

  [oTransactions getFree:ps_tr];

  return win_handle;
}


@implementation TransScrollList

- (TransScrollList*)initScrollList:(UInt16)uh_table inForm:(BaseForm*)oForm
			  numItems:(UInt16)uh_num_items
			itemHeight:(UInt16)uh_item_height
{
  self->oTransactions = [oMaTirelire transaction];

  // On se cale à la fin de la liste
  self->uh_root_item = dmMaxRecordIndex;

  return [super initScrollList:uh_table inForm:oForm
		numItems:uh_num_items
		itemHeight:uh_item_height];
}


//
// En fonction de self->uh_root_item doit renvoyer le dernier item
// visible dans la table. Dépend de l'implémentation et n'est utile
// que si à un moment self->uh_current_item != SCROLLLIST_NO_CURRENT
- (UInt16)getLastVisibleItem
{
  UInt16 uh_record_num;

  if (self->uh_num_items == 0)
    return 0;

  uh_record_num = self->uh_root_item;

  DmSeekRecordInCategory(self->oTransactions->db, &uh_record_num,
			 self->uh_tbl_num_lines - 1,
			 dmSeekForward,
			 self->oTransactions->ps_prefs->ul_cur_category);

  return uh_record_num;
}


//
// Met à jour self->uh_max_root_item qui est la valeur max de
// uh_root_item de façon à ce que la table soit toujours remplie.
// Cette méthode est à appeler dès que le contenu de la liste change
// (ajout ou retrait d'élément, changement d'ordre) ou bien lorsque le
// nombre d'éléments de la table change
- (void)computeMaxRootItem
{
  self->uh_max_root_item = 0;

  if (self->uh_num_items > 0)
  {
    UInt16 uh_record_num = dmMaxRecordIndex;

    DmSeekRecordInCategory(self->oTransactions->db, &uh_record_num,
			   self->uh_tbl_num_lines - 1,
			   dmSeekBackward,
			   self->oTransactions->ps_prefs->ul_cur_category);

    self->uh_max_root_item = uh_record_num;
  }
}


- (void)initRecordsCount
{
  self->uh_num_items
    = DmNumRecordsInCategory(self->oTransactions->db,
			     self->oTransactions->ps_prefs->ul_cur_category);

  // On passe à papa qui va calculer les sommes de chaque compte
  [super initRecordsCount];
}


//
// - initialise self->l_sum
- (void)computeSum
{
  DmOpenRef db;
  struct s_db_prefs *ps_db_prefs;
  MemHandle pv_tr;
  const struct s_transaction *ps_tr;
  void *pv_sum;
  t_amount l_sum;
  PROGRESSBAR_DECL;
  UInt16 uh_cur_account, index, uh_date;

  db = self->oTransactions->db;
  ps_db_prefs = self->oTransactions->ps_prefs;
  uh_cur_account = ps_db_prefs->ul_cur_category;

  switch (ps_db_prefs->ul_sum_type)
  {
  case VIEW_TODAY:
  case VIEW_DATE:
  case VIEW_TODAY_PLUS:
    pv_sum = &&date;
    break;
  case VIEW_WORST:		// Marche pour les prop. compte car tjs pointé
    pv_sum = &&worst;
    break;
  case VIEW_CHECKED:
    pv_sum = &&checked;
    break;
  case VIEW_MARKED:
    pv_sum = &&marked;
    break;
  case VIEW_CHECKNMARKED:
    pv_sum = &&checknmarked;
    break;
  default:		// VIEW_ALL
    pv_sum = &&add;
    break;
  }

  uh_date = [self->oTransactions sumDate:-1];	// -1 == prend le type des préf

  l_sum = 0;

  PROGRESSBAR_BEGIN(DmNumRecords(db), strProgressBarAccountBalance);

  index = 0;
  while ((pv_tr = DmQueryNextInCategory(db, &index, uh_cur_account)) // PG
	 != NULL)
  {
    ps_tr = MemHandleLock(pv_tr);

    goto *pv_sum;

 date:
    if (DateToInt(ps_tr->s_date) == 0	// Propriétés du compte
	|| uh_date >= (ps_tr->ui_rec_value_date
		       ? DateToInt(value_date_extract(ps_tr))
		       : DateToInt(ps_tr->s_date)))
      goto add;
    goto next;

 worst:
    // Marche pour les prop. compte car tjs pointé
    if (ps_tr->ui_rec_checked || ps_tr->l_amount < 0)
      goto add;
    goto next;

 checked:
    if (ps_tr->ui_rec_checked)
      goto add;
    goto next;

 marked:
    if (ps_tr->ui_rec_marked)
      goto add;
    goto next;

 checknmarked:
    if (ps_tr->ui_rec_checked || ps_tr->ui_rec_marked)
    {
  add:
      l_sum += ps_tr->l_amount;
    }

 next:
    MemHandleUnlock(pv_tr);

    PROGRESSBAR_INLOOP(index, 50); // OK

    index++;
  }

  PROGRESSBAR_END;

  self->l_sum = l_sum;
}


//
// Position de la première ligne de la table par rapport à tous les
// éléments (self->uh_num_items). Par exemple dans le cas de la liste
// des enregistrements d'une catégorie, self->uh_root_idx représente
// l'index global de l'enregistrement toutes catégories confondues.
- (UInt16)currentListPos
{
  return DmPositionInCategory(self->oTransactions->db, self->uh_root_item,
			      self->oTransactions->ps_prefs->ul_cur_category);
}


- (void)goto:(UInt16)uh_new_root_item
{
  UInt32 ui_mask, ui_match = 0;

  switch (uh_new_root_item)
  {
  case SCROLLLIST_GOTO_DATE:
  {
    Char ra_title[64];
    DmOpenRef db;
    MemHandle pv_tr;
    const struct s_transaction *ps_tr;
    PROGRESSBAR_DECL;
    DateType s_date;
    UInt16 uh_account, index;
    UInt16 uh_day, uh_month, uh_year, uh_cur_date;
    Boolean b_value_date;

    /* Par défaut on propose la date d'aujourd'hui */
    DateSecondsToDate(TimGetSeconds(), &s_date);
    uh_day = s_date.day;
    uh_month = s_date.month;
    uh_year = s_date.year + firstYear;

    SysCopyStringResource(ra_title, strTransListGotoDate);
    if (SelectDay(selectDayByDay, &uh_month, &uh_day, &uh_year, ra_title) == 0)
      return;

    s_date.day = uh_day;
    s_date.month = uh_month;
    s_date.year = uh_year - firstYear;

    uh_day = DateToInt(s_date);

    db = self->oTransactions->db;
    uh_account = self->oTransactions->ps_prefs->ul_cur_category;

    // Si on ne trouve pas on ira à la fin...
    uh_new_root_item = SCROLLLIST_GOTO_BOTTOM;

    // En fonction de la date de valeur ?
    b_value_date = self->oTransactions->ps_prefs->ul_sort_type;

    // Search the first matching transaction (may be the account properties)
    PROGRESSBAR_BEGIN(DmNumRecords(db), strProgressBarGotoSearch);

    index = 0;
    while ((pv_tr = DmQueryNextInCategory(db, &index, uh_account)) != NULL)//PG
    {
      ps_tr = MemHandleLock(pv_tr);

      uh_cur_date = DateToInt(ps_tr->s_date);

      if (b_value_date && ps_tr->ui_rec_value_date)
	uh_cur_date = DateToInt(*(DateType*)ps_tr->ra_note);

      MemHandleUnlock(pv_tr);

      if (uh_day <= uh_cur_date)
      {
	uh_new_root_item = index;
	break;
      }

      PROGRESSBAR_INLOOP(index, 50); // OK

      index++;
    }

    PROGRESSBAR_END;
  }
  break;

  case SCROLLLIST_GOTO_FIRST_NOT_CHECKED:
  case SCROLLLIST_GOTO_NEXT_NOT_CHECKED:
    ui_mask = RECORD_CHECKED;
    goto search;

  case SCROLLLIST_GOTO_FIRST_NOT_FLAGGED:
  case SCROLLLIST_GOTO_NEXT_NOT_FLAGGED:
    ui_mask = RECORD_MARKED;
    goto search;

  case SCROLLLIST_GOTO_FIRST_NOT_CHK_FLG:
  case SCROLLLIST_GOTO_NEXT_NOT_CHK_FLG:
    ui_mask = (RECORD_CHECKED|RECORD_MARKED);
    goto search;

  case SCROLLLIST_GOTO_FIRST_FLAGGED:
  case SCROLLLIST_GOTO_NEXT_FLAGGED:
    ui_mask = RECORD_MARKED;
    ui_match = RECORD_MARKED;

 search:
    {
      DmOpenRef db;
      MemHandle pv_tr;
      const struct s_transaction *ps_tr;
      UInt16 uh_account, index;

      index = 0;

      // SCROLLLIST_GOTO_NEXT_...
      if (uh_new_root_item >= SCROLLLIST_GOTO_NEXT_NOT_CHECKED)
	index = self->uh_root_item + 1;

      db = self->oTransactions->db;
      uh_account = self->oTransactions->ps_prefs->ul_cur_category;

      // Search the first matching transaction (may be the account properties)
      while ((pv_tr = DmQueryNextInCategory(db, &index, uh_account)) // XXX PG
	     != NULL)
      {
	ps_tr = MemHandleLock(pv_tr);

	if ((ps_tr->ui_rec_flags & ui_mask) == ui_match)
	{
	  uh_new_root_item = index;
	  MemHandleUnlock(pv_tr);
	  goto super_goto;
	}

	MemHandleUnlock(pv_tr);
	index++;
      }
    }

    // Not found, don't move...
    return;
  }

  // On passe à Papa...
 super_goto:
  [super goto:uh_new_root_item];
}


- (UInt16)scrollRootAdjusted:(Int16)h_lines_to_scroll
{
  UInt16 uh_new_root_idx = self->uh_root_item;

  // winDown
  if (h_lines_to_scroll >= 0)
  {
    // On essaie une page en avant
    if ([self->oTransactions seekRecord:&uh_new_root_idx
	     offset:h_lines_to_scroll direction:dmSeekForward] == false
	|| uh_new_root_idx > self->uh_max_root_item)
      uh_new_root_idx = self->uh_max_root_item;
  }
  // winUp
  else
  {
    h_lines_to_scroll = - h_lines_to_scroll;

    if ([self->oTransactions seekRecord:&uh_new_root_idx
	     offset:h_lines_to_scroll direction:dmSeekBackward] == false)
    {
      // Pas assez d'enregistrements pour remplir une page
      uh_new_root_idx = 0;
      [self->oTransactions seekRecord:&uh_new_root_idx
	   offset:0 direction:dmSeekForward];
    }
  }

  return uh_new_root_idx;
}


- (Boolean)getDataForItem:(UInt16*)puh_item row:(UInt16)uh_row
		       in:(UInt32*)pul_data
{
  if (DmQueryNextInCategory(self->oTransactions->db, puh_item, // No PG
			    // Ici on peut accéder directement aux prefs
			    // sans passer par -getPrefs car cette
			    // méthode a forcément déjà été appelée
			    self->oTransactions->ps_prefs->ul_cur_category))
  {
    DmRecordInfo(self->oTransactions->db, *puh_item, NULL, pul_data, NULL);
    return true;
  }

  return false;
}


- (Boolean)getItem:(UInt16*)puh_cur next:(Boolean)b_next
{
  UInt16 uh_record_num = *puh_cur;

  if (DmSeekRecordInCategory(self->oTransactions->db, &uh_record_num,
			     1, b_next ? dmSeekForward : dmSeekBackward,
			     self->oTransactions->ps_prefs->ul_cur_category)
      == errNone)
  {
    *puh_cur = uh_record_num;
    return true;
  }

  return false;
}


- (void)initColumns
{
  self->pf_line_draw = trans_draw_record;

  self->uh_flags = SCROLLLIST_BOTTOP | SCROLLLIST_FULL;

  [super initColumns];
}


// Clic long sur une opération
- (WinHandle)longClicOnRow:(UInt16)uh_row topLeftIn:(PointType*)pp_win
{
  return trans_draw_longclic_frame(self->oTransactions, pp_win,
				   // Index de l'enregistrement
				   // correspondant à la ligne
				   // sélectionnée
				   TblGetRowID(self->pt_table, uh_row), 0);
}


//
// Un clic court vient d'être effectué sur la ligne uh_row
// Il a commencé à l'absisse uh_from_x pour se terminer à celle uh_to_x.
// Renvoie true si on a traité ce clic, false sinon...
- (Boolean)shortClicOnRow:(UInt16)uh_row
		     from:(UInt16)uh_from_x to:(UInt16)uh_to_x
{
  struct s_misc_infos *ps_infos = &oMaTirelire->s_misc_infos;
  struct s_transaction *ps_tr;
  RectangleType s_rect;
  UInt16 uh_rec_index;
  Boolean b_account_prop;

  // Coordonnées de la ligne
  [self getRow:uh_row bounds:&s_rect];

  // Index de l'enregistrement correspondant à la ligne sélectionnée
  uh_rec_index = TblGetRowID(self->pt_table, uh_row);

  // Propriétés de compte ?
  ps_tr = [self->oTransactions getId:uh_rec_index];
  b_account_prop = DateToInt(ps_tr->s_date) == 0;
  [self->oTransactions getFree:ps_tr];

  if (b_account_prop == false)
  {
    // On vient de tirer un trait vers la date
    if (uh_from_x > s_rect.topLeft.x + ps_infos->uh_date_width + 5
	&& uh_to_x < s_rect.topLeft.x + ps_infos->uh_date_width - 5)
    {
      // On édite la date de l'opération
      [(TransListForm*)self->oForm transactionDateEdit:uh_rec_index];
      return true;
    }

    // On vient de tirer un trait de la date
    if (uh_from_x < s_rect.topLeft.x + ps_infos->uh_date_width - 5
	&& uh_to_x > s_rect.topLeft.x + ps_infos->uh_date_width + 5)
    {
      ListType *pt_list;

      // On met en place les lignes (Dé-)pointer et (Dé-)marquer
      pt_list = [self->oForm objectPtrId:TransListActionList];

      ps_tr = [self->oTransactions getId:uh_rec_index];

      SysCopyStringResource
	(LstGetSelectionText(pt_list, 5),
	 strTransListContextMenuClear + ps_tr->ui_rec_checked);

      SysCopyStringResource
	(LstGetSelectionText(pt_list, 6),
	 strTransListContextMenuFlag + ps_tr->ui_rec_marked);

      [self->oTransactions getFree:ps_tr];

      switch ([self->oForm contextPopupList:TransListActionList
		   x:uh_to_x
		   y:s_rect.topLeft.y + s_rect.extent.y
		   selEntry:0])	// Toujours sélection de la première entrée
      {
      case 0:			// Copier
      {
	UInt16 uh_choice = FrmAlert(alertCopy);

	if (uh_choice != 2)
	{
	  TransFormCall(((TransListForm*)self->oForm)->s_trans_form,
			0,
			0, 0,	    // pre_desc
			1, uh_choice, // copy
			uh_rec_index);
	}
      }
      break;

      case 1:			// Supprimer
	// On demande confirmation
	if (FrmAlert(alertTransactionDelete) != 0)
	{
	  // Alarme OK
	  [self->oTransactions deleteId:((UInt32)uh_rec_index
					 | TR_DEL_XFER_LINK_TOO
					 | TR_DEL_MANAGE_ALARM)];

	  // Remaniement de la liste : destiné au formulaire qui nous
	  // contient, donc nous-mêmes
#define update_code (((UInt32)uh_rec_index << 16) \
		     | frmMaTiUpdateList | frmMaTiUpdateListTransactions)
	  [self->oForm sendCallerUpdate:update_code]; // Pour nous-mêmes...
#undef update_code

	  // Redraw de l'écran
	  UniqueUpdateForm(FrmGetFormId(self->oForm->pt_frm),
			   frmRedrawUpdateCode);
	}
	break;

      case 2:			// Date
	 [(TransListForm*)self->oForm transactionDateEdit:uh_rec_index];
	break;

      case 3:			// Heure
	 [(TransListForm*)self->oForm transactionTimeEdit:uh_rec_index];
	break;

      case 4:			// Éditer
	[self clicOnRow:uh_row];
	break;

      case 5:			// Pointer
	// Comme si on avait cliqué pour pointer, sauf qu'on fait
	// juste la comparaison par rapport à la frontière
	// pointé/marqué, donc 0 == pointé
	uh_to_x = 0;
	goto check_or_mark;

      case 6:			// Marquer
	// Comme si on avait cliqué pour marquer
	uh_to_x = s_rect.extent.x;
	goto check_or_mark;

      default:
	break;
      }

      return true;
    }
  }

  // En fonction de l'absisse du clic
  uh_to_x -= s_rect.topLeft.x;

  // On vient de cliquer dans la somme
  if (self->oTransactions->ps_prefs->ul_check_locked == 0
      && uh_to_x >= s_rect.extent.x - ps_infos->uh_amount_width)
  {
    struct s_db_prefs *ps_db_prefs;
    union u_rec_flags u_flags;
    UInt32 ui_stmt_num = STMT_NUM_POPUP_KEEP;
    UInt16 uh_win_flags;
    Boolean b_check, b_add;

 check_or_mark:
    ps_tr = [self->oTransactions recordGetAtId:uh_rec_index];

    u_flags = ps_tr->u_flags;

    // Partie marqué ~ les deux derniers chiffres du montant
    if (b_account_prop		// Si compte => toujours marqué...
	|| uh_to_x >= s_rect.extent.x - ps_infos->uh_amount_width / 4)
    {
      b_add = (u_flags.s_bit.ui_marked ^= 1);
      b_check = false;
    }
    // Juste pointé
    else
    {
      struct s_account_prop *ps_prop;
      Boolean b_stmt_num;

      // Statement num management ?
      ps_prop = [self->oTransactions accountProperties:ACCOUNT_PROP_CURRENT
		     index:NULL];
      b_stmt_num = ps_prop->ui_acc_stmt_num;
      MemPtrUnlock(ps_prop);

      // Yes, we have to manage the statement number
      if (b_stmt_num)
      {
	struct s_rec_options s_options;
	UInt16 uh_y = s_rect.topLeft.y + s_rect.extent.y;

	options_extract(ps_tr, &s_options);

	// Cleared transaction
	if (u_flags.s_bit.ui_checked)
	{
	  // A statement number is present
	  if (u_flags.s_bit.ui_stmt_num)
	  {
	    // ( Keep, Cancel ) noListSelection==DoNothing
	    ui_stmt_num =
	      [(MaTiForm*)self->oForm statementNumberPopup:
			    STMT_NUM_POPUP_TYPE_KEEP_CANCEL
			  list:TransListDescList
			  posx:uh_to_x posy:uh_y
			  currentNum:s_options.ps_stmt_num->ui_stmt_num];
	  }
	}
	// Non-cleared transaction
	else
	{
	  // A statement number is present
	  if (u_flags.s_bit.ui_stmt_num)
	  {
	    // ( Keep, Another... ) noListSelection==DoNothing
	    ui_stmt_num =
	      [(MaTiForm*)self->oForm statementNumberPopup:
			    STMT_NUM_POPUP_TYPE_KEEP_ANOTHER
			  list:TransListDescList
			  posx:uh_to_x posy:uh_y
			  currentNum:s_options.ps_stmt_num->ui_stmt_num];

	    if (ui_stmt_num == STMT_NUM_POPUP_ANOTHER)
	      goto another_stmt_num;
	  }
	  // No statement number
	  else
	  {
	    // ( (last num, )? (current#, next#, )? Another... )
	    // noListSelection==DoNothing
	    ui_stmt_num = [(MaTiForm*)self->oForm statementNumberPopup:
					STMT_NUM_POPUP_TYPE_LIST_ANOTHER
				      list:TransListDescList
				      posx:uh_to_x posy:uh_y currentNum:0];

	    if (ui_stmt_num == STMT_NUM_POPUP_ANOTHER)
	    {
	  another_stmt_num:
	      // Le no ne change pas tout de suite
	      ui_stmt_num = STMT_NUM_POPUP_KEEP;

	      // Edit the transaction with focus
	      TransFormCallFull(((TransListForm*)self->oForm)->s_trans_form,
				0,
				0, 0, 0,	// pre_desc, shortcut, param
				0, 0,		// copy
				1,		// focus to stmt # field
				uh_rec_index,	// record index
				-1);		// no split index
	    }
	  }
	} // Non-cleared transaction

	// Clic à l'extérieur de la liste => on ne fait rien
	if (ui_stmt_num == STMT_NUM_POPUP_DO_NOTHING)
	{
	  [self->oTransactions recordRelease:false];
	  return true;
	}

      }	// Statement number management

      b_add = (u_flags.s_bit.ui_checked ^= 1);
      b_check = true;
    }

    DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
	    &u_flags, sizeof(u_flags));

    uh_win_flags = 0;

    // Haute densité ?
    if (oMaTirelire->uh_high_density)
      uh_win_flags = DRAW_HI_DENSITY;

    // Si on a la couleur...
    if (oMaTirelire->uh_color_enabled)
    {
      WinPushDrawState();

      WinSetBackColor(UIColorGetTableEntryIndex(UIFieldBackground));
      WinSetForeColor(UIColorGetTableEntryIndex(UIObjectForeground));

      uh_win_flags |= DRAW_COLORED;

      // Avant         | Après pointage | Après marquage
      // --------------+----------------+---------------
      // rien          | InvertRect     | draw_marked
      // pointé        | redraw line    | draw_marked
      // marqué        | redraw line    | redraw line
      // pointé&marqué | redraw line    | redraw line

      // On pointe / dépointe
      if (b_check)
      {
	// On vient de pointer une opération NON marquée
	if ((u_flags.ui_all & (RECORD_CHECKED|RECORD_MARKED)) ==RECORD_CHECKED)
	{
	  s_rect.topLeft.x += s_rect.extent.x - ps_infos->uh_amount_width;
	  s_rect.extent.x = ps_infos->uh_amount_width;

	  WinInvertRectangleColor(&s_rect);
	}
	// Autres cas de pointage
	else
	{
	  RectangleType s_bounds, s_clip;

	  // Redraw only the amount part of the line thanks to clipping
      redraw_line:
	  WinGetClip(&s_clip);

	  s_bounds.topLeft.x
	    = s_rect.topLeft.x + s_rect.extent.x - ps_infos->uh_amount_width;
	  s_bounds.topLeft.y = s_rect.topLeft.y;
	  s_bounds.extent.x = ps_infos->uh_amount_width;
	  s_bounds.extent.y = s_rect.extent.y;

	  WinEraseRectangle(&s_bounds, 0);

	  WinSetClip(&s_bounds);

	  // On redessine la ligne
	  self->pf_line_draw(self->pt_table, uh_row, 0, &s_rect);

	  WinSetClip(&s_clip);
	}
      }
      // On marque / démarque
      else
      {
	// On vient de démarquer l'opération
	if (b_add == false)
	  goto redraw_line;

	// On vient de marquer l'opération
    flag_line:
	__draw_marked(s_rect.topLeft.x + s_rect.extent.x - 1,
		      s_rect.topLeft.y + s_rect.extent.y - 1,
		      (self->uh_tbl_item_height + 2) / 3,
		      uh_win_flags | (UInt16)u_flags.s_bit.ui_checked);
      }

      // Il se peut qu'on arrive ici après un goto flag_line de la partie N&B
      if (uh_win_flags & DRAW_COLORED)
	WinPopDrawState();
    }
    // En noir & blanc
    else
    {
      // On marque / démarque
      if (b_check == false)
	goto flag_line;

      // On pointe / dépointe
      s_rect.topLeft.x += s_rect.extent.x - ps_infos->uh_amount_width;
      s_rect.extent.x = ps_infos->uh_amount_width;

      WinInvertRectangle(&s_rect, 0);
    }

    ps_db_prefs = self->oTransactions->ps_prefs;

    // On est en train de faire un (dé)pointage
    if (b_check)
      //         Si la somme totale est la somme des pointés
      b_check = (ps_db_prefs->ul_sum_type == VIEW_CHECKED
		 // OU BIEN la somme des pointés ou marqués
		 || (ps_db_prefs->ul_sum_type == VIEW_CHECKNMARKED
		     && u_flags.s_bit.ui_marked == 0)
		 // OU BIEN la somme de tout sans les NON pointés
		 || (ps_db_prefs->ul_sum_type == VIEW_WORST
		     && ps_tr->l_amount > 0));
    // On est en train de faire un (dé)marquage
    else
      //         Somme des marqués
      b_check = (ps_db_prefs->ul_sum_type == VIEW_MARKED
		 // OU BIEN la somme des pointés ou marqués
		 || (ps_db_prefs->ul_sum_type == VIEW_CHECKNMARKED
		     && u_flags.s_bit.ui_checked == 0));

    // Modification de la somme générale
    if (b_check)
    {
      if (b_add == false)
	self->l_sum -= ps_tr->l_amount;
      else
	self->l_sum += ps_tr->l_amount;
    }

    [self->oTransactions recordRelease:true];

    // On doit faire quelque chose avec le numéro de relevé
    if (ui_stmt_num != STMT_NUM_POPUP_KEEP)
    {
      if (ui_stmt_num == STMT_NUM_POPUP_CANCEL)
	[self->oTransactions deleteStmtNumOption:uh_rec_index];
      else
      {
	[self->oTransactions addStmtNumOption:ui_stmt_num forId:uh_rec_index];

	// Nouveau dernier numéro de relevé saisi
	gui_last_stmt_num = ui_stmt_num;
      }
    }

    if (b_check)
    {
      [self displaySum];

      // Gestion du découvert
      [(TransListForm*)self->oForm warningOverdrawn:false];
    }

    return true;
  }

  // Si rien de tout ça => clic simple
  [self clicOnRow:uh_row];

  return true;
}


//
// Sélection par le clavier sur la ligne uh_row
- (void)clicOnRow:(UInt16)uh_row
{
  struct s_transaction *ps_tr;
  UInt16 uh_rec_index;

  // On édite l'opération OU les propriétés du compte
  // Index de l'enregistrement correspondant à la ligne sélectionnée
  uh_rec_index = TblGetRowID(self->pt_table, uh_row);

  // Propriétés de compte ?
  ps_tr = [self->oTransactions getId:uh_rec_index];

  // Propriétés du compte
  if (DateToInt(ps_tr->s_date) == 0)
    FrmPopupForm(AccountPropFormIdx);
  // Édition de l'opération
  else
  {
    TransFormCall(((TransListForm*)self->oForm)->s_trans_form,
		  0,
		  0, 0,		// pre_desc
		  0, 0,		// copy
		  uh_rec_index);
  }

  [self->oTransactions getFree:ps_tr];
}


- (UInt16)_changeHandFillIncObjs:(UInt16*)puh_objs
		 withoutDontDraw:(Boolean)b_without_dont_draw
{
  UInt16 uh_updown_arrows = 0;
  UInt16 uh_nb_objs = (2 * 2) + 1 + 1; // '+' + '-' + popup_types_somme + Somme

  switch ([oMaTirelire transaction]->ps_prefs->ul_sum_type)
  {
  default:
    if (b_without_dont_draw == false)
    {
      uh_updown_arrows = SCROLLLIST_CH_DONT_DRAW;
    case VIEW_TODAY:
    case VIEW_DATE:
    case VIEW_TODAY_PLUS:
      *puh_objs++ = bmpDateUp | uh_updown_arrows;
      *puh_objs++ = SumListDateUp | uh_updown_arrows;
      *puh_objs++ = bmpDateDown | uh_updown_arrows;
      *puh_objs++ = SumListDateDown | uh_updown_arrows;
      uh_nb_objs += 4;
    }
    break;
  }

  // Les boutons '+' et '-'
  *puh_objs++ = TransListDebit;
  *puh_objs++ = bmpMinus;

  *puh_objs++ = TransListCredit;
  *puh_objs++ = bmpPlus;

  if (b_without_dont_draw == false)
  {
    *puh_objs++ = SumListSumTypeList | SCROLLLIST_CH_DONT_DRAW;
    uh_nb_objs++;
  }

  *puh_objs++ = SumListSumTypePopup;

  *puh_objs = SumListSum;

  return uh_nb_objs;
}


- (void)flagUnflag:(UInt16)uh_action
{
  Transaction *oTransactions = self->oTransactions;
  struct s_transaction *ps_tr;
  PROGRESSBAR_DECL;
  union u_rec_flags u_flags;
  UInt16 index, uh_base, uh_num_to_flag;
  UInt16 uh_account = oTransactions->ps_prefs->ul_cur_category;
  Boolean b_flag, b_xor, b_check_warning;

  b_flag = (uh_action & SCROLLLIST_FLAG_FLAG);
  b_xor = (uh_action & SCROLLLIST_FLAG_INVERT) != 0;

  // Juste une page...
  if (uh_action & SCROLLLIST_FLAG_PAGE)
  {
    uh_base = self->uh_root_item;
    uh_num_to_flag = self->uh_tbl_num_lines;
  }
  // Tout
  else
  {
    uh_base = 0;
    uh_num_to_flag = DmNumRecords(oTransactions->db);
  }

  PROGRESSBAR_BEGIN(uh_num_to_flag, strProgressBarTransformFlagged);

  index = uh_base;
  while (uh_num_to_flag-- != 0
	 && DmQueryNextInCategory(oTransactions->db, &index, uh_account)) // PG
  {
    ps_tr = [oTransactions recordGetAtId:index];
    if (ps_tr != NULL)
    {
      u_flags = ps_tr->u_flags;

      if (b_xor)
	u_flags.s_bit.ui_marked ^= 1; // On inverse
      else
	u_flags.s_bit.ui_marked = b_flag;

      DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
	      &u_flags, sizeof(u_flags));

      [oTransactions recordRelease:true];
    }

    PROGRESSBAR_INLOOP(index - uh_base, 50); // OK

    index++;			// Suivant
  }

  PROGRESSBAR_END;

  b_check_warning = false;
  
  // On ne recalcule la somme que si le type de somme le nécessite...
  // XXX pourrait être optimisé dans la boucle précédente XXX
  switch (oTransactions->ps_prefs->ul_sum_type)
  {
    // Les types de somme qui dépendent des marqués
  case VIEW_MARKED:
  case VIEW_CHECKNMARKED:
    [self computeSum];
    b_check_warning = true;
    break;
  }

  [self redrawList];		// Ré-affiche la somme

  // Gestion du découvert
  if (b_check_warning)
    [(TransListForm*)self->oForm warningOverdrawn:false];
}

@end
