/* 
 * StatsPeriodScrollList.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Jeu aoû  4 23:37:40 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Jan 22 11:54:02 2008
 * Update Count    : 31
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: StatsPeriodScrollList.m,v $
 * Revision 1.10  2008/02/01 17:21:03  max
 * Null amounts handled differently.
 *
 * Revision 1.9  2008/01/14 16:15:32  max
 * Switch to new mcc.
 * When we ignore null amounts, reset all for each change.
 * Always select the first entry in the short clic popup.
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
 * Revision 1.2  2005/08/28 10:02:34  max
 * Handle types list in search criterias.
 * Correct long clic display bug.
 *
 * Revision 1.1  2005/08/20 13:06:34  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_STATSPERIODSCROLLLIST
#include "StatsPeriodScrollList.h"

#include "MaTirelire.h"
#include "StatsForm.h"
#include "CustomListForm.h"
#include "ProgressBar.h"
#include "ExportForm.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


#define WEEK_MIN_LENGTH		7
#define BIWEEK_MIN_LENGTH	14
#define MONTH_MIN_LENGTH	30
#define QUARTER_MIN_LENGTH	90
#define YEAR_MIN_LENGTH		365

//
// Renvoie le nombre de jours exact que comprend la période (fonction
// du type affichage) incluant le mois passé en paramètre
static UInt16 __period_length(DateType s_beg, UInt16 uh_max_length)
{
  switch (uh_max_length)
  {
  case MONTH_MIN_LENGTH:
    return DaysInMonth(s_beg.month, s_beg.year + firstYear);

  case QUARTER_MIN_LENGTH:
    switch (s_beg.month)
    {
    case 1 ... 3:
      return 31 * 2 + DaysInMonth(2, s_beg.year + firstYear);
    case 4 ... 6:
      return 30 + 31 + 30;
    default:
      return 31 + 30 + 31;
    }

  case YEAR_MIN_LENGTH:
    return 365 - 28 + DaysInMonth(2, s_beg.year + firstYear);

  default:			/* WEEK_MIN_LENGTH & BIWEEK_MIN_LENGTH */
    return uh_max_length;
  }
}


//
// Modifie les dates passées en paramètres pour les faire coller avec
// le type d'affichage (semaine, quinzaine, mois, trimestre ou année)
static void __period_round(DateType *ps_begend, UInt16 uh_max_length)
{
  switch (uh_max_length)
  {
  case QUARTER_MIN_LENGTH:
    switch (ps_begend[0].month)
    {
    case 1 ... 3: ps_begend[0].month = 1; break; /* Janvier - Mars */
    case 4 ... 6: ps_begend[0].month = 4; break; /* Avril - Juin */
    case 7 ... 9: ps_begend[0].month = 7; break; /* Juillet - Septembre */
    default:	  ps_begend[0].month = 10; break; /* Octobre - Décembre */
    }

    switch (ps_begend[1].month)
    {
    case 1 ... 3: ps_begend[1].month = 3; break; /* Janvier - Mars */
    case 4 ... 6: ps_begend[1].month = 6; break; /* Avril - Juin */
    case 7 ... 9: ps_begend[1].month = 9; break; /* Juillet - Septembre */
    default:	  ps_begend[1].month = 12; break; /* Octobre - Décembre */
    }

    /* On continue */

  case MONTH_MIN_LENGTH:
    ps_begend[0].day = 1;
    ps_begend[1].day = DaysInMonth(ps_begend[1].month,
				   ps_begend[1].year + firstYear);
    break;

  case YEAR_MIN_LENGTH:
    ps_begend[0].day = 1;
    ps_begend[0].month = 1;
    ps_begend[1].day = 31;
    ps_begend[1].month = 12;    
    break;

  default:			/* WEEK_MIN_LENGTH & BIWEEK_MIN_LENGTH */
    stats_week_beg_end(ps_begend, uh_max_length == BIWEEK_MIN_LENGTH);
    break;
  }
}


static void __statsperiod_draw(void *pv_table, Int16 h_row, Int16 h_col,
			       RectangleType *prec_bounds)
{
  StatsPeriodScrollList *oCustomScrollList = ScrollListGetPtr(pv_table);
  struct s_stats_period *ps_period_infos;
  Char ra_label[PERIOD_LABEL_MAX_LEN];

  ps_period_infos = MemHandleLock(oCustomScrollList->vh_infos);
  ps_period_infos += TblGetRowID((TableType*)pv_table, h_row);

  [oCustomScrollList fillLabel:ra_label forPeriod:ps_period_infos];

  draw_sum_line(ra_label, ps_period_infos->l_sum, prec_bounds,
		ps_period_infos->b_selected ? DRAW_SUM_SELECTED : 0);

  MemHandleUnlock(oCustomScrollList->vh_infos);
}


