/* 
 * EditSplitForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Ven fév 24 14:40:22 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb  1 14:26:29 2008
 * Update Count    : 174
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: EditSplitForm.m,v $
 * Revision 1.5  2008/02/01 17:14:49  max
 * Use symbol* macros whenever it is possible.
 *
 * Revision 1.4  2008/01/14 17:00:59  max
 * Handle signed splits.
 *
 * Revision 1.3  2006/11/04 23:48:05  max
 * Add -beforeOpen method.
 * Correct amount validation.
 * Implement goto event.
 *
 * Revision 1.2  2006/06/23 13:25:08  max
 * Now call -focusObject: instead of FrmSetFocus() to set focus to a field.
 * Auto-init amount field when creating a new split then select it.
 *
 * Revision 1.1  2006/06/19 12:23:44  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_EDITSPLITFORM
#include "EditSplitForm.h"

#include "MaTirelire.h"
#include "TransForm.h"
#include "DescModesListForm.h"
#include "TypesListForm.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


// Pour déterminer si l_amount est un crédit
#define IS_CREDIT(l_amount)	(l_amount >= 0)


@implementation EditSplitForm

- (EditSplitForm*)free
{
  [[oMaTirelire desc] popupListFree:self->pv_popup_desc];
  [[oMaTirelire type] popupListFree:self->pv_popup_types];

  return [super free];
}


- (void)fillCounter
{
  Char ra_counter[] = "000/000", ra_arrow[] = "X";
  Coord uh_new_x;
  UInt16 uh_label_idx, uh_len;
  Boolean b_old_drawn = self->uh_form_drawn, b_enabled;

  uh_label_idx = FrmGetObjectIndex(self->pt_frm, EditSplitPos);

  if (b_old_drawn)
  {
    self->uh_form_drawn = false;
    [self hideIndex:uh_label_idx];
  }

  // Le compteur
  uh_len = StrPrintF(ra_counter, "%u/%u", self->uh_cur, self->uh_num);
  FrmCopyLabel(self->pt_frm, EditSplitPos, ra_counter);

  // The first time
  if (self->uh_x_counter == 0)
    FrmGetObjectPosition(self->pt_frm, uh_label_idx,
			 &self->uh_x_counter, &self->uh_y_counter);

  // 35 is the width of "000/000" in the std font
  uh_new_x = self->uh_x_counter + (35 - FntCharsWidth(ra_counter, uh_len)) / 2;
  if (uh_new_x != self->uh_x_counter)
    FrmSetObjectPosition(self->pt_frm, uh_label_idx,
			 uh_new_x, self->uh_y_counter);

  // Les flèches à gauche et à droite du compteur, grisées si un seul élément
  b_enabled = self->uh_num > 1;

  CtlSetEnabled([self objectPtrId:EditSplitPrev], b_enabled);
  CtlSetEnabled([self objectPtrId:EditSplitNext], b_enabled);

  // ==> b_enabled ? symbol11LeftArrow : symbol11LeftArrowDisabled;
  ra_arrow[0] = symbol11LeftArrowDisabled - b_enabled * 3;
  [self fillLabel:EditSplitPrev withSTR:ra_arrow];
  ra_arrow[0]++;
  [self fillLabel:EditSplitNext withSTR:ra_arrow];

  if (b_old_drawn)
  {
    self->uh_form_drawn = true;
    [self showIndex:uh_label_idx];
  }
}


- (Boolean)saveSplit
{
   TransForm *oTransForm = (TransForm*)self->oPrevForm;
   MemHandle pv_split;
   struct s_rec_one_sub_transaction *ps_split;
   t_amount l_amount;
   UInt16 uh_size;

   uh_size = sizeof(struct s_rec_one_sub_transaction) + 1 // + 1 for ra_desc \0
     + FldGetTextLength([self objectPtrId:EditSplitDesc]);

   // On vérifie le montant en premier, puisque c'est le seul champ
   // sur lequel il peut y avoir une erreur
   if ([self checkField:EditSplitAmount
	     flags:FLD_CHECK_VOID|FLD_SELTRIGGER_SIGN|FLD_TYPE_FDWORD
	     resultIn:&l_amount
	     fieldName:strEditSplitAmount] == false)
     return false;

   // Nouvelle sous opération
   if (oTransForm->h_split_index < 0)
   {
     NEW_HANDLE(pv_split, uh_size, return false);

     if (oTransForm->oSplits == nil)
       oTransForm->oSplits = [Array new];

     if ([oTransForm->oSplits push:pv_split] == false)
     {
       if ([oTransForm->oSplits size] == 0)
	 oTransForm->oSplits = [oTransForm->oSplits free];

       MemHandleFree(pv_split);

       NEW_ERROR((UInt32)-1, return false);
     }

     oTransForm->h_split_index = self->uh_num - 1;
   }
   // Sous-opération existante
   else
   {
     pv_split = [oTransForm->oSplits fetch:oTransForm->h_split_index];

     if (MemHandleResize(pv_split, uh_size) != 0)
       NEW_ERROR(uh_size, return false);
   }

   // Remplissage
   ps_split = MemHandleLock(pv_split);

   MemSet(ps_split, uh_size, '\0');

   // Description
   [self checkField:EditSplitDesc flags:FLD_CHECK_NONE
	 resultIn:ps_split->ra_desc fieldName:FLD_NO_NAME];

   // Montant (la somme des sous-op doit correspondre à la valeur
   // absolue du montant de l'opération. Donc si le montant de
   // l'opération est < 0, il faut inverser le signe du montant de la
   // sous-op avant de sauver)
   ps_split->l_amount = oTransForm->s_trans.uh_op_type == OP_DEBIT
     ? - l_amount : l_amount;

   // Type
   ps_split->ui_type = [[oMaTirelire type] popupListGet:self->pv_popup_types];

   MemHandleUnlock(pv_split);

  return true;
}


- (void)loadSplit
{
  TransForm *oTransForm = (TransForm*)self->oPrevForm;
  MemHandle pv_split;
  struct s_rec_one_sub_transaction *ps_split;

  pv_split = [oTransForm->oSplits fetch:self->uh_cur - 1];
  ps_split = MemHandleLock(pv_split);

  // La somme
  [self replaceField:REPLACE_FIELD_EXT | EditSplitAmount
	withSTR:(Char*)ps_split->l_amount len:REPL_FIELD_FDWORD];

  // Crédit si (op < 0 & split < 0) | (op > 0 & split > 0)
  // donc : soit (op > 0) soit (split < 0) mais pas les deux !
  [self setCredit:oTransForm->s_trans.uh_op_type ^ (ps_split->l_amount < 0)];

  // La description
  [self replaceField:EditSplitDesc withSTR:ps_split->ra_desc len:-1];

  // Le popup des types
  [self initTypesPopup:ps_split->ui_type];

  MemHandleUnlock(pv_split);

  // On garde la trace de l'élément chargé pour TransForm et pour la sauvegarde
  oTransForm->h_split_index = self->uh_cur - 1;

  // La sous-opération existe déjà, il faut les boutons suppression et nouveau
  if (self->uh_form_drawn)
  {
    [self showId:EditSplitDelete];

    // Nouveau seulement si < 255
    if (self->uh_num < 0xff)
      [self showId:EditSplitNew];
  }
}


- (void)expandMacro:(UInt16)uh_desc with:(Desc*)oDesc
{
  struct s_desc *ps_desc;
  UInt16 uh_focus = EditSplitAmount;
  Boolean b_sign_changed = false;

  ps_desc = [oDesc getId:uh_desc];

  // Le signe
  if (ps_desc->ui_sign > 0)
  {
    Boolean b_credit = ps_desc->ui_sign - 1;

    // Si le signe change
    if (b_credit ^ (CtlGetLabel([self objectPtrId:EditSplitSign])[0] == '+'))
    {
      [self setCredit:b_credit];
      b_sign_changed = true;
    }
  }

  // Il y a un nombre
  if (ps_desc->ra_amount[0] != '\0')
  {
    [self replaceField:EditSplitAmount withSTR:ps_desc->ra_amount len:-1];

    // Si le nombre commence par 0, le curseur doit être à gauche
    if (ps_desc->ra_amount[0] == '0')
      FldSetInsPtPosition([self objectPtrId:EditSplitAmount], 0);
  }

  // Le type d'opération
  if (ps_desc->ui_is_type)
  {
    // Si le signe vient de changer, on reconstruit tout le popup des types
    if (b_sign_changed)
      [self initTypesPopup:ps_desc->ui_type];
    else
      [[oMaTirelire type] popupList:self->pv_popup_types
			  setSelection:ps_desc->ui_type];
  }
  // Le signe a changé (et il n'y a pas de type dans la macro) => on
  // reconstruit tout le popup des types avec le type courant
  else if (b_sign_changed)
    [self initTypesPopup:(UInt16)-1];

  // La description
  if (ps_desc->ra_desc[0] != '\0')
    if ([(TransForm*)self->oPrevForm expandDesc:ps_desc inField:EditSplitDesc])
      uh_focus = EditSplitDesc;

  // Auto-validation ???
  if (ps_desc->ui_auto_valid)
    CtlHitControl([self objectPtrId:EditSplitOK]);

  [oDesc getFree:ps_desc];

  /* Le focus
   * - dans le champ somme par défaut
   * - dans le champ desc si le dernier caractère inséré est un espace
   */
  [self focusObject:uh_focus];
}


