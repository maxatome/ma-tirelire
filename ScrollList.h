/* -*- objc -*-
 * ScrollList.h -- 
 * 
 * Author          : Max Root
 * Created On      : Sun Nov 24 21:59:33 2002
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Jan 22 14:47:47 2008
 * Update Count    : 7
 * Status          : Unknown, Use with caution!
 */

#ifndef	__SCROLLLIST_H__
#define	__SCROLLLIST_H__

#include "BaseForm.h"

#ifndef EXTERN_SCROLLLIST
#define EXTERN_SCROLLLIST extern
#endif

#define scrollbarId(self)	(self->uh_table + 1)
#define topScrollId(self)	(self->uh_table + 2)
#define bottomScrollId(self)	(self->uh_table + 3)
#define fullId(self)		(self->uh_table + 4)
#define menuId(self)		(self->uh_table + 5)

//
// Si uh_buttons :
// - le bouton haut est toujours égal à uh_scrollbar + 1
// - le bouton bas est toujours égal à uh_scrollbar + 2
// - le bitmap du bouton haut à bmpScrollTop
// - le bitmap du bouton bas à bmpScrollBottom
@interface ScrollList : Object
{
  BaseForm *oForm;

  TablePtr pt_table;
  ScrollBarPtr pt_scrollbar;

  TableDrawItemFuncType *pf_line_draw;

  UInt16 uh_table;

  UInt16 uh_num_items;		// Nombre d'enregistrements au total
  UInt16 uh_root_item;		// Index du premier enregistrement de
				// la table. Cet index est juste un
				// repère de la classe, il n'a pas de
				// logique apparente sinon celle de la
				// classe qui l'implémente
  UInt16 uh_max_root_item;	// Valeur max de uh_root_item de façon
				// à ce que la table soit toujours
				// remplie (sauf si le nbre d'éléments
				// de la liste est < au nombre de
				// ligne de la table, dans ce cas
				// uh_max_root_item = 0)
#define SCROLLLIST_NO_CURRENT	0xffff
  UInt16 uh_current_item;	// Index de l'enregistrement devant
				// figurer absolument dans la liste
				// visible car, par exemple, il vient
				// d'être édité. Cet index suit la
				// même logique que celle de
				// ul_root_item

  UInt16 uh_tbl_num_lines;	// Nombre de lignes visibles dans la table
  UInt16 uh_tbl_item_height;	// Hauteur de chaque ligne

#define SCROLLLIST_NO_LINE	0xffff
  UInt16 uh_selected_line;	// Index de la ligne sélectionnée
				// (de 0 à uh_tbl_num_lines - 1)

  UInt16 uh_left_handed:1;	// Mode gaucher
  UInt16 uh_full:1;		// Fullscreen
  // Reste 14 bits...

  // Flags
#define SCROLLLIST_BOTTOP	0x0001 // Flèches TOP et BOTTOM présentes
#define SCROLLLIST_FULL		0x0002 // Bouton FULL présent
#define SCROLLLIST_MENU		0x0004 // Bouton MENU présent
#define SCROLLLIST_BUT_MASK \
			(SCROLLLIST_BOTTOP|SCROLLLIST_FULL|SCROLLLIST_MENU)
  UInt16 uh_flags;
}


+ (ScrollList*)newScrollList:(UInt16)uh_table inForm:(BaseForm*)oForm
		    numItems:(UInt16)uh_num_lines
		  itemHeight:(UInt16)uh_item_height;

- (ScrollList*)initScrollList:(UInt16)uh_table inForm:(BaseForm*)oForm
		     numItems:(UInt16)uh_num_lines
		   itemHeight:(UInt16)uh_item_height;

- (void)reinitItemHeight:(UInt16)uh_item_height bounds:(RectangleType*)ps;

- (void)initColumns;

- (UInt16)getLastVisibleItem;
- (void)computeMaxRootItem;

- (Boolean)getDataForItem:(UInt16*)puh_item row:(UInt16)uh_row
		       in:(UInt32*)pul_data;

- (void)initRecordsCount;
#define SCROLLLIST_CURRENT_DONT_RELOAD	0x8000
- (void)setCurrentItem:(UInt16)uh_new_cur;
- (Boolean)getItem:(UInt16*)puh_cur next:(Boolean)b_next;
- (void)loadRecords;
- (void)loadTable;
- (void)updateScrollers;
- (UInt16)currentListPos;

- (Boolean)getDataAtPos:(UInt16*)puh_line_num row:(UInt16)uh_row
		     in:(UInt32*)pul_data;

- (Boolean)changeHand:(Boolean)b_left_handed redraw:(Boolean)b_redraw;
#define SCROLLLIST_CH_DONT_DRAW	0x8000
- (UInt16)_changeHandFillIncObjs:(UInt16*)puh_objs
		 withoutDontDraw:(Boolean)b_without_dont_draw;

- (void)changeFullZoneInc:(UInt16)uh_zsize;

#define SCROLLLIST_GOTO_TOP	0
#define SCROLLLIST_GOTO_BOTTOM	0xffff
- (void)goto:(UInt16)uh_new_root_item;

- (void)scroll:(Int16)h_lines_to_scroll;
- (UInt16)scrollRootAdjusted:(Int16)h_lines_to_scroll;
- (Boolean)pageScrollDir:(WinDirectionType)direction;

- (void)redrawList;

- (void)update;
- (void)updateWithoutRedraw;
- (void)updateHand:(Boolean)b_left_handed height:(UInt16)uh_item_height;

- (void)getRow:(UInt16)uh_row bounds:(RectangleType*)ps_rect;
- (void)selectRow:(UInt16)uh_row;
- (void)unselectRow:(UInt16)uh_row;

- (void)selectLine:(UInt16)uh_line;
- (void)deselectLine;

- (void)selectNextLine;
- (void)selectPrevLine;

- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key;
- (Boolean)tblEnter:(EventType*)e;

#define SCROLLLIST_FAKE_WINHANDLE	((WinHandle)-1)
- (WinHandle)longClicOnRow:(UInt16)uh_row topLeftIn:(PointType*)pp_win;
- (Boolean)shortClicOnRow:(UInt16)uh_row
		     from:(UInt16)uh_from_x to:(UInt16)uh_to_x;
- (void)clicOnRow:(UInt16)uh_row;

- (void)displayLongClicInfoWithTimeoutForRow:(UInt16)uh_row
				     timeout:(UInt16)uh_timeout;

@end

EXTERN_SCROLLLIST void *(*ScrollListGetPtr)(TableType *pt_table);

#endif	/* __SCROLLLIST_H__ */
