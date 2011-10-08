/* 
 * MaTirelire.m -- 
 * 
 * Author          : Max Root
 * Created On      : Sun Jan  5 21:14:43 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Sat Jun 21 18:51:15 2008
 * Update Count    : 64
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: MaTirelire.m,v $
 * Revision 1.17  2008/06/23 08:07:11  max
 * Display alertBeta only if BETA macro is defined.
 *
 * Revision 1.16  2008/02/01 17:16:25  max
 * s/WinPrintf/alert_error_str/g
 *
 * Revision 1.15  2008/01/14 16:50:32  max
 * Switch to new mcc.
 * Correct global Palm OS find feature handling.
 *
 * Revision 1.14  2006/11/04 23:48:08  max
 * Now update currency rates when starting.
 * Allow goto events for splits.
 *
 * Revision 1.13  2006/10/05 19:08:55  max
 * Handle new MiniStatsForm.
 *
 * Revision 1.12  2006/06/19 12:24:01  max
 * Add -checkAndCorrectDBs method to check & correct erroneous
 * databases.
 *
 * Revision 1.11  2006/04/25 08:46:57  max
 * Change memory allocations failures sheme.
 * Add lock on auto-off feature.
 * Correctly pop up the password dialog before switching off the palm.
 *
 * Revision 1.10  2005/11/19 16:56:29  max
 * Add ClearingAutoConfForm dialog and RepeatsListForm screen.
 *
 * Revision 1.9  2005/10/11 19:11:56  max
 * Add ExportForm, ClearingIntroForm, ClearingListForm, StatementNumForm.
 *
 * Revision 1.8  2005/10/06 20:23:53  max
 * s/-computeAllRepeats/-computeAllRepeats:/ and don't force.
 *
 * Revision 1.7  2005/10/06 19:48:15  max
 * Add SearchForm.
 * s/ul_repeat_startup/ul_auto_repeat/
 *
 * Revision 1.6  2005/08/20 13:06:55  max
 * New form CustomListForm.
 * uh_flags attribute and -flags* method deleted. They are replaced by
 * the new form argument passing mechanism.
 * Add b_goto_event_pending to know when a frmGotoEvent is pending.
 *
 * Revision 1.5  2005/05/18 20:00:01  max
 * Remove +new method.
 * Add -find: and -gotoItem:justLaunched: methods to implement Palm Find
 * feature.
 *
 * Revision 1.4  2005/05/08 12:13:01  max
 * Add StatsForm.
 * DBase access code fully operational.
 * The timeout access code is now stored in object attributes, because it
 * can be the application one or the current database one. If both are
 * present, the database one is taken. So -freeTransaction and
 * -eventEach: methods modified.
 * -passwordDialogCode:label:flags: method can now take a label format
 * with the help of PW_FORMAT flag. Now it returns -1 when an
 * appStopEvent occurred.
 * Add -passwordCheckDBaseCode method to do generic DBase code checking.
 * -newTransaction: can now take an already built Transaction object.
 * Replace all [self->oTransactions free] by [self freeTransaction].
 *
 * Revision 1.3  2005/03/27 15:38:24  max
 * Add -gotoFirstFormWithDB: to support launchable databases.
 * Correct erroneous databases at startup (following a synchro.)
 * No more crash when the default database don't exist.
 *
 * Revision 1.2  2005/03/02 19:02:40  max
 * Add PurgeForm.
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_MATIRELIRE
#include "MaTirelire.h"

#include "PalmResize/resize.h"

#include "BaseForm.h"
#include "DBasesListForm.h"
#include "AccountsListForm.h"
#include "TransListForm.h"
#include "TransForm.h"
#include "DescModesListForm.h"
#include "TypesListForm.h"
#include "CurrenciesListForm.h"
#include "EditDescForm.h"
#include "EditModeForm.h"
#include "EditTypeForm.h"
#include "EditCurrencyForm.h"
#include "PrefsForm.h"
#include "DBasePropForm.h"
#include "AccountPropForm.h"
#include "SumDatesForm.h"
#include "AboutForm.h"
#include "PurgeForm.h"
#include "StatsForm.h"
#include "CustomListForm.h"
#include "SearchForm.h"
#include "ExportForm.h"
#include "ClearingIntroForm.h"
#include "ClearingListForm.h"
#include "ClearingAutoConfForm.h"
#include "StatementNumForm.h"
#include "RepeatsListForm.h"
#include "EditSplitForm.h"
#include "MiniStatsForm.h"


#include "PasswordForm.h"	// Formulaire spécial...

#include "float.h"

#define TransFormIdx OpFormIdx	// Compatibility fix
#include "MaTirelireDefsAuto.h"
#include "objRsc.h"		// XXX
#include "ids.h"

#define MaTiVersion	0


@implementation MaTirelire

- (MaTirelire*)init
{
  BaseForm_c **poFormClasses;

  self->oModes = [Mode new];
  self->oTypes = [Type new];
  self->oDesc = [Desc new];
  self->oCurrencies = [Currency new];

  // The forms classes (there is no form with index 0)
  self->vh_form_classes = MemHandleNew(formAutoLast * sizeof(BaseForm_c*));//OK

  ErrFatalDisplayIf(self->vh_form_classes == NULL,
		    "Could not allocate memory for form classes");

  self->uh_form_num = formAutoLast; // Car pas de form en 0

  poFormClasses = MemHandleLock(self->vh_form_classes);

#define NEW_FORM_CLASS(FormName, FormClass) \
    poFormClasses[FormName ## Idx - 1] = (BaseForm_c*)FormClass
#define NEW_FORM(FormName) NEW_FORM_CLASS(FormName, FormName)

  NEW_FORM(DBasesListForm);
  NEW_FORM(AccountsListForm);
  NEW_FORM(TransListForm);
  NEW_FORM(TransForm);
  NEW_FORM(DescModesListForm);
  NEW_FORM(TypesListForm);
  NEW_FORM(CurrenciesListForm);
  NEW_FORM(EditDescForm);
  NEW_FORM(EditModeForm);
  NEW_FORM(EditTypeForm);
  NEW_FORM(EditCurrencyForm);
  NEW_FORM_CLASS(EditReferenceCurrencyForm, EditCurrencyForm);
  NEW_FORM(PrefsForm);
  NEW_FORM(DBasePropForm);
  NEW_FORM(AccountPropForm);
  NEW_FORM(SumDatesForm);
  NEW_FORM(AboutForm);
  NEW_FORM(PurgeForm);
  NEW_FORM(StatsForm);
  NEW_FORM(CustomListForm);
  NEW_FORM(SearchForm);
  NEW_FORM(ExportForm);
  NEW_FORM(ClearingIntroForm);
  NEW_FORM(ClearingListForm);
  NEW_FORM(ClearingAutoConfForm);
  NEW_FORM(StatementNumForm);
  NEW_FORM(RepeatsListForm);
  NEW_FORM(EditSplitForm);
  NEW_FORM(MiniStatsForm);

  MemHandleUnlock(self->vh_form_classes);

  return [super init];
}


- (UInt16)start
{
  InitializeResizeSupport(wlstDIAInfos);

  LoadResizePrefs(MaTiCreatorID, 0x0D1A); // DIA prefs...

  [super start];

#ifdef BETA
  // BETA Alert
  if (self->s_prefs.ul_no_beta_alert == 0)
    switch (FrmAlert(alertBeta))
    {
    case 2:
      self->s_prefs.ul_no_beta_alert = 1;
      // Continue...
    case 1:
      break;
    default:
      return 1;
    }
#else
  // Pour la prochaine bêta
  self->s_prefs.ul_no_beta_alert = 0;
#endif

  [self passwordReinit];

  // S'il y a un mot de passe, on le demande
  if (self->s_prefs.ul_access_code != 0
      && [self passwordDialogCode:self->s_prefs.ul_access_code
	       label:PasswordMaTirelire flags:PW_WAITOK] <= 0)
    return 1;

  // On met le code de l'appli en place, si 0 => pas de code
  self->ul_timeout_access_code = self->s_prefs.ul_access_code;
  self->b_db_access_code = false;

  // A-t'on eu à faire à une base erronée lors de la dernière synchro ?
  if (self->s_prefs.ul_db_must_be_corrected)
  {
    // On annonce à l'utilisateur qu'il vaut mieux corriger !!!
    switch (FrmAlert(alertHaveToCorrectDB))
    {
      // Yes, repair...
    case 1:
      self->s_prefs.ul_db_must_be_corrected = 0;

      [self checkAndCorrectDBs];
      break;

      // No, quit
    case 2:
      return 1;
    }
  }

  // Initialisation de FontBucket
  FmInit(&self->s_fb, kNoFontRangeSpecified, kNoFontRangeSpecified,
	 false /* XXX A CHANGER XXX */);

  // On regarde si la fonte de liste existe encore
  if (self->s_prefs.ui_list_font == 0 // Hack MAX
      || FmValidFont(&self->s_fb, self->s_prefs.ui_list_font) != 0)
    FmGetFMFontID(&self->s_fb, stdFont, &self->s_prefs.ui_list_font);

  // L'équivalent en gras
  if (self->s_prefs.ui_list_bold_font == 0 // Hack MAX
      || FmValidFont(&self->s_fb, self->s_prefs.ui_list_bold_font) != 0)
    self->s_prefs.ui_list_bold_font
      = [self getBoldFont:self->s_prefs.ui_list_font];

  FmUseFont(&self->s_fb, self->s_prefs.ui_list_font,
	    &self->s_fonts.uh_list_font);
  if (self->s_prefs.ui_list_font != self->s_prefs.ui_list_bold_font)
    FmUseFont(&self->s_fb, self->s_prefs.ui_list_bold_font,
	      &self->s_fonts.uh_list_bold_font);
  else
    self->s_fonts.uh_list_bold_font = self->s_fonts.uh_list_font;

  // Initialisation des infos qui servent souvent
  init_misc_infos(&self->s_misc_infos,
		  self->s_fonts.uh_list_font, self->s_fonts.uh_list_bold_font);

  // Mise à jour des taux des devises
  [self->oCurrencies updateRates];

  return 0;
}


