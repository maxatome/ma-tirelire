/* 
 * Application.m -- 
 * 
 * Author          : Max Root
 * Created On      : Sun Jan  5 17:30:08 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jul  6 14:40:35 2007
 * Update Count    : 36
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: Application.m,v $
 * Revision 1.7  2008/01/14 17:09:32  max
 * Switch to new mcc.
 *
 * Revision 1.6  2006/11/04 23:47:54  max
 * Handle high density screens.
 *
 * Revision 1.5  2006/06/30 08:12:36  max
 * Handle correctly Treo600 navigator API.
 *
 * Revision 1.4  2006/06/23 13:24:56  max
 * Now have oApplication global variable.
 * Add attribute to now whether the Palm Nav feature is available or not.
 *
 * Revision 1.3  2005/08/20 13:06:42  max
 * Can now pass arguments to forms when calling them.
 *
 * Revision 1.2  2005/05/18 20:00:00  max
 * Application class now includes global variables flag (change +new to
 * +new: to do so).
 * +new: now populate Application class attributes from the subclass to
 * the Application one. So no need to do so in subclasses.
 * Add -find: and -gotoItem:justLaunched: methods to implement Palm Find
 * feature (implemented by subclasses).
 *
 * Revision 1.1  2005/02/09 22:57:21  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_APPLICATION
#include "Application.h"

//#include <Common/System/palmOneNavigator.h>
#include <Common/System/HsNavCommon.h>
#include <Common/System/HsExtCommon.h>

#include "BaseForm.h"


@implementation Application

+ (Application*)new:(Boolean)b_globals
{
  Application_c *oAppliClass, *oCurClass;

  ErrFatalDisplayIf(self->oAppli != nil,
		    "Can only have one Application at a time");

  // Les flags au lancement du programme
  self->b_globals = b_globals;

  // On met notre unique instance dans la classe
  self->oAppli = [self alloc];

  // On répercute ces attributs jusqu'à la classe Application
  oAppliClass = Application;
  oCurClass = self;

  do
  {
    oCurClass = (Application_c*)oCurClass->oSuper;
  
    oCurClass->b_globals = b_globals;
    oCurClass->oAppli = self->oAppli;
  }
  while (oCurClass != oAppliClass);

  return [self->oAppli init];
}


// Renvoie l'instance unique d'Application : ce n'est pas un constructeur !!!
+ (Application*)appli
{
  return self->oAppli;
}


- (Application*)init
{
  UInt32 ul_version;

  if (self->oIsa->b_globals)
    oApplication = self;

  // Version de la ROM
  FtrGet(sysFtrCreator, sysFtrNumROMVersion, &self->ul_rom_version);

  // Attente infinie d'un évènement
  self->ul_wait_for = evtWaitForever;

  // La couleur et la haute densité
  if (self->ul_rom_version >= 0x03500000)
  {
    void* pv_proc;

    // See if it supports 16-bit color
    pv_proc = SysGetTrapAddress(sysTrapWinSetForeColorRGB);

    if (pv_proc && pv_proc != SysGetTrapAddress(sysTrapSysUnimplemented))
    {
      UInt32 ul_dummy, ul_depth;
      Boolean b_color;

      WinScreenMode(winScreenModeGet, &ul_dummy, &ul_dummy, &ul_depth,
		    &b_color);

      self->uh_color_enabled = ul_depth > 1;
    }

    // High density ?
    if (FtrGet(sysFtrCreator, sysFtrNumWinVersion, &ul_version) == 0
	&& ul_version >= 4)
    {
      //UInt32 ui_attr;
      //WinScreenGetAttribute(winScreenDensity, &ui_attr);
      //if (ui_attr & kDensityDouble)
	self->uh_high_density = 1;
    }
  }

  //
  // La navigation via le 5-way
  //

  // T5/Treo650 navigator API
  if (FtrGet(sysFtrCreator, sysFtrNumFiveWayNavVersion, &ul_version) == 0)
    self->uh_palmnav_available = PALM_NAV_FRM;
  // Treo600 navigator API
  else if (FtrGet(hsFtrCreator, hsFtrIDNavigationSupported, &ul_version) == 0)
    self->uh_palmnav_available = PALM_NAV_HS;

  return self;
}


- (UInt16)start
{
  [self loadPrefs];

  return 0;
}


- (void)stop
{
  FrmCloseAllForms();

  [self savePrefs];
}


- (void)loadPrefs
{
  // Définie dans la classe fille
}


- (void)savePrefs
{
  // Définie dans la classe fille
}


- (void)gotoFirstForm
{
  return [self subclassResponsibility];
}


- (void)find:(FindParamsPtr)ps_find_params
{
  return [self subclassResponsibility];
}


- (void)gotoItem:(GoToParamsPtr)ps_goto_params justLaunched:(Boolean)b_launched
{
  return [self subclassResponsibility];
}


- (void)eventLoop
{
  Int16 err;
  EventType event;

  do
  {
    EvtGetEvent(&event, self->ul_wait_for);

    if ((err = [self eventEach:&event]) != 0)
    {
      if (err < 0)
	goto frm_dispatch;
      continue;
    }

    if (SysHandleEvent(&event))
      continue;

    if (MenuHandleEvent(NULL, &event, &err))
      continue;

    if (event.eType == frmLoadEvent)
    {
      BaseForm_c *oFormClass;
      UInt16 uh_form;

      // event.data.frmLoad.formID MUST ALWAYS BE > 0
      // Un formulaire est forcément sur 7 bits, cela nous permet de
      // faire passer d'autres infos dans les 9 bits de poids fort
      uh_form = (event.data.frmLoad.formID & APP_FORM_ID_MASK) - 1;

      if (uh_form < self->uh_form_num)
      {
	oFormClass
	  = ((BaseForm_c**)MemHandleLock(self->vh_form_classes))[uh_form];
	MemHandleUnlock(self->vh_form_classes);
      
	[oFormClass new:event.data.frmLoad.formID];
	continue;
      }
    }
    // Un formulaire est forcément sur 7 bits, cela nous permet de
    // faire passer d'autres infos dans les 9 bits de poids fort, il
    // faut donc corriger l'ID du formulaire avant de le passer à la
    // fonction générique.
    // On fait ça seulement pour frmLoadEvent et frmOpenEvent car
    // c'est FrmPopupForm() qui les génère tous les deux et c'est de
    // lui dont on se sert.
    else if (event.eType == frmOpenEvent)
      event.data.frmOpen.formID &= APP_FORM_ID_MASK;

 frm_dispatch:
    FrmDispatchEvent(&event);
  }
  while (event.eType != appStopEvent);
}


//
// Retour :
// - Si 0, on analyse l'évènement normalement
// - Si < 0, on effectue un FrmDispatchEvent avec test de appStopEvent
// - Si > 0, on passe à l'évènement suivant
- (Int16)eventEach:(EventType*)ps_event
{
  return 0;
}


- (Application*)free
{
  // On réinitialise notre unique instance dans la classe
  self->oIsa->oAppli = nil;

  return [super free];
}

@end
