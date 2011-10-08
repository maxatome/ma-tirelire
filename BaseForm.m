/* 
 * BaseForm.m -- 
 * 
 * Author          : Max Root
 * Created On      : Thu Nov 21 22:44:12 2002
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb  1 15:54:23 2008
 * Update Count    : 204
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: BaseForm.m,v $
 * Revision 1.19  2008/02/01 17:09:34  max
 * Use symbol* macros whenever it is possible.
 * FLD_CHECK_VOID now uses is_empty().
 *
 * Revision 1.18  2008/01/21 18:27:05  max
 * Delete possible selection before inserting any digit in numeric fields.
 *
 * Revision 1.17  2008/01/14 17:25:06  max
 * Switch to new mcc.
 * Doesn't valid the form if the focus is on a multilines editable field.
 * Avoid overflow in numeric fields.
 * Correct -focusPrevObject and -focusNextObject methods.
 *
 * Revision 1.16  2006/11/04 23:47:55  max
 * Add -selTriggerSignChange: method.
 *
 * Revision 1.15  2006/10/05 19:08:43  max
 * Add dates bound feature...
 *
 * Revision 1.14  2006/06/30 08:12:36  max
 * Handle correctly Treo600 navigator API.
 *
 * Revision 1.13  2006/06/23 13:25:00  max
 * Add -focusObjectIndex: method.
 * Change meaning of -focusObject: to handle object IDs.
 * Use oApplication instead of [Application appli].
 * No more need of fiveway.h with PalmSDK installed.
 * Add new Palm 5-way handling.
 * Handle Palm Nav feature.
 * Now call -focusObject: instead of FrmSetFocus() to set focus to a field.
 * When drawing tabs, take caution to existing clip.
 *
 * Revision 1.12  2006/06/20 14:15:18  max
 * Add -frmObjectFocusLost: method.
 * Handle tabs redraw when focus ring moves. Not perfect yet.
 *
 * Revision 1.11  2006/06/19 16:13:05  max
 * Add the uh_visibility attribute to know whether we can draw or not on
 * the form.
 * Add -frmObjectFocusTake: method to handle "menu flashing" bug on the
 * TX when the form contains a visible list.
 *
 * Revision 1.10  2006/04/26 10:44:06  max
 * Add generic chrCarriageReturn handling.
 *
 * Revision 1.9  2006/04/25 12:44:54  max
 * Correct mistake in comment.
 *
 * Revision 1.8  2006/04/25 08:46:37  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 * guh_pending_events now correctly initialized.
 * Add DEBUG_UPDATE #ifdef to debug redraws.
 * -ctlSelect: now handle tabs.
 * -keyDown: now handle T|T 5-pad navigation for tabs.
 * Redraws reworked (continue).
 * -hideIndex: can now hide frmListObj objects on OSes < 3.5.
 * -showIndex: can now show frmListObj objects on OSes < 3.5.
 * -tabsShow: now correctly handle hidden list with popup/selector-trigger.
 *
 * Revision 1.7  2005/11/19 16:56:20  max
 * Generic handling of T|T 5-way in tabbed dialogs.
 * Handling of . and , reworked in numeric fields.
 *
 * Revision 1.6  2005/08/28 10:02:25  max
 * Add -findPrevForm: method.
 *
 * Revision 1.5  2005/08/20 13:06:44  max
 * oFrm now always initialized.
 * Can now pass arguments to forms when calling them.
 * Delete -getCurForm method.
 * Prepare switching to 64 bits amounts.
 * Rework update/callerUpdate interaction.
 *
 * Revision 1.4  2005/05/08 12:12:50  max
 * list_line_draw() generic sub-menus right arrows drawing added.
 * -fillLabel:withSTR: totally reworked. Works now fine with labels and controls.
 *
 * Revision 1.3  2005/03/20 22:28:17  max
 * -childClosed: mechanism deleted.
 * One can now choose the first visible tab at -open stage.
 *
 * Revision 1.2  2005/02/13 00:06:17  max
 * Change prototype of -keyFilter:for:
 * It allows to detect and not block special keys in numeric fields.
 * Now the Select key of the 5-way works everywhere...
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

//
// Pour ((FormBitmapType*)
//       FrmGetObjectPtr(self->pt_frm, uh_index))->attr.usable = 0;
// Plus bas...
#define ALLOW_ACCESS_TO_INTERNALS_OF_FORMS
#define ALLOW_ACCESS_TO_INTERNALS_OF_WINDOWS
#define ALLOW_ACCESS_TO_INTERNALS_OF_LISTS

#include <Unix/unix_stdarg.h>
#include <PalmOSGlue/FrmGlue.h>
#include <PalmOSGlue/TxtGlue.h>
#include <PalmOSGlue/CtlGlue.h>
#include <68k/System/HsNav.h>
#include <Common/System/palmOneNavigator.h>

#define EXTERN_BASEFORM
#include "BaseForm.h"

#include "Application.h"

#ifdef SUPPORT_DIA
# include "PalmResize/DIA.h"
#endif

#include "float.h"

#include "objRsc.h"		// XXX
#include "MaTirelireDefsAuto.h"	// XXX
#include "misc.h"		// XXX pour list_line_draw()


// Dans PalmResize/resize.c
extern void UniqueUpdateForm(UInt16 formID, UInt16 code);


static Boolean __form_generic_handler(EventPtr e)
{
#ifdef SUPPORT_DIA
  if (ResizeHandleEvent(e))
    return true;
  else
#endif
  {
    switch (e->eType)
    {
    case frmOpenEvent:		return [oFrm open];
    case frmCloseEvent:		return [oFrm close];
    case frmUpdateEvent:	return [oFrm update:&e->data.frmUpdate];
    case frmCallerUpdateEvent:
      return [oFrm callerUpdate:(struct frmCallerUpdate*)&e->data];
    case frmGotoEvent:		return [oFrm goto:&e->data.frmGoto];
    case menuEvent:		return [oFrm menu:e->data.menu.itemID];
    case ctlEnterEvent:		return [oFrm ctlEnter:&e->data.ctlEnter];
    case ctlSelectEvent:	return [oFrm ctlSelect:&e->data.ctlSelect];
    case keyDownEvent:		return [oFrm keyDown:&e->data.keyDown];
    case sclRepeatEvent:	return [oFrm sclRepeat:&e->data.sclRepeat];
    case ctlRepeatEvent:	return [oFrm ctlRepeat:&e->data.ctlRepeat];
    case tblEnterEvent:		return [oFrm tblEnter:e];
    case fldChangedEvent:	return [oFrm fldChanged:&e->data.fldChanged];
    case fldEnterEvent:		return [oFrm fldEnter:&e->data.fldEnter];
    case lstSelectEvent:	return [oFrm lstSelect:&e->data.lstSelect];
    case penDownEvent:		return [oFrm penDown:e];
    case winDisplayChangedEvent:return [oFrm winDisplayChanged];
    case frmObjectFocusTakeEvent:
      return [oFrm frmObjectFocusTake:&e->data.frmObjectFocusTake];
    case frmObjectFocusLostEvent:
      return [oFrm frmObjectFocusLost:&e->data.frmObjectFocusLost];

    case winExitEvent:
      if (e->data.winExit.exitWindow == (WinHandle)oFrm->pt_frm)
	oFrm->uh_visibility = 0;
      return false;

    case winEnterEvent:
      if (e->data.winEnter.enterWindow == (WinHandle)oFrm->pt_frm
	  && e->data.winEnter.enterWindow == (WinHandle)FrmGetFirstForm())
	oFrm->uh_visibility = 1;
      return false;

    default:
      return false;				 
    }
  }
}


void list_line_draw_line(RectangleType *prec_bounds, Int16 h_upperline)
{
  Int16 h_y;
  Boolean b_colored = false;

  if (h_upperline > 0)
    h_y = prec_bounds->topLeft.y;
  else
    h_y = prec_bounds->topLeft.y + prec_bounds->extent.y - 1;

  // Si on a la couleur...
  if (oApplication->uh_color_enabled)
  {
    WinPushDrawState();
    WinSetForeColor(UIColorGetTableEntryIndex(UIObjectFrame));
    b_colored = true;
  }

  WinDrawLine(prec_bounds->topLeft.x - 2, h_y,
	      prec_bounds->topLeft.x + prec_bounds->extent.x - 1, h_y);

  if (b_colored)
    WinPopDrawState();
}


void list_line_draw(Int16 h_line, RectangleType *prec_bounds, Char **ppa_lines)
{
  Char *pa_line;
  UInt16 uh_len;
  Int16 h_upperline = 0;
  FontID uh_font = stdFont;

  for (pa_line = ppa_lines[h_line]; ; pa_line++)
    switch (*pa_line)
    {
    case '*':
      uh_font = boldFont;
      break;

    case '_':
      h_upperline = -1;
      break;

    case '^':
      if (h_line > 0)
	h_upperline = 1;
      break;

    default:
      goto end;
    }

 end:

  // On écrit le texte
  uh_len = StrLen(pa_line);
  if (uh_len > 0)
  {
    FontID uh_save_font;
    UInt16 uh_extent = prec_bounds->extent.x;
    Int16 h_width;

    uh_save_font = FntGetFont();

    if (pa_line[uh_len - 1] == '>')
    {
      FntSetFont(symbol11Font);
      uh_extent -= FntCharWidth(symbol11RightArrow) + 1;

      WinDrawChars("\003" /* is symbol11RightArrow */, 1,
		   prec_bounds->topLeft.x + uh_extent, prec_bounds->topLeft.y);

      uh_len--;
    }

    FntSetFont(uh_font);

    h_width = prepare_truncating(pa_line, &uh_len, uh_extent);
    WinDrawTruncatedChars(pa_line, uh_len,
			  prec_bounds->topLeft.x, prec_bounds->topLeft.y,
			  h_width);

    FntSetFont(uh_save_font);  
  }

  // On dessine la ligne
  if (h_upperline)
    list_line_draw_line(prec_bounds, h_upperline);
}