- (Boolean)checkAndCorrectDBs
{
  UInt32 ul_incorrect_num;

  ul_incorrect_num = do_on_each_transaction(Transaction->_validDB_, true);

  if (ul_incorrect_num > 0)
  {
    Char ra_db_num[10], ra_rec_num[10];

    StrPrintF(ra_db_num,  "%lu", ul_incorrect_num >> 16);
    StrPrintF(ra_rec_num, "%lu", ul_incorrect_num & 0xffff);

    // On annonce le nombre de corrections effectuées
    FrmCustomAlert(alertIncorrectDBnumCorrections,
		   ra_rec_num, ra_db_num, " ");

    return true;
  }

  return false;
}


- (void)stop
{
  [super stop];

  SaveResizePrefs(MaTiCreatorID, 0x0D1A, 0); // DIA prefs...

  TerminateResizeSupport();

  // FontBucket
  FmFreeFont(&self->s_fb, self->s_fonts.uh_list_font);
  if (self->s_fonts.uh_list_bold_font != self->s_fonts.uh_list_font)
    FmFreeFont(&self->s_fb, self->s_fonts.uh_list_bold_font);

  FmClose(&self->s_fb);
}


- (void)gotoFirstForm
{
  UInt16 uh_form = DBasesListFormIdx; // En cas d'erreur...

  switch (self->s_prefs.ul_first_form)
  {
    // Les écrans qui ouvrent la base par défaut
  case FIRST_FORM_TRANS:	// Écran de la liste des opérations
  case FIRST_FORM_ACCOUNTS:	// Écran de la liste des comptes
    // La base doit toujours exister
    if ([self newTransaction:nil] == nil
	// ET le code d'accès doit être vérifié
	|| [self passwordCheckDBaseCode] == false)
      goto first_form;

    // Écran de la liste des comptes
    uh_form = AccountsListFormIdx;

    // Écran de la liste des opérations
    if (self->s_prefs.ul_first_form == FIRST_FORM_TRANS
	// AVEC le compte par défaut toujours existant
	&& [self->oTransactions loadAccountName] != NULL)
      uh_form = TransListFormIdx;
    break;
  }

 first_form:
  FrmGotoForm(uh_form);
}