@implementation StatsPeriodScrollList

- (StatsPeriodScrollList*)initScrollList:(UInt16)uh_table
				  inForm:(BaseForm*)oForm
				numItems:(UInt16)uh_num_items
			      itemHeight:(UInt16)uh_item_height
{
  // Pour les semaines et les quinzaines, on garde un cache d'infos
  // pour aller plus vite après
  switch ([oMaTirelire transaction]->ps_prefs->rs_stats[0].ui_by)
  {
  case STATS_BY_WEEK:
  case STATS_BY_BIWEEK:
  {
    UInt16 uh_weekStartDay;

    SysCopyStringResource(self->s_week_interval.ra_format,
			  strClistTypePeriodFormat);

    // 0 pour dimanche, 1 pour lundi
    uh_weekStartDay = (UInt16)PrefGetPreference(prefWeekStartDay);
    SysStringByIndex(strClistWeekStartDays, uh_weekStartDay,
		     self->s_week_interval.ra_beg_day,
		     sizeof(self->s_week_interval.ra_beg_day));
    SysStringByIndex(strClistWeekEndDays, uh_weekStartDay,
		     self->s_week_interval.ra_end_day,
		     sizeof(self->s_week_interval.ra_end_day));

    self->s_week_interval.e_date_short
      = (DateFormatType)PrefGetPreference(prefDateFormat);
  }
  break;
  }

  return [super initScrollList:uh_table inForm:oForm
		numItems:uh_num_items
		itemHeight:uh_item_height];
}


// Méthode à appeler lorsque le nombre d'entrées dans la liste a changé
// Alloue le buffer contenant les infos sur les différentes périodes
// Pour chaque période :
// - initialisation de s_beg
// - initialisation de s_end
// - initialisation de b_selected
- (void)initRecordsCount
{
  struct s_stats_prefs *ps_stats_prefs;
  struct s_stats_period *ps_base_period_infos, *ps_period_infos;
  UInt32 ul_days;
  UInt16 ruh_period_length[] =
  {
    WEEK_MIN_LENGTH,
    BIWEEK_MIN_LENGTH,
    MONTH_MIN_LENGTH,
    QUARTER_MIN_LENGTH,
    YEAR_MIN_LENGTH
  };
  DateType rs_period_bounds[2];
#define s_beg_first_period	rs_period_bounds[0]
#define s_end_last_period	rs_period_bounds[1]
  UInt16 uh_nb_max_periods, uh_max_days;

  if (self->vh_infos != NULL)
    MemHandleFree(self->vh_infos);

  ps_stats_prefs = &[oMaTirelire transaction]->ps_prefs->rs_stats[0];

  uh_max_days = ruh_period_length[ps_stats_prefs->ui_by - STATS_BY_WEEK];

  // On calcule l'intervalle qui englobe la période passée en paramètre
  MemMove(rs_period_bounds, ps_stats_prefs->rs_date, sizeof(rs_period_bounds));
  __period_round(rs_period_bounds, uh_max_days);

  // Nombre maximal de périodes : (end - beg + 1 + nb - 1) / nb
  uh_nb_max_periods = (DateToDays(s_end_last_period)
		       - DateToDays(s_beg_first_period) /* + 1 */
		       + uh_max_days /* - 1 */) / uh_max_days;

  // Allocation de la zone
  NEW_HANDLE(self->vh_infos, uh_nb_max_periods * sizeof(struct s_stats_period),
	     ({ self->uh_num_items = 0; return; }));

  ps_period_infos = ps_base_period_infos = MemHandleLock(self->vh_infos);

  ps_period_infos->s_beg = s_beg_first_period;
  ul_days = DateToDays(s_beg_first_period);
  for (;;)
  {
    ps_period_infos->b_selected = 0;

    // Fin de la période
    ul_days += __period_length(ps_period_infos->s_beg, uh_max_days) - 1;
    DateDaysToDate(ul_days, &ps_period_infos->s_end);
    if (DateToInt(ps_period_infos->s_end) == DateToInt(s_end_last_period))
      break;

    // Début de la prochaine période
    ps_period_infos++;
    DateDaysToDate(++ul_days, &ps_period_infos->s_beg);
  }

  self->uh_num_items = (ps_period_infos - ps_base_period_infos) + 1;

  MemHandleUnlock(self->vh_infos);

  if (self->uh_num_items < uh_nb_max_periods)
    // Ici il reste forcément au moins une période
    MemHandleResize(self->vh_infos,
		    self->uh_num_items * sizeof(struct s_stats_period));

  // On passe à papa qui va calculer les sommes de chaque compte
  [super initRecordsCount];
}


