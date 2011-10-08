/* 
 * Type.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sun Aug 24 13:04:25 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb  1 17:28:26 2008
 * Update Count    : 33
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: Type.m,v $
 * Revision 1.12  2008/02/01 17:08:16  max
 * s/WinPrintf/alert_error_str/g
 * Use symbol* macros whenever it is possible.
 *
 * Revision 1.11  2008/01/14 13:10:56  max
 * Switch to new mcc.
 * Fix memory leak.
 *
 * Revision 1.10  2006/12/18 09:30:25  max
 * Correct bug in sub-types selection.
 *
 * Revision 1.9  2006/06/19 12:26:28  max
 * Use new -save:size:asId:asNew: prototype.
 *
 * Revision 1.8  2006/04/25 08:48:20  max
 * Now handle type sign.
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.7  2005/10/06 19:48:21  max
 * match() now have a b_exact argument.
 * Minor fix in popup management.
 *
 * Revision 1.6  2005/10/03 20:32:30  max
 * -setBitFamily:forType: included brothers of passed type. Corrected.
 *
 * Revision 1.5  2005/08/28 10:02:40  max
 * Add -setBitFamily:forType: method.
 * -getId: now initialize more attributes for the fake unfiled type.
 * -listBuildInfos:num:largest: reworked.
 * Unfiled item is no longer made visible when selected in popup
 * list. This allows to select easily another item at the top of the
 * list without scrolling up.
 *
 * Revision 1.4  2005/08/20 13:07:16  max
 * -listBuildInfos:largest: can now build Handle'd list.
 * s/__list_draw_glyph/list_draw_glyph/g and no longer static.
 * -fullNameOfId:len: now call -fullNameOfId:len:truncatedTo:.
 * -fullNameOfId:len:truncatedTo: handle now corectly "Unfiled" special type.
 *
 * Revision 1.3  2005/03/27 15:38:30  max
 * Type name truncating is now multi-bytes chars compliant.
 *
 * Revision 1.2  2005/02/19 17:07:54  max
 * -fullNameOfId:len:truncatedTo: returns NULL when a type don't exists.
 *
 * Revision 1.1  2005/02/09 22:57:23  max
 * First import.
 *
 * ==================== RCS ==================== */

#include <PalmOSGlue/TxtGlue.h>

#define EXTERN_TYPE
#include "Type.h"

#include "BaseForm.h"		// list_line_draw_line

#include "MaTirelire.h"

#include "ids.h"

#include "misc.h"
#include "graph_defs.h"
#include "objRsc.h"		// XXX


@implementation Type

- (Type*)init
{
  VoidHand pv_type;
  UInt16 uh_first_id = TYPE_UNFILED;
  UInt16 uh_loops = NUM_TYPES; // Par sécurité... XXX
  UInt16 uh_num_rec;
  Int16 index;

  if ([self cacheAlloc:TYPE_NUM_CACHE_ENTRIES] == false)
  {
    // XXX
    return nil;
  }

  // DB opening/creating
  if ([self initDBType:MaTiTypesType nameSTR:MaTiTypesName] == nil)
  {
    // XXX
    return nil;
  }

  // Init the cache...
  [self cacheInit];

  uh_num_rec = DmNumRecords(self->db);

  // On parcourt du début vers la fin, car c'est dans cet ordre
  // qu'on a le plus de chance d'avoir le moins de ratés...
  for (index = 0; index < uh_num_rec; index++)
  {
    pv_type = DmQueryRecord(self->db, index);
    if (pv_type != NULL)
    {
      struct s_type *ps_type;

      ps_type = MemHandleLock(pv_type);

      //  Type de la racine
      if (ps_type->ui_parent_id == TYPE_UNFILED
	  //  C'est le premier que l'on rencontre
	  && (uh_first_id == TYPE_UNFILED
	      // OU BIEN on tombe sur le frère précédent du premier type
	      || ps_type->ui_brother_id == uh_first_id))
      {
	uh_first_id = ps_type->ui_id;
	index = -1;

	// Par sécurité... XXX
	if (--uh_loops == 0)
	{
	  uh_first_id = TYPE_UNFILED;
	  alert_error_str("Types first ID loop detected...");
	  // XXX
	  break;
	}
      }

      MemHandleUnlock(pv_type);
    }
  }

  // Le premier type à partir de la racine !
  self->uh_first_id = uh_first_id;

  return self;
}


////////////////////////////////////////////////////////////////////////
//
// Internal functions
//
////////////////////////////////////////////////////////////////////////

//
// Renvoie le dernier fils du type passé en paramètre ou NULL si le
// type n'a pas de fils. Le pointeur renvoyé par cette méthode doit
// être libéré par -getFree:
- (struct s_type*)getLastChild:(struct s_type*)ps_type
{
  struct s_type *ps_child_type;
  UInt16 uh_id;

  // On veut le dernier type de la racine
  if (ps_type == NULL)
  {
    uh_id = self->uh_first_id;

    // L'arborescence est vide
    if (uh_id == TYPE_UNFILED)
      return NULL;
  }
  // On veut le dernier fils du type passé en paramètre
  else
  {
    uh_id = ps_type->ui_child_id;

    // Nous n'avons pas de fils, donc pas de dernier fils...
    if (uh_id == TYPE_UNFILED)
      return NULL;
  }

  ps_child_type = [self getId:uh_id];

  // On parcourt tous les fils
  for (;;)
  {
    uh_id = ps_child_type->ui_brother_id;

    // Pas de frère, donc c'est fini...
    if (uh_id == TYPE_UNFILED)
      return ps_child_type;

    [self getFree:ps_child_type];

    // Fils suivant
    ps_child_type = [self getId:uh_id];
  }
}


//
// Renvoie le premier frère du type passé en paramètre ou NULL si
// aucun type n'est présent.
// ps_type peut valoir NULL si on veut le premier type de la racine.
- (struct s_type*)getFirstBrother:(struct s_type*)ps_type
{
  struct s_type *ps_parent_type;

  // Premier type de la racine
  if (ps_type == NULL || ps_type->ui_parent_id == TYPE_UNFILED)
  {
    if (self->uh_first_id == TYPE_UNFILED)
      return NULL;

    return [self getId:self->uh_first_id];
  }

  // Premier type du niveau
  ps_parent_type = [self getId:ps_type->ui_parent_id];

  ps_type = [self getId:ps_parent_type->ui_child_id];

  [self getFree:ps_parent_type];

  return ps_type;
}


//
// Renvoie le frère précédent du type passé en 1er paramètre
// accompagné de son père (NULL si racine) en contexte de liste. Un
// pointeur sur l'adresse du type père peut être passé en second
// paramètre si il a déjà été récupéré (pointeur sur NULL si juste
// récupération).
// Renvoie NULL si le type n'a pas de frère précédent (premier fils).
- (struct s_type*)getPrevBrother:(struct s_type*)ps_type
			parentIn:(struct s_type**)pps_parent_type
{
  struct s_type *ps_parent_type, *ps_child_type;
  UInt16 uh_id;

  // Notre père est déjà passé en paramètre
  if (pps_parent_type != NULL && *pps_parent_type != NULL)
    ps_parent_type = *pps_parent_type;
  // On récupère notre père
  else
  {
    if (ps_type->ui_parent_id != TYPE_UNFILED)
      ps_parent_type = [self getId:ps_type->ui_parent_id];
    else
      ps_parent_type = NULL;
  }

  // On a un père
  if (ps_parent_type != NULL)
  {
    // Premier fils de notre père => notre premier frère
    uh_id = ps_parent_type->ui_child_id;

    // On est le premier fils de notre père => pas de frère précédent
    if (uh_id == ps_type->ui_id)
    {
  none:
      // Il faut retourner notre père
      if (pps_parent_type)
	*pps_parent_type = ps_parent_type;
      // Sinon on le libère (marche même si NULL)
      else
	[self getFree:ps_parent_type];

      return NULL;
    }
  }
  // On est au premier niveau
  else
  {
    // Premier type du premier niveau
    uh_id = self->uh_first_id;

    // On est le premier type au premier niveau => pas de frère précédent
    if (uh_id == ps_type->ui_id)
      goto none;
  }

  ps_child_type = [self getId:uh_id];

  // On parcourt tous les frères du niveau
  for (;;)
  {
    uh_id = ps_child_type->ui_brother_id;

    // Il n'y a plus de frère suivant !!! Ce n'est pas normal
    if (uh_id == TYPE_UNFILED)
    {
      alert_error_str("No prev for %u", uh_id);
      goto none;		// XXX
    }

    // C'est notre frère précédent
    if (uh_id == ps_type->ui_id)
    {
      // Il faut retourner notre père
      if (pps_parent_type)
	*pps_parent_type = ps_parent_type;
      // Sinon on le libère (marche même si NULL)
      else
	[self getFree:ps_parent_type];

      return ps_child_type;
    }

    [self getFree:ps_child_type];

    // Frère suivant
    ps_child_type = [self getId:uh_id];
  }
}


//
// Renvoie l'index du niveau auquel se trouve le type passé en
// paramètre de 1 (type à la racine) à N
- (UInt16)getDepth:(struct s_type*)ps_type
{
  UInt16 uh_depth, uh_parent_id;

  uh_depth = 0;

  // On remonte jusqu'à la racine
  while ((uh_parent_id = ps_type->ui_parent_id) != TYPE_UNFILED)
  {
    if (uh_depth > 0)
      [self getFree:ps_type];

    ps_type = [self getId:uh_parent_id];
    uh_depth++;
  }

  if (uh_depth > 0)
    [self getFree:ps_type];

  return uh_depth + 1;
}


//
// Renvoie la profondeur maximale SOUS le type passé en paramètre à
// partir de 0 (pas de fils), à additionner à -getDepth: pour avoir la
// profondeur maximale totale.
- (UInt16)getMaxDepth:(struct s_type*)ps_type
{
  UInt16 uh_depth, uh_max_depth, uh_id;

  uh_id = ps_type->ui_child_id;

  if (uh_id == TYPE_UNFILED)
    return 0;

  uh_depth = uh_max_depth = 1;

  ps_type = [self getId:uh_id];

  for (;;)
  {
    // Si on a un fils
    uh_id = ps_type->ui_child_id;
    if (uh_id != TYPE_UNFILED)
    {
      uh_depth++;
  next:
      [self getFree:ps_type];
      ps_type = [self getId:uh_id];
      continue;
    }

    // Sinon si on a un frère
 brother:
    uh_id = ps_type->ui_brother_id;
    if (uh_id != TYPE_UNFILED)
      goto next;

    // Sinon on remonte
    if (uh_depth > uh_max_depth)
      uh_max_depth = uh_depth;

    if (--uh_depth == 0)
    {
      [self getFree:ps_type];
      break;
    }

    uh_id = ps_type->ui_parent_id;
    [self getFree:ps_type];
    ps_type = [self getId:uh_id];
    goto brother;
  }

  return uh_max_depth;
}


//
// Renvoie true si au moins un descendant, de l'ID passé en paramètre,
// n'a pas son signe égal à lui.
- (Boolean)isBadSignInDescendantsOfId:(UInt16)uh_base_id
{
  struct s_type *ps_type;
  UInt16 uh_id, uh_sign;

  ps_type = [self getId:uh_base_id];

  uh_id = ps_type->ui_child_id;
  uh_sign = ps_type->ui_sign_depend;

  [self getFree:ps_type];

  // Pas de fils...
  if (uh_id == TYPE_UNFILED)
    return false;

  // On parcourt tous les fils
  ps_type = [self getId:uh_id];

  for (;;)
  {
    if (uh_sign != ps_type->ui_sign_depend)
    {
      [self getFree:ps_type];
      return true;
    }

    // Si on a un fils
    uh_id = ps_type->ui_child_id;
    if (uh_id != TYPE_UNFILED)
    {
  next:
      [self getFree:ps_type];
      ps_type = [self getId:uh_id];
      continue;
    }

    // Sinon si on a un frère
 brother:
    uh_id = ps_type->ui_brother_id;
    if (uh_id != TYPE_UNFILED)
      goto next;

    // Sinon on remonte
    uh_id = ps_type->ui_parent_id;
    [self getFree:ps_type];

    // On revient au point de départ...
    if (uh_id == uh_base_id)
      return false;

    ps_type = [self getId:uh_id];
    goto brother;
  }
}


