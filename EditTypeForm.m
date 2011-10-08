/* 
 * EditTypeForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Wed Feb 18 23:51:02 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb  1 17:15:52 2008
 * Update Count    : 11
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: EditTypeForm.m,v $
 * Revision 1.9  2008/02/01 17:15:13  max
 * Cosmetic changes.
 *
 * Revision 1.8  2008/01/14 16:59:42  max
 * Switch to new mcc.
 *
 * Revision 1.7  2006/06/23 13:24:43  max
 * Now call -focusObject: instead of FrmSetFocus() to set focus to a field.
 *
 * Revision 1.6  2006/06/19 12:23:55  max
 * Conform to new -save:size:asId:asNew: protocol.
 *
 * Revision 1.5  2006/04/25 08:46:15  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.4  2005/08/28 10:02:30  max
 * Comment WinPrintf debug.
 *
 * Revision 1.3  2005/08/20 13:06:51  max
 * Updates are now genericaly managed by MaTiForm.
 *
 * Revision 1.2  2005/03/02 19:02:39  max
 * Swap buttons in alertTypeDelete.
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_EDITTYPEFORM
#include "EditTypeForm.h"

#include "MaTirelire.h"
#include "TypesListForm.h"
#include "Type.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX

#include "misc.h"


@implementation EditTypeForm

- (Boolean)extractAndSave:(UInt16)uh_update_code
{
  Type *oType = [oMaTirelire type];
  UInt16 uh_size, uh_sign;
  struct s_type *ps_new_type;
  Boolean b_ret = false;

  uh_size = sizeof(struct s_type) + 1 // + 1 for \0 of ra_name
    + FldGetTextLength([self objectPtrId:EditTypeLabel]);

  NEW_PTR(ps_new_type, uh_size, return false);

  MemSet(ps_new_type, sizeof(struct s_type), '\0');

  // Type name
  if ([self checkField:EditTypeLabel flags:FLD_CHECK_VOID
	    resultIn:ps_new_type->ra_name
	    fieldName:strEditModeName] == false) // OK pour strModeTypeName
    goto end;

  // Création d'un type
  if (uh_update_code & frmMaTiUpdateEdit2ListNewItem)
  {
    // ID à déterminer
    ps_new_type->ui_id = TYPE_UNFILED;

    // ID parent seulement si "Nouveau sous..." dans la liste des types
    if (self->uh_type_id & TYPE_NEW_UNDER)
    {
      ps_new_type->ui_parent_id = self->uh_type_id & ~TYPE_NEW_MASK;
      ps_new_type->ui_brother_id = TYPE_UNFILED;
    }
    else
    {
      ps_new_type->ui_parent_id = TYPE_UNFILED;

      // Insertion à la fin de la racine
      if (self->uh_type_id & TYPE_NEW_AT_ROOT)
	ps_new_type->ui_brother_id = TYPE_UNFILED;
      // On veut s'insérer juste après l'élément courant, on use alors
      // d'une astuce pour le communiquer à l'objet de classe Type en
      // plaçant l'ID dans le champ ui_brother_id du type.
      // Flag TYPE_NEW_AFTER ou rien...
      else
	ps_new_type->ui_brother_id = self->uh_type_id & ~TYPE_NEW_MASK;
    }
  }
  // Édition d'un type
  else
  {
    // On récupère la filiation (dans ce cas self->uh_type_id n'est que l'ID)
    struct s_type *ps_old_type = [oType getId:self->uh_type_id];

    MemMove(ps_new_type, ps_old_type, TYPE_RELATIONSHIP_SIZE);

    [oType getFree:ps_old_type];
  }

  // Account name
  [self checkField:EditTypeOnlyIn flags:FLD_CHECK_NONE
	resultIn:ps_new_type->ra_only_in_account fieldName:FLD_NO_NAME];

  // Sign dependance
  uh_sign = LstGetSelection([self objectPtrId:EditTypeSignList]);
  switch (uh_sign)
  {
  case 1:			// Débit
  case 2:			// Crédit
    ps_new_type->ui_sign_depend = uh_sign;
    break;
  default:
    ps_new_type->ui_sign_depend = TYPE_ALL;
    break;
  }

  // Sauvegarde seulement si le contenu change...
  if (1)
  {
    UInt16 uh_new_id;

    // Comme on est restrictif sur le signe, on vérifie que tous nos
    // fils ont bien le même signe que notre type
    if (ps_new_type->ui_id != TYPE_UNFILED
	&& ps_new_type->ui_sign_depend != TYPE_ALL
	&& [oType isBadSignInDescendantsOfId:ps_new_type->ui_id])
    {
      // On demande confirmation du changement du signe de tous les fils
      if (FrmAlert(alertTypeChangeChildrenSign))
	goto end;

      if ([oType propagateSign:ps_new_type->ui_sign_depend
		 overChildrenOfId:ps_new_type->ui_id] == false)
	goto end;
    }

    if ([oType save:ps_new_type size:uh_size asId:&uh_new_id
	       asNew:ps_new_type->ui_id == TYPE_UNFILED] == false) // OK
    {
      // XXX
      goto end;
    }

    if (ps_new_type->ui_id == TYPE_UNFILED)
      uh_update_code |= uh_new_id;

    // On update Papa car ça a changé...
    self->ui_update_mati_list |= uh_update_code;
  }

  // On peut retourner chez Papa car tout s'est bien passé...
  [self returnToLastForm];

  b_ret = true;

 end:
  MemPtrFree(ps_new_type);

  return b_ret;
}


- (UInt16)signChoiceParent:(UInt16)uh_parent_id
{
  UInt16 uh_sign_choice = 0;	// Pour TYPE_ALL

  // Pour choisir entre le popup et le label, on regarde le signe du père
  if (uh_parent_id != TYPE_UNFILED)
  {
    Type *oType = [oMaTirelire type];
    struct s_type *ps_parent_type = [oType getId:uh_parent_id];
    if (ps_parent_type != NULL)
    {
      uh_sign_choice = ps_parent_type->ui_sign_depend;
      [oType getFree:ps_parent_type];

      if (uh_sign_choice == TYPE_ALL)
	uh_sign_choice = 0;
    }
  }

  return uh_sign_choice;
}


- (Boolean)open
{
  ListPtr pt_lst;
  UInt16 uh_parent_id, uh_parent_sign, uh_type_sign;
  UInt16 uh_label, uh_hide_label;

  uh_parent_id = TYPE_UNFILED;	// Pas de parent par défaut
  uh_type_sign = 0;		// "Toutes les opérations" par défaut

  self->uh_type_id = [(TypesListForm*)self->oPrevForm editedTypeId];

  // Édition de uh_id
  if ((self->uh_type_id & TYPE_NEW_MASK) == 0)
  {
    Type *oType = [oMaTirelire type];
    struct s_type *ps_type;

    ps_type = [oType getId:self->uh_type_id];
    if (ps_type != NULL)
    {
      uh_parent_id = ps_type->ui_parent_id;
      uh_type_sign = ps_type->ui_sign_depend;

      if (uh_type_sign == TYPE_ALL)
	uh_type_sign = 0;

      // Name
      [self replaceField:EditTypeLabel withSTR:ps_type->ra_name len:-1];

      // Account
      [self replaceField:EditTypeOnlyIn
	    withSTR:ps_type->ra_only_in_account len:-1];

      // Hide delete button when the type has at least a child
      if (ps_type->ui_child_id != TYPE_UNFILED)
	[self hideId:EditTypeDelete];

      // Unlock the record
      [oType getFree:ps_type];
    }

    // Hide new button when max number of types reached
    if ([(TypesListForm*)self->oPrevForm isChildNewButton] == false)
      [self hideId:EditTypeNew];
  }
  // Nouveau
  else
  {
    [self hideId:EditTypeDelete];
    [self hideId:EditTypeNew];

    // Nouveau (en dernier fils)
    if (self->uh_type_id & TYPE_NEW_UNDER)
      uh_parent_id = self->uh_type_id & ~TYPE_NEW_MASK;
    // Nouveau en frère suivant (notre père sera celui de notre futur frère)
    else if (self->uh_type_id & TYPE_NEW_AFTER)
    {
      Type *oType = [oMaTirelire type];
      struct s_type *ps_prev_type;

      ps_prev_type = [oType getId:self->uh_type_id & ~TYPE_NEW_MASK];
      if (ps_prev_type != NULL)
      {
	uh_parent_id = ps_prev_type->ui_parent_id;
	[oType getFree:ps_prev_type];
      }
    }
  }

  // Sign popup/label init
  uh_parent_sign = [self signChoiceParent:uh_parent_id];

  pt_lst = [self objectPtrId:EditTypeSignList];

  uh_hide_label = EditTypeSignLabelInsteadPopup;
  uh_label = EditTypeSignPopup;

  // Label...
  if (uh_parent_sign != 0)	// On ne peut avoir que le signe de notre père
  {
    // On cache le popup
    uh_hide_label = EditTypeSignPopup;
    uh_label = EditTypeSignLabelInsteadPopup;

    uh_type_sign = uh_parent_sign;
  }

  [self hideId:uh_hide_label];

  // On initialise la liste et le label (popup OU label)
  LstSetSelection(pt_lst, uh_type_sign);
  CtlSetLabel([self objectPtrId:uh_label],
	      LstGetSelectionText(pt_lst, uh_type_sign));

  [super open];

  [self focusObject:EditTypeLabel];

  return true;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case EditTypeDelete:
    if ((self->uh_type_id & TYPE_NEW_MASK) == 0)
    {
      Type *oType;
      UInt32 ui_dbases_trans;
      UInt16 uh_desc;

      // Boîte de confirmation de suppression
      if (FrmAlert(alertTypeDelete) == 0)
	break;

      oType = [oMaTirelire type];

      // Suppression effective
      if ([oType deleteId:self->uh_type_id] < 0)
      {
	// XXX
	break;
      }

      // On répercute sur les macros
      uh_desc = [[oMaTirelire desc] removeType:self->uh_type_id];

      // On répercute sur les opérations
      // Big hack... due to the inexistence of @selector in mcc
      ui_dbases_trans = do_on_each_transaction(Transaction->_removeType_,
					       self->uh_type_id);

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

  case EditTypeNew:
    if ([(TypesListForm*)self->oPrevForm isChildNewButton])
      // Sauvegarde
      [self extractAndSave:(frmMaTiUpdateEdit2List
			    | frmMaTiUpdateEdit2ListNewItem)];
    break;

  case EditTypeOK:
    // Sauvegarde
#define OK_UPDATE_CODE \
		((self->uh_type_id & TYPE_NEW_MASK) \
		 ? frmMaTiUpdateEdit2List | frmMaTiUpdateEdit2ListNewItem \
		 : frmMaTiUpdateEdit2List)
    [self extractAndSave:OK_UPDATE_CODE];
    break;

  case EditTypeCancel:
    [self returnToLastForm];
    break;

  default:
    return false;
  }

  return true;
}

@end
