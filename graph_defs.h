/* 
 * graph_defs.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sun Aug 24 11:16:51 2003
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__GRAPH_DEFS_H__
#define	__GRAPH_DEFS_H__

#define MINIMAL_SPACE	4

#define LIST_SCROLL_WIDTH		8

/* Marges supplémentaires à droite des listes pour accueillir '^' */
#define LIST_LEFT_MARGIN		2
#define LIST_RIGHT_MARGIN_NOSCROLL	1
#define LIST_RIGHT_MARGIN		(LIST_SCROLL_WIDTH \
					 + LIST_RIGHT_MARGIN_NOSCROLL)

#define LIST_MARGINS_WITH_SCROLL	(LIST_LEFT_MARGIN + LIST_RIGHT_MARGIN)
#define LIST_MARGINS_NO_SCROLL		(LIST_LEFT_MARGIN \
					 + LIST_RIGHT_MARGIN_NOSCROLL)

#define LIST_EXTERNAL_BORDERS		(1 /* left */ + 2 /* right */)

#define LIST_BORDERS_WITH_SCROLL	(1   /* left border  */ \
					 + LIST_MARGINS_WITH_SCROLL \
					 + 1) /* right border */

#define LIST_BORDERS_NO_SCROLL		(1   /* left border  */ \
					 + LIST_MARGINS_NO_SCROLL \
					 + 1) /* right border */

#endif	/* __GRAPH_DEFS_H__ */
