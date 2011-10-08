/* 
 * Mode.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Fri Aug 22 18:16:20 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Mar 24 11:18:00 2006
 * Update Count    : 4
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: Mode.m,v $
 * Revision 1.5  2006/04/25 08:46:15  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.4  2005/10/06 19:48:14  max
 * match() now have a b_exact argument.
 *
 * Revision 1.3  2005/03/20 22:28:22  max
 * Add method to select first "auto-cheque" mode
 * Delete unused -getFirstModeId method
 *
 * Revision 1.2  2005/02/19 17:10:48  max
 * -fullNameOfId:len: returns NULL when mode don't exists.
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_MODE
#include "Mode.h"

#include "BaseForm.h"		// list_line_draw_line

#include "MaTirelire.h"

#include "ids.h"
#include "misc.h"
#include "graph_defs.h"
#include "objRsc.h"		// XXX


#define MODE_NUM_CACHE_ENTRIES	(NUM_MODES - 1)

@implementation Mode

- (Mode*)init
{
  if ([self cacheAlloc:MODE_NUM_CACHE_ENTRIES] == false)
  {
    // XXX
    return nil;
  }

  // DB opening/creating
  if ([self initDBType:MaTiModesType nameSTR:MaTiModesName] == nil)
  {
    // XXX
    return nil;
  }

  // Init the cache...
  [self cacheInit];

  return self;
}


////////////////////////////////////////////////////////////////////////
//
// Loading modes
//
////////////////////////////////////////////////////////////////////////

//
// Return NULL if the mode does not exist
// Returned pointer must be freed with a call to -getFree:
- (void*)getId:(UInt16)uh_id
{
  struct s_mode *ps_mode;

  // Mode spécial de la classe mère
  if (ITEM_IS_DIRECT(uh_id))
    return [super getId:uh_id];

  // "Unknown" mode : fake record
  if (uh_id >= MODE_UNKNOWN)
  {
    NEW_PTR(ps_mode, sizeof(struct s_mode) + MODE_NAME_MAX_LEN, return NULL);

    MemSet(ps_mode, sizeof(struct s_mode) + MODE_NAME_MAX_LEN, '\0');

    ps_mode->ui_id = MODE_UNKNOWN;

    SysCopyStringResource(ps_mode->ra_name, strModesListUnknown);

    // Pour être propre
    MemPtrResize(ps_mode,
		 sizeof(struct s_mode) + StrLen(ps_mode->ra_name) + 1);
  }
  else
    ps_mode = [super getId:uh_id];

  return ps_mode;
}


////////////////////////////////////////////////////////////////////////
//
// Saving modes
//
////////////////////////////////////////////////////////////////////////

- (UInt16)getIdFrom:(void*)pv_mode
{
  return ((struct s_mode*)pv_mode)->ui_id;
}


- (void)setId:(UInt16)uh_new_id in:(void*)pv_mode
{
  ((struct s_mode*)pv_mode)->ui_id = uh_new_id;
}


////////////////////////////////////////////////////////////////////////
//
// Deleting modes : DBItemId do that for us
//
////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////
//
// Popup management
//
////////////////////////////////////////////////////////////////////////

#define CHEQUE_AUTO_PREFIX	"* "

static UInt16 __fill_mode_macro(struct s_mode *ps_mode,
				Char *pa_macro, Boolean b_account)
{
  UInt16 uh_len = 0;

  // Target account ONLY in edition list
  if (b_account && ps_mode->ra_only_in_account[0] != '\0')
  {
    uh_len = StrLen(ps_mode->ra_only_in_account);

    MemMove(pa_macro, ps_mode->ra_only_in_account, uh_len);
    pa_macro += uh_len;

    if (ps_mode->ui_value_date != MODE_VAL_DATE_NONE)
    {
      *pa_macro++ = ';';
      uh_len++;
    }
  }

  // Value date
  switch (ps_mode->ui_value_date)
  {
  case MODE_VAL_DATE_CUR_MONTH:  // XX=YY
  case MODE_VAL_DATE_NEXT_MONTH: // XX-YY
    uh_len += StrPrintF(pa_macro, "%u%c%u",
			(UInt16)ps_mode->ui_first_val,
			(WChar)(ps_mode->ui_value_date==MODE_VAL_DATE_CUR_MONTH
				? '=' : '-'),
			(UInt16)ps_mode->ui_debit_date);
    break;

  case MODE_VAL_DATE_PLUS_DAYS:  // +ZZ
  case MODE_VAL_DATE_MINUS_DAYS: // -ZZ
    uh_len += StrPrintF(pa_macro, "%c%u",
			(WChar)(ps_mode->ui_value_date==MODE_VAL_DATE_PLUS_DAYS
				? '+' : '-'),
			(UInt16)ps_mode->ui_first_val);
    break;

  default:
    *pa_macro++ = '\0';		// Pour la forme...
    break;
  }

  return uh_len;
}


//
// Si (*puh_num & ITEM_ADD_ANY_LINE) => on ajoute une première entrée
// "Indifférent"
// Si (*puh_num & ITEM_ADD_EDIT_LINE) OU BIEN si (pa_account != NULL)
//	=> on ajoute une dernière entrée "Éditer..."
- (Char**)listBuildInfos:(void*)pv_infos
		     num:(UInt16*)puh_num
		 largest:(UInt16*)puh_largest
{
  Char *pa_account = pv_infos;
  struct __s_list_mode_buf *ps_buf;
  UInt16 uh_index, uh_num, uh_num_records;
  UInt16 uh_width, uh_largest, uh_len, *puh_list2index;

  VoidHand vh_mode;
  struct s_mode *ps_mode;

  uh_num_records = DmNumRecords(self->db);

  NEW_PTR(ps_buf, sizeof(*ps_buf) + uh_num_records * sizeof(UInt16),
	  return NULL);

  uh_largest = 0;
  uh_num = 0;
  puh_list2index = ps_buf->ruh_list2index;

  // Calcul de la plus grande largeur + cache entrées liste / index
  for (uh_index = 0; uh_index < uh_num_records; uh_index++)
  {
    vh_mode = DmQueryRecord(self->db, uh_index);
    if (vh_mode != NULL)
    {
      ps_mode = MemHandleLock(vh_mode);

      // This mode matches the account (if any)
      if (pa_account == NULL || match(ps_mode->ra_only_in_account,
				      pa_account, true))
      {
	// Mode name
	uh_width = FntCharsWidth(ps_mode->ra_name, StrLen(ps_mode->ra_name));

	// Cheque auto
	if (ps_mode->ui_cheque_auto)
	  uh_width += FntCharsWidth(CHEQUE_AUTO_PREFIX,
				    sizeof(CHEQUE_AUTO_PREFIX) - 1);

	// Macro string

	// Value date + Target account ONLY in edition list
	uh_len = __fill_mode_macro(ps_mode, ps_buf->ra_macro,
				   pa_account == NULL);
	if (uh_len > 0)
	   uh_width += MINIMAL_SPACE + FntCharsWidth(ps_buf->ra_macro, uh_len);

	if (uh_width > uh_largest)
	  uh_largest = uh_width;

	uh_num++;
	*puh_list2index++ = uh_index;
      }

      MemHandleUnlock(vh_mode);
    }
  }

  ps_buf->oItem = self;
  ps_buf->uh_num_rec_entries = uh_num;
  ps_buf->uh_is_right_margin = 0;
  ps_buf->uh_only_in_account_view = (pa_account == NULL);

  ps_buf->ra_first_entry[0] = '\0'; // Pas de 1ère entrée par défaut

  // Cas particulier : on ajoute une première entrée "Any"
  if (*puh_num & ITEM_ADD_ANY_LINE)
  {
    load_and_fit(strAnyList, ps_buf->ra_first_entry, &uh_largest);
    uh_num++;
  }

  // On ajoute toujours l'entrée "Unknown" si "Any" ou "Edit..." présent
  if (*puh_num & (ITEM_ADD_ANY_LINE | ITEM_ADD_EDIT_LINE))
  {
    load_and_fit(strModesListUnknown, ps_buf->ra_unknown_entry, &uh_largest);
    uh_num++;
  }

  // Cas particulier : on ajoute l'entrée "Edit..."
  if (*puh_num & ITEM_ADD_EDIT_LINE)
  {
    load_and_fit(strEditList, ps_buf->ra_edit_entry, &uh_largest);
    uh_num++;
  }
  else if (uh_num == 0)
  {
    MemPtrFree(ps_buf);
    ps_buf = NULL;
  }

  *puh_num = uh_num;

  if (puh_largest)
    *puh_largest = uh_largest;

  return (Char**)ps_buf;
}


static void __list_modes_draw(Int16 h_line, RectangleType *prec_bounds,
			      Char **ppa_lines)
{
  struct __s_list_mode_buf *ps_buf = (struct __s_list_mode_buf*)ppa_lines;

  VoidHand vh_mode = NULL;

  Boolean b_cheque_auto = false;
  Char *pa_mode, *pa_macro = "";
  UInt16 uh_macro_len = 0;

  UInt16 uh_macro_width = 0, uh_macro_real_width = 0;
  UInt16 uh_right_margin, uh_max_width;
  Int16 h_width, h_upperline = 0;


  // Ce popup a une entrée avant les modes
  if (ps_buf->ra_first_entry[0] != '\0')
  {
    // On doit justement afficher cette première ligne : "Any" entry
    if (h_line == 0)
    {
      pa_mode = ps_buf->ra_first_entry;
      h_upperline = -1;		// Un séparateur en dessous
      goto draw_it;
    }

    // Sinon on déc. l'index pour coller au tableau de correspondance idx->id
    h_line--;
  }

  // L'entrée sélectionnée est un mode
  if (h_line < ps_buf->uh_num_rec_entries)
  {
    struct s_mode *ps_mode;

    vh_mode = DmQueryRecord(ps_buf->oItem->db, ps_buf->ruh_list2index[h_line]);
    ps_mode = MemHandleLock(vh_mode);

    pa_mode = ps_mode->ra_name;

    b_cheque_auto = ps_mode->ui_cheque_auto;

    pa_macro = ps_buf->ra_macro;
    uh_macro_len = __fill_mode_macro(ps_mode, pa_macro,
				     ps_buf->uh_only_in_account_view);
  }
  // "Unknown" entry
  else if (h_line == ps_buf->uh_num_rec_entries)
    pa_mode = ps_buf->ra_unknown_entry;
  // "Edit..." entry
  else // if (h_line == ps_buf->uh_num_rec_entries + 1)
  {
    pa_mode = ps_buf->ra_edit_entry;
    h_upperline = 1;		// Un séparateur au dessus
  }

 draw_it:

  // Does this list contain scroll arrows?
  uh_right_margin = ps_buf->uh_is_right_margin
    ? LIST_RIGHT_MARGIN : LIST_RIGHT_MARGIN_NOSCROLL;

  // Room required by the macro
  if (uh_macro_len > 0)
  {
    // Place que la macro va prendre
    uh_macro_real_width = FntCharsWidth(pa_macro,uh_macro_len) + MINIMAL_SPACE;

    // Place maximum allouée pour la macro (moitié de la largeur hors marges)
    // La marge de gauche est déjà décomptée par l'OS
    uh_max_width = (prec_bounds->extent.x - uh_right_margin) / 2;

    uh_macro_width = (uh_macro_real_width > uh_max_width)
      ? uh_max_width : uh_macro_real_width;
  }


  {
    UInt16 uh_prefix_width = 0;
    UInt16 uh_x = prec_bounds->topLeft.x;
    UInt16 uh_mode_len;

    // Largeur maximale pour la description sans la macro
    uh_max_width = prec_bounds->extent.x - uh_macro_width - uh_right_margin;

    // Cheque auto prefix
    if (b_cheque_auto)
    {
      WinDrawChars(CHEQUE_AUTO_PREFIX, sizeof(CHEQUE_AUTO_PREFIX) - 1,
		   uh_x, prec_bounds->topLeft.y);
      uh_prefix_width
	= FntCharsWidth(CHEQUE_AUTO_PREFIX, sizeof(CHEQUE_AUTO_PREFIX) - 1);
      uh_x += uh_prefix_width;
    }

    uh_mode_len = StrLen(pa_mode);

    h_width = prepare_truncating(pa_mode, &uh_mode_len,
				 uh_max_width - uh_prefix_width);
    WinDrawTruncatedChars(pa_mode, uh_mode_len,
			  uh_x, prec_bounds->topLeft.y, h_width);
    if (h_width < 0)
      h_width = FntCharsWidth(pa_mode, uh_mode_len);

    // Place restante pour la macro
    uh_max_width = prec_bounds->extent.x - uh_right_margin
      - MINIMAL_SPACE - (h_width + uh_prefix_width);
  }

  // Macro
  if (uh_macro_len > 0)
  {
    UInt16 uh_x, uh_y;

    uh_macro_real_width -= MINIMAL_SPACE;

    h_width = -1;

    // The macro is too large
    if (uh_macro_real_width > uh_max_width)
    {
      h_width = prepare_truncating(pa_macro, &uh_macro_len, uh_max_width);
      uh_macro_real_width = h_width; // Normalement, ici jamais < 0
    }

    uh_x = prec_bounds->topLeft.x + prec_bounds->extent.x
      - uh_right_margin
      - uh_macro_real_width
      - 1;		       // Pour compenser le souligné trop long

    uh_y = prec_bounds->topLeft.y;

    WinDrawTruncatedChars(pa_macro, uh_macro_len, uh_x, uh_y, h_width);

    uh_y += FntBaseLine() + 1;

    WinDrawGrayLine(uh_x, uh_y, uh_x + uh_macro_real_width - 1, uh_y);
  }

  if (vh_mode != NULL)
    MemHandleUnlock(vh_mode);

  if (h_upperline)
    list_line_draw_line(prec_bounds, h_upperline);
}


- (ListDrawDataFuncPtr)listDrawFunction
{
  return __list_modes_draw;
}


- (UInt16)dbMaxEntries
{
  return NUM_MODES - 1;		// Skip "Unknown" mode
}


////////////////////////////////////////////////////////////////////////
//
// Mode popup list
//
////////////////////////////////////////////////////////////////////////

- (Int16)popupListGetAutoChequeMode:(VoidHand)pv_list
{
  struct __s_list_mode_buf *ps_buf;
  struct s_mode *ps_mode;
  UInt16 index;
  Int16 h_ret_mode = -1;

  ps_buf = (struct __s_list_mode_buf*)
    ((struct __s_dbitem_popup_list*)MemHandleLock(pv_list))->ps_buf;

  for (index =0; index < ps_buf->uh_num_rec_entries && h_ret_mode < 0; index++)
  {
    ps_mode = [self getId:ITEM_SET_DIRECT(ps_buf->ruh_list2index[index])];

    if (ps_mode->ui_cheque_auto)
      h_ret_mode = ps_mode->ui_id;

    [self getFree:ps_mode];
  }

  MemHandleUnlock(pv_list);

  return h_ret_mode;
}


- (UInt16)_popupListUnknownItem
{
  return MODE_UNKNOWN;
}


- (UInt16*)_popupListGetList2IndexFrom:(struct __s_list_dbitem_buf*)ps_buf
{
  return ((struct __s_list_mode_buf*)ps_buf)->ruh_list2index;
}


- (Char*)fullNameOfId:(UInt16)uh_id len:(UInt16*)puh_len
{
  struct s_mode *ps_mode;
  Char *pa_name;
  UInt16 uh_len = 1;		// Avec \0

  ps_mode = [self getId:uh_id];
  if (ps_mode == NULL)
  {
    pa_name = NULL;
    goto end;
  }

  uh_len += StrLen(ps_mode->ra_name);

  NEW_PTR(pa_name, uh_len, goto end);

  MemMove(pa_name, ps_mode->ra_name, uh_len);

  [self getFree:ps_mode];

 end:
  if (puh_len != NULL)
    *puh_len = uh_len - 1;	// Sans \0

  return pa_name;
}

@end
