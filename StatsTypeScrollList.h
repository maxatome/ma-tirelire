/* -*- objc -*-
 * StatsTypeScrollList.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Jeu aoû  4 23:38:14 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Dec 10 16:25:18 2007
 * Update Count    : 4
 * Status          : Unknown, Use with caution!
 */

#ifndef	__STATSTYPESCROLLLIST_H__
#define	__STATSTYPESCROLLLIST_H__

#include "CustomScrollList.h"

#include "CustomListForm.h"

#include "Type.h"
#include "misc.h"

#ifndef EXTERN_STATSTYPESCROLLLIST
# define EXTERN_STATSTYPESCROLLLIST extern
#endif

#define TYPES_BITS_WIDTH	DWORDFORBITS(NUM_TYPES)	// mcc hack

struct s_stats_type
{
  t_amount l_sum;			// Somme pour ce type
  t_amount l_sum_with_children;		// Somme pour ce type
  UInt16 uh_num_op;			// Nombre d'opérations
  UInt16 uh_num_op_with_children;	// Nombre d'op. descendance comprise
  UInt32 ui_num_split_op;		// Nombre de sous-opérations
  UInt32 ui_num_split_op_with_children; // Nbre de ss-op. descendance comprise
  UInt16 uh_accounts;			// Comptes concernés
  UInt16 uh_accounts_with_children;	// Comptes concernés
  UInt16 uh_num_children;		// Nombre de fils
  UInt16 uh_id:8;			// ID du type
  UInt16 uh_folded:1;			// Type replié ou non
  UInt16 uh_selected:1;			// Type sélectionné ou non
  UInt16 uh_add_to_num_op:1;		// Local à -searchMatch:
};


struct s_private_search_type
{
  struct s_stats_type *ps_base_type_infos;
  UChar *pua_id2list;		// self->vh_cache locké
};

@interface StatsTypeScrollList : CustomScrollList
{
  MemHandle vh_tree;		// Pour le dessin de l'arborescence
  MemHandle vh_cache;		// ID type -> index buffer vh_infos

  UInt32 rul_types[TYPES_BITS_WIDTH]; // Pour StatsTransScrollList
  Int16 h_type;			// Pour StatsTransScrollList, si >= 0

  UInt16 uh_num_types;		// XXX est-ce utile ? XXX

  struct s_private_search_type *ps_search_type_infos;

  // Set after -searchFrom:amount: call
  Boolean b_ignore_nulls;
}

- (void)updateFolded;

- (void)buildTree:(Boolean)b_force;
- (void)refreshList;

@end

#endif	/* __STATSTYPESCROLLLIST_H__ */