//
// Renvoie true si au moins un fils, de l'ID passé en paramètre,
// correspond au signe uh_sign ET au compte.
// Si uh_sign == 0, on veut les types qui n'ont pas de signe particulier
- (Boolean)isOneChildOfId:(UInt16)uh_id forSign:(UInt16)uh_sign
	    andForAccount:(Char*)pa_account
{
  struct s_type *ps_type;

  ps_type = [self getId:uh_id];

  uh_id = ps_type->ui_child_id;
  [self getFree:ps_type];

  // Pas de fils...
  if (uh_id == TYPE_UNFILED)
    return false;

  // On parcourt tous les fils
  ps_type = [self getId:uh_id];

  for (;;)
  {
    if (((ps_type->ui_sign_depend & uh_sign) != 0
	 // Or the type has no sign (here we don't want - or + : uh_sign = 0)
	 || ps_type->ui_sign_depend == TYPE_ALL)
	// ET le compte aussi
	&& (pa_account == NULL
	    || match(ps_type->ra_only_in_account, pa_account, true)))
    {
      [self getFree:ps_type];
      return true;
    }

    // Sinon si on a un frère
    uh_id = ps_type->ui_brother_id;
    if (uh_id != TYPE_UNFILED)
    {
      [self getFree:ps_type];
      ps_type = [self getId:uh_id];
      continue;
    }

    // Sinon on quitte => rien trouvé...
    [self getFree:ps_type];

    return false;
  }
}


//
// Propage le signe ui_sign à tous les sous-types de l'ID passé en
// paramètre
- (Boolean)propagateSign:(UInt16)uh_sign overChildrenOfId:(UInt16)uh_base_id
{
  struct s_type *ps_type;
  UInt16 uh_id;
  Boolean b_change_sign = false;

  ps_type = [self getId:uh_base_id];

  uh_id = ps_type->ui_child_id;
  [self getFree:ps_type];

  // Pas de fils...
  if (uh_id == TYPE_UNFILED)
    return true;

  // On parcourt tous les fils
  ps_type = [self getId:uh_id];

  for (;;)
  {
    // On a trouvé un type qui n'a pas le bon signe !!!
    if (ps_type->ui_sign_depend != uh_sign)
      b_change_sign = true;

    // Si on a un fils
    uh_id = ps_type->ui_child_id;
    if (uh_id != TYPE_UNFILED)
    {
  next:
      if (b_change_sign)
      {
	b_change_sign = false;
	if ([self changeAttrAndFree:ps_type
		  newSign:uh_sign newFold:-1] == false)
	  return false;
      }
      else
	[self getFree:ps_type];
      ps_type = [self getId:uh_id];
      continue;
    }

    // Sinon si on a un frère
 brother:
    uh_id = ps_type->ui_brother_id;
    if (uh_id != TYPE_UNFILED)
      goto next;

    // Sinon on remonte
    uh_id = ps_type->ui_parent_id;
    if (b_change_sign)
    {
      b_change_sign = false;
      if ([self changeAttrAndFree:ps_type
		newSign:uh_sign newFold:-1] == false)
	return false;
    }
    else
      [self getFree:ps_type];

    // On revient au point de départ...
    if (uh_id == uh_base_id)
      return true;

    ps_type = [self getId:uh_id];
    goto brother;
  }
}


////////////////////////////////////////////////////////////////////////
//
// Déplacements de types
//
////////////////////////////////////////////////////////////////////////

//
// On va placer ce type juste avant son précédent frère
// Renvoie true si un déplacement a eu lieu, false sinon
- (Boolean)moveIdPrev:(UInt16)uh_id
{
  struct s_type *ps_type, *ps_prev_type, *ps_parent_type, *ps_prev_prev_type;

  ps_type = [self getId:uh_id];

  // Notre frère précédent et notre père
  ps_parent_type = NULL;
  ps_prev_type = [self getPrevBrother:ps_type parentIn:&ps_parent_type];

  // On est le premier fils
  if (ps_prev_type == NULL)
  {
    // Rien à faire
    [self getFree:ps_parent_type];
    [self getFree:ps_type];
    return false;
  }

  ps_prev_prev_type
    = [self getPrevBrother:ps_prev_type parentIn:&ps_parent_type];

  // Notre précédent frère est le premier fils
  if (ps_prev_prev_type == NULL)
  {
    if (ps_parent_type != NULL)
      [self changeRelationShipAndFree:ps_parent_type
	    newParent:-1
	    newChild:uh_id
	    newBrother:-1];
    else
      // Le type de base
      self->uh_first_id = uh_id;
  }
  else
  {
    // On n'a plus besoin du père (marche même si NULL)
    [self getFree:ps_parent_type];

    [self changeRelationShipAndFree:ps_prev_prev_type
	  newParent:-1
	  newChild:-1
	  newBrother:uh_id];
  }

  uh_id = ps_prev_type->ui_id;
  [self changeRelationShipAndFree:ps_prev_type
	newParent:-1
	newChild:-1
	newBrother:ps_type->ui_brother_id];

  [self changeRelationShipAndFree:ps_type
	newParent:-1
	newChild:-1
	newBrother:uh_id];

  return true;
}


//
// On va placer ce type juste après son prochain frère
// Renvoie true si un déplacement a eu lieu, false sinon
- (Boolean)moveIdNext:(UInt16)uh_id
{
  struct s_type *ps_type, *ps_prev_type, *ps_parent_type, *ps_next_type;

  ps_type = [self getId:uh_id];

  // Notre frère suivant
  ps_next_type = [self getId:ps_type->ui_brother_id];

  // Aucun frere ne nous suit
  if (ps_next_type == NULL)
  {
    [self getFree:ps_type];
    return false;
  }

  // Notre frère précédent et notre père
  ps_parent_type = NULL;
  ps_prev_type = [self getPrevBrother:ps_type parentIn:&ps_parent_type];

  // On est le premier fils
  if (ps_prev_type == NULL)
  {
    if (ps_parent_type != NULL)
      [self changeRelationShipAndFree:ps_parent_type
	    newParent:-1
	    newChild:ps_next_type->ui_id
	    newBrother:-1];
    else
      // Le type de base
      self->uh_first_id = ps_next_type->ui_id;
  }
  // On a un frère précédent
  else
  {
    // On n'a plus besoin du père
    [self getFree:ps_parent_type]; // Marche même si NULL

    [self changeRelationShipAndFree:ps_prev_type
	  newParent:-1
	  newChild:-1
	  newBrother:ps_next_type->ui_id];
  }

  [self changeRelationShipAndFree:ps_type
	newParent:-1
	newChild:-1
	newBrother:ps_next_type->ui_brother_id];

  [self changeRelationShipAndFree:ps_next_type
	newParent:-1
	newChild:-1
	newBrother:uh_id];

  return true;
}


//
// On va placer ce type juste après son père (il va devenir son
// prochain frère)
// Renvoie true si un déplacement a eu lieu, false sinon
- (Boolean)moveIdUp:(UInt16)uh_id
{
  struct s_type *ps_type, *ps_prev_type, *ps_parent_type;
  Int16 h_parent_child_id = -1;

  ps_type = [self getId:uh_id];

  // On n'a pas de père, on ne peut donc pas remonter
  if (ps_type->ui_parent_id == TYPE_UNFILED)
  {
    [self getFree:ps_type];
    return false;
  }

  // Avons nous un frère avant nous ?
  ps_parent_type = NULL;
  ps_prev_type = [self getPrevBrother:ps_type parentIn:&ps_parent_type];

  // En fait non, on est le premier fils de notre père
  if (ps_prev_type == NULL)
    h_parent_child_id = ps_type->ui_brother_id;
  else
  {
    [self changeRelationShipAndFree:ps_prev_type
	  newParent:-1
	  newChild:-1
	  newBrother:ps_type->ui_brother_id];
  }

  [self changeRelationShipAndFree:ps_type
	newParent:ps_parent_type->ui_parent_id
	newChild:-1
	newBrother:ps_parent_type->ui_brother_id];

  [self changeRelationShipAndFree:ps_parent_type
	newParent:-1
	newChild:h_parent_child_id
	newBrother:uh_id];

  return true;
}


//
// On va placer ce type en dernier fils de son précédent frère
// Renvoie true si un déplacement a eu lieu, false sinon
- (Boolean)moveIdDown:(UInt16)uh_id
{
  struct s_type *ps_type, *ps_prev_type, *ps_prev_last_type;
  Int16 h_prev_type_child_id = -1;

  ps_type = [self getId:uh_id];

  // Notre précédent frère ?
  ps_prev_type = [self getPrevBrother:ps_type parentIn:NULL];

  // Pas de frère précédent, on ne peut pas descendre
  if (ps_prev_type == NULL)
  {
    // none: XXX
    [self getFree:ps_type];
    return false;
  }

  // Notre frère précédent a un type incompatible avec le notre
  if ((ps_type->ui_sign_depend & ps_prev_type->ui_sign_depend)
      != ps_type->ui_sign_depend)
  {
    [self getFree:ps_prev_type];
    [self getFree:ps_type];	// XXX goto none -^
    return false;
  }

  // Le dernier fils de notre précédent frère
  ps_prev_last_type = [self getLastChild:ps_prev_type];

  // Notre frère précédent n'a pas de fils
  if (ps_prev_last_type == NULL)
    // Maintenant si !
    h_prev_type_child_id = uh_id;
  else
  {
    [self changeRelationShipAndFree:ps_prev_last_type
	  newParent:-1
	  newChild:-1
	  newBrother:uh_id];
  }

  uh_id = ps_prev_type->ui_id;
  [self changeRelationShipAndFree:ps_prev_type
	newParent:-1
	newChild:h_prev_type_child_id
	newBrother:ps_type->ui_brother_id];

  [self changeRelationShipAndFree:ps_type
	newParent:uh_id
	newChild:-1
	newBrother:TYPE_UNFILED];

  return true;
}


- (Boolean)foldId:(UInt16)uh_id
{
  struct s_type *ps_type;

  ps_type = [self getId:uh_id];

  // Pas de fils, rien à replier
  if (ps_type->ui_child_id == TYPE_UNFILED)
  {
    [self getFree:ps_type];
    return false;
  }

  // Au moins un fils
  return [self changeAttrAndFree:ps_type
	       newSign:-1 newFold:ps_type->ui_folded ^ 1];
}


