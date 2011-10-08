/* -*- objc -*-
 * Type.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sun Aug 24 13:04:31 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb 17 12:12:48 2006
 * Update Count    : 3
 * Status          : Unknown, Use with caution!
 */

#ifndef	__TYPE_H__
#define	__TYPE_H__

#include "DBItemId.h"

#ifndef EXTERN_TYPE
# define EXTERN_TYPE extern
#endif

#define NUM_TYPES	(1 << 8)

//
// Transaction types
struct s_type
{
#define TYPE_RELATIONSHIP_SIZE	sizeof(UInt32)
#define TYPE_RELATIONSHIP_OFFSET 0
#define TYPE_UNFILED	(NUM_TYPES - 1)
  UInt32 ui_id:8;		// ID du type
  UInt32 ui_parent_id:8;	// ID du type parent, TYPE_UNFILED si aucun
  UInt32 ui_child_id:8;		// ID du premier fils, TYPE_UNFILED si aucun
  UInt32 ui_brother_id:8;	// ID du prochain frère, TYPE_UNFILED si aucun

#define TYPE_ATTR_SIZE		sizeof(UInt32)
#define TYPE_ATTR_OFFSET	TYPE_RELATIONSHIP_SIZE
  //#define TYPE_NONE	0	// Undefined
#define TYPE_DEBIT	1
#define TYPE_CREDIT	2
#define TYPE_ALL	3
  UInt32 ui_sign_depend:2;
  UInt32 ui_folded:1;		// Is type folded is types list dialog
  UInt32 ui_reserved:29;	// Reserved for future use

  // Account name/wildcard visibility
#define TYPE_ONLY_IN_ACC_LEN	(23 + 1)
  Char ra_only_in_account[TYPE_ONLY_IN_ACC_LEN];

#define TYPE_NAME_MAX_LEN	(31 + 1)
  Char ra_name[0];		// Type fini par NUL (longueur variable)
};


//
// Utilisé en interne pour les popups en cascade
struct __s_type_popup_list;

struct __s_edit_list_type_buf;


#define TYPE_NUM_CACHE_ENTRIES	(NUM_TYPES - 1)
@interface Type : DBItemId
{
  UInt16 uh_first_id;		// First type from root
}

- (struct s_type*)getLastChild:(struct s_type*)ps_type;
- (struct s_type*)getFirstBrother:(struct s_type*)ps_type;
- (struct s_type*)getPrevBrother:(struct s_type*)ps_type
			parentIn:(struct s_type**)pps_parent_type;
- (UInt16)getDepth:(struct s_type*)ps_type;
- (UInt16)getMaxDepth:(struct s_type*)ps_type;

#define TYPE_NOT_SIGN	0x8000
- (Boolean)isOneChildOfId:(UInt16)uh_id forSign:(UInt16)uh_sign
	    andForAccount:(Char*)pa_account;

- (Boolean)isBadSignInDescendantsOfId:(UInt16)uh_id;

- (Boolean)propagateSign:(UInt16)ui_sign overChildrenOfId:(UInt16)uh_base_id;

- (Boolean)changeRelationShipAndFree:(struct s_type*)ps_type
			   newParent:(Int16)h_parent_id
			    newChild:(Int16)h_child_id
			  newBrother:(Int16)h_brother_id;

- (Boolean)changeAttrAndFree:(struct s_type*)ps_type
		     newSign:(Int16)h_sign
		     newFold:(Int16)h_fold;

- (Boolean)moveIdPrev:(UInt16)uh_id;
- (Boolean)moveIdNext:(UInt16)uh_id;
- (Boolean)moveIdUp:(UInt16)uh_id;
- (Boolean)moveIdDown:(UInt16)uh_id;

- (Boolean)foldId:(UInt16)uh_id;

- (UInt16)setBitFamily:(UInt32*)pul_types forType:(UInt16)uh_id;

- (struct __s_popup_list_type_buf*)listBuildForAccount:(Char*)pa_account
						 selId:(UInt16*)puh_id
						   num:(UInt16*)puh_num
					       largest:(UInt16*)puh_largest;

- (Char*)fullNameOfId:(UInt16)uh_id len:(UInt16*)puh_len
	  truncatedTo:(UInt16)uh_max_width;

////////////////////////////////////////////////////////////////////////
//
// Gestion des popups de type

#define TYPE_FLAG_SIGN_CREDIT	0x8000 // Only credit types \_ if both only ALL
#define TYPE_FLAG_SIGN_DEBIT	0x4000 // Only debit types  /
#define TYPE_FLAG_SIGN_NONE	(TYPE_FLAG_SIGN_CREDIT|TYPE_FLAG_SIGN_DEBIT)
#define TYPE_FLAG_SIGN_SHIFT	14
#define TYPE_ADD_ANY_LINE	0x2000 // The "Any" first line is present
#define TYPE_ADD_EDIT_LINE	0x1000 // The "Edit..." last lineS are present
#define TYPE_FLAGS_MASK		0xf000
// pour -popupListInit:form:Id:forAccount:

- (Boolean)_popupListTapSubMenu:(struct __s_type_popup_list*)ps_list
			  right:(Boolean)b_right;

@end

// On accepte jusqu'à 10 niveaux de profondeur, pas plus
#define TYPE_MAX_DEPTH	10

#define GLYPH_WIDTH	7

////////////////////////////////////////////////////////////////////////
//
// Écran de la liste des types
struct __s_one_type
{
  UInt32 ui_depth:4;		// Profondeur du type
#define DEPTH_GLYPH_NONE 0	// -rien-
#define DEPTH_GLYPH_I	 1	// |
#define DEPTH_GLYPH_T	 2	// |-
#define DEPTH_GLYPH_L	 3	// +-
#define DEPTH_GLYPH_MASK 3	// Masque...
  UInt32 ui_depth_glyphs:TYPE_MAX_DEPTH * 2; // 2 bits par niveau
  UInt32 ui_id:8;		// ID du type (n'est pas l'index dans la base)
};

struct __s_edit_list_type_buf
{
  __STRUCT_DBITEM_LIST_BUF(Type);
  Char ra_macro[1	// +/-
		+ 1	// Separator
		+ TYPE_ONLY_IN_ACC_LEN]; // ra_only_in_account + \0
  UInt16 uh_x_pos;		// First X pixel of cells in the list
  struct __s_one_type rs_list2id[0];
};


#define GLYPH_WIDTH	7

#define DRAW_GLYPH_CHILD	0x4000
#define DRAW_GLYPH_FOLDED	0x8000
EXTERN_TYPE void list_draw_glyph(UInt16 uh_x, UInt16 uh_y, UInt16 uh_h,
				 UInt16 uh_flags);

#endif	/* __TYPE_H__ */
