/* -*- objc -*-
 * TransScrollList.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Dim mar 28 19:32:11 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Nov  2 15:57:04 2006
 * Update Count    : 7
 * Status          : Unknown, Use with caution!
 */

#ifndef	__TRANSSCROLLLIST_H__
#define	__TRANSSCROLLLIST_H__

#include "SumScrollList.h"

#include "Transaction.h"

#include "misc.h"


#ifndef EXTERN_TRANSSCROLLLIST
# define EXTERN_TRANSSCROLLLIST extern
#endif

@interface TransScrollList : SumScrollList
{
  Transaction *oTransactions;
}

// Pour la méthode -goto:, avec ces defines on peut faire :
// [XXX goto:SCROLLLIST_GOTO_FIRST_BASE + ps_prefs->ul_firstnext_action]
// [XXX goto:SCROLLLIST_GOTO_NEXT_BASE + ps_prefs->ul_firstnext_action]
#define SCROLLLIST_GOTO_FIRST_BASE	  SCROLLLIST_GOTO_FIRST_NOT_CHECKED
#define SCROLLLIST_GOTO_NEXT_BASE	  SCROLLLIST_GOTO_NEXT_NOT_CHECKED

// Pour la méthode -goto:
#define SCROLLLIST_GOTO_FIRST_NOT_CHECKED (SCROLLLIST_GOTO_BOTTOM - 9)
#define SCROLLLIST_GOTO_FIRST_NOT_FLAGGED (SCROLLLIST_GOTO_BOTTOM - 8)
#define SCROLLLIST_GOTO_FIRST_NOT_CHK_FLG (SCROLLLIST_GOTO_BOTTOM - 7)
#define SCROLLLIST_GOTO_FIRST_FLAGGED	  (SCROLLLIST_GOTO_BOTTOM - 6)

#define SCROLLLIST_GOTO_NEXT_NOT_CHECKED  (SCROLLLIST_GOTO_BOTTOM - 5)
#define SCROLLLIST_GOTO_NEXT_NOT_FLAGGED  (SCROLLLIST_GOTO_BOTTOM - 4)
#define SCROLLLIST_GOTO_NEXT_NOT_CHK_FLG  (SCROLLLIST_GOTO_BOTTOM - 3)
#define SCROLLLIST_GOTO_NEXT_FLAGGED	  (SCROLLLIST_GOTO_BOTTOM - 2)

#define SCROLLLIST_GOTO_DATE		  (SCROLLLIST_GOTO_BOTTOM - 1)


#define SCROLLLIST_FLAG_UNFLAG	0x0000
#define SCROLLLIST_FLAG_FLAG	0x0001
#define SCROLLLIST_FLAG_INVERT	0x0002
#define SCROLLLIST_FLAG_PAGE	0x0004
- (void)flagUnflag:(UInt16)uh_action;

@end

// Adresse de la structure à passer via pv_table lorsque cette
// fonction est appelée depuis la recherche globale
struct s_infos_from_find
{
  Transaction *oTransactions;
  struct s_transaction *ps_tr;
  struct s_misc_infos s_infos;	// Buffer pour trans_draw_record
  UInt16 uh_db_idx;
};

#define TRANS_DRAW_SPLIT_REMAIN	0x0100
EXTERN_TRANSSCROLLLIST void trans_draw_record(void *pv_table,
					      Int16 h_row, Int16 h_col,
					      RectangleType *prec_bounds);

#define TRANS_DRAW_LONGCLIC_STATS	0x0001
#define TRANS_DRAW_LONGCLIC_FUTURE	0x0002 // Un DateType suit
#define TRANS_DRAW_LONGCLIC_SPLIT	0x0004 // Un Int16 suit
EXTERN_TRANSSCROLLLIST WinHandle trans_draw_longclic_frame(Transaction *oTrans,
							   PointType *pp_win,
							   UInt16 uh_rec_index,
							   UInt16 uh_flags,
							   ...);

#endif	/* __TRANSSCROLLLIST_H__ */
