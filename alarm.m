/* 
 * alarm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Lun mar  7 22:06:04 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Wed Dec 12 09:12:35 2007
 * Update Count    : 5
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: alarm.m,v $
 * Revision 1.4  2008/01/14 13:08:56  max
 * Switch to new mcc.
 *
 * Revision 1.3  2006/06/23 13:25:34  max
 * s/oMaTirelire/oLocalMaTirelire/g;
 *
 * Revision 1.2  2005/05/08 12:13:10  max
 * Check for account properties when searching alarm.
 *
 * Revision 1.1  2005/03/27 20:42:34  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_ALARMFORM
#include "alarm.h"

#include "MaTirelire.h"
#include "Transaction.h"

#include "float.h"
#include "misc.h"

#include "ids.h"
#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


struct s_alarm_infos
{
  LocalID  ui_lid;		// Base qui contient l'opération
  UInt16   uh_cardno;
  UInt32   ui_unique_id;	// Unique ID de l'opération
};


static void __alarm_draw(FormType *pt_frm)
{
  MemHandle pv_infos;
  struct s_alarm_infos *ps_alarm;
  DmOpenRef db;
  MaTirelire *oLocalMaTirelire;
  Currency *oCurrencies;

  Char ra_format[64];
  Char ra_date[longDateStrLength], ra_time[timeStringLength];
  Char ra_tmp[longDateStrLength + timeStringLength + sizeof(ra_format)];
  Char *pa_cur;

  UInt16 uh_rec, index, uh_num, uh_tr_height;

  UInt16 uh_desc_lines, uh_hfont, uh_height, uh_len, uh_y;
  FontID uh_font;

  oLocalMaTirelire = [MaTirelire appli];
  oCurrencies = [oLocalMaTirelire currency];

  if (oLocalMaTirelire->uh_color_enabled)
  {
    WinPushDrawState();

    WinSetForeColor(UIColorGetTableEntryIndex(UIDialogFrame));
    WinSetBackColor(UIColorGetTableEntryIndex(UIDialogFill));
    WinSetTextColor(UIColorGetTableEntryIndex(UIObjectForeground));
  }

  uh_font = FntSetFont(stdFont);
  uh_hfont = FntLineHeight();

  pv_infos = FrmGetGadgetData(pt_frm, FrmGetObjectIndex(pt_frm, AlarmGadget));

#define X_OFFSET	4
#define LINE_MARGIN	20
#define Y_OFFSET	(12 + 5)
#define ALARM_WIDTH	156
#define ALARM_HEIGHT	108
#define uh_lines	2	/* Date et Somme */

  uh_y = Y_OFFSET;
  SysCopyStringResource(ra_format, strTransListDateTime);

  uh_num = MemHandleSize(pv_infos) / sizeof(struct s_alarm_infos);
  uh_tr_height = ALARM_HEIGHT / uh_num;
  if (uh_tr_height < uh_hfont * (uh_lines + 1) + 2) // Moins que le minimum...
  {
    uh_tr_height = uh_hfont * (uh_lines + 1) + 2;
    uh_num = ALARM_HEIGHT / uh_tr_height;
  }
  else
    uh_tr_height -= 2;		// Pour la ligne séparatrice...

  ps_alarm = MemHandleLock(pv_infos);

  for (index = uh_num; index-- > 0; )
  {
    db = DmOpenDatabase(ps_alarm->uh_cardno, ps_alarm->ui_lid, dmModeReadOnly);

    if (DmFindRecordByID(db, ps_alarm->ui_unique_id, &uh_rec) == 0)
    {
      MemHandle pv_rec;
      struct s_transaction *ps_tr;
      struct s_rec_options s_options;

      pv_rec = DmQueryRecord(db, uh_rec); // Sans test => DmFindRecordByID OK
      ps_tr = MemHandleLock(pv_rec);

      // Dessin...
      options_extract(ps_tr, &s_options);

      pa_cur = s_options.pa_note;
      uh_desc_lines = (*pa_cur == '\0')
	? 0
	: FldCalcFieldHeight(pa_cur, ALARM_WIDTH - X_OFFSET * 2);

      /* lignes de base et lignes description */
      uh_height = uh_hfont * (uh_lines + uh_desc_lines);
      if (uh_height > uh_tr_height) /* Trop de lignes */
      {
	/* On réduit le nombre de lignes affichées... */
	uh_desc_lines = uh_tr_height / uh_hfont - uh_lines;
	uh_height = uh_hfont * (uh_desc_lines + uh_lines);
      }

      // Date
      DateToAscii(ps_tr->s_date.month, ps_tr->s_date.day,
		  ps_tr->s_date.year + firstYear,
		  (DateFormatType)PrefGetPreference(prefLongDateFormat),
		  ra_date);
      TimeToAscii(ps_tr->s_time.hours, ps_tr->s_time.minutes,
		  (TimeFormatType)PrefGetPreference(prefTimeFormat), ra_time);
      uh_len = StrPrintF(ra_tmp, ra_format, ra_date, ra_time);
      WinDrawChars(ra_tmp, uh_len, X_OFFSET, uh_y);

      // Affichage de la note
      while (uh_desc_lines-- > 0)
      {
	uh_y += uh_hfont;
	uh_len = FldWordWrap(pa_cur, ALARM_WIDTH - X_OFFSET * 2);
	if (uh_len > 0)
	{
	  WinDrawChars(pa_cur, uh_len - (pa_cur[uh_len - 1] == '\n'),
		       X_OFFSET, uh_y);
	  pa_cur += uh_len;
	}
      }

      // La somme
      uh_y += uh_hfont;
      FntSetFont(boldFont);
      Str100FToA(ra_tmp,
		 ps_tr->ui_rec_currency
		 ? s_options.ps_currency->l_currency_amount
		 : ps_tr->l_amount, &uh_len, float_dec_separator());
      WinDrawChars(ra_tmp, uh_len, X_OFFSET, uh_y);

      // Suivie de la devise
      FntSetFont(stdFont);
      // XXX X_OFFSET + ...
      FntCharsWidth(ra_tmp, uh_len);

      MemHandleUnlock(pv_rec);

      uh_y += uh_hfont;

      if (index > 0)
      {
	uh_y++;

	// On tire une ligne horizontale
	WinDrawLine(X_OFFSET + LINE_MARGIN, uh_y,
		    ALARM_WIDTH - X_OFFSET - LINE_MARGIN, uh_y);

	uh_y++;
      }
    }

    DmCloseDatabase(db);

    ps_alarm++;
  }

  MemHandleUnlock(pv_infos);

  if (oLocalMaTirelire->uh_color_enabled)
    WinPopDrawState();
  else
    FntSetFont(uh_font);
}


