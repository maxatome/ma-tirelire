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

// Il y a un pb au linkage avec TblGlueGetItemPtr, donc on gère ça nous même

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

  // Met à jour la hauteur de toutes les lignes (même celles qui ne
  // seront pas visibles tout de suite)
  for (uh_row = uh_max_rows; uh_row-- > 0; )
     TblSetRowHeight(self->pt_table, uh_row, uh_item_height);

  // On annule la sélection courante
  [self deselectLine];

  if (self->oForm->uh_form_drawn)
    TblEraseTable(self->pt_table);

  if (ps_bounds != &s_bounds)
    TblSetBounds(self->pt_table, ps_bounds);

  [self computeMaxRootItem];

  // On était en fond de liste, on y reste
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

  // On positionne le style de la 1ère colonne une fois pour toutes
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

  // Coordonnées de la table
  uh_table_id = FrmGetObjectIndex(pt_frm, self->uh_table);
  FrmGetObjectBounds(pt_frm, uh_table_id, &s_table);

  // Coordonnées de la barre de scroll
  uh_other_id = FrmGetObjectIndex(pt_frm, scrollbarId(self));
  FrmGetObjectBounds(pt_frm, uh_other_id, &s_other);

  // Tout est déjà positionné en mode gaucher et il faut passer en gaucher
  // OU BIEN tout est en droitier et il faut passer en droitier
  if (((s_table.topLeft.x > s_other.topLeft.x) ^ b_left_handed) == 0)
  {
    // XXX Faut-il cacher/faire apparaître les objets du bas si b_redraw ?
    goto done;
  }

  // Passage en mode gaucher : table à gauche
  if (b_left_handed)
  {
    uh_xother = s_table.topLeft.x;
    uh_xtable = s_other.topLeft.x + s_other.extent.x - s_table.extent.x;
  }
  // Passage en mode droitier : table à droite
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

  // On bouge les autres boutons (s'ils sont présents)
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

    // Les flèches TOP et BOTTOM
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
      // Si on est à gauche, alors juste pour ce bouton on se décale
      // d'un pixel en plus à gauche...
      *puh_cur++ = uh_xother - b_left_handed;
      uh_nb_objs++;
    }

    // Notre classe fille a peut-être des objets à décaler ?
    puh_base_inc = puh_cur;
    uh_nb_objs += [self _changeHandFillIncObjs:puh_cur withoutDontDraw:false];

    // On fait tout disparaitre et on déplace
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

    // On fait tout ré-apparaître
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

	// On est en mode full, on ne fait pas réapparaitre les boutons du bas
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
  // Si on est en normal, on va passer en full => les objets vont disparaître
  uh_show = self->uh_full;

  puh_cur = ruh_objs;
  while (uh_nb_objs-- > 0)
    *puh_cur++ = SET_SHOW(*puh_cur, uh_show);
  *puh_cur = 0;

  TblGetBounds(self->pt_table, &s_bounds);

  // Les boutons vont réapparaître
  if (uh_show)
  {
    s_bounds.extent.y -= uh_zsize;
    [self reinitItemHeight:self->uh_tbl_item_height bounds:&s_bounds];
  }

  [self->oForm showHideIds:ruh_objs];

  // Les boutons viennent de disparaître
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
// visible dans la table. Dépend de l'implémentation et n'est utile
// que si à un moment self->uh_current_item != SCROLLLIST_NO_CURRENT
- (UInt16)getLastVisibleItem
{
  UInt16 uh_last = self->uh_root_item + self->uh_tbl_num_lines - 1;

  if (uh_last >= self->uh_num_items)
    return self->uh_num_items - 1;

  return uh_last;
}


//
// Met à jour self->uh_max_root_item qui est la valeur max de
// uh_root_item de façon à ce que la table soit toujours remplie.
// Cette méthode est à appeler dès que le contenu de la liste change
// (ajout ou retrait d'élément, changement d'ordre) ou bien lorsque le
// nombre d'éléments de la table change
- (void)computeMaxRootItem
{
  if (self->uh_num_items > self->uh_tbl_num_lines)
    self->uh_max_root_item = self->uh_num_items - self->uh_tbl_num_lines;
  else
    self->uh_max_root_item = 0;
}


