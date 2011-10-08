/* 
 * RepeatsScrollList.m -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Tue Nov  1 23:42:11 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Wed Jan 23 13:21:17 2008
 * Update Count    : 84
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: RepeatsScrollList.m,v $
 * Revision 1.10  2008/02/01 17:17:30  max
 * Correct bug in -setCurrentItem:.
 *
 * Revision 1.9  2008/01/14 16:30:50  max
 * Switch to new mcc.
 *
 * Revision 1.8  2006/11/05 14:22:24  max
 * Don't forget to init s_draw.uh_another_amount.
 *
 * Revision 1.7  2006/11/04 23:48:12  max
 * Handle changes in struct s_stats_trans_draw.
 * In some cases, list could be not updated: corrected.
 *
 * Revision 1.6  2006/10/05 19:08:44  max
 * s/Int32/t_amount/g
 *
 * Revision 1.5  2006/06/28 14:22:43  max
 * Add -getItem:next: implementation to handle TransForm next/prev navigation.
 *
 * Revision 1.4  2006/06/28 09:41:41  max
 * s/pt_frm/oForm/g attribute.
 *
 * Revision 1.3  2006/06/19 12:24:07  max
 * Account balance was skipped from cleared sum. Corrected.
 *
 * Revision 1.2  2006/04/25 08:47:20  max
 * Correct sum bug when transactions with withdrawal dates.
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.1  2005/11/19 16:56:44  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_REPEATSSCROLLLIST
#include "RepeatsScrollList.h"

#include "RepeatsListForm.h"
#include "StatsTransScrollList.h" // Pour struct s_stats_trans_draw
#include "TransScrollList.h"	  // Pour trans_draw_record()

#include "MaTirelire.h"
#include "ProgressBar.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


static void __repeats_trans_draw(void *pv_table, Int16 h_row, Int16 h_col,
				 RectangleType *prec_bounds)
{
  RepeatsScrollList *oRepeatsScrollList = ScrollListGetPtr(pv_table);
  UInt16 uh_pos;

  uh_pos = TblGetRowID((TableType*)pv_table, h_row);

  // Cas particulier pour la première ligne : somme des non répétitions
  if (uh_pos == 0)
  {
    Char ra_label[64];

    SysCopyStringResource(ra_label, strRepeatsListNonRepeatsSum);

    // Somme jamais sélectionnée
    draw_sum_line(ra_label, oRepeatsScrollList->l_non_repeats_sum,
		  prec_bounds, DRAW_SUM_MIN_WIDTH);
  }
  else
  {
    UInt32 *pui_tr, ui_tr;
    struct s_stats_trans_draw s_draw;

    // L'index de l'enregistrement
    pui_tr = MemHandleLock(oRepeatsScrollList->vh_infos);

    ui_tr = pui_tr[uh_pos - 1];

    MemHandleUnlock(oRepeatsScrollList->vh_infos);

    s_draw.uh_rec_index = (UInt16)(ui_tr & 0x7fff);
    s_draw.h_split = -1;	// Opération complète

    // Description normale
    s_draw.uh_add_to_desc = TRANS_DRAW_ADD_NONE;

    // On ne sélectionne pas
    s_draw.uh_selected = false;
    s_draw.uh_select_with_internal_flag = false;

    // On dessine le marquage
    s_draw.uh_non_flagged = false;

    // Écran des répétitions
    s_draw.uh_repeat_screen = true;

    // Pas de montant spécial
    s_draw.uh_another_amount = 0;

    // Opération du futur
    DateToInt(s_draw.s_date) = (ui_tr & 0x8000UL) ? (UInt16)(ui_tr >> 16) : 0;

    // On peut dessiner la ligne...
    trans_draw_record(&s_draw, h_row, -1, prec_bounds);
  }
}


static Int16 _repeats_cmp(UInt32 *pui1, UInt32 *pui2, void *pv_dummy)
{
  if (*pui1 < *pui2)
    return -1;

  return *pui1 > *pui2;
}


@implementation RepeatsScrollList

- (RepeatsScrollList*)free
{
  if (self->vh_infos != NULL)
    MemHandleFree(self->vh_infos);

  return [super free];
}


// L'opération passée en paramère comporte forcément une répétition
- (UInt16)numRepeatsFor:(struct s_transaction*)ps_tr
		maxDate:(UInt16)uh_max_date
		 putsIn:(UInt32*)pui_tr
{
  struct s_rec_options s_options;
  struct s_rec_repeat *ps_repeat;
  UInt32 ui_next_days;
  DateType s_next_date;
  UInt16 uh_next_date, uh_last_date, uh_num_repeats = 0;

  options_extract(ps_tr, &s_options);

  // Calcul de la date du futur enregistrement
  s_next_date = ps_tr->s_date;

  uh_last_date = ps_tr->ui_rec_value_date
    ? DateToInt(s_options.ps_value_date->s_value_date) : DateToInt(s_next_date);

  ps_repeat = s_options.ps_repeat;

  for (;;)
  {
    switch (ps_repeat->uh_repeat_type)
    {
    case REPEAT_WEEKLY:
      // Prochaine date en jours
      ui_next_days = DateToDays(s_next_date) + ps_repeat->uh_repeat_freq * 7;

      // Le prochain jour
      DateDaysToDate(ui_next_days, &s_next_date);
      break;

    case REPEAT_MONTHLY:
    case REPEAT_MONTHLY_END:
    default:
    {
      UInt16 uh_new_month, uh_days;

      /* X mois de plus (l'année peut changer...) */
      uh_new_month
	= (s_next_date.month - 1 + ps_repeat->uh_repeat_freq) % 12 + 1;

      s_next_date.year +=
	ps_repeat->uh_repeat_freq / 12 + (uh_new_month < s_next_date.month);

      s_next_date.month = uh_new_month;

      /* Nombre de jours dans ce mois */
      uh_days = DaysInMonth(s_next_date.month, s_next_date.year + firstYear);

      /* Le dernier jour de chaque mois */
      if (ps_repeat->uh_repeat_type == REPEAT_MONTHLY_END
	  /* OU BIEN jour invalide pour ces mois/année */
	  || s_next_date.day > uh_days)
	s_next_date.day = uh_days;
    }
    break;
    }

    uh_next_date = DateToInt(s_next_date);

    // S'il y a une date de fin de répétition
    if (DateToInt(ps_repeat->s_date_end) != 0
	&& uh_next_date > DateToInt(ps_repeat->s_date_end))
      break;

    // Trop loin
    if (uh_next_date > uh_max_date)
    {
      // Soit on rajoute pui_tr == NULL et on ne fait ce test qu'une
      // fois, soit on laisse et lors du 2ème passage (pui_tr != NULL)
      // on teste pour rien
      if (uh_next_date < self->uh_next_change_date)
	self->uh_next_change_date = uh_next_date;

      break;
    }

    // OK on garde cette répétition
    if (pui_tr != NULL)
      *pui_tr++ = (UInt32)uh_next_date << 16;
    uh_num_repeats++;

    uh_last_date = uh_next_date;
  }

  // Soit on rajoute pui_tr == NULL et on ne fait ce test qu'une
  // fois, soit on laisse et lors du 2ème passage (pui_tr != NULL)
  // on teste pour rien
  if (uh_last_date > self->uh_last_change_date)
    self->uh_last_change_date = uh_last_date;

  return uh_num_repeats;
}


