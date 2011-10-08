/* 
 * StatsTransAllScrollList.m -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Mon Oct 23 23:10:44 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Dec 11 15:03:00 2007
 * Update Count    : 81
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: StatsTransAllScrollList.m,v $
 * Revision 1.2  2008/01/14 16:12:21  max
 * Handle signed splits (only comments).
 *
 * Revision 1.1  2006/11/04 23:47:52  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_STATSTRANSALLSCROLLLIST
#include "StatsTransAllScrollList.h"

#include "MaTirelire.h"
#include "ExportForm.h"
#include "TransScrollList.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


struct s_stats_trans_split
{
  STRUCT_STATS_TRANS_BASE;
  Int16  h_split_index;		// Index de la sous-op � afficher, ou -1
				// TRANS_DRAW_SPLIT_REMAIN pour le reste
};

@implementation StatsTransAllScrollList

- (Boolean)searchInit:(struct s_search_infos*)ps_infos
{
  // Aucun type n'est recherch� en particulier, inutile de parcourir
  // alors les sous-op�rations
  self->ps_search_trans_infos->b_no_type
    = (ps_infos->s_search_criteria.pul_types == NULL
       && ps_infos->s_search_criteria.h_one_type < 0);

  return [super searchInit:ps_infos];
}


- (void)searchMatch:(struct s_search_infos*)ps_infos addSplit:(Int16)h_split
{
  struct s_stats_trans_split *ps_trans;

  ps_trans = (struct s_stats_trans_split*)self->ps_search_trans_infos->ps_items;

  ps_trans->uh_rec_index = ps_infos->index;
  ps_trans->h_split_index = h_split;

  // On mettra � jour ps_trans->l_amount dans -computeEachEntryConvertSum

  self->ps_search_trans_infos->uh_opt_num--;
  self->ps_search_trans_infos->ps_items
    = (struct s_stats_trans_base*)(ps_trans + 1);
}


// Appel� par -searchFrom:amount:
//
// ps_infos->l_amount est le montant de l'op�ration, dans la monnaie
// de l'op�ration. Le montant complet, pas une somme de
// sous-op�rations, puisque dans cette classe on appelle
// -searchFrom:amount: avec true comme argument pour ne justement pas
// g�rer cette somme...
- (Boolean)searchMatch:(struct s_search_infos*)ps_infos
{
  Boolean b_second_pass = self->ps_search_trans_infos->b_second_pass;

  // Si au moins un type est recherch�
  if (self->ps_search_trans_infos->b_no_type == false
      // ET qu'il y a une ventilation, il faut parcourir toutes les
      //    sous-op�rations pour voir celles qui nous int�ressent
      && ps_infos->ps_tr->ui_rec_splits)
  {
    t_amount l_splits_sum = 0, l_remain_amount, l_orig_amount;
    FOREACH_SPLIT_DECL;

    // Les options n'ont peut-�tre pas �t� calcul�es
    if (ps_infos->s_options.pa_note == NULL)
      options_extract((struct s_transaction*)ps_infos->ps_tr,
		      &ps_infos->s_options);

    // S'il y a une devise, on prend son montant car toutes les
    // sous-op�rations sont dans cette devise
    l_orig_amount = ps_infos->ps_tr->ui_rec_currency
      ? ps_infos->s_options.ps_currency->l_currency_amount
      : ps_infos->ps_tr->l_amount;

    // On parcourt toutes les sous-op�rations, en g�rant le crit�re de
    // recherche sur le type

    //
    // Crit�res pour plusieurs types
    if (ps_infos->s_search_criteria.h_one_type < 0)
    {
      FOREACH_SPLIT(&ps_infos->s_options)
      {
	// Le type correspond
	if (BIT_ISSET(ps_cur_split->ui_type,
		      ps_infos->s_search_criteria.pul_types))
	{
	  if (b_second_pass == false)
	    self->uh_num_items++;
	  else
	    [self searchMatch:ps_infos
		  addSplit:ps_infos->s_options.ps_splits->uh_num - __uh_num -1];
	}

	l_splits_sum += ps_cur_split->l_amount;
      }

      // Reste
      l_remain_amount = ABS(l_orig_amount) - l_splits_sum;

      //
      // S'il y a une ventilation avec un reste nul, le type de l'op�ration
      // n'est pris en compte que si le type n'est pas "Unfiled"
      // Donc s'il n'y a pas de reste ET que le type est "Unfiled", on
      // ignore.
      // � noter que le reste est forc�ment toujours positif !!!
      // l'inverse �tant interdit !!!
      if ((ps_infos->ps_tr->ui_rec_type != TYPE_UNFILED || l_remain_amount > 0)
	  // ET que le type de l'op�ration correspond...
	  && BIT_ISSET(ps_infos->ps_tr->ui_rec_type,
		       ps_infos->s_search_criteria.pul_types))
      {
	if (b_second_pass == false)
	  self->uh_num_items++;
	else
	  [self searchMatch:ps_infos addSplit:TRANS_DRAW_SPLIT_REMAIN];
      }
    }
    //
    // Crit�re pour un seul type : on n'accepte que ce type
    else
    {
      UInt16 uh_type = ps_infos->s_search_criteria.h_one_type;

      FOREACH_SPLIT(&ps_infos->s_options)
      {
	// Le type correspond
	if (ps_cur_split->ui_type == uh_type)
	{
	  if (b_second_pass == false)
	    self->uh_num_items++;
	  else
	    [self searchMatch:ps_infos
		  addSplit:ps_infos->s_options.ps_splits->uh_num - __uh_num -1];
	}

	l_splits_sum += ps_cur_split->l_amount;
      }

      // Le type de l'op�ration correspond, on regarde s'il y a un reste
      if (ps_infos->ps_tr->ui_rec_type == uh_type)
      {
	// Reste
	l_remain_amount = ABS(l_orig_amount) - l_splits_sum;

	//
	// S'il y a une ventilation avec un reste nul, le type de l'op�ration
	// n'est pris en compte que si le type n'est pas "Unfiled"
	// Donc s'il n'y a pas de reste ET que le type est "Unfiled", on
	// ignore.
	// � noter que le reste est forc�ment toujours positif !!!
	// l'inverse �tant interdit !!!
	if (ps_infos->ps_tr->ui_rec_type != TYPE_UNFILED || l_remain_amount > 0)
	{
	  if (b_second_pass == false)
	    self->uh_num_items++;
	  else
	    [self searchMatch:ps_infos addSplit:TRANS_DRAW_SPLIT_REMAIN];
	}
      }
    }

    // Premi�re passe de comptage
    if (b_second_pass == false)
    {
      if (ps_infos->index < self->ps_search_trans_infos->uh_opt_min)
	self->ps_search_trans_infos->uh_opt_min = ps_infos->index;

      return false;
    }
  }
  else
  {
    //
    // Premi�re passe de comptage
    if (b_second_pass == false)
    {
      self->uh_num_items++;

      if (ps_infos->index < self->ps_search_trans_infos->uh_opt_min)
	self->ps_search_trans_infos->uh_opt_min = ps_infos->index;

      return false;
    }

    //
    // Seconde passe de stockage
    //
    [self searchMatch:ps_infos addSplit:-1];
  }

  //
  // Ici on est toujours dans la seconde passe de stockage
  return self->ps_search_trans_infos->uh_opt_num == 0;
}


- (void)computeEachEntryConvertSum
{
  if (self->vh_infos != NULL)
  {
    Transaction *oTransactions = [oMaTirelire transaction];
    struct s_stats_trans_split *ps_trans;
    struct s_transaction *ps_tr;
    struct s_search_infos s_search_infos;
    UInt16 uh_index;

    ps_trans = MemHandleLock(self->vh_infos);

    [self searchInit:&s_search_infos];

    for (uh_index = self->uh_num_items; uh_index-- > 0; ps_trans++)
    {
      ps_tr = [oTransactions getId:ps_trans->uh_rec_index];

      // Le compte de l'op�ration
      DmRecordInfo(oTransactions->db, ps_trans->uh_rec_index,
		   &s_search_infos.uh_account, NULL, NULL);
      s_search_infos.uh_account &= dmRecAttrCategoryMask;

      s_search_infos.ps_tr = ps_tr;
      s_search_infos.l_amount = ps_tr->l_amount;

      // Il s'agit d'une sous-op�ration OU BIEN il y a une devise
      if (ps_trans->h_split_index >= 0 || ps_tr->ui_rec_currency)
      {
	options_extract(ps_tr, &s_search_infos.s_options);

	// Il y a une devise
	if (ps_tr->ui_rec_currency)
	  s_search_infos.l_amount
	    = s_search_infos.s_options.ps_currency->l_currency_amount;

	// Il s'agit d'une sous-op�ration
	if (ps_trans->h_split_index >= 0)
	{
	  FOREACH_SPLIT_DECL;	// ps_cur_split et __uh_num
	  t_amount l_splits_sum;
	  Int16 h_split = ps_trans->h_split_index;

	  // Le reste des sous-op�rations
	  if (h_split >= TRANS_DRAW_SPLIT_REMAIN)
	  {
	    l_splits_sum = 0;

	    FOREACH_SPLIT(&s_search_infos.s_options)
	      l_splits_sum += ps_cur_split->l_amount;

	    if (s_search_infos.l_amount < 0)
	      l_splits_sum = - l_splits_sum;

	    s_search_infos.l_amount -= l_splits_sum;
	  }
	  // Une sous-op�ration particuli�re
	  else
	    FOREACH_SPLIT(&s_search_infos.s_options)
	      if (h_split-- == 0)
	      {
		s_search_infos.l_amount = s_search_infos.l_amount < 0
		  ? - ps_cur_split->l_amount : ps_cur_split->l_amount;
		break;
	      }
	}
      }

      // Conversion dans la devise du formulaire
      [super searchMatch:&s_search_infos];
      ps_trans->l_amount = s_search_infos.l_amount;

      [oTransactions getFree:ps_tr];
    }

    [self searchFree:&s_search_infos];

    MemHandleUnlock(self->vh_infos);
  }

  return [super computeEachEntryConvertSum];
}


//
// Un clic long vient d'�tre d�tect� sur la ligne uh_row
// Renvoie le WinHandle correspondant � la zone � restaurer.
// - uh_row est la ligne de la table qui a subi le clic long ;
// - pp_top_left est l'adresse � laquelle le coin sup�rieur gauche de
//   la zone sauv�e doit �tre stock� (le champ y est initialis� aux
//   cordonn�es du stylet press� � l'appel) ;
- (WinHandle)longClicOnRow:(UInt16)uh_row topLeftIn:(PointType*)pp_win
{
  struct s_stats_trans_split s_trans;
  UInt16 uh_flags;

  // L'op�ration
  [self getRecordInfos:(struct s_stats_trans_base*)&s_trans
	forLine:TblGetRowID(self->pt_table, uh_row)];

  if (s_trans.h_split_index < 0)
    uh_flags = TRANS_DRAW_LONGCLIC_STATS;
  else
    uh_flags = TRANS_DRAW_LONGCLIC_STATS|TRANS_DRAW_LONGCLIC_SPLIT;

  return trans_draw_longclic_frame([oMaTirelire transaction], pp_win,
				   s_trans.uh_rec_index,
				   uh_flags, s_trans.h_split_index);
}
  

- (Boolean)shortClicOnLabelOfRow:(UInt16)uh_row xPos:(UInt16)uh_x
{
  struct s_stats_trans_split s_trans;

  // L'op�ration
  [self getRecordInfos:(struct s_stats_trans_base*)&s_trans
	forLine:TblGetRowID(self->pt_table, uh_row)];

  // Le reste de l'op�ration ?
  if (s_trans.h_split_index >= TRANS_DRAW_SPLIT_REMAIN)
    s_trans.h_split_index = -1;

  TransFormSplitCall(self->u.s_trans_form,
		     0,
		     0, 0,		// pre_desc
		     0, 0,		// copy
		     s_trans.uh_rec_index, s_trans.h_split_index);

  return true;
}


- (UInt16)exportFormat:(Char*)pa_format
{
  if (pa_format != NULL)
    // d = (UInt32)DateType
    // s = char*
    // f = t_amount en 100F
    // b = (UInt32)boolean
    StrCopy(pa_format, "dsfbbb");

  return strExportHeadersStatsTrans;
}


- (void)exportLine:(UInt16)uh_line with:(id)oExportForm
{
  Transaction *oTransactions = [oMaTirelire transaction];
  MemHandle vh_rec;
  struct s_transaction *ps_tr;
  struct s_stats_trans_split s_trans;
  struct s_rec_options s_options;
  UInt32 ui_date, ui_selected, *pul_select;
  UInt16 uh_type;
  Boolean b_free_note = false;

  // L'index, index de la sous-op�ration et montant de l'enregistrement
  [self getRecordInfos:(struct s_stats_trans_base*)&s_trans
	forLine:uh_line];

  vh_rec = DmQueryRecord(oTransactions->db, s_trans.uh_rec_index);
  ps_tr = MemHandleLock(vh_rec);

  // Il ne peut pas y avoir de propri�t�s de compte ici

  // On extrait les options
  options_extract(ps_tr, &s_options);

  if (oTransactions->ps_prefs->ul_list_date && ps_tr->ui_rec_value_date)
    ui_date = DateToInt(s_options.ps_value_date->s_value_date);
  else
    ui_date = DateToInt(ps_tr->s_date);

  uh_type = ps_tr->ui_rec_type;

  // Il s'agit d'une sous-op�ration, mais pas du reste (car dans ce
  // cas type et description sont ceux de l'op�ration elle-m�me)
  if (s_trans.h_split_index >= 0
      && s_trans.h_split_index < TRANS_DRAW_SPLIT_REMAIN)
  {
    FOREACH_SPLIT_DECL;

    FOREACH_SPLIT(&s_options)
      if (s_trans.h_split_index-- == 0)
      {
	s_options.pa_note = ps_cur_split->ra_desc;
	uh_type = ps_cur_split->ui_type;
	break;
      }
  }

  // Pas de note, on met le type
  if (s_options.pa_note[0] == '\0' || oTransactions->ps_prefs->ul_list_type)
  {
    b_free_note = true;
    s_options.pa_note = [[oMaTirelire type] fullNameOfId:uh_type len:NULL];
  }

  // La s�lection
  pul_select = MemHandleLock(self->vh_select);
  ui_selected = BIT_ISSET(uh_line, pul_select);
  MemHandleUnlock(self->vh_select);

  // Dans les stats
  // - point�
  // - marqu�
  // - s�lectionn�
  [(ExportForm*)oExportForm exportLine:NULL,
		ui_date, s_options.pa_note, s_trans.l_amount,
		(UInt32)ps_tr->ui_rec_checked,
		(UInt32)ps_tr->ui_rec_marked,
		ui_selected];

  if (b_free_note)
    MemPtrFree(s_options.pa_note);

  MemHandleUnlock(vh_rec);
}


- (UInt16)oneElementSize
{
  return sizeof(struct s_stats_trans_split);
}


- (void)initDraw:(struct s_stats_trans_draw*)ps_draw
	    from:(struct s_stats_trans_base*)ps_infos
{
  ps_draw->h_split = ((struct s_stats_trans_split*)ps_infos)->h_split_index;

  ps_draw->uh_non_flagged = false;
}

@end
