/* 
 * EditDescForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sun Feb 29 23:42:39 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jul  6 14:43:48 2007
 * Update Count    : 6
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: EditDescForm.m,v $
 * Revision 1.7  2008/01/14 17:02:22  max
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
 * Revision 1.3  2005/03/02 19:02:37  max
 * Swap buttons in alertDescDelete.
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

#define EXTERN_EDITDESCFORM
#include "EditDescForm.h"

#include "MaTirelire.h"
#include "DescModesListForm.h"
#include "Desc.h"
#include "Type.h"
#include "Mode.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX

#include "misc.h"


@implementation EditDescForm

- (EditDescForm*)free
{
  [[oMaTirelire mode] popupListFree:self->pv_popup_modes];
  [[oMaTirelire type] popupListFree:self->pv_popup_types];

  return [super free];
}


- (Boolean)extractAndSave:(UInt16)uh_update_code
{
  struct s_desc *ps_new_desc;
  UInt16 uh_size, uh_id;
  Boolean b_ret = false;

  uh_size = sizeof(struct s_desc) + 1 // + 1 for \0 of ra_desc
    + FldGetTextLength([self objectPtrId:EditDescLabel]);

  NEW_PTR(ps_new_desc, uh_size, return false);

  MemSet(ps_new_desc, sizeof(struct s_desc), '\0');

  // Description name
  [self checkField:EditDescLabel flags:FLD_CHECK_NONE
	resultIn:ps_new_desc->ra_desc fieldName:FLD_NO_NAME];

  // Account name (only in)
  [self checkField:EditDescOnlyIn flags:FLD_CHECK_NONE
	resultIn:ps_new_desc->ra_only_in_account fieldName:FLD_NO_NAME];

  // Shortcut
  {
    char *pa_shortcut = FldGetTextPtr([self objectPtrId:EditDescShortcut]);
    if (pa_shortcut)
      ps_new_desc->ui_shortcut = *pa_shortcut;
  }

  // Execution account
  [self checkField:EditDescAccount flags:FLD_CHECK_NONE
	resultIn:ps_new_desc->ra_account fieldName:FLD_NO_NAME];

  // Amount sign
  ps_new_desc->ui_sign = LstGetSelection([self objectPtrId:EditDescSignList]);

  // Amount...
  [self checkField:EditDescAmount flags:FLD_CHECK_NONE
	resultIn:ps_new_desc->ra_amount fieldName:FLD_NO_NAME];

  // Mode
  uh_id = [[oMaTirelire mode] popupListGet:self->pv_popup_modes];
  if (uh_id != ITEM_ANY)
  {
    ps_new_desc->ui_is_mode = 1;
    ps_new_desc->ui_mode = uh_id;
  }

  // Type
  uh_id = [[oMaTirelire type] popupListGet:self->pv_popup_types];
  if (uh_id != ITEM_ANY)
  {
    ps_new_desc->ui_is_type = 1;
    ps_new_desc->ui_type = uh_id;
  }

  // Xfer account
  [self checkField:EditDescXfer flags:FLD_CHECK_NONE
	resultIn:ps_new_desc->ra_xfer fieldName:FLD_NO_NAME];

  // Auto cheque
  ps_new_desc->ui_cheque_num
    = CtlGetValue([self objectPtrId:EditDescChequeAuto]);

  // Auto submit
  ps_new_desc->ui_auto_valid
    = CtlGetValue([self objectPtrId:EditDescAutoSubmit]);

  // Vérification : macro complètement vide
  if (ps_new_desc->ra_desc[0] == '\0'
      && ps_new_desc->ui_sign == 0
      && ps_new_desc->ui_is_mode == 0
      && ps_new_desc->ui_is_type == 0
      && ps_new_desc->ra_amount[0] == '\0'
      && ps_new_desc->ra_xfer[0] == '\0'
      && ps_new_desc->ra_account[0] == '\0')
  {
    FrmAlert(alertEmptyMacroDef);
    goto end;
  }

  // Vérification : cas de l'auto-validation
  if (ps_new_desc->ui_auto_valid && ps_new_desc->ra_amount[0] == '\0')
  {
    FrmAlert(alertMacroCantAutoSubmit);
    goto end;
  }

  // Sauvegarde seulement si le contenu change...
  if (1)
  {
    UInt16 uh_index_pos = self->uh_desc_idx;

    // Si on crée un nouvel enregistrement à partir d'un existant, on
    // se met juste après lui...
    if (self->uh_desc_idx != dmMaxRecordIndex
	&& (uh_update_code & frmMaTiUpdateEdit2ListNewItem))
    {
      uh_update_code |= frmMaTiUpdateEdit2ListNewItemAfter;
      uh_index_pos++;
    }

    if ([[oMaTirelire desc]
	  save:ps_new_desc size:uh_size
	  asId:&uh_index_pos
	  asNew:(uh_update_code & frmMaTiUpdateEdit2ListNewItem) != 0] == false)
    {
      // XXX
      goto end;
    }
			    
    // On update Papa car ça a changé...
    self->ui_update_mati_list |= uh_update_code;
  }

  // On peut retourner chez Papa car tout s'est bien passé...
  [self returnToLastForm];

  b_ret = true;

 end:
  MemPtrFree(ps_new_desc);

  return b_ret;
}


- (Boolean)open
{
  ListPtr pt_lst;
  UInt16 uh_amount_sign, uh_type, uh_mode;

  uh_amount_sign = 0;
  uh_type = ITEM_ANY;
  uh_mode = ITEM_ANY;

  self->uh_desc_idx = [(DescModesListForm*)self->oPrevForm editedEntryIndex];

  // New
  if (self->uh_desc_idx == dmMaxRecordIndex)
  {
    [self hideId:EditDescDelete];
    [self hideId:EditDescNew];
  }
  // Edit
  else
  {
    Desc *oDesc = [oMaTirelire desc];
    struct s_desc *ps_desc;

    ps_desc = [oDesc getId:self->uh_desc_idx];
    if (ps_desc != NULL)
    {
      // Label (EditDescLabel)
      [self replaceField:EditDescLabel withSTR:ps_desc->ra_desc len:-1];

      // Account (EditDescOnlyIn)
      [self replaceField:EditDescOnlyIn
	    withSTR:ps_desc->ra_only_in_account len:-1];

      // Shortcut (EditDescShortcut)
      {
	UChar ua_shortcut = ps_desc->ui_shortcut;
	[self replaceField:EditDescShortcut withSTR:&ua_shortcut len:1];
      }

      // Goto account (EditDescAccount)
      [self replaceField:EditDescAccount withSTR:ps_desc->ra_account len:-1];

      // Amount sign (popup EditDescSignPopup)
      uh_amount_sign = ps_desc->ui_sign;

      // Amount (EditDescAmount)
      [self replaceField:EditDescAmount withSTR:ps_desc->ra_amount len:-1];

      // Modes (popup EditDescModePopup)
      if (ps_desc->ui_is_mode)
	uh_mode = ps_desc->ui_mode;

      // Types (popup EditDescTypePopup)
      if (ps_desc->ui_is_type)
	uh_type = ps_desc->ui_type;

      // Xfer account (EditDescXfer)
      [self replaceField:EditDescXfer withSTR:ps_desc->ra_xfer len:-1];

      // Cheque auto (checkbox EditDescChequeAuto)
      CtlSetValue([self objectPtrId:EditDescChequeAuto],
		  ps_desc->ui_cheque_num);

      // Auto submit (checkbox EditDescAutoSubmit)
      CtlSetValue([self objectPtrId:EditDescAutoSubmit],
		  ps_desc->ui_auto_valid);

      // Unlock the record
      [oDesc getFree:ps_desc];
    }

    // Hide new button when max number of mode reached
    if ([(DescModesListForm*)self->oPrevForm isChildNewButton] == false)
      [self hideId:EditDescNew];
  }

  // Popup des types
  self->pv_popup_types = [[oMaTirelire type] popupListInit:EditDescTypeList
					     form:self->pt_frm
					     Id:uh_type | TYPE_ADD_ANY_LINE
					     forAccount:NULL];

  // Popup des modes
  self->pv_popup_modes
    = [[oMaTirelire mode] popupListInit:EditDescModeList
			  form:self->pt_frm
			  Id:uh_mode | ITEM_ADD_UNKNOWN_LINE|ITEM_ADD_ANY_LINE
			  forAccount:NULL];

  // Le popup du signe de la somme
  pt_lst = [self objectPtrId:EditDescSignList];
  LstSetSelection(pt_lst, uh_amount_sign);
  CtlSetLabel([self objectPtrId:EditDescSignPopup],
	      LstGetSelectionText(pt_lst, uh_amount_sign));

  // Barre de scroll sur le label si besoin
  [self fieldUpdateScrollBar:EditDescScrollbar
	fieldPtr:[self objectPtrId:EditDescScrollbar - 1]
	setScroll:true];

  [super open];

  [self focusObject:EditDescLabel];

  return true;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case EditDescTypePopup:
    [[oMaTirelire type] popupList:self->pv_popup_types];
    break;

  case EditDescModePopup:
    [[oMaTirelire mode] popupList:self->pv_popup_modes];
    break;

  case EditDescDelete:
    if (self->uh_desc_idx != dmMaxRecordIndex)
    {
      // Boîte de confirmation de suppression
      if (FrmAlert(alertDescDelete) == 0)
	break;

      // Suppression effective
      if ([[oMaTirelire desc] deleteId:self->uh_desc_idx] < 0)
      {
	// XXX
	break;
      }

      // On envoie un update au formulaire précédent
      self->ui_update_mati_list |= (frmMaTiUpdateEdit2List
				    | frmMaTiUpdateEdit2ListDeletedItem);

      // Puis retour...
      [self returnToLastForm];
    }
    break;

  case EditDescNew:
    if ([(DescModesListForm*)self->oPrevForm isChildNewButton])
      // Sauvegarde
      [self extractAndSave:(frmMaTiUpdateEdit2List
			    | frmMaTiUpdateEdit2ListNewItem)];
    break;

  case EditDescOK:
    // Sauvegarde
    // pas besoin de true si création car self->uh_desc_idx == dmMaxRecordIndex
#define OK_UPDATE_CODE \
		(self->uh_desc_idx == dmMaxRecordIndex \
		 ? frmMaTiUpdateEdit2List | frmMaTiUpdateEdit2ListNewItem \
		 : frmMaTiUpdateEdit2List)
    [self extractAndSave:OK_UPDATE_CODE];
#undef OK_UPDATE_CODE
    break;

  case EditDescCancel:
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

  if (fld_id != noFocus
      && FrmGetObjectId(self->pt_frm, fld_id) == EditDescAmount)
    return [self keyFilter:KEY_FILTER_FLOAT | fld_id for:ps_key];

  return false;
}


- (Boolean)sclRepeat:(struct sclRepeat *)ps_repeat
{
  [self fieldScrollBar:EditDescScrollbar
	linesToScroll:ps_repeat->newValue - ps_repeat->value update:false];

  return false;
}


- (Boolean)fldChanged:(struct fldChanged *)ps_fld_changed
{
  if (ps_fld_changed->fieldID == EditDescLabel)
  {
    [self fieldUpdateScrollBar:EditDescScrollbar
	  fieldPtr:ps_fld_changed->pField setScroll:false];
    return true;
  }

  return false;
}

@end
