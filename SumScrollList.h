/* -*- objc -*-
 * SumScrollList.h -- 
 * 
 * Author          : Maxime Soulé
 * Created On      : Thu Nov 18 21:56:46 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Jan 22 12:02:20 2008
 * Update Count    : 9
 * Status          : Unknown, Use with caution!
 */

#ifndef	__SUMSCROLLLIST_H__
#define	__SUMSCROLLLIST_H__

#include "ScrollList.h"

#ifndef EXTERN_SUMSCROLLLIST
# define EXTERN_SUMSCROLLLIST extern
#endif

@interface SumScrollList : ScrollList
{
  // La somme à afficher en bas de la liste
  t_amount l_sum;

  // May be set by -computeEachEntryConvertSum
  Boolean b_deleted_items;
}

+ (SumScrollList*)newInForm:(BaseForm*)oForm;

- (void)computeEachEntrySum;
- (void)computeEachEntryConvertSum;
- (void)computeSum;

#define computeAgainEachEntryConvertSum	computeAgainWithConvert:true
#define computeAgainEachEntrySum	computeAgainWithConvert:false
- (void)computeAgainWithConvert:(Boolean)b_convert_sum;

- (UInt16)amountWidth;

- (Boolean)shortClicOnLabelOfRow:(UInt16)uh_row xPos:(UInt16)uh_x;
- (Int16)shortClicOnSumOfRow:(UInt16)uh_row xPos:(UInt16)uh_x
		      amount:(t_amount*)pl_amount;
- (Boolean)addAmount:(t_amount)l_amount selected:(Boolean)b_selected;

- (void)displaySum;

- (Int16)getTransaction:(UInt16)uh_index next:(Boolean)b_next
	     updateList:(Boolean)b_upddate_list;

- (UInt16)exportFormat:(Char*)ra_format;
- (UInt16)exportInit;
- (void)exportLine:(UInt16)uh_line with:(id)oExportForm;
- (void)exportEnd;

@end

#define DRAW_SUM_SELECTED	0x0001
#define DRAW_SUM_NO_AMOUNT	0x0002
#define DRAW_SUM_MIN_WIDTH	0x0004
EXTERN_SUMSCROLLLIST void draw_sum_line(Char *pa_label, t_amount l_sum,
					RectangleType *prec_bounds,
					UInt16 uh_flags);

#endif	/* __SUMSCROLLLIST_H__ */
