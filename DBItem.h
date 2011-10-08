/* -*- objc -*-
 * DBItem.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sun Aug 24 21:43:10 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jun  9 14:22:46 2006
 * Update Count    : 9
 * Status          : Unknown, Use with caution!
 */

#ifndef	__DBITEM_H__
#define	__DBITEM_H__

#include "Object.h"
#include "db_list.h"

#ifndef EXTERN_DBITEM
#define EXTERN_DBITEM extern
#endif

struct s_record_infos
{
  MemHandle vh_data;
  UInt16 uh_index;
};

struct __s_list_dbitem_buf;


@interface DBItem : Object
{
  DmOpenRef db;

  // Current record (-record* methods)
  struct s_record_infos s_record_infos;
}

+ (DBItem*)new;
- (DBItem*)init;
- (DBItem*)initDBType:(UInt32)ui_db_type nameSTR:(Char*)pa_db_name;
- (DBItem*)initWithCardNo:(UInt16)uh_cardno withID:(LocalID)ul_id;
- (void)setBackupBit;

- (Char*)getName:(Char*)pa_name;

- (void*)recordNewAtId:(UInt16*)puh_index size:(UInt16)uh_size;
- (void*)recordGetAtId:(UInt16)uh_index;
- (void*)recordResizeId:(UInt16)uh_index newSize:(UInt16)uh_size;
- (void)recordRelease:(Boolean)b_modified;

- (void*)getId:(UInt16)uh_id;
- (void)getFree:(void*)ps_item;

- (Boolean)save:(void*)ps_item size:(UInt16)uh_size asId:(UInt16*)puh_index
	  asNew:(UInt16)uh_new;
- (void)setCategory:(UInt16)uh_category forId:(UInt16)uh_id;
- (Boolean)moveId:(UInt16)uh_id direction:(WinDirectionType)dir;

// returns -1 if error, 1 if remove, 0 if delete
#define DBITEM_DEL_REMOVE	0x80000000 // Force Remove (really delete)
#define DBITEM_DEL_DELETE	0x40000000 // Force Delete (leave rec entry)
- (Int16)deleteId:(UInt32)ui_id;

// Gestion du AppInfoBlock
#define DBITEM_CATEGORY_INFOS	     0x8000
#define DBITEM_SIZE_MASK	     0x07ff
#define DBITEM_DEFCAT_SET(cat, size) (DBITEM_CATEGORY_INFOS|(cat << 11)|size)
#define DBITEM_DEFCAT_GET(size)	     ((size >> 11) & (dmRecNumCategories-1))
- (Err)appInfoBlockSave:(void*)pv_zone size:(UInt16)uh_size;
- (Err)appInfoBlockLoad:(void**)ppv_zone size:(UInt16*)puh_size
		  flags:(UInt16)uh_flags;

- (Err)sortInfoBlockSave:(void*)pv_zone size:(UInt16)uh_size;
- (Err)sortInfoBlockLoad:(void**)ppv_zone size:(UInt16*)puh_size
		   flags:(UInt16)uh_flags;


// Gestion des popups
- (Char**)listBuildInfos:(void*)pv_infos num:(UInt16*)puh_num
		 largest:(UInt16*)puh_largest;
- (void)listFree:(Char**)ppa_list;
- (ListDrawDataFuncPtr)listDrawFunction;

- (UInt16)dbMaxEntries;

- (Boolean)rightMarginList:(ListType*)pt_list
		       num:(UInt16)uh_num
			in:(struct __s_list_dbitem_buf*)ps_buf
		   selItem:(Int16)h_sel_item; // -1 si pas de sélection à faire

- (DmOpenRef)db;

- (DBItem*)clone:(Char*)pa_clone_name;

- (void)getCardNo:(UInt16*)puh_card_no andID:(LocalID*)pul_id;

- (Char*)getCategoriesNamesForMask:(UInt16)uh_accounts_mask
			    retLen:(UInt16*)puh_len
			    retNum:(UInt16*)puh_num;

#if 0
// Type des fonctions utilisées pur la méthode -foreachDo:from:to:
typedef Boolean(*t_trans_foreach)(const void*, void*);

- XXX(Boolean)foreachDo:(t_trans_foreach)pf_func
		from:(UInt16)uh_from to:(UInt16)uh_to
	  inCategory:(UInt16)uh_category
		   with:(void*)pv_param;
#endif

@end

#define __STRUCT_DBITEM_LIST_BUF(Class) \
	Class *oItem; \
	UInt16 uh_is_right_margin:1; \
	UInt16 uh_is_scroll_list:1; \
	UInt16 uh_only_in_account_view:1; \
	UInt16 uh_flags:13; \
	UInt16 uh_num_rec_entries

struct __s_list_dbitem_buf
{
  __STRUCT_DBITEM_LIST_BUF(DBItem);
};

#endif	/* __DBITEM_H__ */
