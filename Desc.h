/* -*- objc -*-
 * Desc.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sun Aug 24 13:04:31 2003
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__DESC_H__
#define	__DESC_H__

#include "DBItem.h"

#include "Mode.h"
#include "Type.h"

#ifndef EXTERN_DESC
#define EXTERN_DESC extern
#endif


// ** ATTENTION ** si on veut changer ce define, il faut penser à
// ** modifier le nombre de bits de uh_pre_desc dans la structure
// ** struct s_trans_form_args dans TransForm.h
#define NUM_DESC	256

//
// Pour les descriptions/macros avec pour chaque enregistrement :
struct s_desc
{
#define DESC_HEADER_OFFSET	0
#define DESC_HEADER_SIZE	sizeof(UInt32)
  UInt32 ui_sign:2;		// 0 pas de signe, 1 -, 2 +
  UInt32 ui_is_mode:1;		// Le champ ui_mode contient une valeur
  UInt32 ui_mode:5;		// ID du mode à initialiser (si ui_is_mode)
  UInt32 ui_is_type:1;		// Le champ ui_type contient une valeur
  UInt32 ui_type:8;		// ID du type à initialiser (si ui_is_type)
  UInt32 ui_shortcut:8;		// Caractère de raccourci pour la macro
  UInt32 ui_cheque_num:1;	// Numéro de chèque auto à calculer
  UInt32 ui_auto_valid:1;	// Validation automatique après execution
  UInt32 ui_reserved:5;		// Pour le futur : toujours à 0

  Char  ra_amount[11 + 1];	// Somme de la macro finie par NUL
				// mais toujours 12 octets
  Char  ra_account[dmCategoryLength]; // Nom du compte de la macro fini par NUL
				// mais toujours 16 octets (si ui_is_xfer)
  Char  ra_xfer[dmCategoryLength]; // Nom du compte de transfert fini par NUL
				// mais toujours 16 octets (si ui_is_xfer)

  // Account name/wildcard visibility
#define DESC_ONLY_IN_ACC_LEN	(23 + 1)
  Char  ra_only_in_account[DESC_ONLY_IN_ACC_LEN];

#define DESC_MAX_LEN	(255 + 1)
  Char  ra_desc[0];		// Description finie par NUL
				// (longueur variable)
};


@interface Desc : DBItem
{
}

- (UInt16)removeType:(UInt16)uh_id;
- (UInt16)removeMode:(UInt16)uh_id;

// Pour -listBuildInfos:num:largest:
struct s_desc_list_infos
{
  Char ra_account[dmCategoryLength];
  Char ra_shortcut[2];		// [1] doit TOUJOURS valoir \0
};

struct s_desc_popup_infos
{
  UInt16 uh_account;		// Utilisé dans -popupListInit:...
#define DESC_ADD_EDIT_LINE	0x0001
#define DESC_AT_SCREEN_BOTTOM	0x0002
  UInt16 uh_flags;
  Char ra_shortcut[2];		// [1] doit TOUJOURS valoir \0
};

- (VoidHand)popupListInit:(UInt16)uh_list_id
                     form:(FormType*)pt_frm
		    infos:(struct s_desc_popup_infos*)ps_infos;

#define DESC_EDIT		0x8000
- (UInt16)popupList:(VoidHand)pv_list autoReturn:(Boolean)b_auto_return;

- (void)popupListFree:(VoidHand)pv_list;

@end

// Mode can be prefixed by a '*'
#define MACRO_COMP_MAX_LEN	(TYPE_NAME_MAX_LEN + 1)
#define MACRO_NUM_COMP		6 // Components...

struct __s_desc_one_macro_comp
{
  Char ra_str[MACRO_COMP_MAX_LEN];
  UInt16 uh_len:8;
  UInt16 uh_truncated:8;
};

struct __s_list_desc_buf
{
  __STRUCT_DBITEM_LIST_BUF(Desc);
  Mode *oMode;
  Type *oType;

  union
  {
    // TYPE_NAME_MAX_LEN est le plus contenant de tous les composants
    struct __s_desc_one_macro_comp rs_macro_comps[MACRO_NUM_COMP];
    Char ra_str[MACRO_NUM_COMP * MACRO_COMP_MAX_LEN];
  } u;

  Char ra_edit_entry[31 + 1];

  UInt16 uh_total_width;
  UInt16 uh_num_comp;
  UInt16 uh_non_empty;

  UInt16 ruh_list2index[0];
};

#endif	/* __DESC_H__ */
