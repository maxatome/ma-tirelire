// Copyright (C) 2004 Alexander R. Pruss

#include <PalmOS.h>
#include "resize.h"

#include "resizedemo_res.h"

#define appCreatorID 'rDem'
#define myError ( appErrorClass | 1 )

static Boolean   terminate;

void FatalError( UInt16 alert )
{
     FrmAlert( alert );
     ErrThrow( myError );
}


void* SafeMemPtrNew( UInt32 size )
{
    void* p;
    p = MemPtrNew( size );
    if ( p == NULL ) {
        FatalError( altNoMem );
    }
    return p;
}


void SafeMemPtrFree( void* p )
{
    if ( p != NULL )
        MemPtrFree( p );
}


UInt16 GetObjectIndex( UInt16 id )
{
    return FrmGetObjectIndex( FrmGetActiveForm(), id );
}


void* GetObjectPtr ( UInt16 id )
{
    return FrmGetObjectPtr( FrmGetActiveForm(), GetObjectIndex( id ) );
}


static void Init_frmMain( void )
{
    FrmDrawForm( FrmGetActiveForm() );
}



static Boolean Handler_frmMain( EventType* event )
{
    Boolean handled;

    if ( ResizeHandleEvent( event ) )
        return true;

    handled = false;

    switch (event->eType) {
        case frmOpenEvent:
            Init_frmMain();
            handled = true;
            break;

        case frmUpdateEvent:
            FrmDrawForm( FrmGetActiveForm() );

            handled = true;
            break;

        case ctlSelectEvent: {
            switch( event->data.ctlEnter.controlID ) {
                case btnOK:
                    terminate = true;
                    handled   = true;
                    break;
                default:
                    break;
            }
            break;
        }

        default:
            break;
    }
    return handled;
}



static Boolean Handler_frmAbout( EventType* event )
{
    Boolean handled;

    if ( ResizeHandleEvent( event ) )
        return true;

    handled = false;

    switch (event->eType) {
        case frmOpenEvent:
            FrmDrawForm( FrmGetActiveForm() );
            handled = true;
            break;

        case ctlSelectEvent: {
            switch( event->data.ctlEnter.controlID ) {
                case btnOK:
                    FrmReturnToForm( 0 );
                    handled = true;
                    break;
                default:
                    break;
            }
            break;
        }

        default:
            break;
    }
    return handled;
}



static void EventLoop( void )
{
    EventType event;
    Boolean   handled;

    terminate = false;

    do {
       	EvtGetEvent( &event, evtWaitForever );

       	handled = SysHandleEvent( &event );

       	if ( ! handled ) {
       	    Err err;

       	    handled = MenuHandleEvent( NULL, &event, &err );
       	}

       	if ( ! handled ) {
            switch ( event.eType ) {
                case frmLoadEvent: {
                    UInt16    formID;
                    FormType* form;

                    formID = event.data.frmLoad.formID;

                    form = FrmInitForm( formID );
                    FrmSetActiveForm( form );

                    switch ( formID ) {
                        case frmMain:
                            SetResizePolicy( frmMain );
                            FrmSetEventHandler( form, Handler_frmMain );
                            break;
                        case frmAbout:
                            SetResizePolicy( frmAbout );
                            FrmSetEventHandler( form, Handler_frmAbout );
                            break;
                    }
                    handled = true;
                }
                case menuEvent:
                    switch( event.data.menu.itemID ) {
                        case mnuAbout:
                            FrmPopupForm( frmAbout );
                            handled = true;
                            break;

                        default:
                            break;
                    }
                default:
                    handled = FrmDispatchEvent( &event );
            }
       	}
    } while ( event.eType != appStopEvent && ! terminate );
    FrmCloseAllForms();
}



static Boolean ApplicationStart( void )
{
    InitializeResizeSupport( resizeIndex );
    LoadResizePrefs( ( UInt32 )appCreatorID, PREF_ID_RESIZE );

    FrmGotoForm(frmMain);

    return true;
}


static void ApplicationStop( Boolean cleanupOnly )
{
    if ( ! cleanupOnly )
        SaveResizePrefs( ( UInt32 )appCreatorID, PREF_ID_RESIZE,
            0 );
    TerminateResizeSupport();

}



UInt32 PilotMain( UInt16 command, void* cmdPBP, UInt16 flags )
{
    switch ( command ) {
        case sysAppLaunchCmdNormalLaunch: {
            Err err;
            ErrTry {
                err = errNone;
                if ( ApplicationStart() ) {
                    EventLoop();
                    ApplicationStop( false );
                }
            }
            ErrCatch( err ) {
                ApplicationStop( true );
                if ( err != errNone )
                    return err;
                break;
            } ErrEndCatch

            break;
        }
        case sysAppLaunchCmdNotify:
            HandleResizeNotification( ( (SysNotifyParamType *)cmdPBP )->notifyType );
            break;
        default:
            break;
    }
    return 0;
}



