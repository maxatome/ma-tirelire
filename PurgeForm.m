/* 
 * PurgeForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sam fév 26 17:30:34 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Dec 10 17:49:39 2007
 * Update Count    : 17
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: PurgeForm.m,v $
 * Revision 1.6  2008/01/14 16:33:47  max
 * Switch to new mcc.
 * Didn't handle correctly splits. Corrected.
 * Handle signed splits.
 *
 * Revision 1.5  2006/11/04 23:48:11  max
 * Use FOREACH_SPLIT* macros.
 * Handle unsorted dates.
 *
 * Revision 1.4  2006/10/05 19:08:58  max
 * s/s_date/rs_date/g
 * The two dates can now be bound.
 *
 * Revision 1.3  2006/04/25 08:47:16  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 * Handle splitted transactions.
 *
 * Revision 1.2  2005/08/20 13:06:58  max
 * Prepare switching to 64 bits amounts.
 * Updates are now genericaly managed by MaTiForm.
 *
 * Revision 1.1  2005/05/08 12:12:46  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_PURGEFORM
#include "PurgeForm.h"

#include "MaTirelire.h"
#include "Transaction.h"

#include "ProgressBar.h"
#include "alarm.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


@implementation PurgeForm

- (Boolean)open
{
  Transaction *oTransactions = [oMaTirelire transaction];
  MemHandle pv_tr;
  const struct s_transaction *ps_tr;
  DateTimeType s_datetime;
  UInt16 index;

  // Par défaut, on rassemble dans le compte
  CtlSetValue([self objectPtrId:PurgeInAccount], 1);

  // Format des dates
  self->e_format = (DateFormatType)PrefGetPreference(prefLongDateFormat);

  // La date de fin est la date d'aujourd'hui
  TimSecondsToDateTime(TimGetSeconds(), &s_datetime);
  self->rs_date[1].day = s_datetime.day;
  self->rs_date[1].month = s_datetime.month;
  self->rs_date[1].year = s_datetime.year - firstYear;

  // La date de début est la date de la première opération du compte
  self->rs_date[0] = self->rs_date[1]; // Par défaut la même date...
  index = 0;
  while ((pv_tr = DmQueryNextInCategory	// PG inutile
	  (oTransactions->db, &index,oTransactions->ps_prefs->ul_cur_category))
	 != NULL)
  {
    ps_tr = MemHandleLock(pv_tr);

    if (DateToInt(ps_tr->s_date) != 0)
    {
      self->rs_date[0] = ps_tr->s_date;
      MemHandleUnlock(pv_tr);
      break;
    }

    MemHandleUnlock(pv_tr);
    index++;
  }

  [self dateSet:PurgeBegDate date:self->rs_date[0] format:self->e_format];
  [self dateSet:PurgeEndDate date:self->rs_date[1] format:self->e_format];

  return [super open];
}


- (Boolean)ctlRepeat:(struct ctlRepeat *)ps_repeat
{
  UInt16 uh_button;

  switch (ps_repeat->controlID)
  {
  case PurgeBegDateUp:
  case PurgeBegDateDown:
    uh_button = PurgeBegDate;
    break;

  case PurgeEndDateUp:
  case PurgeEndDateDown:
    uh_button = PurgeEndDate;
    break;

  default:
    return false;
  }

  [self dateInc:uh_button date:&self->rs_date[uh_button == PurgeEndDate]
	pressedButton:ps_repeat->controlID format:self->e_format];

  // On retourne toujours false sinon la répétition s'arrête
  return false;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case PurgeBegDate:
  case PurgeEndDate:
    [self dateInc:ps_select->controlID
	  date:&self->rs_date[ps_select->controlID == PurgeEndDate]
	  pressedButton:ps_select->controlID format:self->e_format];
    break;

  case PurgeOK:
    if (FrmAlert(alertDeleteCleared) == 0)
      break;

    [self purge];

    self->ui_update_mati_list |= (frmMaTiUpdateList
				  | frmMaTiUpdateListTransactions);

    // Continue sur cancel...

  case PurgeCancel:
    [self returnToLastForm];
    break;

  default:
    return false;
  }

  return true;
}


- (UInt16)dateIsBound:(UInt16)uh_date_id date:(DateType**)pps_date
{
  if (CtlGetValue([self objectPtrId:PurgeDatesBound]))
  {
    if (uh_date_id == PurgeBegDate)
    {
      *pps_date = &self->rs_date[1];
      return PurgeEndDate;
    }

    *pps_date = &self->rs_date[0];
    return PurgeBegDate;
  }

  return 0;
}


- (void)purge
{
  Transaction *oTransactions = [oMaTirelire transaction];
  DmOpenRef db;
  MemHandle pv_tr;
  struct s_transaction *ps_tr;
  t_amount l_sum = 0, *pl_sums = NULL, l_split_amount;
  PROGRESSBAR_DECL;
  UInt16 uh_nb_sums = 0;
  UInt16 uh_account, index, uh_date, uh_beg_date, uh_end_date;
#define PURGE_IN_ACCOUNT 0
#define PURGE_BY_TYPE	 1
#define PURGE_BY_MODE	 2
  UInt16 uh_purge;
  UInt16 uh_reschedule_alarm = 0;
  Boolean b_value_date, b_use_conduit;

  // Pour la barre de progression
  b_use_conduit = oTransactions->ps_prefs->ul_remove_type;

  // En fonction de la date de valeur
  b_value_date = CtlGetValue([self objectPtrId:PurgeValDate]);

  if (CtlGetValue([self objectPtrId:PurgeInAccount]))
    uh_purge = PURGE_IN_ACCOUNT;    
  else
  {
    if (CtlGetValue([self objectPtrId:PurgeByType]))
    {
      uh_purge = PURGE_BY_TYPE;
      uh_nb_sums = NUM_TYPES;
    }
    else // if (CtlGetValue([self objectPtrId:PurgeByMode]))
    {
      uh_purge = PURGE_BY_MODE;
      uh_nb_sums = NUM_MODES;
    }

    NEW_PTR(pl_sums, uh_nb_sums * sizeof(UInt32), return);

    MemSet(pl_sums, uh_nb_sums * sizeof(UInt32), 0);
  }

  db = oTransactions->db;
  uh_account = oTransactions->ps_prefs->ul_cur_category;

  uh_beg_date = DateToInt(self->rs_date[0]);
  uh_end_date = DateToInt(self->rs_date[1]);
  if (uh_beg_date > uh_end_date)
  {
    uh_beg_date = uh_end_date;
    uh_end_date = DateToInt(self->rs_date[0]);
  }

  PROGRESSBAR_BEGIN(DmNumRecords(db) + uh_nb_sums, strProgressBarPurge);

  index = 0;
  while ((pv_tr = DmQueryNextInCategory(db, &index, uh_account)) != NULL) // PG
  {
    ps_tr = MemHandleLock(pv_tr);

    // Ajouter RECORD_ALARM ???
    if ((ps_tr->ui_rec_flags & (RECORD_CHECKED|RECORD_REPEAT))
	== RECORD_CHECKED)
    {
      uh_date = DateToInt(ps_tr->s_date);

      if (b_value_date && ps_tr->ui_rec_value_date)
	uh_date = DateToInt(*(DateType*)ps_tr->ra_note);

      // OK, dans l'intervalle...
      if (uh_date >= uh_beg_date && uh_date <= uh_end_date)
      {
	switch (uh_purge)
	{
	case PURGE_IN_ACCOUNT:
	  l_sum += ps_tr->l_amount;
	  break;

	case PURGE_BY_TYPE:
	  // Il y a des sous-opérations
	  if (ps_tr->ui_rec_splits)
	  {
	    struct s_rec_options s_options;
	    FOREACH_SPLIT_DECL; // __uh_num et ps_cur_split

	    options_extract(ps_tr, &s_options);

	    FOREACH_SPLIT(&s_options)
	    {
	      l_split_amount = ps_cur_split->l_amount;
	      if (ps_tr->l_amount < 0)
		l_split_amount = - l_split_amount;

	      // On soustrait cette somme au type principal, car il va
	      // être incrémenté de la somme totale de l'opération
	      // juste après la boucle...
	      pl_sums[ps_tr->ui_rec_type] -= l_split_amount;

	      pl_sums[ps_cur_split->ui_type] += l_split_amount;
	    }
	  }

	  pl_sums[ps_tr->ui_rec_type] += ps_tr->l_amount;
	  break;

	default:		// PURGE_BY_MODE
	  pl_sums[ps_tr->ui_rec_mode] += ps_tr->l_amount;
	  break;
	}

	MemHandleUnlock(pv_tr);

	// Suppression de l'opération
	uh_reschedule_alarm // Alarme OK
	  |= [oTransactions deleteId:((UInt32)index
				      | TR_DEL_MANAGE_ALARM
				      | TR_DEL_DONT_RESCHED_ALARM)];

	// Si l'opération est supprimée immédiatement : pas d'inc. de index
	if (b_use_conduit == false)
	{
	  PROGRESSBAR_DECMAX;
	  goto next;
	}

	goto next_inc;
      }
    }

    MemHandleUnlock(pv_tr);

 next_inc:
    index++;

 next:
    PROGRESSBAR_INLOOP(index, 25); // XXX normalement avant ++
  }

  if (uh_purge == PURGE_IN_ACCOUNT)
  {
    if (l_sum != 0)
    {
      struct s_account_prop *ps_prop;

  in_account:
      ps_prop = [oTransactions
		  accountProperties:ACCOUNT_PROP_RECORDGET | uh_account
		  index:NULL];

      l_sum += ps_prop->l_amount;

      DmWrite(ps_prop, offsetof(struct s_account_prop, l_amount),
	      &l_sum, sizeof(l_sum));

      [oTransactions recordRelease:true];
    }
  }
  else
  {
    DBItemId *oItems;
    Char *pa_name;
    UInt32 *pl_sum;
    struct s_transaction s_tr;
    DateTimeType s_datetime;
    UInt16 uh_len, uh_record_num;

    TimSecondsToDateTime(TimGetSeconds(), &s_datetime);

    s_tr.s_date.day = s_datetime.day;
    s_tr.s_date.month = s_datetime.month;
    s_tr.s_date.year = s_datetime.year - firstYear;

    s_tr.s_time.hours = s_datetime.hour;
    s_tr.s_time.minutes = s_datetime.minute;

    s_tr.ui_rec_flags = (RECORD_CHECKED
			 | ((UInt32)TYPE_UNFILED << RECORD_TYPE_SHIFT)
			 | ((UInt32)MODE_UNKNOWN << RECORD_MODE_SHIFT));

    if (uh_purge == PURGE_BY_TYPE)
      oItems = (DBItemId*)[oMaTirelire type];
    else			// PURGE_BY_MODE
      oItems = (DBItemId*)[oMaTirelire mode];

    // Rassemblement des pointés...
    PROGRESSBAR_LABEL(strProgressBarPurgeGather);

    for (index = 0, pl_sum = pl_sums; index < uh_nb_sums; index++, pl_sum++)
    {
      if (*pl_sum != 0)
      {
	s_tr.l_amount = *pl_sum;

	pa_name = [oItems fullNameOfId:index len:&uh_len];

	if (uh_purge == PURGE_BY_TYPE)
	{
	  // Type inexistant, on met le tout dans la partie Unfiled
	  if (pa_name == NULL)
	  {
	    if (index != TYPE_UNFILED)
	      pl_sums[TYPE_UNFILED] += *pl_sum;
	    else
	      l_sum += *pl_sum;	// Biz, pas réussi à allouer pour le nom...
	    continue;
	  }

	  s_tr.ui_rec_type = index;
	}
	else			// PURGE_BY_MODE
	{
	  // Mode inexistant, on met le tout dans la partie Unknown
	  if (pa_name == NULL)
	  {
	    if (index != MODE_UNKNOWN)
	      pl_sums[MODE_UNKNOWN] += *pl_sum;
	    else
	      l_sum += *pl_sum;	// Biz, pas réussi à allouer pour le nom...
	    continue;
	  }

	  s_tr.ui_rec_mode = index;
	}

	// L'opération...
	NEW_PTR(ps_tr, sizeof(s_tr) + uh_len + 1,
		// Pb d'allocation, au pire on remettra tout ça dans les
		// propriétés du compte...
		l_sum += *pl_sum);

	MemMove(ps_tr, &s_tr, sizeof(s_tr));
	MemMove(ps_tr->ra_note, pa_name, uh_len + 1); // Avec \0

	MemPtrFree(pa_name);

	uh_record_num = dmMaxRecordIndex; // Nouvelle opération
	if ([oTransactions save:ps_tr size:sizeof(s_tr) + uh_len + 1
			   asId:&uh_record_num
			   account:uh_account xferAccount:-1] == false)
	  // Pb d'allocation, au pire on remettra tout ça dans les
	  // propriétés du compte...
	  l_sum += *pl_sum;

	MemPtrFree(ps_tr);

	PROGRESSBAR_INLOOP(__oProgressBar->ui_max_value	// OK
			   - uh_nb_sums + index + 1, 5);
      }
    }

    MemPtrFree(pl_sums);

    // On a eu des problèmes d'allocation, on modifie juste la somme
    // du compte
    if (l_sum != 0)
      goto in_account;
  }

  PROGRESSBAR_END;

  // On place la prochaine alarme, car elle vient d'être
  // désactivée par un des -deleteId: qui ont précédé
  // XXX (sauf si on ne supprime pas les RECORD_ALARM) XXX
  if (uh_reschedule_alarm & TR_DEL_MUST_RESCHED_ALARM)
    alarm_schedule_all();
}

@end