@implementation BaseForm

+ (void)initialize:(Boolean)b_globals
{
  if (b_globals)
  {
    oFrm = nil;
    guh_pending_events = 0;
  }
}


+ (BaseForm*)setCurForm:(BaseForm*)oCurForm
{
  BaseForm *oOldForm = oFrm;
  oFrm = oCurForm;
  return oOldForm;
}

+ (BaseForm*)new:(UInt16)uh_id
{
  return [[[self alloc] init] load:uh_id];
}


- (BaseForm*)free
{
  // Libération de la sauvegarde des scrollbars...
  if (self->ps_scrollbars != NULL)
    MemPtrFree(self->ps_scrollbars);

  return [super free];
}


- (BaseForm*)init
{
  self->pf_form_handler = __form_generic_handler;

  return self;
}


- (Boolean)open
{
  // Si on est sur une rom < 3.2, il faut faire une bidouille pour
  // faire disparaître les scrollbars
  if (oApplication->ul_rom_version < 0x03203000)
  {
    Int16 h_index;
    UInt16 uh_id, uh_num_scrollbars = 0;

    for (h_index = FrmGetNumberOfObjects(self->pt_frm); --h_index >= 0; )
    {
      uh_id = FrmGetObjectId(self->pt_frm, h_index);

      if (FrmGetObjectType(self->pt_frm, h_index) == frmScrollBarObj)
	uh_num_scrollbars++;
    }

    if (uh_num_scrollbars > 0)
    {
      uh_num_scrollbars *= sizeof(*self->ps_scrollbars);

      // XXX Erreur fatale plutôt ??? XXX
      NEW_PTR(self->ps_scrollbars, uh_num_scrollbars, return false);

      MemSet(self->ps_scrollbars, uh_num_scrollbars, '\0');
    }
  }

  // S'il y a des onglets...
  if (self->uh_tabs_num > 0)
  {
    UInt16 uh_tab;

    // Premier onglet
    if (self->uh_tabs_current == 0)
      self->uh_tabs_current = TAB_ID_TO_NUM(TAB_ID_FIRST_TAB);

    uh_tab = TAB_NUM_TO_ID(self->uh_tabs_current);

    [self tabsHide:uh_tab];
    FrmDrawForm(self->pt_frm);
    self->uh_form_drawn = 1;
    [self tabsDraw:uh_tab drawLines:true];
  }
  else
  {
    FrmDrawForm(self->pt_frm);
    self->uh_form_drawn = 1;
  }

  return true;
}


- (Boolean)close
{
  oFrm = self->oPrevForm;

  [self free];

  return false;
}


- (BaseForm*)load:(UInt16)uh_id
{
  self->uh_form_flags = uh_id;

  // Voir -eventLoop dans Application
  uh_id &= APP_FORM_ID_MASK;

  self->pt_frm = FrmInitForm(uh_id);

  FrmSetActiveForm(self->pt_frm);

#ifdef SUPPORT_DIA
  SetResizePolicy(uh_id);
#endif
  FrmSetEventHandler(self->pt_frm, self->pf_form_handler);

  self->oPrevForm = [isa setCurForm:self];

  return self;
}


- (BaseForm*)findPrevForm:(id)oFormClass
{
  BaseForm *oCurForm;

  for (oCurForm = self->oPrevForm; oCurForm != nil;
       oCurForm = oCurForm->oPrevForm)
    if ([(Object*)oCurForm->oIsa isKindOf:oFormClass])
      return oCurForm;

  return nil;
}


// Appelée par -update: avec code frmRedrawUpdateCode
- (void)redrawForm
{
  FrmDrawForm(self->pt_frm);

  // S'il y a des onglets, il faut les redessiner...
  if (self->uh_tabs_num > 0)
    [self tabsDraw:TAB_NUM_TO_ID(self->uh_tabs_current) drawLines:true];
}


- (Boolean)update:(struct frmUpdate *)ps_update
{
  if (ps_update->updateCode == frmRedrawUpdateCode)
  {
    // Si il y a au moins un événement callerUpdate pas encore arrivé,
    // on retarde l'exécution de l'update
    if (guh_pending_events & ~PENDING_EVENT_UPDATE)
    {
      guh_pending_events |= PENDING_EVENT_UPDATE;

#ifdef DEBUG_UPDATE
      DrawPrintf("Z 0x%x ", guh_pending_events);
#endif
    }
    else
    {
      [self redrawForm];
      self->uh_display_changed = 0;

#ifdef DEBUG_UPDATE
      DrawPrintf("X");
#endif
    }

    return true;
  }

  return false;
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  // Si un update est arrivé juste avant nous, on l'a mis de coté et
  // il faut donc l'appeler maintenant
  if (--guh_pending_events == PENDING_EVENT_UPDATE)
  {
    // On supprime le flag PENDING_EVENT_UPDATE
    guh_pending_events = 0;

    [self redrawForm];
    self->uh_display_changed = 0;

#ifdef DEBUG_UPDATE
    DrawPrintf("O (%lx) ", ps_update->updateCode);
#endif
  }
#ifdef DEBUG_UPDATE
  else
    DrawPrintf("W 0x%x (%lx) ", guh_pending_events, ps_update->updateCode);
#endif

  // Comme c'est un événement à nous, créé de toute pièce, on le
  // déclare comme traité
  return true;
}


- (void)sendCallerUpdate:(UInt32)ul_code
{
  EventType e_user;
  struct frmCallerUpdate *ps_update;

  MemSet(&e_user, sizeof(e_user), 0);

  e_user.eType = frmCallerUpdateEvent;

  ps_update = (struct frmCallerUpdate*)&e_user.data;
  ps_update->formID = FrmGetFormId(FrmGetFirstForm());
  ps_update->updateCode = ul_code;

  EvtAddEventToQueue(&e_user);

  // Un nouvel événement callerUpdate est en route...
  guh_pending_events++;

#ifdef DEBUG_UPDATE
  DrawPrintf("B+ 0x%x ", guh_pending_events);
#endif
}


- (Boolean)goto:(struct frmGoto *)ps_goto
{
  return false;
}


- (Boolean)menu:(UInt16)uh_id
{
  return false;
}