// Il faut démarrer avec une base de comptes précise
- (void)gotoFirstFormWithDB:(SysAppLaunchCmdOpenDBType*)cmdPBP
{
  Char ra_db_name[dmDBNameLength];
  UInt32 ui_type_id, ui_creator_id;
  UInt16 uh_form;

  // Vérification de la conformité de la base qui va être chargée
  DmDatabaseInfo(cmdPBP->cardNo, cmdPBP->dbID, ra_db_name,
		 NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		 &ui_type_id, &ui_creator_id);
  if (ui_creator_id != MaTiCreatorID // Inutile normalement
      || ui_type_id != MaTiAccountsType)
  {
    [self gotoFirstForm];
    return;
  }

  uh_form = DBasesListFormIdx; // En cas d'erreur...

  // Au cas où une base de comptes serait déjà ouverte...
  [self freeTransaction];

  self->oTransactions = [[Transaction alloc] initWithCardNo:cmdPBP->cardNo
					      withID:cmdPBP->dbID];
  if (self->oTransactions != nil)
  {
    struct s_db_prefs *ps_prefs;

    // On conserve le nom de la base
    MemMove(self->s_prefs.ra_last_db, ra_db_name, sizeof(ra_db_name));

    ps_prefs = [self->oTransactions getPrefs];

    // La base ne possède ni catégories, ni préférences...
    if (ps_prefs == NULL)	// Big error !!!!
      [self freeTransaction];
    else
    {
      if (ps_prefs->ul_access_code != 0)
      {
	// Vérification du code d'accès pour cette base
	if ([self passwordCheckDBaseCode] == false)
	  goto first_form;

	// Le code d'accès du timeout devient celui de la base
	self->ul_timeout_access_code = ps_prefs->ul_access_code;
	self->b_db_access_code = true;
      }

      // Les répétitions
      if (ps_prefs->ul_auto_repeat)
	[self->oTransactions computeAllRepeats:false onMaxDays:0];

      // Le premier formulaire
      switch (self->s_prefs.ul_first_form)
      {
      case FIRST_FORM_TRANS:
	// Le compte par défaut a disparu, on passe sur la liste des comptes
	if ([self->oTransactions loadAccountName] == NULL)
	  uh_form = AccountsListFormIdx;
	// OK, on a tout ce qu'il faut...
	else
	  uh_form = TransListFormIdx;
	break;

	// Comme il faut démarrer avec une base de compte, on bascule sur
	// l'écran des comptes
      default: //case FIRST_FORM_DBASES:
	self->s_prefs.ul_first_form = FIRST_FORM_ACCOUNTS;

	// Continue...

      case FIRST_FORM_ACCOUNTS:
	uh_form = AccountsListFormIdx;
	break;
      }
    }
  }

 first_form:
  FrmGotoForm(uh_form);
}


