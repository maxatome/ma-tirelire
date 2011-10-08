/* 
 * db_list.h -- 
 * 
 * Author          : Maxime Soulé
 * Created On      : Wed Jun 30 22:59:58 2004
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__DB_LIST_H__
#define	__DB_LIST_H__

#include <PalmOS.h>

#ifndef EXTERN_DB_LIST
# define EXTERN_DB_LIST extern
#endif

#define DB_LIST_LAST_ENTRY_MAXLEN	32
EXTERN_DB_LIST MemHandle db_list_new(UInt32 ul_creator, UInt32 ul_type,
				     UInt16 *puh_num, UInt16 *puh_largest,
				     UInt16 uh_last_entry1,
				     UInt16 uh_last_entry2,
				     Boolean b_db_sub_menus);

EXTERN_DB_LIST Char *db_list_visible_name(Char *pa_db_name);

#define INFOBLK_CATEGORIES	0x0001
#define INFOBLK_DIRECTZONE	0x0002
#define INFOBLK_PTRNEW		0x0004
EXTERN_DB_LIST Err db_app_info_block_load(UInt16 uh_cardno, LocalID ui_lid,
					  void **ppv_zone, UInt16 *puh_size,
					  UInt16 uh_flags);
EXTERN_DB_LIST Err db_app_info_block_save(DmOpenRef db,
					  UInt16 uh_cardno, LocalID ui_lid,
					  void *pv_zone, UInt16 uh_size,
					  Int16 h_def_category);/* -1 no cat */

EXTERN_DB_LIST Err db_sort_info_block_load(UInt16 uh_cardno, LocalID ui_lid,
					   void **ppv_zone, UInt16 *puh_size,
					   UInt16 uh_flags);
EXTERN_DB_LIST Err db_sort_info_block_save(DmOpenRef db,
					   UInt16 uh_cardno, LocalID ui_lid,
					   void *pv_zone, UInt16 uh_size);

#endif	/* __DB_LIST_H__ */
