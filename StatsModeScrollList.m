/* 
 * StatsModeScrollList.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Dim aoû  7 10:36:31 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Jan 22 11:51:41 2008
 * Update Count    : 47
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: StatsModeScrollList.m,v $
 * Revision 1.10  2008/02/01 17:20:21  max
 * Null amounts handled differently.
 *
 * Revision 1.9  2008/01/14 16:18:17  max
 * When we ignore null amounts, reset all for each change.
 *
 * Revision 1.8  2006/10/05 19:09:00  max
 * Search totally reworked using CustomScrollList genericity.
 *
 * Revision 1.7  2006/06/28 09:41:41  max
 * s/pt_frm/oForm/g attribute.
 *
 * Revision 1.6  2006/04/25 08:46:15  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.5  2005/10/11 19:12:00  max
 * Export feature added.
 *
 * Revision 1.4  2005/08/31 19:43:08  max
 * Does not take account properties into account anymore.
 *
 * Revision 1.3  2005/08/31 19:38:52  max
 * *** empty log message ***
 *
 * Revision 1.2  2005/08/28 10:02:33  max
 * Rework -initRecordsCount to consume less memory.
 * Handle types list in search criterias.
 * Correct long clic display bug.
 * When short clic on a mode with is no transaction behind, display the
 * long clic message.
 *
 * Revision 1.1  2005/08/20 13:06:34  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_STATSMODESCROLLLIST
#include "StatsModeScrollList.h"

#include "MaTirelire.h"
#include "Mode.h"

#include "CustomListForm.h"
#include "StatsPeriodScrollList.h"
#include "ProgressBar.h"
#include "ExportForm.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


static void __statsmode_draw(void *pv_table, Int16 h_row, Int16 h_col,
			     RectangleType *prec_bounds)
{
  StatsModeScrollList *oCustomScrollList = ScrollListGetPtr(pv_table);
  Mode *oModes;
  struct s_mode *ps_mode;
  struct s_stats_mode *ps_mode_infos;

  ps_mode_infos = MemHandleLock(oCustomScrollList->vh_infos);
  ps_mode_infos += TblGetRowID((TableType*)pv_table, h_row);

  oModes = [oMaTirelire mode];

  ps_mode = [oModes getId:ps_mode_infos->uh_id];

  draw_sum_line(ps_mode->ra_name, ps_mode_infos->l_sum, prec_bounds,
		ps_mode_infos->uh_selected ? DRAW_SUM_SELECTED : 0);

  [oModes getFree:ps_mode];

  MemHandleUnlock(oCustomScrollList->vh_infos);
}


@implementation StatsModeScrollList

// Méthode à appeler lorsque le nombre d'entrées dans la liste a changé
// Alloue le buffer contenant les infos sur les modes
// Pour chaque mode :
// - initialisation de uh_id
// - initialisation de uh_selected
- (void)initRecordsCount
{
  Mode *oModes;
  MemHandle pv_mode;
  struct s_stats_mode *ps_mode_infos;
  UInt16 index, uh_num_allocated, uh_num_records;

  if (self->vh_infos != NULL)
    MemHandleFree(self->vh_infos);

  oModes = [oMaTirelire mode];

  uh_num_records = DmNumRecords(oModes->db);

  uh_num_allocated = uh_num_records + 1;
  if (uh_num_allocated > NUM_MODES)
    uh_num_allocated = NUM_MODES;

  NEW_HANDLE(self->vh_infos, uh_num_allocated *sizeof(struct s_stats_mode),
	     ({ self->uh_num_items = 0; return; }));

  ps_mode_infos = MemHandleLock(self->vh_infos);

  // Inutile d'initialiser la zone, ça sera fait dans
  // -computeEachEntryConvertSum

  // Parcours de tous les modes
  self->uh_num_items = 1;		// Au moins "Unknown"

  for (index = 0; index < uh_num_records; index++)
  {
    pv_mode = DmQueryRecord(oModes->db, index);
    if (pv_mode != NULL)
    {
      ps_mode_infos->uh_id = ((struct s_mode*)MemHandleLock(pv_mode))->ui_id;
      ps_mode_infos->uh_selected = 0;
      MemHandleUnlock(pv_mode);

      ps_mode_infos++;
      self->uh_num_items++;
    }
  }

  // Et le mode "Unknown"
  ps_mode_infos->uh_id = MODE_UNKNOWN;
  ps_mode_infos->uh_selected = 0;

  MemHandleUnlock(self->vh_infos);

  if (self->uh_num_items < uh_num_allocated)
    MemHandleResize(self->vh_infos,
		    self->uh_num_items * sizeof(struct s_stats_mode));

  // On passe à papa qui va calculer les sommes de chaque mode
  [super initRecordsCount];
}


// -computeEachEntrySum appelle -computeEachEntryConvertSum dans la
// classe SumScrollList... On laisse faire.


//
// Pour chaque mode :
// - initialisation l_sum
// - initialisation uh_num_op
// - initialisation uh_accounts
- (void)computeEachEntryConvertSum
{
  struct s_stats_mode *ps_mode_infos;
  struct s_private_search_mode s_search_infos;
  UInt16 index, uh_new_num;
  Boolean b_ignore_nulls;

  if (self->vh_infos == NULL)
    return;

  // Zone de correspondance ID du mode -> index dans la liste
  MemSet(s_search_infos.rua_id2list, sizeof(s_search_infos.rua_id2list), '\0');

  // Pour chaque mode
  s_search_infos.ps_base_mode_infos
    = ps_mode_infos = MemHandleLock(self->vh_infos);

  for (index = 0; index < self->uh_num_items; index++, ps_mode_infos++)
  {
    ps_mode_infos->l_sum = 0;
    ps_mode_infos->uh_num_op = 0;
    ps_mode_infos->uh_accounts = 0;

    s_search_infos.rua_id2list[ps_mode_infos->uh_id] = index;
  }

  // Pour notre/nos méthodes appelées durant -search
  self->ps_search_mode_infos = &s_search_infos;

  // On fait la recherche...
  b_ignore_nulls = [self searchFrom:0 amount:false];

  // Il faut ignorer les montants nuls (peut-être qu'on l'a déjà fait,
  // dans ce cas c'est pas grave, on ne trouvera rien)
  uh_new_num = self->uh_num_items;
  if (b_ignore_nulls && uh_new_num > 0)
  {
    struct s_stats_mode *ps_end_mode_infos;

    ps_end_mode_infos = s_search_infos.ps_base_mode_infos + uh_new_num - 1;

    for (ps_mode_infos = ps_end_mode_infos;
	 ps_mode_infos >= s_search_infos.ps_base_mode_infos; ps_mode_infos--)
    {
      // Montant nul
      if (ps_mode_infos->l_sum == 0)
      {
	// Il faut supprimer cette entrée
	if (ps_mode_infos != ps_end_mode_infos)
	  MemMove(ps_mode_infos, ps_mode_infos + 1,
		  (Char*)ps_end_mode_infos - (Char*)ps_mode_infos);

	uh_new_num--;
	ps_end_mode_infos--;
      }
    }
  }

  MemHandleUnlock(self->vh_infos);

  // On peut réduire la taille du buffer. On se met après le
  // MemHandleUnlock, ça permet de libérer la zone si on est à 0
  if (uh_new_num < self->uh_num_items)
  {
    // Plus rien, on libère...
    if (uh_new_num == 0)
    {
      MemHandleFree(self->vh_infos);
      self->vh_infos = NULL;
    }
    else
      MemHandleResize(self->vh_infos,
		      uh_new_num * sizeof(struct s_stats_mode));

    self->uh_num_items = uh_new_num;

    // Au moins un item a été supprimé
    self->b_deleted_items = true;
  }

  // On passe à papa qui va convertir les sommes de chaque mode dans
  // la monnaie demandée...
  [super computeEachEntryConvertSum];
}


// Appelé par -searchFrom:amount:
- (Boolean)searchMatch:(struct s_search_infos*)ps_infos
{
  struct s_stats_mode *ps_mode_infos;

  // On convertit le montant retenu de l'opération dans la monnaie du
  // formulaire
  [super searchMatch:ps_infos];

  // On ajoute le montant de cette opération aux infos de son mode
#define idx \
	self->ps_search_mode_infos->rua_id2list[ps_infos->ps_tr->ui_rec_mode]
  ps_mode_infos = &self->ps_search_mode_infos->ps_base_mode_infos[idx];
#undef idx

  ps_mode_infos->l_sum += ps_infos->l_amount;
  ps_mode_infos->uh_num_op++;
  ps_mode_infos->uh_accounts |= (1 << ps_infos->uh_account);

  return false;
}


//
// - initialise self->l_sum
- (void)computeSum
{
  t_amount l_sum = 0;

  if (self->vh_infos != NULL)
  {
    struct s_stats_mode *ps_mode_infos;
    UInt16 uh_index, uh_comp;

    ps_mode_infos = MemHandleLock(self->vh_infos);

    // Si sum_type == ALL (0)        => -1 ==> 0xffff (XOR 1 != 0 / XOR 0 != 0)
    // Si sum_type == SELECT (1)     => 0
    // Si sum_type == NON_SELECT (2) => 1
    uh_comp = self->uh_sum_filter - 1;

    for (uh_index = self->uh_num_items; uh_index-- > 0; ps_mode_infos++)
      if (uh_comp ^ ps_mode_infos->uh_selected)
	l_sum += ps_mode_infos->l_sum;

    MemHandleUnlock(self->vh_infos);
  }

  self->l_sum = l_sum;
}


- (void)initColumns
{
  self->pf_line_draw = __statsmode_draw;

  self->uh_flags = SCROLLLIST_BOTTOP | SCROLLLIST_FULL;

  [super initColumns];
}


//
// Un clic long vient d'être détecté sur la ligne uh_row
// Pas d'action par défaut => mais pas d'erreur...
// Renvoie le WinHandle correspondant à la zone à restaurer.
// - uh_row est la ligne de la table qui a subit le clic long ;
// - pp_top_left est l'adresse à laquelle le coin supérieur gauche de
//   la zone sauvée doit être stocké (le champ y est initialisé aux
//   cordonnées du stylet pressé à l'appel) ;
- (WinHandle)longClicOnRow:(UInt16)uh_row topLeftIn:(PointType*)pp_win
{
  Mode *oModes;
  struct s_stats_mode *ps_mode_infos;
  Char *pa_fullname, *pa_accounts, *pa_cur;
  WinHandle win_handle = NULL;
  RectangleType rec_win;
  UInt16 uh_save_font, uh_hfont, uh_lines, uh_dummy;
  UInt16 uh_mode_len, uh_accounts_lines, uh_accounts_len, uh_accounts_num;

  ps_mode_infos = MemHandleLock(self->vh_infos);
  ps_mode_infos += TblGetRowID(self->pt_table, uh_row);

  oModes = [oMaTirelire mode];
  pa_fullname = [oModes fullNameOfId:ps_mode_infos->uh_id len:&uh_mode_len];
  if (pa_fullname == NULL)
  {
    // XXX
    goto end2;
  }

  pa_accounts = NULL;
  if (ps_mode_infos->uh_accounts != 0)
  {
    pa_accounts = [[oMaTirelire transaction]
		    getCategoriesNamesForMask:ps_mode_infos->uh_accounts
		    retLen:&uh_accounts_len retNum:&uh_accounts_num];
    if (pa_accounts == NULL)
    {
      // XXX
      goto end1;
    }
  }

  WinGetWindowExtent(&rec_win.extent.x, &uh_dummy);

  uh_save_font = FntSetFont(stdFont);

  uh_accounts_lines =
    pa_accounts ? FldCalcFieldHeight(pa_accounts,rec_win.extent.x - 3 - 2) : 0;

  FntSetFont(boldFont);

  uh_hfont = FntLineHeight();

  uh_lines = 1 + 1 + uh_accounts_lines;

  win_handle = DrawFrame(pp_win, &uh_lines, uh_hfont, &rec_win,
			 oMaTirelire->uh_color_enabled);
  if (win_handle != NULL)
  {
    Char ra_tmp[32];
    UInt16 uh_y, uh_len;
    Int16 h_width;

    // Pour le reste, on réduit les lignes de comptes
    // XXX pas propre car certains comptes ne vont plus apparaître XXX
    uh_accounts_lines = uh_lines - 1 - 1;

    uh_y = rec_win.topLeft.y;

    // On affiche le mode
    h_width = prepare_truncating(pa_fullname, &uh_mode_len,
				 rec_win.extent.x - 3 - 2);
    WinDrawTruncatedChars(pa_fullname, uh_mode_len, rec_win.topLeft.x, uh_y,
			  h_width);
    uh_y += uh_hfont;

    FntSetFont(stdFont);

    // On affiche le nombre d'opérations du mode
    if (ps_mode_infos->uh_num_op > 1)
    {
      Char ra_format[32];

      SysCopyStringResource(ra_format, strClistAccountsManyOp);
      StrPrintF(ra_tmp, ra_format, ps_mode_infos->uh_num_op);
    }
    else
      SysCopyStringResource(ra_tmp, ps_mode_infos->uh_num_op
                            ? strClistAccountsOneOp : strClistAccountsZeroOp);

    WinDrawChars(ra_tmp, StrLen(ra_tmp), rec_win.topLeft.x, uh_y);

    // On affiche les comptes
    if (pa_accounts)
    {
      pa_cur = pa_accounts;
      while (uh_accounts_lines-- > 0)
      {
	uh_y += uh_hfont;
	uh_len = FldWordWrap(pa_cur, rec_win.extent.x - 2);
	if (uh_len > 0)
	{
	  WinDrawChars(pa_cur, uh_len - (pa_cur[uh_len - 1] == '\n'),
		       rec_win.topLeft.x, uh_y);
	  pa_cur += uh_len;
	}
      }
    }

    // Sauvé par DrawFrame()
    if (oMaTirelire->uh_color_enabled)
      WinPopDrawState();
  }

  FntSetFont(uh_save_font);

  if (pa_accounts)
    MemPtrFree(pa_accounts);

 end1:
  MemPtrFree(pa_fullname);

 end2:
  MemHandleUnlock(self->vh_infos);

  return win_handle;
}


- (Boolean)shortClicOnLabelOfRow:(UInt16)uh_row xPos:(UInt16)uh_x
{
  struct s_stats_mode *ps_mode_infos;

  ps_mode_infos = MemHandleLock(self->vh_infos);
  ps_mode_infos += TblGetRowID(self->pt_table, uh_row);

  if (ps_mode_infos->uh_num_op > 0)
  {
    self->uh_mode = ps_mode_infos->uh_id;
    MemHandleUnlock(self->vh_infos);

    FrmPopupForm(CustomListFormIdx | CLIST_SUBFORM_TRANS_STATS);
  }
  else
  {
    MemHandleUnlock(self->vh_infos);

    // Les infos du clic long
    [self displayLongClicInfoWithTimeoutForRow:uh_row timeout:0];
  }


  return true;
}


//
// Renvoie -1 si rien n'a bougé
// Renvoie 1 si la somme a été sélectionnée (passage de 0 à 1)
// Renvoie 3 si pareil mais qu'il faut redessiner la somme complètement
// Renvoie 0 si la somme a été désélectionnée (passage de 1 à 0)
- (Int16)shortClicOnSumOfRow:(UInt16)uh_row xPos:(UInt16)uh_x
		      amount:(t_amount*)pl_amount
{
  struct s_stats_mode *ps_mode_infos;
  Boolean b_new_select_state;

  ps_mode_infos = MemHandleLock(self->vh_infos);
  ps_mode_infos += TblGetRowID(self->pt_table, uh_row);

  b_new_select_state = (ps_mode_infos->uh_selected ^= 1);

  *pl_amount = ps_mode_infos->l_sum;

  MemHandleUnlock(self->vh_infos);

  return b_new_select_state;
}


- (void)selectChange:(Int16)h_action
{
  struct s_stats_mode *ps_mode_infos;
  UInt16 index;

  if (self->vh_infos == NULL)
    return;

  ps_mode_infos = MemHandleLock(self->vh_infos);

  // Invert
  if (h_action < 0)
    for (index = self->uh_num_items; index-- > 0; ps_mode_infos++)
      ps_mode_infos->uh_selected ^= 1;
  // UnsetAll OR SetAll
  else
    for (index = self->uh_num_items; index-- > 0; ps_mode_infos++)
      ps_mode_infos->uh_selected = h_action;

  MemHandleUnlock(self->vh_infos);

  [super selectChange:h_action];
}


- (UInt16)exportFormat:(Char*)pa_format
{
  if (pa_format != NULL)
    StrCopy(pa_format, "sfb");

  return strExportHeadersStatsMode;
}


- (void)exportLine:(UInt16)uh_line with:(id)oExportForm
{
  Mode *oModes;
  struct s_mode *ps_mode;
  struct s_stats_mode *ps_mode_infos;

  ps_mode_infos = MemHandleLock(self->vh_infos);
  ps_mode_infos += uh_line;

  oModes = [oMaTirelire mode];

  ps_mode = [oModes getId:ps_mode_infos->uh_id];

  [(ExportForm*)oExportForm exportLine:NULL,
		ps_mode->ra_name, ps_mode_infos->l_sum,
		(UInt32)ps_mode_infos->uh_selected];

  [oModes getFree:ps_mode];

  MemHandleUnlock(self->vh_infos);
}

@end
