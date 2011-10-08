/* 
 * SumScrollList.m -- 
 * 
 * Author          : Maxime Soulé
 * Created On      : Thu Nov 18 21:56:43 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Jan 22 17:30:19 2008
 * Update Count    : 22
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: SumScrollList.m,v $
 * Revision 1.7  2008/02/01 17:32:23  max
 * New -computeAgainWithConvert: method.
 *
 * Revision 1.6  2008/01/14 15:55:33  max
 * Switch to new mcc.
 * Now handle navigator button presses in a generic way.
 *
 * Revision 1.5  2006/11/04 23:48:21  max
 * s/-exportNumLines/-exportInit/.
 * Add -exportEnd method.
 * Redraw only when the form is in the foreground.
 *
 * Revision 1.4  2006/06/28 09:42:07  max
 * s/pt_frm/oForm/g attribute.
 * Add -getTransaction:next:updateList:
 *
 * Revision 1.3  2005/10/11 19:12:04  max
 * Export feature added.
 * -shortClic* methods imported from CustomScrollList.
 *
 * Revision 1.2  2005/08/20 13:07:07  max
 * Add method +newInForm:.
 * Add draw_sum_line() function to help writing table drawing functions
 * in this kind of screen..
 *
 * Revision 1.1  2005/02/09 22:57:23  max
 * First import.
 *
 * ==================== RCS ==================== */

#include <Common/System/palmOneNavigator.h>

#define EXTERN_SUMSCROLLLIST
#include "SumScrollList.h"

#include "BaseForm.h"
#include "MaTirelire.h"

#include "float.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


void draw_sum_line(Char *pa_label, t_amount l_sum, RectangleType *prec_bounds,
		   UInt16 uh_flags)
{
  struct s_misc_infos *ps_infos;
  Char ra_buf[1 + 10 + 1 + 1];	// -99999999,99\0
  UInt16 uh_len, uh_amount_width;
  Int16 h_width;
  FontID uh_save_font;
  Boolean b_colored = false;

  // Si on a la couleur...
  if (oMaTirelire->uh_color_enabled)
  {
    struct s_mati_prefs *ps_prefs = &oMaTirelire->s_prefs;
    IndexedColorType a_color;

    WinPushDrawState();

    WinSetBackColor(UIColorGetTableEntryIndex(UIFieldBackground));
    a_color = UIColorGetTableEntryIndex(UIObjectForeground);

    if (l_sum >= 0)
    {
      if (ps_prefs->uh_list_flags & USER_CREDIT_COLOR)
	a_color = ps_prefs->ra_colors[COLOR_CREDIT];
    }
    else
    {
      if (ps_prefs->uh_list_flags & USER_DEBIT_COLOR)
	a_color = ps_prefs->ra_colors[COLOR_DEBIT];
    }

    WinSetTextColor(a_color);

    b_colored = true;
  }

  uh_save_font = FntSetFont(oMaTirelire->s_fonts.uh_list_font);

  ps_infos = &oMaTirelire->s_misc_infos;

  uh_amount_width = (uh_flags & DRAW_SUM_MIN_WIDTH)
    ? ps_infos->uh_amount_width : ps_infos->uh_max_amount_width;

  // Le label
  uh_len = StrLen(pa_label);
  h_width = prepare_truncating(pa_label, &uh_len,
			       prec_bounds->extent.x - uh_amount_width);
  WinDrawTruncatedChars(pa_label, uh_len,
			prec_bounds->topLeft.x, prec_bounds->topLeft.y,
			h_width);

  // La somme
  if ((uh_flags & DRAW_SUM_NO_AMOUNT) == 0)
  {
    Str100FToA(ra_buf, l_sum, &uh_len, ps_infos->a_dec_separator);
    WinDrawChars(ra_buf, uh_len,
		 prec_bounds->topLeft.x + prec_bounds->extent.x
		 - FntCharsWidth(ra_buf, uh_len),
		 prec_bounds->topLeft.y);
  }

  // Somme sélectionnée
  if (uh_flags & DRAW_SUM_SELECTED)
  {
    RectangleType s_rect;
    
    s_rect = *prec_bounds;
    s_rect.topLeft.x += s_rect.extent.x - uh_amount_width;
    s_rect.extent.x = uh_amount_width;

    if (b_colored)
      WinInvertRectangleColor(&s_rect);
    else
      WinInvertRectangle(&s_rect, 0);
  }

  if (b_colored)
    WinPopDrawState();
  else
    FntSetFont(uh_save_font);
}


@implementation SumScrollList

+ (SumScrollList*)newInForm:(BaseForm*)oForm
{
  return [super newScrollList:0 inForm:oForm
				numItems:0 itemHeight:0];
}