- (Boolean)ctlEnter:(struct ctlEnter *)ps_enter
{
  // Clic sur un onglet (valide)
  // On le fait au ctlEnter plutôt qu'au ctlSelect car c'est nous qui
  // dessinons le contour du bouton en arrondi alors que l'OS gère un
  // bouton carré...
  if (self->uh_tabs_num > 0
      && (ps_enter->controlID & TAB_ID_MASK) == 0
      && ps_enter->controlID > 0
      && ps_enter->controlID <= TAB_NUM_TO_ID(self->uh_tabs_num))
    return [self clicOnTab:ps_enter->controlID];

  return false;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  if (self->uh_tabs_num > 0
      && (ps_select->controlID & TAB_ID_MASK) == 0
      && ps_select->controlID > 0
      && ps_select->controlID <= TAB_NUM_TO_ID(self->uh_tabs_num))
    return [self clicOnTab:ps_select->controlID];

  return false;
}


- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key
{
  switch (ps_key->chr)
  {
  case vchrNextField:
    return [self focusNextObject];

  case vchrPrevField:
    return [self focusPrevObject];

  case chrCarriageReturn:
  case chrLineFeed:
  {
    UInt16 uh_index;

    // On n'utilise pas FrmGlueGetDefaultButtonID() car dans pas mal
    // d'écrans le bouton par default est Cancel
    uh_index = FrmGetObjectIndex(self->pt_frm, autoCarriageReturnButton);
    if (uh_index != frmInvalidObjectId
	&& FrmGetObjectType(self->pt_frm, uh_index) == frmControlObj
	&& FrmGlueGetObjectUsable(self->pt_frm, uh_index))
    {
      UInt16 uh_focus_idx = FrmGetFocus(self->pt_frm);

      // Si le focus est sur un champ éditable multi-lignes on ne fait rien
      if (uh_focus_idx != noFocus
	  && FrmGetObjectType(self->pt_frm, uh_focus_idx) == frmFieldObj)
      {
	FieldAttrType s_attr;

	FldGetAttributes(FrmGetObjectPtr(self->pt_frm, uh_focus_idx), &s_attr);

	// Champ multi-lignes
	if (s_attr.usable && s_attr.visible && s_attr.editable
	    && s_attr.singleLine == 0)
	  break;
      }

      CtlHitControl(FrmGetObjectPtr(self->pt_frm, uh_index));
      return true;
    }
  }
  break;
  }

  // S'il y a des onglets, déplacement dans les onglets via le 5-pad des T|T
  if (self->uh_tabs_num > 0 && ps_key->chr == vchrNavChange) // OK (5-way T|T)
  {
    Int16 h_tab;

    switch (ps_key->keyCode & (navBitsAll | navChangeBitsAll))
    {
    case navBitLeft | navChangeLeft:
      h_tab = -1;
      break;
    case navBitRight | navChangeRight:
      h_tab = 1;
      break;
    default:
      return false;
    }

    h_tab += self->uh_tabs_current;
    if (h_tab <= 0)
      h_tab = self->uh_tabs_num;
    else if (h_tab > self->uh_tabs_num)
      h_tab = 1;

    [self clicOnTab:TAB_NUM_TO_ID(h_tab)];

    return true;
  }

  return false;
}


- (Boolean)sclRepeat:(struct sclRepeat *)ps_repeat
{
  return false;
}


- (Boolean)ctlRepeat:(struct ctlRepeat *)ps_repeat
{
  return false;
}


- (Boolean)tblEnter:(EventType*)e
{
  return false;
}


- (Boolean)fldChanged:(struct fldChanged *)ps_fld_changed
{
  return false;
}


- (Boolean)fldEnter:(struct fldEnter*)ps_fld_enter
{
  return false;
}


- (Boolean)lstSelect:(struct lstSelect *)ps_list_select
{
  return false;
}


- (Boolean)penDown:(EventType*)e
{
  return false;
}


- (Boolean)winDisplayChanged
{
  // On devra faire le nécessaire dans -update:
  self->uh_display_changed = 1;

  return false;
}


//
// When the focus changes via 5-way navigator :
// - Receive frmObjectFocusTakeEvent for the new object
// - When user handler returns false, system handler delete old ring,
//   draw new object in its focused state (read in Palm OS Reference) and
//   draw new ring
//
// - Receive frmObjectFocusLostEvent for the previous object
// - When user handler returns false, system handler draws internal
//   new ring and redraws previous object
//


//
// Bidouille pour le TX où il nous arrive d'avoir cet évènement au
// moment où le menu vient de s'ouvrir, ce qui le fait se fermer
// immédiatement.
- (Boolean)frmObjectFocusTake:(struct frmObjectFocusTake*)ps_take
{
  if (oFrm->uh_visibility == 0)
    return true;

  return false;
}


- (Boolean)frmObjectFocusLost:(struct frmObjectFocusLost*)ps_lost
{
  // S'il y a des onglets...
  if (self->uh_tabs_num > 0
      && (ps_lost->objectID & TAB_ID_MASK) == 0
      && ps_lost->objectID > 0
      && ps_lost->objectID <= TAB_NUM_TO_ID(self->uh_tabs_num))
    [self tabsDraw:TAB_NUM_TO_ID(self->uh_tabs_current) drawLines:true];

  return false;
}


////////////////////////////////////////////////////////////////////////
//
// Méthodes diverses
//
////////////////////////////////////////////////////////////////////////

- (Boolean)replaceField:(UInt16)uh_field withSTR:(Char*)pa_new len:(Int16)h_len
{
  FieldType *pt_field;
  MemHandle vh_field;
  Char ra_num[DOUBLE_STR_SIZE], *pa_field;
  UInt16 uh_max_chars;
  Boolean b_ret = false;

  // On n'a pas affaire à une chaîne
  if (uh_field & REPLACE_FIELD_EXT)
  {
    UInt16 uh_num_len;
    Boolean b_neg = false;
    Char a_dec_sep = '\0';

    uh_field &= ~REPLACE_FIELD_EXT;

    // Le séparateur décimal ne nous est pas donné, on le prend des préférences
    if (h_len & (REPL_FIELD_DOUBLE | REPL_FIELD_FDWORD))
      a_dec_sep = float_dec_separator();

    // pa_new est un pointeur sur un double
    if (h_len & REPL_FIELD_DOUBLE)
    {
      double d_num = *(double*)pa_new;

      if (d_num == 0 && (h_len & REPL_FIELD_EMPTY_IF_NULL))
	uh_num_len = 0;
      else
      {
	if (d_num < 0)
	{
	  b_neg = true;

	  // On n'affiche pas le signe
	  if ((h_len & REPL_FIELD_KEEP_SIGN) == 0)
	    d_num = - d_num;
	}

	StrDoubleToA(ra_num, d_num, &uh_num_len, a_dec_sep, 9);
      }
    }
    // pa_new EST un Int32
    else if (h_len & (REPL_FIELD_DWORD | REPL_FIELD_FDWORD))
    {
      Int32 l_num = (Int32)pa_new;

      pa_new = ra_num;

      if (l_num == 0 && (h_len & REPL_FIELD_EMPTY_IF_NULL))
	uh_num_len = 0;
      else
      {
	if (l_num < 0)
	{
	  b_neg = true;

	  l_num = - l_num;

	  // On affiche le signe
	  if (h_len & REPL_FIELD_KEEP_SIGN)
	    *pa_new++ = '-';
	}

	if (h_len & REPL_FIELD_DWORD)
	  StrUInt32ToA(pa_new, l_num, &uh_num_len);
	else
	  Str100FToA(pa_new, l_num, &uh_num_len, a_dec_sep);

	if (pa_new != ra_num)
	  uh_num_len++;
      }
    }
#if 0
    // pa_new est un pointeur sur un Int64
    else if (h_len & (REPL_FIELD_INT64 | REPL_FIELD_FINT64))
    {
      Int64 ll_num = *(Int64*)pa_new;

      pa_new = ra_num;

      if (ll_num == 0 && (h_len & REPL_FIELD_EMPTY_IF_NULL))
	uh_num_len = 0;
      else
      {
	if (ll_num < 0)
	{
	  b_neg = true;

	  ll_num = - ll_num;

	  // On affiche le signe
	  if (h_len & REPL_FIELD_KEEP_SIGN)
	    *pa_new++ = '-';
	}

	if (h_len & REPL_FIELD_DWORD)
	  StrUInt64ToA(pa_new, ll_num, &uh_num_len);
	else
	  Str64100FToA(pa_new, ll_num, &uh_num_len, a_dec_sep);

	if (pa_new != ra_num)
	  uh_num_len++;
      }
    }
#endif
    else
      return false;

    if (h_len & REPL_FIELD_SELTRIGGER_SIGN)
      [self fillLabel:uh_field - 1 withSTR:b_neg ? "-" : "+"];

    // Près pour la suite
    pa_new = ra_num;
    h_len = uh_num_len;
  }

  pt_field = [self objectPtrId:uh_field];

  if (h_len < 0)
    h_len = StrLen(pa_new);

  vh_field = (MemHandle)FldGetTextHandle(pt_field);

  /* On doit vider le champ */
  if (h_len == 0)
  {
    if (vh_field)
    {
      FldSetTextHandle(pt_field, NULL);
      MemHandleFree(vh_field);

      FldSetDirty(pt_field, true);
    }
    
    b_ret = true;
  }
  else
  {
    /* Pas trop de caractères !!! */
    uh_max_chars = FldGetMaxChars(pt_field);
    if (h_len > uh_max_chars)
      h_len = uh_max_chars;

    /* Champ vide */
    if (vh_field == NULL)
      NEW_HANDLE(vh_field, h_len + 1, return false);
    /* Champ déjà rempli */
    else
    {
      FldSetTextHandle(pt_field, NULL);

      if (MemHandleSize(vh_field) != h_len + 1
	  && MemHandleResize(vh_field, h_len + 1) != 0)
	goto end;
    }

    pa_field = MemHandleLock(vh_field);
    MemMove(pa_field, pa_new, h_len);
    pa_field[h_len] = '\0';
    MemHandleUnlock(vh_field);

    FldSetDirty(pt_field, true);

    b_ret = true;

 end:
    FldSetTextHandle(pt_field, vh_field);
  }

  // Si le champ est visible, on le redessine...
  if (self->uh_form_drawn
      && FrmGlueGetObjectUsable(self->pt_frm,
				FrmGetObjectIndex(self->pt_frm, uh_field)))
    FldDrawField(pt_field);

  return b_ret;
}


