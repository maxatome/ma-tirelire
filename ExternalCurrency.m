/* 
 * ExternalCurrency.m -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Thu Oct 26 16:55:17 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jan 11 14:42:46 2008
 * Update Count    : 65
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: ExternalCurrency.m,v $
 * Revision 1.2  2008/01/14 16:58:27  max
 * Rework external currencies handling.
 *
 * Revision 1.1  2006/11/04 23:47:51  max
 * First import.
 *
 * ==================== RCS ==================== */

//#define	TRY_TO_LOAD_FROM_VFS

#define EXTERN_EXTERNALCURRENCY
#include "ExternalCurrency.h"

#ifdef TRY_TO_LOAD_FROM_VFS
# include <ExpansionMgr/VFSMgr.h>
#endif

#include "ExternalCurrencyMaTi.h"
#include "ExternalCurrencyCur4.h"

#include "ids.h"


@implementation ExternalCurrency

- (ExternalCurrency*)init
{
  Char ra_name[dmDBNameLength];
  UInt32 ui_creator, ui_type;

  ui_creator = [self creatorType:&ui_type name:ra_name];

  // Si un nom est spécifié, on essaie d'abord de trouver la base avec ce nom
  if (ra_name[0] != '\0')
  {
    UInt32 ui_creator_found, ui_type_found;
    LocalID ul_id;

    ul_id = DmFindDatabase(0, ra_name);

    if (ul_id != 0
	&& DmDatabaseInfo(0, ul_id,
			  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
			  &ui_type_found, &ui_creator_found) == errNone
	&& ui_type_found == ui_type
	&& ui_creator_found == ui_creator_found
	&& [self initWithCardNo:0 withID:ul_id] != nil)
      return self;
  }

  // Sinon, on charge juste en fonction du créateur et du type de la base
  self->db = DmOpenDatabaseByTypeCreator(ui_type, ui_creator, dmModeReadOnly);
  if (self->db == NULL)
    return nil;

  return self;
}


- (UInt32)getLastUpdateDate
{
  UInt32  ui_last_upd_date = 0;
  LocalID ui_lid;
  UInt16  uh_cardno;

  if (DmOpenDatabaseInfo(self->db, &ui_lid, NULL, NULL, &uh_cardno, NULL)
      == errNone)
    DmDatabaseInfo(uh_cardno, ui_lid, NULL, NULL, NULL,
		   &ui_last_upd_date, // Date de création de la base
		   NULL, NULL, NULL, NULL, NULL, NULL, NULL);

  return ui_last_upd_date;
}


- (BOOL)getReferenceFrom:(Currency*)oCurrencies
	    andPutRateIn:(struct s_eur_ref*)ps_eur_ref
{
  return [self subclassResponsibility];
}


- (void*)getISO4217:(Char*)pa_iso4217
{
  return [self subclassResponsibility];
}


- (void)adjustCurrency:(struct s_currency*)ps_currency
  withExternalCurrency:(void*)ps_ext_cur
	  andReference:(struct s_eur_ref*)ps_eur_ref
{
  return [self subclassResponsibility];
}


- (UInt32)creatorType:(UInt32*)ui_type name:(Char*)pa_name
{
  return [self subclassResponsibility];
}


- (UInt16)dbMaxEntries
{
  return DmNumRecords(self->db);
}


- (UInt16)dbFirstItem
{
  return 0;
}

@end