- (void)find:(FindParamsPtr)ps_sys_find_params
{
  struct s_tr_find_params s_find_params;

  s_find_params.b_signed = false;
  s_find_params.ui_int_num = 0;
  s_find_params.h_sign = 0;

  switch (ps_sys_find_params->strAsTyped[0])
  {
  case '<':
    s_find_params.h_sign = -1;
    break;
  case '>':
    s_find_params.h_sign = 1;
    break;
  }

  // On regarde si la chaîne à rechercher est un nombre
  s_find_params.b_find_num = isStrATo100F(ps_sys_find_params->strAsTyped
					  + (s_find_params.h_sign != 0),
					  &s_find_params.l_amount);
  if (s_find_params.b_find_num)
  {
    // On ne divise pas l_amount par 100 au cas ou l_amount aurait débordé
    s_find_params.ui_int_num = StrAToI(ps_sys_find_params->strAsTyped
				       + (s_find_params.h_sign != 0));

    switch (ps_sys_find_params->strAsTyped[s_find_params.h_sign != 0])
    {
    case '+':
    case '-':
      s_find_params.b_signed = true;
      break;
    }
  }

  //
  // Autre init...
  s_find_params.ps_sys_find_params = ps_sys_find_params;

  ps_sys_find_params->more = false;

  // Si on est appelé alors que Ma Tirelire ne tourne pas déjà, il
  // faut charger les préférences
  if (self->oIsa->b_globals == false)
    [self loadPrefs];

  find_on_each_transaction(&s_find_params);
}


- (void)gotoItem:(GoToParamsPtr)ps_goto_params justLaunched:(Boolean)b_launched
{
  Transaction *oCurTransactions, *oCurOpened;
  struct s_transaction *ps_tr;
  UInt32 ul_unique_id;
  LocalID ui_opened_lid = 0;
  UInt16 uh_opened_card_no = 0;
  UInt16 uh_attr, uh_rec_num;
  EventType s_event;
  Boolean b_close_done = false;

  // A-t-on une base de comptes déjà ouverte ?
  oCurOpened = [[MaTirelire appli] transaction];
  if (oCurOpened != nil)
  {
    [oCurOpened getCardNo:&uh_opened_card_no andID:&ui_opened_lid];

    // La base actuellement ouverte correspond à celle du goto
    if (uh_opened_card_no == ps_goto_params->dbCardNo
	&& ui_opened_lid == ps_goto_params->dbID)
    {
      oCurTransactions = oCurOpened;
      goto ok;
    }
  }

  // If the application is already running, close all open forms. As
  // it doesn't concern the found DB, we can do it as soon as possible
  if (b_launched == false)
  {
    FrmCloseAllForms();
    b_close_done = true;
  }

  // Ouverture de la nouvelle base
  oCurTransactions = [[Transaction alloc]
		      initWithCardNo:ps_goto_params->dbCardNo
		      withID:ps_goto_params->dbID];
  if (oCurTransactions == nil)
  {
 dbases_list:
    FrmGotoForm(DBasesListFormIdx);
    return;
  }

  // Mise en place de la nouvelle base dans l'application
  [self newTransaction:oCurTransactions];

  if ([self passwordCheckDBaseCode] == false)
    goto dbases_list;

  [oCurTransactions getName:self->s_prefs.ra_last_db];

 ok:
  uh_rec_num = ps_goto_params->recordNum;
  DmRecordInfo(oCurTransactions->db,
	       uh_rec_num, &uh_attr, &ul_unique_id, NULL);

  self->s_prefs.ul_first_form = FIRST_FORM_TRANS;

  // Le compte concerné
  oCurTransactions->ps_prefs->ul_cur_category
    = uh_attr & dmRecAttrCategoryMask;
  if ([oCurTransactions loadAccountName] == NULL)
    goto dbases_list;

  // If the application is already running, close all open forms.  This 
  // may cause in the database record to be reordered, so we'll find the 
  // records index by its unique id.
  if (b_launched == false)
  {
    // Do it only if we didn't close before == only if same DB
    if (b_close_done == false)
      FrmCloseAllForms();

    // ul_unique_ID est forcément un unique ID possible...
    if (DmFindRecordByID(oCurTransactions->db, ul_unique_id, &uh_rec_num) != 0)
      goto dbases_list;
  }

  // Propriétés de compte OU BIEN opération ?
  ps_tr = [oCurTransactions getId:uh_rec_num];
  if (ps_tr == NULL)
    goto dbases_list;

  s_event.data.frmLoad.formID
    = DateToInt(ps_tr->s_date) == 0 ? AccountPropFormIdx : OpFormIdx;

  [oCurTransactions getFree:ps_tr];

  FrmGotoForm(TransListFormIdx);

  // Send an event to goto a form and select the matching text
  s_event.eType = frmLoadEvent;
  EvtAddEventToQueue(&s_event);

  s_event.data.frmGoto.formID = s_event.data.frmLoad.formID;
  s_event.eType = frmGotoEvent;
  s_event.data.frmGoto.recordNum = uh_rec_num;
  s_event.data.frmGoto.matchPos = ps_goto_params->matchPos;
  s_event.data.frmGoto.matchLen = (ps_goto_params->matchCustom & 0xffff);
  s_event.data.frmGoto.matchFieldNum = ps_goto_params->matchFieldNum;
  s_event.data.frmGoto.matchCustom = (ps_goto_params->matchCustom >> 16);
  EvtAddEventToQueue(&s_event);

  // On garde en tête qu'un Goto est en cours pour ne pas afficher de
  // boîte de dialogue avant l'exécution totale de l'événement
  self->b_goto_event_pending = true;
}