- (void)beforeOpen
{
  TransForm *oTransForm = (TransForm*)self->oPrevForm;
  Currency *oCurrencies = [oMaTirelire currency];
  struct s_currency *ps_currency;

  self->uh_num = oTransForm->oSplits != nil ? [oTransForm->oSplits size] : 0;

  // La devise de l'opération
  ps_currency =
    [oCurrencies getId:[oCurrencies
			 popupListGet:oTransForm->pv_popup_currencies]];

  [self fillLabel:EditSplitCurrency withSTR:ps_currency->ra_name];

  [oCurrencies getFree:ps_currency];
}


//
// Initialise le popup des types
- (void)initTypesPopup:(UInt16)uh_type
{
  TransForm *oTransForm = (TransForm*)self->oPrevForm;
  Type *oTypes = [oMaTirelire type];
  Char ra_account_name[dmCategoryLength];

  if (self->pv_popup_types != NULL)
  {
    if (uh_type == (UInt16)-1)
      uh_type = [oTypes popupListGet:self->pv_popup_types];

    [oTypes popupListFree:self->pv_popup_types];
  }

  CategoryGetName([oMaTirelire transaction]->db,
		  oTransForm->uh_account, ra_account_name);

  // Pas d'information sur le signe, on regarde donc le signe du montant
  if ((uh_type & (TYPE_FLAG_SIGN_CREDIT | TYPE_FLAG_SIGN_DEBIT)) == 0)
  {
    if (CtlGetLabel([self objectPtrId:EditSplitSign])[0] == '+')
      uh_type |= TYPE_FLAG_SIGN_CREDIT;
    else
      uh_type |= TYPE_FLAG_SIGN_DEBIT;
  }

  self->pv_popup_types = [oTypes popupListInit:EditSplitTypeList
				 form:self->pt_frm
				 Id:uh_type | TYPE_ADD_EDIT_LINE
				 forAccount:ra_account_name];
}


