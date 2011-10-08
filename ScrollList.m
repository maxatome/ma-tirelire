/* 
 * ScrollList.m -- 
 * 
 * Author          : Max Root
 * Created On      : Sun Nov 24 21:59:30 2002
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Jan 22 16:13:59 2008
 * Update Count    : 89
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: ScrollList.m,v $
 * Revision 1.16  2008/02/01 17:19:06  max
 * Correct -computeMaxRootItem.
 * Now -pageScrollDir: returns a Boolean.
 * Handle option+UP/DOWN on selected lines.
 *
 * Revision 1.15  2008/01/14 16:29:56  max
 * Switch to new mcc.
 * Handle page up/down + option.
 * Space equals long clic.
 * Add timeout feature to long clic handling.
 *
 * Revision 1.14  2006/06/30 08:12:50  max
 * When switching from fullscreen with the list at bottom, the list stay
 * at bottom.
 *
 * Revision 1.13  2006/06/28 09:42:00  max
 * s/pt_frm/oForm/g attribute.
 * Add -updateWithoutRedraw method.
 *
 * Revision 1.12  2006/06/23 13:25:17  max
 * No more need of fiveway.h with PalmSDK installed.
 * Use oApplication instead of [Application appli].
 * Rework T|T 5-way handling.
 * Add new Palm 5-way handling.
 *
 * Revision 1.11  2006/04/25 08:47:07  max
 * Add comment.
 *
 * Revision 1.10  2005/10/16 21:44:06  max
 * Add -getItem:next: to handle moves in list from another form. Not yet enabled.
 * Delete -nextItem:
 *
 * Revision 1.9  2005/10/11 19:11:58  max
 * Populate generic -getLastVisibleItem.
 *
 * Revision 1.8  2005/08/28 10:02:32  max
 * Add -displayLongClicInfoWithTimeoutForRow: method.
 *
 * Revision 1.7  2005/08/20 13:07:00  max
 * -drawFrameAtPos:forLines:fontHeight:coord:color: changed into the
 * function DrawFrame() in misc.c
 * Now set the height of all rows, not only visible ones.
 * Now -longClicOnRow:topLeftIn: receive x pos in topLeftIn: argument.
 *
 * Revision 1.6  2005/03/27 15:38:25  max
 * Some problems accured in left handed mode. Corrected.
 *
 * Revision 1.5  2005/03/20 22:28:23  max
 * Correct -goto: method when called after an item edition
 * Left key of the 5-way navigator now expand to full screen
 *
 * Revision 1.4  2005/03/02 19:02:41  max
 * Change -initialize and -deinitialize methods to -initialize: and
 * -deinitialize: to know whether the globals are available or not.
 *
 * Revision 1.3  2005/02/21 20:44:22  max
 * Add color support for long clic frame drawing.
 *
 * Revision 1.2  2005/02/19 17:10:33  max
 * Long clic frame drawing method.
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

//
// Pour pt_table->items[0].ptr;
// Plus bas...
#define ALLOW_ACCESS_TO_INTERNALS_OF_TABLES
#define ALLOW_ACCESS_TO_INTERNALS_OF_FIELDS

#include <Common/System/palmOneNavigator.h>
#include <SonyChars.h>

#define EXTERN_SCROLLLIST
#include "ScrollList.h"

#include "Application.h"

#include "BaseForm.h"

#include "misc.h"		// XXX

// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#include "MaTirelireDefsAuto.h"	// Pour bmpScrollTop et bmpScrollBottom
// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


@implementation ScrollList

// Il y a un pb au linkage avec TblGlueGetItemPtr, donc on g�re �a nous m�me

static void *__ScrollListGetPtr35(TableType *pt_table)
{
  return pt_table->items[0].ptr;
}

static void *__ScrollListGetPtr(TableType *pt_table)
{
  return TblGetItemPtr(pt_table, 0, 0);
}

+ (void)initialize:(Boolean)b_globals
{
  if (b_globals)
  {
    UInt32 ul_rom_version;

    FtrGet(sysFtrCreator, sysFtrNumROMVersion, &ul_rom_version);

    // Sur les OS >= 3.5
    if (ul_rom_version >= 0x03500000)
      ScrollListGetPtr = __ScrollListGetPtr;
    else
      ScrollListGetPtr = __ScrollListGetPtr35;
  }
}


+ (ScrollList*)newScrollList:(UInt16)uh_table inForm:(BaseForm*)oForm
		    numItems:(UInt16)uh_num_items
		  itemHeight:(UInt16)uh_item_height
{
  return [[self alloc] initScrollList:uh_table inForm:oForm
		       numItems:uh_num_items
		       itemHeight:uh_item_height];
}


- (ScrollList*)initScrollList:(UInt16)uh_table inForm:(BaseForm*)oForm
		     numItems:(UInt16)uh_num_items
		   itemHeight:(UInt16)uh_item_height
{
  self->oForm = oForm;

  self->pt_table = [oForm objectPtrId:uh_table];
  self->uh_table = uh_table;

  self->pt_scrollbar = [oForm objectPtrId:scrollbarId(self)];

  self->uh_num_items = uh_num_items;

  self->uh_current_item = SCROLLLIST_NO_CURRENT;
  self->uh_selected_line = SCROLLLIST_NO_LINE;

  [self initRecordsCount];

  [self reinitItemHeight:uh_item_height bounds:NULL];

  [self initColumns];

  return self;
}


- (void)reinitItemHeight:(UInt16)uh_item_height
		  bounds:(RectangleType*)ps_bounds
{
  RectangleType s_bounds;
  UInt16 uh_max_rows, uh_row;
  Boolean b_is_at_end;

  // Calcul du nombre de lignes visibles dans la table
  uh_max_rows = TblGetNumberOfRows(self->pt_table);

  if (ps_bounds == NULL)
  {
    TblGetBounds(self->pt_table, &s_bounds);

    ps_bounds = &s_bounds;
  }

  b_is_at_end = (self->uh_root_item == self->uh_max_root_item);

  self->uh_tbl_num_lines = ps_bounds->extent.y / uh_item_height;
  if (self->uh_tbl_num_lines > uh_max_rows)
    self->uh_tbl_num_lines = uh_max_rows;

  self->uh_tbl_item_height = uh_item_height;

  // Met � jour la hauteur de toutes les lignes (m�me celles qui ne
  // seront pas visibles tout de suite)
  for (uh_row = uh_max_rows; uh_row-- > 0; )
     TblSetRowHeight(self->pt_table, uh_row, uh_item_height);

  // On annule la s�lection courante
  [self deselectLine];

  if (self->oForm->uh_form_drawn)
    TblEraseTable(self->pt_table);

  if (ps_bounds != &s_bounds)
    TblSetBounds(self->pt_table, ps_bounds);

  [self computeMaxRootItem];

  // On �tait en fond de liste, on y reste
  if (b_is_at_end)
    self->uh_root_item = self->uh_max_root_item;

  [self loadRecords];

  if (self->oForm->uh_form_drawn)
    TblDrawTable(self->pt_table);
}


- (void)initColumns
{
  UInt16 uh_row;

  TblSetCustomDrawProcedure(self->pt_table, 0, self->pf_line_draw);
  TblSetColumnUsable(self->pt_table, 0, true);

  // On positionne le style de la 1�re colonne une fois pour toutes
  for (uh_row = TblGetNumberOfRows(self->pt_table); uh_row-- > 0; )
    TblSetItemStyle(self->pt_table, uh_row, 0, customTableItem);
}


- (UInt16)_changeHandFillIncObjs:(UInt16*)puh_objs
		 withoutDontDraw:(Boolean)b_without_dont_draw
{
  return 0;
}


- (Boolean)changeHand:(Boolean)b_left_handed redraw:(Boolean)b_redraw
{
  FormPtr pt_frm = self->oForm->pt_frm;
  RectangleType s_table, s_other;
  UInt16 uh_table_id, uh_other_id;
  UInt16 uh_xtable, uh_xother;

  if (b_left_handed == self->uh_left_handed)
    return false;

  // Coordonn�es de la table
  uh_table_id = FrmGetObjectIndex(pt_frm, self->uh_table);
  FrmGetObjectBounds(pt_frm, uh_table_id, &s_table);

  // Coordonn�es de la barre de scroll
  uh_other_id = FrmGetObjectIndex(pt_frm, scrollbarId(self));
  FrmGetObjectBounds(pt_frm, uh_other_id, &s_other);

  // Tout est d�j� positionn� en mode gaucher et il faut passer en gaucher
  // OU BIEN tout est en droitier et il faut passer en droitier
  if (((s_table.topLeft.x > s_other.topLeft.x) ^ b_left_handed) == 0)
  {
    // XXX Faut-il cacher/faire appara�tre les objets du bas si b_redraw ?
    goto done;
  }

  // Passage en mode gaucher : table � gauche
  if (b_left_handed)
  {
    uh_xother = s_table.topLeft.x;
    uh_xtable = s_other.topLeft.x + s_other.extent.x - s_table.extent.x;
  }
  // Passage en mode droitier : table � droite
  else
  {
    uh_xtable = s_other.topLeft.x;
    uh_xother = s_table.topLeft.x + s_table.extent.x - s_other.extent.x;
  }

  // Effacement de la table et de la barre de scroll
  if (b_redraw)
    TblEraseTable(self->pt_table);

  // Nouvelle position de la table
  s_table.topLeft.x = uh_xtable;
  FrmSetObjectBounds(pt_frm, uh_table_id, &s_table);

  // On bouge les autres boutons (s'ils sont pr�sents)
  {
#define NB_INC_OBJS	12
    UInt16 ruh_objs[2 + 6 * 2 + NB_INC_OBJS], *puh_cur, *puh_base_inc;
    UInt16 index, uh_nb_objs, uh_dont_draw = 0;
    Int16 h_inc = 7;

    if (b_left_handed == 0)
      h_inc = -7;

    // Il ne faut pas redessiner les boutons de scroll si pas de barre
    // de scroll
    if (self->uh_num_items <= self->uh_tbl_num_lines)
      uh_dont_draw = SCROLLLIST_CH_DONT_DRAW;
    
    puh_cur = ruh_objs;

    // La barre de scroll
    *puh_cur++ = scrollbarId(self) | uh_dont_draw;
    *puh_cur++ = uh_xother;

    uh_nb_objs = 1;

    // Les fl�ches TOP et BOTTOM
    if (self->uh_flags & SCROLLLIST_BOTTOP)
    {
      *puh_cur++ = topScrollId(self) | uh_dont_draw;
      *puh_cur++ = uh_xother;

      *puh_cur++ = bmpScrollTop | uh_dont_draw;
      *puh_cur++ = uh_xother;

      *puh_cur++ = bottomScrollId(self) | uh_dont_draw;
      *puh_cur++ = uh_xother;

      *puh_cur++ = bmpScrollBottom | uh_dont_draw;
      *puh_cur++ = uh_xother;

      uh_nb_objs += 4;
    }

    // Bouton MENU
    if (self->uh_flags & SCROLLLIST_MENU)
    {
      *puh_cur++ = menuId(self);
      *puh_cur++ = uh_xother;
      uh_nb_objs++;
    }

    // Bouton FULL
    if (self->uh_flags & SCROLLLIST_FULL)
    {
      *puh_cur++ = fullId(self);
      // Si on est � gauche, alors juste pour ce bouton on se d�cale
      // d'un pixel en plus � gauche...
      *puh_cur++ = uh_xother - b_left_handed;
      uh_nb_objs++;
    }

    // Notre classe fille a peut-�tre des objets � d�caler ?
    puh_base_inc = puh_cur;
    uh_nb_objs += [self _changeHandFillIncObjs:puh_cur withoutDontDraw:false];

    // On fait tout disparaitre et on d�place
    puh_cur = ruh_objs;
    for (index = 0; index < uh_nb_objs; index++)
    {
      uh_dont_draw = (*puh_cur & SCROLLLIST_CH_DONT_DRAW);
      uh_other_id  = (*puh_cur & ~SCROLLLIST_CH_DONT_DRAW);

      uh_other_id = FrmGetObjectIndex(pt_frm, uh_other_id);

      // On conserve pour les disparitions plus bas
      *puh_cur++ = uh_other_id | uh_dont_draw;

      // On cache (seulement s'il le faut)
      if (b_redraw && uh_dont_draw == 0)
	[self->oForm hideIndex:uh_other_id];

      // On bouge
      FrmGetObjectBounds(pt_frm, uh_other_id, &s_other);
      if (puh_cur < puh_base_inc)
	s_other.topLeft.x = *puh_cur++;
      else
	s_other.topLeft.x += h_inc;
      FrmSetObjectBounds(pt_frm, uh_other_id, &s_other);
    }

    // Cas particulier => le bouton FULL change de contenu
    if (self->uh_flags & SCROLLLIST_FULL)
      [self->oForm fillLabel:fullId(self)
	   withSTR:((UInt16)b_left_handed ^ self->uh_full) ? "\002" : "\003"];

    // On fait tout r�-appara�tre
    if (b_redraw)
    {
      puh_cur = ruh_objs;
      while (uh_nb_objs-- > 0)
      {
	if ((*puh_cur & SCROLLLIST_CH_DONT_DRAW) == 0)
	  [self->oForm showIndex:*puh_cur];

	puh_cur++;
	if (puh_cur < puh_base_inc)
	  puh_cur++;

	// On est en mode full, on ne fait pas r�apparaitre les boutons du bas
	if (self->uh_full && puh_cur == puh_base_inc)
	  break;
      }
    }
  }

 done:
  self->uh_left_handed = b_left_handed;

  return true;
}


- (void)changeFullZoneInc:(UInt16)uh_zsize
{
  RectangleType s_bounds;
  UInt16 ruh_objs[NB_INC_OBJS + 1], *puh_cur, uh_nb_objs, uh_show;

  uh_nb_objs = [self _changeHandFillIncObjs:ruh_objs withoutDontDraw:true];

  // Si on est en full, on va passer en normal => on va voir les objets
  // Si on est en normal, on va passer en full => les objets vont dispara�tre
  uh_show = self->uh_full;

  puh_cur = ruh_objs;
  while (uh_nb_objs-- > 0)
    *puh_cur++ = SET_SHOW(*puh_cur, uh_show);
  *puh_cur = 0;

  TblGetBounds(self->pt_table, &s_bounds);

  // Les boutons vont r�appara�tre
  if (uh_show)
  {
    s_bounds.extent.y -= uh_zsize;
    [self reinitItemHeight:self->uh_tbl_item_height bounds:&s_bounds];
  }

  [self->oForm showHideIds:ruh_objs];

  // Les boutons viennent de dispara�tre
  if (uh_show == 0)
  {
    s_bounds.extent.y += uh_zsize;
    [self reinitItemHeight:self->uh_tbl_item_height bounds:&s_bounds];
  }

  self->uh_full ^= 1;

  // Cas particulier => le bouton FULL change de contenu
  if (self->uh_flags & SCROLLLIST_FULL)
    [self->oForm fillLabel:fullId(self)
	 withSTR:(self->uh_left_handed ^ self->uh_full) ? "\002" : "\003"];
}


//
// En fonction de self->uh_root_item doit renvoyer le dernier item
// visible dans la table. D�pend de l'impl�mentation et n'est utile
// que si � un moment self->uh_current_item != SCROLLLIST_NO_CURRENT
- (UInt16)getLastVisibleItem
{
  UInt16 uh_last = self->uh_root_item + self->uh_tbl_num_lines - 1;

  if (uh_last >= self->uh_num_items)
    return self->uh_num_items - 1;

  return uh_last;
}


//
// Met � jour self->uh_max_root_item qui est la valeur max de
// uh_root_item de fa�on � ce que la table soit toujours remplie.
// Cette m�thode est � appeler d�s que le contenu de la liste change
// (ajout ou retrait d'�l�ment, changement d'ordre) ou bien lorsque le
// nombre d'�l�ments de la table change
- (void)computeMaxRootItem
{
  if (self->uh_num_items > self->uh_tbl_num_lines)
    self->uh_max_root_item = self->uh_num_items - self->uh_tbl_num_lines;
  else
    self->uh_max_root_item = 0;
}


//
// M�thode � appeler lorsque le nombre d'entr�es dans la liste a chang�
- (void)initRecordsCount
{
  // Rien � faire ici
}


//
// M�thode � appeler lorsqu'on veut positionner l'�lement qui sera
// toujours visible dans la liste (self->uh_current_item)
- (void)setCurrentItem:(UInt16)uh_new_cur
{
  if (uh_new_cur == SCROLLLIST_NO_CURRENT)
    self->uh_current_item = SCROLLLIST_NO_CURRENT;
  else
  {
    if (uh_new_cur & SCROLLLIST_CURRENT_DONT_RELOAD)
      self->uh_current_item = uh_new_cur & ~SCROLLLIST_CURRENT_DONT_RELOAD;
    else if (uh_new_cur != self->uh_current_item)
    {
      self->uh_current_item = uh_new_cur;
      [self loadRecords];
    }
  }
}


- (Boolean)getItem:(UInt16*)puh_cur next:(Boolean)b_next
{
  if (self->uh_num_items == 0)
    return false;

  // Item suivant
  if (b_next)
  {
    if (*puh_cur >= self->uh_num_items - 1)
      return false;

    (*puh_cur)++;

    return true;
  }

  // Item pr�c�dent
  if (*puh_cur == 0)
    return false;

  (*puh_cur)--;

  return true;
}


//
// Rectifie self->uh_root_item s'il est trop grand
- (void)loadRecords
{
  if (self->uh_current_item != SCROLLLIST_NO_CURRENT)
  {
    // L'enregistrement courant est avant le 1er visible
    //    ----|--------------------|============--------
    //        ^-current            ^-root
    // => ----|============-----------------------------
    //        ^-current=root
    if (self->uh_root_item > self->uh_current_item)
      self->uh_root_item = self->uh_current_item;
    // L'enregistrement courant est dans ou apr�s la partie visible
    else
    {
      // L'enregistrement courant est apr�s le dernier visible
      //    ----|============--------|--------------------
      //        ^-root               ^-current
      // => ----|============-----------------------------
      //        ^-current=root
      if (self->uh_current_item > [self getLastVisibleItem])
	self->uh_root_item = self->uh_current_item;
    }
  }

  // Moins d'�l�ments que de lignes dans la table
  if (self->uh_num_items <= self->uh_tbl_num_lines)
    self->uh_root_item = 0;
  // Plus d'�l�ments que ne permet d'en afficher la table, mais il
  // faut que l'�cran soit plein, alors il faut peut-�tre reculer la
  // base...
  else if (self->uh_root_item > self->uh_max_root_item)
    self->uh_root_item = self->uh_max_root_item;

  [self loadTable];
}


- (void)loadTable
{
  UInt32 ul_data;
  UInt16 uh_item, uh_row;

  uh_item = self->uh_root_item;

  // Pour aider, on se stocke nous m�me dans le Ptr du premier �l�ment...
  TblSetItemPtr(self->pt_table, 0, 0, self);

  // Pour chaque ligne de la table
  for (uh_row = 0; uh_row < self->uh_tbl_num_lines; uh_row++)
  {
    // On a une ligne � afficher
    if ([self getDataForItem:&uh_item row:uh_row in:&ul_data])
    {
      TblSetRowID(self->pt_table, uh_row, uh_item);

      // Si le contenu de la ligne a chang�
      if (TblGetRowData(self->pt_table, uh_row) != ul_data
	  || TblRowUsable(self->pt_table, uh_row) == false)
      {
	TblSetRowUsable(self->pt_table, uh_row, true);
	TblSetRowData(self->pt_table, uh_row, ul_data);
	TblMarkRowInvalid(self->pt_table, uh_row);
      }

      // Item suivant
      uh_item++;
    }
    // sinon on marque la ligne unusable
    else
      TblSetRowUsable(self->pt_table, uh_row, false);
  }

  // Invalide les lignes qui ne sont pas visibles
  uh_item = TblGetNumberOfRows(self->pt_table);
  for (; uh_row < uh_item; uh_row++)
    TblSetRowUsable(self->pt_table, uh_row, false);

  // Met � jour la barre de scroll
  [self updateScrollers];
}


// Stocke *puh_item dans *pul_data par d�faut.
- (Boolean)getDataForItem:(UInt16*)puh_item row:(UInt16)uh_row
		       in:(UInt32*)pul_data
{
  if (*puh_item < self->uh_num_items)
  {
    *pul_data = *puh_item;
    return true;
  }

  return false;
}


- (void)updateScrollers
{
  UInt16 uh_pos, uh_max_value;

  // Plus de lignes que d'entr�es dans la table
  if (self->uh_num_items > self->uh_tbl_num_lines)
  {
    uh_pos = [self currentListPos];
    uh_max_value = self->uh_num_items - self->uh_tbl_num_lines;

    // On rend visible les fl�ches top et bottom et leur bouton respectif...
    [self->oForm showId:bmpScrollTop];
    [self->oForm showId:bmpScrollBottom];
    [self->oForm showId:topScrollId(self)];
    [self->oForm showId:bottomScrollId(self)];
  }
  // Moins de lignes que dans la table
  else
  {
    uh_pos = uh_max_value = 0;

    // On cache les fl�ches top et bottom et leur bouton respectif...
    [self->oForm hideId:bmpScrollTop];
    [self->oForm hideId:bmpScrollBottom];
    [self->oForm hideId:topScrollId(self)];
    [self->oForm hideId:bottomScrollId(self)];
  }

  SclSetScrollBar(self->pt_scrollbar,
		  uh_pos, 0, uh_max_value, self->uh_tbl_num_lines);
}


- (void)update
{
  [self initRecordsCount];

  [self computeMaxRootItem];

  [self loadRecords];

  [self redrawList];
}


- (void)updateWithoutRedraw
{
  [self initRecordsCount];

  [self computeMaxRootItem];

  [self loadRecords];
}


- (void)redrawList
{
  TblEraseTable(self->pt_table);
  TblDrawTable(self->pt_table);
}


- (void)updateHand:(Boolean)b_left_handed height:(UInt16)uh_item_height
{
  // R�agence la barre de scroll et les boutons du bas...
  [self changeHand:b_left_handed redraw:true];

  // Recalcule le contenu de la table en fonction de la (possible)
  // nouvelle fonte
  [self reinitItemHeight:uh_item_height bounds:NULL];
}


//
// Position de la premi�re ligne de la table par rapport � tous les
// �l�ments (self->uh_num_items). Par exemple dans le cas de la liste
// des enregistrements d'une cat�gorie, self->uh_root_idx repr�sente
// l'index global de l'enregistrement toutes cat�gories confondues.
- (UInt16)currentListPos
{
  return self->uh_root_item;
}


- (void)goto:(UInt16)uh_new_root_item
{
  if (self->uh_root_item != uh_new_root_item)
  {
    // On annule la s�lection courante
    [self deselectLine];

    self->uh_current_item = SCROLLLIST_NO_CURRENT;

    self->uh_root_item = uh_new_root_item;

    // � voir XXXX n�cessaire pour TransListForm
    if (uh_new_root_item == 0)
      self->uh_root_item = [self scrollRootAdjusted:0];

    [self loadRecords];

    TblRedrawTable(self->pt_table);
  }
}

- (UInt16)scrollRootAdjusted:(Int16)h_lines_to_scroll
{
  UInt16 uh_new_root_item = self->uh_root_item;

  // Down
  if (h_lines_to_scroll > 0)
  {
    uh_new_root_item += h_lines_to_scroll;

    // On est all� trop loin
    if (uh_new_root_item > self->uh_max_root_item)
      uh_new_root_item = self->uh_max_root_item;
  }
  // Up
  else
  {
    // Trop pr�s du d�but de la liste
    if (uh_new_root_item <= - h_lines_to_scroll)
      uh_new_root_item = 0;
    else
      uh_new_root_item += h_lines_to_scroll; // car h_lines_to_scroll est < 0
  }

  return uh_new_root_item;
}


- (void)scroll:(Int16)h_lines_to_scroll
{
  WinDirectionType direction;

  if (h_lines_to_scroll == 0)
    return;

  self->uh_root_item = [self scrollRootAdjusted:h_lines_to_scroll];
  self->uh_current_item = SCROLLLIST_NO_CURRENT;

  if (h_lines_to_scroll > 0)
    direction = winUp;
  else
  {
    direction = winDown;
    h_lines_to_scroll = - h_lines_to_scroll;
  }

  // On scrolle les lignes qui restent visibles
  if (h_lines_to_scroll < self->uh_tbl_num_lines)
  {
    UInt16 uh_index;
    RectangleType s_bounds, s_vacated;

    // Vers le haut
    if (direction == winUp)
    {
      for (uh_index = 0; uh_index < h_lines_to_scroll; uh_index++)
	TblRemoveRow(self->pt_table, 0);
    }
    // Vers le bas
    else
    {
      for (uh_index = 0; uh_index < h_lines_to_scroll; uh_index++)
	TblInsertRow(self->pt_table, 0);
    }

    TblGetBounds(self->pt_table, &s_bounds);
    // On corrige la hauteur pour ne garder que la hauteur visible...
    s_bounds.extent.y = self->uh_tbl_num_lines * self->uh_tbl_item_height;

    WinScrollRectangle(&s_bounds, direction,
		       h_lines_to_scroll * self->uh_tbl_item_height,
		       &s_vacated);
    WinEraseRectangle(&s_vacated, 0);
  }

  [self loadTable];

  TblRedrawTable(self->pt_table);
}


- (Boolean)pageScrollDir:(WinDirectionType)direction
{
  Int16 h_lines_to_scroll = self->uh_tbl_num_lines - 1 ? : 1;
  UInt16 uh_new_root_item;

  self->uh_current_item = SCROLLLIST_NO_CURRENT;

  // Vers le haut d'une page - 1 ligne
  if (direction != winDown)
    h_lines_to_scroll = - h_lines_to_scroll;

  uh_new_root_item = [self scrollRootAdjusted:h_lines_to_scroll];

  // On ne redessine que si �a change
  if (uh_new_root_item != self->uh_root_item)
  {
    self->uh_root_item = uh_new_root_item;

    [self loadRecords];

    TblRedrawTable(self->pt_table);

    return true;
  }

  return false;
}


- (void)getRow:(UInt16)uh_row bounds:(RectangleType*)ps_rect
{
  TblGetItemBounds(self->pt_table, uh_row, 0, ps_rect);

  // TblGetItemBounds renvoie 11 dans rec_cell.extent.y !!!
  ps_rect->extent.y = self->uh_tbl_item_height;
}


- (void)selectRow:(UInt16)uh_row
{
  RectangleType rec_cell;

  [self getRow:uh_row bounds:&rec_cell];

  if (oApplication->uh_color_enabled)
    WinInvertRectangleColor(&rec_cell);
  else
    WinInvertRectangle(&rec_cell, 0);
  
}


- (void)unselectRow:(UInt16)uh_row
{
  RectangleType rec_cell;

  [self getRow:uh_row bounds:&rec_cell];

  if (oApplication->uh_color_enabled)
  {
    WinPushDrawState();

    WinSetBackColor(UIColorGetTableEntryIndex(UIFieldBackground));
    WinSetForeColor(UIColorGetTableEntryIndex(UIObjectForeground));

    WinEraseRectangle(&rec_cell, 0);

    // On redessine la ligne
    self->pf_line_draw(self->pt_table, uh_row, 0, &rec_cell);

    WinPopDrawState();
  }
  else
    WinInvertRectangle(&rec_cell, 0);
}


- (void)selectLine:(UInt16)uh_line
{
  self->uh_selected_line = uh_line;
  [self selectRow:uh_line];
}


- (void)deselectLine
{
  if (self->uh_selected_line == SCROLLLIST_NO_LINE)
    return;

  [self unselectRow:self->uh_selected_line];
  self->uh_selected_line = SCROLLLIST_NO_LINE;
}


- (void)selectNextLine
{
  // Pas d'item => rien � s�lectionner
  if (self->uh_num_items == 0)
    return;

  // Pas encore de ligne s�lectionn�e
  if (self->uh_selected_line == SCROLLLIST_NO_LINE)
    self->uh_selected_line = 0;
  // Une ligne est d�j� s�lectionn�e
  else
  {
    // Ligne s�lectionn�e == derni�re ligne de la liste
    // (cas o� self->uh_num_items < self->uh_tbl_num_lines)
    if (self->uh_selected_line == self->uh_num_items - 1)
      return;

    // On est sur la derni�re ligne de la table => il faut scroller
    if (self->uh_selected_line == self->uh_tbl_num_lines - 1)
    {
      UInt16 uh_max, uh_value, uh_dummy;

      SclGetScrollBar(self->pt_scrollbar,
		      &uh_value, &uh_dummy, &uh_max, &uh_dummy);

      // On est sur le dernier item de la liste (ou plus par s�curit�)
      if (uh_value >= uh_max)
	return;

      // On peut scroller
      [self scroll:1];
      self->uh_selected_line--; // On vient de passer en avant derni�re ligne
    }

    // On d�s�lectionne l'ancienne ligne et on passe � la suivante
    [self unselectRow:self->uh_selected_line];

    self->uh_selected_line++;
  }

  // On s�lectionne la ligne
  [self selectRow:self->uh_selected_line];
}


- (void)selectPrevLine
{
  // Pas d'item => rien � s�lectionner
  if (self->uh_num_items == 0)
    return;

  // Pas encore de ligne s�lectionn�e
  if (self->uh_selected_line == SCROLLLIST_NO_LINE)
    self->uh_selected_line = ((self->uh_num_items < self->uh_tbl_num_lines
			      ? self->uh_num_items : self->uh_tbl_num_lines)
			      - 1);
  // Une ligne est d�j� s�lectionn�e
  else
  {
    // Ligne s�lectionn�e == 1�re ligne de l'�cran => il faut scroller
    if (self->uh_selected_line == 0)
    {
      UInt16 uh_min, uh_value, uh_dummy;

      // Moins d'enregistrements que de lignes dans la table
      if (self->uh_num_items <= self->uh_tbl_num_lines)
	return;

      SclGetScrollBar(self->pt_scrollbar,
		      &uh_value, &uh_min, &uh_dummy, &uh_dummy);

      // On est sur la 1er item de la liste (ou moins par s�curit�)
      if (uh_value <= uh_min)
	return;

      // On peut scroller
      [self scroll:-1];
      self->uh_selected_line++; // On vient de passer en 2�me ligne
    }

    // On d�s�lectionne l'ancienne ligne et on passe � la pr�c�dente
    [self unselectRow:self->uh_selected_line];

    self->uh_selected_line--;
  }

  // On s�lectionne la ligne
  [self selectRow:self->uh_selected_line];
}


//
// Renvoie false si l'�v�nement n'a pas �t� trait�.
// Renvoie true s'il l'a �t�. Si une ligne a �t� "cliqu�e" la m�thode
// -clicOnRow: est appel�e et true est renvoy�.
- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key
{
  switch (ps_key->chr)
  {
  case vchrNavChange:		// OK (only 5-way T|T)
    if (ps_key->modifiers & autoRepeatKeyMask)
      return false;

    // Pas de ligne s�lectionn�e
    if (self->uh_selected_line == SCROLLLIST_NO_LINE)
    {
      switch (ps_key->keyCode & (navBitsAll | navChangeBitsAll))
      {
      case navChangeSelect:
	[self selectNextLine];
	break;
      case navBitLeft | navChangeLeft: // Passage en full screen ou inverse
	[self changeFullZoneInc:12];
	break;
      default:
	return false;
      }
    }
    // Une ligne est d�j� s�lectionn�e
    else
    {
      switch (ps_key->keyCode & (navBitsAll | navChangeBitsAll))
      {
      case navBitLeft | navChangeLeft:	// D�s�lection de la ligne
	[self deselectLine];
	break;
      case navChangeSelect:	// �dition de la ligne
	goto clic_on_selected_row;
      default:
	return false;
      }
    }
    break;

    // De NavSelectHSPressed()
  case vchrRockerCenter:
    if ((ps_key->modifiers & commandKeyMask) == 0)
      return false;

    if (self->uh_selected_line != SCROLLLIST_NO_LINE)
      goto clic_on_selected_row;

    [self selectNextLine];
    break;

    // De NavDirectionHSPressed()
  case vchrRockerLeft:
    if ((ps_key->modifiers & commandKeyMask) == 0)
      return false;

    if (self->uh_selected_line == SCROLLLIST_NO_LINE)
      [self changeFullZoneInc:12]; // Passage en full screen ou inverse
    else
      [self deselectLine];
    break;

  case vchrJogPushedDown:	/* Sony Jogdial */
    [self deselectLine];
    [self pageScrollDir:winDown];
    break;

  case vchrJogPushedUp:		/* Sony Jogdial */
    [self deselectLine];
    [self pageScrollDir:winUp];
    break;

  case pageDownChr:
    if (self->uh_selected_line == SCROLLLIST_NO_LINE)
    {
      if (ps_key->modifiers & optionKeyMask) // Sur Treo : bouton option
	[self goto:SCROLLLIST_GOTO_BOTTOM];
      else
	[self pageScrollDir:winDown];
      break;
    }
    // Selected line
    else if (ps_key->modifiers & optionKeyMask) // Sur Treo : bouton option
    {
      [self deselectLine];
      if ([self pageScrollDir:winDown] == false)
      {
	// On n'a pas boug� : on est en fin de liste, on s�lectionne
	// le dernier de la liste
	[self selectPrevLine];
	break;
      }

      // Sinon on continue, et on s�lectionnera le premier de l'�cran...
    }

    // CONTINUE

  case vchrJogDown:		/* Sony Jogdial */
  case vchrNextField:
  case '\t':			// XXX
    [self selectNextLine];
    break;

  case pageUpChr:
    if (self->uh_selected_line == SCROLLLIST_NO_LINE)
    {
      if (ps_key->modifiers & optionKeyMask) // Sur Treo : bouton option
	[self goto:SCROLLLIST_GOTO_TOP];
      else
	[self pageScrollDir:winUp];
      break;
    }
    // Selected line
    else if (ps_key->modifiers & optionKeyMask) // Sur Treo : bouton option
    {
      [self deselectLine];
      if ([self pageScrollDir:winUp] == false)
      {
	// On n'a pas boug� : on est en d�but de liste, on s�lectionne
	// le premier de la liste
	[self selectNextLine];
	break;
      }

      // Sinon on continue, et on s�lectionnera le dernier de l'�cran...
    }

    // CONTINUE

  case vchrJogUp:		/* Sony Jogdial */
  case vchrPrevField:
    [self selectPrevLine];
    break;

    // Escape : on d�s�lectionne la ligne si elle l'est sinon rien...
  case vchrJogBack:		/* Sony Jogdial */
    if (self->uh_selected_line == SCROLLLIST_NO_LINE)
      return false;

    // CONTINUE

  case chrEscape:
    [self deselectLine];
    break;

    // Enter...
  case vchrJogRelease:	/* Sony Jogdial */
  case chrCarriageReturn:
  case chrLineFeed:
    if (self->uh_selected_line == SCROLLLIST_NO_LINE)
      return false;
    else
    {
      UInt16 uh_row;

  clic_on_selected_row:
      uh_row = self->uh_selected_line;
      [self deselectLine];
      [self clicOnRow:uh_row];
    }
    break;

  case ' ':
    // �quivalant clic long
    if (self->uh_selected_line == SCROLLLIST_NO_LINE)
      return false;

    [self displayLongClicInfoWithTimeoutForRow:self->uh_selected_line
	  timeout:60];	// secondes
    break;

  default:
    return false;
  }

  return true;
}


