/* 
 * StatsForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Dim mar 27 22:41:00 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Dec 11 16:36:07 2007
 * Update Count    : 35
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: StatsForm.m,v $
 * Revision 1.9  2008/01/14 16:20:26  max
 * Switch to new mcc.
 * Import bound date status when coming from mini stats screen.
 * In LstSetSelection: s/noListSelection/0/g.
 *
 * Revision 1.8  2006/11/04 23:48:14  max
 * Can now be called by MiniStatsForm.
 * Handle unsorted dates.
 *
 * Revision 1.7  2006/10/05 19:14:27  max
 * The two dates can now be bound (choice saved in stats preferences as
 * other fields are).
 * Accounts selection differ a tiny bit.
 *
 * Revision 1.6  2006/07/06 15:52:31  max
 * Do some cleaning.
 *
 * Revision 1.5  2005/10/06 19:48:17  max
 * Source change.
 *
 * Revision 1.4  2005/10/03 20:32:27  max
 * On popup always selected first entry. Corrected.
 * Last and Last but one month in Between popup gave incorrect month. Corrected.
 *
 * Revision 1.3  2005/08/28 10:02:27  max
 * Handle types list in search criterias.
 *
 * Revision 1.2  2005/08/20 13:07:02  max
 * The screen is now fully updatable.
 * Add "On flagged" case.
 * When "All" is selected, take the date of the last valid transaction
 * instead of today one.
 * The form is now initialized with the last used statistics criteria.
 * Add -applyPrevStat:, -initOldestYear and initAccountsPopup: methods.
 *
 * Revision 1.1  2005/05/08 12:12:46  max
 * First import.
 *
 * ==================== RCS ==================== */

#include <PalmOSGlue/LstGlue.h>
#include <PalmOSGlue/TxtGlue.h>

#define EXTERN_STATSFORM
#include "StatsForm.h"

#include "MaTirelire.h"
#include "AccountsListForm.h"
#include "CustomListForm.h"
#include "MiniStatsForm.h"

#include "graph_defs.h"
#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX



// All item selected...
#define chooseAll \
	({ self->uh_menu_choice = STATS_MENU_ALL; \
	   self->uh_week_bounds = 0; })


// On conserve l'info de semaine, seulement si il y a déjà un
// choix en cours
#define chooseWeekBegEnd \
	({ \
	  stats_week_beg_end(self->rs_date, false); \
	  if (self->uh_menu_choice != STATS_MENU_NONE) \
	    self->uh_week_bounds = 1; \
	})


// Nombre de caractères max pour un nom de comptedans le popup des
// stats précédentes
#define ACC_TRUNC	3

struct s_prev_stats
{
  DmOpenRef db;
  struct s_stats_prefs *ps_stats;
  Char ra_buf[15		// Date || menu choice
	      + 15		// Date || rounded to week
	      + 1		// space
	      + 1 + 1		// By shortcut + space
	      + 2 + 1		// Type & mode shortcut + space
	      + 1 + 1		// Debit || credit shortcut + space
	      + (ACC_TRUNC * sizeof(WChar)) + 1
				// Account name (3 chars) + ellipsis
	      + 1		// space
	      + 2 + 1];		// Valuable date + ignore nulls + \0
};