- (Boolean)open
{
  TransForm *oTransForm = (TransForm*)self->oPrevForm;

  [self beforeOpen];

  // Création
  if (oTransForm->h_split_index < 0)
  {
    TransForm *oTransForm = (TransForm*)oFrm->oPrevForm;
    FieldType *ps_field;
    t_amount l_amount;
    Boolean b_credit;

    self->uh_num++;
    self->uh_cur = self->uh_num;

    b_credit = oTransForm->s_trans.uh_op_type;

    // On place la somme restante entre la somme de l'opération et
    // celle des sous-opérations
    [oTransForm checkField:OpAmount flags:FLD_TYPE_FDWORD
		resultIn:&l_amount fieldName:FLD_NO_NAME];
    l_amount -= oTransForm->l_splits_sum;
    if (l_amount != 0)
    {
      [self replaceField:REPLACE_FIELD_EXT | EditSplitAmount
	    withSTR:(Char*)l_amount len:REPL_FIELD_FDWORD];

      ps_field = [self objectPtrId:EditSplitAmount];
      FldSetSelection(ps_field, 0, FldGetTextLength(ps_field));

      // Si on a affaire à un débit, il faut inverser le signe du reste
      if (b_credit == false)
	l_amount = - l_amount;

      b_credit = IS_CREDIT(l_amount);
    }

    [self setCredit:b_credit];

    // Pas de bouton de suppression ni nouveau
    [self hideId:EditSplitDelete];
    [self hideId:EditSplitNew];

    // Le popup des types
    [self initTypesPopup:TYPE_UNFILED];
  }
  // Édition
  else
  {
    self->uh_cur = oTransForm->h_split_index + 1;

    // Le popup des types est initialisé dans -loadSplit
    [self loadSplit];

    if (self->uh_num >= 0xff)
      [self hideId:EditSplitNew];
  }

  [self fillCounter];

  // Barre de scroll sur le label si besoin
  [self fieldUpdateScrollBar:EditSplitScrollbar
	fieldPtr:[self objectPtrId:EditSplitScrollbar - 1]
	setScroll:true];

  [super open];

  [self focusObject:EditSplitAmount];

  return true;
}