static Boolean __alarm_form_handler(EventPtr e)
{
  Boolean handled = true;

  switch (e->eType)
  {
    // Pas de lancement d'appli pendant l'affichage de notre boîte
  case appStopEvent:
    break;

  case frmUpdateEvent:
  {
    FormType *pt_frm;

    pt_frm = FrmGetActiveForm();
    FrmDrawForm(pt_frm);

    __alarm_draw(pt_frm);
  }
  break;

  default:
    handled = false;
    break;
  }

  return handled;
}


static void __alarm_tr_del_alarm(DmOpenRef db, UInt16 index)
{
  MemHandle pv_rec;
  struct s_transaction *ps_tr;
  union u_rec_flags u_flags;

  pv_rec = DmGetRecord(db, index);

  ps_tr = MemHandleLock(pv_rec);

  u_flags = ps_tr->u_flags;
  u_flags.s_bit.ui_alarm = 0;
  DmWrite(ps_tr, offsetof(struct s_transaction, u_flags),
	  &u_flags, sizeof(u_flags));
	      
  MemHandleUnlock(pv_rec);

  DmReleaseRecord(db, index, true);
}


//
// L'alarme vient de se déclencher, on va vérifier qu'elle est encore
// d'actualité. On doit passer un minimum de temps dans cette
// fonction.
void alarm_triggered(SysAlarmTriggeredParamType *cmdPBP)
{
  cmdPBP->purgeAlarm = true;

  if (cmdPBP->ref != NULL)
  {
    struct s_alarm_infos *ps_alarm, *ps_cur;
    DmOpenRef db;
    UInt16 uh_rec, uh_size;
    Boolean b_ok;

    ps_alarm = ps_cur = MemHandleLock((MemHandle)cmdPBP->ref);

    uh_size = MemHandleSize((MemHandle)cmdPBP->ref);
    while (uh_size >= sizeof(struct s_alarm_infos))
    {
      db = DmOpenDatabase(ps_alarm->uh_cardno, ps_alarm->ui_lid,
			  dmModeReadOnly);

      b_ok = false;

      // On regarde si l'opération existe
      if (DmFindRecordByID(db, ps_alarm->ui_unique_id, &uh_rec) == 0)
      {
	MemHandle pv_rec;
	struct s_transaction *ps_tr;
	DateTimeType s_tr_date;

	pv_rec = DmQueryRecord(db, uh_rec); // Sans test => DmFindRecordByID OK
	ps_tr = MemHandleLock(pv_rec);

	s_tr_date.second = 0;
	s_tr_date.minute = ps_tr->s_time.minutes;
	s_tr_date.hour = ps_tr->s_time.hours;
	s_tr_date.day = ps_tr->s_date.day;
	s_tr_date.month = ps_tr->s_date.month;
	s_tr_date.year = ps_tr->s_date.year + firstYear;

	MemHandleUnlock(pv_rec);

	if (TimDateTimeToSeconds(&s_tr_date) == cmdPBP->alarmSeconds)
	{
	  // On retire le flag d'alarme de l'opération
	  __alarm_tr_del_alarm(db, uh_rec);

	  cmdPBP->purgeAlarm = false;
	  b_ok = true;
	}
      }

      DmCloseDatabase(db);

      // Ce qu'il reste
      uh_size -= sizeof(struct s_alarm_infos);

      // Cette opération n'est pas à prendre
      if (b_ok == false)
      {
	UInt32 ui_offset = (Char*)ps_cur - (Char*)ps_alarm;

	// On ramène ce qu'il reste à la fin
	if (uh_size > 0)
	  DmWrite(ps_alarm, ui_offset, ps_cur + 1, uh_size);

	// On peut réduire même locké, mais pas à 0 (dans ce cas le
	// chunk sera libéré à la fin de la boucle)...
	ui_offset += uh_size;
	if (ui_offset > 0)
	  MemHandleResize((MemHandle)cmdPBP->ref, ui_offset);
      }
      else
	ps_cur++;
    }

    MemHandleUnlock((MemHandle)cmdPBP->ref);

    // Il n'y aura pas de suite : aucune opération n'a été trouvée...
    if (cmdPBP->purgeAlarm)
      MemHandleFree((MemHandle)cmdPBP->ref);
  }

  alarm_schedule_all();
}


