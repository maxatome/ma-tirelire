/* 
 * EditModeForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sun Aug 24 12:13:19 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb  1 17:12:36 2008
 * Update Count    : 4
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: EditModeForm.m,v $
 * Revision 1.8  2008/02/01 17:14:30  max
 * Delete not needed WinPrintf.
 *
 * Revision 1.7  2008/01/14 17:01:55  max
 * Switch to new mcc.
 *
 * Revision 1.6  2006/06/23 13:24:43  max
 * Now call -focusObject: instead of FrmSetFocus() to set focus to a field.
 *
 * Revision 1.5  2006/04/25 08:46:15  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.4  2005/08/20 13:06:51  max
 * Updates are now genericaly managed by MaTiForm.
 *
 * Revision 1.3  2005/03/02 19:02:38  max
 * Swap buttons in alertModeDelete.
 *
 * Revision 1.2  2005/02/13 00:06:18  max
 * Change prototype of -keyFilter:for:
 * It allows to detect and not block special keys in numeric fields.
 * Now the Select key of the 5-way works everywhere...
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_EDITMODEFORM
#include "EditModeForm.h"

#include "MaTirelire.h"
#include "DescModesListForm.h"
#include "Mode.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX

#include "misc.h"


@implementation EditModeForm

- (Boolean)extractAndSave:(UInt16)uh_update_code
{
  struct s_mode *ps_new_mode;
  UInt16 uh_size;
  UInt16 uh_tmp;
  Boolean b_ret = false;

  uh_size = sizeof(struct s_mode) + 1 // + 1 for \0 of ra_name
    + FldGetTextLength([self objectPtrId:EditModeLabel]);

  NEW_PTR(ps_new_mode, uh_size, return false);

  MemSet(ps_new_mode, sizeof(struct s_mode), '\0');

  // Mode name
  if ([self checkField:EditModeLabel flags:FLD_CHECK_VOID
	    resultIn:ps_new_mode->ra_name fieldName:strEditModeName] == false)
    goto end;

  // Mode ID (si création il sera écrasé)
  ps_new_mode->ui_id = self->uh_mode_id;

  // Value date
  if (CtlGetValue([self objectPtrId:EditModeCheck1]))
  {
    // Si date op < au...
    if ([self checkField:EditModeCheck1Day1
	      flags:FLD_CHECK_NULL|FLD_CHECK_VOID|FLD_TYPE_WORD
	      resultIn:&uh_tmp fieldName:strEditModeCheck1Day1] == false)
      goto end;
    ps_new_mode->ui_first_val = (uh_tmp > 31) ? 31 : uh_tmp;

    // alors date de valeur =
    if ([self checkField:EditModeCheck1Day2
	      flags:FLD_CHECK_NULL|FLD_CHECK_VOID|FLD_TYPE_WORD
	      resultIn:&uh_tmp fieldName:strEditModeCheck1Day2] == false)
      goto end;
    ps_new_mode->ui_debit_date = (uh_tmp > 31) ? 31 : uh_tmp;

    // du mois
    ps_new_mode->ui_value_date
      = (LstGetSelection([self objectPtrId:EditModeCheck1List]) == 0)
      ? MODE_VAL_DATE_CUR_MONTH : MODE_VAL_DATE_NEXT_MONTH;
  }
  else if (CtlGetValue([self objectPtrId:EditModeCheck2]))
  {
    if ([self checkField:EditModeCheck2Day
	      flags:FLD_CHECK_VOID|FLD_TYPE_WORD
	      resultIn:&uh_tmp fieldName:strEditModeCheck2Day] == false)
      goto end;
    ps_new_mode->ui_first_val = (uh_tmp > 63) ? 63 : uh_tmp; // 6 bits

    // avant/après la date de l'opération
    ps_new_mode->ui_value_date
      = (LstGetSelection([self objectPtrId:EditModeCheck2List]) == 0)
      ? MODE_VAL_DATE_MINUS_DAYS : MODE_VAL_DATE_PLUS_DAYS;
  }

  // Cheque auto
  ps_new_mode->ui_cheque_auto
    = CtlGetValue([self objectPtrId:EditModeChequeAuto]);

  // Account name
  [self checkField:EditModeOnlyIn flags:FLD_CHECK_NONE
	resultIn:ps_new_mode->ra_only_in_account fieldName:FLD_NO_NAME];

  // Sauvegarde seulement si le contenu change...
  if (1)
  {
    Mode *oMode = [oMaTirelire mode];
    UInt16 uh_index_pos;

    if (self->uh_mode_id != MODE_UNKNOWN)
    {
      uh_index_pos = [oMode getCachedIndexFromID:self->uh_mode_id];

      // Il s'agit d'une création par copie => on se met juste après l'original
      if (uh_update_code & frmMaTiUpdateEdit2ListNewItem)
      {
	uh_update_code |= frmMaTiUpdateEdit2ListNewItemAfter;
	uh_index_pos++;
      }
    }
    // Création pure...
    else
      uh_index_pos = dmMaxRecordIndex;

    if ([oMode save:ps_new_mode size:uh_size
	       asId:&uh_index_pos
	       asNew:(uh_update_code & frmMaTiUpdateEdit2ListNewItem) != 0]
	== false)
      goto end;

    // On update Papa car ça a changé...
    self->ui_update_mati_list |= uh_update_code;
  }

  // On peut retourner chez Papa car tout s'est bien passé...
  [self returnToLastForm];

  b_ret = true;

 end:
  MemPtrFree(ps_new_mode);

  return b_ret;
}


- (Boolean)open
{
  ListPtr pt_lst;
  UInt16 uh_month, uh_days, uh_index;

  uh_month = 0;
  uh_days = 1;

  // Default value...
  self->uh_mode_id = MODE_UNKNOWN;

  uh_index = [(DescModesListForm*)self->oPrevForm editedEntryIndex];

  // New
  if (uh_index == dmMaxRecordIndex)
  {
    [self hideId:EditModeDelete];
    [self hideId:EditModeNew];
  }
  // Edit
  else
  {
    Mode *oMode = [oMaTirelire mode];
    struct s_mode *ps_mode;

    ps_mode = [oMode getId:ITEM_SET_DIRECT(uh_index)];
    if (ps_mode != NULL)
    {
      self->uh_mode_id = ps_mode->ui_id;

      // Name
      [self replaceField:EditModeLabel withSTR:ps_mode->ra_name len:-1];

      // Account
      [self replaceField:EditModeOnlyIn
	    withSTR:ps_mode->ra_only_in_account len:-1];

      // Cheque auto
      CtlSetValue([self objectPtrId:EditModeChequeAuto],
		  ps_mode->ui_cheque_auto);

      // Value date
      switch (ps_mode->ui_value_date)
      {
      case MODE_VAL_DATE_CUR_MONTH:
      case MODE_VAL_DATE_NEXT_MONTH:
	CtlSetValue([self objectPtrId:EditModeCheck1], 1);

	[self replaceField:REPLACE_FIELD_EXT | EditModeCheck1Day1
	      withSTR:(Char*)ps_mode->ui_first_val
	      len:REPL_FIELD_DWORD];

	[self replaceField:REPLACE_FIELD_EXT | EditModeCheck1Day2
	      withSTR:(Char*)ps_mode->ui_debit_date
	      len:REPL_FIELD_DWORD];

	uh_month = (ps_mode->ui_value_date == MODE_VAL_DATE_NEXT_MONTH);
	break;

      case MODE_VAL_DATE_PLUS_DAYS:
      case MODE_VAL_DATE_MINUS_DAYS:
	CtlSetValue([self objectPtrId:EditModeCheck2], 1);

	[self replaceField:REPLACE_FIELD_EXT | EditModeCheck2Day
	      withSTR:(Char*)ps_mode->ui_first_val
	      len:REPL_FIELD_DWORD];

	uh_days = (ps_mode->ui_value_date == MODE_VAL_DATE_PLUS_DAYS);
	break;
      }

      // Unlock the record
      [oMode getFree:ps_mode];
    }

    // Hide new button when max number of mode reached
    if ([(DescModesListForm*)self->oPrevForm isChildNewButton] == false)
      [self hideId:EditModeNew];
  }


  // Popups init
  pt_lst = [self objectPtrId:EditModeCheck1List];
  LstSetSelection(pt_lst, uh_month);
  CtlSetLabel([self objectPtrId:EditModeCheck1Popup],
	      LstGetSelectionText(pt_lst, uh_month));

  pt_lst = [self objectPtrId:EditModeCheck2List];
  LstSetSelection(pt_lst, uh_days);
  CtlSetLabel([self objectPtrId:EditModeCheck2Popup],
	      LstGetSelectionText(pt_lst, uh_days));

  [super open];

  [self focusObject:EditModeLabel];

  return true;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case EditModeCheck1:
    if (CtlGetValue(ps_select->pControl))
      CtlSetValue([self objectPtrId:EditModeCheck2], 0);
    break;

  case EditModeCheck2:
    if (CtlGetValue(ps_select->pControl))
      CtlSetValue([self objectPtrId:EditModeCheck1], 0);
    break;

  case EditModeDelete:
    if (self->uh_mode_id != MODE_UNKNOWN)
    {
      Mode *oMode;
      UInt32 ui_dbases_trans;
      UInt16 uh_desc;

      // Boîte de confirmation de suppression
      if (FrmAlert(alertModeDelete) == 0)
	break;

      oMode = [oMaTirelire mode];

      // Suppression effective
      if ([oMode deleteId:self->uh_mode_id] < 0)
      {
	// XXX
	break;
      }

      // On répercute sur les macros
      uh_desc = [[oMaTirelire desc] removeMode:self->uh_mode_id];

      // On répercute sur les opérations
      // Big hack... due to the inexistence of @selector in mcc
      ui_dbases_trans = do_on_each_transaction(Transaction->_removeMode_,
					       self->uh_mode_id);

      if (uh_desc || ui_dbases_trans)
      {
	Char ra_desc[5 + 1], ra_trans[5 + 1], ra_dbases[5 + 1];

	StrIToA(ra_desc, uh_desc);
	StrIToA(ra_trans, ui_dbases_trans & 0xffff);
	StrIToA(ra_dbases, ui_dbases_trans >> 16);

	FrmCustomAlert(alertRecordsModified, ra_trans, ra_dbases, ra_desc);
      }

      // On envoie un update au formulaire précédent
      self->ui_update_mati_list |= (frmMaTiUpdateEdit2List
				    | frmMaTiUpdateEdit2ListDeletedItem);

      // Puis retour...
      [self returnToLastForm];
    }
    break;

  case EditModeNew:
    if ([(DescModesListForm*)self->oPrevForm isChildNewButton])
      // Sauvegarde
      [self extractAndSave:(frmMaTiUpdateEdit2List
			    | frmMaTiUpdateEdit2ListNewItem)];
    break;

  case EditModeOK:
    // Sauvegarde
    // (pas besoin de true si création car self->uh_mode_id == MODE_UNKNOWN)
#define OK_UPDATE_CODE	\
	(self->uh_mode_id == MODE_UNKNOWN \
	 ? frmMaTiUpdateEdit2List | frmMaTiUpdateEdit2ListNewItem \
	 : frmMaTiUpdateEdit2List)
    [self extractAndSave:OK_UPDATE_CODE];
#undef OK_UPDATE_CODE
    break;

  case EditModeCancel:
    [self returnToLastForm];
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
    switch (FrmGetObjectId(self->pt_frm, fld_id))
    {
    case EditModeCheck1Day1:
    case EditModeCheck1Day2:
    case EditModeCheck2Day:
      return [self keyFilter:KEY_FILTER_INT | fld_id for:ps_key];
    }

  return false;
}

@end