static UInt16 __prev_stats_prepare(struct s_prev_stats *ps_prev,
				   UInt16 uh_stat)
{
  struct s_stats_prefs *ps_stats = &ps_prev->ps_stats[uh_stat];
  Char *pa_cur = ps_prev->ra_buf;
  UInt16 index, uh_accounts, uh_last_account;

  // Les dates...
  if (ps_stats->ui_menu_choice == STATS_MENU_NONE
      || ps_stats->ui_menu_choice > STATS_MENU_ALL)
  {
    DateFormatType e_date_fmt;

    e_date_fmt = (DateFormatType)PrefGetPreference(prefDateFormat);

    DateToAscii(ps_stats->rs_date[0].month, ps_stats->rs_date[0].day,
		ps_stats->rs_date[0].year + firstYear,
		e_date_fmt, pa_cur);

    pa_cur += StrLen(pa_cur);
    *pa_cur++ = ' ';

    DateToAscii(ps_stats->rs_date[1].month, ps_stats->rs_date[1].day,
		ps_stats->rs_date[1].year + firstYear,
		e_date_fmt, pa_cur);

    pa_cur += StrLen(pa_cur);
  }
  else
  {
    SysStringByIndex(strStatsBetweenListShortCut, ps_stats->ui_menu_choice - 1,
		     pa_cur, 16);

    pa_cur += StrLen(pa_cur);

    if (ps_stats->ui_week_bounds)
    {
      SysStringByIndex(strStatsBetweenListShortCut, STATS_MENU_WEEK_POS,
		       pa_cur, 16);
      pa_cur += StrLen(pa_cur);
    }
  }

  *pa_cur++ = '/';

  // By...
  SysCopyStringResource(pa_cur, strStatsByListShortCut);
  *pa_cur++ = pa_cur[ps_stats->ui_by];

  *pa_cur++ = ' ';

  // Un mode et/ou un type
  if (ps_stats->ui_type_any == 0 || ps_stats->ui_mode_any == 0)
  {
    *pa_cur++ = ps_stats->ui_type_any ? '.' : '*';
    *pa_cur++ = ps_stats->ui_mode_any ? '.' : '*';
    *pa_cur++ = ' ';
  }

  // On...
  if (ps_stats->ui_on)
  {
    switch (ps_stats->ui_on)
    {
    case STATS_ON_DEBITS:  *pa_cur++ = '-'; break;
    case STATS_ON_CREDITS: *pa_cur++ = '+'; break;
    case STATS_ON_FLAGGED: *pa_cur++ = '^'; break;
    }
    *pa_cur++ = ' ';
  }

  // Account(s)
  uh_accounts = 0;
  uh_last_account = 0;
  for (index = 0; index < 16; index++)
    if (ps_stats->uh_checked_accounts & (1 << index))
    {
      uh_accounts++;
      uh_last_account = index;
    }

  // Trois premières lettres du compte
  if (uh_accounts == 1)
  {
    Char ra_account[dmCategoryLength];
    WChar wa_chr;
    UInt16 uh_size, uh_len;

    CategoryGetName(ps_prev->db, uh_last_account, ra_account);

    // On fait un tour de plus pour voir si le (ACC_TRUNC+1)-ème
    // caractère n'est pas \0
    uh_len = 0;
    index = ACC_TRUNC + 1;
    for (;;)
    {
      uh_size = TxtGlueGetNextChar(ra_account, uh_len, &wa_chr);
      if (wa_chr == '\0')
	break;

      if (--index == 0)
	break;

      uh_len += uh_size;
    }

    MemMove(pa_cur, ra_account, uh_len);
    pa_cur += uh_len;

    if (wa_chr != '\0')
      *pa_cur++ = ellipsis(NULL);
  }
  // Nombre de comptes
  else
  {
    StrIToA(pa_cur, uh_accounts);
    pa_cur += StrLen(pa_cur);
  }

  if (ps_stats->ui_val_date || ps_stats->ui_ignore_nulls)
  {
    *pa_cur++ = ' ';

    if (ps_stats->ui_val_date)
      *pa_cur++ = '!';

    if (ps_stats->ui_ignore_nulls)
      *pa_cur++ = '0';
  }

  *pa_cur = '\0';

  index = pa_cur - ps_prev->ra_buf;

  return index;
}


static void __list_prev_stats(Int16 h_line, RectangleType *prec_bounds,
			      Char **ppa_lines)
{
  struct s_prev_stats *ps_prev = (struct s_prev_stats*)ppa_lines;
  Char *pa_str;
  UInt16 uh_len;

  uh_len = __prev_stats_prepare(ps_prev, h_line);

  pa_str = ps_prev->ra_buf;
  list_line_draw(0, prec_bounds, &pa_str);
}


static void __list_years(Int16 h_line, RectangleType *prec_bounds,
			 Char **ppa_lines)
{
  Char ra_num[5], *pa_years;

  StrIToA(ra_num, h_line + (UInt16)(UInt32)ppa_lines + firstYear);

  pa_years = ra_num;
  list_line_draw(0, prec_bounds, &pa_years);
}


void stats_week_beg_end(DateType *ps_date, Boolean b_biweek)
{
  // 0 pour dimanche, 1 pour lundi
  UInt16 uh_weekStartDay = (UInt16)PrefGetPreference(prefWeekStartDay);
  UInt16 uh_dow, uh_days;
  UInt32 ul_beg = 0, ul_end = 0;

  // On met les dates dans l'ordre
  if (DateToInt(ps_date[0]) > DateToInt(ps_date[1]))
  {
    DateType s_tmp;

    s_tmp = ps_date[0];
    ps_date[0] = ps_date[1];
    ps_date[1] = s_tmp;
  }

  // Date de début :  on cherche avant
  uh_dow = DayOfWeek(ps_date[0].month, ps_date[0].day,
		     ps_date[0].year + firstYear);
  if (uh_dow != uh_weekStartDay)
  {
    // Dimanche
    if (uh_weekStartDay == sunday)
      uh_days = uh_dow;
    // Lundi
    else
      uh_days = (uh_dow == sunday) ? 6 : uh_dow - 1;

    // Il faut oter h_days
    ul_beg = DateToDays(ps_date[0]) - uh_days;
    DateDaysToDate(ul_beg, &ps_date[0]);
  }

  // Date de fin : on cherche après
  uh_dow = DayOfWeek(ps_date[1].month, ps_date[1].day,
		     ps_date[1].year + firstYear);
  if (uh_dow != (uh_weekStartDay ? sunday : saturday))
  {
    // Dimanche
    if (uh_weekStartDay == sunday)
      uh_days = 6 - uh_dow;
    // Lundi
    else
      uh_days = 7 - uh_dow;

    // Il faut ajouter h_days
    ul_end = DateToDays(ps_date[1]) + uh_days;
    DateDaysToDate(ul_end, &ps_date[1]);
  }
  // On a affaire à des quinzaines...
  if (b_biweek)
  {
    if (ul_end == 0)
      ul_end = DateToDays(ps_date[1]);

    // On n'a pas un multiple de 14 jours...
    if ((ul_end - (ul_beg ? : DateToDays(ps_date[0])) + 1) % 14 != 0)
    {
      ul_end += 7;		/* On rajoute une semaine */
      DateDaysToDate(ul_end, &ps_date[1]);
    }
  }
}


