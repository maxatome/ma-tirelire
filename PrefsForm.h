/* -*- objc -*-
 * PrefsForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sam mar 27 15:17:35 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Nov 18 10:37:44 2005
 * Update Count    : 1
 * Status          : Unknown, Use with caution!
 */

#ifndef	__PREFSFORM_H__
#define	__PREFSFORM_H__

#include "MaTiForm.h"
#include "FontBucket.h"

#ifndef EXTERN_PREFSFORM
# define EXTERN_PREFSFORM extern
#endif

//			 Nom-		    Style-		Taille\0
#define FULL_FONT_NAME	(kMaxFontNameSize + kMaxFontStyleSize + 3 + 1)

@interface PrefsForm : MaTiForm
{
  UInt32 ul_current_code;

  FmFontID ui_tmp_font;
  Char ra_font_name[FULL_FONT_NAME];

  IndexedColorType ra_colors[8];
  UInt16 uh_list_flags;
}

- (void)extractAndSave;

- (void)_changeCode;

- (void)_displayFontName;

- (void)_colorRedraw:(UInt16)index;

@end

#endif	/* __PREFSFORM_H__ */