#ifndef alertErrorField
# error *** Must define an alert box alertErrorField in .rcp file ***
#endif
#ifndef strFldErrMiss
# error *** Must define a string strFldErrMiss in .rcp file ***
#endif
#ifndef strFldErrNull
# error *** Must define a string strFldErrNull in .rcp file ***
#endif

#define FLD_TYPE_MASK           (FLD_TYPE_WORD | FLD_TYPE_DWORD)
#define FLD_TYPE_FMASK          (FLD_TYPE_FWORD | FLD_TYPE_FDWORD)

#define FLD_TYPE_16MASK         (FLD_TYPE_WORD | FLD_TYPE_FWORD)   /* 16 bits*/
#define FLD_TYPE_32MASK         (FLD_TYPE_DWORD | FLD_TYPE_FDWORD) /* 32 bits*/

/*
 * Verifie le champ renvoie true s'il est valide, false sinon
 * pt_frm   = formulaire
 * uh_field = champ
 * uh_flags = vérification à faire + type de la donnée (voir defines FLD_*)
 * pv_data  = pointeur sur l'endroit à remplir si true
 * uh_label = chaîne contenant le label du champ
 */
- (Boolean)checkField:(UInt16)uh_field flags:(UInt16)uh_flags
	     resultIn:(void*)pv_data
	    fieldName:(UInt16)uh_label
{
  Char	   *pa_content;
  UInt16   uh_sentence;
  FieldPtr pt_field = [self objectPtrId:uh_field];
  Boolean  b_neg = false;


  if ((uh_flags & FLD_TYPE_NEG)
      || ((uh_flags & FLD_SELTRIGGER_SIGN)
	  && CtlGetLabel([self objectPtrId:uh_field - 1])[0] == '-'))
    b_neg = true;

  pa_content = FldGetTextPtr(pt_field);

  /* Le champ ne doit pas etre vide ET il l'est */
  if ((uh_flags & FLD_CHECK_VOID)
      && (pa_content == NULL || is_empty(pa_content)))
    uh_sentence = strFldErrMiss;
  /* Le champ est numérique */
  else if (uh_flags & (FLD_TYPE_MASK|FLD_TYPE_FMASK))
  {
    Int32 l_retval = 0;

    if (pa_content && *pa_content)
    {
      /* Lecture d'un nombre a virgule OU BIEN d'un entier */
      if (uh_flags & FLD_TYPE_FMASK)
	isStrATo100F(pa_content, &l_retval); /* À virgule */
      else
	l_retval = StrAToI(pa_content);	/* Entier */
    }

    /* Le champ ne doit pas valoir 0 ET il le vaut */
    if ((uh_flags & FLD_CHECK_NULL) && l_retval == 0)
      uh_sentence = strFldErrNull;
    else
    {
      /* Nombre négatif */
      if (b_neg)
	l_retval = - l_retval;

      /* Sauvegarde en 16 bits*/
      if (uh_flags & FLD_TYPE_16MASK)
	*(Int16 *)pv_data = (Int16)l_retval;
      /* Sauvegarde en 32 bits*/
      else
	*(Int32 *)pv_data = l_retval;

      return true;
    }
  }
  /* Le champ est numérique double */
  else if (uh_flags & FLD_TYPE_DOUBLE)
  {
    double d_retval = 0;

    if (pa_content && *pa_content)
      isStrAToDouble(pa_content, &d_retval);

    /* Le champ ne doit pas valoir 0 ET il le vaut */
    if ((uh_flags & FLD_CHECK_NULL) && d_retval == 0.)
      uh_sentence = strFldErrNull;
    else
    {
      /* Nombre négatif */
      if (b_neg)
	d_retval = - d_retval;

      *(double*)pv_data = d_retval;

      return true;
    }
  }
  /* Chaîne de caractère */
  else
  {
    UInt16 uh_len;

    if ((uh_len = FldGetTextLength(pt_field)) > 0)
      MemMove(pv_data, pa_content, uh_len);

    ((char*)pv_data)[uh_len] = '\0';

    return true;
  }

  /* Une erreur s'est produite */
  if ((uh_flags & FLD_CHECK_NOALERT) == 0)
  {
    Char ra_label[32], ra_sentence[32];
    UInt16 uh_tab;

    // Le champ erroné est dans un onglet, il faut passer dessus...
    uh_tab = [self tabsGetTabForId:uh_field];
    if (uh_tab > 0)
      [self clicOnTab:uh_tab];

    SysCopyStringResource(ra_sentence, uh_sentence);
    SysCopyStringResource(ra_label, uh_label);

    FrmCustomAlert(alertErrorField, ra_label, ra_sentence, " ");

    [self focusObject:uh_field];

    uh_sentence = FldGetTextLength(pt_field);
    if (uh_sentence)
      FldSetSelection(pt_field, 0, uh_sentence);
  }

  return false;
}


//
// Appelée dans une méthode -ctlSelect: pour changer le signe d'un
// SELECTORTRIGGER ne pouvant contenir que '+' ou '-'
- (void)selTriggerSignChange:(struct ctlSelect *)ps_select
{
  Char ra_sign[] = "X";

  // Le code ASCII de '-' est 0x2d
  // Le code ASCII de '+' est 0x2e
  // Donc pour transformer l'un en l'autre il faut faire un ^ 0x06
  ra_sign[0] = (CtlGetLabel(ps_select->pControl))[0] ^ 0x06;

  [self fillLabel:ps_select->controlID withSTR:ra_sign];
}


- (Boolean)dateSelect:(UInt16)uh_title date:(DateType*)ps_date
{
  Int16 month = ps_date->month;
  Int16 day = ps_date->day;
  Int16 year = ps_date->year + firstYear;
  Char ra_title[32];

  SysCopyStringResource(ra_title, uh_title);
  if (SelectDay(selectDayByDay, &month, &day, &year, ra_title))
  {
    ps_date->month = (UInt16)month;
    ps_date->day = (UInt16)day;
    ps_date->year = (UInt16)(year - firstYear);

    return true;
  }

  return false;
}


