/* 
 * Desc.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sun Aug 24 13:04:25 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Nov 19 12:20:16 2007
 * Update Count    : 14
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: Desc.m,v $
 * Revision 1.5  2008/01/14 17:13:47  max
 * LstSetSelection: s/noListSelection/0/g.
 * Correctly display the list at the bottom of screen instead of out of
 * screen.
 *
 * Revision 1.4  2006/04/25 08:46:15  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.3  2005/10/06 19:48:14  max
 * match() now have a b_exact argument.
 *
 * Revision 1.2  2005/03/20 22:28:19  max
 * Don't use the -listDrawFunction but directly __list_desc_draw()
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_DESC
#include "Desc.h"

#include "BaseForm.h"		// list_line_draw_line

#include "MaTirelire.h"

#include "ids.h"

#include "misc.h"
#include "graph_defs.h"
#include "objRsc.h"		// XXX

#include <PalmOSGlue/TxtGlue.h>
#include <PalmOSGlue/FntGlue.h>


@implementation Desc

- (Desc*)init
{
  // DB opening/creating
  if ([self initDBType:MaTiDescType nameSTR:MaTiDescName] == nil)
  {
    // XXX
    return nil;
  }

  return self;
}


////////////////////////////////////////////////////////////////////////
//
// Loading descriptions/macros
//
////////////////////////////////////////////////////////////////////////

// Nothing to do here


////////////////////////////////////////////////////////////////////////
//
// Saving descriptions/macros
//
////////////////////////////////////////////////////////////////////////

// Nothing to do here


////////////////////////////////////////////////////////////////////////
//
// Deleting descriptions/macros
//
////////////////////////////////////////////////////////////////////////

// Nothing to do here


////////////////////////////////////////////////////////////////////////
//
// Popup management
//
////////////////////////////////////////////////////////////////////////


static UInt16 __desc_macro_prepare(struct s_desc *ps_desc,
				   struct __s_list_desc_buf *ps_buf,
				   UInt16 *puh_width,
				   Boolean b_account)
{
  struct __s_desc_one_macro_comp *ps_comp;
  UInt16 uh_num_comp, uh_non_empty;
  UInt16 uh_total_width, uh_len, uh_total_len;
  Char *pa_str;

  ps_comp = ps_buf->u.rs_macro_comps;
  MemSet(ps_comp, sizeof(ps_buf->u.rs_macro_comps), '\0');
  uh_num_comp = 0;
  uh_total_width = 0;
  uh_total_len = 0;
  uh_non_empty = 0;

  //
  // Remplissage
  //

  // Partie somme (auto-valid / signe / somme)
  if (ps_desc->ui_auto_valid
      || ps_desc->ui_sign
      || ps_desc->ra_amount[0] != '\0')
  {
    pa_str = ps_comp->ra_str;

    if (ps_desc->ui_auto_valid)
    {
      *pa_str++ = '!';
      ps_comp->uh_len++;
    }

    switch (ps_desc->ui_sign)
    {
    case 1: *pa_str++ = '-'; ps_comp->uh_len++; break;
    case 2: *pa_str++ = '+'; ps_comp->uh_len++; break;
    }

    if (ps_desc->ra_amount[0] != '\0')
    {
      uh_len = StrLen(ps_desc->ra_amount);
      MemMove(pa_str, ps_desc->ra_amount, uh_len);
      ps_comp->uh_len += uh_len;
    }

    uh_total_width += FntCharsWidth(ps_comp->ra_str, ps_comp->uh_len);
    uh_total_len += ps_comp->uh_len;

    uh_num_comp = 1;
    uh_non_empty++;
  }

  // Le mode de paiement
  if (ps_desc->ui_is_mode || ps_desc->ui_cheque_num)
  {
    ps_comp = &ps_buf->u.rs_macro_comps[1];
    pa_str = ps_comp->ra_str;

    uh_len = 0;

    if (ps_desc->ui_cheque_num)
    {
      *pa_str++ = '*';
      uh_len = 1;
    }

    if (ps_desc->ui_is_mode)
    {
      struct s_mode *ps_mode;
      UInt16 uh_mode_len;

      ps_mode = [ps_buf->oMode getId:ps_desc->ui_mode];

      uh_mode_len = StrLen(ps_mode->ra_name);
      MemMove(pa_str, ps_mode->ra_name, uh_mode_len);

      [ps_buf->oMode getFree:ps_mode];

      uh_len += uh_mode_len;
    }

    ps_comp->uh_len = uh_len;
    uh_total_width += FntCharsWidth(ps_comp->ra_str, uh_len);
    uh_total_len += ps_comp->uh_len;

    uh_num_comp = 2;
    uh_non_empty++;
  }

  // Le type d'opération
  if (ps_desc->ui_type)
  {
    struct s_type *ps_type;

    ps_comp = &ps_buf->u.rs_macro_comps[2];

    ps_type = [ps_buf->oType getId:ps_desc->ui_type];

    uh_len = StrLen(ps_type->ra_name);
    MemMove(ps_comp->ra_str, ps_type->ra_name, uh_len);

    [ps_buf->oType getFree:ps_type];

    ps_comp->uh_len = uh_len;
    uh_total_width += FntCharsWidth(ps_comp->ra_str, uh_len);
    uh_total_len += uh_len;

    uh_num_comp = 3;
    uh_non_empty++;
  }

  ;

#define add_str(uh_num, pa_str) \
      do \
      { \
	ps_comp = &ps_buf->u.rs_macro_comps[uh_num - 1]; \
	uh_len = StrLen(pa_str); \
	MemMove(ps_comp->ra_str, pa_str, uh_len); \
	\
	ps_comp->uh_len = uh_len; \
	uh_total_width += FntCharsWidth(ps_comp->ra_str, uh_len); \
        uh_total_len += uh_len; \
	\
	uh_num_comp = uh_num; \
	uh_non_empty++; \
      } \
      while (0)

  // Le compte d'exécution
  if (ps_desc->ra_account[0] != '\0')
    add_str(4, ps_desc->ra_account);

  // Le compte de transfert
  if (ps_desc->ra_xfer[0] != '\0')
    add_str(5, ps_desc->ra_xfer);

  // Le filtre d'apparition
  if (b_account && ps_desc->ra_only_in_account[0] != '\0')
    add_str(6, ps_desc->ra_only_in_account);

  ps_buf->uh_num_comp = uh_num_comp;

  // Au moins un composant
  if (uh_num_comp > 0)
    // On ajoute la largeur des ';'
    uh_total_width += FntCharWidth(';') * (uh_num_comp - 1);
  
  ps_buf->uh_total_width = uh_total_width;
  ps_buf->uh_non_empty = uh_non_empty;

  *puh_width = uh_total_width;

  return uh_total_len;
}


static UInt16 __desc_macro_fill(struct __s_list_desc_buf *ps_buf,
				UInt16 *puh_width,
				UInt16 uh_max_width)
{
  struct __s_desc_one_macro_comp *ps_comp;
  UInt16 uh_num_comp, uh_non_empty, uh_index, uh_total_width, uh_len;
  Char *pa_str;

  UInt16 uh_ell_width = FntCharWidth('.');
  Char a_ell = '.';

  uh_num_comp = ps_buf->uh_num_comp;
  if (uh_num_comp == 0)
  {
    *puh_width = 0;
    return 0;
  }

  uh_total_width = ps_buf->uh_total_width;
  uh_non_empty = ps_buf->uh_non_empty;
  
  // On rétrécit tout le monde si besoin
  if (uh_total_width > uh_max_width)
  {
    UInt16 uh_largest;

    // On recherche le composant le plus long
    uh_largest = 0;
    ps_comp = &ps_buf->u.rs_macro_comps[uh_num_comp];
    for (uh_index = uh_num_comp; uh_index-- > 0; )
    {
      ps_comp--;
      if (ps_comp->uh_len > uh_largest)
	uh_largest = ps_comp->uh_len;
    }

    do
    {
      // Pour chaque composant en partant du dernier...
      ps_comp = &ps_buf->u.rs_macro_comps[uh_num_comp];
      for (uh_index = uh_num_comp; uh_index-- > 0; )
      {
	ps_comp--;

	if (ps_comp->uh_len >= uh_largest)
	{
	  // Pas encore tronqué
	  if (ps_comp->uh_truncated == 0)
	  {
	    uh_total_width += uh_ell_width;
	    ps_comp->uh_truncated = 1;
	  }

	  // Déjà tronqué => on continue...
	  uh_total_width -= FntCharWidth(ps_comp->ra_str[--ps_comp->uh_len]);

	  if (uh_total_width <= uh_max_width)
	    goto good_width;

	  if (ps_comp->uh_len == 0 && --uh_non_empty == 0)
	  {
	    // Dans ce cas, on a réduit à mort et la macro ne contient
	    // toujours pas => on affiche juste '...'
	    ps_buf->u.ra_str[0] = a_ell;
	    *puh_width = uh_ell_width;
	    return 1;
	  }
	}
      } /* for (;;) */
    }
    while (--uh_largest > 0);
  }

  // On prépare la chaîne de retour
 good_width:
  ps_comp = &ps_buf->u.rs_macro_comps[0];
  uh_len = ps_comp->uh_len;
  pa_str = &ps_buf->u.ra_str[uh_len];
  for (uh_index = 0; uh_index < uh_num_comp; uh_index++, ps_comp++)
  {
    // Pas le premier (la première chaîne est déjà bien placée)
    if (uh_index > 0)
    {
      *pa_str++ = ';';
      uh_len++;

      if (ps_comp->uh_len > 0)
      {
	MemMove(pa_str, ps_comp->ra_str, ps_comp->uh_len);
	pa_str += ps_comp->uh_len;
	uh_len += ps_comp->uh_len;
      }
    }

    if (ps_comp->uh_truncated)
    {
      *pa_str++ = a_ell;
      uh_len++;
    }
  }

  *pa_str = '\0';		// Ne sert à rien

  *puh_width = uh_total_width;

  return uh_len;
}