//
// Dans pul_types, un bit à 1 pour le type s'il fait partie de la
// descendance de uh_parent_id
- (UInt16)setBitFamily:(UInt32*)pul_types forType:(UInt16)uh_parent_id
{
  struct s_type *ps_type;
  UInt16 uh_id, uh_num;

  // Tous les fils du type à mettre à 1 dans rul_types
  MemSet(pul_types, BYTESFORBITS(NUM_TYPES), '\0');

  ps_type = [self getId:uh_parent_id];
  BIT_SET(uh_parent_id, pul_types);

  // Le premier fils
  uh_id = ps_type->ui_child_id;
  [self getFree:ps_type];

  // Pas de fils...
  if (uh_id == TYPE_UNFILED)
    return 1;

  uh_num = 1;

  // Le premier fils
  ps_type = [self getId:uh_id];
  for (;;)
  {
    BIT_SET(ps_type->ui_id, pul_types);
    uh_num++;

    // Si on a un fils
    uh_id = ps_type->ui_child_id;
    if (uh_id != TYPE_UNFILED)
    {
  load_and_continue:
      [self getFree:ps_type];
      ps_type = [self getId:uh_id];

      continue;
    }

    // Sinon, si on a un frère
 brother:
    uh_id = ps_type->ui_brother_id;
    if (uh_id != TYPE_UNFILED)
      goto load_and_continue;

    // Sinon, si on a un père
    uh_id = ps_type->ui_parent_id;

    // On n'a pas encore fait le tour
    if (uh_id != uh_parent_id)
    {
      // On passe à son frère OU à son père...
      if (uh_id != TYPE_UNFILED)
      {
	[self getFree:ps_type];
	ps_type = [self getId:uh_id];

	goto brother;
      }
    }

    // Sinon c'est fini...
    [self getFree:ps_type];

    break;
  }

  return uh_num;
}


////////////////////////////////////////////////////////////////////////
//
// Loading types
//
////////////////////////////////////////////////////////////////////////

//
// Return NULL if the type does not exist
// Returned pointer must be freed with a call to -getFree:
- (void*)getId:(UInt16)uh_id
{
  struct s_type *ps_type;

  // "unfiled" type : fake record
  if (uh_id >= TYPE_UNFILED)
  {
    NEW_PTR(ps_type, sizeof(struct s_type) + TYPE_NAME_MAX_LEN, return NULL);

    MemSet(ps_type, sizeof(struct s_type) + TYPE_NAME_MAX_LEN, '\0');

    ps_type->ui_id = TYPE_UNFILED;
    ps_type->ui_parent_id = TYPE_UNFILED;
    ps_type->ui_child_id = TYPE_UNFILED;
    ps_type->ui_brother_id = TYPE_UNFILED;

    SysCopyStringResource(ps_type->ra_name, strTypesListUnfiled);

    // Pour être propre
    MemPtrResize(ps_type,
		 sizeof(struct s_type) + StrLen(ps_type->ra_name) + 1);
  }
  else
    ps_type = [super getId:uh_id];

  return ps_type;
}


////////////////////////////////////////////////////////////////////////
//
// Saving types
//
////////////////////////////////////////////////////////////////////////

- (Boolean)changeRelationShipAndFree:(struct s_type*)ps_type
			   newParent:(Int16)h_parent_id
			    newChild:(Int16)h_child_id
			  newBrother:(Int16)h_brother_id
{
  struct s_type s_save;
  void *ps_rec;
  UInt16 uh_index;

  s_save.ui_id = ps_type->ui_id;

  s_save.ui_parent_id = h_parent_id < 0 ? ps_type->ui_parent_id : h_parent_id;

  s_save.ui_child_id = h_child_id < 0 ? ps_type->ui_child_id : h_child_id;

  s_save.ui_brother_id
    = h_brother_id < 0 ? ps_type->ui_brother_id : h_brother_id;

  uh_index = [self getCachedIndexFromID:ps_type->ui_id];

  [self getFree:ps_type];	// On libère la zone transmise...

  if (uh_index == ITEM_FREE_ID)
  {
    // XXX
    return false;
  }
  
  ps_rec = [self recordGetAtId:uh_index];

  // On ne sauve que la partie filiation
  DmWrite(ps_rec, TYPE_RELATIONSHIP_OFFSET, &s_save, TYPE_RELATIONSHIP_SIZE);

  [self recordRelease:true];

  return true;
}


- (Boolean)changeAttrAndFree:(struct s_type*)ps_type
		     newSign:(Int16)h_sign
		     newFold:(Int16)h_fold
{
  struct s_type s_save;
  void *ps_rec;
  UInt16 uh_index;

  // On conserve la valeur des autres champs
  *(UInt32*)((Char*)&s_save + TYPE_ATTR_OFFSET)
    = *(UInt32*)((Char*)ps_type + TYPE_ATTR_OFFSET);

  if (h_sign >= 0)
    s_save.ui_sign_depend = h_sign;

  if (h_fold >= 0)
    s_save.ui_folded = h_fold;

  uh_index = [self getCachedIndexFromID:ps_type->ui_id];

  [self getFree:ps_type];	// On libère la zone transmise...

  if (uh_index == ITEM_FREE_ID)
  {
    alert_error_str("ID %u is free!", ps_type->ui_id);
    return false;
  }

  ps_rec = [self recordGetAtId:uh_index];

  // On ne sauve que la partie signe
  DmWrite(ps_rec, TYPE_ATTR_OFFSET,
	  (Char*)&s_save + TYPE_ATTR_OFFSET, TYPE_ATTR_SIZE);

  [self recordRelease:true];

  return true;
}


// If ps_type->uh_id == TYPE_UNFILED, create a new type : dans ce cas,
// seuls les champs ui_parent_id, ui_sign_depend, ra_only_in_account
// et ra_name importent. Les autres sont remplis automatiquement.
// Renvoie true, ou false si une erreur s'est produite.
- (Boolean)save:(void*)pv_type size:(UInt16)uh_size asId:(UInt16*)puh_index
	  asNew:(UInt16)uh_new
{
  struct s_type *ps_type = pv_type;

  // New record (always insert at end)
  if (uh_new)
  {
    struct s_type *ps_prev_type = NULL;

    // On s'insère juste APRÈS ce frère. On utilise le champ
    // ui_brother_id pour transmettre l'ID du type APRÈS lequel on
    // veut se mettre. Ce champ va donc être modifié pour coller à la
    // réalité.
    if (ps_type->ui_brother_id != TYPE_UNFILED)
    {
      ps_prev_type = [self getId:ps_type->ui_brother_id];
      if (ps_prev_type != NULL)
      {
	ps_type->ui_parent_id = ps_prev_type->ui_parent_id;
	ps_type->ui_brother_id = ps_prev_type->ui_brother_id;

	// On ne libère pas ps_prev_type tout de suite...
      }
      else
	ps_type->ui_brother_id = TYPE_UNFILED;
    }

    ps_type->ui_child_id = TYPE_UNFILED; // Pas de fils

    *puh_index = dmMaxRecordIndex; // Ajout toujours en fin

    // On passe le bébé à papa, il va s'occuper du nouvel ID...
    if ([super save:pv_type size:uh_size asId:puh_index asNew:uh_new] == false)
    {
      if (ps_prev_type != NULL)
	[self getFree:ps_prev_type];

      return false;
    }

    // On se place par rapport à notre frère précédent, on le modifie
    if (ps_prev_type != NULL)
    {
      [self changeRelationShipAndFree:ps_prev_type
	    newParent:-1
	    newChild:-1
	    newBrother:ps_type->ui_id];
    }
    // On a un père...
    else if (ps_type->ui_parent_id != TYPE_UNFILED)
    {
      struct s_type *ps_parent_type, *ps_last_type;

      ps_parent_type = [self getId:ps_type->ui_parent_id];

      // Le dernier fils de notre futur père
      ps_last_type = [self getLastChild:ps_parent_type];

      // Le futur père n'a pas de fils
      if (ps_last_type == NULL)
	[self changeRelationShipAndFree:ps_parent_type
	      newParent:-1
	      newChild:ps_type->ui_id
	      newBrother:-1];
      else
      {
	[self getFree:ps_parent_type];

	[self changeRelationShipAndFree:ps_last_type
	      newParent:-1
	      newChild:-1
	      newBrother:ps_type->ui_id];
      }
    }
    // On s'ajoute à la racine
    else
    {
      struct s_type *ps_last_type = [self getLastChild:NULL];

      // L'arborescence est vide
      if (ps_last_type == NULL)
	self->uh_first_id = ps_type->ui_id;
      // On a le dernier fils
      else
      {
	[self changeRelationShipAndFree:ps_last_type
	      newParent:-1
	      newChild:-1
	      newBrother:ps_type->ui_id];
      }
    }
  }
  // Record modification
  else
    return [super save:pv_type size:uh_size asId:puh_index asNew:false];

  return true;
}


- (UInt16)getIdFrom:(void*)pv_type
{
  return ((struct s_type*)pv_type)->ui_id;
}


- (void)setId:(UInt16)uh_new_id in:(void*)pv_type
{
  ((struct s_type*)pv_type)->ui_id = uh_new_id;
}


////////////////////////////////////////////////////////////////////////
//
// Deleting types
//
////////////////////////////////////////////////////////////////////////

- (Int16)deleteId:(UInt32)ui_id
{
  struct s_type *ps_type, *ps_prev_type, *ps_parent_type;
  UInt16 uh_id = ui_id & 0xffff;

  ps_type = [self getId:uh_id];

  // Pour le moment si un type a un fils on ne peut pas le supprimer
  if (ps_type->ui_child_id != TYPE_UNFILED)
  {
    [self getFree:ps_type];
    return -1;
  }

  // Notre frère précédent et notre père
  ps_parent_type = NULL;
  ps_prev_type = [self getPrevBrother:ps_type parentIn:&ps_parent_type];

  // On est le premier type du niveau
  if (ps_prev_type == NULL)
  {
    // On a un père
    if (ps_parent_type != NULL)
    {
      [self changeRelationShipAndFree:ps_parent_type
	    newParent:-1
	    newChild:ps_type->ui_brother_id
	    newBrother:-1];
    }
    // On est à la racine
    else
      self->uh_first_id = ps_type->ui_brother_id;
  }
  // On a un frère précédent
  else
  {
    // On n'a plus besoin du père
    [self getFree:ps_parent_type]; // Marche même si NULL

    [self changeRelationShipAndFree:ps_prev_type
	  newParent:-1
	  newChild:-1
	  newBrother:ps_type->ui_brother_id];
  }

  [self getFree:ps_type];

  return [super deleteId:uh_id];
}


////////////////////////////////////////////////////////////////////////
//
// Popup management
//
////////////////////////////////////////////////////////////////////////


