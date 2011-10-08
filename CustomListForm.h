/* -*- objc -*-
 * CustomListForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sam mai 21 14:48:06 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Jul  6 10:25:22 2006
 * Update Count    : 4
 * Status          : Unknown, Use with caution!
 */

#ifndef	__CUSTOMLISTFORM_H__
#define	__CUSTOMLISTFORM_H__

#include "SumListForm.h"
#include "CustomScrollList.h"

#ifndef EXTERN_CUSTOMLISTFORM
# define EXTERN_CUSTOMLISTFORM extern
#endif

@interface CustomListForm : SumListForm
{
}

- (CustomScrollList_c*)initTitleAndLabel;

- (Boolean)initStatsSearch:(struct s_clist_stats_search*)ps_search;

#define CLIST_SUBFORM_TYPE		(0 << APP_FORM_ID_FLAGS_SHIFT)
#define CLIST_SUBFORM_MODE		(1 << APP_FORM_ID_FLAGS_SHIFT)
#define CLIST_SUBFORM_PERIOD		(2 << APP_FORM_ID_FLAGS_SHIFT)
#define CLIST_SUBFORM_TRANS_STATS	(3 << APP_FORM_ID_FLAGS_SHIFT)
//#define CLIST_SUBFORM_MINAVGMAX		(4 << APP_FORM_ID_FLAGS_SHIFT)
#define CLIST_SUBFORM_LAST_STAT		CLIST_SUBFORM_TRANS_STATS

#define CLIST_SUBFORM_TRANS_FLAGGED	(10 << APP_FORM_ID_FLAGS_SHIFT)

@end

#endif	/* __CUSTOMLISTFORM_H__ */