- (Boolean)goto:(struct frmGoto *)ps_goto
{
  TransForm *oTransForm = (TransForm*)self->oPrevForm;
  FieldType *pt_field;

  [self beforeOpen];

  oTransForm->h_split_index = ps_goto->matchCustom;

  self->uh_cur = oTransForm->h_split_index + 1;
  [self loadSplit];

  if (self->uh_num >= 0xff)
    [self hideId:EditSplitNew];

  [self fillCounter];

  // Barre de scroll sur le label si besoin
  [self fieldUpdateScrollBar:EditSplitScrollbar
	fieldPtr:[self objectPtrId:EditSplitScrollbar - 1]
	setScroll:true];

  [super open];

  pt_field = [self objectPtrId:ps_goto->matchFieldNum];
  if (pt_field != NULL)
  {
    // Si c'est la description on la scrolle
    if (ps_goto->matchFieldNum == EditSplitDesc)
    {
      UInt16 uh_max_value, uh_scroll_pos, uh_text_height, uh_field_height;

      FldSetScrollPosition(pt_field, ps_goto->matchPos);

      FldGetScrollValues(pt_field, &uh_scroll_pos,
			 &uh_text_height, &uh_field_height);

      if (uh_text_height > uh_field_height)
	uh_max_value = uh_text_height - uh_field_height;
      else if (uh_scroll_pos)
	uh_max_value = uh_scroll_pos;
      else
	uh_max_value = 0;

      SclSetScrollBar([self objectPtrId:EditSplitScrollbar],
		      uh_scroll_pos, 0, uh_max_value, uh_field_height - 1);
    }

    // On sélectionne tout...
    if ((Int16)ps_goto->matchPos < 0)
      FldSetSelection(pt_field, 0, FldGetTextLength(pt_field));
    // On sélectionne la bonne partie
    else
      FldSetSelection(pt_field, ps_goto->matchPos,
		      ps_goto->matchPos + ps_goto->matchLen);
  }

  return true;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case EditSplitPopup:
  {
    Desc *oDesc = [oMaTirelire desc];
    UInt16 uh_desc;

    // Liste des descriptions pas encore construite
    if (self->pv_popup_desc == NULL)
    {
      struct s_desc_popup_infos s_infos;

      s_infos.uh_account = ((TransForm*)self->oPrevForm)->uh_account;
      s_infos.uh_flags = DESC_ADD_EDIT_LINE;
      s_infos.ra_shortcut[0] = '\0';

      self->pv_popup_desc = [oDesc popupListInit:EditSplitDescList
				   form:self->pt_frm
				   infos:&s_infos];
    }

    uh_desc = [oDesc popupList:self->pv_popup_desc autoReturn:false];

    switch (uh_desc)
    {
    case noListSelection:
      break;

    case DESC_EDIT:
      FrmPopupForm(DescListFormIdx);
      break;

    default:
      [self expandMacro:uh_desc with:oDesc];
      break;
    }
  }
  break;

  case EditSplitSign:
    [self setCredit:(CtlGetLabel(ps_select->pControl))[0] == '-'];
    [self initTypesPopup:(UInt16)-1];
    break;

  case EditSplitTypePopup:
  {
    UInt16 uh_type = [[oMaTirelire type] popupList:self->pv_popup_types];

    if (uh_type != noListSelection && (uh_type & ITEM_EDIT))
    {
      // Car TypesListForm appelle la méthode -getInfos
      self->ui_infos = TYPE_LIST_DEFAULT_ID | (uh_type & ~ITEM_EDIT);

      // On lance la boîte d'édition des types...
      FrmPopupForm(TypesListFormIdx);
    }
  }
  break;

  case EditSplitOK:
    if ([self saveSplit] == false)
      break;

    // Continue sur Cancel...

  case EditSplitCancel:
    [self returnToLastForm];
    break;

  case EditSplitDelete:
  {
    TransForm *oTransForm = (TransForm*)self->oPrevForm;

    // Si on n'est pas sur une nouvelle sous-op pas encore enregistrée
    if (oTransForm->h_split_index >= 0)
    {
      MemHandleFree([oTransForm->oSplits remove:oTransForm->h_split_index]);

      if (--self->uh_num == 0)
	oTransForm->oSplits = [oTransForm->oSplits free];

      if (oTransForm->h_split_index >= self->uh_num)
	oTransForm->h_split_index--;
    }

    [self returnToLastForm];
  }
  break;

  case EditSplitNew:
  {
    TransForm *oTransForm = (TransForm*)self->oPrevForm;
    Int16 h_old_index = oTransForm->h_split_index;

    // Pour sauver en tant que nouveau
    oTransForm->h_split_index = -1;

    if ([self saveSplit] == false)
    {
      oTransForm->h_split_index = h_old_index;
      break;
    }

    // Sinon on est sur l'avant dernier comme -saveSplit initialise à
    // self->uh_num - 1
    oTransForm->h_split_index++;

    [self returnToLastForm];
  }
  break;

  default:
    return false;
  }

  return true;
}