- (void)initRecordsCount
{
  Transaction *oTransactions;
  DmOpenRef db;
  MemHandle pv_tr;
  struct s_transaction *ps_tr;
  PROGRESSBAR_DECL;
  t_amount l_sum;
  UInt16 index, uh_num_records, uh_cur_account;
  UInt16 uh_nb_repeats, uh_nb_next_repeats, uh_max_date, uh_date;
  // Pour optimisation
  UInt16 uh_opt_min;
  Boolean b_sort_by_value_date;

  if (self->vh_infos != NULL)
  {
    MemHandleFree(self->vh_infos);
    self->vh_infos = NULL;
  }

  //
  // Somme des opérations non-répétées pour la première ligne
  oTransactions = [oMaTirelire transaction];

  b_sort_by_value_date = oTransactions->ps_prefs->ul_sort_type;

  db = [oTransactions db];
  uh_cur_account = oTransactions->ps_prefs->ul_cur_category;

  uh_num_records = DmNumRecords(db);

  uh_max_date = DateToInt(((RepeatsListForm*)self->oForm)->s_end_date);

  self->uh_next_change_date = 0xffff;
  self->uh_last_change_date = 0;

  /////////////////////////
  //
  // Première passe de comptage
  PROGRESSBAR_BEGIN(uh_num_records * 2, strProgressBarAccountBalance);

  uh_opt_min = 0;

  l_sum = 0;
  uh_nb_repeats = uh_nb_next_repeats = 0;

  // Pour chaque opération
  index = 0;
  while ((pv_tr = DmQueryNextInCategory(db, &index, uh_cur_account)) // PG
	 != NULL)
  {
    ps_tr = MemHandleLock(pv_tr);

    // Les propriétés du compte
    if (DateToInt(ps_tr->s_date) == 0)
      l_sum += ps_tr->l_amount;
    // Pas les propriétés du compte
    else
    {
      uh_date = (ps_tr->ui_rec_value_date
		 ? DateToInt(value_date_extract(ps_tr))
		 : DateToInt(ps_tr->s_date));

      // Les opérations jusqu'à la date butoir
      if (uh_date <= uh_max_date)
      {
	if (ps_tr->ui_rec_repeat == 0)
	{
	  l_sum += ps_tr->l_amount;

	  if (uh_date > self->uh_last_change_date)
	    self->uh_last_change_date = uh_date;
	}
	// Opération avec répétition
	else
	{
	  if (uh_nb_repeats++ == 0)
	    uh_opt_min = index;

	  // Les répétitions à venir
	  uh_nb_next_repeats += [self numRepeatsFor:ps_tr maxDate:uh_max_date
				      putsIn:NULL];
	}
      }
      // Date hors champ
      else
      {
	if (uh_date < self->uh_next_change_date)
	  self->uh_next_change_date = uh_date;
      }
    }

    MemHandleUnlock(pv_tr);

    index++;

    PROGRESSBAR_INLOOP(index, 50); // OK
  }

  self->l_non_repeats_sum = l_sum;

  self->uh_num_items = 1 + uh_nb_repeats + uh_nb_next_repeats;

  // On peut allouer la place nécessaire
  if (uh_nb_repeats > 0)
  {
    UInt32 *pui_tr, *pui_base;
    UInt16 uh_total, uh_num;

    /////////////////////////
    //
    // Allocation

    uh_total = self->uh_num_items - 1;

    NEW_HANDLE(self->vh_infos, uh_total * sizeof(UInt32),
	       ({ self->uh_num_items = 1; goto end; }));

    /////////////////////////
    //
    // Deuxième passe de stockage

    pui_base = pui_tr = MemHandleLock(self->vh_infos);

    // Pour chaque opération
    for (index = uh_opt_min; uh_nb_repeats > 0; index++)
    {
      pv_tr = DmQueryNextInCategory(db, &index, uh_cur_account);

      ps_tr = MemHandleLock(pv_tr);

      if (DateToInt(ps_tr->s_date) != 0 && ps_tr->ui_rec_repeat)
      {
	uh_date = (ps_tr->ui_rec_value_date
		   ? DateToInt(value_date_extract(ps_tr))
		   : DateToInt(ps_tr->s_date));

	if (uh_date <= uh_max_date)
	{
	  // Si le tri doit être effectué par date d'opération
	  if (b_sort_by_value_date == 0)
	    uh_date = DateToInt(ps_tr->s_date);

	  // La répétition de base
	  *pui_tr++ = ((UInt32)uh_date << 16) | (UInt32)index;

	  // Les répétitions à venir
	  uh_num = [self numRepeatsFor:ps_tr maxDate:uh_max_date
			 putsIn:pui_tr];
	  while (uh_num-- > 0)
	    *pui_tr++ |= 0x8000UL | (UInt32)index;

	  uh_nb_repeats--;
	}
      }

      MemHandleUnlock(pv_tr);

      PROGRESSBAR_INLOOP(uh_num_records + index, 50); // OK
    }

    // Il faut trier par date de valeur
    SysInsertionSort(pui_base, uh_total, sizeof(*pui_base),
		     (CmpFuncPtr)_repeats_cmp, 0);

    MemHandleUnlock(self->vh_infos);

end:
    ;
  }

  PROGRESSBAR_END;

  [super initRecordsCount];
}


