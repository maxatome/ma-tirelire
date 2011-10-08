/* 
 * DBasePropForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Jeu jul  1 19:31:25 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Wed Dec 12 10:29:15 2007
 * Update Count    : 24
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: DBasePropForm.m,v $
 * Revision 1.17  2008/01/14 17:09:32  max
 * Switch to new mcc.
 *
 * Revision 1.16  2006/06/23 13:24:43  max
 * Now call -focusObject: instead of FrmSetFocus() to set focus to a field.
 *
 * Revision 1.15  2006/06/19 12:24:44  max
 * Delete empty -menu method.
 *
 * Revision 1.14  2006/04/25 08:46:48  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 * -ctlSelect: calls now super one to handle tabs clicks.
 *
 * Revision 1.13  2005/11/19 16:56:25  max
 * Redraws reworked.
 * Last edited database is now selected in databases list.
 * Add "Transactions lists" tab, including "type instead of description"
 * option.
 *
 * Revision 1.12  2005/10/06 20:23:52  max
 * Compute repeats when needed at form exit: now works correctly.
 *
 * Revision 1.11  2005/10/06 19:56:49  max
 * Refresh transactions list after computing repeats.
 *
 * Revision 1.10  2005/10/06 19:48:13  max
 * s/ul_repeat_startup/ul_auto_repeat/
 * Auto repeat is now on by default on new DBs.
 * Compute repeats when needed at form exit.
 *
 * Revision 1.9  2005/08/31 19:43:05  max
 * Withdrawal date sort reworked. Now the withdrawal date is taken first
 * (as before) then the transaction date (new), then the transaction
 * time.
 * Transaction.m now handle sorts.
 *
 * Revision 1.8  2005/08/31 19:38:52  max
 * *** empty log message ***
 *
 * Revision 1.7  2005/08/20 13:06:48  max
 * Updates are now genericaly managed by MaTiForm.
 *
 * Revision 1.6  2005/05/08 12:12:55  max
 * Code cleaning.
 *
 * Revision 1.5  2005/03/27 15:38:21  max
 * alert_error() moved to misc.c
 * DBase can now be launchable (when a database is launchable, the
 * `MaTi=' prefix is omitted.)
 * Sort implemented.
 * Display date choice update transactions list screen correctly.
 * Backup bit is now set systematically.
 *
 * Revision 1.4  2005/03/02 19:02:35  max
 * For new databases the "Use conduit" flag default value is inherited
 * from Ma Tirelire preferences.
 * Swap buttons in alertDBaseDelete.
 *
 * Revision 1.3  2005/02/19 17:11:19  max
 * DB properties can now be called from everywhere.
 *
 * Revision 1.2  2005/02/13 00:06:17  max
 * Change prototype of -keyFilter:for:
 * It allows to detect and not block special keys in numeric fields.
 * Now the Select key of the 5-way works everywhere...
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_DBASEPROPFORM
#include "DBasePropForm.h"

#include "MaTirelire.h"
#include "DBasesListForm.h"
#include "AccountsListForm.h"

#include "misc.h"
#include "db_list.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX
#include "ids.h"


@implementation DBasePropForm

- (DBasePropForm*)init
{
  self->uh_tabs_num = 4;

  return [super init];
}


- (Boolean)extractAndSave
{
  LocalID ui_dbid;
  struct s_db_prefs *ps_db_prefs;
  Char ra_db_name[MaTiAcntPrefixLen + dmDBNameLength];
  UInt16 uh_cardno, uh_size, uh_note_size, uh_repeat_days, uh_update_code = 0;
  UInt16 uh_attributes, uh_old_repeat_days;
  Err error;
  Boolean b_ret, b_resort, b_launchable, b_exe_repeats, b_old_auto_repeat;

  // To avoid GCC warnings
  uh_old_repeat_days = 0;
  b_old_auto_repeat = false;
  // *********************

  // Base exécutable
  b_launchable = CtlGetValue([self objectPtrId:DBasePropLaunchable]);

  // Le nom de la base ne doit pas être vide
  // Si la base est "launchable", on ne met pas le préfixe "MaTi="
  if ([self checkField:DBasePropName flags:FLD_CHECK_VOID
	    resultIn:&ra_db_name[b_launchable ? 0 : MaTiAcntPrefixLen]
	    fieldName:strDBasePropName] == false)
    return false;
  if (b_launchable == false)
    MemMove(ra_db_name, MaTiAcntPrefix, MaTiAcntPrefixLen); // Ajout préfixe
  ra_db_name[dmDBNameLength - 1] = '\0'; // On tronque à la longueur max

  // Si on est appelé depuis la liste des bases, on redonne le nom de la base
  if ([(Object*)self->oPrevForm->oIsa isKindOf:DBasesListForm])
    StrCopy(((DBasesListForm*)self->oPrevForm)->ra_db_name, ra_db_name);

  // Visualisation des répétitions N jours avant
  if ([self checkField:DBasePropRepeatDays flags:FLD_CHECK_VOID|FLD_TYPE_WORD
	    resultIn:&uh_repeat_days
	    fieldName:strDBasePropRepeatDays] == false)
    return false;

  // La base n'existe pas encore, il faut la créer
  if (self->vh_db_prefs == NULL && self->uh_transaction == false)
  {
    error = DmCreateDatabase(0, ra_db_name,
			     MaTiCreatorID, MaTiAccountsType, false);
    if (error)
    {
      alert_error(error);
      return false;
    }

    ui_dbid = DmFindDatabase(0, ra_db_name);
    if (ui_dbid == 0)
    {
      // XXXX
      return false;
    }

    uh_cardno = 0;

    uh_update_code = frmMaTiUpdateList | frmMaTiUpdateListDBases;
  }
  // La base existe déjà
  else
  {
    // Changement de nom ?
    if (StrCompare(ra_db_name, self->ra_name) != 0)
    {
      error = DmSetDatabaseInfo(self->uh_card_no, self->ui_db_id, ra_db_name,
				NULL, NULL, NULL, NULL, NULL,
				NULL, NULL, NULL, NULL, NULL);
      if (error)
      {
	alert_error(error);
	return false;
      }

      uh_update_code = frmMaTiUpdateList | frmMaTiUpdateListDBases;
    }

    ui_dbid = self->ui_db_id;
    uh_cardno = self->uh_card_no;
  }

  // On met systématiquement le bit de backup en place (et le
  // launchable si besoin)
  DmDatabaseInfo(uh_cardno, ui_dbid, NULL, &uh_attributes, NULL, NULL,
		 NULL, NULL, NULL, NULL, NULL, NULL, NULL);
  uh_attributes |= dmHdrAttrBackup;
  if (b_launchable)
    uh_attributes |= dmHdrAttrLaunchableData;
  else
    uh_attributes &= ~dmHdrAttrLaunchableData;
  DmSetDatabaseInfo(uh_cardno, ui_dbid, NULL, &uh_attributes,
		    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

  // On prépare l'écriture du AppInfoBlock
  uh_note_size = FldGetTextLength([self objectPtrId:DBasePropNote]);
  uh_size = sizeof(struct s_db_prefs) + 1 // + 1 for \0 of ra_note
    + uh_note_size;

  NEW_PTR(ps_db_prefs, uh_size,
	  // XXX il faudrait supprimer la base si self->vh_db_prefs == NULL
	  return false);

  if (self->vh_db_prefs == NULL)
  {
    // La base a déjà chargé ses préférences (AccountsListForm)
    if (self->uh_transaction)
    {
      Transaction *oTransaction = [oMaTirelire transaction];

      // On copie les valeurs actuelles sans la note
      MemMove(ps_db_prefs, oTransaction->ps_prefs, sizeof(struct s_db_prefs));

      b_old_auto_repeat  = ps_db_prefs->ul_auto_repeat;
      uh_old_repeat_days = ps_db_prefs->ul_repeat_days;

      // On sauve les préférences actuelles avec retour en état initial
      [oTransaction savePrefs];
    }
    // La base vient d'être créée, on initialise tout à 0
    else
      MemSet(ps_db_prefs, sizeof(struct s_db_prefs), '\0');
  }
  else
  {
    // On copie les valeurs actuelles sans la note
    MemMove(ps_db_prefs, MemHandleLock(self->vh_db_prefs),
	    sizeof(struct s_db_prefs));
    MemHandleUnlock(self->vh_db_prefs);
  }

  // On sauve le contenu du formulaire...
  
  //
  // Onglet "Général"
  //
  // Exe des répètitions au démarrage
  ps_db_prefs->ul_auto_repeat
    = CtlGetValue([self objectPtrId:DBasePropAutoRepeat]);

  // Visualisation des répétitions N jours avant
  if (uh_repeat_days >= (1 << 7))
    uh_repeat_days = (1 << 7) - 1;
  ps_db_prefs->ul_repeat_days = uh_repeat_days;

  // Utilisation de la conduite
  ps_db_prefs->ul_remove_type
    = CtlGetValue([self objectPtrId:DBasePropRemoveType]);

  //
  // Onglet Listes d'opérations
  //
  // Trier par date de valeur
  ps_db_prefs->ul_sort_type
    = CtlGetValue([self objectPtrId:DBasePropSortType]);
  b_resort = (ps_db_prefs->ul_sort_type != self->uh_sort_type);
  if (b_resort)
    uh_update_code |= frmMaTiUpdateList | frmMaTiUpdateListTransactions;

  // Afficher la date de valeur
  ps_db_prefs->ul_list_date
    = CtlGetValue([self objectPtrId:DBasePropValueDate]);
  if (ps_db_prefs->ul_list_date != self->uh_list_date)
    uh_update_code |= frmMaTiUpdateList | frmMaTiUpdateListTransactions;

  // Afficher le type au lieu de la description
  ps_db_prefs->ul_list_type
    = CtlGetValue([self objectPtrId:DBasePropTypeForDesc]);
  if (ps_db_prefs->ul_list_type != self->uh_list_type)
    uh_update_code |= frmMaTiUpdateList | frmMaTiUpdateListTypes;
  // Juste un redraw à faire...

  //
  // Onglet "Sécurité"
  //
  // Code d'accès à la base
  ps_db_prefs->ul_access_code = self->ul_current_code;

  // Accepter la recherche globale
  ps_db_prefs->ul_deny_find
    = CtlGetValue([self objectPtrId:DBasePropDenyFind]);

  //
  // Onglet "Note"
  //
  if (uh_note_size > 0)
    MemMove(ps_db_prefs->ra_note,
	    FldGetTextPtr([self objectPtrId:DBasePropNote]),
	    uh_note_size);
  ps_db_prefs->ra_note[uh_note_size] = '\0';

  b_ret = true;

  // Si la base est déjà chargée, on regarde s'il faut exécuter les répétitions
  b_exe_repeats = false;
  if (self->uh_transaction
      // ET les répétitions auto sont activées
      && ps_db_prefs->ul_auto_repeat
      // ET elles ne l'étaient pas avant
      && (b_old_auto_repeat == false
	    // OU BIEN le nouveau nombre de jours est plus grand
	    || uh_repeat_days > uh_old_repeat_days))
  {
    b_exe_repeats = true;
    uh_update_code |= frmMaTiUpdateList | frmMaTiUpdateListTransactions;
  }

  // Écriture du bloc
  if (db_app_info_block_save(NULL, uh_cardno, ui_dbid,
			     ps_db_prefs, uh_size, 0))
  {
    // XXX
    b_ret = false;
  }
  else if (uh_update_code != 0)
    self->ui_update_mati_list |= uh_update_code;

  MemPtrFree(ps_db_prefs);

  // Si la base est déjà chargée, on recharge les préférences avant de quitter
  if (self->uh_transaction)
  {
    Transaction *oTransactions = [oMaTirelire transaction];

    [oTransactions getPrefs];

    // On modifie le nom de la base dans les préférences de l'application
    if (uh_update_code != 0)
      MemMove([oMaTirelire getPrefs]->ra_last_db, ra_db_name, dmDBNameLength);

    if (b_ret)
    {
      // Il faut exécuter les répétitions
      if (b_exe_repeats)
	[oTransactions computeAllRepeats:true onMaxDays:0];

      // Il faut retrier la base
      if (b_resort)
	// Si on triait par date, c'est l'inverse maintenant
	[oTransactions sortByValueDate:self->uh_sort_type == SORT_BY_DATE];
    }
  }
  else if (b_ret && b_resort)
  {
    DmOpenRef db;

    // Ouverture de la base
    db = DmOpenDatabase(uh_cardno, ui_dbid, dmModeReadWrite);
    if (db != NULL)
    {
      // Tri (si on triait par date, c'est l'inverse maintenant)
      DmQuickSort(db, self->uh_sort_type == SORT_BY_DATE
		  ? (DmComparF*)transaction_val_date_cmp
		  : (DmComparF*)transaction_std_cmp,
		  self->uh_sort_type == SORT_BY_DATE);

      DmCloseDatabase(db);
    }
  }

  return b_ret;
}


- (void)_changeCode
{
  Char ra_label[16 + 1];

  SysCopyStringResource(ra_label, self->ul_current_code
			? strPrefsCodeEnable : strPrefsCodeDisable);

  [self fillLabel:DBasePropCode withSTR:ra_label];
}


- (DBasePropForm*)free
{
  if (self->vh_db_prefs != NULL)
    MemHandleFree(self->vh_db_prefs);

  return [super free];
}


- (Boolean)open
{
  Transaction *oTransactions = NULL;
  Char ra_title[dmDBNameLength], *pa_title;
  UInt16 uh_repeat_days;
  Boolean b_new = false, b_remove_type, b_exe_repeats;

  // On vient de la liste des bases
  if ([(Object*)self->oPrevForm->oIsa isKindOf:DBasesListForm])
  {
    SysDBListItemType *ps_db;

    ps_db = [(DBasesListForm*)self->oPrevForm editedDB];
    if (ps_db == NULL)
      b_new = true;
    else
    {
      self->ui_db_id = ps_db->dbID;
      self->uh_card_no = ps_db->cardNo;
      MemMove(self->ra_name, ps_db->name, sizeof(self->ra_name));
    }
  }
  // On vient de la liste des comptes ou de la liste des opérations,
  // en tout cas la base est déjà ouverte, donc elle existe...
  else
  {
    self->uh_transaction = true;

    oTransactions = [oMaTirelire transaction];

    [oTransactions getCardNo:&self->uh_card_no andID:&self->ui_db_id];
    [oTransactions getName:self->ra_name];
  }

  // New
  if (b_new)
  {
    [self hideId:DBasePropDelete];

    SysCopyStringResource(ra_title, strTitleNewDBaseProp);
    pa_title = ra_title;

    //
    // Valeurs par défaut
    //
    // Exe des répètitions automatique, activé par défaut
    b_exe_repeats = true;

    // Utilisation de la conduite (idem préférences générales)
    b_remove_type = oMaTirelire->s_prefs.ul_remove_type;

    // Visualisation des répétitions N jours avant
    uh_repeat_days = 15;
  }
  // Edit
  else
  {
    UInt16 uh_attributes;
    struct s_db_prefs *ps_db_prefs;

    DmDatabaseInfo(self->uh_card_no, self->ui_db_id, NULL, &uh_attributes,
		   NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

    pa_title = db_list_visible_name(self->ra_name);

    // Si on vient de la liste des comptes ou des opérations, on ne
    // peut pas supprimer la base
    if (self->uh_transaction)
    {
      [self hideId:DBasePropDelete];

      ps_db_prefs = oTransactions->ps_prefs; // Forcément chargé ici
    }
    else
    {
      if (db_app_info_block_load(self->uh_card_no, self->ui_db_id,
				 (void**)&self->vh_db_prefs, NULL, true) != 0)
	// XXX
	;

      ps_db_prefs = MemHandleLock(self->vh_db_prefs);
    }

    // Le nom de la base
    [self replaceField:DBasePropName withSTR:pa_title len:-1];

    //
    // Onglet "Général"
    //
    // Base exécutable
    CtlSetValue([self objectPtrId:DBasePropLaunchable],
		(uh_attributes & dmHdrAttrLaunchableData) != 0);

    // Exe des répètitions automatique
    b_exe_repeats = ps_db_prefs->ul_auto_repeat;

    // Visualisation des répétitions N jours avant
    uh_repeat_days = ps_db_prefs->ul_repeat_days;

    // Utilisation de la conduite
    b_remove_type = ps_db_prefs->ul_remove_type;

    //
    // Onglet Listes d'opérations
    //
    // Trier par date de valeur
    self->uh_sort_type = ps_db_prefs->ul_sort_type;
    CtlSetValue([self objectPtrId:DBasePropSortType], self->uh_sort_type);

    // Afficher la date de valeur
    self->uh_list_date = ps_db_prefs->ul_list_date;
    CtlSetValue([self objectPtrId:DBasePropValueDate], self->uh_list_date);

    // Afficher le type au lieu de la description
    self->uh_list_type = ps_db_prefs->ul_list_type;
    CtlSetValue([self objectPtrId:DBasePropTypeForDesc], self->uh_list_type);

    //
    // Onglet "Sécurité"
    //
    // Code d'accès à la base
    self->ul_current_code = ps_db_prefs->ul_access_code;

    // Accepter la recherche globale
    CtlSetValue([self objectPtrId:DBasePropDenyFind],
		ps_db_prefs->ul_deny_find);

    //
    // Onglet "Note"
    //
    [self replaceField:DBasePropNote withSTR:ps_db_prefs->ra_note len:-1];

    if (self->uh_transaction == false)
      MemHandleUnlock(self->vh_db_prefs);
  }

  // Avant le StrIToA car on réutilise ra_title...
  FrmCopyTitle(self->pt_frm, pa_title);

  // Exe des répètitions automatique
  CtlSetValue([self objectPtrId:DBasePropAutoRepeat], b_exe_repeats);

  // Visualisation des répétitions N jours avant
  [self replaceField:REPLACE_FIELD_EXT | DBasePropRepeatDays
	withSTR:(Char*)(UInt32)uh_repeat_days len:REPL_FIELD_DWORD];

  // Utilisation de la conduite
  CtlSetValue([self objectPtrId:DBasePropRemoveType], b_remove_type);

  // Bouton du code d'accès à la base
  [self _changeCode];

  // Si on est en mode gaucher, il faut inverser la note avec la barre
  // de scroll
  if (oMaTirelire->s_prefs.ul_left_handed)
    [self swapLeft:DBasePropNote rightOnes:DBasePropNoteScrollbar, 0];

  [self fieldUpdateScrollBar:DBasePropNoteScrollbar
	fieldPtr:[self objectPtrId:DBasePropNote]
	setScroll:true];

  [super open];

  // On place le focus sur le nom de la base
  [self focusObject:DBasePropName];

  return true;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  if ([super ctlSelect:ps_select])
    return true;

  switch (ps_select->controlID)
  {
  case DBasePropCode:
  {
    UInt32 ul_access_code = 0;

    if (self->vh_db_prefs)
    {
      ul_access_code =
	((struct s_db_prefs*)MemHandleLock(self->vh_db_prefs))->ul_access_code;
      MemHandleUnlock(self->vh_db_prefs);
    }
    // Préférences déjà chargées
    else if (self->uh_transaction)
      ul_access_code = [oMaTirelire transaction]->ps_prefs->ul_access_code;

    if ([oMaTirelire passwordChange:ul_access_code
		     currentCode:&self->ul_current_code] == 0)
      // On change le libellé du bouton ET on fait {ap,dis}paraître
      // les widgets timeout
      [self _changeCode];
  }
  break;

  case DBasePropOK:
    if ([self extractAndSave] == false)
      break;

    /* On continue sur cancel */

  case DBasePropCancel:
    [self returnToLastForm];
    break;

  case DBasePropDelete:
    if (self->vh_db_prefs != NULL && FrmAlert(alertDBaseDelete) != 0)
    {
      // Suppression effective
      if (DmDeleteDatabase(self->uh_card_no, self->ui_db_id))
      {
	// XXX
      }

      // Et une base en moins, une...
      self->ui_update_mati_list |=
	(frmMaTiUpdateList | frmMaTiUpdateListDBases);

      [self returnToLastForm];
    }
    break;

  default:
    return false;
  }

  return true;
}


- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key
{
  UInt16 fld_id;

  // On laisse la main à Papa pour gérer les déplacements entre champs...
  if ([super keyDown:ps_key])
    return true;

  fld_id = FrmGetFocus(self->pt_frm);

  if (fld_id != noFocus)
  {
    UInt16 uh_id = FrmGetObjectId(self->pt_frm, fld_id);

    switch (uh_id)
    {
    case DBasePropRepeatDays:
      return [self keyFilter:KEY_FILTER_INT | fld_id for:ps_key];
    }
  }

  return false;
}


- (Boolean)sclRepeat:(struct sclRepeat *)ps_repeat
{
  [self fieldScrollBar:DBasePropNoteScrollbar
	linesToScroll:ps_repeat->newValue - ps_repeat->value update:false];

  return false;
}


- (Boolean)fldChanged:(struct fldChanged *)ps_fld_changed
{
  if (ps_fld_changed->fieldID == DBasePropNote)
  {
    [self fieldUpdateScrollBar:DBasePropNoteScrollbar
	  fieldPtr:ps_fld_changed->pField
	  setScroll:false];
    return true;
  }

  return false;
}

@end
