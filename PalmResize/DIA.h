/* $Id: DIA.h,v 1.2 2006/06/20 12:49:04 max Exp $ */
/*******************************************************************************
    Copyright (c) 2004, Alexander R. Pruss
    All rights reserved.

    Redistribution and use in source and binary forms, with or without modification,
    are permitted provided that the following conditions are met:

        Redistributions of source code must retain the above copyright notice, this
        list of conditions and the following disclaimer.

        Redistributions in binary form must reproduce the above copyright notice, this
        list of conditions and the following disclaimer in the documentation and/or
        other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
    ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************/ 
    
#ifndef _ARP_DIA_H
#define _ARP_DIA_H
    
#ifndef _Str
#define _Str(x) #x
#endif  /* 
 */
    
//#include "viewer.h"
    
#include "resize.h"

typedef enum { 
DIA_HARDWARE_NONE =
        0, 
DIA_HARDWARE_HANDERA, 
DIA_HARDWARE_SONY1, 
DIA_HARDWARE_SONY2,
        
DIA_HARDWARE_PALM10, 
DIA_HARDWARE_PALM11, 
DIA_HARDWARE_UNKNOWN 
} DIAHardwareType;


#ifdef SUPPORT_DIA

extern DIAHardwareType InitializeDIA(void) DIA_SECTION;

extern void TerminateDIA(void) DIA_SECTION;

extern void SetDIAState(DIAStateType state) DIA_SECTION;

extern void SetDIAAllowResize(Boolean allow) DIA_SECTION;

extern Boolean HandleResizeNotification(UInt32 notificationType) 
 DIA_SECTION;

extern DIAStateType GetDIAState(void) DIA_SECTION;

extern void SetCustomDIAPolicy(UInt16 formID) DIA_SECTION;

extern DIAHardwareType GetDIAHardware(void) DIA_SECTION;

extern void SetDIAConstraints(WinHandle winH, Boolean defaultBig, 
    Boolean allowBig) DIA_SECTION;

/* Check which DIA state covers more screen space */ 
extern Int16 CompareDIAState(DIAStateType x, DIAStateType y) 
 DIA_SECTION;

extern void GetHiddenStatusBarArea(RectangleType * area) DIA_SECTION;


/* These two functions should NOT be used by code other than that in
   resize.c and DIA.c. */ 
extern void PushCoordinateSystemToStandard(void) DIA_SECTION;

extern void PopCoordinateSystem(void) DIA_SECTION;

extern FontID HanderaAdjustFont(FontID font) DIA_SECTION;

extern Coord HanderaCoord(Coord x) DIA_SECTION;


#else   /* 
 */
    
#define InitializeDIA()              DIA_HARDWARE_NONE
#define TerminateDIA()
#define SetDIAState( s )
#define SetDIAAllowResize( a )
#define HandleResizeNotification( n ) false
#define GetDIAState()                DIA_STATE_MAX
#define SetCustomDIAPolicy( f )
#define GetDIAHardware()             DIA_HARDWARE_NONE
#define SetDIAConstraints( w, d, a )
#define CompareDIAState( x, y )      0
#define GetHiddenStatusBarArea( a )  MemSet( a, sizeof( RectangleType ), 0 )
#define HanderaAdjustFont( font )    ( font )
#define HanderaCoord( x )            ( x )
    
#endif  /* 
 */
    
#endif  /* _ARP_DIA_H */
