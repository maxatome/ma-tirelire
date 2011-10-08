/* -*- objc -*-
 * DBasePropForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Jeu jul  1 19:31:25 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Nov 18 13:59:24 2005
 * Update Count    : 1
 * Status          : Unknown, Use with caution!
 */

#ifndef	__DBASEPROPFORM_H__
#define	__DBASEPROPFORM_H__

#include "MaTiForm.h"
#include "structs.h"

#ifndef EXTERN_DBASEPROPFORM
# define EXTERN_DBASEPROPFORM extern
#endif

@interface DBasePropForm : MaTiForm
{
  UInt32 ul_current_code;
  MemHandle vh_db_prefs;

  // La base en cours d'édition
  Char ra_name[dmDBNameLength];
  LocalID ui_db_id;
  UInt16  uh_card_no;

  // À true si les préférences sont déjà chargées et prises depuis
  // [oMaTirelire transaction]->ps_prefs
  UInt16 uh_transaction:1;

  // Type de tri
  UInt16 uh_sort_type:1;

  // Type de date affichée
  UInt16 uh_list_date:1;

  // Type en lieu et place de la description
  UInt16 uh_list_type:1;
}

- (Boolean)extractAndSave;

- (void)_changeCode;

@end

#endif	/* __DBASEPROPFORM_H__ */