////////////////////////////////////////////////////////////////////////
//
// Gestion des codes d'accès
//
////////////////////////////////////////////////////////////////////////

- (Int16)eventEach:(EventType*)ps_event
{
  // Il y a un code d'accès
  if (self->ul_timeout_access_code)
  {
    // Le timeout
    if (self->s_prefs.ul_timeout)
    {
      UInt32 ul_now = TimGetSeconds();

      // On est après le timeout
      // |----------------|----------|
      // last       last+timeout      now
      if (self->ul_last_event + self->ul_timeout_sec < ul_now)
      {
	Char ra_db_name[dmDBNameLength];
	UInt16 uh_flags;
	UInt16 uh_label;

    ask_for_password:
	uh_flags = PW_RTOFORM|PW_WAITOK;
	uh_label = PasswordMaTirelire;
	ra_db_name[0] = '\0';

	// Si le code à donner est celui de la base de comptes en cours
	if (self->b_db_access_code)
	{
	  // XXX Ne devrait pas se produire XXX
	  if (self->oTransactions == nil)
	  {
	    alert_error_str("Should use DBase passwd, but no DBase opened");
	    return 0;
	  }

	  [self->oTransactions getName:ra_db_name];

	  uh_flags |= PW_FORMAT;
	  uh_label = PasswordDataBase;
	}

	// On rempile l'évènement, au cas où ce serait une extinction...
	EvtAddEventToQueue(ps_event);

	// Pour le prochain tour...
	self->ul_wait_for = self->ul_initial_wait_for;

	// On demande le mot de passe pour continuer...
	if ([self passwordDialogCode:self->ul_timeout_access_code
		  label:uh_label flags:uh_flags,
		  db_list_visible_name(ra_db_name)] > 0)
	  // Bon mot de passe, on attend le prochain évènement...
	  return 1;

	// Sinon on a reçu un Stop qu'on laisse filer pour le form...
	return -1;
      }
      // On est avant le timeout
      // |----------------|----------|
      // last            now   last+timeout
      else
      {
	// Évènement de timeout : on réajuste le timeout
	if (ps_event->eType == nilEvent)
	  self->ul_wait_for = SysTicksPerSecond()
	    * (self->ul_last_event + self->ul_timeout_sec - ul_now);
	// N'importe quel autre évènement
	else
	{
	  self->ul_last_event = ul_now;
	  self->ul_wait_for = self->ul_initial_wait_for;
	}
      }
    }

    // Lock quand on éteint la bête
    if (self->s_prefs.ul_auto_lock_on_power_off)
    {
      if (ps_event->eType == keyDownEvent
	  && (ps_event->data.keyDown.chr == hardPowerChr
	      || ps_event->data.keyDown.chr == autoOffChr))
	goto ask_for_password;
    }
  }

  return 0;
}


- (void)passwordReinit
{
  self->ul_last_event = TimGetSeconds();
  self->ul_initial_wait_for = SysTicksPerSecond();

  switch (self->s_prefs.ul_timeout)
  {
  default:
    self->s_prefs.ul_timeout = PW_TIMEOUT_NONE;
  case PW_TIMEOUT_NONE:
    self->ul_initial_wait_for = evtWaitForever;
    self->ul_timeout_sec = 0;
    break;
  case PW_TIMEOUT_30S:
    self->ul_initial_wait_for *= (self->ul_timeout_sec = 30) + 1;
    break;
  case PW_TIMEOUT_60S:
    self->ul_initial_wait_for *= (self->ul_timeout_sec = 60) + 1;
    break;
  case PW_TIMEOUT_120S:
    self->ul_initial_wait_for *= (self->ul_timeout_sec = 120) + 1;
    break;
  case PW_TIMEOUT_300S:
    self->ul_initial_wait_for *= (self->ul_timeout_sec = 300) + 1;
    break;
  }

  self->ul_wait_for = self->ul_initial_wait_for;
}