static void manage_prev_stats(struct s_stats_prefs *ps_stats,
			      struct s_stats_prefs *ps_add_stat)
{
  struct s_stats_prefs *ps_cur;
  UInt16 index;

  ps_cur = ps_stats;
  for (index = 0; index < DB_PREFS_STATS_NUM; index++, ps_cur++)
    // On vient de trouver la même stat dans la liste, on la passe en tête
    if (MemCmp(ps_cur, ps_add_stat, sizeof(*ps_add_stat)) == 0)
    {
      MemMove(ps_stats + 1, ps_stats, (ps_cur - ps_stats) * sizeof(*ps_cur));
      goto insert;
    }

  // On s'insère au début
  MemMove(ps_stats + 1, ps_stats, (DB_PREFS_STATS_NUM - 1) *sizeof(*ps_stats));

 insert:
  MemMove(ps_stats, ps_add_stat, sizeof(*ps_add_stat));
}


@implementation StatsForm

- (StatsForm*)free
{
  [[oMaTirelire mode] popupListFree:self->pv_popup_modes];
  [[oMaTirelire type] popupListFree:self->pv_popup_types];
  [[oMaTirelire transaction] popupListFree:self->pv_popup_accounts];

  return [super free];
}


- (void)initAllDates:(Boolean)b_init_all
{
  if (b_init_all)
  {
    Transaction *oTransactions;
    MemHandle pv_tr;
    const struct s_transaction *ps_tr;
    DateTimeType s_datetime;
    UInt16 index, uh_nb_records;

    oTransactions = [oMaTirelire transaction];

    // La date de fin est la date d'aujourd'hui
    TimSecondsToDateTime(TimGetSeconds(), &s_datetime);
    self->rs_date[1].day = s_datetime.day;
    self->rs_date[1].month = s_datetime.month;
    self->rs_date[1].year = s_datetime.year - firstYear;

    // La date de début est la date de la première opération du compte
    // Par défaut la même date...
    self->rs_date[0] = self->rs_date[1];

    uh_nb_records = DmNumRecords(oTransactions->db); // PG inutile
    for (index = 0; index < uh_nb_records; index++)
    {
      pv_tr = DmQueryRecord(oTransactions->db, index);
      if (pv_tr != NULL)
      {
	ps_tr = MemHandleLock(pv_tr);

	if (DateToInt(ps_tr->s_date) != 0)
	{
	  self->rs_date[0] = ps_tr->s_date;
	  MemHandleUnlock(pv_tr);
	  break;
	}

	MemHandleUnlock(pv_tr);
      }
    }

    // On regarde la date de la dernière opération du compte
    while (uh_nb_records-- > 0)
    {
      pv_tr = DmQueryRecord(oTransactions->db, uh_nb_records); // PG inutile
      if (pv_tr != NULL)
      {
	ps_tr = MemHandleLock(pv_tr);

	if (DateToInt(ps_tr->s_date) != 0)
	{
	  // On vient de trouver une date après aujourd'hui...
	  if (DateToInt(ps_tr->s_date) > DateToInt(self->rs_date[1]))
	    self->rs_date[1] = ps_tr->s_date;

	  MemHandleUnlock(pv_tr);
	  break;
	}

	MemHandleUnlock(pv_tr);
      }
    }
  }

  [self dateSet:StatsBegDate date:self->rs_date[0] format:self->e_format];
  [self dateSet:StatsEndDate date:self->rs_date[1] format:self->e_format];
}


- (void)initAccountsPopup:(UInt16)uh_accounts
{
  Transaction *oTransactions;
  struct s_tr_accounts_list s_infos;

  oTransactions = [oMaTirelire transaction];

  // Popup des comptes
  s_infos.h_skip_account = -1;

  // Le popup est déjà présent à l'écran, on essaie de resélectionner
  // les mêmes comptes
  if (self->pv_popup_accounts != NULL)
  {
    s_infos.uh_checked_accounts
      = [oTransactions popupListGet:self->pv_popup_accounts];

    [oTransactions popupListFree:self->pv_popup_accounts];
  }
  else
    s_infos.uh_checked_accounts = uh_accounts;

  s_infos.uh_before_last = strStatsSelectAllAccounts;
  s_infos.uh_last = strStatsResetAccounts;
  s_infos.ra_first_item[0] = '\0';

  // Popup des comptes
  self->pv_popup_accounts = [oTransactions popupListInit:StatsFromAccountsList
					   form:(BaseForm*)self
					   infos:&s_infos
					   selectedAccount:0];
}