//
// uh_date_id est l'ID du SELECTORTRIGGER contenant la date.
// puh_date est un pointeur sur un DateType contenant la date gérée.
// Le bouton UP est toujours (uh_date_id - 2)
// Le bouton DOWN est toujours (uh_date_id - 1)
// Lorsque la date est cliquée directement, uh_date_id est également
// l'ID de la chaîne à utiliser comme titre de la boîte de choix de la
// date.
- (Boolean)dateInc:(UInt16)uh_date_id date:(DateType*)ps_date
     pressedButton:(UInt16)uh_obj
	    format:(DateFormatType)e_format
{
  DateType s_old_date, *ps_bound_date;
  UInt16 uh_bound_date_id;

  s_old_date = *ps_date;

  // On vient de cliquer sur la date
  if (uh_obj == uh_date_id)
  {
    if ([self dateSelect:uh_date_id date:ps_date] == false)
    {
      // On rafraîchit toujours l'écran sur lequel on va retourner
      UniqueUpdateForm(FrmGetFormId(self->pt_frm), frmRedrawUpdateCode);
      return false;
    }

    // On rafraîchit toujours l'écran sur lequel on va retourner
    UniqueUpdateForm(FrmGetFormId(self->pt_frm), frmRedrawUpdateCode);
  }
  // On vient de cliquer sur le bouton UP ou DOWN
  else
    DateAdjust(ps_date, uh_obj == uh_date_id - 1 ? /*DOWN*/ -1 : /*UP*/ 1);

  // On change la date
  [self dateSet:uh_date_id date:*ps_date format:e_format];

  // Si un autre champ de date est lié à celui-ci, on le fait bouger aussi
  uh_bound_date_id = [self dateIsBound:uh_date_id date:&ps_bound_date];
  if (uh_bound_date_id != 0)
  {
    DateAdjust(ps_bound_date,
	       (Int32)DateToDays(*ps_date) - (Int32)DateToDays(s_old_date));

    [self dateSet:uh_bound_date_id date:*ps_bound_date format:e_format];
  }

  return true;
}


//
// uh_date_id est l'ID du SELECTORTRIGGER contenant la date.
// s_date contient la date à positionner
- (void)dateSet:(UInt16)uh_date_id date:(DateType)s_date
	 format:(DateFormatType)e_format
{
  Char ra_date[longDateStrLength];

  DateToAscii(s_date.month, s_date.day, s_date.year + firstYear,
              e_format, ra_date);

  [self fillLabel:uh_date_id withSTR:ra_date];
}


- (UInt16)dateIsBound:(UInt16)uh_date_id date:(DateType**)pps_date
{
  return 0;
}


- (Boolean)timeSelect:(UInt16)uh_title time:(TimeType*)ps_time
	      dialog3:(Boolean)b_dialog3
{
  Char ra_title[32];
  Boolean b_ret = false;

  SysCopyStringResource(ra_title, uh_title);

  /* Version du système >= 3.1 */
  if (oApplication->ul_rom_version >= 0x03103000 && b_dialog3)
  {
    Int16 uh_hours, uh_minutes;

    uh_hours = ps_time->hours;
    uh_minutes = ps_time->minutes;

    if (SelectOneTime(&uh_hours, &uh_minutes, ra_title))
    {
      ps_time->hours = uh_hours;
      ps_time->minutes = uh_minutes;

      b_ret = true;
    }
  }
  /* Autres systèmes (< 3.1) */
  else
  {
    TimeType s_begin, s_end;

    s_begin = s_end = *ps_time;

    if (SelectTimeV33(&s_begin, &s_end, false, ra_title, 8))
    {
      /* Sans heure, on met à minuit... */
      if (TimeToInt(s_begin) == noTime)
      {
	ps_time->hours = 0;
	ps_time->minutes = 0;
      }
      else
	*ps_time = s_begin;

      b_ret = true;
    }
  }

  return b_ret;
}


//
// uh_time_id est l'ID du SELECTORTRIGGER contenant l'heure.
// s_time contient la date à positionner
- (void)timeSet:(UInt16)uh_time_id time:(TimeType)s_time
	 format:(TimeFormatType)e_format
{
  Char ra_time[timeStringLength];

  TimeToAscii(s_time.hours, s_time.minutes, e_format, ra_time);

  [self fillLabel:uh_time_id withSTR:ra_time];
}


- (Boolean)keyFilter:(UInt32)ui_fld_idx for:(struct _KeyDownEventType*)ps_key
{
  // Special key
  if (ps_key->modifiers & virtualKeyMask)
    return false;

  // This field has to contain only numeric contents
  if (ui_fld_idx & (KEY_FILTER_INT | KEY_FILTER_FLOAT | KEY_FILTER_DOUBLE))
  {
    UInt16 key = ps_key->chr;

    // Not a control char
    if (key >= ' ')
    {
      // (ui_fld_idx & KEY_FILTER_IDX) inutile puisque passage sur 16 bits
      FieldType *pt_field = FrmGetObjectPtr(self->pt_frm, ui_fld_idx);
      Char *pa_content = FldGetTextPtr(pt_field);

      // A digit
      if (key >= '0' && key <= '9')
      {
	if (pa_content != NULL)
	{
	  UInt16 index, uh_len, uh_char_len, uh_start, uh_end;
	  UInt16 uh_period_pos, uh_num_digits_int, uh_num_digits_dec;
	  WChar wa_chr;
	  Boolean b_dec_part;

	  // S'il y a une sélection active, on commence par la virer...
	  FldGetSelection(pt_field, &uh_start, &uh_end);
	  if (uh_start != uh_end)
	    FldDelete(pt_field, uh_start, uh_end);

	  uh_len = FldGetTextLength(pt_field);

	  uh_num_digits_int = 0;
	  uh_num_digits_dec = 0;
	  b_dec_part = false;
	  uh_period_pos = 0xffff;

	  for (index = 0; index < uh_len; index += uh_char_len)
	  {
	    uh_char_len = TxtGlueGetNextChar(pa_content, index, &wa_chr);

	    switch (wa_chr)
	    {
	    case '0' ... '9':
	      if (b_dec_part)
		uh_num_digits_dec++;
	      else
		uh_num_digits_int++;
	      break;
	    case '.': case ',':
	      uh_period_pos = index;
	      b_dec_part = true;
	      break;
	    }
	  }

	  // For an integer we allow 9 digits (no decimal part)
	  if (ui_fld_idx & KEY_FILTER_INT)
	  {
	    if (uh_num_digits_int >= 9)
	      return true;
	  }
	  else
	  {
	    index = FldGetInsPtPosition(pt_field);

	    // For an float (in a integer) we allow 7 integer digits
	    // and 2 decimal ones
	    if (ui_fld_idx & KEY_FILTER_FLOAT)
	    {
	      if (index > uh_period_pos
		  ? (uh_num_digits_dec >= 2)  // We are in decimal part
		  : (uh_num_digits_int >= 7)) // We are in integral part
		return true;
	    }
	    // For a double we allow 9 digits (integer or decimal ones)
	    else		// KEY_FILTER_DOUBLE
	    {
	      if (index > uh_period_pos
		  ? (uh_num_digits_dec >= 9)  // We are in decimal part
		  : (uh_num_digits_int >= 9)) // We are in integral part
		return true;
	    }
	  }
	}
      }
      // The key is not a control char AND not a digit
      else
      {
	if (key == '-' || key == '+')
	{
	  // '-' accepted but only in first position
	  if (ui_fld_idx & KEY_FILTER_NEG)
	  {
	    // Pas de '+' dans ce cas...
	    if (key == '+')
	      return true;

	    // Curseur en première position ET pas de '-' en tête : on accepte
	    if (FldGetInsPtPosition(pt_field) == 0
		&& (pa_content == NULL || *pa_content != '-'))
	      return false; // On laisse le système accepter le caractère
	  }
	  // '-' or '+' set the SELECTORTRIGGER with ID just before field one
	  else if (ui_fld_idx & KEY_SELTRIGGER_SIGN)
	  {
	    Char ra_sign[] = { key, '\0' };

	    // (ui_fld_idx & KEY_FILTER_IDX) inutile puisque passage sur 16 bits
	    [self fillLabel:FrmGetObjectId(self->pt_frm, ui_fld_idx) - 1
		  withSTR:ra_sign];
	  
	    return true;
	  }
	}
	// The space char select the whole field
	else if (key == ' ')
	{
	  FldSetSelection(pt_field, 0, FldGetTextLength(pt_field));
	  return true;
	}

	// Only digit are allowed
	if (ui_fld_idx & KEY_FILTER_INT)
	  return true;

	// Comma and period allowed (KEY_FILTER_FLOAT flag)
	if (key != ',' && key != '.')
	  return true;

	// OK, comma/period allowed but only once (out of the selection)
	if (pa_content != NULL)
	{
	  UInt16 index, uh_chr_index, uh_len, uh_start, uh_end;
	  WChar wa_chr;

	  FldGetSelection(pt_field, &uh_start, &uh_end);
	  uh_len = FldGetTextLength(pt_field);
	
	  for (index = 0, uh_chr_index = 0; index < uh_len; uh_chr_index++)
	  {
	    index += TxtGlueGetNextChar(pa_content, index, &wa_chr);

	    // Out of the selection (that will be replaced by this char)
	    if (uh_chr_index < uh_start || uh_chr_index >= uh_end)
	    {
	      // Comma OR period found => no place for a new one!
	      if (wa_chr == '.' || wa_chr == ',')
		return true;
	    }
	  }

	  // Si une sélection est active on la supprime nous même, car
	  // si elle contient un séparateur décimal (et que le champ est
	  // NUMERIC) l'OS refusera le nouveau séparateur... ce con...
	  if (uh_start != uh_end)
	    FldDelete(pt_field, uh_start, uh_end);
	}

	// Si le séparateur est '.' et qu'on vient de filtrer ',' on intervertit
	// Si le séparateur est ',' et qu'on vient de filtrer '.' on intervertit
	if (float_dec_separator() != key)
	{
	  // XXX Faut-il flusher la queue des événements clavier avant ?
	  //EvtFlushKeyQueue();

	  // On balance un nouvel événement
	  // , == 0x2e
	  // . == 0x2c
	  EvtEnqueueKey(key ^ 0x02, 0, 0);

	  // On ne passe pas ce caractère à l'OS
	  return true;
	}
      }
    }
  }

  /* On laisse le système faire : car chiffres ou caractères avant espace */
  return false;
}