- (Int16)passwordDialogCode:(UInt32)ul_code
		      label:(UInt16)uh_label
		      flags:(UInt16)uh_flags, ...
{
  PasswordForm *oPasswordForm = nil;
  EventType s_event, s_save_event;
  UInt16 err;

  s_save_event.eType = nilEvent;

  // On purge les évènements restants avant d'ouvrir la boîte
  for (;;)
  {
    EvtGetEvent(&s_event, 0);

    // Évènement de timeout : on va pouvoir ouvrir la boîte...
    if (s_event.eType == nilEvent)
      break;

    // Il s'agit d'une extinction, il faudra afficher le formulaire
    // avant l'extinction
    if (s_event.eType == keyDownEvent
	&& (s_event.data.keyDown.chr == hardPowerChr
	    || s_event.data.keyDown.chr == autoOffChr))
    {
      MemMove(&s_save_event, &s_event, sizeof(s_event));
      continue;
    }

    if (SysHandleEvent(&s_event))
      continue;

    if (MenuHandleEvent(NULL, &s_event, &err))
      continue;

    if (s_event.eType == appStopEvent)
    {
      EvtAddEventToQueue(&s_event);

      // Pour le retour dans EventLoop()
      self->ul_last_event = TimGetSeconds();

      return -1;
    }
  }

  // Pas de formulaire en cours, on ne pourra pas retourner au
  // formulaire précédent
  if (oFrm == nil)
    uh_flags &= ~PW_RTOFORM;

  FrmPopupForm(PasswordFormIdx);

  // Il faut poster un événement après l'affichage du formulaire
  if (s_save_event.eType != nilEvent)
    EvtAddEventToQueue(&s_save_event);

  for (;;)
  {
    EvtGetEvent(&s_event, evtWaitForever);

    // On chope les touches hard avant le SysHandleEvent, sauf si la
    // touche a déclenché l'allumage de la bête
    if (s_event.eType == keyDownEvent)
    {
      if ((s_event.data.keyDown.modifiers & (commandKeyMask|poweredOnKeyMask))
	  == commandKeyMask
	  && s_event.data.keyDown.chr >= vchrHard1
	  && s_event.data.keyDown.chr <= vchrHard4)
	goto frm_dispatch;
    }

    if (SysHandleEvent(&s_event))
      continue;

    if (MenuHandleEvent(NULL, &s_event, &err))
      continue;

    switch (s_event.eType)
    {
    case frmLoadEvent:
      if (s_event.data.frmLoad.formID == PasswordFormIdx)
      {
	va_list ap = NULL;

	if (uh_flags & PW_FORMAT)
	  va_start(ap, uh_flags);

	oPasswordForm = [PasswordForm new:s_event.data.frmLoad.formID
				       withLabel:uh_label va:ap];

	if (uh_flags & PW_FORMAT)
	  va_end(ap);

	continue;
      }
      break;

    case appStopEvent:
      if (oPasswordForm != nil)
      {
	if (uh_flags & PW_RTOFORM)
	  [oPasswordForm returnToLastForm];
	else
	{
	  FormType *pt_frm = FrmGetActiveForm();

	  [oPasswordForm close];

	  FrmEraseForm(pt_frm);
	  FrmDeleteForm(pt_frm);
	}
      }

      EvtAddEventToQueue(&s_event);

      // Pour le retour dans EventLoop()
      self->ul_last_event = TimGetSeconds();

      return -1;

    case firstUserEvent:
      // Il faut que le mot de passe soit correct
      if (uh_flags & PW_WAITOK)
      {
	if (ul_code != *(UInt32*)&s_event.data.generic)
	{
	  FrmAlert(alertPasswordBadCode);
	  [oPasswordForm _clear];
	  continue;
	}
      }

      if (uh_flags & PW_RTOFORM)
	[oPasswordForm returnToLastForm];
      else
      {
	FormType *pt_frm = FrmGetActiveForm();

	[oPasswordForm close];

	FrmEraseForm(pt_frm);
	FrmDeleteForm(pt_frm);
      }

      // Pour le retour dans EventLoop()
      self->ul_last_event = TimGetSeconds();

      // Il faut retourner le code saisi, et renvoyer true
      if (uh_flags & PW_RETURNCODE)
      {
	*(UInt32*)ul_code = *(UInt32*)&s_event.data.generic;
	return 1;		/* On renvoie toujours true dans ce cas */
      }

      return ul_code == *(UInt32*)&s_event.data.generic;

    // Évite un warning de gcc
    default:
      break;
    }

 frm_dispatch:
    FrmDispatchEvent(&s_event);
  }

  // Jamais atteint...  
}