- (void)applyPrevStat:(struct s_stats_prefs*)ps_stats
{
  Transaction *oTransactions;
  Type *oTypes;
  Mode *oModes;
  ListType *pt_list;
  struct s_stats_prefs s_init_stats;
  DateType s_today;
  UInt16 uh_id;

  DateSecondsToDate(TimGetSeconds(), &s_today);

  oTransactions = [oMaTirelire transaction];

  // Cas initial : pas encore de préférence sauvée
  if (DateToInt(ps_stats->rs_date[0]) == 0)
  {
    MemSet(&s_init_stats, sizeof(s_init_stats), '\0');

    s_init_stats.ui_menu_choice = STATS_MENU_CUR_YEAR;
    s_init_stats.ui_by = STATS_BY_MONTH;
    s_init_stats.ui_type_any = 1;
    s_init_stats.ui_mode_any = 1;

    // On vient de la liste des comptes
    if ([(Object*)self->oPrevForm->oIsa isKindOf:AccountsListForm]
	&& oTransactions->ps_prefs->uh_selected_accounts != 0)
      s_init_stats.uh_checked_accounts
	= oTransactions->ps_prefs->uh_selected_accounts;
    // Sinon le compte courant
    else
      s_init_stats.uh_checked_accounts
	= (1 << oTransactions->ps_prefs->ul_cur_category);

    ps_stats = &s_init_stats;
  }

  // Dates liées
  CtlSetValue([self objectPtrId:StatsDatesBound], ps_stats->ui_dates_bound);

  // Popup des types
  oTypes = [oMaTirelire type];
  uh_id = ps_stats->ui_type_any ? ITEM_ANY : ps_stats->ui_type;
  if (self->pv_popup_types == NULL)
    self->pv_popup_types = [oTypes popupListInit:StatsTypeList
				   form:self->pt_frm
				   Id:uh_id | TYPE_ADD_ANY_LINE
				   forAccount:NULL];
  else
    [oTypes  popupList:self->pv_popup_types setSelection:uh_id];

  // Popup des modes
  oModes = [oMaTirelire mode];
  uh_id = ps_stats->ui_mode_any ? ITEM_ANY : ps_stats->ui_mode;
  if (self->pv_popup_modes == NULL)
    self->pv_popup_modes = [oModes popupListInit:StatsModeList
				   form:self->pt_frm
				   Id:(uh_id
				       | ITEM_ADD_UNKNOWN_LINE
				       | ITEM_ADD_ANY_LINE)
				   forAccount:NULL];
  else
    [oModes  popupList:self->pv_popup_modes setSelection:uh_id];

  // Par (type, mode, semaine...)
  [self initByPopup:ps_stats->ui_by];

  // Type avec ses fils
  CtlSetValue([self objectPtrId:StatsTypeChildren],ps_stats->ui_type_children);

  // Sur (tout, débits, crédits)
  pt_list = [self objectPtrId:StatsDebCredList];
  LstSetSelection(pt_list, ps_stats->ui_on);
  CtlSetLabel([self objectPtrId:StatsDebCredPopup],
	      LstGetSelectionText(pt_list, ps_stats->ui_on));

  // En fonction des dates de valeur
  CtlSetValue([self objectPtrId:StatsValDate], ps_stats->ui_val_date);

  // Ignorer les montants nuls
  CtlSetValue([self objectPtrId:StatsExcludeNils],
	      ps_stats->ui_ignore_nulls);

  // Les comptes sélectionnés
  if (self->pv_popup_accounts == NULL)
    [self initAccountsPopup:ps_stats->uh_checked_accounts];
  else
    [oTransactions popupList:self->pv_popup_accounts
		   setSelection:ps_stats->uh_checked_accounts];

  // Macro ?
  switch (ps_stats->ui_menu_choice)
  {
  default:		// STATS_MENU_NONE
    self->uh_menu_choice = STATS_MENU_NONE;
    self->uh_week_bounds = 0;
	
    MemMove(self->rs_date, ps_stats->rs_date, sizeof(self->rs_date));
    break;

  case STATS_MENU_CUR_MONTH:
  case STATS_MENU_LAST_MONTH:
  case STATS_MENU_LAST2_MONTH:
    [self chooseMonth:ps_stats->ui_menu_choice today:&s_today];
    break;

  case STATS_MENU_CUR_YEAR:
  case STATS_MENU_LAST_YEAR:
    [self chooseYear:ps_stats->ui_menu_choice today:&s_today];
    break;

  case STATS_MENU_ALL:
    chooseAll;
    break;
  }

  if (ps_stats->ui_week_bounds)
    chooseWeekBegEnd;

  // Appel pour rechercher les dates extrèmes
#define b_init_all (ps_stats->ui_menu_choice == STATS_MENU_ALL)
  [self initAllDates:b_init_all];
#undef b_init_all
}