//
// Méthode appelée dans l'écran de la liste des types pour initialiser
// la liste OU BIEN par le résultat des stats par type.
//
// Si pv_unfiled est != NULL l'entrée "Unfiled" est ajoutée en fin, et
// l'allocation de la mémoire est faite à l'aide de MamHandleNew() au
// lieu de MamPtrNew().
// 
// Ici on se fout de puh_dummy, car ce n'est pas la même méthode qui
// est appelée lorsqu'il s'agit de la contruction d'un popup
- (Char**)listBuildInfos:(void*)pv_unfiled num:(UInt16*)puh_num
		 largest:(UInt16*)puh_dummy
{
  struct __s_edit_list_type_buf *ps_buf;
  struct __s_one_type *ps_one_type;
  MemHandle vh_buf = NULL;

  // Cache entrées liste / index
  if (self->uh_first_id != TYPE_UNFILED)
  {
    struct s_type *ps_type;
    UInt16 uh_num, uh_num_records, uh_id;

    UInt32 ui_depth_glyphs = 0, ui_depth = 1;
    Boolean b_add_unfiled;

    vh_buf = NULL;

    uh_num_records = DmNumRecords(self->db); // Pire cas

    if (pv_unfiled != NULL)
    {
      b_add_unfiled = true;

      NEW_HANDLE(vh_buf,
		 sizeof(*ps_buf)
		 // + 1 pour "Unfiled" qu'on rajoute dans ce cas
		 + (uh_num_records + 1) * sizeof(*ps_one_type),
		 return NULL);

      ps_buf = MemHandleLock(vh_buf);
    }
    else
    {
      b_add_unfiled = false;

      NEW_PTR(ps_buf, sizeof(*ps_buf) + uh_num_records * sizeof(*ps_one_type),
	      return NULL);
    }

    uh_num = 0;
    ps_one_type = ps_buf->rs_list2id;

    ps_type = [self getId:self->uh_first_id];

    for (;;)
    {
      // On garde ce type
      ps_one_type->ui_depth = ui_depth;
      ps_one_type->ui_depth_glyphs
	= (ui_depth_glyphs << 2) | (ps_type->ui_brother_id == TYPE_UNFILED
				    && (ui_depth != 1 || b_add_unfiled ==false)
				    ? DEPTH_GLYPH_L
				    : DEPTH_GLYPH_T);
      ps_one_type->ui_id = ps_type->ui_id;

      uh_num++;
      ps_one_type++;

      // Si on est replié, on passe au frangin...
      if (ps_type->ui_folded)
	goto brother;

      // Si on a un fils
      uh_id = ps_type->ui_child_id;
      if (uh_id != TYPE_UNFILED)
      {
	ui_depth_glyphs <<= 2;
	ui_depth_glyphs |= (ps_type->ui_brother_id == TYPE_UNFILED
			    && (ui_depth != 1 || b_add_unfiled == false)
			    ? DEPTH_GLYPH_NONE
			    : DEPTH_GLYPH_I);
	ui_depth++;

    load_and_continue:
	[self getFree:ps_type];
	ps_type = [self getId:uh_id];

	continue;
      }

      // Sinon, si on a un frère
  brother:
      uh_id = ps_type->ui_brother_id;
      if (uh_id != TYPE_UNFILED)
	goto load_and_continue;

      // Sinon, si on a un père => on passe à son frère OU à son père...
      uh_id = ps_type->ui_parent_id;
      if (uh_id != TYPE_UNFILED)
      {
	ui_depth_glyphs >>= 2;
	ui_depth--;

	[self getFree:ps_type];
	ps_type = [self getId:uh_id];

	goto brother;
      }

      // Sinon c'est fini...
      [self getFree:ps_type];

      break;
    }

    // Cas ou on ne construit pas cette liste pour un popup, on
    // rajoute l'entrée "Unfiled" en fin...
    if (b_add_unfiled)
    {
      ps_one_type->ui_depth = 1;
      ps_one_type->ui_depth_glyphs = DEPTH_GLYPH_L;
      ps_one_type->ui_id = TYPE_UNFILED;

      uh_num++;
    }

    ps_buf->oItem = self;
    ps_buf->uh_num_rec_entries = uh_num;
    ps_buf->uh_is_right_margin = 0;

    *puh_num = uh_num;

    if (b_add_unfiled)
    {
      MemHandleUnlock(vh_buf);
      return (Char**)vh_buf;
    }

    return (Char**)ps_buf;
  }
  // Il n'y a que le type "Unfiled"
  else if (pv_unfiled != NULL)
  {
    NEW_HANDLE(vh_buf, sizeof(*ps_buf) + sizeof(*ps_one_type), return NULL);

    ps_buf = MemHandleLock(vh_buf);

    ps_one_type = ps_buf->rs_list2id;

    ps_one_type->ui_depth = 1;
    ps_one_type->ui_depth_glyphs = DEPTH_GLYPH_L;
    ps_one_type->ui_id = TYPE_UNFILED;

    ps_buf->oItem = self;
    ps_buf->uh_num_rec_entries = 1;
    ps_buf->uh_is_right_margin = 0;

    *puh_num = 1;

    MemHandleUnlock(vh_buf);

    return (Char**)vh_buf;
  }

  // Aucun type n'est présent
  *puh_num = 0;
  return NULL;
}



struct __s_one_popup_type
{
  UInt16 uh_id:8;
#define TYPE_SUBTYPE_NONE	0 // Pas de sous-type
#define TYPE_SUBTYPE_ENABLED	1 // Il y a au moins un sous-types
#define TYPE_SUBTYPE_DISABLED	2 // Idem, mais pas accessible dans ce contexte
  UInt16 uh_submenu:2;
  UInt16 uh_sign:1;		// Dessin du signe...
};

struct __s_popup_list_type_buf
{
  __STRUCT_DBITEM_LIST_BUF(Type);
  Char ra_first_entry[TYPE_NAME_MAX_LEN];
  Char ra_edit_entry[TYPE_NAME_MAX_LEN];
  union				// Les entrées "Unfiled" et "up level"
  {				// sont incompatibles
    // "Unfiled" entry
    Char ra_unfiled_entry[TYPE_NAME_MAX_LEN];
    // or "up level" one...
    Char *pa_uplevel;		// MemPtrFree à faire si EDIT_UPLEVEL_ENTRY
  } u;
#define EDIT_ANY_ENTRY		0x0001
#define EDIT_UNFILED_ENTRY	0x0002
#define EDIT_EDIT_ENTRY		0x0004
#define EDIT_UPLEVEL_ENTRY	0x0008
  UInt16 uh_entries;
  struct __s_one_popup_type rs_list2id[0];
};


//
// Méthode appelée par les méthodes -popupList...
// Construit une liste correspondant au niveau qui contient l'ID passé
// en paramètre. Renvoie l'ID dans ce même paramètre au cas où l'ID
// passé n'existerait pas.
// Des flags peuvent être passé via uh_id, ce sont les mêmes que pour
// -popupListInit:Id:forAccount:
- (struct __s_popup_list_type_buf*)listBuildForAccount:(Char*)pa_account
						 selId:(UInt16*)puh_id
						   num:(UInt16*)puh_num
					       largest:(UInt16*)puh_largest
{
  struct __s_popup_list_type_buf *ps_buf;
  struct s_type *ps_type, *ps_first_type;
  UInt16 uh_id, uh_flags;
  UInt16 uh_num, uh_width, uh_largest, uh_submenu_width;

  uh_id = uh_flags = *puh_id;
  uh_id &= ~TYPE_FLAGS_MASK;

  //  On recherche le premier type du niveau
  if (uh_id >= TYPE_UNFILED)
    ps_type = NULL;
  else
    ps_type = [self getId:uh_id];

  ps_first_type = [self getFirstBrother:ps_type];

  // On n'a pas trouvé de type correspondant à cet ID
  if (ps_type == NULL)
    *puh_id = (uh_id > TYPE_UNFILED) ? uh_id : TYPE_UNFILED;
  else
  {
    *puh_id = ps_type->ui_id;
    [self getFree:ps_type];
  }

  uh_num = 0;

  // Si il y a au moins un type...
  if (ps_first_type != NULL)
  {
    // Calcul grossier (tient pas compte du signe ni du compte) du
    // nombre de types destiné à faire l'allocation...
    uh_num++;

    uh_id = ps_first_type->ui_brother_id;
    while (uh_id != TYPE_UNFILED)
    {
      ps_type = [self getId:uh_id];
      uh_id = ps_type->ui_brother_id;
      [self getFree:ps_type];

      uh_num++;
    }
  }

  // Allocation
  NEW_PTR(ps_buf, sizeof(*ps_buf) + uh_num * sizeof(ps_buf->rs_list2id[0]),
	  ({ [self getFree:ps_first_type]; return NULL; }));

  uh_largest = 0;

  // Largeur du caractère <- ou -> ou -> grisé (c'est toujours la même)
  FntSetFont(symbol11Font);
  uh_submenu_width = FntCharWidth(symbol11RightArrow);
  FntSetFont(stdFont);

  // Re-parcourt du niveau, mais plus précis cette fois
  if (ps_first_type != NULL)
  {
    struct __s_one_popup_type *ps_one_type;
    UInt16 uh_parent_id = ps_first_type->ui_parent_id;
    UInt16 ruh_sign_width[2];
    UInt16 uh_sign;

    uh_sign = (uh_flags >> TYPE_FLAG_SIGN_SHIFT);

    // N'importe quel signe
    if (uh_sign == 0)
      uh_sign = TYPE_ALL;
    // Seulement les types qui n'ont pas de signe
    else if (uh_sign == (TYPE_FLAG_SIGN_NONE >> TYPE_FLAG_SIGN_SHIFT))
      uh_sign = 0;

    // Largeur des caractères qu'on va retrouver souvent
    ruh_sign_width[0] = FntCharWidth('-');
    ruh_sign_width[1] = FntCharWidth('+');

    ps_one_type = ps_buf->rs_list2id;

    ps_type = ps_first_type;
    goto first_step;
    //
    do
    {
      ps_type = [self getId:uh_id];
  first_step:

      // The sign matches
      if (((ps_type->ui_sign_depend & uh_sign) != 0
	   // Or the type has no sign (here we don't want - or + : uh_sign = 0)
	   || ps_type->ui_sign_depend == TYPE_ALL)
	  // AND this type matches the account (if any)
	  && (pa_account == NULL
	      || match(ps_type->ra_only_in_account, pa_account, true)))
      {
	// Type name
	uh_width = FntCharsWidth(ps_type->ra_name, StrLen(ps_type->ra_name));

	// Init item...
	*(UInt16*)ps_one_type = 0;

	// Sign, only when popup with all signs and type with only one
	if (uh_sign == TYPE_ALL && ps_type->ui_sign_depend != TYPE_ALL)
	{
	  uh_width
	    += MINIMAL_SPACE + ruh_sign_width[ps_type->ui_sign_depend - 1];
	  ps_one_type->uh_sign = 1;
	}

	// Sub-menu
	// On a un fils
	if (ps_type->ui_child_id != TYPE_UNFILED)
	{
	  if ([self isOneChildOfId:ps_type->ui_id
		    forSign:uh_sign
		    andForAccount:pa_account])
	    ps_one_type->uh_submenu = TYPE_SUBTYPE_ENABLED;
	  else
	    ps_one_type->uh_submenu = TYPE_SUBTYPE_DISABLED;

	  uh_width += MINIMAL_SPACE + uh_submenu_width;
	}

	if (uh_width > uh_largest)
	  uh_largest = uh_width;

	ps_one_type->uh_id = ps_type->ui_id;

	ps_one_type++;
      }
      else
	uh_num--;		// Un item de moins

      uh_id = ps_type->ui_brother_id;
      if (ps_type != ps_first_type)
	[self getFree:ps_type];
    }
    while (uh_id != TYPE_UNFILED);

    // Calcul de la largeur du nom du père...
    uh_parent_id++;		// XXX
  }

  ps_buf->oItem = self;
  ps_buf->uh_num_rec_entries = uh_num;
  ps_buf->uh_is_right_margin = 0;
  ps_buf->uh_is_scroll_list = 0;

  // Additionnal entries

  // Entrée "Unfiled" (racine) OU BIEN entrée `up level'
  uh_num++;

  // Si aucun type, on est à la racine...
  if (ps_first_type == NULL)
    uh_id = TYPE_UNFILED;
  // Notre père à tous (plus besoin de notre premier frère)
  else
  {
    uh_id = ps_first_type->ui_parent_id;
    [self getFree:ps_first_type];
  }

  // On est à la racine
  if (uh_id == TYPE_UNFILED)
  {
    // Entrée "Unfiled"
    load_and_fit(strTypesListUnfiled, ps_buf->u.ra_unfiled_entry, &uh_largest);
    ps_buf->uh_entries = EDIT_UNFILED_ENTRY;

    // Première entrée "Indifférent"
    if (uh_flags & TYPE_ADD_ANY_LINE)
    {
      load_and_fit(strAnyList, ps_buf->ra_first_entry, &uh_largest);
      uh_num++;
      ps_buf->uh_entries |= EDIT_ANY_ENTRY;
    }
  }
  // Vers le niveau supérieur
  else
  {
    UInt16 uh_len;

    WinGetDisplayExtent(&uh_width, &uh_len); // uh_len dummy

    // On tronque toujours comme s'il y avait pas de flèche de scroll
    // à droite, car il n'y en aura jamais sur cette ligne (la première)
    ps_buf->u.pa_uplevel
      = [self fullNameOfId:uh_id len:&uh_len
	      truncatedTo:(uh_width
			   - LIST_BORDERS_NO_SCROLL - uh_submenu_width - 1)];
    // Flèche gauche + 1 + texte
    uh_width = uh_submenu_width
      + 1 + FntCharsWidth(ps_buf->u.pa_uplevel, uh_len);

    if (uh_width > uh_largest)
      uh_largest = uh_width;

    ps_buf->uh_entries = EDIT_UPLEVEL_ENTRY;
  }

  // Entrée "Éditer"
  if (uh_flags & TYPE_ADD_EDIT_LINE)
  {
    load_and_fit(strEditList, ps_buf->ra_edit_entry, &uh_largest);
    uh_num++;
    ps_buf->uh_entries |= EDIT_EDIT_ENTRY;
  }

  *puh_num = uh_num;

  if (puh_largest)
    *puh_largest = uh_largest;

  return ps_buf;
}