// FrmReturnToForm don't post frmClose event, -returnToLastForm call -close
- (void)returnToLastForm
{
  [self close];

  FrmReturnToForm(0);
}


- (void*)objectPtrId:(UInt16)uh_obj_id
{
  return FrmGetObjectPtr(self->pt_frm,
			 FrmGetObjectIndex(self->pt_frm, uh_obj_id));
}


- (void)hideId:(UInt16)uh_obj_id
{
  [self hideIndex:FrmGetObjectIndex(self->pt_frm, uh_obj_id)];
}


- (void)showId:(UInt16)uh_obj_id
{
  [self showIndex:FrmGetObjectIndex(self->pt_frm, uh_obj_id)];
}


// Cache d'abord les objets à cacher et montre ensuite ceux à montrer...
- (void)showHideIds:(UInt16*)puh_obj_ids
{
  UInt16 *puh_show_ids, *puh_hide_ids;
  UInt16 uh_obj_id;

  puh_hide_ids = puh_obj_ids;
  puh_show_ids = NULL;

  // On cache d'abord
  while ((uh_obj_id = *puh_hide_ids) != 0)
  {
    if (uh_obj_id & 1)
    {
      if (puh_show_ids == NULL)
	puh_show_ids = puh_hide_ids;
    }
    else
      [self hideId:uh_obj_id >> 1];

    puh_hide_ids++;
  }

  // On montre ensuite
  if (puh_show_ids != NULL)
    while ((uh_obj_id = *puh_show_ids++) != 0)
      if (uh_obj_id & 1)
	[self showId:uh_obj_id >> 1];
}


- (void)hideIndex:(UInt16)uh_index
{
  UInt32 ul_rom_version = oApplication->ul_rom_version;

  FrmHideObject(self->pt_frm, uh_index);

  if (ul_rom_version < 0x03500000)
  {
    FormObjectKind e_obj = FrmGetObjectType(self->pt_frm, uh_index);

    // Prior to OS version 3.2, FrmHideObject did not set the usable bit
    // of the object attribute data to false.
    if (ul_rom_version < 0x03203000)
    {
      // We only do it for bitmap and scrollbar, that are persistent
      // else...
      switch (e_obj)
      {
      case frmBitmapObj:
	((FormBitmapType*)
	 FrmGetObjectPtr(self->pt_frm, uh_index))->attr.usable = 0;
	goto done;

      case frmScrollBarObj:
      {
	UInt16 i;

	for (i = 0; ; i++)
	  if (self->ps_scrollbars[i].uh_index == 0)
	  {
	    ScrollBarType *pt_scrollbar = FrmGetObjectPtr(self->pt_frm,
							  uh_index);
	    UInt16 uh_min, uh_page;
	    SclGetScrollBar(pt_scrollbar, &self->ps_scrollbars[i].uh_cur_val,
			    &uh_min, &self->ps_scrollbars[i].uh_max_val,
			    &uh_page);
	    SclSetScrollBar(pt_scrollbar, uh_min, uh_min, uh_min, uh_page);
	    self->ps_scrollbars[i].uh_index = uh_index;
	    break;
	  }
	goto done;
      }

      default:
	break;
      }
    }

    // On versions of Palm OS prior to 3.5 this function doesn't affect lists
    if (e_obj == frmListObj)
      ((ListType*)FrmGetObjectPtr(self->pt_frm, uh_index))->attr.usable = 0;

done:
    ;
  }
}


- (void)showIndex:(UInt16)uh_index
{
  // S'il y a des scrollbars enregistrées, c'est qu'on a une ROM < 3.2
  if (self->ps_scrollbars)
  {
    if (FrmGetObjectType(self->pt_frm, uh_index) == frmScrollBarObj)
    {
      UInt16 i;

      for (i = 0; ; i++)
	if (self->ps_scrollbars[i].uh_index == uh_index)
	{
	  ScrollBarType *pt_scrollbar = FrmGetObjectPtr(self->pt_frm,uh_index);
	  UInt16 uh_dummy, uh_min, uh_page;

	  SclGetScrollBar(pt_scrollbar,
			  &uh_dummy, &uh_min, &uh_dummy, &uh_page);
	  SclSetScrollBar(pt_scrollbar, self->ps_scrollbars[i].uh_cur_val,
			  uh_min, self->ps_scrollbars[i].uh_max_val, uh_page);
	  self->ps_scrollbars[i].uh_index = 0;
	  break;
	}
    }
  }

  FrmShowObject(self->pt_frm, uh_index);

  if (oApplication->ul_rom_version < 0x03500000
      && FrmGetObjectType(self->pt_frm, uh_index) == frmListObj)
    ((ListType*)
     FrmGetObjectPtr(self->pt_frm, uh_index))->attr.usable = 1;
}


//
// Renvoie l'index de l'objet qui a le focus ou noFocus si aucun ne l'a
- (UInt16)focusGetObject
{
  return FrmGetFocus(self->pt_frm);
}


//
// Vérifie que l'objet est bien un champ avec toutes les
// caractéristiques nécessaires pour accueillir le focus et lui
// donne. Renvoie alors true.
// Renvoie false si l'objet n'offre pas les garanties nécessires à
// l'accueil du focus.
- (Boolean)focusObjectIndex:(UInt)uh_index
{
  // Si on est sur un champ éditable
  if (FrmGetObjectType(self->pt_frm, uh_index) == frmFieldObj)
  {
    FieldType *pt_field = FrmGetObjectPtr(self->pt_frm, uh_index);
    FieldAttrType s_attr;

    FldGetAttributes(pt_field, &s_attr);

    // Le champ est apte à recevoir le focus...
    if (s_attr.usable && s_attr.visible && s_attr.editable)
    {
      if (oApplication->uh_palmnav_available)
      {
	uh_index = FrmGetObjectId(self->pt_frm, uh_index);

	// T5/Treo650 navigator API
	if (oApplication->uh_palmnav_available == PALM_NAV_FRM)
	  FrmNavObjectTakeFocus(self->pt_frm, uh_index);
	// Treo600 navigator API
	else			// == PALM_NAV_HS
	  HsNavObjectTakeFocus(self->pt_frm, uh_index);
      }
      else
	FrmSetFocus(self->pt_frm, uh_index);
      return true;
    }
  }

  return false;
}