//
// Permet la saisie d'un nouveau code en vérifiant auparavant que
// l'utilisateur connait le code ul_access_code.
// *pul_current_code contient le code courant temporaire, non encore
// valide au niveau global
//
// Renvoie -1 si Stop
// Renvoie 0  si OK, le nouveau code est dans *pul_current_code
// Renvoie 1  si erreur de saisie OU BIEN pas de changement...
- (Int16)passwordChange:(UInt32)ul_access_code
	    currentCode:(UInt32*)pul_current_code
{
  UInt32 ul_code1, ul_code2;
  Int16 h_ret;

  // On vérifie le mot de passe courant
  if (ul_access_code != 0
      && (h_ret = [self passwordDialogCode:ul_access_code
			label:PasswordPresent flags:PW_RTOFORM]) <= 0)
  {
    // Si Stop on quitte
    if (h_ret < 0)
      return -1;

    FrmAlert(alertPasswordBadCode);
    return 1;			// Erreur de saisie...
  }

  // On appelle la boîte de code d'accès (PasswordNew)
  if ([self passwordDialogCode:(UInt32)&ul_code1
	    label:PasswordNew
	    flags:PW_RTOFORM|PW_RETURNCODE] < 0)
    return -1;			/* Si Stop, on quitte... */

  // Si nouveau code
  if (ul_code1 != 0)
  {
    // On rappelle la boîte de code d'accès pour confirmation (PasswordAgain)
    if ([self passwordDialogCode:(UInt32)&ul_code2
	      label:PasswordAgain
	      flags:PW_RTOFORM|PW_RETURNCODE] < 0)
      return -1;		/* Si Stop, on quitte... */

    if (ul_code1 != ul_code2)
    {
      // Les deux codes doivent être égaux
      FrmAlert(alertPasswordCodesMustBeEqual);
      return 1;			// Erreur de saisie...
    }
  }

  // Si le code a changé
  if (ul_code1 != *pul_current_code)
  {
    *pul_current_code = ul_code1;
    return 0;			// OK le code a bien changé
  }

  return 1;			// Pas de changement...
}


- (Boolean)passwordCheckDBaseCode
{
  if (self->oTransactions == nil)
    return false;

  // Il y a un code d'accès pour cette base
  if (self->oTransactions->ps_prefs->ul_access_code != 0)
  {
    Char ra_db_name[dmDBNameLength];
    UInt16 uh_retry = PW_DBASE_RETRY;
    Int16 h_ret;

    [self->oTransactions getName:ra_db_name];

    // On demande le mot de passe pour continuer...
    while ((h_ret = [self passwordDialogCode:
			    self->oTransactions->ps_prefs->ul_access_code
			  label:PasswordDataBase
			  flags:PW_FORMAT|PW_RTOFORM,
			  db_list_visible_name(ra_db_name)]) <= 0)
    {
      // Si Stop on arrête de suite
      if (h_ret < 0)
	goto abort;

      // Code incorrect
      FrmAlert(alertPasswordBadCode);

      if (--uh_retry == 0)
      {
    abort:
	[self freeTransaction];
	return false;
      }
    }
  }

  return true;
}


- (MaTirelire*)free
{
  if (self->oModes != nil)
    [self->oModes free];

  if (self->oTypes != nil)
    [self->oTypes free];

  if (self->oDesc != nil)
    [self->oDesc free];

  if (self->oCurrencies != nil)
    [self->oCurrencies free];

  [self freeTransaction];

  if (self->vh_form_classes != NULL)
    MemHandleFree(self->vh_form_classes);

  return [super free];
}


//
// Charge les préférences dans l'attribut s_prefs
- (void)loadPrefs
{
  Word uh_size = 0;
  SWord  h_version;

  h_version = PrefGetAppPreferences(MaTiCreatorID, 0, NULL, &uh_size, true);

  // On pré-initialise tout à 0, comme ça si la taille est inférieure
  // à celle de la structure, le reste sera initialisé à 0
  MemSet(&self->s_prefs, sizeof(self->s_prefs), 0);

  // On a les bonnes préférences
  if (h_version == MaTiVersion && uh_size <= sizeof(self->s_prefs))
    PrefGetAppPreferences(MaTiCreatorID, 0, &self->s_prefs, &uh_size, true);
  // Pas bon, on initialise ce qui ne doit pas être à 0
  else
  {
    self->s_prefs.ul_replace_desc = 1;
    self->s_prefs.uh_list_flags = USER_XFER_BOLD;
  }
}


//
// Sauve les préférences
- (void)savePrefs
{
  PrefSetAppPreferences(MaTiCreatorID, 0, MaTiVersion, &self->s_prefs,
			sizeof(self->s_prefs), true);
}


//
// Access to the loaded application preferences
- (struct s_mati_prefs*)getPrefs
{
  return &self->s_prefs;
}


- (FmType*)getFontBucket
{
  return &self->s_fb;
}