//
// Le moment est venu d'afficher la boîte d'alarme
void alarm_display(SysDisplayAlarmParamType *cmdPBP)
{
  if (cmdPBP->ref != NULL)
  {
    FormType *pt_frm, *pt_cur_frm;

    SndPlaySystemSound(sndAlarm);

    pt_frm = FrmInitForm(AlarmFormIdx);

    pt_cur_frm = FrmGetActiveForm();
    if (pt_cur_frm)
      FrmSetActiveForm(pt_frm);

    // Set the event handler for the alarm dialog.
    FrmSetEventHandler(pt_frm, __alarm_form_handler);

    // Store the infomation necessary to draw the alarm's description
    // in a gadget object.  This allows us to redraw the 
    // description on a frmUpdate event.
    FrmSetGadgetData(pt_frm, FrmGetObjectIndex(pt_frm, AlarmGadget),
		     (const void*)cmdPBP->ref);

    FrmDrawForm(pt_frm);

    __alarm_draw(pt_frm);

    // Display the alarm dialog
    FrmDoDialog(pt_frm);

    FrmDeleteForm(pt_frm);
    FrmSetActiveForm(pt_cur_frm);

    // Libération
    MemHandleFree((MemHandle)cmdPBP->ref);
  }
}


// Ajoute, remplace ou enlève l'alarme correspondant à
// l'enregistrement, dont la base et l'index sont passés en paramètre,
// dans la zone de mémoire pointée par *ppv_infos (qui peut-être NULL,
// dans ce cas la zone est allouée et renvoyée à la même place).
#define ALARM_ADDEL_DELETE	0x0000
#define ALARM_ADDEL_ADD		0x0001
#define ALARM_ADDEL_REPLACE	0x0002
//#define ALARM_ADDEL_SET_ALARM	0x8000 // Que avec ALARM_ADDEL_SET_ALARM
static Boolean __alarm_addel(DmOpenRef db, UInt16 index, MemHandle *ppv_infos,
			     UInt16 uh_flags)
{
  struct s_alarm_infos *ps_alarm_base;
  UInt32 ui_unique_id;
  LocalID ui_lid;
  UInt16 uh_cardno, uh_size;

  DmRecordInfo(db, index, NULL, &ui_unique_id, NULL);
  DmOpenDatabaseInfo(db, &ui_lid, NULL, NULL, &uh_cardno, NULL);

  //
  // La zone existe déjà
  if (*ppv_infos != NULL)
  {
    struct s_alarm_infos *ps_alarm;
    Boolean b_free, b_found;

    // Il faut remplacer la totalité de la zone
    if (uh_flags == ALARM_ADDEL_REPLACE)
    {
      uh_size = 0;

      if (MemHandleResize(*ppv_infos, sizeof(struct s_alarm_infos)) == 0)
	goto add_to_zone;

      // XXX
      return false;
    }

    b_free = false;
    b_found = false;

    ps_alarm_base = ps_alarm = MemHandleLock(*ppv_infos);

    // On parcourt la zone pour voir si l'opération est présente
    for (uh_size = MemHandleSize(*ppv_infos); uh_size > 0; ps_alarm++)
    {
      uh_size -= sizeof(struct s_alarm_infos);

      // On vient de trouver l'opération...
      if (ps_alarm->ui_lid == ui_lid && ps_alarm->uh_cardno == uh_cardno
	  && ps_alarm->ui_unique_id == ui_unique_id)
      {
	// Il faut supprimer cet emplacement
	if (uh_flags == ALARM_ADDEL_DELETE)
	{
	  // C'est la seule opération de la zone : il faut libérer la zone
	  if (uh_size == 0 && ps_alarm_base == ps_alarm)
	    b_free = true;
	  // Il faut décaler la fin
	  else
	  {
	    UInt32 ui_offset = (Char*)ps_alarm - (Char*)ps_alarm_base;

	    // On ramène ce qu'il reste à la fin
	    if (uh_size > 0)
	      DmWrite(ps_alarm_base, ui_offset, ps_alarm + 1, uh_size);

	    // On peut réduire même locké...
	    MemHandleResize(*ppv_infos, ui_offset + uh_size);
	  }
	}

	// Dans le cas de l'ajout il n'y a rien à faire
	b_found = true;

	break;
      }
    }

    MemHandleUnlock(*ppv_infos);

    // Il faut ôter l'opération
    if (uh_flags == ALARM_ADDEL_DELETE)
    {
      // La zone est maintenant vide
      if (b_free)
      {
	MemHandleFree(*ppv_infos);
	*ppv_infos = NULL;
      }
    }
    // Il faut ajouter l'opération...
    else
    {
      // ...car elle n'a pas été trouvée
      if (b_found == false)
      {
	uh_size = MemHandleSize(*ppv_infos);

	if (MemHandleResize(*ppv_infos, 
			    uh_size + sizeof(struct s_alarm_infos)) == 0)
	  goto add_to_zone;

	// XXX
	return false;
      }
    }
  }
  //
  // La zone n'existe pas
  else
  {
    DmOpenRef db_app;
    struct s_alarm_infos s_alarm;
    LocalID ui_app_lid;
    UInt16 uh_app_cardno;

    // Il faut faire une suppression : pas de zone => rien à supprimer
    if (uh_flags == ALARM_ADDEL_DELETE)
      return true;

    // Il faut faire un ajout
    SysCurAppDatabase(&uh_app_cardno, &ui_app_lid);

    db_app = DmOpenDatabase(uh_app_cardno, ui_app_lid, dmModeReadOnly);
    *ppv_infos = DmNewHandle(db_app, sizeof(struct s_alarm_infos));
    DmCloseDatabase(db_app);

    if (*ppv_infos == NULL)
    {
      // XXX
      return false;
    }

    uh_size = 0;

 add_to_zone:
    s_alarm.ui_lid = ui_lid;
    s_alarm.uh_cardno = uh_cardno;
    s_alarm.ui_unique_id = ui_unique_id;

    ps_alarm_base = MemHandleLock(*ppv_infos);

    DmWrite(ps_alarm_base, uh_size,
	    &s_alarm, sizeof(struct s_alarm_infos));

    MemHandleUnlock(*ppv_infos);
  }

  return true;
}