- (Boolean)focusObject:(UInt)uh_id
{
  return [self focusObjectIndex:FrmGetObjectIndex(self->pt_frm, uh_id)];
}


- (Boolean)focusNextObject
{
  Int16 h_fld_idx = [self focusGetObject];
  Int16 h_num_obj = FrmGetNumberOfObjects(self->pt_frm);
  Int16 h_index;

  if (h_fld_idx == noFocus)
  {
    h_index = h_fld_idx = 0;
    goto direct;
  }

  for (h_index = h_fld_idx;;)
  {
    // On est arrivé à la fin, on boucle...
    if (++h_index >= h_num_obj)
      h_index = 0;

    if (h_index == h_fld_idx)
      break;

direct:
    // Si on accepte le focus
    if ([self focusObjectIndex:h_index])
      return true;
  }

  return false;
}


- (Boolean)focusPrevObject
{
  Int16 h_fld_idx = [self focusGetObject];
  Int16 h_num_obj = FrmGetNumberOfObjects(self->pt_frm);
  Int16 h_index;

  if (h_fld_idx == noFocus)
  {
    h_index = h_fld_idx = h_num_obj - 1;
    goto direct;
  }

  for (h_index = h_fld_idx;;)
  {
    // On est arrivé au début, on boucle...
    if (--h_index < 0)
      h_index = h_num_obj - 1;

    if (h_index == h_fld_idx)
      break;

direct:
    // Si on accepte le focus
    if ([self focusObjectIndex:h_index])
      return true;
  }

  return false;
}


//
// Cette méthode peut être utilisée par un formulaire pour récupérer
// des infos du formulaire l'appelant de manière générique (cette
// méthode est présente dans tous les formulaire) : voir
// TypeListForm.m
- (UInt32)getInfos
{
  return self->ui_infos;
}


- (void)fillLabel:(UInt16)uh_obj withSTR:(Char*)pa_label
{
  ControlType *pt_label;
  UInt16 index = FrmGetObjectIndex(self->pt_frm, uh_obj);
  Boolean b_visible;

  // On regarde si le label est actuellement visible ou non...
  b_visible = (self->uh_form_drawn && FrmGlueGetObjectUsable(self->pt_frm,
							     index));
  if (b_visible)
    [self hideIndex:index];

  pt_label = FrmGetObjectPtr(self->pt_frm, index);

  if (FrmGetObjectType(self->pt_frm, index) == frmLabelObj)
    FrmCopyLabel(self->pt_frm, uh_obj, pa_label);
  else
    CtlSetLabel(pt_label, StrCopy((Char*)CtlGetLabel(pt_label), pa_label));

  if (b_visible)
    [self showIndex:index];
}


////////////////////////////////////////////////////////////////////////
//
// Gestion des champs scrollables
//
// L'ID de la barre de scroll est toujours égal à celui du champ + 1
//
////////////////////////////////////////////////////////////////////////

- (void)fieldScrollBar:(UInt16)uh_scrollbar
	 linesToScroll:(Int16)h_lines_to_scroll
		update:(Boolean)b_update
{
  FieldType *pt_field;
  UInt16 uh_blank_lines;

  pt_field = [self objectPtrId:uh_scrollbar - 1];
  uh_blank_lines = FldGetNumberOfBlankLines(pt_field);

  if (h_lines_to_scroll < 0)
    FldScrollField(pt_field, - h_lines_to_scroll, winUp);
  else if (h_lines_to_scroll > 0)
    FldScrollField(pt_field, h_lines_to_scroll, winDown);

  // If there were blank lines visible at the end of the field
  // then we need to update the scroll bar.
  if (uh_blank_lines || b_update)
    [self fieldUpdateScrollBar:uh_scrollbar fieldPtr:pt_field setScroll:false];
}


- (void)fieldUpdateScrollBar:(UInt16)uh_scrollbar
		    fieldPtr:(FieldType*)pt_field
		   setScroll:(Boolean)b_set_scroll
{
  UInt16 uh_scroll_pos;
  UInt16 uh_text_height;
  UInt16 uh_field_height;
  Int16 h_max_value;

  if (b_set_scroll)
  {
    FieldAttrType s_attr;

    FldGetAttributes(pt_field, &s_attr);
    s_attr.hasScrollBar = true;
    FldSetAttributes(pt_field, &s_attr);

    FldSetScrollPosition(pt_field, 0);
  }

  FldGetScrollValues(pt_field,
		     &uh_scroll_pos, &uh_text_height,  &uh_field_height);

  if (uh_text_height > uh_field_height)
    h_max_value = (uh_text_height - uh_field_height)
      + FldGetNumberOfBlankLines(pt_field);
  else if (uh_scroll_pos)
    h_max_value = uh_scroll_pos;
  else
    h_max_value = 0;

  SclSetScrollBar([self objectPtrId:uh_scrollbar],
		  uh_scroll_pos, 0, h_max_value, uh_field_height - 1);
}


- (void)swapLeft:(UInt16)uh_left_obj rightOnes:(UInt16)uh_right_one, ...
{
  RectangleType s_left, s_right, s_tmp;
  va_list ap;

  va_start(ap, uh_right_one);

  uh_left_obj = FrmGetObjectIndex(self->pt_frm, uh_left_obj);
  FrmGetObjectBounds(self->pt_frm, uh_left_obj, &s_left);
  FrmGetObjectBounds(self->pt_frm,
		     FrmGetObjectIndex(self->pt_frm, uh_right_one),&s_right);

  s_tmp = s_left;
  s_tmp.topLeft.x += s_right.extent.x
    + (s_right.topLeft.x - s_left.topLeft.x) - s_left.extent.x;

  FrmSetObjectBounds(self->pt_frm, uh_left_obj, &s_tmp);

  do
  {
    uh_right_one = FrmGetObjectIndex(self->pt_frm, uh_right_one);
    FrmGetObjectBounds(self->pt_frm, uh_right_one, &s_right);

    s_right.topLeft.x = s_left.topLeft.x;

    FrmSetObjectBounds(self->pt_frm, uh_right_one, &s_right);
  }
  while ((uh_right_one = va_arg(ap, UInt16)) != 0);

  va_end(ap);
}


////////////////////////////////////////////////////////////////////////
//
// Menu contextuel...
//
////////////////////////////////////////////////////////////////////////

- (Int16)contextPopupList:(UInt16)uh_list x:(Int16)h_x y:(Int16)h_y
		 selEntry:(UInt16)uh_sel
{
  ListType *pt_list;
  RectangleType s_bounds;
  UInt16 uh_height, uh_width;

  uh_list = FrmGetObjectIndex(self->pt_frm, uh_list);
  pt_list = FrmGetObjectPtr(self->pt_frm, uh_list);

  FrmGetObjectBounds(self->pt_frm, uh_list, &s_bounds);

  WinGetDisplayExtent(&uh_width, &uh_height);

  if (h_x < 0)
    h_x = uh_width / 2;

  if (h_y < 0)
    h_y = uh_height / 2;

  s_bounds.topLeft.x = h_x - (s_bounds.extent.x >> 1);
  s_bounds.topLeft.y = h_y;

  if (s_bounds.topLeft.x + s_bounds.extent.x > uh_width)
    s_bounds.topLeft.x = uh_width - s_bounds.extent.x;

  if (s_bounds.topLeft.y + s_bounds.extent.y > uh_height)
    s_bounds.topLeft.y = uh_height - s_bounds.extent.y;

  FrmSetObjectBounds(self->pt_frm, uh_list, &s_bounds);

  // On ne sélectionne aucune entrée par défaut
  LstSetSelection(pt_list, uh_sel);

  return LstPopupList(pt_list);
}


////////////////////////////////////////////////////////////////////////
//
// Gestion des onglets
//
////////////////////////////////////////////////////////////////////////

- (Boolean)clicOnTab:(UInt16)uh_tab
{
  // Déjà sur l'onglet courant
  if (TAB_ID_TO_NUM(uh_tab) == self->uh_tabs_current)
    return true;

  [self tabsHide:0];		// Cache l'onglet courant...
  [self tabsDraw:uh_tab drawLines:false];
  [self tabsShow:uh_tab];

  return true;
}