- (Boolean)changeFont:(FmFontID)ui_new_font
{
  FmFontID ui_new_bold_font = [self getBoldFont:ui_new_font];

  // Au moins une des deux fontes change
  if (ui_new_font != self->s_prefs.ui_list_font
      || ui_new_bold_font != self->s_prefs.ui_list_bold_font)
  {
    // On libère les fontes allouées
    FmFreeFont(&self->s_fb, self->s_fonts.uh_list_font);
    if (self->s_fonts.uh_list_font != self->s_fonts.uh_list_bold_font)
      FmFreeFont(&self->s_fb, self->s_fonts.uh_list_bold_font);

    // On demande les nouvelles
    FmUseFont(&self->s_fb, ui_new_font, &self->s_fonts.uh_list_font);
    if (ui_new_bold_font != ui_new_font)
      FmUseFont(&self->s_fb, ui_new_bold_font,
		&self->s_fonts.uh_list_bold_font);
    else
      self->s_fonts.uh_list_bold_font = self->s_fonts.uh_list_font;

    self->s_prefs.ui_list_font = ui_new_font;
    self->s_prefs.ui_list_bold_font = ui_new_bold_font;

    init_misc_infos(&self->s_misc_infos,
		    self->s_fonts.uh_list_font,
		    self->s_fonts.uh_list_bold_font);

    return true;
  }

  return false;
}


- (FmFontID)getBoldFont:(FmFontID)ui_font
{
  FmFontInfoType s_infos;
  FmFontID ui_bold_font;

  FmGetFontInfo(&self->s_fb, ui_font, &s_infos);

  {
    UInt16 uh_style_len = StrLen(s_infos.fontStyle);
    Char *pa_prev_style, *pa_new_style;
    Char ra_style[uh_style_len + 2]; // Il faudra mettre le "B" en plus + '\0'

    pa_prev_style = s_infos.fontStyle;
    pa_new_style = ra_style;

    // Le style 'L' est toujours avant le style 'B' qu'on veut rajouter
    if (*pa_prev_style == 'L')
    {
      *pa_new_style++ = 'L';
      pa_prev_style++;
    }

    // Si le style est déjà 'B', on garde la même fonte
    if (*pa_prev_style == 'B')
      return ui_font;

    // Sinon, on le rajoute avant d'ajouter les autres styles
    *pa_new_style++ = 'B';
    StrCopy(pa_new_style, pa_prev_style);

    // Si on ne trouve pas la version grasse, on garde la même
    if (FmGetFMFontIdFromName(&self->s_fb, s_infos.fontName, &ui_bold_font,
			      ra_style, s_infos.fontSize) != 0)
      return ui_font;
  }

  return ui_bold_font;
}


- (struct s_mati_fonts*)getFonts
{
  return &self->s_fonts;
}


- (UInt16)getFontHeight
{
  UInt16 uh_cur_font, uh_height_std, uh_height_bold;

  uh_cur_font = FntSetFont(self->s_fonts.uh_list_font);
  uh_height_std = FntLineHeight();

  FntSetFont(self->s_fonts.uh_list_bold_font);
  uh_height_bold = FntLineHeight();

  FntSetFont(uh_cur_font);

  return uh_height_std > uh_height_bold ? uh_height_std : uh_height_bold;
}


- (Transaction*)newTransaction:(Transaction*)oNewTransactions
{
  struct s_db_prefs *ps_prefs;

  if (self->oTransactions != nil)
  {
    // On remet le code de l'appli en place
    self->ul_timeout_access_code = self->s_prefs.ul_access_code;
    self->b_db_access_code = false;

    [self->oTransactions free];
  }

  if (oNewTransactions == nil)
  {
    oNewTransactions = [Transaction open:self->s_prefs.ra_last_db];
    if (oNewTransactions == nil)
      return nil;
  }
  else
    [oNewTransactions getName:self->s_prefs.ra_last_db];

  // Les préférences de la base
  ps_prefs = [oNewTransactions getPrefs];

  // Le code d'accès du timeout devient celui de la base
  if (ps_prefs->ul_access_code != 0)
  {
    self->ul_timeout_access_code = ps_prefs->ul_access_code;
    self->b_db_access_code = true;
  }

  // Les répétitions
  if (ps_prefs->ul_auto_repeat)
    [oNewTransactions computeAllRepeats:false onMaxDays:0];

  return self->oTransactions = oNewTransactions;
}


- (void)freeTransaction
{
  if (self->oTransactions != NULL)
    self->oTransactions = [self->oTransactions free];

  // On remet le code de l'appli en place
  self->ul_timeout_access_code = self->s_prefs.ul_access_code;
  self->b_db_access_code = false;
}


- (Transaction*)transaction
{
  return self->oTransactions;
}


- (Mode*)mode
{
  return self->oModes;
}


- (Type*)type
{
  return self->oTypes;
}


- (Desc*)desc
{
  return self->oDesc;
}


- (Currency*)currency
{
  return self->oCurrencies;
}

@end