- (void)initOldestYear
{
  Transaction *oTransactions = [oMaTirelire transaction];
  MemHandle pv_tr;
  const struct s_transaction *ps_tr;
  DateTimeType s_datetime;
  DateType s_oldest;
  UInt16 uh_nb_records, index;

  // La date de fin est la date d'aujourd'hui
  TimSecondsToDateTime(TimGetSeconds(), &s_datetime);
  s_oldest.day = s_datetime.day;
  s_oldest.month = s_datetime.month;
  s_oldest.year = s_datetime.year - firstYear;

  uh_nb_records = DmNumRecords(oTransactions->db); // PG inutile
  for (index = 0; index < uh_nb_records; index++)
  {
    pv_tr = DmQueryRecord(oTransactions->db, index);
    if (pv_tr != NULL)
    {
      ps_tr = MemHandleLock(pv_tr);

      if (DateToInt(ps_tr->s_date) != 0)
      {
	s_oldest = ps_tr->s_date;
	MemHandleUnlock(pv_tr);
	break;
      }

      MemHandleUnlock(pv_tr);
    }
  }

  self->uh_oldest_year = s_oldest.year;
}


- (Boolean)open
{
  Transaction *oTransactions = [oMaTirelire transaction];
  struct s_stats_prefs s_stats, *ps_stats, *ps_last_stats;

  // Format des dates
  self->e_format = (DateFormatType)PrefGetPreference(prefLongDateFormat);

  // L'année la plus ancienne
  [self initOldestYear];

  ps_last_stats = &oTransactions->ps_prefs->rs_stats[0];

  // On vient de l'écran des MiniStats
  if ([(Object*)self->oPrevForm->oIsa isKindOf:MiniStatsForm])
  {
    MemSet(&s_stats, sizeof(s_stats), '\0');

    MemMove(s_stats.rs_date, ((MiniStatsForm*)self->oPrevForm)->rs_date,
	    sizeof(self->rs_date));

    s_stats.ui_by = STATS_BY_MONTH;
    s_stats.ui_type_any = 1;
    s_stats.ui_mode_any = 1;

    // Le compte courant
    s_stats.uh_checked_accounts
      = (1 << oTransactions->ps_prefs->ul_cur_category);

    // Choix de date de valeur identique à celui de l'écran précédent
    s_stats.ui_val_date
      = CtlGetValue([self->oPrevForm objectPtrId:MiniStatsValDate]);

    // Les dates étaient liées => elle le restent (et vice versa)
    s_stats.ui_dates_bound
      = CtlGetValue([self->oPrevForm objectPtrId:MiniStatsDatesBound]);

    // Lorsqu'on n'est pas dans le cas initial, on reprend ce choix
    // des dernières stats
    if (DateToInt(ps_last_stats->rs_date[0]))
      s_stats.ui_ignore_nulls = ps_last_stats->ui_ignore_nulls;

    ps_stats = &s_stats;
  }
  else
    // On initialise avec les dernières stats
    ps_stats = ps_last_stats;

  [self applyPrevStat:ps_stats];

  LstSetDrawFunction([self objectPtrId:StatsPeriodList], list_line_draw);
  LstSetDrawFunction([self objectPtrId:StatsReqList], list_line_draw);

  return [super open];
}


- (void)initByPopup:(UInt16)index
{
  ListType *pt_list;
  Char *pa_label;
  Boolean b_show = (index >= STATS_BY_WEEK && index <= STATS_BY_YEAR);

  pt_list = [self objectPtrId:StatsReqList];
  LstSetSelection(pt_list, index);

  pa_label = LstGetSelectionText(pt_list, index);

  // Il faut sauter le caractère de surlignement s'il y en a un
  if (*pa_label == '^')
    pa_label++;

  CtlSetLabel([self objectPtrId:StatsReqPopup], pa_label);

  // Si le formulaire est déjà dessiné OU BIEN qu'il faut cacher...
  if (self->uh_form_drawn || b_show == false)
  {
    UInt16 ruh_objs[] =
    {
      SET_SHOW(StatsTypeLabel, b_show),
      SET_SHOW(StatsTypePopup, b_show),
      SET_SHOW(StatsTypeChildren, b_show),
      SET_SHOW(StatsModeLabel, b_show),
      SET_SHOW(StatsModePopup, b_show),
      0
    };

    [self showHideIds:ruh_objs];
  }
}


- (void)chooseMonth:(UInt16)uh_month_choice today:(DateType*)ps_today
{
  switch (uh_month_choice)
  {
  case STATS_MENU_LAST_MONTH:
  case STATS_MENU_LAST2_MONTH:
    {
      Int16 h_month = (Int16)ps_today->month - (Int16)uh_month_choice + 1;
      if (h_month <= 0)
      {
	ps_today->month = 12 + h_month;
	ps_today->year--;
      }
      else
	ps_today->month = h_month;
    }
    // Continue

  case STATS_MENU_CUR_MONTH:
    self->uh_menu_choice = uh_month_choice;

  all_month:
    self->uh_week_bounds = 0;

    ps_today->day = 1;
    self->rs_date[0] = *ps_today;
    ps_today->day = DaysInMonth(ps_today->month, ps_today->year + firstYear);
    self->rs_date[1] = *ps_today;
    break;

  default:
    ps_today->month = uh_month_choice >> 8;

    if (self->rs_date[0].year == self->rs_date[1].year)
      ps_today->year = self->rs_date[0].year;

    self->uh_menu_choice = STATS_MENU_NONE;

    goto all_month;
  }
}


