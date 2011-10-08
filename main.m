/* 
 * main.c -- 
 * 
 * Author          : Max Root
 * Created On      : Sat Jul  6 16:07:41 2002
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Dec 13 14:41:01 2007
 * Update Count    : 34
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: main.m,v $
 * Revision 1.7  2008/01/14 13:06:28  max
 * Rework PilotMain().
 *
 * Revision 1.6  2006/06/23 13:25:36  max
 * Don't set oMaTirelire anymore. It's now Application that set oApplication.
 *
 * Revision 1.5  2005/05/18 20:00:08  max
 * Add ARE_GLOBALS macro.
 * Pass global variables presence flag to the MaTirelire class constructor.
 * Find Palm feature implemented.
 *
 * Revision 1.4  2005/03/27 15:38:31  max
 * Implement sysAppLaunchCmdOpenDB and sysAppLaunchCmdSyncNotify launch codes.
 *
 * Revision 1.3  2005/03/20 22:28:32  max
 * Add alarm management
 *
 * Revision 1.2  2005/03/02 19:02:52  max
 * Tell classes whether the globals are available or not.
 *
 * Revision 1.1  2005/02/09 22:57:23  max
 * First import.
 *
 * ==================== RCS ==================== */

#include "MaTirelire.h"
#include "MaTirelireDefs.h"

#include "alarm.h"

#include "PalmResize/DIA.h"

// Set when the system has created and initialized a new globals world
// for the application. Implies new owner ID for memory chunks.
#define ARE_GLOBALS(launchFlags) \
			((launchFlags & sysAppLaunchFlagNewGlobals) != 0)

static MaTirelire *app_init(UInt16 launchFlags)
{
  // Test pour savoir si oui ou non les classes doivent �tre initialis�es :
  // => Tout le temps sauf si on est appel� pendant notre propre ex�cution
  //
  // Set when the application is calling its entry point as a
  // subroutine call. This tells the launch code that it's OK to keep
  // the A5 (globals) pointer valid through the call. If this flag is
  // set, it indicates that the application is already running as the
  // current application.
  if ((launchFlags & sysAppLaunchFlagSubCall) == 0)
  {
    // On charge les classes
    ObjcLoadClasses(ARE_GLOBALS(launchFlags));

    return [MaTirelire new:ARE_GLOBALS(launchFlags)];
  }

  // D�j� initialis�e...
  return [MaTirelire appli];
}

#define APP_BEGIN	oAppli = app_init(launchFlags)

UInt32 PilotMain(UInt16 cmd, Ptr cmdPBP, UInt16 launchFlags)
{
  MaTirelire *oAppli = NULL;

  switch (cmd)
  {
    ////////////////////////////////////////////////////////////////////////
    //
    // Les codes suivants ont acc�s aux variables globales
    //
    ////////////////////////////////////////////////////////////////////////

    // D�marrage normal
  case sysAppLaunchCmdNormalLaunch:
  case sysAppLaunchCmdOpenDB:	// Avec une base de comptes pr�cise
    APP_BEGIN;

    if ([oAppli start])
      break;

    if (cmd == sysAppLaunchCmdNormalLaunch)
      [oAppli gotoFirstForm];
    else
      [oAppli gotoFirstFormWithDB:(SysAppLaunchCmdOpenDBType*)cmdPBP];

    [oAppli eventLoop];

    [oAppli stop];
    break;

    // Apr�s une recherche, on va direct � un enregistrement
  case sysAppLaunchCmdGoTo:
  {
    Boolean b_not_running = ARE_GLOBALS(launchFlags);

    APP_BEGIN;

    if (b_not_running)
    {
      if ([oAppli start])
	break;
    }

    [oAppli gotoItem:(GoToParamsPtr)cmdPBP justLaunched:b_not_running];

    if (b_not_running)
    {
      [oAppli eventLoop];
      [oAppli stop];
    }
  }
  break;

    ////////////////////////////////////////////////////////////////////////
    //
    // Les codes suivants n'ont pas acc�s aux variables globales
    //
    ////////////////////////////////////////////////////////////////////////

    // Recherche
  case sysAppLaunchCmdFind:
    APP_BEGIN;
    [oAppli find:(FindParamsPtr)cmdPBP];
    break;

    // Juste apr�s une synchro il faut trier/v�rifier la base...
  case sysAppLaunchCmdSyncNotify:
    APP_BEGIN;

    // V�rification des bases AVEC tri
    do_on_each_transaction(Transaction->_validDB_, false);

    // Continue avec la gestion des alarmes...

    // La date et/ou l'heure ont chang�
  case sysAppLaunchCmdTimeChange:
    // Les alarmes...
    alarm_schedule_all();	// objc-free
    break;

    // Une alarme !!!
  case sysAppLaunchCmdAlarmTriggered:
    alarm_triggered((SysAlarmTriggeredParamType *)cmdPBP); // objc-free
    break;

    // Il faut afficher l'alarme
  case sysAppLaunchCmdDisplayAlarm:
    APP_BEGIN;
    alarm_display((SysDisplayAlarmParamType *)cmdPBP);
    break;

  // Apr�s un reset
  case sysAppLaunchCmdSystemReset:
    if (((SysAppLaunchCmdSystemResetType*)cmdPBP)->hardReset == 0)
      alarm_schedule_all();	// objc-free
    break;

    // Un autre palm tente de nous beamer des donn�es
  case sysAppLaunchCmdExgReceiveData:
    break;

  case sysAppLaunchCmdNotify:
    APP_BEGIN;
    HandleResizeNotification(((SysNotifyParamType*)cmdPBP)->notifyType);
    break;
  }

  // Si l'appli est initialis�e ET qu'on n'est pas appel� en tant que fonction
  if (oAppli != NULL && (launchFlags & sysAppLaunchFlagSubCall) == 0)
  {
    [oAppli free];

    // On lib�re les classes (si aucune n'a �t� allou�e, c'est pas grave)...
    ObjcUnloadClasses(ARE_GLOBALS(launchFlags));
  }

  return 0;
}
