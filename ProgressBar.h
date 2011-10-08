/* -*- objc -*-
 * ProgressBar.h -- 
 * 
 * Author          : Maxime Soulé
 * Created On      : Fri Oct 15 20:41:29 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jul  6 14:58:34 2007
 * Update Count    : 6
 * Status          : Unknown, Use with caution!
 */

#ifndef	__PROGRESSBAR_H__
#define	__PROGRESSBAR_H__

#include <Unix/unix_stdarg.h>

#include "Object.h"

#ifndef EXTERN_PROGRESSBAR
# define EXTERN_PROGRESSBAR extern
#endif

@interface ProgressBar : Object
{
  WinHandle win_handle;

  UInt32 ui_max_value;		// Valeur maximale possible

  Char ra_label[64];		// Label

  UInt32 ui_init_ticks;		// Nombre de ticks au démarrage
  UInt16 uh_ticks_per_sec;	// Nombre de ticks par seconde

  Int16 h_last_percent;		// Valeur courante par rapport à la barre

  PointType point_win;
  FontID uh_save_font;		// Only for OSes < 3.5
}

+ (ProgressBar*)newNumValues:(UInt32)ui_num label:(UInt16)uh_str_id, ...;

- (ProgressBar*)initNumValues:(UInt32)ui_num label:(UInt16)uh_str_id
			   va:(va_list)ap;

- (void)updateValue:(Int32)i_value;

- (void)label:(UInt16)uh_str_id, ...;
- (void)label:(UInt16)uh_str_id va:(va_list)ap;
- (void)labelRedraw:(Boolean)b_first;

- (void)restart;
- (void)suspend;

@end

//
// Macros utiles
#define PROGRESSBAR_DECL	 \
  ProgressBar *__oProgressBar;	 \
  Int32 __i_last_value = 0

#define PROGRESSBAR_BEGIN(ui_num, uh_str_id, args...)			\
  __oProgressBar = [ProgressBar newNumValues:ui_num label:uh_str_id, ## args]

#define PROGRESSBAR_INLOOP(ui_value, ui_inc_update)			\
  ({									\
    UInt32 __ui_val = (ui_value);					\
    if (__ui_val - __i_last_value >= ui_inc_update)			\
      [__oProgressBar updateValue:__i_last_value = __ui_val];		\
  })

#define PROGRESSBAR_DECMAX	    \
  __oProgressBar->ui_max_value--;   \
  __i_last_value--;

#define PROGRESSBAR_DECMAX_VAL(dec)		\
  __oProgressBar->ui_max_value -= dec;		\
  __i_last_value -= dec;

#define PROGRESSBAR_LABEL(uh_str_id, args...)	\
  [__oProgressBar label:uh_str_id, ## args];

#define PROGRESSBAR_END		[__oProgressBar free]

#endif	/* __PROGRESSBAR_H__ */