//
// Renvoie false si l'�v�nement n'a pas �t� trait�.
// Renvoie true s'il l'a �t�. Dans ce cas *puh_item contient l'item
// s�lectionn� ou SCROLLLIST_NO_CURRENT s'il n'y a pas eu de
// s�lection.
- (Boolean)tblEnter:(EventType*)e
{
  UInt32 ui_last_tick;
  RectangleType rec_cell;
  UInt16 uh_row, x, y;

  WinHandle win_handle = NULL;
  PointType point_win;

  Boolean b_selected = true, b_pen_down = true;

  if (e->data.tblSelect.pTable != self->pt_table)
    return false;

  ui_last_tick = TimGetTicks();

  // Ligne qui vient d'�tre point�e
  uh_row = e->data.tblSelect.row;

  // On d�s�lectionne la ligne s�lectionn�e
  [self deselectLine];

  // Taille et s�lection de la case
  [self selectRow:uh_row];
  [self getRow:uh_row bounds:&rec_cell];

  // Boucle tant que le stylet reste appuy�
  while (EvtGetPen(&x, &y, &b_pen_down), b_pen_down)
  {
    // Si les infos ne sont pas affich�es
    if (win_handle == NULL)
    {
      // Si le stylet n'est pas dans la case
      if (RctPtInRectangle(x, y, &rec_cell) == false)
      {
	// La case est s�lectionn�e
	if (b_selected)
	{
	  // D�s�lection de la case
	  b_selected = false;
	  [self unselectRow:uh_row];
	}
      }
      // Stylet dans la case
      else
      {
	// La case n'est pas s�lectionn�e
	if (b_selected == false)
	{
	  ui_last_tick = TimGetTicks();

	  /* S�lection de la case */
	  b_selected = true;
	  [self selectRow:uh_row];

	  // On vient de re-rentrer dans la case...
	  e->screenX = x;
	}
	// Case d�j� s�lectionn�e, on regarde s'il faut afficher les infos
	// c'est � dire si 1/2 seconde s'est �coul�e
	else if (TimGetTicks() - ui_last_tick >= (SysTicksPerSecond() >> 1))
	{
	  point_win.x = x;
	  point_win.y = y;
	  win_handle = [self longClicOnRow:uh_row topLeftIn:&point_win];
	}
      }
    } // Infos pas affich�es
  } // while(EvtGetPen)

  // Il faut effacer les infos, si le fond d'�cran a �t� sauv�...
  if (win_handle && win_handle != SCROLLLIST_FAKE_WINHANDLE)
    WinRestoreBits(win_handle, point_win.x, point_win.y);

  // Si la case n'est pas s�lectionn�e => c'est fini...
  if (b_selected == false)
    return true;

  // D�s�lection de la case
  [self unselectRow:uh_row];

  // Les infos ont �t� affich�es => c'est fini
  if (win_handle != NULL)
    return true;

  return [self shortClicOnRow:uh_row from:e->screenX to:x];
}


