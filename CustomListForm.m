/* 
 * CustomListForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sam mai 21 14:48:06 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Jul  5 16:43:47 2007
 * Update Count    : 27
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: CustomListForm.m,v $
 * Revision 1.10  2008/01/14 17:09:32  max
 * Switch to new mcc.
 *
 * Revision 1.9  2006/11/04 23:47:59  max
 * Do some cleaning.
 *
 * Revision 1.8  2006/10/05 19:08:49  max
 * Types search preparation reworked.
 *
 * Revision 1.7  2006/07/06 15:45:43  max
 * Type is no longer set in ui_rec_flags_* but in h_one_type to allow
 * searchs in splits.
 *
 * Revision 1.6  2006/06/28 09:41:32  max
 * SumScrollList +newInForm: prototype changed.
 * Now call SumScrollList -updateWithoutRedraw.
 *
 * Revision 1.5  2005/11/19 16:56:19  max
 * Redraws reworked.
 *
 * Revision 1.4  2005/10/16 21:44:04  max
 * Correct list update code.
 *
 * Revision 1.3  2005/10/11 19:11:51  max
 * frmMaTiUpdateListTransactions handling works now correctly for created
 * transactions.
 *
 * Revision 1.2  2005/08/28 10:02:28  max
 * Handle types list in search criterias.
 * Redraw StatsForm when return to.
 *
 * Revision 1.1  2005/08/20 13:06:34  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_CUSTOMLISTFORM
#include "CustomListForm.h"

#include "MaTirelire.h"
#include "StatsForm.h"
#include "StatsTypeScrollList.h"
#include "StatsModeScrollList.h"
#include "StatsPeriodScrollList.h"
#include "StatsTransAllScrollList.h"
#include "StatsTransFlaggedScrollList.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


static void period_to_label(DateType *ps_period, Boolean b_week_day,
			    Char *pa_label)
{
  Char ra_date_beg[dateStringLength + 5], ra_date_end[dateStringLength + 5];
  Char *pa_date_beg, *pa_date_end;
  Char ra_format[16];
  DateFormatType e_date_short;

  pa_date_beg = ra_date_beg;
  pa_date_end = ra_date_end;

  // Dates précédées du jour de la semaine
  if (b_week_day)
  {
    // 0 pour dimanche, 1 pour lundi
    UInt16 uh_weekStartDay = (UInt16)PrefGetPreference(prefWeekStartDay);    

    SysStringByIndex(strClistWeekStartDays, uh_weekStartDay,
                     ra_date_beg, sizeof(ra_date_beg) - dateStringLength);
    SysStringByIndex(strClistWeekEndDays, uh_weekStartDay,
                     ra_date_end, sizeof(ra_date_end) - dateStringLength);

    pa_date_beg += StrLen(ra_date_beg);
    pa_date_end += StrLen(ra_date_end);
  }

  SysCopyStringResource(ra_format, strClistTypePeriodFormat);

  e_date_short = (DateFormatType)PrefGetPreference(prefDateFormat);

  DateToAscii(ps_period[0].month, ps_period[0].day,
	      ps_period[0].year + firstYear,
              e_date_short, pa_date_beg);
  DateToAscii(ps_period[1].month, ps_period[1].day,
	      ps_period[1].year + firstYear,
              e_date_short, pa_date_end);

  StrPrintF(pa_label, ra_format, ra_date_beg, ra_date_end);
}


@implementation CustomListForm

static UInt32 *get_types_field(UInt32 *pul_types)
{
  UInt16 index;

  // Recherche si au moins un type est activé...
  for (index = 0; index < DWORDFORBITS(NUM_TYPES); index++)
    if (pul_types[index] != 0)
      return pul_types;

  return NULL;
}


// Renvoie false si on n'est pas dans une succession d'écran issus des
// stats, true sinon
- (Boolean)initStatsSearch:(struct s_clist_stats_search*)ps_search
{
  struct s_db_prefs *ps_prefs = [oMaTirelire transaction]->ps_prefs;
  Boolean b_affine = false;

  ps_search->uh_end_date = 0xffff;

  ps_search->uh_stats_screens = 0;
  ps_search->pul_types = NULL;
  ps_search->h_one_type = -1;

  // Si on vient de l'écran initial des stats
  if ([(Object*)self->oPrevForm->oIsa isKindOf:StatsForm]
      // OU BIEN si on vient d'un CustomListForm (on est alors en affinage)
      || (b_affine = true,
	  [(Object*)self->oPrevForm->oIsa isKindOf:CustomListForm]))
  {
    StatsForm *oStatsForm;
    struct s_stats_prefs *ps_stats_prefs;
    DateType *ps_period_dates = NULL;
    Int16 h_mode;
    Boolean b_mode = false;

    // Le formulaire des stats contient le champ de bit des types
    oStatsForm = (StatsForm*)[self findPrevForm:StatsForm]; //Forcément != nil
    ps_search->pul_types = get_types_field(oStatsForm->rul_types);

    ps_search->b_flagged = false;

    // Premier janvier 1904 => DateToInt(((DateType){ 0, 1, 1 }))
    // pour ne pas prendre en compte les propriétés de compte
    ps_search->uh_beg_date = 0x0021;

    h_mode = -1;

    ps_stats_prefs = &ps_prefs->rs_stats[0];

    // Premier écran des stats
    if (b_affine == false)
    {
      // Il faut prendre la période de temps des stats
      ps_period_dates = ps_stats_prefs->rs_date;

      // Type particulier qui vient des stats
      if (ps_stats_prefs->ui_type_any == 0)
	ps_search->h_one_type = ps_stats_prefs->ui_type;

      // Mode particulier qui vient des stats
      if (ps_stats_prefs->ui_mode_any == 0)
	h_mode = ps_stats_prefs->ui_mode;
    }
    // Si le formulaire précédent contient un StatsPeriodScrollList,
    // alors on lui prend sa période de temps
    else if ([(Object*)((CustomListForm*)self->oPrevForm)->oList->oIsa
		  isKindOf:StatsPeriodScrollList])
    {
      // XXX Pas très propre
      ps_period_dates = ((StatsPeriodScrollList*)
			 ((CustomListForm*)
			  self->oPrevForm)->oList)->rs_period_dates;

      // Type particulier qui vient des stats
      if (ps_stats_prefs->ui_type_any == 0)
	ps_search->h_one_type = ps_stats_prefs->ui_type;

      // Mode particulier qui vient des stats
      if (ps_stats_prefs->ui_mode_any == 0)
	h_mode = ps_stats_prefs->ui_mode;

      // C'est à priori le seul de la chaîne des écrans de stats
      ps_search->uh_stats_screens = STATS_SCREEN_PERIOD;
    }
    // Si le formulaire précédent contient un StatsTypeScrollList
    // (b_mode == false) OU BIEN un StatsModeScrollList (b_mode == true)
    // alors il y a deux cas
    else if ([(Object*)((CustomListForm*)self->oPrevForm)->oList->oIsa
			isKindOf:StatsTypeScrollList]
	     || (b_mode = true,
		 [(Object*)((CustomListForm*)self->oPrevForm)->oList->oIsa
			   isKindOf:StatsModeScrollList]))
    {
      // Il faut regarder le formulaire qui précède le précédent :
      // s'il s'agit encore d'un CustomListForm, il contiendra
      // forcément un StatsPeriodScrollList qui a sa période de temps
      if ([(Object*)self->oPrevForm->oPrevForm->oIsa isKindOf:CustomListForm])
      {
	// XXX Pas très propre
	ps_period_dates
	  = ((StatsPeriodScrollList*)
	     ((CustomListForm*)
	      self->oPrevForm->oPrevForm)->oList)->rs_period_dates;

	// Si un type a été forcé dans les stats à l'origine, il y est encore
	if (ps_stats_prefs->ui_type_any == 0)
	  ps_search->h_one_type = ps_stats_prefs->ui_type;

	// Si un mode a été forcé dans les stats à l'origine, il y est encore
	if (ps_stats_prefs->ui_mode_any == 0)
	  h_mode = ps_stats_prefs->ui_mode;

	// On est donc passé par l'écran des stats par périodes
	ps_search->uh_stats_screens = STATS_SCREEN_PERIOD;
      }
      // Sinon, il faut prendre la période de temps des stats
      else
	ps_period_dates = ps_stats_prefs->rs_date;

      // Si on vient de la liste des modes, on prend le mode sélectionné
      if (b_mode)
      {
	// XXX Pas très propre
	h_mode = ((StatsModeScrollList*)
		  ((CustomListForm*)self->oPrevForm)->oList)->uh_mode;

	// Puis par l'écran des stats par modes
	ps_search->uh_stats_screens |= STATS_SCREEN_MODES;
      }
      // Si on vient de la liste des types, on prend le type sélectionné
      else
      {
	// XXX Pas très propre
	StatsTypeScrollList *oTypeScrollList =
	  (StatsTypeScrollList*)((CustomListForm*)self->oPrevForm)->oList;

	ps_search->h_one_type = oTypeScrollList->h_type;

	// Une série de types
	if (ps_search->h_one_type < 0)
	  ps_search->pul_types = oTypeScrollList->rul_types;
	// Un type en particulier, on annule l'éventuelle série de
	// StatsForm, le type en fait forcément partie
	else
	  ps_search->pul_types = NULL;

	// Puis par l'écran des stats par types
	ps_search->uh_stats_screens |= STATS_SCREEN_TYPES;
      }
    }

    if (ps_period_dates != NULL)
    {
      ps_search->uh_beg_date = DateToInt(ps_period_dates[0]);
      ps_search->uh_end_date = DateToInt(ps_period_dates[1]);
    }

    // Un mode et/ou un flag en particulier ?
    ps_search->ui_rec_flags_mask = 0;
    ps_search->ui_rec_flags_value = 0;

    // Plusieurs types => un seul test
    if (ps_search->h_one_type >= 0 && ps_search->pul_types != NULL)
    {
      BIT_SET(ps_search->h_one_type, ps_search->pul_types);
      ps_search->h_one_type = -1;
    }
    // Sinon un seul type qui est déjà dans h_one_type

    if (h_mode >= 0)
    {
      ps_search->ui_rec_flags_mask |= RECORD_MODE_MASK;
      ps_search->ui_rec_flags_value |= ((UInt32)h_mode << RECORD_MODE_SHIFT);
    }

    // Si "Toutes les opérations" => 3 (puisque Débits=>1 et Crédits=>2)
    // (à noter que si STATS_ON_FLAGGED => 3 aussi)
    ps_search->uh_on = ps_stats_prefs->ui_on ? : 3;

    // Seulement sur les marqués
    if (ps_stats_prefs->ui_on == STATS_ON_FLAGGED)
    {
      ps_search->ui_rec_flags_mask |= RECORD_MARKED;
      ps_search->ui_rec_flags_value |= RECORD_MARKED;
    }

    // En fonction de la date de valeur
    ps_search->b_val_date = ps_stats_prefs->ui_val_date;

    // Ignore les montants nuls
    ps_search->b_ignore_nulls = ps_stats_prefs->ui_ignore_nulls;

    // Les comptes
    ps_search->uh_accounts = ps_stats_prefs->uh_checked_accounts;

    return true;
  }

  // Sinon, c'est qu'on liste les marqués, c'est plus simple...
  ps_search->b_flagged = true;

  // Comme un compte peut-être marqué, la date de début passe à 0
  ps_search->uh_beg_date = 0;

  ps_search->uh_accounts = (1 << ps_prefs->ul_cur_category);

  // Ici "Toutes les opérations" => 3 (puisque Débits=>1 et Crédits=>2) 
  ps_search->uh_on = 3;

  // En fonction de la date de valeur (on s'en fiche dans ce cas)
  ps_search->b_val_date = false;

  // Les opérations et propriétés de compte doivent être marquées
  ps_search->ui_rec_flags_mask = RECORD_MARKED;
  ps_search->ui_rec_flags_value = RECORD_MARKED;

  return false;
}


#define TITLE_MAX_LEN	64
#define LABEL_MAX_LEN	32
- (CustomScrollList_c*)initTitleAndLabel
{
  Transaction *oTransactions;
  CustomScrollList_c *oScrollListClass;
  Char ra_title[TITLE_MAX_LEN], ra_label[LABEL_MAX_LEN];
  UInt16 uh_subform = (self->uh_form_flags & APP_FORM_ID_FLAGS_MASK);
  Int16 h_title_type = -1;
  UInt16 uh_label_id, x, y, uh_len;

  oTransactions = [oMaTirelire transaction];

  if (uh_subform <= CLIST_SUBFORM_LAST_STAT)
  {
    struct s_stats_prefs *ps_stats_prefs;
    struct s_clist_stats_search s_search;
    Int16 h_title;

    [self initStatsSearch:&s_search];

    ps_stats_prefs = &oTransactions->ps_prefs->rs_stats[0];

    switch (uh_subform)
    {
      // Par type
    case CLIST_SUBFORM_TYPE:
      oScrollListClass = (CustomScrollList_c*)StatsTypeScrollList;

      // On n'utilise pas ps_stats_prefs->ui_by car on peut être
      // appelé pour un affinage
      h_title = STATS_BY_TYPE;
      break;

      // Par mode
    case CLIST_SUBFORM_MODE:
      oScrollListClass = (CustomScrollList_c*)StatsModeScrollList;

      // On n'utilise pas ps_stats_prefs->ui_by car on peut être
      // appelé pour un affinage
      h_title = STATS_BY_MODE;
      break;

      // Par période
    case CLIST_SUBFORM_PERIOD:
      oScrollListClass = (CustomScrollList_c*)StatsPeriodScrollList;
      h_title = ps_stats_prefs->ui_by;
      break;

      // Les opérations
    case CLIST_SUBFORM_TRANS_STATS:
      oScrollListClass = (CustomScrollList_c*)StatsTransAllScrollList;
      h_title = ps_stats_prefs->ui_by;
      break;

    default:
      return nil;
    }

    // Le titre
    if (s_search.uh_stats_screens & STATS_SCREEN_TYPES)
    {
      // On est en affinage, le nom du type sera tronqué plus bas, car
      // c'est l'objet Type qui sait le mieux le faire

      // Il y a plusieurs types, mais avec un seul parent
      if (s_search.pul_types != NULL)
      {
	Type *oTypes = [oMaTirelire type];
	struct s_type *ps_type;
	UInt16 index, uh_cur_depth, uh_min_depth = -1;

	// XXX méthode pas terrible XXX
	for (index = NUM_TYPES; index-- > 0; )
	  if (BIT_ISSET(index, s_search.pul_types))
	  {
	    ps_type = [oTypes getId:index];

	    uh_cur_depth = [oTypes getDepth:ps_type];

	    [oTypes getFree:ps_type];

	    if (uh_cur_depth < uh_min_depth)
	    {
	      uh_min_depth = uh_cur_depth;
	      h_title_type = index;
	    }
	  }
      }
      // Un seul type
      else
	h_title_type = s_search.h_one_type;
    }
    else if (s_search.uh_stats_screens & STATS_SCREEN_MODES)
    {
      // On est en affinage, le nom du mode
      Mode *oModes;
      struct s_mode *ps_mode;

      oModes = [oMaTirelire mode];

      ps_mode = [oModes getId:(s_search.ui_rec_flags_value
			       & RECORD_MODE_MASK) >> RECORD_MODE_SHIFT];
      if (ps_mode == NULL)
      {
	ra_title[0] = '?';
	ra_title[1] = '\0';
      }
      else
      {
	StrNCopy(ra_title, ps_mode->ra_name, sizeof(ra_title) - 1);
	ra_title[sizeof(ra_title) - 1] = '\0'; // Au cas où

	[oModes getFree:ps_mode];
      }
    }
    // Une chaîne du type "Par ZZZ"
    else if (h_title >= 0)
      // Le type de stat...
      SysStringByIndex(strCustomListStatsTitle, h_title,
		       ra_title, sizeof(ra_title));
    // Une chaîne directement...
    else
      SysCopyStringResource(ra_title, - h_title);

    // Le label (période de temps)
    period_to_label((DateType*)&s_search.uh_beg_date, false, ra_label);
  }
  else
  {
    switch (uh_subform)
    {
      // L'écran des marqués
    case CLIST_SUBFORM_TRANS_FLAGGED:
      oScrollListClass = (CustomScrollList_c*)StatsTransFlaggedScrollList;

      // Marqués en titre
      SysCopyStringResource(ra_title, strClistFlagged);

      // Le nom du compte en label
      CategoryGetName(oTransactions->db,
		      oTransactions->ps_prefs->ul_cur_category, ra_label);
      break;

    default:
      return nil;
    }
  }

  WinGetDisplayExtent(&x, &uh_len);

  //
  // Titre et label en haut à droite
  uh_label_id = FrmGetObjectIndex(self->pt_frm, CustomListLabel);
  if (self->uh_form_drawn)
    [self hideIndex:uh_label_id];

  // Le label : il doit être calé à la droite de l'écran
  FrmGetObjectPosition(self->pt_frm, uh_label_id, &uh_len, &y);
  x -= FntCharsWidth(ra_label, StrLen(ra_label));
  FrmSetObjectPosition(self->pt_frm, uh_label_id, x, y);

  FrmCopyLabel(self->pt_frm, CustomListLabel, ra_label);

  if (self->uh_form_drawn)
    [self showIndex:uh_label_id];

  // Le titre
  // Il y a 3 pixels de chaque coté du titre + 1 d'espace et il est en gras
  x -= 3 * 2 - 1;
  FntSetFont(boldFont);
  if (h_title_type < 0)
  {
    uh_len = StrLen(ra_title);
    // Il y a 3 pixels de chaque coté du titre + 1 d'espace et il est en gras
    truncate_name(ra_title, &uh_len, x - 3 * 2 - 1, ra_title);
  }
  else
  {
    Char *pa_type = [[oMaTirelire type] fullNameOfId:h_title_type
					len:&uh_len truncatedTo:x];
    if (pa_type == NULL)
    {
      ra_title[0] = '?';
      ra_title[1] = '\0';
    }
    else
    {
      StrNCopy(ra_title, pa_type, sizeof(ra_title) - 1);
      ra_title[sizeof(ra_title) - 1] = '\0'; // Au cas où

      MemPtrFree(pa_type);
    }
  }
  FntSetFont(stdFont);

  FrmCopyTitle(self->pt_frm, ra_title);

  return oScrollListClass;
}


- (Boolean)open
{
  CustomScrollList_c *oScrollListClass;
  SumListForm *oPrevForm;
  ListType *pt_list;

  // On regarde le type du formulaire précédent. Si le formulaire
  // précédent est StatsForm, on prend le précédent encore.
  oPrevForm =
    (SumListForm*)([(Object*)self->oPrevForm->oIsa isKindOf:StatsForm]
		   ? self->oPrevForm->oPrevForm : self->oPrevForm);

  // Si on vient d'un formulaire SumListForm AVEC popup de devises, on
  // prend, la même devise pour nous
  if ([(Object*)oPrevForm->oIsa isKindOf:SumListForm]
      && (oPrevForm->uh_subclasses_flags & SUMLISTFORM_HAS_CURRENCIES_POPUP))
    // XXX Pas très propre
    self->uh_currency = oPrevForm->uh_currency;
  // *** La classe CustomScrollList peut initialiser l'attribut uh_currency ***
  else
    self->uh_currency = -1;

  oScrollListClass = [self initTitleAndLabel];
  if (oScrollListClass == nil)
    return false;

  self->oList = (SumScrollList*)[oScrollListClass newInForm:(BaseForm*)self];

  // La liste de ce formulaire a initialisé une devise, donc le
  // formulaire a une liste de devises
  if (self->uh_currency != -1)
  {
    // Ici self->uh_currency est forcément initialisé par la méthode
    // -initFormCurrency de CustomScrollList appelée à la construction
    // de l'objet
    [self reloadCurrenciesPopup];

    // On dit à Maman qu'on a un popup des devises...
    self->uh_subclasses_flags = SUMLISTFORM_HAS_CURRENCIES_POPUP;
  }

  // Filtre de somme à droite du bouton retour
  pt_list = [self objectPtrId:CustomListList];
  LstSetDrawFunction(pt_list, list_line_draw);
  LstSetSelection(pt_list, 0);
  CtlSetLabel([self objectPtrId:CustomListPopup],
	      LstGetSelectionText(pt_list, 0));

  // On repositionne le champ de la somme
  [self sumFieldRepos];

  return [super open];
}


- (Boolean)menu:(UInt16)uh_id
{
  if ([super menu:uh_id])
    return true;

  switch (uh_id)
  {
  case CustomListSelectInvert:
  case CustomListSelectNone:
  case CustomListSelectAll:
    // Invert   => -1
    // Unselect => 0
    // Select   => 1
    [(CustomScrollList*)self->oList
			selectChange:(Int16)uh_id - CustomListSelectNone];
    break;

  default:
    return false;
  }

  return true;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  if ([super ctlSelect:ps_select])
    return true;

  switch (ps_select->controlID)
  {
  case CustomListQuit:
    if ([(CustomScrollList*)self->oList beforeQuitting] == false)
      break;

    [self returnToLastForm];
    break;

  case CustomListPopup:
  {
    ListType *pt_list = [self objectPtrId:CustomListList];
    UInt16 uh_old_index, uh_index;

    uh_old_index = LstGetSelection(pt_list);

    uh_index = LstPopupList(pt_list);
    if (uh_index != noListSelection)
    {
      // All, Selected, Not selected
      if (uh_index <= 2)
      {
	CtlSetLabel(ps_select->pControl,
		    LstGetSelectionText(pt_list, uh_index));

	// On repositionne le champ de la somme
	[self sumFieldRepos];

	[(CustomScrollList*)self->oList changeSumFilter:uh_index];
      }
      // Invert(3), Unselect all(4), Select all(5)
      else
      {
	// On resélectionne le type de somme
	LstSetSelection(pt_list, uh_old_index);

	// Invert   => -1
	// Unselect => 0
	// Select   => 1
	[(CustomScrollList*)self->oList selectChange:(Int16)uh_index - 4];
      }
    }
  }
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
    // Si les types, les modes, les comptes ou les opérations ont
    // changé, on met la liste à jour
    if (ps_update->updateCode & (frmMaTiUpdateListTypes
				 | frmMaTiUpdateListModes
				 | frmMaTiUpdateListTransactions
				 | frmMaTiUpdateListAccounts))
    {
      // On remet le cadre à jour, même si ça n'est pas forcément nécessaire
      [self initTitleAndLabel];

      // Dans le cas d'une opération modifiée, on la rend visible dans
      // la liste
      switch (self->uh_form_flags & APP_FORM_ID_FLAGS_MASK)
      {
      case CLIST_SUBFORM_TRANS_STATS:
      case CLIST_SUBFORM_TRANS_FLAGGED:
	if (ps_update->updateCode & frmMaTiUpdateListTransactions)
	{
	  UInt16 uh_index = (ps_update->updateCode >> 16);

	  if (uh_index > 0)
	    [self->oList setCurrentItem:
		   uh_index | SCROLLLIST_CURRENT_DONT_RELOAD];
	}
	break;
      }

      [self->oList updateWithoutRedraw];

      // On efface le contenu de la liste, le redraw de retour sur
      // notre écran fera le reste
      TblEraseTable(self->oList->pt_table);
    }
  }

  return [super callerUpdate:ps_update];
}


// Appelée par -redrawForm si le DIA a changé d'état avant le redessin
- (void)sumTypeWidgetChange
{
  // On redimensionne le champ de la somme
  [self sumFieldRepos];
}

@end