static UInt16 __fill_type_macro(struct s_type *ps_type,
				Char *pa_macro, Boolean b_account)
{
   UInt16 uh_len = 0;

   // Sign dependence
   switch (ps_type->ui_sign_depend)
   {
   case TYPE_DEBIT:  *pa_macro++ = '-'; uh_len++; break;
   case TYPE_CREDIT: *pa_macro++ = '+'; uh_len++; break;
   }

   // Target account ONLY in edition list
   if (b_account && ps_type->ra_only_in_account[0] != '\0')
   {
     UInt16 uh_account_len;

     // Add a space after the sign, if any
     if (uh_len > 0)
     {
       *pa_macro++ = ' ';
       uh_len++;
     }

     uh_account_len = StrLen(ps_type->ra_only_in_account);

     MemMove(pa_macro, ps_type->ra_only_in_account, uh_account_len);
     pa_macro += uh_account_len;

     uh_len += uh_account_len;
   }

   return uh_len;
}


void list_draw_glyph(UInt16 uh_x, UInt16 uh_y, UInt16 uh_h, UInt16 uh_flags)
{  
  UInt16 uh_y2 = uh_y + uh_h - 1;
  UInt16 uh_glyph = (uh_flags & DEPTH_GLYPH_MASK);

  // |
  switch (uh_glyph)
  {
  case DEPTH_GLYPH_I:
    uh_x += 2;
    WinDrawLine(uh_x, uh_y, uh_x, uh_y2);
  case DEPTH_GLYPH_NONE:
  break;

  default:
  {
    UInt16 uh_ymiddle = uh_y + FntBaseLine() / 2 + 1;

    // Il y a un fils...
    if (uh_flags & DRAW_GLYPH_CHILD)
    {
      RectangleType s_rect = { { uh_x + 1, uh_ymiddle - 1 }, { 3, 3 } };

      if (uh_glyph == DEPTH_GLYPH_T)
	WinDrawLine(uh_x + 2, uh_y2, uh_x + 2, uh_ymiddle + 3);

      WinDrawRectangleFrame(rectangleFrame, &s_rect);

      WinDrawLine(uh_x + 2, uh_y, uh_x + 2, uh_ymiddle - 3);
      WinDrawLine(uh_x + 5, uh_ymiddle, uh_x + 6, uh_ymiddle);

      // On est replié
      if (uh_flags & DRAW_GLYPH_FOLDED)
      {
	WinDrawLine(uh_x + 1, uh_ymiddle, uh_x + 3, uh_ymiddle);
	uh_x += 2;
	WinDrawLine(uh_x, uh_ymiddle - 1, uh_x, uh_ymiddle + 1);
      }
      // On est déplié
      else
      {
	uh_x += 2;
	WinDrawLine(uh_x, uh_ymiddle, uh_x, uh_ymiddle);
      }
    }
    // Pas de fils
    else
    {
      // -
      WinDrawLine(uh_x + 3, uh_ymiddle, uh_x + 6, uh_ymiddle);

      if (uh_glyph == DEPTH_GLYPH_L)
	uh_y2 = uh_ymiddle;

      // |
      uh_x += 2;
      WinDrawLine(uh_x, uh_y, uh_x, uh_y2);
    }
    break;
  }
  }
}


//
// Pour chaque ligne dans l'écran de la liste des types
static void __list_edit_types_draw(Int16 h_line, RectangleType *prec_bounds,
				   Char **ppa_lines)
{
  struct __s_edit_list_type_buf *ps_buf;
  struct __s_one_type *ps_one_type;
  struct s_type *ps_type;

  Char *pa_type;
  UInt16 uh_macro_len, uh_type_len;

  UInt16 uh_macro_width = 0, uh_macro_real_width = 0;
  UInt16 uh_right_margin, uh_max_width, uh_glyphs_width;

  UInt16 uh_x, uh_y;
  Int16 h_depth;

  ps_buf = (struct __s_edit_list_type_buf*)ppa_lines;

  // Pour dérouler les types...
  ps_buf->uh_x_pos = prec_bounds->topLeft.x;

  ps_one_type = &ps_buf->rs_list2id[h_line];

  // Chargement du type
  ps_type = [ps_buf->oItem getId:ps_one_type->ui_id];

  // Avec le nom du compte si présent
  uh_macro_len = __fill_type_macro(ps_type, ps_buf->ra_macro, true);

  // Does this list contain scroll arrows?
  uh_right_margin = ps_buf->uh_is_right_margin
    ? LIST_RIGHT_MARGIN : LIST_RIGHT_MARGIN_NOSCROLL;

  // Room required by the macro
  if (uh_macro_len > 0)
  {
    // Place que la macro va prendre
    uh_macro_real_width
      = FntCharsWidth(ps_buf->ra_macro, uh_macro_len) + MINIMAL_SPACE;

    // Place maximum allouée pour la macro (tier de la largeur hors marges)
    // La marge de gauche est déjà décomptée par l'OS
    uh_max_width = (prec_bounds->extent.x - uh_right_margin) / 3;

    uh_macro_width = (uh_macro_real_width > uh_max_width)
      ? uh_max_width : uh_macro_real_width;
  }

  // Largeur maximale pour la description sans la macro
  uh_max_width = prec_bounds->extent.x - uh_macro_width - uh_right_margin;

  // Place prise par le dessin de l'arborescence (5 pixels par élément)
  h_depth = ps_one_type->ui_depth;
  uh_glyphs_width = h_depth * GLYPH_WIDTH;
  uh_max_width -= uh_glyphs_width;

  pa_type = ps_type->ra_name;
  uh_type_len = StrLen(pa_type);

  // Dessin de l'arborescence juste avant le nom...
  uh_x = prec_bounds->topLeft.x;
  uh_y = prec_bounds->topLeft.y;
  if (h_depth > 0)
  {
    h_depth--;
    h_depth *= 2;

    do
    {
      // Il faut passer le fait que le type a un fils ou non
      list_draw_glyph(uh_x, uh_y, prec_bounds->extent.y,
		      ((ps_one_type->ui_depth_glyphs >> h_depth)
		       & DEPTH_GLYPH_MASK)
		      // Type replié
		      | (ps_type->ui_folded << 15)
		      // Type avec fils
		      | ((ps_type->ui_child_id != TYPE_UNFILED) << 14));

      h_depth -= 2;
      uh_x += GLYPH_WIDTH;
    }
    while (h_depth >= 0);

    uh_x++;		// Jonction avec le texte
  }

  h_depth = prepare_truncating(pa_type, &uh_type_len, uh_max_width);
  WinDrawTruncatedChars(pa_type, uh_type_len, uh_x, uh_y, h_depth);
  if (h_depth < 0)
    h_depth = FntCharsWidth(pa_type, uh_type_len);

  // Place restante pour la macro
  uh_max_width = prec_bounds->extent.x - uh_right_margin
    - MINIMAL_SPACE - (h_depth + uh_glyphs_width);

  // Macro
  if (uh_macro_len > 0)
  {
    uh_macro_real_width -= MINIMAL_SPACE;

    pa_type = ps_buf->ra_macro;
    h_depth = -1;

    // The macro is too large
    if (uh_macro_real_width > uh_max_width)
    {
      h_depth = prepare_truncating(pa_type, &uh_macro_len, uh_max_width);
      uh_macro_real_width = h_depth; // Normalement, ici jamais < 0
    }

    uh_x = prec_bounds->topLeft.x + prec_bounds->extent.x
      - uh_right_margin
      - uh_macro_real_width
      - 1;		       // Pour compenser le souligné trop long

    WinDrawTruncatedChars(pa_type, uh_macro_len, uh_x, uh_y, h_depth);

    uh_y += FntBaseLine() + 1;

    WinDrawGrayLine(uh_x, uh_y, uh_x + uh_macro_real_width - 1, uh_y);
  }

  [ps_buf->oItem getFree:ps_type];
}


