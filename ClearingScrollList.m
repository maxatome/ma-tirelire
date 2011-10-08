/* 
 * ClearingScrollList.m -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Fri Oct  7 22:38:22 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Feb  4 16:43:30 2008
 * Update Count    : 85
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: ClearingScrollList.m,v $
 * Revision 1.13  2008/02/07 14:23:09  max
 * Correct auto-clearing bug...
 *
 * Revision 1.12  2008/02/01 17:11:26  max
 * Make -setCurrentItem: more consistent.
 *
 * Revision 1.11  2008/01/14 17:19:34  max
 * Switch to new mcc.
 * Handle auto-clearing when less than 3 transactions are not cleared.
 * Avoid a crash when no transaction is not cleared.
 *
 * Revision 1.10  2006/11/05 14:22:24  max
 * Don't forget to init s_draw.uh_another_amount.
 *
 * Revision 1.9  2006/11/04 23:47:57  max
 * Handle changes in struct s_stats_trans_draw.
 *
 * Revision 1.8  2006/10/05 19:08:46  max
 * s/Int32/t_amount/g
 * Last sort choice is now saved saved in database preferences.
 *
 * Revision 1.7  2006/06/28 14:22:42  max
 * Add -getItem:next: implementation to handle TransForm next/prev navigation.
 *
 * Revision 1.6  2006/06/28 09:41:41  max
 * s/pt_frm/oForm/g attribute.
 *
 * Revision 1.5  2006/04/25 08:46:14  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.4  2005/11/19 16:56:23  max
 * trans_draw_longclic_frame() and trans_draw_record() calling
 * conventions changed.
 * Click on row via T|T 5-way is now possible.
 * Handle new ClearingAutoConfForm dialog.
 * Add sort by amount.
 *
 * Revision 1.3  2005/10/16 21:44:03  max
 * Add SCROLLLIST_CURRENT_DONT_RELOAD flag handling to -setCurrentItem:
 *
 * Revision 1.2  2005/10/14 22:37:25  max
 * Add auto clearing and sort features.
 *
 * Revision 1.1  2005/10/11 18:27:53  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_CLEARINGSCROLLLIST
#include "ClearingScrollList.h"

#include "ClearingIntroForm.h"
#include "ClearingListForm.h"
#include "StatsTransScrollList.h" // Pour struct s_stats_trans_draw
#include "TransScrollList.h"	  // Pour trans_draw_record()

#include "MaTirelire.h"
#include "ProgressBar.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


#define MAX_AUTOCLEAR_NUM	48

struct s_clear_cmp_args
{
  DmOpenRef db;
  Type *oTypes;
  Mode *oModes;
};

static Int16 _clear_val_date_cmp(UInt16 *puh1, UInt16 *puh2,
				 struct s_clear_cmp_args *ps_args);


static void __clearing_trans_draw(void *pv_table, Int16 h_row, Int16 h_col,
				  RectangleType *prec_bounds)
{
  ClearingScrollList *oClearingScrollList = ScrollListGetPtr(pv_table);
  UInt16 uh_pos;

  uh_pos = TblGetRowID((TableType*)pv_table, h_row);

  // Cas particulier pour la première ligne : somme des pointés
  if (uh_pos == 0)
  {
    Char ra_label[64];

    SysCopyStringResource(ra_label, strClearingListClearedSum);

    // Somme toujours sélectionnée
    draw_sum_line(ra_label, oClearingScrollList->l_checked_sum,
		  prec_bounds, DRAW_SUM_SELECTED | DRAW_SUM_MIN_WIDTH);
  }
  else
  {
    UInt16 *puh_index;
    struct s_stats_trans_draw s_draw;

    // L'index de l'enregistrement
    puh_index = MemHandleLock(oClearingScrollList->vh_infos);

    s_draw.uh_rec_index = puh_index[uh_pos - 1];
    s_draw.h_split = -1;	// Opération complète

    MemHandleUnlock(oClearingScrollList->vh_infos);

    // Faut-il ajouter quelquechose à la description
    switch (oClearingScrollList->uh_sort_type)
    {
    case CLEAR_SORT_BY_MODE:
      s_draw.uh_add_to_desc = TRANS_DRAW_ADD_MODE;
      break;
    case CLEAR_SORT_BY_TYPE:
      s_draw.uh_add_to_desc = TRANS_DRAW_ADD_TYPE;
      break;
    case CLEAR_SORT_BY_CHEQUE_NUM:
      s_draw.uh_add_to_desc = TRANS_DRAW_ADD_CHEQUE;
      break;
    default:
      s_draw.uh_add_to_desc = TRANS_DRAW_ADD_NONE;
      break;
    }

    // Est-il sélectionné ou non ?
    s_draw.uh_selected = false;
    s_draw.uh_select_with_internal_flag = true; // En fonction du internal flag

    // On dessine le marquage
    s_draw.uh_non_flagged = false;

    // Pas l'écran des répétitions
    s_draw.uh_repeat_screen = false;

    // Pas de montant spécial
    s_draw.uh_another_amount = 0;

    // Date de l'opération
    DateToInt(s_draw.s_date) = 0;

    // On peut dessiner la ligne...
    trans_draw_record(&s_draw, h_row, -1, prec_bounds);
  }
}


@implementation ClearingScrollList

- (ClearingScrollList*)free
{
  // Si un auto-pointage était en cours
  [self autoClearingFree:true];

  if (self->vh_infos != NULL)
  {
    [self changeInternalFlag:false stmtNum:0];
    MemHandleFree(self->vh_infos);
  }

  return [super free];
}


// On parcourt tous les enregistrements et on calcule l_checked_sum
- (void)initRecordsCount
{
  Transaction *oTransactions;
  DmOpenRef db;
  MemHandle pv_tr;
  const struct s_transaction *ps_tr;
  PROGRESSBAR_DECL;
  t_amount l_sum;
  UInt16 index, uh_num_records, uh_cur_account, uh_nb_non_cleared;
  // Pour optimisation
  UInt16 uh_opt_min;

  // Le type de tri est dans les préférences de l'application
  self->uh_sort_type = [oMaTirelire getPrefs]->ul_clearing_sort;

  // On annule un éventuel auto pointage en cours, mais on laisse les
  // opérations qui ont été auto-pointées
  [self autoClearingFree:false];

  if (self->vh_infos != NULL)
  {
    MemHandleFree(self->vh_infos);
    self->vh_infos = NULL;
  }

  //
  // Somme des pointés pour la première ligne
  oTransactions = [oMaTirelire transaction];

  db = [oTransactions db];
  uh_cur_account = oTransactions->ps_prefs->ul_cur_category;

  uh_num_records = DmNumRecords(db);

  /////////////////////////
  //
  // Première passe de comptage
  PROGRESSBAR_BEGIN(uh_num_records * 2, strProgressBarAccountBalance);

  uh_opt_min = 0;

  l_sum = 0;
  uh_nb_non_cleared = 0;

  // Pour chaque opération
  index = 0;
  while ((pv_tr = DmQueryNextInCategory(db, &index, uh_cur_account)) // PG
	 != NULL)
  {
    ps_tr = MemHandleLock(pv_tr);

    if (ps_tr->ui_rec_checked)
      l_sum += ps_tr->l_amount;
    else
    {
      if (uh_nb_non_cleared++ == 0)
	uh_opt_min = index;
    }

    MemHandleUnlock(pv_tr);

    index++;

    PROGRESSBAR_INLOOP(index, 50); // OK
  }

  self->l_checked_sum = l_sum;

  self->uh_num_items = 1 + uh_nb_non_cleared;

  // On peut allouer la place nécessaire
  if (uh_nb_non_cleared > 0)
  {
    UInt16 *puh_tr;

    /////////////////////////
    //
    // Allocation

    NEW_HANDLE(self->vh_infos, uh_nb_non_cleared * sizeof(UInt16),
	       ({ self->uh_num_items = 1; goto end; }));

    /////////////////////////
    //
    // Deuxième passe de stockage

    puh_tr = MemHandleLock(self->vh_infos);

    // Pour chaque opération
    for (index = uh_opt_min; uh_nb_non_cleared > 0; index++)
    {
      pv_tr = DmQueryNextInCategory(db, &index, uh_cur_account);

      ps_tr = MemHandleLock(pv_tr);

      if (ps_tr->ui_rec_checked == 0)
      {
	*puh_tr++ = index;
	uh_nb_non_cleared--;
      }

      MemHandleUnlock(pv_tr);

      PROGRESSBAR_INLOOP(uh_num_records + index, 50); // OK
    }

    MemHandleUnlock(self->vh_infos);

    ////////////////////////
    //
    // Enfin on trie
    [self sort];

end:
    ;
  }

  PROGRESSBAR_END;

  [super initRecordsCount];
}


// Calcule la somme de toutes les entrées de la liste
- (void)computeSum
{
  t_amount l_sum = self->l_checked_sum;

  if (self->vh_infos != NULL)
  {
    MemHandle pv_tr;
    struct s_transaction *ps_tr;
    UInt16 *puh_tr;
    DmOpenRef db = [oMaTirelire transaction]->db;
    UInt16 index;

    puh_tr = MemHandleLock(self->vh_infos);

    // - 1 car la première ligne qui est la somme des pointés compte
    // dans le nbre de lignes, mais n'est pas présente dans vh_infos
    for (index = self->uh_num_items - 1; index-- > 0; )
    {
      pv_tr = DmQueryRecord(db, *puh_tr++);
      ps_tr = MemHandleLock(pv_tr);

      if (ps_tr->ui_rec_internal_flag)
	l_sum += ps_tr->l_amount;

      MemHandleUnlock(pv_tr);
    }

    MemHandleUnlock(self->vh_infos);
  }

  if (((ClearingListForm*)self->oForm)->b_left_sum)
    self->l_sum = TARGET_BALANCE - l_sum;
  else
    self->l_sum = l_sum;
}


- (void)initColumns
{
  self->pf_line_draw = __clearing_trans_draw;

  self->uh_flags = SCROLLLIST_BOTTOP | SCROLLLIST_FULL;

  [super initColumns];
}


- (WinHandle)longClicOnRow:(UInt16)uh_row topLeftIn:(PointType*)pp_win
{
  UInt16 *puh_index, index;

  index = TblGetRowID(self->pt_table, uh_row);

  // La première ligne est la somme des pointés
  if (index == 0)
    return NULL;

  puh_index = MemHandleLock(self->vh_infos);

  index = puh_index[index - 1];

  MemHandleUnlock(self->vh_infos);

  return trans_draw_longclic_frame([oMaTirelire transaction], pp_win,
				   index, 0);
}


- (UInt16)amountWidth
{
  return oMaTirelire->s_misc_infos.uh_amount_width;
}


// Renvoie true si le clic a été traité
- (Boolean)shortClicOnLabelOfRow:(UInt16)uh_row xPos:(UInt16)uh_x
{
  [self clicOnRow:uh_row];

  return true;
}


- (void)clicOnRow:(UInt16)uh_row
{
  UInt16 *puh_index, index;

  index = TblGetRowID(self->pt_table, uh_row);

  // La première ligne est la somme des pointés
  if (index == 0)
    return;

  puh_index = MemHandleLock(self->vh_infos);

  index = puh_index[index - 1];

  MemHandleUnlock(self->vh_infos);

  TransFormCall(((ClearingListForm*)self->oForm)->s_trans_form,
		0,
		0, 0,		// pre_desc
		0, 0,		// copy
		index);
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
  union u_rec_flags u_flags;
  UInt16 *puh_index, uh_pos, uh_rec_index;
  Int16 h_ret;

  uh_pos = TblGetRowID(self->pt_table, uh_row);

  // La première ligne est la somme des pointés
  if (uh_pos == 0)
    return -1;

  // On annule un éventuel auto pointage en cours, mais on laisse les
  // opérations qui ont été auto-pointées
  [self autoClearingFree:false];

  uh_pos--;

  puh_index = MemHandleLock(self->vh_infos);
  puh_index += uh_pos;

  uh_rec_index = *puh_index;

  MemHandleUnlock(self->vh_infos);

  ps_tr = [oTransactions recordGetAtId:uh_rec_index];

  //
  // L'état sélectionné ou non
  u_flags = ps_tr->u_flags;
  u_flags.s_bit.ui_internal_flag ^= 1;

  DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
	  &u_flags, sizeof(u_flags));

  if (u_flags.s_bit.ui_internal_flag)
    // On renvoie 3 si sélectionné car on veut que la somme soit
    // complètement redessinée à cause du pointage/marquage
    h_ret = ps_tr->ui_rec_marked ? 3 : 1;
  else
    h_ret = 0;

  *pl_amount = ps_tr->l_amount;

  [oTransactions recordRelease:false]; // On ne positionne pas le bit dirty

  return h_ret;
}


// La somme l_amount vient de changer d'état en b_selected
// Il faut peut-être modifier self->l_sum et si c'est le cas, il faut
// renvoyer true.
// Renvoie true si la somme doit être rafaichie
- (Boolean)addAmount:(t_amount)l_amount selected:(Boolean)b_selected
{
  if (((ClearingListForm*)self->oForm)->b_left_sum ^ b_selected)
    self->l_sum += l_amount;
  else
    self->l_sum -= l_amount;

  return true;
}


- (UInt16)_changeHandFillIncObjs:(UInt16*)puh_objs
		 withoutDontDraw:(Boolean)b_without_dont_draw
{
  *puh_objs++ = bmpBack;
  *puh_objs++ = ClearingListQuit;
  *puh_objs++ = ClearingListNew;

  *puh_objs++ = ClearingListPopup;

  *puh_objs = SumListSum;

  return 3 + 1 + 1; // Boutons + popup + somme
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
    UInt16 *puh_index;
    UInt16 uh_final_cur, uh_index, uh_flags;

    uh_flags = (uh_new_cur & SCROLLLIST_CURRENT_DONT_RELOAD);
    uh_new_cur &= ~SCROLLLIST_CURRENT_DONT_RELOAD;

    uh_final_cur = 0;

    if (self->vh_infos != NULL)
    {
      puh_index = MemHandleLock(self->vh_infos);

      // = 1 car la première ligne est la somme des pointés
      for (uh_index = 1; uh_index < self->uh_num_items; puh_index++, uh_index++)
	if (*puh_index == uh_new_cur)
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
    UInt16 *puh_index, uh_index;

    puh_index = MemHandleLock(self->vh_infos);

    for (uh_index = 0; uh_index < self->uh_num_items - 1;
	 puh_index++, uh_index++)
      if (*puh_index == *puh_cur)
      {
	if (b_next)
	{
	  if (uh_index < self->uh_num_items - 2)
	  {
	    b_ret = true;
	    *puh_cur = puh_index[1];
	  }
	}
	else			// Previous
	{
	  if (uh_index > 0)
	  {
	    b_ret = true;
	    *puh_cur = puh_index[-1];	    
	  }
	}

	break;
      }

    MemHandleUnlock(self->vh_infos);
  }

  return b_ret;
}


- (void)swapSumType
{
  self->l_sum = TARGET_BALANCE - self->l_sum;

  [self displaySum];
}


// Renvoie true si au moins une opération a été "pré-pointée"
- (Boolean)isCleared
{
  MemHandle pv_tr;
  struct s_transaction *ps_tr;
  DmOpenRef db = [oMaTirelire transaction]->db;
  UInt16 *puh_index, index;
  Boolean b_one_cleared;

  if (self->vh_infos == NULL)
    return false;

  b_one_cleared = false;

  // On parcourt toutes les opérations pour regarder le internal flag
  puh_index = MemHandleLock(self->vh_infos);

  for (index = self->uh_num_items - 1; index-- > 0; puh_index++)
  {
    pv_tr = DmQueryRecord(db, *puh_index);
    ps_tr = MemHandleLock(pv_tr);

    if (ps_tr->ui_rec_internal_flag)
    {
      b_one_cleared = true;
      MemHandleUnlock(pv_tr);
      break;
    }

    MemHandleUnlock(pv_tr);
  }  

  MemHandleUnlock(self->vh_infos);

  return b_one_cleared;
}


- (void)changeInternalFlag:(Boolean)b_to_clear stmtNum:(UInt32)ui_stmt_num
{
  Transaction *oTransactions;
  struct s_transaction *ps_tr;
  union u_rec_flags u_flags;
  UInt16 *puh_index, index;

  if (self->vh_infos == NULL)
    return;

  oTransactions = [oMaTirelire transaction];

  // On parcourt toutes les opérations pour virer le internal flag
  puh_index = MemHandleLock(self->vh_infos);

  for (index = self->uh_num_items - 1; index-- > 0; puh_index++)
  {
    ps_tr = [oTransactions recordGetAtId:*puh_index];

    u_flags.s_bit.ui_checked = 0;

    if (ps_tr->ui_rec_internal_flag)
    {
      u_flags = ps_tr->u_flags;
      u_flags.s_bit.ui_internal_flag = 0;
      u_flags.s_bit.ui_checked = b_to_clear;

      DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
	      &u_flags, sizeof(u_flags));
    }

    // On ne positionne le bit dirty que si on transforme en pointé
    [oTransactions recordRelease:b_to_clear];

    // Il y a un numéro de relevé à mettre en place ET on vient de
    // pointer l'opération
    if (ui_stmt_num != 0 && u_flags.s_bit.ui_checked)
      [oTransactions addStmtNumOption:ui_stmt_num forId:*puh_index];
  }

  MemHandleUnlock(self->vh_infos);
}


//
// Renvoie true s'il y a une suite à venir
- (Boolean)autoClearingRunning
{
  return self->ps_autoclear_amounts != NULL;
}


- (Boolean)autoClearingInit
{
  MemHandle pv_tr;
  const struct s_transaction *ps_tr;
  struct s_auto_clearing_op *ps_cur;
  struct s_clear_cmp_args s_sort_args;
  t_amount l_left_sum;
  UInt16 *puh_index, *puh_base;
  DmOpenRef db;
  UInt16 index, uh_num, uh_max_date;

  // Au cas où, mais on laisse les opérations qui ont été auto-pointées
  [self autoClearingFree:false];

  if (self->vh_infos == NULL)
  {
    FrmAlert(alertAutoClearNone);
    return false;
  }

  db = [oMaTirelire transaction]->db;
  puh_index = puh_base = MemHandleLock(self->vh_infos);

  // Nombre d'opération à pointer
  self->uh_autoclear_num_to_clear =
    ((ClearingListForm*)self->oForm)->s_clear_auto_form.uh_num_transactions;

  // Date butoir
  uh_max_date
    = DateToInt(((ClearingListForm*)self->oForm)->s_clear_auto_form.s_date);

  //
  // Nombre d'opérations pas encore pointées dans l'écran
  uh_num = 0;
  for (index = self->uh_num_items - 1; index-- > 0; puh_index++)
  {
    pv_tr = DmQueryRecord(db, *puh_index);
    ps_tr = MemHandleLock(pv_tr);

    // Pas pointé dans l'écran
    if (ps_tr->ui_rec_internal_flag == 0
	// ET date d'opération jusqu'à la date limite
	&& (ps_tr->ui_rec_value_date ? DateToInt(value_date_extract(ps_tr))
	    : DateToInt(ps_tr->s_date)) <= uh_max_date)
      uh_num++;

    MemHandleUnlock(pv_tr);
  }

  // Aucune opération à pointer
  if (uh_num == 0)
  {
    FrmAlert(alertAutoClearNone);
    MemHandleUnlock(self->vh_infos);
    return false;
  }

  // Trop d'opérations à pointer
  if (uh_num > MAX_AUTOCLEAR_NUM)
  {
    FrmAlert(alertAutoClearTooMany);
    MemHandleUnlock(self->vh_infos);
    return false;
  }

  self->uh_autoclear_num_non_cleared = uh_num;

  // Allocation des sommes
  NEW_PTR(self->ps_autoclear_amounts,
	  self->uh_autoclear_num_non_cleared
	  * sizeof(struct s_auto_clearing_op),
	  ({ MemHandleUnlock(self->vh_infos); return false; }));
  ps_cur = self->ps_autoclear_amounts;

  // On stocke les sommes et les index de la liste correspondant
  puh_index = puh_base;
  for (index = 1, uh_num = self->uh_autoclear_num_non_cleared; uh_num > 0;
       puh_index++, index++)
  {
    pv_tr = DmQueryRecord(db, *puh_index);
    ps_tr = MemHandleLock(pv_tr);

    if (ps_tr->ui_rec_internal_flag == 0)
    {
      ps_cur->uh_rec_index = *puh_index;
      ps_cur->l_amount = ps_tr->l_amount;

      ps_cur++;
      uh_num--;
    }

    MemHandleUnlock(pv_tr);
  }

  MemHandleUnlock(self->vh_infos);

  // On trie par ordre croissant de dates de valeur
  s_sort_args.db = db;
  SysInsertionSort(self->ps_autoclear_amounts,
		   self->uh_autoclear_num_non_cleared,
		   sizeof(*self->ps_autoclear_amounts),
		   (CmpFuncPtr)_clear_val_date_cmp, (Int32)&s_sort_args);

  // La somme qu'il faut atteindre en additionnant les non pointés
  if (((ClearingListForm*)self->oForm)->b_left_sum)
    l_left_sum = self->l_sum;
  else
    l_left_sum = TARGET_BALANCE - self->l_sum;

  self->ull_autoclear_checked = 0;

  return true;
}


- (Boolean)autoClearingNext
{
  UInt64 ull_checked, ull_last;
  t_amount l_left_sum;
  struct s_auto_clearing_op *ps_amounts;
  UInt16 index, uh_old_auto_off_time, uh_num_auto_cleared;
  Boolean b_found = true;

  ull_last = (1ULL << self->uh_autoclear_num_non_cleared) - 2;

  // Pour aller plus vite on recopie certains attributs en local
  ps_amounts = self->ps_autoclear_amounts;
  ull_checked = self->ull_autoclear_checked;

  // Nombre d'opérations déjà auto-pointées
  uh_num_auto_cleared = 0;
  for (index = self->uh_autoclear_num_non_cleared; index-- > 0; )
    if (ull_checked & (1ULL << index))
      uh_num_auto_cleared++;

  // Elle le sont toutes ! => rien à faire...
  if (uh_num_auto_cleared == self->uh_autoclear_num_non_cleared)
  {
    // On annule l'auto pointage en cours, mais on laisse les
    // opérations qui ont été auto-pointées
    [self autoClearingFree:false];

    FrmAlert(alertAutoClearNone);
    return false;
  }

  // On prend la somme avant les -autoClearingSetInternalFlag:false
  // car elle va y être modifiée
  if (((ClearingListForm*)self->oForm)->b_left_sum)
    l_left_sum = self->l_sum;
  else
    l_left_sum = TARGET_BALANCE - self->l_sum;

  // On annule le timeout d'extinction auto
  uh_old_auto_off_time = SysSetAutoOffTime(0);

  // Less transactions than 3
  if (self->uh_autoclear_num_non_cleared < 3)
  {
    // On ôte le internal_flag des opérations précédemment auto-pointées
    [self autoClearingSetInternalFlag:false];

    // Il faut redessiner la table
    [self redrawList];

    // Only one transaction...
    if (self->uh_autoclear_num_non_cleared == 1)
    {
      ull_checked ^= 1ULL;

      if (ull_checked)
      {
	l_left_sum -= ps_amounts[0].l_amount;
	uh_num_auto_cleared++;
      }

      if (l_left_sum == 0
	  && (self->uh_autoclear_num_to_clear == 0
	      || uh_num_auto_cleared == self->uh_autoclear_num_to_clear))
	goto ok;
    }
    // Only two transactions...
    else
    {
      ull_last++;
      do
      {
	ull_checked++;

	// La première somme disparaît et la seconde apparaît
	if (ull_checked == 0x2ULL)
	{
	  l_left_sum += ps_amounts[0].l_amount;
	  l_left_sum -= ps_amounts[1].l_amount;
	  // uh_num_auto_cleared ne change pas : - 1 + 1
	}
	// La première somme apparaît (0x1) ou réapparaît (0x2)
	else
	{
	  l_left_sum -= ps_amounts[0].l_amount;
	  uh_num_auto_cleared++;
	}

	if (l_left_sum == 0
	    && (self->uh_autoclear_num_to_clear == 0
		|| uh_num_auto_cleared == self->uh_autoclear_num_to_clear))
	  goto ok;
      }
      while (ull_checked != ull_last);
    }

    goto not_found;
  }

  // On est sur un nombre impair, on est donc en cours de recherche,
  // il faut passer sur le prochain nombre pair
  if (ull_checked & 1)
  {
    // On ôte le internal_flag des opérations précédemment auto-pointées
    [self autoClearingSetInternalFlag:false];

    // Il faut redessiner la table
    [self redrawList];

    [self->oProgressBar restart];

    ull_checked++;

    goto even;
  }

  // On est sur un nombre pair :
  // - soit on est en cours de recherche
  if (ull_checked != 0)
  {
    // On ôte le internal_flag des opérations précédemment auto-pointées
    [self autoClearingSetInternalFlag:false];

    // Il faut redessiner la table
    [self redrawList];

    [self->oProgressBar restart];
  }
  // - soit c'est le premier (0)
  else
    self->oProgressBar
      = [ProgressBar newNumValues:(ull_last >> (MAX_AUTOCLEAR_NUM - 32)) + 1
		      label:strProgressBarAutoClearing];

  // Dans tous les cas il faut passer sur le prochain nombre impair

  goto odd;

  do
  {
    ull_checked += 2;

    //
    // Pair, la première somme disparaît toujours : ....1 => ....0
 even:
    l_left_sum += ps_amounts[0].l_amount;

    switch (ull_checked & 0x7ULL)
    {
      // La deuxième somme apparaît
    default:
      //case 0x2:		// ....001 => ....010
      //case 0x6:		// ....101 => ....110
      l_left_sum -= ps_amounts[1].l_amount;
      // uh_num_auto_cleared ne change pas : - 1 + 1
      break;

      // La deuxième somme disparaît et la 3ème apparaît
    case 0x4:			// ....011 => ....100
      l_left_sum += ps_amounts[1].l_amount;
      l_left_sum -= ps_amounts[2].l_amount;
      uh_num_auto_cleared += -2 + 1;
      break;

      // Les 3 premières sommes disparaissent et une seule apparaît
    case 0:			// ....111 => ....000
      l_left_sum += ps_amounts[1].l_amount + ps_amounts[2].l_amount;
      for (index = 3;; index++)
      {
	if (ull_checked & (1ULL << index))
	{
	  l_left_sum -= ps_amounts[index].l_amount;
	  break;
	}

	l_left_sum += ps_amounts[index].l_amount;
      }
      uh_num_auto_cleared -= index - 1;

      if ((ull_checked & ((1ULL << (MAX_AUTOCLEAR_NUM - 32)) - 1)) == 0)
      {
	// Un événement ?
	if (EvtSysEventAvail(true))
	{
	  // Au cas où il s'agit un clic sur l'écran, on supprime tous
	  // les clics pour ne pas déclencher d'événement à venir dans
	  // le formulaire
	  if (EvtPenQueueSize() > 0)
	    EvtFlushPenQueue();

	  // Comme par hasard, on vient de tomber juste...
	  b_found = (l_left_sum == 0
		     && (self->uh_autoclear_num_to_clear == 0
			 || uh_num_auto_cleared
			 == self->uh_autoclear_num_to_clear));
	  goto ok;
	}

	[self->oProgressBar
	     updateValue:ull_checked >> (MAX_AUTOCLEAR_NUM - 32)];
      }
      break;
    }

    if (l_left_sum == 0
	&& (self->uh_autoclear_num_to_clear == 0
	    || uh_num_auto_cleared == self->uh_autoclear_num_to_clear))
      goto ok;

    //
    // Impair, c'est toujours la première somme qui apparaît
    // ....0 => ....1
 odd:
    l_left_sum -= ps_amounts[0].l_amount;
    uh_num_auto_cleared++;
    if (l_left_sum == 0
	&& (self->uh_autoclear_num_to_clear == 0
	    || uh_num_auto_cleared == self->uh_autoclear_num_to_clear))
    {
      // Comme on incrémente de 2 en 2 et qu'ici on est sur un nombre
      // impair, on rectifie
      ull_checked++;
      goto ok;
    }
  }
  while (ull_checked != ull_last);

not_found:
  // On n'a rien trouvé

  // On remet en place le timeout d'extinction auto
  SysSetAutoOffTime(uh_old_auto_off_time);

  // Ici il n'y a pas d'opérations auto-pointées, puisqu'on les a
  // toutes dépointées à l'entrée dans la méthode
  [self autoClearingFree:false];

  FrmAlert(alertAutoClearNotFound);

  return false;

 ok:
  self->ull_autoclear_checked = ull_checked;

  // On remet en place le timeout d'extinction auto
  SysSetAutoOffTime(uh_old_auto_off_time);

  //
  // On vient de trouver une opportunité
  if (self->oProgressBar != NULL)
    [self->oProgressBar suspend];

  if (b_found)
  {
    [self autoClearingSetInternalFlag:true];
    [self redrawList];
  }

  return true;
}


- (void)autoClearingFree:(Boolean)b_from_free
{
  if (self->ps_autoclear_amounts != NULL)
  {
    MemPtrFree(self->ps_autoclear_amounts);
    self->ps_autoclear_amounts = NULL;

    if (self->oProgressBar != NULL)
    {
      [self->oProgressBar free];
      self->oProgressBar = NULL;
    }

    if (b_from_free == false)
      [(ClearingListForm*)self->oForm autoClearing:false];
  }
}


// Positionne ou ôte le internal_flag des opérations du pointage auto
- (void)autoClearingSetInternalFlag:(Boolean)b_set
{
  Transaction *oTransactions = [oMaTirelire transaction];
  struct s_transaction *ps_tr;
  union u_rec_flags u_flags;
  t_amount l_sum = 0;
  UInt16 index;

  for (index = self->uh_autoclear_num_non_cleared; index-- > 0; )
    if (self->ull_autoclear_checked & (1ULL << index))
    {
      ps_tr = [oTransactions recordGetAtId:
			       self->ps_autoclear_amounts[index].uh_rec_index];

      if (b_set || ps_tr->ui_rec_internal_flag)
      {
	u_flags = ps_tr->u_flags;
	u_flags.s_bit.ui_internal_flag = b_set;

	DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
		&u_flags, sizeof(u_flags));

	l_sum += ps_tr->l_amount;
      }

      [oTransactions recordRelease:false]; // Sans le dirty bit
    }

  // On ajuste la somme
  if (b_set ^ (((ClearingListForm*)self->oForm)->b_left_sum == false))
    l_sum = - l_sum;

  self->l_sum += l_sum;
}


- (Boolean)changeSortType:(UInt16)uh_new_sort_type
{
  if (self->uh_sort_type != uh_new_sort_type)
  {
    self->uh_sort_type = uh_new_sort_type;

    if (self->vh_infos != NULL)
    {
      // On annule un éventuel auto pointage en cours, mais on laisse les
      // opérations qui ont été auto-pointées
      [self autoClearingFree:false];

      [self sort];
      [self loadRecords];
      [self redrawList];
    }

    return true;
  }

  return false;
}


// Tri par date de valeur
static Int16 _clear_val_date_cmp(UInt16 *puh1, UInt16 *puh2,
				 struct s_clear_cmp_args *ps_args)
{
  MemHandle pv1, pv2;
  struct s_transaction *ps1, *ps2;
  Int16 h_ret;

  pv1 = DmQueryRecord(ps_args->db, *puh1);
  pv2 = DmQueryRecord(ps_args->db, *puh2);

  ps1 = MemHandleLock(pv1);
  ps2 = MemHandleLock(pv2);

  h_ret = transaction_val_date_cmp(ps1, ps2, 0, NULL, NULL, NULL);

  MemHandleUnlock(pv1);
  MemHandleUnlock(pv2);

  return h_ret;
}


// Tri par date
static Int16 _clear_date_cmp(UInt16 *puh1, UInt16 *puh2,
			     struct s_clear_cmp_args *ps_args)
{
  MemHandle pv1, pv2;
  struct s_transaction *ps1, *ps2;
  Int16 h_ret;

  pv1 = DmQueryRecord(ps_args->db, *puh1);
  pv2 = DmQueryRecord(ps_args->db, *puh2);

  ps1 = MemHandleLock(pv1);
  ps2 = MemHandleLock(pv2);

  h_ret = transaction_std_cmp(ps1, ps2, 0, NULL, NULL, NULL);

  MemHandleUnlock(pv1);
  MemHandleUnlock(pv2);

  return h_ret;
}


// Tri par mode
static Int16 _clear_mode_cmp(UInt16 *puh1, UInt16 *puh2,
			     struct s_clear_cmp_args *ps_args)
{
  MemHandle pv1, pv2;
  struct s_transaction *ps1, *ps2;
  Int16 h_ret;

  pv1 = DmQueryRecord(ps_args->db, *puh1);
  pv2 = DmQueryRecord(ps_args->db, *puh2);

  ps1 = MemHandleLock(pv1);
  ps2 = MemHandleLock(pv2);

  // Les deux mêmes modes
  if (ps1->ui_rec_mode == ps2->ui_rec_mode)
    // On trie par date de valeur
    h_ret = transaction_val_date_cmp(ps1, ps2, 0, NULL, NULL, NULL);
  else
  {
    struct s_mode *ps_mode1, *ps_mode2;

    ps_mode1 = [ps_args->oModes getId:ps1->ui_rec_mode];
    ps_mode2 = [ps_args->oModes getId:ps2->ui_rec_mode];

    h_ret = StrCaselessCompare(ps_mode1->ra_name, ps_mode2->ra_name);

    [ps_args->oModes getFree:ps_mode2];
    [ps_args->oModes getFree:ps_mode1];
  }

  MemHandleUnlock(pv1);
  MemHandleUnlock(pv2);

  return h_ret;
}


// Tri par type
static Int16 _clear_type_cmp(UInt16 *puh1, UInt16 *puh2,
			     struct s_clear_cmp_args *ps_args)
{
  MemHandle pv1, pv2;
  struct s_transaction *ps1, *ps2;
  Int16 h_ret;

  pv1 = DmQueryRecord(ps_args->db, *puh1);
  pv2 = DmQueryRecord(ps_args->db, *puh2);

  ps1 = MemHandleLock(pv1);
  ps2 = MemHandleLock(pv2);

  // Les deux mêmes types
  if (ps1->ui_rec_type == ps2->ui_rec_type)
    // On trie par date de valeur
    h_ret = transaction_val_date_cmp(ps1, ps2, 0, NULL, NULL, NULL);
  else
  {
    struct s_type *ps_type1, *ps_type2;

    ps_type1 = [ps_args->oTypes getId:ps1->ui_rec_type];
    ps_type2 = [ps_args->oTypes getId:ps2->ui_rec_type];

    h_ret = StrCaselessCompare(ps_type1->ra_name, ps_type2->ra_name);

    [ps_args->oTypes getFree:ps_type2];
    [ps_args->oTypes getFree:ps_type1];
  }

  MemHandleUnlock(pv1);
  MemHandleUnlock(pv2);

  return h_ret;
}


// Tri par numéro de chèque (si aucun en dernier)
static Int16 _clear_cheque_num_cmp(UInt16 *puh1, UInt16 *puh2,
				   struct s_clear_cmp_args *ps_args)
{
  MemHandle pv1, pv2;
  struct s_transaction *ps1, *ps2;
  Int16 h_ret;

  pv1 = DmQueryRecord(ps_args->db, *puh1);
  pv2 = DmQueryRecord(ps_args->db, *puh2);

  ps1 = MemHandleLock(pv1);
  ps2 = MemHandleLock(pv2);

  // Pas de numéro de chèque pour le 1er
  if (ps1->ui_rec_check_num == 0)
  {
    // Ni pour le second
    if (ps2->ui_rec_check_num == 0)
      // On trie par date de valeur
      h_ret = transaction_val_date_cmp(ps1, ps2, 0, NULL, NULL, NULL);
    // Le second a un numéro de chèque, il doit venir avant
    else
      h_ret = 1;
  }
  // Un numéro de chèque pour le 1er
  else
  {
    // Mais pas pour le second, il doit passer après
    if (ps2->ui_rec_check_num == 0)
      h_ret = -1;
    // Tous les deux ont un numéro de chèque
    else
    {
      struct s_rec_options s_options1, s_options2;

      options_extract(ps1, &s_options1);
      options_extract(ps2, &s_options2);

      if (s_options1.ps_check_num->ui_check_num
	  < s_options2.ps_check_num->ui_check_num)
	h_ret = -1;
      else
	h_ret = (s_options1.ps_check_num->ui_check_num
		 > s_options2.ps_check_num->ui_check_num);
    }
  }

  MemHandleUnlock(pv1);
  MemHandleUnlock(pv2);

  return h_ret;
}


// Tri par somme
static Int16 _clear_sum_cmp(UInt16 *puh1, UInt16 *puh2,
			    struct s_clear_cmp_args *ps_args)
{
  MemHandle pv1, pv2;
  struct s_transaction *ps1, *ps2;
  t_amount l1, l2;
  Int16 h_ret;

  pv1 = DmQueryRecord(ps_args->db, *puh1);
  pv2 = DmQueryRecord(ps_args->db, *puh2);

  ps1 = MemHandleLock(pv1);
  ps2 = MemHandleLock(pv2);

  l1 = ps1->l_amount;
  if (l1 < 0)
    l1 = - l1;

  l2 = ps2->l_amount;
  if (l2 < 0)
    l2 = - l2;

  // Les deux mêmes sommes
  if (l1 == l2)
    // On trie par date de valeur
    h_ret = transaction_val_date_cmp(ps1, ps2, 0, NULL, NULL, NULL);
  else
    h_ret = (l1 < l2) ? -1 : 1;

  MemHandleUnlock(pv1);
  MemHandleUnlock(pv2);

  return h_ret;
}


typedef Int16 (*tf_clear_sort)(UInt16*, UInt16*, struct s_clear_cmp_args*);

- (void)sort
{
  const tf_clear_sort rpf_sort[] =
  {
    _clear_val_date_cmp,	// CLEAR_SORT_BY_VAL_DATE
    _clear_date_cmp,		// CLEAR_SORT_BY_DATE
    _clear_mode_cmp,		// CLEAR_SORT_BY_MODE
    _clear_type_cmp,		// CLEAR_SORT_BY_TYPE
    _clear_cheque_num_cmp,	// CLEAR_SORT_BY_CHEQUE_NUM
    _clear_sum_cmp,		// CLEAR_SORT_BY_SUM
  };
  UInt16 *puh_tr;
  struct s_clear_cmp_args s_args;

  s_args.db = [oMaTirelire transaction]->db;
  s_args.oTypes = [oMaTirelire type];
  s_args.oModes = [oMaTirelire mode];

  puh_tr = MemHandleLock(self->vh_infos);

  SysInsertionSort(puh_tr, self->uh_num_items - 1, sizeof(*puh_tr),
		   (CmpFuncPtr)rpf_sort[self->uh_sort_type], (Int32)&s_args);

  MemHandleUnlock(self->vh_infos);
}

@end
