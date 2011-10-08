/* -*- objc -*-
 * Mode.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Fri Aug 22 17:53:35 2003
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__MODE_H__
#define	__MODE_H__

#include "DBItemId.h"

#ifndef EXTERN_MODE
#define EXTERN_MODE extern
#endif

#define NUM_MODES	(1 << 5)

//
// Transaction modes
struct s_mode
{
#define MODE_UNKNOWN	(NUM_MODES - 1)
  UInt32 ui_id:5;		// Mode ID
#define MODE_VAL_DATE_NONE		0
#define MODE_VAL_DATE_CUR_MONTH		1
#define MODE_VAL_DATE_NEXT_MONTH	2
#define MODE_VAL_DATE_PLUS_DAYS		3
#define MODE_VAL_DATE_MINUS_DAYS	4
  UInt32 ui_value_date:3;       // 0 pas de raccourci sur date de valeur
				// 1 => ancien XX=YY
				// 2 => ancien XX-YY
				// 3 => ancien +ZZ
				// 4 => nouveau -ZZ
				// 5-7 => réservés (équivalent à 0)
  UInt32 ui_first_val:6;	// XX ou ZZ selon ui_value_date
  UInt32 ui_debit_date:5;	// YY
  UInt32 ui_cheque_auto:1;	// Mode à sélectionner si chèque auto
  UInt32 ui_reserved:12;	// Pour le futur : toujours à 0

  // Account name/wildcard visibility
#define MODE_ONLY_IN_ACC_LEN	(23 + 1)
  Char ra_only_in_account[MODE_ONLY_IN_ACC_LEN];

#define MODE_NAME_MAX_LEN	(31 + 1)
  Char ra_name[0];		// Type fini par NUL (longueur variable)
};


@interface Mode : DBItemId
{
}

- (Int16)popupListGetAutoChequeMode:(VoidHand)pv_list;

@end

struct __s_list_mode_buf
{
  __STRUCT_DBITEM_LIST_BUF(Mode);
  Char ra_macro[5	// XX-YY
		+ 1	// Separator
		+ MODE_ONLY_IN_ACC_LEN]; // ra_only_in_account + \0
  Char ra_edit_entry[MODE_NAME_MAX_LEN];
  Char ra_unknown_entry[MODE_NAME_MAX_LEN];
  Char ra_first_entry[MODE_NAME_MAX_LEN];
  UInt16 ruh_list2index[0];
};

#endif	/* __MODE_H__ */
