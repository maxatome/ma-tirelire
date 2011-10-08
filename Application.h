/* -*- objc -*-
 * Application.h -- 
 * 
 * Author          : Max Root
 * Created On      : Sun Jan  5 17:30:12 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Jul 16 14:17:16 2007
 * Update Count    : 12
 * Status          : Unknown, Use with caution!
 */

#ifndef	__APPLICATION_H__
#define	__APPLICATION_H__

#include "Object.h"

#ifndef EXTERN_APPLICATION
# define EXTERN_APPLICATION extern
#endif

// Un ID de formulaire ne peut pas être sur plus de 7 bits (127 formulaires)
#define APP_FORM_ID_MASK	0x007f
#define APP_FORM_ID_FLAGS_MASK	(~APP_FORM_ID_MASK)
#define APP_FORM_ID_FLAGS_SHIFT	7

@interface Application : Object
{
  UInt32 ul_rom_version;

  // Paramètre à passer à EvtGetEvent
  UInt32 ul_wait_for;

  // Les formulaires
  VoidHand vh_form_classes;
  UInt16 uh_form_num:APP_FORM_ID_FLAGS_SHIFT; // Nombre de formulaires

  UInt16 uh_color_enabled:1;	// On est en couleur
#define PALM_NAV_NONE	0
#define PALM_NAV_FRM	1	// T5/Treo650 navigator API
#define PALM_NAV_HS	2	// Treo600 navigator API
  UInt16 uh_palmnav_available:2;// Le FrmNav(1) ou HsNav(2) de Palm est dispo
  UInt16 uh_high_density:1;	// Feature haute densité
}
: // Variables de classe...
{
  Application *oAppli;
  Boolean b_globals;
}

+ (Application*)new:(Boolean)b_globals;
+ (Application*)appli;

- (Application*)init;

- (UInt16)start;
- (void)stop;

- (void)gotoFirstForm;

- (void)eventLoop;
- (Int16)eventEach:(EventType*)ps_event;

- (void)loadPrefs;
- (void)savePrefs;

- (void)find:(FindParamsPtr)ps_find_params;
- (void)gotoItem:(GoToParamsPtr)ps_goto_params justLaunched:(Boolean)b_lched;

@end

EXTERN_APPLICATION Application *oApplication;

#endif	/* __APPLICATION_H__ */