// Calcule la somme de toutes les entrées de la liste
- (void)computeSum
{
  t_amount l_sum = self->l_non_repeats_sum;

  if (self->vh_infos != NULL)
  {
    MemHandle pv_tr;
    struct s_transaction *ps_tr;
    UInt32 *pui_tr;
    DmOpenRef db = [oMaTirelire transaction]->db;
    UInt16 index;

    pui_tr = MemHandleLock(self->vh_infos);

    // - 1 car la première ligne qui est la somme des pointés compte
    // dans le nbre de lignes, mais n'est pas présente dans vh_infos
    for (index = self->uh_num_items - 1; index-- > 0; )
    {
      pv_tr = DmQueryRecord(db, (*pui_tr++ & 0x7fffUL));
      ps_tr = MemHandleLock(pv_tr);

      l_sum += ps_tr->l_amount;

      MemHandleUnlock(pv_tr);
    }

    MemHandleUnlock(self->vh_infos);
  }

  self->l_sum = l_sum;
}


- (void)initColumns
{
  self->pf_line_draw = __repeats_trans_draw;

  self->uh_flags = SCROLLLIST_BOTTOP | SCROLLLIST_FULL;

  [super initColumns];
}


- (WinHandle)longClicOnRow:(UInt16)uh_row topLeftIn:(PointType*)pp_win
{
  Transaction *oTransactions;
  UInt32 *pui_tr, ui_tr;
  UInt16 index;

  index = TblGetRowID(self->pt_table, uh_row);

  // La première ligne est la somme des pointés
  if (index == 0)
    return NULL;

  pui_tr = MemHandleLock(self->vh_infos);

  ui_tr = pui_tr[index - 1];

  MemHandleUnlock(self->vh_infos);

  oTransactions = [oMaTirelire transaction];

  // Opération non existante
  if (ui_tr & 0x8000UL)
    return trans_draw_longclic_frame(oTransactions, pp_win,
				     (UInt16)(ui_tr & 0x7FFFUL),
				     TRANS_DRAW_LONGCLIC_FUTURE,
				     (UInt16)(ui_tr >> 16));

  // Opération existante
  return trans_draw_longclic_frame(oTransactions, pp_win,
			      (UInt16)(ui_tr & 0x7FFFUL), 0);
}