- (void)chooseYear:(UInt16)uh_year_choice today:(DateType*)ps_today
{
  switch (uh_year_choice)
  {
  case STATS_MENU_LAST_YEAR:
    ps_today->year--;

    // Continue

  case STATS_MENU_CUR_YEAR:
    self->uh_menu_choice = uh_year_choice;

 all_year:
    self->uh_week_bounds = 0;

    ps_today->day = 1;
    ps_today->month = 1;
    self->rs_date[0] = *ps_today;
    ps_today->day = 31;
    ps_today->month = 12;
    self->rs_date[1] = *ps_today;
    break;

  default:
    ps_today->year = self->uh_oldest_year + (uh_year_choice >> 8);

    // Stats state reset
    self->uh_menu_choice = STATS_MENU_NONE;
    goto all_year;
  }
}


- (UInt16)dateIsBound:(UInt16)uh_date_id date:(DateType**)pps_date
{
  if (CtlGetValue([self objectPtrId:StatsDatesBound]))
  {
    if (uh_date_id == StatsBegDate)
    {
      *pps_date = &self->rs_date[1];
      return StatsEndDate;
    }

    *pps_date = &self->rs_date[0];
    return StatsBegDate;
  }

  return 0;
}


- (Boolean)ctlRepeat:(struct ctlRepeat *)ps_repeat
{
  UInt16 uh_button;

  switch (ps_repeat->controlID)
  {
  case StatsBegDateUp:
  case StatsBegDateDown:
    uh_button = StatsBegDate;
    break;

  case StatsEndDateUp:
  case StatsEndDateDown:
    uh_button = StatsEndDate;
    break;

  default:
    return false;
  }

  [self dateInc:uh_button date:&self->rs_date[uh_button == StatsEndDate]
	pressedButton:ps_repeat->controlID format:self->e_format];

  // Stats state reset
  self->uh_menu_choice = STATS_MENU_NONE;
  self->uh_week_bounds = 0;

  // On retourne toujours false sinon la répétition s'arrête
  return false;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case StatsBegDate:
  case StatsEndDate:
    if ([self dateInc:ps_select->controlID
	      date:&self->rs_date[ps_select->controlID == StatsEndDate]
	      pressedButton:ps_select->controlID format:self->e_format])
    {
      // Stats state reset
      self->uh_menu_choice = STATS_MENU_NONE;
      self->uh_week_bounds = 0;
    }
    break;

  case StatsPeriodPopup:
  {
    Transaction *oTransactions = [oMaTirelire transaction];
    struct s_stats_prefs *ps_old_stats, *ps_cur_stats;
    ListType *pt_list = [self objectPtrId:StatsPeriodList];
    struct s_prev_stats s_buf;
    DateType s_today;
    UInt16 index, uh_sub_index, uh_list;

    ps_old_stats = oTransactions->ps_prefs->rs_stats;

    // Entrée des anciennes stats visible ?
    index = 9 + (DateToInt(ps_old_stats->rs_date[0]) != 0);
    LstSetHeight(pt_list, index);

    {
      Char **ppa = LstGlueGetItemsText(pt_list);
      LstSetListChoices(pt_list, ppa, index); // XXX Bug OS 5 / TT ??? XXX
      LstSetListChoices(pt_list, ppa, index);
    }

    // Sélection de la première entrée
    LstSetSelection(pt_list, 0);

    index = LstPopupList(pt_list);

    DateSecondsToDate(TimGetSeconds(), &s_today);

    switch (index)
    {
    case 0:			// Mois en cours
    case 1:			// Mois dernier
    case 2:			// Avant dernier mois
      [self chooseMonth:index + STATS_MENU_CUR_MONTH today:&s_today];
      break;

    case 4:			// Année en cours
    case 5:			// Année précédente
      [self chooseYear:index - 4 + STATS_MENU_CUR_YEAR today:&s_today];
      break;

    case 7:			// Début/fin de semaine
      chooseWeekBegEnd;
      break;

    case 8:			// Tout
      chooseAll;
      break;

      // Entries with sub-menu
    case 9:			// Older stats...
    case 6:			// Year>
      uh_list = StatsSubPopup;
      goto sub_list_ok;
    case 3:			// Month>
    {
      ListType *pt_list;
      UInt16 uh_x, uh_y, uh_list_idx;
      Boolean b_dummy;

      uh_list = StatsMonths;
  sub_list_ok:

      EvtGetPen(&uh_x, &uh_y, &b_dummy);

      uh_list_idx = FrmGetObjectIndex(self->pt_frm, uh_list);
      pt_list = FrmGetObjectPtr(self->pt_frm, uh_list_idx);

      switch (index)
      {
	// Year>
      case 6:
      {
	RectangleType s_bounds;
	UInt16 uh_num;

	FrmGetObjectBounds(self->pt_frm, uh_list_idx, &s_bounds);
	s_bounds.extent.x = 20-1+4; // "2000"
	FrmSetObjectBounds(self->pt_frm, uh_list_idx, &s_bounds);

	uh_num = s_today.year - self->uh_oldest_year + 1 + 1;// Avec année suiv
	LstSetListChoices(pt_list,(Char**)(UInt32)self->uh_oldest_year,uh_num);
	LstSetHeight(pt_list, uh_num);

	LstSetDrawFunction(pt_list, __list_years);
      }
      break;

      // Previous stats...>
      case 9:
      {
	RectangleType s_bounds;
	UInt16 uh_stat, uh_len, uh_largest, uh_width;

	s_buf.db = oTransactions->db;
	s_buf.ps_stats = ps_old_stats;

	uh_largest = 0;
	ps_cur_stats = ps_old_stats;
	for (uh_stat = 0; uh_stat < DB_PREFS_STATS_NUM;
	     uh_stat++, ps_cur_stats++)
	{
	  if (DateToInt(ps_cur_stats->rs_date[0]) == 0)
	    break;

	  uh_len = __prev_stats_prepare(&s_buf, uh_stat);
	  uh_width = FntCharsWidth(s_buf.ra_buf, uh_len);
	  if (uh_width > uh_largest)
	    uh_largest = uh_width;
	}

	FrmGetObjectBounds(self->pt_frm, uh_list_idx, &s_bounds);
	s_bounds.extent.x = uh_largest + LIST_MARGINS_NO_SCROLL;
	FrmSetObjectBounds(self->pt_frm, uh_list_idx, &s_bounds);

	LstSetListChoices(pt_list, (Char**)&s_buf, uh_stat);
	LstSetHeight(pt_list, uh_stat);

	LstSetDrawFunction(pt_list, __list_prev_stats);
      }
      break;
      }

      // Sélection de la première entrée
      uh_sub_index = [self contextPopupList:uh_list x:uh_x y:uh_y selEntry:0];
      if (uh_sub_index == noListSelection)
	return false;

      switch (index)
      {
	// Month>
      case 3:
	uh_sub_index = (uh_sub_index + 1) << 8;
	[self chooseMonth:uh_sub_index today:&s_today];
	break;

	// Year>
      case 6:
	uh_sub_index <<= 8;
	[self chooseYear:uh_sub_index today:&s_today];
	break;

	// Previous stats...>
      default: // case 9:
	[self applyPrevStat:&ps_old_stats[uh_sub_index]];
	break;
      }
    }
    break;
    }

    [self initAllDates:index == 8]; // Si "All" => grosse init
  }
  break;

  case StatsReqPopup:
  {
    ListType *pt_list = [self objectPtrId:StatsReqList];
    UInt16 index;

    index = LstPopupList(pt_list);
    if (index != noListSelection)
      [self initByPopup:index];
  }
  break;

  case StatsTypePopup:
    [[oMaTirelire type] popupList:self->pv_popup_types];
    break;

  case StatsModePopup:
    [[oMaTirelire mode] popupList:self->pv_popup_modes];
    break;

  case StatsFromAccountsPopup:
  {
    Transaction *oTransactions = [oMaTirelire transaction];
    UInt16 uh_sel;

display_popup:
    uh_sel = [oTransactions popupList:self->pv_popup_accounts
			    firstIsValid:false]; // Pas de 1er ici

    switch (uh_sel)
    {
    case ACC_POPUP_BEFORE_LAST:	// Select all accounts
    case ACC_POPUP_LAST:	// Reset to one account
      uh_sel = (uh_sel == ACC_POPUP_BEFORE_LAST
		? 0xffff
		: (1 << oTransactions->ps_prefs->ul_cur_category));
      [oTransactions popupList:self->pv_popup_accounts setSelection:uh_sel];
      break;

    case noListSelection:
      break;

      // Un compte vient d'être sélectionné, on réaffiche la liste...
    default:
      goto display_popup;
    }
  }
  break;

  case StatsValid:
  {
    ListType *pt_list;
    struct s_stats_prefs s_add_stat;
    UInt16 uh_sub_form;

    // Ajoute cette stat aux précédentes
    MemSet(&s_add_stat, sizeof(s_add_stat), '\0');

    if (self->uh_menu_choice != STATS_MENU_NONE)
    {
      s_add_stat.ui_menu_choice = self->uh_menu_choice;
      s_add_stat.ui_week_bounds = self->uh_week_bounds;

      // Même dans ce cas on stocke les dates telles quelles car les
      // écrans de résultat des stats en ont besoin
    }

    MemMove(s_add_stat.rs_date, self->rs_date, sizeof(self->rs_date));
    if (DateToInt(s_add_stat.rs_date[0]) > DateToInt(s_add_stat.rs_date[1]))
    {
      DateToInt(s_add_stat.rs_date[0]) = DateToInt(s_add_stat.rs_date[1]);
      DateToInt(s_add_stat.rs_date[1]) = DateToInt(self->rs_date[0]);
    }

    // Dates liées
    s_add_stat.ui_dates_bound = CtlGetValue([self objectPtrId:StatsDatesBound]);

    pt_list = [self objectPtrId:StatsReqList];
    s_add_stat.ui_by = LstGetSelection([self objectPtrId:StatsReqList]);

    // Si plusieurs types
    MemSet(self->rul_types, sizeof(self->rul_types), '\0');

    // Par type ou par mode
    if (s_add_stat.ui_by <= STATS_BY_MODE)
	// OU BIEN Minimum/Moyenne/Maximum
	//|| s_add_stat.ui_by >= STATS_BY_MINAVGMAX)
    {
      s_add_stat.ui_type_any = 1;
      s_add_stat.ui_mode_any = 1;

      if (s_add_stat.ui_by == STATS_BY_TYPE)
	uh_sub_form = CustomListFormIdx | CLIST_SUBFORM_TYPE;
      else			// STATS_BY_MODE
	uh_sub_form = CustomListFormIdx | CLIST_SUBFORM_MODE;
    }
    // Par période
    else
    {
      Type *oTypes = [oMaTirelire type];
      UInt16 uh_id;

      uh_id = [[oMaTirelire type] popupListGet:self->pv_popup_types];
      if (uh_id == ITEM_ANY)
	s_add_stat.ui_type_any = 1;
      else
      {
	// Si avec tous les fils du type
	if (CtlGetValue([self objectPtrId:StatsTypeChildren]))
	{
	  s_add_stat.ui_type_children = 1;
	  [oTypes setBitFamily:self->rul_types forType:uh_id];
	}

	s_add_stat.ui_type = uh_id;
      }

      uh_id = [[oMaTirelire mode] popupListGet:self->pv_popup_modes];
      if (uh_id == ITEM_ANY)
	s_add_stat.ui_mode_any = 1;
      else
	s_add_stat.ui_mode = uh_id;

      uh_sub_form = CustomListFormIdx | CLIST_SUBFORM_PERIOD;
    }

    // Sur...
    s_add_stat.ui_on = LstGetSelection([self objectPtrId:StatsDebCredList]);

    // En fonction de la date de valeur
    s_add_stat.ui_val_date = CtlGetValue([self objectPtrId:StatsValDate]);

    // Ignorer les montants nuls
    s_add_stat.ui_ignore_nulls
      = CtlGetValue([self objectPtrId:StatsExcludeNils]);

    // Les comptes
    s_add_stat.uh_checked_accounts
      = [[oMaTirelire transaction] popupListGet:self->pv_popup_accounts];

    manage_prev_stats([oMaTirelire transaction]->ps_prefs->rs_stats,
		      &s_add_stat);

    // Formulaire de résultat
    FrmPopupForm(uh_sub_form);
  }
  break;

  case StatsCancel:
    // On vient de l'écran des MiniStats
    if ([(Object*)self->oPrevForm->oIsa isKindOf:MiniStatsForm]
	// ET la liste des opérations a changé, il faudra recalculer les sommes
	&& ((self->ui_update_mati_list
	     & (frmMaTiUpdateList | frmMaTiUpdateListTransactions))
	    == (frmMaTiUpdateList | frmMaTiUpdateListTransactions)))
      [self sendCallerUpdate:frmMaTiUpdateMiniStatsForm];

    [self returnToLastForm];
    break;

  default:
    return false;
  }

  return true;
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  if (UPD_CODE(ps_update->updateCode) == frmMaTiUpdateList)
  {
    UInt16 uh_id;

    // La liste des types a changé
    if (ps_update->updateCode & frmMaTiUpdateListTypes)
    {
      Type *oTypes = [oMaTirelire type];

      uh_id = [oTypes popupListGet:self->pv_popup_types];

      [oTypes popupListFree:self->pv_popup_types];

      // On vient d'effacer le type actuellement sélectionné
      if (uh_id < TYPE_UNFILED
	  && [oTypes getCachedIndexFromID:uh_id] == ITEM_FREE_ID)
	uh_id = ITEM_ANY;

      self->pv_popup_types = [oTypes popupListInit:StatsTypeList
				     form:self->pt_frm
				     Id:(uh_id | TYPE_ADD_ANY_LINE)
				     forAccount:NULL];
    }

    // La liste des modes a changé
    if (ps_update->updateCode & frmMaTiUpdateListModes)
    {
      Mode *oModes = [oMaTirelire mode];

      uh_id = [oModes popupListGet:self->pv_popup_modes];

      [oModes popupListFree:self->pv_popup_modes];

      // On vient d'effacer le mode actuellement sélectionné
      if (uh_id < MODE_UNKNOWN
	  && [oModes getCachedIndexFromID:uh_id] == ITEM_FREE_ID)
	uh_id = ITEM_ANY;

      self->pv_popup_modes
	= [oModes popupListInit:StatsModeList
		  form:self->pt_frm
		  Id:(uh_id | ITEM_ADD_UNKNOWN_LINE | ITEM_ADD_ANY_LINE)
		  forAccount:NULL];
    }

    // La liste des comptes a changé
    if (ps_update->updateCode & frmMaTiUpdateListAccounts)
      [self initAccountsPopup:0];

    // La liste des opérations a changé
    if (ps_update->updateCode & frmMaTiUpdateListTransactions)
      [self initOldestYear];
  }

  return [super callerUpdate:ps_update];
}

@end