- (Char**)listBuildInfos:(void*)pv_infos num:(UInt16*)puh_num
		 largest:(UInt16*)puh_largest
{
  struct s_desc_list_infos *ps_infos = pv_infos;
  struct __s_list_desc_buf *ps_buf;
  UInt16 uh_index, uh_num, uh_num_records;
  UInt16 uh_width, uh_largest;
  Char ra_shortcut[2] = { 0, 0 };

  VoidHand vh_desc;
  struct s_desc *ps_desc;

  uh_num_records = DmNumRecords(self->db);

  NEW_PTR(ps_buf, sizeof(*ps_buf) + uh_num_records * sizeof(UInt16),
	  return NULL);

  uh_largest = 0;
  uh_num = 0;

  ps_buf->oMode = [oMaTirelire mode];
  ps_buf->oType = [oMaTirelire type];

  // Calcul de la plus grande largeur + cache entrées liste / index
  for (uh_index = 0; uh_index < uh_num_records; uh_index++)
  {
    vh_desc = DmQueryRecord(self->db, uh_index);
    if (vh_desc != NULL)
    {
      ps_desc = MemHandleLock(vh_desc);

      // On prend toutes les descriptions
      if (ps_infos == NULL
	  // OU BIEN celles avec le bon raccourci
	  || ((ps_infos->ra_shortcut[0] == '\0'
	       || (ra_shortcut[0] = ps_desc->ui_shortcut,
		   StrCaselessCompare(ra_shortcut, ps_infos->ra_shortcut)==0))
	      // ET qui matchent le compte
	      &&  match(ps_desc->ra_only_in_account,
			ps_infos->ra_account, true)))
      {
	// Macro
	if (__desc_macro_prepare(ps_desc, ps_buf,
				 &uh_width, ps_infos == NULL) > 0)
	  uh_width += MINIMAL_SPACE;

	// Description
	uh_width += FntCharsWidth(ps_desc->ra_desc, StrLen(ps_desc->ra_desc));

	if (uh_width > uh_largest)
	  uh_largest = uh_width;

	ps_buf->ruh_list2index[uh_num++] = uh_index;
      }

      MemHandleUnlock(vh_desc);
    }
  }

  ps_buf->oItem = self;
  ps_buf->uh_num_rec_entries = uh_num;
  ps_buf->uh_is_right_margin = 0;
  ps_buf->uh_only_in_account_view = (ps_infos == NULL);

  // Additionnal entry (sauf si la liste est fonction d'un raccourci)
  if (ps_infos != NULL && ps_infos->ra_shortcut[0] == '\0')
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


static void __list_desc_draw(Int16 h_line, RectangleType *prec_bounds,
			     Char **ppa_lines)
{
  struct __s_list_desc_buf *ps_buf = (struct __s_list_desc_buf*)ppa_lines;

  VoidHand vh_desc = NULL;
  struct s_desc *ps_desc = NULL;

  Char *pa_desc;
  UInt16 uh_desc_len = 0, uh_macro_len = 0;

  UInt16 uh_macro_width = 0, uh_macro_real_width = 0;
  UInt16 uh_right_margin, uh_max_width, uh_y = 0;
  Int16 h_width = 0, h_upperline = 0;

  Char a_shortcut = 0;

  if (h_line < ps_buf->uh_num_rec_entries)
  {
    vh_desc = DmQueryRecord(ps_buf->oItem->db, ps_buf->ruh_list2index[h_line]);
    ps_desc = MemHandleLock(vh_desc);

    // Description
    pa_desc = ps_desc->ra_desc;

    // Macro
    uh_macro_len = __desc_macro_prepare(ps_desc, ps_buf,
					&uh_macro_real_width,
					ps_buf->uh_only_in_account_view);
    if (uh_macro_len > 0)
      uh_macro_real_width += MINIMAL_SPACE;

    // Le raccourci
    a_shortcut = ps_desc->ui_shortcut;
  }
  // "Edit..." entry
  else // if (h_line == ps_buf->uh_num_rec_entries)
  {
    pa_desc = ps_buf->ra_edit_entry;
    h_upperline = 1;		// Un séparateur au dessus
  }

  // Does this list contain scroll arrows?
  uh_right_margin = ps_buf->uh_is_right_margin
    ? LIST_RIGHT_MARGIN : LIST_RIGHT_MARGIN_NOSCROLL;

  // Macro
  if (uh_macro_len > 0)
  {
    // Place maximum allouée pour la macro (moitié de la largeur hors marges)
    // La marge de gauche est déjà décomptée par l'OS
    uh_max_width = (prec_bounds->extent.x - uh_right_margin) / 2;

    uh_macro_width = (uh_macro_real_width > uh_max_width)
      ? uh_max_width : uh_macro_real_width;
  }

  // Largeur maximale pour la description sans la macro
  uh_max_width = prec_bounds->extent.x - uh_macro_width - uh_right_margin;

  //
  // On affiche la partie description
  if (*pa_desc != '\0')
  {
    uh_desc_len = StrLen(pa_desc);

    h_width = prepare_truncating(pa_desc, &uh_desc_len, uh_max_width);
    WinDrawTruncatedChars(pa_desc, uh_desc_len,
			  prec_bounds->topLeft.x, prec_bounds->topLeft.y,
			  h_width);
    if (h_width < 0)
      h_width = FntCharsWidth(pa_desc, uh_desc_len);

    // On dessine le souligné du raccourci
    if (a_shortcut != 0)
    {
      Char *pa_shortcut;
      WChar wa_shortcut;

      // On cherche la majuscule d'abord
      if (((pa_shortcut = StrChr(pa_desc,
				 wa_shortcut = TxtGlueUpperChar(a_shortcut)))
	   != NULL
	   ||
	   // Sinon la minuscule...
	   (pa_shortcut = StrChr(pa_desc,
				 wa_shortcut = TxtGlueLowerChar(a_shortcut)))
	   != NULL)
	  // ET le raccourci va être visible
	  && (pa_shortcut - pa_desc) < uh_desc_len)
      {
	UInt16 uh_x;

	uh_x = prec_bounds->topLeft.x
	  + FntCharsWidth(pa_desc, pa_shortcut - pa_desc);
	uh_y = prec_bounds->topLeft.y + FntBaseLine() + 1;

	WinDrawLine(uh_x, uh_y,
		    uh_x + FntGlueWCharWidth(wa_shortcut) - 1, uh_y);
      }
    }
  }

  // Place restante pour la macro
  uh_max_width = prec_bounds->extent.x - uh_right_margin
    - MINIMAL_SPACE - h_width;

  // Macro
  if (uh_macro_len > 0)
  {
    UInt16 uh_x, uh_y;

    // Adjust the macro len if needed
    uh_macro_len = __desc_macro_fill(ps_buf,
				     &uh_macro_real_width, uh_max_width);

    uh_x = prec_bounds->topLeft.x + prec_bounds->extent.x
      - uh_right_margin
      - uh_macro_real_width
      - 1;		       // Pour compenser le souligné trop long

    uh_y = prec_bounds->topLeft.y;

    WinDrawChars(ps_buf->u.ra_str, uh_macro_len, uh_x, uh_y);

    uh_y += FntBaseLine() + 1;

    WinDrawGrayLine(uh_x, uh_y, uh_x + uh_macro_real_width - 1, uh_y);
  }

  if (vh_desc != NULL)
    MemHandleUnlock(vh_desc);

  if (h_upperline)
    list_line_draw_line(prec_bounds, h_upperline);
}


- (ListDrawDataFuncPtr)listDrawFunction
{
  return __list_desc_draw;
}


- (UInt16)dbMaxEntries
{
  return NUM_DESC;
}


////////////////////////////////////////////////////////////////////////
//
// Gestion automatique des popups
//
////////////////////////////////////////////////////////////////////////

struct __s_desc_popup_list
{
  ListType *pt_list;
  struct __s_list_desc_buf *ps_buf;
};

- (VoidHand)popupListInit:(UInt16)uh_list_id
                     form:(FormType*)pt_frm
		    infos:(struct s_desc_popup_infos*)ps_infos
{
  VoidHand pv_list;
  struct __s_desc_popup_list *ps_list;
  struct s_desc_list_infos s_desc_infos;
  RectangleType s_rect;
  UInt16 uh_list_idx, uh_screen_width, uh_screen_height, uh_num, uh_largest;

  NEW_HANDLE(pv_list, sizeof(struct __s_desc_popup_list), return NULL);

  ps_list = MemHandleLock(pv_list);

  // Les infos pour la construction de la liste
  CategoryGetName([oMaTirelire transaction]->db, ps_infos->uh_account,
		  s_desc_infos.ra_account);
  s_desc_infos.ra_shortcut[0] = ps_infos->ra_shortcut[0];
  s_desc_infos.ra_shortcut[1] = '\0';

  ps_list->ps_buf =
    (struct __s_list_desc_buf*)[self listBuildInfos:&s_desc_infos
				       num:&uh_num
				     largest:&uh_largest];
  if (ps_list->ps_buf != NULL)
  {
    uh_list_idx = FrmGetObjectIndex(pt_frm, uh_list_id);
    ps_list->pt_list = FrmGetObjectPtr(pt_frm, uh_list_idx);

    LstSetHeight(ps_list->pt_list, uh_num);

    uh_largest += LIST_MARGINS_NO_SCROLL;

    if ([self rightMarginList:ps_list->pt_list num:uh_num
	      in:(struct __s_list_dbitem_buf*)ps_list->ps_buf selItem:-1])
      uh_largest += LIST_MARGINS_WITH_SCROLL - LIST_MARGINS_NO_SCROLL;

    // On sélectionne la première entrée (arbitraire)
    LstSetSelection(ps_list->pt_list, 0);

    // On s'adapte à la largeur de l'écran
    WinGetDisplayExtent(&uh_screen_width, &uh_screen_height);
    if (uh_largest > uh_screen_width - LIST_EXTERNAL_BORDERS)
      uh_largest = uh_screen_width - LIST_EXTERNAL_BORDERS;

    // On remet la liste à la bonne position (avec une largeur adéquate)
    FrmGetObjectBounds(pt_frm, uh_list_idx, &s_rect);
    s_rect.extent.x = uh_largest;
    if (ps_infos->uh_flags & DESC_AT_SCREEN_BOTTOM)
    {
      s_rect.topLeft.x = (uh_screen_width - uh_largest) / 2;
      s_rect.topLeft.y = uh_screen_height - s_rect.extent.y;
    }
    FrmSetObjectBounds(pt_frm, uh_list_idx, &s_rect);

    // Le callback de remplissage de la liste
    LstSetDrawFunction(ps_list->pt_list, __list_desc_draw);
  }

  MemHandleUnlock(pv_list);

  return pv_list;
}


//
// Si b_auto_return et qu'il n'y a qu'une description dans la liste,
// le popup ne se déploie pas, mais l'ID de la description est
// renvoyé.
- (UInt16)popupList:(VoidHand)pv_list autoReturn:(Boolean)b_auto_return
{
  struct __s_desc_popup_list *ps_list;
  UInt16 uh_item;

  ps_list = MemHandleLock(pv_list);

  if (b_auto_return)
  {
    // Liste vide (l'autre cas ne survient normalement jamais car dans
    // le cas b_auto_return il n'y a jamais d'entrée "Éditer...")
    if (ps_list->ps_buf == NULL || ps_list->ps_buf->uh_num_rec_entries == 0)
    {
      uh_item = noListSelection;
      goto end;
    }

    // Un seul élément
    if (ps_list->ps_buf->uh_num_rec_entries == 1)
    {
      uh_item = ps_list->ps_buf->ruh_list2index[0];
      goto end;
    }
  }

  // On déploie la liste
  uh_item = LstPopupList(ps_list->pt_list);

  // Il y a une sélection
  if (uh_item != noListSelection)
  {
    // On vient de sélectionner un item
    if (uh_item < ps_list->ps_buf->uh_num_rec_entries)
      uh_item = ps_list->ps_buf->ruh_list2index[uh_item];
    // L'entrée "Éditer..."
    else
      uh_item = DESC_EDIT;

    // On repasse sur la première entrée pour la prochaine fois
    LstSetSelection(ps_list->pt_list, 0);
  }

 end:
  MemHandleUnlock(pv_list);

  return uh_item;
}


- (void)popupListFree:(VoidHand)pv_list
{
  if (pv_list != NULL)
  {
    struct __s_desc_popup_list *ps_list = MemHandleLock(pv_list);

    if (ps_list->ps_buf != NULL)
      MemPtrFree(ps_list->ps_buf);

    MemHandleUnlock(pv_list);

    MemHandleFree(pv_list);
  }
}


////////////////////////////////////////////////////////////////////////
//
// Type/Mode removing
//
////////////////////////////////////////////////////////////////////////

- (UInt16)removeType:(UInt16)uh_id
{
  MemHandle pv_item;

  UInt32 ui_desc_header;
  struct s_desc *ps_desc, *ps_header_desc = NULL;

  UInt16 index, uh_num = 0;
  Boolean b_to_delete = false;
  

  for (index = DmNumRecords(self->db); index-- > 0; )
  {
    pv_item = DmQueryRecord(self->db, index);
    if (pv_item != NULL)
    {
      ps_desc = MemHandleLock(pv_item);

      if (ps_desc->ui_is_type && ps_desc->ui_type == uh_id)
      {
	// Load header locally
	ui_desc_header = *(UInt32*)ps_desc;
	ps_header_desc = (struct s_desc*)&ui_desc_header;

	// La macro va devenir complètement vide
	if (ps_desc->ra_desc[0] == '\0'
	    && ps_desc->ui_sign == 0
	    && ps_desc->ui_is_mode == 0
	    && ps_desc->ra_amount[0] == '\0'
	    && ps_desc->ra_xfer[0] == '\0'
	    && ps_desc->ra_account[0] == '\0')
	{
	  // On laisse le type "Unfiled"
	  ps_header_desc->ui_type = TYPE_UNFILED;
	}
	// On peut retirer complètement le type
	else
	{
	  ps_header_desc->ui_is_type = 0;
	  ps_header_desc->ui_type = 0;
	}

	b_to_delete = true;
      }

      MemHandleUnlock(pv_item);

      // Commit changes
      if (b_to_delete)
      {
	void *ps_rec = [self recordGetAtId:index];

	// On ne sauve que le header
	DmWrite(ps_rec, DESC_HEADER_OFFSET, ps_header_desc, DESC_HEADER_SIZE);

	[self recordRelease:true];

	uh_num++;

	b_to_delete = false;
      }
    }
  }

  return uh_num;
}


- (UInt16)removeMode:(UInt16)uh_id
{
  MemHandle pv_item;

  UInt32 ui_desc_header;
  struct s_desc *ps_desc, *ps_header_desc = NULL;

  UInt16 index, uh_num = 0;
  Boolean b_to_delete = false;
  

  for (index = DmNumRecords(self->db); index-- > 0; )
  {
    pv_item = DmQueryRecord(self->db, index);
    if (pv_item != NULL)
    {
      ps_desc = MemHandleLock(pv_item);

      if (ps_desc->ui_is_mode && ps_desc->ui_mode == uh_id)
      {
	// Load header locally
	ui_desc_header = *(UInt32*)ps_desc;
	ps_header_desc = (struct s_desc*)&ui_desc_header;

	// La macro va devenir complètement vide
	if (ps_desc->ra_desc[0] == '\0'
	    && ps_desc->ui_sign == 0
	    && ps_desc->ui_is_type == 0
	    && ps_desc->ra_amount[0] == '\0'
	    && ps_desc->ra_xfer[0] == '\0'
	    && ps_desc->ra_account[0] == '\0')
	{
	  // On laisse le mode "Unknown"
	  ps_header_desc->ui_mode = MODE_UNKNOWN;
	}
	// On peut retirer complètement le mode
	else
	{
	  ps_header_desc->ui_is_mode = 0;
	  ps_header_desc->ui_mode = 0;
	}

	b_to_delete = true;
      }

      MemHandleUnlock(pv_item);

      // Commit changes
      if (b_to_delete)
      {
	void *ps_rec = [self recordGetAtId:index];

	// On ne sauve que le header
	DmWrite(ps_rec, DESC_HEADER_OFFSET, ps_header_desc, DESC_HEADER_SIZE);

	[self recordRelease:true];

	uh_num++;

	b_to_delete = false;
      }
    }
  }

  return uh_num;
}

@end