- (void)tabsDraw:(UInt16)uh_cur_tab drawLines:(Boolean)b_lines
{
  UInt16 uh_base_y, uh_top_y;
  RectangleType s_cur_bounds, s_frm_bounds;

  Boolean b_colored = false;
  IndexedColorType e_old_color = 0;

  // Coordonnées du formulaire
  FrmGetFormBounds(self->pt_frm, &s_frm_bounds);

  // Coordonnées de l'onglet courant
  FrmGetObjectBounds(self->pt_frm, FrmGetObjectIndex(self->pt_frm, uh_cur_tab),
		     &s_cur_bounds);
  uh_base_y = s_cur_bounds.topLeft.y + s_cur_bounds.extent.y;
  uh_top_y = s_cur_bounds.topLeft.y - 1;

  // On efface la ligne de base
  WinEraseLine(0, uh_base_y, s_frm_bounds.extent.x - 1, uh_base_y);

  // Avec quelle couleur doit-on dessiner les lignes ?
  if (oApplication->uh_color_enabled)
  {
    // Pas la même couleur si le formulaire est modal ou non...
    e_old_color = WinSetForeColor
      (UIColorGetTableEntryIndex(WinModal(FrmGetWindowHandle(self->pt_frm))
				 ? UIDialogFrame : UIFormFrame));
    b_colored = true;
  }

  if (b_lines)
  {
    RectangleType s_bounds, s_old_clip, s_new_clip;
    UInt16 uh_num;

    WinGetClip(&s_old_clip);

    // On dessine chaque bouton
    for (uh_num = 1; uh_num <= self->uh_tabs_num; uh_num++)
    {
      FrmGetObjectBounds(self->pt_frm,
			 FrmGetObjectIndex(self->pt_frm,
					   TAB_NUM_TO_ID(uh_num)),
			 &s_bounds);

      // Clippe la zone de dessin aux contours du bouton
      s_bounds.topLeft.x--;
      s_bounds.topLeft.y--;
      s_bounds.extent.x += 2;
      s_bounds.extent.y++;

      // Au cas où on serait déjà clippé
      RctGetIntersection(&s_old_clip, &s_bounds, &s_new_clip);
      WinSetClip(&s_new_clip);

      // Dessine un rectangle aux coins arrondis
      s_bounds.topLeft.x++;
      s_bounds.topLeft.y++;
      s_bounds.extent.x -= 2;
      s_bounds.extent.y += 10; // Pour que les coins du bas soient hors du clip
      WinDrawRectangleFrame(roundFrame, &s_bounds);
    }

    WinSetClip(&s_old_clip);
  }

  // Ligne de base à gauche
  WinDrawLine(0, uh_base_y, s_cur_bounds.topLeft.x - 1, uh_base_y);

  // Ligne de base à droite
  WinDrawLine(s_cur_bounds.topLeft.x + s_cur_bounds.extent.x, uh_base_y,
	      s_frm_bounds.extent.x - 1, uh_base_y);

  // On fait une ligne au dessus du bouton Save
  if (b_lines && self->uh_tabs_space > 0)
  {
    FrmGetObjectBounds(self->pt_frm,
		       FrmGetObjectIndex(self->pt_frm, TAB_ID_AFTER_LINE),
		       &s_cur_bounds);

    uh_base_y = s_cur_bounds.topLeft.y - 2 - self->uh_tabs_space;

    WinDrawLine(0, uh_base_y, s_frm_bounds.extent.x - 1, uh_base_y);
  }

  if (b_colored)
    WinSetForeColor(e_old_color);
}


- (void)tabsHide:(UInt16)uh_cur_tab
{
  UInt16 uh_id, uh_num_obj;
  Int16 h_index;

  uh_num_obj = FrmGetNumberOfObjects(self->pt_frm);

  // On cache l'onglet courant
  if (uh_cur_tab == 0)
  {
    uh_cur_tab = TAB_NUM_TO_ID(self->uh_tabs_current);

    for (h_index = uh_num_obj; --h_index >= 0; )
    {
      uh_id = FrmGetObjectId(self->pt_frm, h_index);

      if ((uh_id & (TAB_ID_FIRST_TAB - 1)) != 0 /* Not a tab */
	  && uh_id > uh_cur_tab && uh_id < uh_cur_tab + TAB_ID_FIRST_TAB)
      {

	// On a un gadget AVEC une donnée spéciale qui veut dire que
	// l'objet précédent est un bitmap situé dans le même onglet
	if (FrmGetObjectType(self->pt_frm, h_index) == frmGadgetObj
	    && FrmGetGadgetData(self->pt_frm, h_index) == TAB_GADGET_MAGIC)
	  h_index--;

	[self hideIndex:h_index];
      }
    }
  }
  // On cache tout sauf l'onglet passé en paramètre, les objets hors
  // onglet et les AUTOID
  else
  {
    for (h_index = uh_num_obj; --h_index >= 0; )
    {
      uh_id = FrmGetObjectId(self->pt_frm, h_index);

      if (uh_id < AUTOID_BASE	// Not an AUTOID object
	  && (uh_id & (TAB_ID_FIRST_TAB - 1)) != 0 /* Not a tab */
	  && (uh_id < uh_cur_tab || uh_id > uh_cur_tab + TAB_ID_FIRST_TAB)
	  && uh_id > TAB_ID_FIRST_TAB) /* Not Save and Cancel buttons... */
      {
	// On a un gadget AVEC une donnée spéciale qui veut dire que
	// l'objet précédent est un bitmap situé dans le même onglet
	if (FrmGetObjectType(self->pt_frm, h_index) == frmGadgetObj
	    && FrmGetGadgetData(self->pt_frm, h_index) == TAB_GADGET_MAGIC)
	  h_index--;

	[self hideIndex:h_index];
      }
    }
  }
}


- (void)tabsShow:(UInt16)uh_cur_tab
{
  UInt16 uh_id;
  Int16 h_index;

  // Onglet courant...
  self->uh_tabs_current = TAB_ID_TO_NUM(uh_cur_tab);

  // On rend tout visible
  for (h_index = FrmGetNumberOfObjects(self->pt_frm); --h_index >= 0; )
  {
    uh_id = FrmGetObjectId(self->pt_frm, h_index);

    if ((uh_id & (TAB_ID_FIRST_TAB - 1)) != 0 /* Not a tab */
	&& uh_id > uh_cur_tab && uh_id < uh_cur_tab + TAB_ID_FIRST_TAB)
    {
      switch (FrmGetObjectType(self->pt_frm, h_index))
      {
	// On a un gadget AVEC une donnée spéciale qui veut dire que
	// l'objet précédent est un bitmap situé dans le même onglet
      case frmGadgetObj:
	if (FrmGetGadgetData(self->pt_frm, h_index) == TAB_GADGET_MAGIC)
	  h_index--;
	break;

	// Si une liste est précédée par un frmControlObj de type
	// popupTriggerCtl ou selectorTriggerCtl, on l'ignore car il
	// s'agit d'une liste déroulante qui est toujours cachée sauf
	// quand on la déplie
      case frmListObj:
	if (h_index > 0
	    // Il faut tester si l'objet précédent est un
	    // popupTriggerCtl ou un selectorTriggerCtl
	    && FrmGetObjectType(self->pt_frm, h_index - 1) == frmControlObj)
	{
	  switch (CtlGlueGetControlStyle(FrmGetObjectPtr(self->pt_frm,
							 h_index - 1)))
	  {
	  case popupTriggerCtl:
	  case selectorTriggerCtl:
	    continue;
	  default:
	    break;
	  }
	}
	break;

      default:
	break;
      }

      [self showIndex:h_index];
    }
  }
}


// Renvoie 0 si l'objet n'appartient à aucun onglet, l'ID de l'onglet
// sinon
- (UInt16)tabsGetTabForId:(UInt16)uh_obj
{
  if (self->uh_tabs_num > 0 && uh_obj > TAB_ID_FIRST_TAB)
    return TAB_NUM_TO_ID(TAB_ID_TO_NUM(uh_obj));

  return 0;
}

@end