- (Boolean)shortClicOnRow:(UInt16)uh_row
		     from:(UInt16)uh_from_x to:(UInt16)uh_to_x
{
  [self clicOnRow:uh_row];

  return true;
}


- (void)clicOnRow:(UInt16)uh_row
{
  UInt32 *pui_tr, ui_tr;
  UInt16 index;

  index = TblGetRowID(self->pt_table, uh_row);

  // La première ligne est la somme des pointés
  if (index == 0)
    return;

  pui_tr = MemHandleLock(self->vh_infos);

  ui_tr = pui_tr[index - 1];

  MemHandleUnlock(self->vh_infos);

  // Opération existante OU BIEN on veut voir l'originale
  if ((ui_tr & 0x8000UL) == 0 || FrmAlert(alertRepeatsViewOrig))
  {
    TransFormCall(((RepeatsListForm*)self->oForm)->s_trans_form,
		  0,
		  0, 0,		// pre_desc
		  0, 0,		// copy
		  (UInt16)(ui_tr & 0x7FFFUL));
  }
}


- (UInt16)_changeHandFillIncObjs:(UInt16*)puh_objs
		 withoutDontDraw:(Boolean)b_without_dont_draw
{
  *puh_objs++ = bmpBack;
  *puh_objs++ = RepeatsListQuit;

  *puh_objs++ = bmpDateUp;
  *puh_objs++ = RepeatsListDateUp;
  *puh_objs++ = bmpDateDown;
  *puh_objs++ = RepeatsListDateDown;

  *puh_objs++ = RepeatsListDate;

  *puh_objs = SumListSum;

  return 2 + 4 + 1 + 1;
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
    UInt32 *pui_tr;
    UInt16 uh_final_cur, uh_index, uh_flags;

    uh_flags = (uh_new_cur & SCROLLLIST_CURRENT_DONT_RELOAD);
    uh_new_cur &= ~SCROLLLIST_CURRENT_DONT_RELOAD;

    uh_final_cur = 0;

    if (self->vh_infos != NULL)
    {
      pui_tr = MemHandleLock(self->vh_infos);

      // = 1 car la première ligne est la somme des pointés
      for (uh_index = 1; uh_index < self->uh_num_items; pui_tr++, uh_index++)
	if ((*pui_tr & 0xffffUL) == uh_new_cur)
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


- (Boolean)getItem:(UInt16*)puh_cur next:(Boolean)b_next
{
  Boolean b_ret = false;

  if (self->vh_infos != NULL)
  {
    UInt32 *pui_tr;
    UInt16 uh_index, uh_last;
    Int16 h_inc;

    pui_tr = MemHandleLock(self->vh_infos);

    for (uh_index = 0; uh_index < self->uh_num_items - 1; pui_tr++, uh_index++)
      if ((*pui_tr & 0xffffUL) == *puh_cur)
      {
	if (b_next)
	{
	  h_inc = 1;
	  uh_last = self->uh_num_items - 2;
	}
	else
	{
	  h_inc = -1;
	  uh_last = 0;
	}

	if (uh_index != uh_last)
	{
	  // On recherche la prochaine opération NON virtuelle
	  do
	  {
	    pui_tr += h_inc;
	    uh_index += h_inc;

	    if ((*pui_tr & 0x8000UL) == 0)
	    {
	      *puh_cur = (*pui_tr & 0xffffUL);
	      b_ret = true;
	      break;
	    }
	  }
	  while (uh_index != uh_last);
	}

	break;
      }

    MemHandleUnlock(self->vh_infos);
  }

  return b_ret;
}


- (void)changeDate:(UInt16)uh_new_date
{
  if (uh_new_date < self->uh_last_change_date
      || uh_new_date >= self->uh_next_change_date)
    [self update];		// OK
}

@end