//
// Méthode à appeler lorsque le nombre d'entrées dans la liste a changé
- (void)initRecordsCount
{
  // Rien à faire ici
}


//
// Méthode à appeler lorsqu'on veut positionner l'élement qui sera
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

  // Item précédent
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
    // L'enregistrement courant est dans ou après la partie visible
    else
    {
      // L'enregistrement courant est après le dernier visible
      //    ----|============--------|--------------------
      //        ^-root               ^-current
      // => ----|============-----------------------------
      //        ^-current=root
      if (self->uh_current_item > [self getLastVisibleItem])
	self->uh_root_item = self->uh_current_item;
    }
  }

  // Moins d'éléments que de lignes dans la table
  if (self->uh_num_items <= self->uh_tbl_num_lines)
    self->uh_root_item = 0;
  // Plus d'éléments que ne permet d'en afficher la table, mais il
  // faut que l'écran soit plein, alors il faut peut-être reculer la
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

  // Pour aider, on se stocke nous même dans le Ptr du premier élément...
  TblSetItemPtr(self->pt_table, 0, 0, self);

  // Pour chaque ligne de la table
  for (uh_row = 0; uh_row < self->uh_tbl_num_lines; uh_row++)
  {
    // On a une ligne à afficher
    if ([self getDataForItem:&uh_item row:uh_row in:&ul_data])
    {
      TblSetRowID(self->pt_table, uh_row, uh_item);

      // Si le contenu de la ligne a changé
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

  // Met à jour la barre de scroll
  [self updateScrollers];
}


// Stocke *puh_item dans *pul_data par défaut.
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

  // Plus de lignes que d'entrées dans la table
  if (self->uh_num_items > self->uh_tbl_num_lines)
  {
    uh_pos = [self currentListPos];
    uh_max_value = self->uh_num_items - self->uh_tbl_num_lines;

    // On rend visible les flèches top et bottom et leur bouton respectif...
    [self->oForm showId:bmpScrollTop];
    [self->oForm showId:bmpScrollBottom];
    [self->oForm showId:topScrollId(self)];
    [self->oForm showId:bottomScrollId(self)];
  }
  // Moins de lignes que dans la table
  else
  {
    uh_pos = uh_max_value = 0;

    // On cache les flèches top et bottom et leur bouton respectif...
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
  // Réagence la barre de scroll et les boutons du bas...
  [self changeHand:b_left_handed redraw:true];

  // Recalcule le contenu de la table en fonction de la (possible)
  // nouvelle fonte
  [self reinitItemHeight:uh_item_height bounds:NULL];
}


//
// Position de la première ligne de la table par rapport à tous les
// éléments (self->uh_num_items). Par exemple dans le cas de la liste
// des enregistrements d'une catégorie, self->uh_root_idx représente
// l'index global de l'enregistrement toutes catégories confondues.
- (UInt16)currentListPos
{
  return self->uh_root_item;
}


- (void)goto:(UInt16)uh_new_root_item
{
  if (self->uh_root_item != uh_new_root_item)
  {
    // On annule la sélection courante
    [self deselectLine];

    self->uh_current_item = SCROLLLIST_NO_CURRENT;

    self->uh_root_item = uh_new_root_item;

    // À voir XXXX nécessaire pour TransListForm
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

    // On est allé trop loin
    if (uh_new_root_item > self->uh_max_root_item)
      uh_new_root_item = self->uh_max_root_item;
  }
  // Up
  else
  {
    // Trop près du début de la liste
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

  // On ne redessine que si ça change
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
  // Pas d'item => rien à sélectionner
  if (self->uh_num_items == 0)
    return;

  // Pas encore de ligne sélectionnée
  if (self->uh_selected_line == SCROLLLIST_NO_LINE)
    self->uh_selected_line = 0;
  // Une ligne est déjà sélectionnée
  else
  {
    // Ligne sélectionnée == dernière ligne de la liste
    // (cas où self->uh_num_items < self->uh_tbl_num_lines)
    if (self->uh_selected_line == self->uh_num_items - 1)
      return;

    // On est sur la dernière ligne de la table => il faut scroller
    if (self->uh_selected_line == self->uh_tbl_num_lines - 1)
    {
      UInt16 uh_max, uh_value, uh_dummy;

      SclGetScrollBar(self->pt_scrollbar,
		      &uh_value, &uh_dummy, &uh_max, &uh_dummy);

      // On est sur le dernier item de la liste (ou plus par sécurité)
      if (uh_value >= uh_max)
	return;

      // On peut scroller
      [self scroll:1];
      self->uh_selected_line--; // On vient de passer en avant dernière ligne
    }

    // On désélectionne l'ancienne ligne et on passe à la suivante
    [self unselectRow:self->uh_selected_line];

    self->uh_selected_line++;
  }

  // On sélectionne la ligne
  [self selectRow:self->uh_selected_line];
}


- (void)selectPrevLine
{
  // Pas d'item => rien à sélectionner
  if (self->uh_num_items == 0)
    return;

  // Pas encore de ligne sélectionnée
  if (self->uh_selected_line == SCROLLLIST_NO_LINE)
    self->uh_selected_line = ((self->uh_num_items < self->uh_tbl_num_lines
			      ? self->uh_num_items : self->uh_tbl_num_lines)
			      - 1);
  // Une ligne est déjà sélectionnée
  else
  {
    // Ligne sélectionnée == 1ère ligne de l'écran => il faut scroller
    if (self->uh_selected_line == 0)
    {
      UInt16 uh_min, uh_value, uh_dummy;

      // Moins d'enregistrements que de lignes dans la table
      if (self->uh_num_items <= self->uh_tbl_num_lines)
	return;

      SclGetScrollBar(self->pt_scrollbar,
		      &uh_value, &uh_min, &uh_dummy, &uh_dummy);

      // On est sur la 1er item de la liste (ou moins par sécurité)
      if (uh_value <= uh_min)
	return;

      // On peut scroller
      [self scroll:-1];
      self->uh_selected_line++; // On vient de passer en 2ème ligne
    }

    // On désélectionne l'ancienne ligne et on passe à la précédente
    [self unselectRow:self->uh_selected_line];

    self->uh_selected_line--;
  }

  // On sélectionne la ligne
  [self selectRow:self->uh_selected_line];
}


//
// Renvoie false si l'évènement n'a pas été traité.
// Renvoie true s'il l'a été. Si une ligne a été "cliquée" la méthode
// -clicOnRow: est appelée et true est renvoyé.
- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key
{
  switch (ps_key->chr)
  {
  case vchrNavChange:		// OK (only 5-way T|T)
    if (ps_key->modifiers & autoRepeatKeyMask)
      return false;

    // Pas de ligne sélectionnée
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
    // Une ligne est déjà sélectionnée
    else
    {
      switch (ps_key->keyCode & (navBitsAll | navChangeBitsAll))
      {
      case navBitLeft | navChangeLeft:	// Désélection de la ligne
	[self deselectLine];
	break;
      case navChangeSelect:	// Édition de la ligne
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
	// On n'a pas bougé : on est en fin de liste, on sélectionne
	// le dernier de la liste
	[self selectPrevLine];
	break;
      }

      // Sinon on continue, et on sélectionnera le premier de l'écran...
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
	// On n'a pas bougé : on est en début de liste, on sélectionne
	// le premier de la liste
	[self selectNextLine];
	break;
      }

      // Sinon on continue, et on sélectionnera le dernier de l'écran...
    }

    // CONTINUE

  case vchrJogUp:		/* Sony Jogdial */
  case vchrPrevField:
    [self selectPrevLine];
    break;

    // Escape : on désélectionne la ligne si elle l'est sinon rien...
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
    // Équivalant clic long
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
// Renvoie false si l'évènement n'a pas été traité.
// Renvoie true s'il l'a été. Dans ce cas *puh_item contient l'item
// sélectionné ou SCROLLLIST_NO_CURRENT s'il n'y a pas eu de
// sélection.
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

  // Ligne qui vient d'être pointée
  uh_row = e->data.tblSelect.row;

  // On désélectionne la ligne sélectionnée
  [self deselectLine];

  // Taille et sélection de la case
  [self selectRow:uh_row];
  [self getRow:uh_row bounds:&rec_cell];

  // Boucle tant que le stylet reste appuyé
  while (EvtGetPen(&x, &y, &b_pen_down), b_pen_down)
  {
    // Si les infos ne sont pas affichées
    if (win_handle == NULL)
    {
      // Si le stylet n'est pas dans la case
      if (RctPtInRectangle(x, y, &rec_cell) == false)
      {
	// La case est sélectionnée
	if (b_selected)
	{
	  // Désélection de la case
	  b_selected = false;
	  [self unselectRow:uh_row];
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
	  [self selectRow:uh_row];

	  // On vient de re-rentrer dans la case...
	  e->screenX = x;
	}
	// Case déjà sélectionnée, on regarde s'il faut afficher les infos
	// c'est à dire si 1/2 seconde s'est écoulée
	else if (TimGetTicks() - ui_last_tick >= (SysTicksPerSecond() >> 1))
	{
	  point_win.x = x;
	  point_win.y = y;
	  win_handle = [self longClicOnRow:uh_row topLeftIn:&point_win];
	}
      }
    } // Infos pas affichées
  } // while(EvtGetPen)

  // Il faut effacer les infos, si le fond d'écran a été sauvé...
  if (win_handle && win_handle != SCROLLLIST_FAKE_WINHANDLE)
    WinRestoreBits(win_handle, point_win.x, point_win.y);

  // Si la case n'est pas sélectionnée => c'est fini...
  if (b_selected == false)
    return true;

  // Désélection de la case
  [self unselectRow:uh_row];

  // Les infos ont été affichées => c'est fini
  if (win_handle != NULL)
    return true;

  return [self shortClicOnRow:uh_row from:e->screenX to:x];
}


//
// Un clic long vient d'être détecté sur la ligne uh_row
// Pas d'action par défaut => mais pas d'erreur...
// Renvoie le WinHandle correspondant à la zone à restaurer.
// - uh_row est la ligne de la table qui a subit le clic long ;
// - pp_top_left est l'adresse à laquelle le coin supérieur gauche de
//   la zone sauvée doit être stocké (le champ y est initialisé à
//   l'ordonnée du stylet pressé à l'appel) ;
- (WinHandle)longClicOnRow:(UInt16)uh_row topLeftIn:(PointType*)pp_win
{
  return NULL;
}


//
// Pour un affichage des infos d'un clic long, mais avec un clic
// court. Les infos disparaissent au bout de 2 secondes ou bien au
// premier événement
// uh_timeout == 0 => timeout par défaut
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
      uh_timeout = 2;		// secondes par défaut

    // Tant qu'il n'y a pas un évènement quelconque
    while (EvtSysEventAvail(true) == false
	   // ET pas 2 secondes de passées
	   && TimGetTicks() - ui_last_tick <= SysTicksPerSecond() * uh_timeout)
      // Pause de 1/20 de seconde (50 ms)
      SysTaskDelay(SysTicksPerSecond() / 20);

    // Au cas où une touche vient d'être appuyée, on supprime toutes
    // les touches de la queue pour éviter de déclencher un évènement
    // dans le formulaire
    if (EvtKeyQueueSize() > 0)
      EvtFlushKeyQueue();

    if (EvtPenQueueSize() > 0)
      EvtFlushPenQueue();

    WinRestoreBits(win_handle, s_bounds.topLeft.x, s_bounds.topLeft.y);
  }
}


//
// Un clic court vient d'être effectué sur la ligne uh_row
// Il a commencé à l'absisse uh_from_x pour se terminer à celle uh_to_x.
// Renvoie true si on a traité ce clic, false sinon...
- (Boolean)shortClicOnRow:(UInt16)uh_row
		     from:(UInt16)uh_from_x to:(UInt16)uh_to_x
{
  [self clicOnRow:uh_row];
  return true;
}


//
// Clic simple (ou sélection par le clavier) sur la ligne uh_row
- (void)clicOnRow:(UInt16)uh_row
{
  // Rien à faire dans cette classe...
}

@end