//
// Pour chaque ligne dans un popup des types
static void __list_popup_types_draw(Int16 h_line, RectangleType *prec_bounds,
				    Char **ppa_lines)
{
  struct __s_popup_list_type_buf *ps_buf;
  struct __s_one_popup_type *ps_one_type;
  struct s_type *ps_type;

  Char *pa_type;
  UInt16 uh_type_len;
  UInt16 uh_type_max_width;

  // Le signe du type s'il y en a un et qu'il faut l'afficher
  Char a_sign = 0;
  UInt16 uh_sign_width = 0;

  // Le sigle du sous menu, s'il y en a un
  Char a_submenu = 0;
  UInt16 uh_submenu_width = 0;

  UInt16 uh_x, uh_y;
  Int16 h_upperline = 0;

  uh_x = prec_bounds->topLeft.x;
  uh_y = prec_bounds->topLeft.y;


  ps_buf = (struct __s_popup_list_type_buf*)ppa_lines;

  // Ce popup a une première entrée avant les vrais types
  if (ps_buf->uh_entries & (EDIT_UPLEVEL_ENTRY | EDIT_ANY_ENTRY))
  {
    // On doit justement afficher cette première ligne
    if (h_line == 0)
    {
      // Entrée "Any"
      if (ps_buf->uh_entries & EDIT_ANY_ENTRY)
      {
	pa_type = ps_buf->ra_first_entry;
	h_upperline = -1;	// Séparateur en dessous
      }
      // Entrée "Up level..."
      else
      {
	// Il faut dessiner l'icône de retour
	a_submenu = symbol11LeftArrow;

	FntSetFont(symbol11Font);

	// -1 car la première colonne du caractère est vide de pixel
	WinDrawChars(&a_submenu, 1, uh_x - 1, uh_y);

	// On va décaler le reste : + 1 avec la colonne vide ça fera 2
	uh_x += FntCharWidth(a_submenu) + 1;

	FntSetFont(stdFont);

	pa_type = ps_buf->u.pa_uplevel;
      }

      goto draw_spec_line;
    }

    // Sinon on déc. l'index pour coller au tableau de correspondance idx->id
    h_line--;
  }

  // L'entrée est au delà des types
  if (h_line >= ps_buf->uh_num_rec_entries)
  {
    if (h_line == ps_buf->uh_num_rec_entries
	&& (ps_buf->uh_entries & EDIT_UNFILED_ENTRY))
      // Entrée "Unfiled"
      pa_type = ps_buf->u.ra_unfiled_entry;
    else
    {
      // Entrée "Édit..."
      pa_type = ps_buf->ra_edit_entry;
      h_upperline = 1;		// Séparateur au dessus
    }

 draw_spec_line:
    // On ne tronque pas ces lignes, elles contiennent forcemment
    WinDrawChars(pa_type, StrLen(pa_type), uh_x, uh_y);

    // Un séparateur à dessiner
    if (h_upperline)
      list_line_draw_line(prec_bounds, h_upperline);

    return;
  }

  // On va afficher un type...
  ps_one_type = &ps_buf->rs_list2id[h_line];

  // Chargement du type
  ps_type = [ps_buf->oItem getId:ps_one_type->uh_id];

  uh_type_max_width = prec_bounds->extent.x
    // Does this list contain scroll arrows?
    - (ps_buf->uh_is_right_margin
       ? LIST_RIGHT_MARGIN : LIST_RIGHT_MARGIN_NOSCROLL);

  // Y a-t'il un sous menu à suivre (au moins à afficher)
  if (ps_one_type->uh_submenu)
  {
    if (ps_one_type->uh_submenu == TYPE_SUBTYPE_ENABLED)
      a_submenu = symbol11RightArrow; // ->
    else
      a_submenu = symbol11RightArrowDisabled; // -> grisé

    FntSetFont(symbol11Font);
    uh_submenu_width = FntCharWidth(a_submenu);

    // On affiche de suite
    WinDrawChars(&a_submenu, 1,
		 uh_x + uh_type_max_width - uh_submenu_width, uh_y);

    FntSetFont(stdFont);

    uh_type_max_width -= uh_submenu_width + MINIMAL_SPACE;
  }

  // On affiche +/- juste après le nom du type s'il le faut
  if (ps_one_type->uh_sign)
  {
    a_sign = (ps_type->ui_sign_depend == TYPE_CREDIT) ? '+' : '-';
    uh_sign_width = FntCharWidth(a_sign);

    uh_type_max_width -= uh_sign_width + MINIMAL_SPACE;
  }

  // Le type
  pa_type = ps_type->ra_name;
  uh_type_len = StrLen(pa_type);

  {
    Int16 h_width;

    h_width = prepare_truncating(pa_type, &uh_type_len, uh_type_max_width);

    WinDrawTruncatedChars(pa_type, uh_type_len, uh_x, uh_y, h_width);

    // On dessine le signe si besoin...
    if (a_sign)
    {
      if (h_width < 0)
	h_width = FntCharsWidth(pa_type, uh_type_len);

      uh_x += MINIMAL_SPACE + h_width;

      WinDrawChars(&a_sign, 1, uh_x, uh_y);

      uh_y += FntBaseLine() + 1;

      WinDrawGrayLine(uh_x, uh_y, uh_x + uh_sign_width - 1, uh_y);
    }
  }

  [ps_buf->oItem getFree:ps_type];
}


- (ListDrawDataFuncPtr)listDrawFunction
{
  return __list_edit_types_draw;
}


- (UInt16)dbMaxEntries
{
  return NUM_TYPES - 1;		// Skip "Unfiled" type
}


////////////////////////////////////////////////////////////////////////
//
// Type name manipulation
//
////////////////////////////////////////////////////////////////////////

#define TYPE_SEPARATOR   '/'

//
// Renvoie le nom du type alloué avec MemPtrNew
// NULL si l'ID n'existe pas...
- (Char*)fullNameOfId:(UInt16)uh_id len:(UInt16*)puh_len
{
  return [self fullNameOfId:uh_id len:puh_len truncatedTo:32767];
}


//
// Get type full path name truncated to fit in uh_max_width
// The returned pointer must be freed with a call to MemPtrFree
// puh_len can be NULL
// **** uh_max_width must be >= 27 ****
- (Char*)fullNameOfId:(UInt16)uh_id len:(UInt16*)puh_len
	  truncatedTo:(UInt16)uh_max_width
{
  struct s_type_def
  {
    struct s_type *ps_type;
    UInt16 uh_len:8;
    UInt16 uh_truncate:8; // 1=... 2&+= more than one type here (big hole)
    UInt16 uh_width;
  } rs_types_def[TYPE_MAX_DEPTH], *ps_type_def;	// XXX MemPtrNew plutôt ?

  struct s_type *ps_type;
  Char *pa_name;

  UInt16 uh_num_types;
  UInt16 uh_total_width, uh_total_len, uh_slash_width, uh_ell_width;
  Char a_ell;

  if (uh_id == TYPE_UNFILED)
  {
    NEW_PTR(pa_name, TYPE_NAME_MAX_LEN, return NULL);

    SysCopyStringResource(pa_name, strTypesListUnfiled);

    uh_total_len = StrLen(pa_name);
    truncate_name(pa_name, &uh_total_len, uh_max_width, pa_name);

    if (puh_len != NULL)
      *puh_len = uh_total_len;

    return pa_name;
  }

  uh_slash_width = FntCharWidth(TYPE_SEPARATOR);

  a_ell = ellipsis(&uh_ell_width);


  ////////////////////////////////////////////////////////////////////////
  //
  // Step 1 - array init - AAA/BBB/CCC/DDD/ROOT

  uh_total_width = - uh_slash_width;
  uh_total_len = 0;		// Pas -1 car ici on compte le \0 de fin
  uh_num_types = 0;
  ps_type_def = rs_types_def;
  do
  {
    ps_type = [self getId:uh_id];

    ps_type_def->ps_type = ps_type;
    ps_type_def->uh_len = StrLen(ps_type->ra_name);
    ps_type_def->uh_truncate = 0;
    ps_type_def->uh_width
      = FntCharsWidth(ps_type->ra_name, ps_type_def->uh_len);

    uh_total_width += ps_type_def->uh_width + uh_slash_width;
    uh_total_len += ps_type_def->uh_len + 1; // + 1 pour le '/' ou le \0

    uh_num_types++;
    ps_type_def++;

    uh_id = ps_type->ui_parent_id;
  }
  while (uh_id != TYPE_UNFILED);

  if (uh_total_width <= uh_max_width)
    goto allocation;

  if (uh_num_types <= 2)
  {
    // Un seul type dans l'arborescence...
    if (uh_num_types == 1)
    {
      uh_total_len = rs_types_def[0].uh_len;

      NEW_PTR(pa_name, uh_total_len + 1,
	      ({ [self getFree:rs_types_def[0].ps_type]; return NULL; }));

      MemMove(pa_name, rs_types_def[0].ps_type->ra_name, uh_total_len);

      [self getFree:rs_types_def[0].ps_type];

      truncate_name(pa_name, &uh_total_len, uh_max_width, pa_name);

      if (puh_len != NULL)
	*puh_len = uh_total_len;

      return pa_name;
    }

    // Deux types dans l'arborescence
    goto ultimate_reduction_2;
  }

  ////////////////////////////////////////////////////////////////////////
  //
  // Step 2 - middle reduction => AAA/B.../C.../D.../ROOT

  {
    UInt16 uh_middle, uh_largest, uh_char_width;
    Int16 h_inc;
    WChar wa_prev;

    // On recherche le nom le plus long
    uh_largest = 0;
    ps_type_def = &rs_types_def[1];
    for (h_inc = uh_num_types - 2; h_inc-- > 0; ps_type_def++)
      if (ps_type_def->uh_len > uh_largest)
	uh_largest = ps_type_def->uh_len;

    do
    {
      uh_middle = uh_num_types / 2;	// 5 => 2 et 6 => 3
      h_inc = 0;

      do
      {
	uh_middle += h_inc;

	ps_type_def = &rs_types_def[uh_middle];

	// Le label doit être tronqué
	if (ps_type_def->uh_len >= uh_largest)
	{
	  uh_char_width = TxtGlueGetPreviousChar(ps_type_def->ps_type->ra_name,
						 ps_type_def->uh_len,
						 &wa_prev);
	  ps_type_def->uh_len -= uh_char_width;
	  uh_total_len -= uh_char_width;

	  // Il n'y a pas encore de '...'
	  if (ps_type_def->uh_truncate == 0)
	  {
	    uh_total_len++;
	    uh_total_width += uh_ell_width;
	    ps_type_def->uh_truncate = 1;
	  }

	  uh_total_width -= ps_type_def->uh_width;

	  if (ps_type_def->uh_len == 0) // Le label n'est plus du tout visible
	    [self getFree:ps_type_def->ps_type];
	  else
	  {
	    // Nouvelle largeur
	    ps_type_def->uh_width= FntCharsWidth(ps_type_def->ps_type->ra_name,
						 ps_type_def->uh_len);
	    uh_total_width += ps_type_def->uh_width;
	  }

	  if (uh_total_width <= uh_max_width)
	    goto allocation;
	}

	if (h_inc == 0)
	{
	  // 4/3/2/1/ROOT = 5 (nombre de composants impair)
	  if (uh_num_types & 1)
	    h_inc = 1;
	  // 5/4/3/2/1/ROOT = 6 (nombre de composants pair)
	  else
	    h_inc = -1;
	}
	else
	{
	  h_inc = - h_inc;

	  if (h_inc > 0)
	    h_inc++;
	  else
	    h_inc--;
	}
      }
      while (uh_middle != 1);
    }
    while (--uh_largest > 0);
  }

  // Ici on a : AAA/.../.../.../ROOT

  ////////////////////////////////////////////////////////////////////////
  //
  // Step 3 - ultimate reduction 1 => AAA/.../ROOT

  if (uh_num_types > 3)
  {
    UInt16 uh_num_to_del;

    MemMove(&rs_types_def[2], &rs_types_def[uh_num_types - 1],
	    sizeof(rs_types_def[0]));

    // On ôte les '...' et les '/' des largeurs
    uh_num_to_del = uh_num_types - 3;

    uh_total_len -= uh_num_to_del * 2; // '...' et '/'
    uh_total_width -= uh_num_to_del * (uh_ell_width + uh_slash_width);

    uh_num_types = 3;

    // Big hole (more than one type here)
    rs_types_def[1].uh_truncate += uh_num_to_del;

    uh_total_len += 2;		// To hold 2 more characters for "big hole"
    uh_total_width -= uh_ell_width;
    uh_total_width += 3 * FntCharWidth(':'); // Big holes are denoted by ':::'

    if (uh_total_width <= uh_max_width)
      goto allocation;
  }

  ////////////////////////////////////////////////////////////////////////
  //
  // Step 4 - ultimate reduction 2 => A.../.../ROOT  |  A.../ROOT (if 2 items)
  //				      .../.../R...   |  .../R... (if 2 items)
 ultimate_reduction_2:

  // Ici on a : AAA/.../ROOT OU BIEN AAA/ROOT
  {
    UInt16 uh_reduce_idx, uh_full_idx, uh_tmp_len;

    uh_full_idx = 0;
    uh_reduce_idx = uh_num_types - 1;

    // Est-ce qu'on peut se contenter de réduire l'entête (dernier élément) ?
    if (uh_total_width - rs_types_def[uh_reduce_idx].uh_width + uh_ell_width
	<= uh_max_width)
    {
      // Il faudra ignorer la largeur du dernier puisqu'il reste entier
      uh_max_width -= rs_types_def[uh_full_idx].uh_width;
    }
    // On réduit direct le premier élément (qui est en fait le
    // dernier), puis on s'attaque au dernier (qui est en fait le
    // premier élément)
    else
    {
      uh_full_idx = uh_reduce_idx;
      uh_reduce_idx = 0;

      [self getFree:rs_types_def[uh_full_idx].ps_type];

      // Retrait type + ajout '...'
      uh_total_len -= rs_types_def[uh_full_idx].uh_len - 1;
      uh_total_width -= rs_types_def[uh_full_idx].uh_width - uh_ell_width;

      rs_types_def[uh_full_idx].uh_len = 0;
      rs_types_def[uh_full_idx].uh_truncate = 1;

      // Il faudra ignorer la largeur du premier qui est '...'
      uh_max_width -= uh_ell_width;
    }

    // On va voir si on contient dans la largeur restante
    uh_max_width -=
      (uh_num_types - 1) * uh_slash_width	// Largeur des slashs
      + (uh_num_types - 2) * uh_ell_width;	// Largeur de '...' si présent

    uh_tmp_len = rs_types_def[uh_reduce_idx].uh_len;
    uh_total_len -= uh_tmp_len;
    pa_name = truncate_name(rs_types_def[uh_reduce_idx].ps_type->ra_name,
			    &uh_tmp_len, uh_max_width, NULL);

    // Le nom n'est pas tronqué... bizarre, mais bon...
    if (pa_name != NULL)
      rs_types_def[uh_reduce_idx].uh_len = uh_tmp_len;
    else
    {
      if ((rs_types_def[uh_reduce_idx].uh_len = uh_tmp_len - 1) == 0)
	[self getFree:rs_types_def[uh_reduce_idx].ps_type];

      rs_types_def[uh_reduce_idx].uh_truncate = 1;
    }
    uh_total_len += uh_tmp_len;
  }

  ////////////////////////////////////////////////////////////////////////
  //
  // Step 4 - allocation
 allocation:
  
  {
    UInt16 uh_index;
    Char *pa_cur;

    NEW_PTR(pa_name, uh_total_len, goto error);

    pa_cur = pa_name;

    uh_index = uh_num_types;
    for (ps_type_def = &rs_types_def[uh_num_types - 1];
	 uh_index > 0; uh_index--, ps_type_def--)
    {
      if (ps_type_def->uh_len > 0)
      {
	MemMove(pa_cur, ps_type_def->ps_type->ra_name, ps_type_def->uh_len);
	pa_cur += ps_type_def->uh_len;

	[self getFree:ps_type_def->ps_type];
      }

      if (ps_type_def->uh_truncate > 0)
      {
	// ...
	if (ps_type_def->uh_truncate == 1)
	  *pa_cur++ = a_ell;
	// Big hole : more than one type is here...
	else
	{
	  *pa_cur++ = ':';
	  *pa_cur++ = ':';
	  *pa_cur++ = ':';
	}
      }

      *pa_cur++ = TYPE_SEPARATOR;
    }

    pa_cur[-1] = '\0';		// On remplace le dernier '/'

    if (puh_len != NULL)
      *puh_len = uh_total_len - 1;

    return pa_name;

 error:

    ps_type_def = rs_types_def;
    for (uh_index = 0; uh_index < uh_num_types; uh_index++, ps_type_def++)
      if (ps_type_def->uh_len > 0)
	[self getFree:ps_type_def->ps_type];

    return NULL;
  }
}


