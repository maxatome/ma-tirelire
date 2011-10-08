/* 
 * MiniStatsForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Ven sep  8 23:22:20 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Jul  5 16:48:29 2007
 * Update Count    : 8
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: MiniStatsForm.m,v $
 * Revision 1.3  2008/01/14 16:45:15  max
 * Switch to new mcc.
 *
 * Revision 1.2  2006/11/04 23:48:10  max
 * Can now call statistics form and can be updated by it.
 *
 * Revision 1.1  2006/10/10 17:41:02  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_MINISTATSFORM
#include "MiniStatsForm.h"

#include "MaTirelire.h"
#include "ProgressBar.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


@implementation MiniStatsForm

- (Boolean)open
{
  Transaction *oTransactions = [oMaTirelire transaction];
  Currency *oCurrencies = [oMaTirelire currency];
  struct s_currency *ps_currency;
  Char ra_title[dmCategoryLength];
  DateTimeType s_datetime;

  // Le titre de la boîte est le nom du compte
  CategoryGetName(oTransactions->db, oTransactions->ps_prefs->ul_cur_category,
		  ra_title);
  FrmCopyTitle(self->pt_frm, ra_title);

  // Format des dates
  self->e_format = (DateFormatType)PrefGetPreference(prefLongDateFormat);

  // Les dates encadrent le mois courant
  TimSecondsToDateTime(TimGetSeconds(), &s_datetime);
  s_datetime.year -= firstYear;

  self->rs_date[0].day = 1;
  self->rs_date[0].month = s_datetime.month;
  self->rs_date[0].year = s_datetime.year;

  self->rs_date[1].day = DaysInMonth(s_datetime.month, s_datetime.year);
  self->rs_date[1].month = s_datetime.month;
  self->rs_date[1].year = s_datetime.year;

  [self dateSet:MiniStatsBegDate date:self->rs_date[0] format:self->e_format];
  [self dateSet:MiniStatsEndDate date:self->rs_date[1] format:self->e_format];

  // En fonction de la date de valeur
  CtlSetValue([self objectPtrId:MiniStatsValDate],
	      oTransactions->ps_prefs->ul_sort_type != SORT_BY_DATE);

  // Devise du compte
  ps_currency = [oCurrencies getId:[oTransactions
				     accountCurrency:ACCOUNT_PROP_CURRENT]];

  [self fillLabel:MiniStatsCurrency withSTR:ps_currency->ra_name];

  [oCurrencies getFree:ps_currency];

  // Calcul des sommes...
  [self computeSum];

  return [super open];
}


- (Boolean)ctlRepeat:(struct ctlRepeat *)ps_repeat
{
  UInt16 uh_button;

  switch (ps_repeat->controlID)
  {
  case MiniStatsBegDateUp:
  case MiniStatsBegDateDown:
    uh_button = MiniStatsBegDate;
    break;

  case MiniStatsEndDateUp:
  case MiniStatsEndDateDown:
    uh_button = MiniStatsEndDate;
    break;

  default:
    return false;
  }

  [self dateInc:uh_button date:&self->rs_date[uh_button == MiniStatsEndDate]
	pressedButton:ps_repeat->controlID format:self->e_format];

  // On recalcule les sommes
  [self computeSum];

  // On retourne toujours false sinon la répétition s'arrête
  return false;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case MiniStatsBegDate:
  case MiniStatsEndDate:
    [self dateInc:ps_select->controlID
	  date:&self->rs_date[ps_select->controlID == MiniStatsEndDate]
	  pressedButton:ps_select->controlID format:self->e_format];

    // On continue avec le recalcul des sommes

  case MiniStatsValDate:
    [self computeSum];
    break;

  case  MiniStatsOK:
    [self returnToLastForm];
    break;

  case MiniStatsStatistics:
    FrmPopupForm(StatsFormIdx);
    break;

  default:
    return false;
  }

  return true;
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  // On revient des stats, on recalcule les sommes...
  if (UPD_CODE(ps_update->updateCode) == frmMaTiUpdateMiniStatsForm)
  {
    [self computeSum];

    // Il ne faut pas que la classe mère conserve cet événement pour
    // Papa, on s'en est chargé nous-mêmes une ligne au dessus.
    ps_update->updateCode = 0;
  }

  return [super callerUpdate:ps_update];
}


- (UInt16)dateIsBound:(UInt16)uh_date_id date:(DateType**)pps_date
{
  if (CtlGetValue([self objectPtrId:MiniStatsDatesBound]))
  {
    if (uh_date_id == MiniStatsBegDate)
    {
      *pps_date = &self->rs_date[1];
      return MiniStatsEndDate;
    }

    *pps_date = &self->rs_date[0];
    return MiniStatsBegDate;
  }

  return 0;
}


- (void)computeSum
{
  Transaction *oTransactions = [oMaTirelire transaction];
  DmOpenRef db;
  MemHandle pv_tr;
  const struct s_transaction *ps_tr;
  t_amount l_total, l_credits, l_debits;
  PROGRESSBAR_DECL;
  UInt16 uh_cur_account, index, uh_date, uh_date_beg, uh_date_end;
  Boolean b_value_date;

  l_total = l_credits = 0;

  // Les bornes de dates
  uh_date_beg = DateToInt(self->rs_date[0]);
  uh_date_end = DateToInt(self->rs_date[1]);
  if (uh_date_beg > uh_date_end)
  {
    uh_date_beg = uh_date_end;
    uh_date_end = DateToInt(self->rs_date[0]);
  }

  // En fonction de la date de valeur
  b_value_date = CtlGetValue([self objectPtrId:MiniStatsValDate]);

  db = oTransactions->db;
  uh_cur_account = oTransactions->ps_prefs->ul_cur_category;

  PROGRESSBAR_BEGIN(DmNumRecords(db), strProgressBarStats);
  index = 0;
  while ((pv_tr = DmQueryNextInCategory(db, &index, uh_cur_account)) // PG
	 != NULL)
  {
    ps_tr = MemHandleLock(pv_tr);

    uh_date = (b_value_date && ps_tr->ui_rec_value_date)
      ? DateToInt(value_date_extract(ps_tr)) : DateToInt(ps_tr->s_date);

    if (uh_date >= uh_date_beg && uh_date <= uh_date_end)
    {
      l_total += ps_tr->l_amount;

      if (ps_tr->l_amount > 0)
	l_credits += ps_tr->l_amount;
    }

    MemHandleUnlock(pv_tr);

    PROGRESSBAR_INLOOP(index, 50); // OK

    index++;
  }

  PROGRESSBAR_END;

  l_debits = l_total - l_credits;

  // Les montants
  [self replaceField:REPLACE_FIELD_EXT | MiniStatsCredits
	withSTR:(Char*)l_credits len:REPL_FIELD_FDWORD];

  [self replaceField:REPLACE_FIELD_EXT | MiniStatsDebits
	withSTR:(Char*)l_debits len:REPL_FIELD_FDWORD | REPL_FIELD_KEEP_SIGN];

  [self replaceField:REPLACE_FIELD_EXT | MiniStatsTotal
	withSTR:(Char*)l_total len:REPL_FIELD_FDWORD | REPL_FIELD_KEEP_SIGN];

  // Les pourcentages
  l_total = l_credits - l_debits;

  if (l_total == 0)
  {
    [self hideId:MiniStatsCreditsPercentLabel];
    [self hideId:MiniStatsDebitsPercentLabel];

    [self replaceField:MiniStatsCreditsPercent withSTR:"" len:0];
    [self replaceField:MiniStatsDebitsPercent withSTR:"" len:0];
  }
  else
  {
    [self showId:MiniStatsCreditsPercentLabel];
    [self showId:MiniStatsDebitsPercentLabel];

    l_credits = (l_credits * 100 + (l_total >> 1)) / l_total;
    [self replaceField:REPLACE_FIELD_EXT | MiniStatsCreditsPercent
	  withSTR:(Char*)l_credits len:REPL_FIELD_DWORD];

    l_debits = (-l_debits * 100 + (l_total >> 1)) / l_total;
    [self replaceField:REPLACE_FIELD_EXT | MiniStatsDebitsPercent
	  withSTR:(Char*)l_debits len:REPL_FIELD_DWORD];
  }
}

@end