- (SumScrollList*)initScrollList:(UInt16)uh_dummy1 inForm:(BaseForm*)oForm
			numItems:(UInt16)uh_dummy2
		      itemHeight:(UInt16)uh_dummy3
{
  struct s_mati_prefs *ps_prefs;

  [super initScrollList:SumListTable inForm:oForm numItems:0
	 itemHeight:[oMaTirelire getFontHeight]];

  [self displaySum];

  // La barre de scroll à gauche ?
  ps_prefs = [oMaTirelire getPrefs];
  [self changeHand:ps_prefs->ul_left_handed redraw:false];

  return self;
}


- (Boolean)keyDown:(struct _KeyDownEventType*)ps_key
{
  UInt16 uh_line;

  // Right key simulates a clic on amount of the selected line to check/uncheck
  uh_line = self->uh_selected_line;
  if (uh_line != SCROLLLIST_NO_LINE)
  {
    switch (ps_key->chr)
    {
    case vchrNavChange:		// OK (only 5-way T|T)
      if ((ps_key->modifiers & autoRepeatKeyMask) == 0
	  &&
	  (ps_key->keyCode & (navBitsAll | navChangeBitsAll))
	  == (navBitRight | navChangeRight))
      {
    check:
	[self deselectLine];

	// INT16_MAX max positive value for an Int16
	[self shortClicOnRow:uh_line from:0 to:INT16_MAX];

	[self selectLine:uh_line];
	return true;
      }
      break;

      // De NavDirectionHSPressed()
    case vchrRockerRight:
      if (ps_key->modifiers & commandKeyMask)
	goto check;

      break;
    }
  }

  return [super keyDown:ps_key];
}


- (void)initRecordsCount
{
  self->b_deleted_items = false;

  [self computeEachEntrySum];
}


// Calcule le montant de chaque entrée de la liste
- (void)computeEachEntrySum
{
  [self computeEachEntryConvertSum];
}


// Convertit le montant de chaque entrée de la liste dans une autre devise
- (void)computeEachEntryConvertSum
{
  [self computeSum];
}


// Calcule la somme de toutes les entrées de la liste
- (void)computeSum
{
  [self subclassResponsibility];
}


// b_convert_sum == false => computeEachEntrySum
//               == true  => computeEachEntryConvertSum
- (void)computeAgainWithConvert:(Boolean)b_convert_sum
{
  Boolean b_is_at_end = (self->uh_root_item == self->uh_max_root_item);

  // Si au moins un item a été supprimé, on reprend tout de zéro (réalloc, etc.)
  if (self->b_deleted_items)
    [self initRecordsCount];
  // Sinon on part de l'endroit requis
  else if (b_convert_sum)
    [self computeEachEntryConvertSum];
  // idem
  else
    [self computeEachEntrySum];

  // Some items were deleted (flag set in -computeEachEntryConvertSum)
  if (self->b_deleted_items)
  {
    [self computeMaxRootItem];

    // On était en fond de liste, on y reste
    if (b_is_at_end)
      self->uh_root_item = self->uh_max_root_item;

    [self loadRecords];
  }
}


- (void)displaySum
{
  [self->oForm replaceField:REPLACE_FIELD_EXT | SumListSum
       withSTR:(Char*)self->l_sum
       len:REPL_FIELD_FDWORD | REPL_FIELD_KEEP_SIGN];
}


- (void)redrawList
{
  [super redrawList];

  [self displaySum];
}


- (void)updateWithoutRedraw
{
  Boolean b_form_drawn;

  [super updateWithoutRedraw];

  b_form_drawn = self->oForm->uh_form_drawn;
  self->oForm->uh_form_drawn = false;

  [self displaySum];

  self->oForm->uh_form_drawn = b_form_drawn;
}


// Une méthode plutôt qu'un attribut, ça permet de faire référence à
// une valeur qui peut bouger sans avoir à gérer ces changements nous
// mêmes
- (UInt16)amountWidth
{
  return oMaTirelire->s_misc_infos.uh_max_amount_width;
}


