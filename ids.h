/* 
 * ids.h -- 
 * 
 * Author          : Max Root
 * Created On      : Sat Jan 11 12:35:43 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Wed Jun  2 14:34:11 2004
 * Update Count    : 3
 * Status          : Unknown, Use with caution!
 */

#ifndef	__IDS_H__
#define	__IDS_H__

#define MaTiCreatorID		'MaT2'
#define MaTiPrefix		"MaTi"
#define MaTiDBPrefix		MaTiPrefix "-"
#define MaTiAcntPrefix		MaTiPrefix "="
#define MaTiAcntPrefixLen	(sizeof(MaTiAcntPrefix) - 1)

// Types DB
#define MaTiTypesType		'Type'
#define MaTiTypesName		MaTiDBPrefix "Types"

// Modes DB
#define MaTiModesType		'Mode'
#define MaTiModesName		MaTiDBPrefix "Modes"

// Descriptions/macros DB
#define MaTiDescType		'Desc'
#define MaTiDescName		MaTiDBPrefix "Descriptions"

// Currencies DB
#define MaTiCurrType		'Curr'
#define MaTiCurrName		MaTiDBPrefix "Currencies"

// External currencies DB to update Ma Tirelire one...
#define MaTiExtCurrType		'CurX'
#define MaTiExtCurrName		MaTiDBPrefix "ExternalCurrencies"

// Accounts DB
#define MaTiAccountsType	'Acnt'

#endif	/* __IDS_H__ */