void alarm_schedule_all(void)
{
  MemHandle hdl_dbs;
  SysDBListItemType *ps_db;
  MemHandle pv_infos;
  DateTimeType s_tr_date;
  UInt32 ui_alarm_secs = 0xffffffff, ui_cur_secs, ui_now_secs;
  LocalID ui_app_lid;
  UInt16 uh_app_cardno;
  UInt16 uh_num_dbs, uh_db;

  // On anticipe de 20 secondes au cas où la recherche durerait un
  // certain temps...
  ui_now_secs = TimGetSeconds() + 20;

  SysCurAppDatabase(&uh_app_cardno, &ui_app_lid);

  // Alarme courante supprimée
  if (AlmGetAlarm(uh_app_cardno, ui_app_lid, (UInt32*)&pv_infos) != 0)
    AlmSetAlarm(uh_app_cardno, ui_app_lid, 0, 0, true);
  else
    pv_infos = NULL;

  if (SysCreateDataBaseList(MaTiAccountsType, MaTiCreatorID,
			    &uh_num_dbs, &hdl_dbs, false)
      && uh_num_dbs > 0)
  {
    ps_db = MemHandleLock(hdl_dbs);

    for (uh_db = 0; uh_db < uh_num_dbs; uh_db++, ps_db++)
    {
      DmOpenRef db;
      MemHandle pv_rec;
      struct s_transaction *ps_tr;
      UInt16 index;

      db = DmOpenDatabase(ps_db->cardNo, ps_db->dbID, dmModeReadOnly);

      for (index = DmNumRecords(db); index-- > 0; )
      {
	pv_rec = DmQueryRecord(db, index);
	if (pv_rec != NULL)
	{
	  ps_tr = MemHandleLock(pv_rec);

	  if (DateToInt(ps_tr->s_date) != 0 && ps_tr->ui_rec_alarm)
	  {
	    s_tr_date.second = 0;
	    s_tr_date.minute = ps_tr->s_time.minutes;
	    s_tr_date.hour = ps_tr->s_time.hours;
	    s_tr_date.day = ps_tr->s_date.day;
	    s_tr_date.month = ps_tr->s_date.month;
	    s_tr_date.year = ps_tr->s_date.year + firstYear;

	    MemHandleUnlock(pv_rec);

	    // Calcul du nombre de secondes correspondant à cette date
	    ui_cur_secs = TimDateTimeToSeconds(&s_tr_date);

	    // Alarme avant maintenant => il faut retirer le flag
	    // d'alarme de cette opération
	    if (ui_cur_secs <= ui_now_secs)
	      __alarm_tr_del_alarm(db, index);
	    // Cette opération échoie avant ou en même temps que
	    // l'alarme courante
	    else if (ui_cur_secs <= ui_alarm_secs)
	    {
	      // En même temps : il faut ajouter cette opération
	      if (ui_cur_secs == ui_alarm_secs)
		__alarm_addel(db, index, &pv_infos, ALARM_ADDEL_ADD);
	      // Avant : il faut remplacer l'alarme courante
	      else
	      {
		__alarm_addel(db, index, &pv_infos, ALARM_ADDEL_REPLACE);

		// Nouvelle alarme
		ui_alarm_secs = ui_cur_secs;

		AlmSetAlarm(uh_app_cardno, ui_app_lid,
			    (UInt32)pv_infos, ui_alarm_secs, true);
	      }
	    }

	    continue;
	  }

	  MemHandleUnlock(pv_rec);
	}
      }

      DmCloseDatabase(db);
    }

    MemHandleUnlock(hdl_dbs);
    MemHandleFree(hdl_dbs);
  }
}