//
// Un clic long vient d'�tre d�tect� sur la ligne uh_row
// Pas d'action par d�faut => mais pas d'erreur...
// Renvoie le WinHandle correspondant � la zone � restaurer.
// - uh_row est la ligne de la table qui a subit le clic long ;
// - pp_top_left est l'adresse � laquelle le coin sup�rieur gauche de
//   la zone sauv�e doit �tre stock� (le champ y est initialis� �
//   l'ordonn�e du stylet press� � l'appel) ;
- (WinHandle)longClicOnRow:(UInt16)uh_row topLeftIn:(PointType*)pp_win
{
  return NULL;
}


//
// Pour un affichage des infos d'un clic long, mais avec un clic
// court. Les infos disparaissent au bout de 2 secondes ou bien au
// premier �v�nement
// uh_timeout == 0 => timeout par d�faut
- (void)displayLongClicInfoWithTimeoutForRow:(UInt16)uh_row
				     timeout:(UInt16)uh_timeout
{
  WinHandle win_handle;
  RectangleType s_bounds;

  [self getRow:uh_row bounds:&s_bounds];

  s_bounds.topLeft.y += self->uh_tbl_item_height / 2;

  win_handle = [self longClicOnRow:uh_row topLeftIn:&s_bounds.topLeft];
  if (win_handle != NULL && win_handle != SCROLLLIST_FAKE_WINHANDLE)
  {
    UInt32 ui_last_tick = TimGetTicks();

    if (uh_timeout == 0)
      uh_timeout = 2;		// secondes par d�faut

    // Tant qu'il n'y a pas un �v�nement quelconque
    while (EvtSysEventAvail(true) == false
	   // ET pas 2 secondes de pass�es
	   && TimGetTicks() - ui_last_tick <= SysTicksPerSecond() * uh_timeout)
      // Pause de 1/20 de seconde (50 ms)
      SysTaskDelay(SysTicksPerSecond() / 20);

    // Au cas o� une touche vient d'�tre appuy�e, on supprime toutes
    // les touches de la queue pour �viter de d�clencher un �v�nement
    // dans le formulaire
    if (EvtKeyQueueSize() > 0)
      EvtFlushKeyQueue();

    if (EvtPenQueueSize() > 0)
      EvtFlushPenQueue();

    WinRestoreBits(win_handle, s_bounds.topLeft.x, s_bounds.topLeft.y);
  }
}


//
// Un clic court vient d'�tre effectu� sur la ligne uh_row
// Il a commenc� � l'absisse uh_from_x pour se terminer � celle uh_to_x.
// Renvoie true si on a trait� ce clic, false sinon...
- (Boolean)shortClicOnRow:(UInt16)uh_row
		     from:(UInt16)uh_from_x to:(UInt16)uh_to_x
{
  [self clicOnRow:uh_row];
  return true;
}


//
// Clic simple (ou s�lection par le clavier) sur la ligne uh_row
- (void)clicOnRow:(UInt16)uh_row
{
  // Rien � faire dans cette classe...
}

@end