// -computeEachEntrySum appelle -computeEachEntryConvertSum dans la
// classe SumScrollList... On laisse faire.


//
// Pour chaque période :
// - initialisation l_sum
// - initialisation uh_num_op
// - initialisation uh_accounts
- (void)computeEachEntryConvertSum
{
  struct s_stats_period *ps_period_infos;
  struct s_private_search_period s_search_infos;
  UInt16 index, uh_new_num;
  Boolean b_ignore_nulls;

  if (self->vh_infos == NULL)
    return;

  // Pour chaque période
  s_search_infos.ps_base_period_infos = s_search_infos.ps_cache
    = ps_period_infos = MemHandleLock(self->vh_infos);

  for (index = 0; index < self->uh_num_items; index++, ps_period_infos++)
  {
    ps_period_infos->l_sum = 0;
    ps_period_infos->uh_num_op = 0;
    ps_period_infos->uh_accounts = 0;
  }

  // Pour notre/nos méthodes appelées durant -search
  self->ps_search_period_infos = &s_search_infos;

  // On fait la recherche...
  b_ignore_nulls = [self searchFrom:0 amount:false];

  // Il faut ignorer les montants nuls (peut-être qu'on l'a déjà fait,
  // dans ce cas c'est pas grave, on ne trouvera rien)
  uh_new_num = self->uh_num_items;
  if (b_ignore_nulls && uh_new_num > 0)
  {
    struct s_stats_period *ps_end_period_infos;

    ps_end_period_infos = s_search_infos.ps_base_period_infos + uh_new_num - 1;

    for (ps_period_infos = ps_end_period_infos;
	 ps_period_infos >= s_search_infos.ps_base_period_infos;
	 ps_period_infos--)
    {
      // Montant nul
      if (ps_period_infos->l_sum == 0)
      {
	// Il faut supprimer cette entrée
	if (ps_period_infos != ps_end_period_infos)
	  MemMove(ps_period_infos, ps_period_infos + 1,
		  (Char*)ps_end_period_infos - (Char*)ps_period_infos);

	uh_new_num--;
	ps_end_period_infos--;
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
		      uh_new_num * sizeof(struct s_stats_period));

    self->uh_num_items = uh_new_num;

    // Au moins un item a été supprimé
    self->b_deleted_items = true;
  }

  // On passe à papa qui va convertir les sommes de chaque periode dans
  // la monnaie demandée...
  [super computeEachEntryConvertSum];
}


// Appelé par -search
- (Boolean)searchMatch:(struct s_search_infos*)ps_infos
{
  struct s_stats_period *ps_cache = self->ps_search_period_infos->ps_cache;

  // On convertit le montant retenu de l'opération dans la monnaie du
  // formulaire
  [super searchMatch:ps_infos];

  // On trouve la bonne période...
  if (ps_infos->uh_date > DateToInt(ps_cache->s_end))
  {
    do
      ps_cache++;
    while (ps_infos->uh_date > DateToInt(ps_cache->s_end));

    self->ps_search_period_infos->ps_cache = ps_cache;
  }
  // La date est inférieure à l'intervalle courant
  else if (ps_infos->uh_date < DateToInt(ps_cache->s_beg))
  {
    do
      ps_cache--;
    while (ps_infos->uh_date < DateToInt(ps_cache->s_beg));

    self->ps_search_period_infos->ps_cache = ps_cache;
  }

  ps_cache->l_sum += ps_infos->l_amount;
  ps_cache->uh_num_op++;
  ps_cache->uh_accounts |= (1 << ps_infos->uh_account);

  return false;
}


//
// - initialise self->l_sum
- (void)computeSum
{
  t_amount l_sum = 0;

  if (self->vh_infos != NULL)
  {
    struct s_stats_period *ps_period_infos;
    UInt16 uh_index, uh_comp;

    ps_period_infos = MemHandleLock(self->vh_infos);

    // Si sum_type == ALL (0)        => -1 ==> 0xffff (XOR 1 != 0 / XOR 0 != 0)
    // Si sum_type == SELECT (1)     => 0
    // Si sum_type == NON_SELECT (2) => 1
    uh_comp = self->uh_sum_filter - 1;

    for (uh_index = self->uh_num_items; uh_index-- > 0; ps_period_infos++)
      if (uh_comp ^ ps_period_infos->b_selected)
	l_sum += ps_period_infos->l_sum;

    MemHandleUnlock(self->vh_infos);
  }

  self->l_sum = l_sum;
}


- (void)initColumns
{
  self->pf_line_draw = __statsperiod_draw;

  self->uh_flags = SCROLLLIST_BOTTOP | SCROLLLIST_FULL;

  [super initColumns];
}


//
// Un clic long vient d'être détecté sur la ligne uh_row
// Pas d'action par défaut => mais pas d'erreur...
// Renvoie le WinHandle correspondant à la zone à restaurer.
// - uh_row est la ligne de la table qui a subit le clic long ;
// - pp_top_left est l'adresse à laquelle le coin supérieur gauche de
//   la zone sauvée doit être stocké (le champ y est initialisé à
//   l'ordonnée du stylet pressé à l'appel) ;
- (WinHandle)longClicOnRow:(UInt16)uh_row topLeftIn:(PointType*)pp_win
{
  struct s_stats_period *ps_period_infos;
  Char ra_label[PERIOD_LABEL_MAX_LEN], *pa_accounts, *pa_cur;
  WinHandle win_handle = NULL;
  RectangleType rec_win;
  UInt16 uh_save_font, uh_hfont, uh_lines, uh_dummy;
  UInt16 uh_accounts_lines, uh_accounts_len, uh_accounts_num;

  ps_period_infos = MemHandleLock(self->vh_infos);
  ps_period_infos += TblGetRowID(self->pt_table, uh_row);

  [self fillLabel:ra_label forPeriod:ps_period_infos];

  pa_accounts = NULL;
  if (ps_period_infos->uh_accounts != 0)
  {
    pa_accounts = [[oMaTirelire transaction]
		    getCategoriesNamesForMask:ps_period_infos->uh_accounts
		    retLen:&uh_accounts_len retNum:&uh_accounts_num];
    if (pa_accounts == NULL)
    {
      // XXX
      goto end;
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

    // On affiche la période
    uh_len = StrLen(ra_label);
    h_width = prepare_truncating(ra_label, &uh_len, rec_win.extent.x - 3 - 2);
    WinDrawTruncatedChars(ra_label, uh_len, rec_win.topLeft.x, uh_y,
			  h_width);
    uh_y += uh_hfont;

    FntSetFont(stdFont);

    // On affiche le nombre d'opérations de la période
    if (ps_period_infos->uh_num_op > 1)
    {
      Char ra_format[32];

      SysCopyStringResource(ra_format, strClistAccountsManyOp);
      StrPrintF(ra_tmp, ra_format, ps_period_infos->uh_num_op);
    }
    else
      SysCopyStringResource(ra_tmp, ps_period_infos->uh_num_op
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

 end:
  MemHandleUnlock(self->vh_infos);

  return win_handle;
}


// uh_x vaut -1 si la méthode est appelée par un événement clavier
- (Boolean)shortClicOnLabelOfRow:(UInt16)uh_row xPos:(UInt16)uh_x
{
  RectangleType s_rect;
  Int16 h_sel_entry;

  // Position en Y de la ligne sélectionnée
  [self getRow:uh_row bounds:&s_rect];

  // On re-sélectionne la ligne
  [self selectRow:uh_row];

  h_sel_entry = [self->oForm contextPopupList:CustomListActionList
		     x:(Int16)uh_x y:s_rect.topLeft.y + s_rect.extent.y
		     selEntry:0]; // Toujours sélection de la 1ère entrée
  if (h_sel_entry != noListSelection)
  {
    struct s_stats_period *ps_period_infos;

    ps_period_infos = MemHandleLock(self->vh_infos);
    ps_period_infos += TblGetRowID(self->pt_table, uh_row);

    // On sauve les dates correspondant à la période dans notre attribut
    self->rs_period_dates[0] = ps_period_infos->s_beg;
    self->rs_period_dates[1] = ps_period_infos->s_end;

    switch (h_sel_entry)
    {
    case 0:			// Refine by transaction type
      FrmPopupForm(CustomListFormIdx | CLIST_SUBFORM_TYPE);
      break;

    case 1:			// Refine by payment mode
      FrmPopupForm(CustomListFormIdx | CLIST_SUBFORM_MODE);
      break;

    case 2:			// View all
      FrmPopupForm(CustomListFormIdx | CLIST_SUBFORM_TRANS_STATS);
      break;
    }

    MemHandleUnlock(self->vh_infos);
  }

  // Désélection de la ligne
  [self unselectRow:uh_row];

  return true;
}


//
// Renvoie -1 si rien n'a bougé
// Renvoie 1 si la somme a été sélectionnée (passage de 0 à 1)
// Renvoie 0 si la somme a été désélectionnée (passage de 1 à 0)
- (Int16)shortClicOnSumOfRow:(UInt16)uh_row xPos:(UInt16)uh_x
		      amount:(t_amount*)pl_amount
{
  struct s_stats_period *ps_period_infos;
  Boolean b_new_select_state;

  ps_period_infos = MemHandleLock(self->vh_infos);
  ps_period_infos += TblGetRowID(self->pt_table, uh_row);

  b_new_select_state = (ps_period_infos->b_selected ^= 1);

  *pl_amount = ps_period_infos->l_sum;

  MemHandleUnlock(self->vh_infos);

  return b_new_select_state;
}


- (void)fillLabel:(Char*)ra_buf
	forPeriod:(struct s_stats_period*)ps_period_infos
{
  UInt16 uh_len;

  switch ([oMaTirelire transaction]->ps_prefs->rs_stats[0].ui_by)
  {
  case STATS_BY_WEEK:
  case STATS_BY_BIWEEK:
  {
    Char ra_date_beg[dateStringLength + 5], ra_date_end[dateStringLength + 5];

    StrCopy(ra_date_beg, self->s_week_interval.ra_beg_day);
    StrCopy(ra_date_end, self->s_week_interval.ra_end_day);

    DateToAscii(ps_period_infos->s_beg.month, ps_period_infos->s_beg.day,
		ps_period_infos->s_beg.year + firstYear,
		self->s_week_interval.e_date_short,
		&ra_date_beg[StrLen(ra_date_beg)]);

    DateToAscii(ps_period_infos->s_end.month, ps_period_infos->s_end.day,
		ps_period_infos->s_end.year + firstYear,
		self->s_week_interval.e_date_short,
		&ra_date_end[StrLen(ra_date_end)]);

    StrPrintF(ra_buf, self->s_week_interval.ra_format,
	      ra_date_beg, ra_date_end);

    // On quitte de suite car on ne veut pas ajouter l'année
    return;
  }

  case STATS_BY_MONTH:
    SysStringByIndex(strLongMonths, ps_period_infos->s_beg.month - 1,
		     ra_buf, PERIOD_LABEL_MAX_LEN - 5);
    break;

  case STATS_BY_QUARTER:
  {
    Char ra_first_month[16], ra_last_month[16];
    Char ra_format[16];

    SysStringByIndex(strLongMonths, ps_period_infos->s_beg.month - 1,
		     ra_first_month, sizeof(ra_first_month));
    SysStringByIndex(strLongMonths, ps_period_infos->s_end.month - 1,
		     ra_last_month, sizeof(ra_last_month));

    SysCopyStringResource(ra_format, strClistTypePeriodFormat);

    StrPrintF(ra_buf, ra_format, ra_first_month, ra_last_month);
  }
  break;

  default:			/* STATS_BY_YEAR */
    SysCopyStringResource(ra_buf, strClistTypeYear);
    break;
  }

  // On ajoute un espace et l'année sur 4 chiffres (ça l'apprendra !)
  uh_len = StrLen(ra_buf);
  ra_buf[uh_len++] = ' ';
  StrIToA(ra_buf + uh_len, ps_period_infos->s_beg.year + firstYear);
}


- (void)selectChange:(Int16)h_action
{
  struct s_stats_period *ps_period_infos;
  UInt16 index;

  if (self->vh_infos == NULL)
    return;

  ps_period_infos = MemHandleLock(self->vh_infos);

  // Invert
  if (h_action < 0)
    for (index = self->uh_num_items; index-- > 0; ps_period_infos++)
      ps_period_infos->b_selected ^= 1;
  // UnsetAll OR SetAll
  else
    for (index = self->uh_num_items; index-- > 0; ps_period_infos++)
      ps_period_infos->b_selected = h_action;

  MemHandleUnlock(self->vh_infos);

  [super selectChange:h_action];
}


- (UInt16)exportFormat:(Char*)pa_format
{
  if (pa_format != NULL)
    StrCopy(pa_format, "sfb");

  return strExportHeadersStatsPeriods;
}


- (void)exportLine:(UInt16)uh_line with:(id)oExportForm
{
  struct s_stats_period *ps_period_infos;
  Char ra_label[PERIOD_LABEL_MAX_LEN];

  ps_period_infos = MemHandleLock(self->vh_infos);
  ps_period_infos += uh_line;

  [self fillLabel:ra_label forPeriod:ps_period_infos];

  [(ExportForm*)oExportForm exportLine:NULL,
		ra_label, ps_period_infos->l_sum,
		(UInt32)ps_period_infos->b_selected];

  MemHandleUnlock(self->vh_infos);
}

@end