- (Boolean)ctlRepeat:(struct ctlRepeat *)ps_repeat
{
  switch (ps_repeat->controlID)
  {
  case EditSplitPrev:
    if (self->uh_num != 1)
    {
      // Sauvegarde de cette sous-opération
      if ([self saveSplit] == false)
	break;

      if (--self->uh_cur == 0)
	self->uh_cur = self->uh_num;

      [self fillCounter];

      // Chargement de la nouvelle sous-opération
      [self loadSplit];
    }
    break;

  case EditSplitNext:
    if (self->uh_num != 1)
    {
      // Sauvegarde de cette sous-opération
      if ([self saveSplit] == false)
	break;

      if (self->uh_cur++ == self->uh_num)
	self->uh_cur = 1;

      [self fillCounter];

      // Chargement de la nouvelle sous-opération
      [self loadSplit];
    }
    break;
  }

  // On retourne toujours false sinon la répétition s'arrête
  return false;
}


- (Boolean)sclRepeat:(struct sclRepeat *)ps_repeat
{
  [self fieldScrollBar:EditSplitScrollbar
	linesToScroll:ps_repeat->newValue - ps_repeat->value update:false];

  return false;
}


- (Boolean)fldChanged:(struct fldChanged *)ps_fld_changed
{
  if (ps_fld_changed->fieldID == EditSplitDesc)
  {
    [self fieldUpdateScrollBar:EditSplitScrollbar
	  fieldPtr:ps_fld_changed->pField setScroll:false];
    return true;
  }

  return false;
}


- (void)setCredit:(Boolean)b_credit
{
  // Le label du signe
  [self fillLabel:EditSplitSign withSTR:b_credit ? "+" : "-"];

  // On met le focus sur le champ si le formulaire est déjà dessiné
  if (self->uh_form_drawn)
    [self focusObject:EditSplitAmount];
}


- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key
{
  UInt16 fld_id;

  // On laisse la main à Papa pour gérer les déplacements entre champs...
  if ([super keyDown:ps_key])
    return true;

  fld_id = FrmGetFocus(self->pt_frm);

  if (fld_id != noFocus
      && FrmGetObjectId(self->pt_frm, fld_id) == EditSplitAmount)
  {
    Boolean b_credit = ps_key->chr == '+';
    if (b_credit || ps_key->chr == '-')
    {
      ControlType *ps_ctl = [self objectPtrId:EditSplitSign];

      // On simule l'appui sur le signe s'il est différent
      if (CtlGetLabel(ps_ctl)[0] != ps_key->chr)
	CtlHitControl(ps_ctl);

      return true;
    }

    return [self keyFilter:KEY_FILTER_FLOAT | fld_id for:ps_key];
  }

  return false;
}


- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update
{
  switch (UPD_CODE(ps_update->updateCode))
  {
  case frmMaTiUpdateList:
    // La liste des descriptions a changé
    if (ps_update->updateCode & frmMaTiUpdateListDesc)
    {
      // Inutile de reconstruire la liste des descriptions, elle le
      // sera au déploiement du popup
      [[oMaTirelire desc] popupListFree:self->pv_popup_desc];
      self->pv_popup_desc = NULL;
    }

    // La liste des types a changé
    if (ps_update->updateCode & frmMaTiUpdateListTypes)
      [self initTypesPopup:(UInt16)-1];

    break;
  }

  return [super callerUpdate:ps_update];
}


- (void)returnToLastForm
{
  // On signale le changement de la liste de ventilation à TransForm
  [self sendCallerUpdate:(frmMaTiUpdateTransForm
			  | frmMaTiUpdateTransFormSplits)];

  [super returnToLastForm];
}

@end
