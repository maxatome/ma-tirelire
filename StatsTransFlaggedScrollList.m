/* 
 * StatsTransFlaggedScrollList.m -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Mon Oct 23 23:08:30 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Nov  2 14:37:35 2006
 * Update Count    : 63
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: StatsTransFlaggedScrollList.m,v $
 * Revision 1.1  2006/11/04 23:47:52  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_STATSTRANSFLAGGEDSCROLLLIST
#include "StatsTransFlaggedScrollList.h"

#include "MaTirelire.h"
#include "ExportForm.h"
#include "TransScrollList.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


@implementation StatsTransFlaggedScrollList

// Appelé par -searchFrom:amount: pour chaque opération correspondant
// aux critères de recherche
- (Boolean)searchMatch:(struct s_search_infos*)ps_infos
{
  //
  // Première passe de comptage
  if (self->ps_search_trans_infos->b_second_pass == false)
  {
    self->uh_num_items++;

    if (ps_infos->index < self->ps_search_trans_infos->uh_opt_min)
      self->ps_search_trans_infos->uh_opt_min = ps_infos->index;

    return false;
  }

  //
  // Seconde passe de stockage
  self->ps_search_trans_infos->ps_items->uh_rec_index = ps_infos->index;
  self->ps_search_trans_infos->ps_items++;

  return --self->ps_search_trans_infos->uh_opt_num == 0;
}


- (void)computeEachEntryConvertSum
{
  if (self->vh_infos != NULL)
  {
    Transaction *oTransactions = [oMaTirelire transaction];
    struct s_stats_trans_base *ps_trans;
    struct s_transaction *ps_tr;
    struct s_search_infos s_search_infos;
    UInt16 uh_index;

    ps_trans = MemHandleLock(self->vh_infos);

    // Le compte de l'opération est toujours le même
    s_search_infos.uh_account = oTransactions->ps_prefs->ul_cur_category;

    [self searchInit:&s_search_infos];

    for (uh_index = self->uh_num_items; uh_index-- > 0; ps_trans++)
    {
      ps_tr = [oTransactions getId:ps_trans->uh_rec_index];

      s_search_infos.ps_tr = ps_tr;

      if (ps_tr->ui_rec_currency)
      {
	options_extract(ps_tr, &s_search_infos.s_options);
	s_search_infos.l_amount
	  = s_search_infos.s_options.ps_currency->l_currency_amount;
      }
      else
	s_search_infos.l_amount = ps_tr->l_amount;

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


- (UInt16)accounts
{
  // Toujours le compte courant
  return 1 << [oMaTirelire transaction]->ps_prefs->ul_cur_category;
}


//
// Un clic long vient d'être détecté sur la ligne uh_row
// Renvoie le WinHandle correspondant à la zone à restaurer.
// - uh_row est la ligne de la table qui a subi le clic long ;
// - pp_top_left est l'adresse à laquelle le coin supérieur gauche de
//   la zone sauvée doit être stocké (le champ y est initialisé aux
//   cordonnées du stylet pressé à l'appel) ;
- (WinHandle)longClicOnRow:(UInt16)uh_row topLeftIn:(PointType*)pp_win
{
  struct s_stats_trans_base s_trans;

  // L'opération
  [self getRecordInfos:&s_trans forLine:TblGetRowID(self->pt_table, uh_row)];

  return trans_draw_longclic_frame([oMaTirelire transaction], pp_win,
				   s_trans.uh_rec_index,
				   TRANS_DRAW_LONGCLIC_STATS);
}


- (Boolean)shortClicOnLabelOfRow:(UInt16)uh_row xPos:(UInt16)uh_x
{
  Transaction *oTransactions;
  struct s_transaction *ps_tr;
  struct s_stats_trans_base s_trans;

  // L'opération
  [self getRecordInfos:&s_trans	forLine:TblGetRowID(self->pt_table, uh_row)];

  oTransactions = [oMaTirelire transaction];

  ps_tr = [oTransactions getId:s_trans.uh_rec_index];

  // Propriétés de compte ?
  if (DateToInt(ps_tr->s_date) == 0)
  {
    DmRecordInfo(oTransactions->db, s_trans.uh_rec_index,
		 &self->u.uh_edited_account, NULL, NULL);
    self->u.uh_edited_account &= dmRecAttrCategoryMask;

    FrmPopupForm(AccountPropFormIdx);
  }
  // Opération
  else
  {
    TransFormSplitCall(self->u.s_trans_form,
		       0,
		       0, 0,		// pre_desc
		       0, 0,		// copy
		       s_trans.uh_rec_index, -1);
  }

  [oTransactions getFree:ps_tr];
  
  return true;
}


#define EXPORT_ENDLINE_FLAGS_FMT	"sfbb"

- (UInt16)exportFormat:(Char*)pa_format
{
  if (pa_format != NULL)
    // d = (UInt32)DateType
    // s = char*
    // f = t_amount en 100F
    // b = (UInt32)boolean
    StrCopy(pa_format, "d" EXPORT_ENDLINE_FLAGS_FMT);

  return strExportHeadersFlaggedTrans;
}


- (void)exportLine:(UInt16)uh_line with:(id)oExportForm
{
  Transaction *oTransactions = [oMaTirelire transaction];
  MemHandle vh_rec;
  Char *pa_format;
  struct s_transaction *ps_tr;
  struct s_stats_trans_base s_trans;
  struct s_rec_options s_options;
  UInt32 ui_date, ui_selected, *pul_select;
  Boolean b_free_note = false;

  // L'index de l'enregistrement
  [self getRecordInfos:&s_trans	forLine:uh_line];

  vh_rec = DmQueryRecord(oTransactions->db, s_trans.uh_rec_index);
  ps_tr = MemHandleLock(vh_rec);

  // Dans cet écran, la monnaie du formulaire est la monnaie du compte

  // Propriétés de compte, pas de date
  if (DateToInt(ps_tr->s_date) == 0)
  {
    // e = skip
    // s = char*
    // f = t_amount en 100F
    // b = UInt32 boolean
    pa_format = "e" EXPORT_ENDLINE_FLAGS_FMT;

    ui_date = 0;

    s_options.pa_note = ((struct s_account_prop*)ps_tr)->ra_note;
  }
  else
  {
    pa_format = NULL;

    // On extrait les options
    options_extract(ps_tr, &s_options);

    if (oTransactions->ps_prefs->ul_list_date && ps_tr->ui_rec_value_date)
      ui_date = DateToInt
	(s_options.ps_value_date->s_value_date);
    else
      ui_date = DateToInt(ps_tr->s_date);

    // Pas de note, on met le type
    if (s_options.pa_note[0] == '\0' || oTransactions->ps_prefs->ul_list_type)
    {
      b_free_note = true;
      s_options.pa_note
	= [[oMaTirelire type] fullNameOfId:ps_tr->ui_rec_type len:NULL];
    }
  }

  // La sélection
  pul_select = MemHandleLock(self->vh_select);
  ui_selected = BIT_ISSET(uh_line, pul_select);
  MemHandleUnlock(self->vh_select);

  // Dans l'écran des marqués
  // - pointé
  // - sélectionné
  [(ExportForm*)oExportForm exportLine:pa_format,
		ui_date, s_options.pa_note, s_trans.l_amount,
		(UInt32)ps_tr->ui_rec_checked,
		(UInt32)ui_selected];

  if (b_free_note)
    MemPtrFree(s_options.pa_note);

  MemHandleUnlock(vh_rec);
}


//
// Juste avant de quitter...
- (Boolean)beforeQuitting
{
  if (self->vh_select != NULL)
  {
    Transaction *oTransactions;
    struct s_transaction *ps_tr;
    UInt32 *pul_select;
    struct s_stats_trans_base *ps_trans;
    union u_rec_flags u_flags;
    UInt16 uh_index;
    Boolean b_ask = false;

    oTransactions = [oMaTirelire transaction];

    // On regarde si au moins une entrée n'est plus sélectionnée
    pul_select = MemHandleLock(self->vh_select);
    ps_trans = MemHandleLock(self->vh_infos);

    for (uh_index = 0; uh_index < self->uh_num_items; uh_index++, ps_trans++)
      if (BIT_ISSET(uh_index, pul_select) == 0)
      {
	// On demande s'il faut répercuter
	if (b_ask == false)
	{
	  if (FrmAlert(alertFlaggedUnflag) != 1)
	    break;

	  b_ask = true;

	  // La liste des opérations est modifiée
	  // XXX pas très propre
	  ((MaTiForm*)self->oForm)->ui_update_mati_list
	    |= (frmMaTiUpdateList | frmMaTiUpdateListTransactions);
	}

	// Démarquage de l'opération
	ps_tr = [oTransactions recordGetAtId:ps_trans->uh_rec_index];
	if (ps_tr != NULL)
	{
	  u_flags = ps_tr->u_flags;

	  u_flags.s_bit.ui_marked = 0;

	  DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
		  &u_flags, sizeof(u_flags));

	  [oTransactions recordRelease:true];
	}
      }

    MemHandleUnlock(self->vh_infos);
    MemHandleUnlock(self->vh_select);
  }

  return true;
}


- (UInt16)oneElementSize
{
  return sizeof(struct s_stats_trans_base);
}


- (UChar)initSelectedPattern
{
  return 0xff;
}


- (void)initDraw:(struct s_stats_trans_draw*)ps_draw
	    from:(struct s_stats_trans_base*)ps_infos
{
  ps_draw->h_split = -1;

  // Dans l'écran des marqués, les marqués sont sélectionnés, il ne
  // faut donc pas les marquer en plus
  ps_draw->uh_non_flagged = true;
}

@end