- (Boolean)shortClicOnRow:(UInt16)uh_row
		     from:(UInt16)uh_from_x to:(UInt16)uh_to_x
{
  RectangleType s_rect;
  UInt16 uh_amount_width = [self amountWidth];

  [self getRow:uh_row bounds:&s_rect];
  s_rect.topLeft.x += s_rect.extent.x - uh_amount_width;

  // Sélection / désélection de la somme (uh_to_x vaut -1 si via clavier)
  if ((Int16)uh_to_x > s_rect.topLeft.x)
  {
    t_amount l_amount = 0;
    Int16 h_selected;
    Boolean b_redraw_sum;

    // Renvoie -1 si rien n'a bougé
    // Renvoie 1 si la somme a été sélectionnée (passage de 0 à 1)
    // Renvoie 3 si pareil mais qu'il faut redessiner la somme complètement
    // Renvoie 0 si la somme a été désélectionnée (passage de 1 à 0)
    h_selected = [self shortClicOnSumOfRow:uh_row xPos:uh_to_x
		       amount:&l_amount];
    if (h_selected < 0)
      return true;

    b_redraw_sum = [self addAmount:l_amount selected:h_selected & 1];

    s_rect.extent.x = uh_amount_width;
    s_rect.extent.y = self->uh_tbl_item_height;

    if (oMaTirelire->uh_color_enabled == 0)
      WinInvertRectangle(&s_rect, 0);
    else
    {
      WinPushDrawState();

      WinSetBackColor(UIColorGetTableEntryIndex(UIFieldBackground));
      WinSetForeColor(UIColorGetTableEntryIndex(UIObjectForeground));

      if (h_selected == 1)
	WinInvertRectangleColor(&s_rect);
      else
      {
	RectangleType s_clip;

	// Redraw only the amount part of the line thanks to clipping
	WinGetClip(&s_clip);

	WinEraseRectangle(&s_rect, 0);

	WinSetClip(&s_rect);

	// On redessine la ligne
	[self getRow:uh_row bounds:&s_rect];
	self->pf_line_draw(self->pt_table, uh_row, 0, &s_rect);

	WinSetClip(&s_clip);
      }

      WinPopDrawState();
    }

    // La somme générale a changé...
    if (b_redraw_sum)
      [self displaySum];

    return true;
  }

  // Clic sur la partie description
  return [self shortClicOnLabelOfRow:uh_row xPos:uh_to_x];
}


// La somme l_amount vient de changer d'état en b_selected
// Il faut peut-être modifier self->l_sum et si c'est le cas, il faut
// renvoyer true.
// Renvoie true si la somme doit être rafaichie
- (Boolean)addAmount:(t_amount)l_amount selected:(Boolean)b_selected
{
  return false;
}


// Renvoie true si le clic a été traité
- (Boolean)shortClicOnLabelOfRow:(UInt16)uh_row xPos:(UInt16)uh_x
{
  // Rien à faire dans cette classe...
  return true;
}


//
// Renvoie -1 si rien n'a bougé
// Renvoie 1 si la somme a été sélectionnée (passage de 0 à 1)
// Renvoie 3 si pareil mais qu'il faut redessiner la somme complètement
// Renvoie 0 si la somme a été désélectionnée (passage de 1 à 0)
- (Int16)shortClicOnSumOfRow:(UInt16)uh_row xPos:(UInt16)uh_x
		      amount:(t_amount*)pl_amount
{
  // Par défaut, même comportement qu'un clic sur la description
  [self shortClicOnLabelOfRow:uh_row xPos:uh_x];
  return -1;
}


- (Int16)getTransaction:(UInt16)uh_index next:(Boolean)b_next
	     updateList:(Boolean)b_upddate_list
{
  if ([self getItem:&uh_index next:b_next])
  {
    Transaction *oTransactions = [oMaTirelire transaction];
    struct s_transaction *ps_tr;
    Boolean b_account_prop;

    // Il faut vérifier qu'il ne s'agit pas des propriétés du compte
    ps_tr = [oTransactions getId:uh_index];
    b_account_prop = DateToInt(ps_tr->s_date) == 0;
    [oTransactions getFree:ps_tr];

    if (b_account_prop == false)
    {
      if (b_upddate_list)
	[self updateWithoutRedraw];

      return uh_index;
    }
  }

  return -1;
}


//
// Pas d'export par défaut, sinon renvoie le format de chaque colonne
// dans ra_format terminé par \0
// *** TOUS CES ARGUMENTS SONT SUR 32 BITS ***
// - s	Char*
// - u	UInt32
// - f	100F
// - d  DateType
// - t  TimeType
// - b	Boolean
// - e  empty/skip
//
// Si ra_format vaut NULL, renvoie juste le fait qu'un export est
// possible ou non dans cette classe
//
// Renvoie 0 si cette liste ne gère pas d'export.
// L'ID de la liste des en-têtes des colonnes sinon.
- (UInt16)exportFormat:(Char*)ra_format
{
  return 0;
}


- (UInt16)exportInit
{
  return self->uh_num_items;
}


- (void)exportLine:(UInt16)uh_line with:(id)oExport
{
  [self subclassResponsibility];
}


- (void)exportEnd
{
  // Rien à faire ici...
}

@end
