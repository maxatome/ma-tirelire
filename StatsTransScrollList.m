/* 
 * StatsTransScrollList.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mar aoû 16 20:23:51 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Nov  2 12:59:59 2006
 * Update Count    : 100
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: StatsTransScrollList.m,v $
 * Revision 1.17  2008/01/14 16:08:53  max
 * Switch to new mcc.
 *
 * Revision 1.16  2006/12/16 16:56:48  max
 * Correct crash when selecting amount in the list.
 *
 * Revision 1.15  2006/11/04 23:48:16  max
 * Is now a super class.
 * Handle changes in struct s_stats_trans_draw.
 * Amounts are now stored in memory, no longer computed at fly.
 *
 * Revision 1.14  2006/10/05 19:09:00  max
 * Search totally reworked using CustomScrollList genericity.
 *
 * Revision 1.13  2006/06/28 14:22:47  max
 * Rework -getItem:next: to handle TransForm next/prev navigation.
 *
 * Revision 1.12  2006/06/28 09:41:41  max
 * s/pt_frm/oForm/g attribute.
 *
 * Revision 1.11  2006/04/25 08:46:15  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.10  2005/11/19 16:56:32  max
 * trans_draw_longclic_frame() and trans_draw_record() calling
 * conventions changed.
 *
 * Revision 1.9  2005/10/16 21:44:07  max
 * Add -getItem:next: to handle moves in list from TransForm. Not yet enabled.
 *
 * Revision 1.8  2005/10/14 22:37:30  max
 * New trans_draw_record() behavior requests new argument.
 *
 * Revision 1.7  2005/10/11 19:12:00  max
 * Export feature added.
 *
 * Revision 1.6  2005/10/06 19:48:18  max
 * Add -accounts method to help to determine the currency to use in scrolllist.
 *
 * Revision 1.5  2005/09/02 17:23:09  max
 * Correct bug, bad index passed to DmRecordInfo.
 *
 * Revision 1.4  2005/08/31 19:43:09  max
 * Does not take account properties into account anymore when withdrawal
 * date is in use or when searching for a currency option..
 * Does not use BIT_INV macro anymore. It causes stack problems!
 * Sum of selected/unselected lines is now correct.
 *
 * Revision 1.3  2005/08/31 19:38:53  max
 * *** empty log message ***
 *
 * Revision 1.2  2005/08/28 10:02:35  max
 * Bit manipulation macros pass to misc.h.
 * Handle types list in search criterias.
 * Correct long clic display bug.
 *
 * Revision 1.1  2005/08/20 13:06:35  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_STATSTRANSSCROLLLIST
#include "StatsTransScrollList.h"

#include "MaTirelire.h"
#include "CustomListForm.h"
#include "StatsTypeScrollList.h"
#include "StatsModeScrollList.h"
#include "StatsPeriodScrollList.h"
#include "TransScrollList.h"
#include "ProgressBar.h"
#include "ExportForm.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


static void __stats_trans_draw(void *pv_table, Int16 h_row, Int16 h_col,
			       RectangleType *prec_bounds)
{ // OK
  StatsTransScrollList *oTransScrollList = ScrollListGetPtr(pv_table);
  UInt32 *pul_select;
  struct s_stats_trans_base *ps_trans;
  UInt16 index;
  struct s_stats_trans_draw s_draw;

  index = TblGetRowID((TableType*)pv_table, h_row);

  // Est-il sélectionné ou non ?
  pul_select = MemHandleLock(oTransScrollList->vh_select);

  s_draw.uh_selected = (BIT_ISSET(index, pul_select) != 0);
  s_draw.uh_select_with_internal_flag = false;
  s_draw.uh_add_to_desc = TRANS_DRAW_ADD_NONE;

  MemHandleUnlock(oTransScrollList->vh_select);

  // Pas l'écran des répétitions
  s_draw.uh_repeat_screen = false;

  // Date de l'opération intacte
  DateToInt(s_draw.s_date) = 0;

  ps_trans = MemHandleLock(oTransScrollList->vh_infos);
  (Char*)ps_trans += (UInt32)index * [oTransScrollList oneElementSize];

  s_draw.uh_rec_index = ps_trans->uh_rec_index;

  // Montant particulier
  s_draw.uh_another_amount = 1;
  s_draw.l_amount = ps_trans->l_amount;

  [oTransScrollList initDraw:&s_draw from:ps_trans];

  MemHandleUnlock(oTransScrollList->vh_infos);

  // On peut dessiner la ligne...
  trans_draw_record(&s_draw, h_row, -1, prec_bounds);
}


@implementation StatsTransScrollList

- (StatsTransScrollList*)free
{
  if (self->vh_select != NULL)
    MemHandleFree(self->vh_select);

  return [super free];
}


// Méthode à appeler lorsque le nombre d'entrées dans la liste a changé
- (void)initRecordsCount
{
  struct s_private_search_trans s_search_infos;

  if (self->vh_infos != NULL)
  {
    MemHandleFree(self->vh_infos);
    self->vh_infos = NULL;
  }

  if (self->vh_select != NULL)
  {
    MemHandleFree(self->vh_select);
    self->vh_select = NULL;
  }

  /////////////////////////
  //
  // Première passe de comptage

  s_search_infos.uh_opt_min = 0xffff;
  s_search_infos.b_second_pass = false;

  self->uh_num_items = 0;

  // Pour notre/nos méthodes appelées durant -search
  self->ps_search_trans_infos = &s_search_infos;

  [self searchFrom:0 amount:true];

  // On peut allouer la place nécessaire
  if (self->uh_num_items > 0)
  {
    UInt32 ui_size;
    UInt16 uh_select_size;

    /////////////////////////
    //
    // Allocation

    ui_size = [self oneElementSize];

    NEW_HANDLE(self->vh_infos, self->uh_num_items * ui_size,
	       ({ self->uh_num_items = 0; goto end; }));

    uh_select_size = BYTESFORBITS(self->uh_num_items);

    NEW_HANDLE(self->vh_select, uh_select_size,
	       ({
		 MemHandleFree(self->vh_infos);
		 self->vh_infos = NULL;
		 self->uh_num_items = 0;
		 goto end;
	       }));

    // On pré-sélectionne tout s'il s'agit de l'écran des marqués
    MemSet(MemHandleLock(self->vh_select), uh_select_size,
	   [self initSelectedPattern]);
    MemHandleUnlock(self->vh_select);


    /////////////////////////
    //
    // Deuxième passe de stockage

    s_search_infos.b_second_pass = true;
    s_search_infos.uh_opt_num = self->uh_num_items;

    s_search_infos.ps_items = MemHandleLock(self->vh_infos);

    [self searchFrom:s_search_infos.uh_opt_min amount:true];

    MemHandleUnlock(self->vh_infos);
  }

  // Les montants nuls ne sont jamais ignorés dans cet écran

 end:
  [super initRecordsCount];
}


- (void)initColumns
{
  self->pf_line_draw = __stats_trans_draw;

  self->uh_flags = SCROLLLIST_BOTTOP | SCROLLLIST_FULL;

  [super initColumns];
}


- (UInt16)amountWidth
{
  return oMaTirelire->s_misc_infos.uh_amount_width;
}


//
// - initialise self->l_sum
- (void)computeSum
{
  t_amount l_sum = 0;

  if (self->vh_infos != NULL)
  {
    UInt32 *pul_select;
    struct s_stats_trans_base *ps_trans;
    UInt16 uh_index, uh_comp, uh_inc;

    uh_inc = [self oneElementSize];

    pul_select = MemHandleLock(self->vh_select);
    ps_trans = MemHandleLock(self->vh_infos);

    // Si sum_type == ALL (0)        => -1 ==> 0xffff (XOR 1 != 0 / XOR 0 != 0)
    // Si sum_type == SELECT (1)     => 0
    // Si sum_type == NON_SELECT (2) => 1
    uh_comp = self->uh_sum_filter - 1;

    for (uh_index = 0; uh_index < self->uh_num_items;
	 uh_index++, (Char*)ps_trans += uh_inc)
      if (uh_comp ^ (BIT_ISSET(uh_index, pul_select) != 0))
	l_sum += ps_trans->l_amount;

    MemHandleUnlock(self->vh_infos);
    MemHandleUnlock(self->vh_select);
  }

  self->l_sum = l_sum;
}


//
// Renvoie -1 si rien n'a bougé
// Renvoie 1 si la somme a été sélectionnée (passage de 0 à 1)
// Renvoie 3 si pareil mais qu'il faut redessiner la somme complètement
// Renvoie 0 si la somme a été désélectionnée (passage de 1 à 0)
- (Int16)shortClicOnSumOfRow:(UInt16)uh_row xPos:(UInt16)uh_x
		      amount:(t_amount*)pl_amount
{
  Transaction *oTransactions = [oMaTirelire transaction];
  struct s_transaction *ps_tr;
  struct s_stats_trans_base *ps_trans;
  UInt32 *pul_select, ui_mask;
  UInt16 index;
  Int16 h_ret = 1;

  index = TblGetRowID(self->pt_table, uh_row);

  ps_trans = MemHandleLock(self->vh_infos);
  (UInt32)ps_trans += (UInt32)index * [self oneElementSize];

  *pl_amount = ps_trans->l_amount;
  ps_tr = [oTransactions getId:ps_trans->uh_rec_index];

  MemHandleUnlock(self->vh_infos);

  pul_select = MemHandleLock(self->vh_select);

  // On inverse l'état, la macro BIT_INV() provoque des problèmes de pile
  pul_select += index / NBITS;
  ui_mask = _bit_mask(index);
  *pul_select ^= ui_mask;
  if (*pul_select & ui_mask)
    // On renvoie 3 si sélectionné car on veut que la somme soit
    // complètement redessinée à cause du pointage/marquage
    h_ret = (ps_tr->ui_rec_flags & (RECORD_CHECKED|RECORD_MARKED)) ? 3 : 1;
  else
    h_ret = 0;

  MemHandleUnlock(self->vh_select);

  [oTransactions getFree:ps_tr];

  return h_ret;
}


- (void)selectChange:(Int16)h_action
{
  UInt32 *pul_select;
  UInt16 uh_num;

  if (self->vh_select == NULL)
    return;

  pul_select = MemHandleLock(self->vh_select);

  uh_num = DWORDFORBITS(self->uh_num_items);

  // Invert
  if (h_action < 0)
    while (uh_num-- > 0)
      *pul_select++ ^= 0xffffffff;
  else
  {
    UInt32 ui_new_select = (h_action == 0) ? 0 : 0xffffffff;

    while (uh_num-- > 0)
      *pul_select++ = ui_new_select;
  }

  MemHandleUnlock(self->vh_select);

  [super selectChange:h_action];
}


//
// Méthode à appeler lorsqu'on veut positionner l'élement qui sera
// toujours visible dans la liste (self->uh_current_item)
//
// uh_new_cur est l'index de l'opération, il faut le rechercher dans
// notre liste et donner sa position à Papa
- (void)setCurrentItem:(UInt16)uh_new_cur
{
  if (uh_new_cur != SCROLLLIST_NO_CURRENT)
  {
    UInt16 uh_final_cur, uh_index, uh_flags;

    uh_flags = (uh_new_cur & SCROLLLIST_CURRENT_DONT_RELOAD);
    uh_new_cur &= ~SCROLLLIST_CURRENT_DONT_RELOAD;

    uh_final_cur = 0;

    if (self->vh_infos != NULL)
    {
      struct s_stats_trans_base *ps_trans;
      UInt16 uh_inc;

      uh_inc = [self oneElementSize];

      ps_trans = MemHandleLock(self->vh_infos);

      for (uh_index = 0; uh_index < self->uh_num_items;
	   (Char*)ps_trans += uh_inc, uh_index++)
	if (ps_trans->uh_rec_index == uh_new_cur)
	{
	  uh_final_cur = uh_index;
	  break;
	}

      MemHandleUnlock(self->vh_infos);
    }

    uh_new_cur = uh_final_cur | uh_flags;
  }

  [super setCurrentItem:uh_new_cur];
}


//
// Implémentation pas terrible, mais on n'a pas trop le choix. Si
// TransForm change la date d'une opération de la liste, l'opération
// va changer d'index et donc les suivants/précédents ne seront plus
// corrects
- (Boolean)getItem:(UInt16*)puh_cur next:(Boolean)b_next
{
  Boolean b_ret = false;

  if (self->vh_infos != NULL)
  {
    struct s_stats_trans_base *ps_trans;
    UInt16 uh_index, uh_inc;

    uh_inc = [self oneElementSize];

    ps_trans = MemHandleLock(self->vh_infos);

    for (uh_index = 0; uh_index < self->uh_num_items;
	 (Char*)ps_trans += uh_inc, uh_index++)
      if (ps_trans->uh_rec_index == *puh_cur)
      {
	if (b_next)
	{
	  if (uh_index < self->uh_num_items - 1)
	  {
	    b_ret = true;
	    (Char*)ps_trans += uh_inc;
	    *puh_cur = ps_trans->uh_rec_index;
	  }
	}
	else
	{
	  if (uh_index > 0)
	  {
	    b_ret = true;
	    (Char*)ps_trans -= uh_inc;
	    *puh_cur = ps_trans->uh_rec_index;
	  }
	}

	break;
      }

    MemHandleUnlock(self->vh_infos);
  }

  return b_ret;
}


- (void)getRecordInfos:(struct s_stats_trans_base*)ps_infos
	       forLine:(UInt16)uh_line
{
  UInt32 ui_size = [self oneElementSize];

  MemMove(ps_infos, (Char*)MemHandleLock(self->vh_infos) + uh_line * ui_size,
	  ui_size);

  MemHandleUnlock(self->vh_infos);
}


////////////////////////////////////////////////////////////////////////
//
// Méthodes virtuelles
//
////////////////////////////////////////////////////////////////////////

- (UInt16)oneElementSize
{
  return [self subclassResponsibility];
}


- (UChar)initSelectedPattern
{
  return 0x00; // Par défaut on initialise à 0 : rien n'est sélectionné
}


- (void)initDraw:(struct s_stats_trans_draw*)ps_draw
	    from:(struct s_stats_trans_base*)ps_infos
{
  return [self subclassResponsibility];
}

@end