//
// Renvoie true si l'alarme de l'application vient d'être desactivée
Boolean alarm_schedule_transaction(DmOpenRef db, UInt16 uh_rec,
				   Boolean b_force_unschedule)
{
  MemHandle pv_rec;
  struct s_transaction *ps_tr;
  LocalID ui_app_lid;
  UInt16 uh_app_cardno;

  pv_rec = DmQueryRecord(db, uh_rec);
  if (pv_rec != NULL)
  {
    UInt32 ui_alarm_secs, ui_cur_secs;
    MemHandle pv_infos;
    DateTimeType s_tr_date;
    Boolean b_alarm;

    ps_tr = MemHandleLock(pv_rec);

    s_tr_date.second = 0;
    s_tr_date.minute = ps_tr->s_time.minutes;
    s_tr_date.hour = ps_tr->s_time.hours;
    s_tr_date.day = ps_tr->s_date.day;
    s_tr_date.month = ps_tr->s_date.month;
    s_tr_date.year = ps_tr->s_date.year + firstYear;

    // Si le flag b_unschedule est passé en paramètre, on se fout du
    // flag d'alarme de l'opération
    b_alarm = ps_tr->ui_rec_alarm && (b_force_unschedule == false);

    MemHandleUnlock(pv_rec);

    SysCurAppDatabase(&uh_app_cardno, &ui_app_lid);

    ui_alarm_secs = AlmGetAlarm(uh_app_cardno, ui_app_lid, (UInt32*)&pv_infos);
    if (ui_alarm_secs == 0)
    {
      ui_alarm_secs = 0xffffffff;
      pv_infos = NULL;
    }

    if (b_alarm)
    {
      ui_cur_secs = TimDateTimeToSeconds(&s_tr_date);

      // Avant maintenant (+ sécurité) il faut supprimer le flag
      // d'alarme de l'opération
      if (ui_cur_secs <= TimGetSeconds() + 20)
      {
	__alarm_tr_del_alarm(db, uh_rec);
	goto verify_alarm_contents;
      }

      // Cette opération échoie en même temps que l'alarme courante :
      // il faut ajouter cette opération
      if (ui_cur_secs == ui_alarm_secs)
	__alarm_addel(db, uh_rec, &pv_infos, ALARM_ADDEL_ADD);
      // Cette opération échoie avant l'alarme courante : il faut
      // remplacer l'alarme courante
      else if (ui_cur_secs < ui_alarm_secs)
      {
	__alarm_addel(db, uh_rec, &pv_infos, ALARM_ADDEL_REPLACE);

	// Nouvelle alarme
	AlmSetAlarm(uh_app_cardno, ui_app_lid,
		    (UInt32)pv_infos, ui_cur_secs, true);
      }
      // L'échéance de l'alarme est plus proche que l'opération
      else
	goto verify_alarm_contents;
    }
    // Pas de flag d'alarme
    else
    {
  verify_alarm_contents:
      // Il y a une alarme actuellement
      if (ui_alarm_secs != 0xffffffff)
      {
	// Il faut vérifier si cette opération ne faisait pas partie de
	// l'alarme auparavant. Si c'est le cas, on l'ôte.
	__alarm_addel(db, uh_rec, &pv_infos, ALARM_ADDEL_DELETE);

	// La zone vient d'être libérée, il faut supprimer l'alarme...
	if (pv_infos == NULL)
	{
	  SysCurAppDatabase(&uh_app_cardno, &ui_app_lid);

	  AlmSetAlarm(uh_app_cardno, ui_app_lid, 0, 0, true);

	  return true;
	}
      }
    }
  }

  return false;
}