////////////////////////////////////////////////////////////////////////
//
// Type popup list
//
////////////////////////////////////////////////////////////////////////

struct __s_type_popup_list
{
  FormType *pt_form;
  ListType *pt_list;
  struct __s_popup_list_type_buf *ps_buf;
  Char ra_account[dmCategoryLength]; // Le popup dépend de ce compte
  Char *pa_popup_label;		// MemPtrFree à faire
  UInt16 uh_list_idx;		// Index de la liste dans le formulaire
  UInt16 uh_popup_idx;		// Index du popup dans le formulaire
  UInt16 uh_popup_width;	// Largeur initiale (et maximale) du popup
  UInt16 uh_id;			// ID actuellement sélectionné
  UInt16 uh_flags;		// Redondant avec ps_buf->uh_entries, mais bon
  UInt16 uh_num;		// Nombre total d'entrées
  UInt16 uh_max_width;		// Largeur maxi de l'intérieur d'une cellule
  PointType s_list_pos;		// Position initiale de la liste
};


//
// Alloue la structure opaque dont on va se servir par la suite
// Construction de la liste en fonction de ID (+ flags) et du compte
// Le popup utilisant la liste est (uh_list_id - 1)
// N'affiche rien
- (VoidHand)popupListInit:(UInt16)uh_list_id
		     form:(FormType*)pt_form
		       Id:(UInt16)uh_id
	       forAccount:(Char*)pa_account
{
  VoidHand pv_list;
  struct __s_type_popup_list *ps_list;
  RectangleType s_rect;
  UInt16 uh_dummy;

  NEW_HANDLE(pv_list, sizeof(struct __s_type_popup_list), return NULL);

  ps_list = MemHandleLock(pv_list);

  // Largeur maxi des entrées une fois pour toutes
  WinGetDisplayExtent(&ps_list->uh_max_width, &uh_dummy);
  ps_list->uh_max_width -= LIST_EXTERNAL_BORDERS;

  ps_list->pt_form = pt_form;

  ps_list->uh_list_idx = FrmGetObjectIndex(pt_form, uh_list_id);
  ps_list->uh_popup_idx = FrmGetObjectIndex(pt_form, uh_list_id - 1);

  // Coordonnées originales de la liste
  FrmGetObjectBounds(pt_form, ps_list->uh_list_idx, &s_rect);
  ps_list->s_list_pos = s_rect.topLeft;

  ps_list->pt_list = FrmGetObjectPtr(pt_form, ps_list->uh_list_idx);

  if (pa_account == NULL)
    ps_list->ra_account[0] = '\0';
  else
    StrCopy(ps_list->ra_account, pa_account);

  ps_list->uh_flags = uh_id & TYPE_FLAGS_MASK;
  ps_list->uh_id = uh_id;	// Avec les flags, modifié par listBuild...

  [self _popupListInit:(struct __s_dbitem_popup_list*)ps_list];

  // On charge la largeur max du popup
  // Coordonnées du popup
  FrmGetObjectBounds(pt_form, ps_list->uh_popup_idx, &s_rect);
  // -15 à gauche pour le "v" ET -3 à droite pour les espaces de fin
  ps_list->uh_popup_width = s_rect.extent.x - 15 - 3;

  // Label du popup
  ps_list->pa_popup_label = NULL;
  [self _popupListSetLabel:(struct __s_dbitem_popup_list*)ps_list];

  // Sélectionne l'item correspondant à l'ID
  [self _popupListSetSelection:(struct __s_dbitem_popup_list*)ps_list];

  // Le callback de remplissage de la liste
  LstSetDrawFunction(ps_list->pt_list, __list_popup_types_draw);

  MemHandleUnlock(pv_list);

  return pv_list;
}


- (void)popupList:(VoidHand)pv_list setSelection:(UInt16)uh_id
{
  struct __s_type_popup_list *ps_list;

  ps_list = MemHandleLock(pv_list);

  if (ps_list->uh_id != uh_id)
  {
    ps_list->uh_id = uh_id;
    [self _popupListReinit:(VoidHand)ps_list flags:PLIST_REINIT_DIRECT];
  }

  MemHandleUnlock(pv_list);
}


//
// Re-construit la liste en fonction de l'ID (+ flags) et du compte
// contenus dans la structure opaque passée en paramètre
- (void)_popupListReinit:(VoidHand)pv_list flags:(UInt16)uh_flags
{
  struct __s_type_popup_list *ps_list;

  // On nous passe directement la zone déjà lockée
  if (uh_flags & PLIST_REINIT_DIRECT)
    ps_list = (struct __s_type_popup_list*)pv_list;
  else
    ps_list = MemHandleLock(pv_list);

  // Libération de l'entrée "UP"
  if (ps_list->ps_buf->uh_entries & EDIT_UPLEVEL_ENTRY)
    MemPtrFree(ps_list->ps_buf->u.pa_uplevel);

  // Libération
  MemPtrFree(ps_list->ps_buf);

  // Réallocation
  ps_list->uh_id |= ps_list->uh_flags;
  [self _popupListInit:(struct __s_dbitem_popup_list*)ps_list];

  // Label du popup
  if ((uh_flags & PLIST_REINIT_NO_LABEL) == false)
    [self _popupListSetLabel:(struct __s_dbitem_popup_list*)ps_list];

  // Sélectionne l'item correspondant à l'ID
  if ((uh_flags & PLIST_REINIT_NO_SETSEL) == false)
    [self _popupListSetSelection:(struct __s_dbitem_popup_list*)ps_list];

  if ((uh_flags & PLIST_REINIT_DIRECT) == false)
    MemHandleUnlock(pv_list);
}


//
// Affiche la liste actuelle
// Gère la navigation entre les niveaux
// Retourne l'ID sélectionné ou TYPE_{ANY,EDIT,UNFILED} ou noListSelection
- (UInt16)popupList:(VoidHand)pv_list
{
  struct __s_type_popup_list *ps_list;
  UInt16 uh_saved_id, uh_id, uh_item, uh_flags;
  Boolean b_change_level = false;

  ps_list = MemHandleLock(pv_list);

  uh_saved_id = ps_list->uh_id;

  for (;;)
  {
    // Toutes les infos sur le popup de ce niveau
    uh_flags = ps_list->ps_buf->uh_entries;

    uh_item = LstPopupList(ps_list->pt_list);

    // Pas de sélection
    if (uh_item == noListSelection)
    {
      uh_id = noListSelection;
      break;
    }

    // Si c'est le premier item
    if (uh_item == 0)
    {
      // On a une entrée "Any"
      if (uh_flags & EDIT_ANY_ENTRY)
      {
	uh_id = ITEM_ANY;
	break;
      }

      // On a une entrée "up level" => il faut remonter d'un niveau...
      if (uh_flags & EDIT_UPLEVEL_ENTRY)
      {
	struct s_type *ps_type;
	Boolean b_up_level;

	// On a cliqué pour remonter d'un niveau ?
	b_up_level = [self _popupListTapSubMenu:ps_list right:false];

	// Rien dans la liste, cela peut se produire si une opération
	// a un type dont le parent ne matche pas le compte de
	// l'opération. Du coup le menu du parent sera vide...
	if (ps_list->ps_buf->uh_num_rec_entries == 0)
	{
	  uh_id = TYPE_UNFILED;
	  b_up_level = true;
	}
	else
	{
	  // On a forcemment au moins un type dans le menu, on prend le
	  // premier pour récupérer son père...
	  ps_type = [self getId:ps_list->ps_buf->rs_list2id[0].uh_id];
	  uh_id = ps_type->ui_parent_id;

	  [self getFree:ps_type];
	}

	// Reconstruction de la liste en fonction du nouveau type
	ps_list->uh_id = uh_id;
	[self _popupListReinit:(VoidHand)ps_list
	      flags:PLIST_REINIT_DIRECT | PLIST_REINIT_NO_LABEL];

	// Si on a cliqué sur la flèche : on remonte d'un niveau
	if (b_up_level)
	{
	  // On vient de changer de niveau
	  b_change_level = true;
	  continue;
	}

	// Sinon on sélectionne ce type : on retourne de suite
	break;
      }

      // Sinon c'est un type...
    }
    // La première ligne est occupée, on décrémente pour la correspondance
    else if (uh_flags & (EDIT_ANY_ENTRY | EDIT_UPLEVEL_ENTRY))
      uh_item--;

    // Il s'agit d'un type
    if (uh_item < ps_list->ps_buf->uh_num_rec_entries)
    {
      struct __s_one_popup_type *ps_one_type;

      ps_one_type = &ps_list->ps_buf->rs_list2id[uh_item];
      uh_id = ps_one_type->uh_id;

      // Il y a un sous-menu
      if (ps_one_type->uh_submenu == TYPE_SUBTYPE_ENABLED
	  // ET on a cliqué sur l'icône
	  && [self _popupListTapSubMenu:ps_list right:true])
      {
	struct s_type *ps_type;

	// On récupère le premier fils
	ps_type = [self getId:uh_id];
	ps_list->uh_id = ps_type->ui_child_id;
	[self getFree:ps_type];

	[self _popupListReinit:(VoidHand)ps_list
	      flags:PLIST_REINIT_DIRECT
	      | PLIST_REINIT_NO_SETSEL
	      | PLIST_REINIT_NO_LABEL];

	// On sélectionne le premier élément...
	LstSetSelection(ps_list->pt_list, 0);
	LstMakeItemVisible(ps_list->pt_list, 0);
	ps_list->uh_id = uh_id;

	// On vient de changer de niveau
	b_change_level = true;

	continue;
      }

      // On sélectionne ce type : on retourne de suite
      break;
    }

    // Une entrée "Unfiled" ou "Edit..."

    // Entrée "Unfiled"
    if (uh_item == ps_list->ps_buf->uh_num_rec_entries
	&& (uh_flags & EDIT_UNFILED_ENTRY))
      uh_id = TYPE_UNFILED;
    // Entrée "Edit..."
    else
    {
      uh_item = ps_list->ps_buf->uh_num_rec_entries;

      // Pas d'élément dans la liste
      if (uh_item == 0)
	uh_id = TYPE_UNFILED;
      else
      {
	struct __s_one_popup_type *ps_one_type;

	ps_one_type = ps_list->ps_buf->rs_list2id;

	// Premier du niveau par défaut
	uh_id = ps_one_type->uh_id;

	// On part de la fin
	ps_one_type += uh_item;

	// Si l'ID actuellement sélectionné est à ce niveau, on
	// renvoie cet ID. Sinon on renvoie le premier ID du niveau
	do
	{
	  if (ps_list->uh_id == (--ps_one_type)->uh_id)
	  {
	    uh_id = ps_one_type->uh_id;
	    break;
	  }
	}
	while (--uh_item > 0);
      }

      uh_id |= ITEM_EDIT;
    }

    break;
  } // for (;;)

  // uh_id = ID qui vient d'être sélectionné
  // uh_saved_id = ID qui était sélectionné à l'entrée dans la fonction
  // ps_list->uh_id = ID qui sert à la construction des listes dans cette fctn

  // L'ID sélectionné a changé
  if (uh_id != uh_saved_id)
  {
    // Il faut resélectionner la bonne entrée pour la prochaine ouverture
    if ((uh_id & ITEM_EDIT) || uh_id == noListSelection)
    {
      // La liste a bougé depuis le début OU BIEN on a changé de
      // niveau au moins une fois, il faut tout remettre en état
      if (ps_list->uh_id != uh_saved_id || b_change_level)
      {
	ps_list->uh_id = uh_saved_id;

	[self _popupListReinit:(VoidHand)ps_list
	      flags:PLIST_REINIT_DIRECT | PLIST_REINIT_NO_LABEL];

	// Sélectionne l'item correspondant à l'ID en cours
	[self _popupListSetSelection:(struct __s_dbitem_popup_list*)ps_list];
      }
      // C'est l'entrée "Edit..." qui a été sélectionnée, mais la
      // liste affichée n'a pas changé. On rectifie juste la sélection
      else if (uh_id != noListSelection)
	[self _popupListSetSelection:(struct __s_dbitem_popup_list*)ps_list];
    }
    // L'ID change pour de bon, on répercute...
    else
    {
      ps_list->uh_id = uh_id;

      // Label du popup
      [self _popupListSetLabel:(struct __s_dbitem_popup_list*)ps_list];
    }
  }

  MemHandleUnlock(pv_list);

  return uh_id;
}


//
// Retourne l'ID sélectionné ou TYPE_UNFILED ou ITEM_ANY
- (UInt16)popupListGet:(VoidHand)pv_list
{
  UInt16 uh_id;

  uh_id = ((struct __s_type_popup_list*)MemHandleLock(pv_list))->uh_id;
  MemHandleUnlock(pv_list);

  return uh_id;
}


//
// Libère tout ce qui a été alloué...
- (void)popupListFree:(VoidHand)pv_list
{
  if (pv_list != NULL)
  {
    struct __s_type_popup_list *ps_list;
    RectangleType s_rect;

    ps_list = MemHandleLock(pv_list);

    // On remet en place la largeur du popup, si jamais une liste doit
    // être reconstruite dans le même formulaire avant sa destruction
    FrmGetObjectBounds(ps_list->pt_form, ps_list->uh_popup_idx, &s_rect);
    s_rect.extent.x = ps_list->uh_popup_width + 15 + 3;	// "v" ET espaces fin
    FrmSetObjectBounds(ps_list->pt_form, ps_list->uh_popup_idx, &s_rect);

    MemPtrFree(ps_list->pa_popup_label);

    // Libération de l'entrée "UP"
    if (ps_list->ps_buf->uh_entries & EDIT_UPLEVEL_ENTRY)
      MemPtrFree(ps_list->ps_buf->u.pa_uplevel);

    MemPtrFree(ps_list->ps_buf);

    MemHandleUnlock(pv_list);

    MemHandleFree(pv_list);
  }
}


//
// Il faut initialiser la liste dont on vient de reconstruire le
// contenu
- (void)_popupListInit:(struct __s_dbitem_popup_list*)ps_super_list
{
  struct __s_type_popup_list *ps_list;
  RectangleType s_rect;
  Char *pa_account;
  UInt16 uh_largest;

  ps_list = (struct __s_type_popup_list*)ps_super_list;

  // Construction du contenu de la liste
  pa_account = ps_list->ra_account[0] == '\0' ? NULL : ps_list->ra_account;
  ps_list->ps_buf = [self listBuildForAccount:pa_account
			  selId:&ps_list->uh_id
			  num:&ps_list->uh_num
			  largest:&uh_largest];

  LstSetHeight(ps_list->pt_list, ps_list->uh_num);

  uh_largest += LIST_MARGINS_NO_SCROLL;

  // On initialise la liste et on regarde s'il y a ou non une flèche
  // de scroll dans la marge de droite
  if ([self rightMarginList:ps_list->pt_list num:ps_list->uh_num
	    in:(struct __s_list_dbitem_buf*)ps_list->ps_buf
	    selItem:-1])
    uh_largest += LIST_MARGINS_WITH_SCROLL - LIST_MARGINS_NO_SCROLL;

  // On s'adapte à la largeur de l'écran
  if (uh_largest > ps_list->uh_max_width)
    uh_largest = ps_list->uh_max_width;

  // On remet la liste à la bonne position (avec une largeur adéquate)
  FrmGetObjectBounds(ps_list->pt_form, ps_list->uh_list_idx, &s_rect);

  if (ps_list->s_list_pos.x + uh_largest > ps_list->uh_max_width)
    s_rect.topLeft.x = ps_list->uh_max_width - uh_largest;
  else
    s_rect.topLeft.x = ps_list->s_list_pos.x;

  s_rect.topLeft.y = ps_list->s_list_pos.y;
  s_rect.extent.x = uh_largest;

  FrmSetObjectBounds(ps_list->pt_form, ps_list->uh_list_idx, &s_rect);

  FrmGetObjectBounds(ps_list->pt_form, ps_list->uh_list_idx, &s_rect);
}


//
// En fonction de l'item sélectionné, modifie le label du popup
// associé à la liste.
- (void)_popupListSetLabel:(struct __s_dbitem_popup_list*)ps_super_list
{
  struct __s_type_popup_list *ps_list;
  Char *pa_label;

  ps_list = (struct __s_type_popup_list*)ps_super_list;

  if (ps_list->pa_popup_label != NULL)
    MemPtrFree(ps_list->pa_popup_label);

  if (ps_list->uh_id == ITEM_ANY)
  {
    UInt16 uh_len;

    NEW_PTR(pa_label, TYPE_NAME_MAX_LEN,
	    ({ ps_list->pa_popup_label = NULL; return; }));

    SysCopyStringResource(pa_label, strAnyList);

    uh_len = StrLen(pa_label);
    pa_label = truncate_name(pa_label, &uh_len, ps_list->uh_popup_width,
			     pa_label);
  }
  else
    pa_label = [self fullNameOfId:ps_list->uh_id
		     len:NULL
		     truncatedTo:ps_list->uh_popup_width];

  CtlSetLabel(FrmGetObjectPtr(ps_list->pt_form, ps_list->uh_popup_idx),
	      pa_label);

  ps_list->pa_popup_label = pa_label;
}


//
// En fonction de l'item sélectionné, sélectionne la bonne entrée dans
// la liste
- (void)_popupListSetSelection:(struct __s_dbitem_popup_list*)ps_super_list
{
  struct __s_type_popup_list *ps_list;
  UInt16 uh_item;
  Boolean b_item_visible = true;

  ps_list = (struct __s_type_popup_list*)ps_super_list;

  switch (ps_list->uh_id)
  {
  case ITEM_ANY:
    uh_item = 0;		// Toujours en tête...
    break;

  case TYPE_UNFILED:
    // "Unfiled" est dernier si pas d'entrée "Edit...", avant dernier sinon
    uh_item = ps_list->uh_num - 1;

    if (ps_list->uh_flags & TYPE_ADD_EDIT_LINE)
      uh_item--;

    // Dans ce cas précis, on ne cherche pas à rendre visible l'item
    b_item_visible = false;
    break;

  default:
  {
    struct __s_one_popup_type *ps_one_type;
    UInt16 uh_num_types = ps_list->ps_buf->uh_num_rec_entries;

    ps_one_type = ps_list->ps_buf->rs_list2id;

    for (uh_item = 0; uh_item < uh_num_types; uh_item++, ps_one_type++)
      if (ps_one_type->uh_id == ps_list->uh_id)
	break;

    // Ce popup a une première entrée avant les vrais types
    if (ps_list->ps_buf->uh_entries & (EDIT_UPLEVEL_ENTRY | EDIT_ANY_ENTRY))
      uh_item++;
    break;
  }
  }

  LstSetSelection(ps_list->pt_list, uh_item);
  LstMakeItemVisible(ps_list->pt_list, b_item_visible ? uh_item : 0);
}


//
// Renvoie true si le stylet a été relaché sur l'icône du sous-menu à
// droite (b_right) ou à gauche (b_right == false)
- (Boolean)_popupListTapSubMenu:(struct __s_type_popup_list*)ps_list
			  right:(Boolean)b_right
{
  RectangleType s_rect;
  UInt16 uh_x, uh_x_base, uh_submenu_width;
  Boolean b_pen;

  // Coordonnées de la liste
  FrmGetObjectBounds(ps_list->pt_form, ps_list->uh_list_idx, &s_rect);

  EvtGetPen(&uh_x, &uh_x_base /*DUMMY*/, &b_pen /*DUMMY*/);

  uh_x_base = s_rect.topLeft.x;

#define TAP_SUBMENU_WIDTH	10 // Arbitraire...
  uh_submenu_width = TAP_SUBMENU_WIDTH;

  if (b_right)
  {
    uh_x_base += s_rect.extent.x - TAP_SUBMENU_WIDTH;

    // S'il y a une flèche de scroll, il faut se décaler un peu plus...
    if (ps_list->ps_buf->uh_is_scroll_list)
    {
      uh_x_base -= LIST_SCROLL_WIDTH;
      uh_submenu_width += LIST_SCROLL_WIDTH;
    }
  }

  return uh_x >= uh_x_base && uh_x < uh_x_base + uh_submenu_width;
}

@end
