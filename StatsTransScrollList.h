/* -*- objc -*-
 * StatsTransScrollList.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Mar aoû 16 20:23:51 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Wed Jun 27 18:26:03 2007
 * Update Count    : 31
 * Status          : Unknown, Use with caution!
 */

#ifndef	__STATSTRANSSCROLLLIST_H__
#define	__STATSTRANSSCROLLLIST_H__

#include "CustomScrollList.h"

#include "TransForm.h"


#ifndef EXTERN_STATSTRANSSCROLLLIST
# define EXTERN_STATSTRANSSCROLLLIST extern
#endif


// Structure utilisée par trans_draw_record()
struct s_stats_trans_draw
{
  UInt16 uh_rec_index;
  Int16  h_split;		// -1 op complète, 0x100 reste, sinon idx split
#define TRANS_DRAW_ADD_NONE	0
#define TRANS_DRAW_ADD_MODE	1
#define TRANS_DRAW_ADD_TYPE	2
#define TRANS_DRAW_ADD_CHEQUE	3
  UInt16 uh_add_to_desc:2;
  UInt16 uh_selected:1;		// On veut la somme sélectionnée
  UInt16 uh_select_with_internal_flag:1; // Le internal_flag select ou non
  UInt16 uh_non_flagged:1;	// On ne veut pas la somme marquée
  UInt16 uh_repeat_screen:1;	// Écran des répétitions
  UInt16 uh_another_amount:1;	// l_amount est le montant de la ligne
  DateType s_date;		// À utiliser si != 0
  t_amount l_amount;		// À utiliser si uh_another_amount
};

union u_stats_trans_edit
{
  UInt16 uh_edited_account;	// Catégorie (compte) pour AccountPropForm
  struct s_trans_form_args s_trans_form; // Infos pour TransForm
};


// Pour les classes filles, base de chaque élément de self->vh_infos
#define STRUCT_STATS_TRANS_BASE					       \
  UInt16   uh_rec_index;     /* Index de l'enregistrement */	       \
  t_amount l_amount	     /* Somme dans la monnaie du formulaire */

struct s_stats_trans_base
{
  STRUCT_STATS_TRANS_BASE;
};


struct s_private_search_trans
{
  UInt16 uh_opt_min;		// Pour optimiser la seconde passe
  UInt16 uh_opt_num;		// Pour optimiser la seconde passe

  struct s_stats_trans_base *ps_items; // Pour le stockage

  Boolean b_second_pass;
  Boolean b_no_type;		// Utilisé dans StatsTransAllScrollList
};

@interface StatsTransScrollList : CustomScrollList
{
  MemHandle vh_select;

  struct s_private_search_trans *ps_search_trans_infos;

  union u_stats_trans_edit u;
}

- (void)getRecordInfos:(struct s_stats_trans_base*)ps_infos
	       forLine:(UInt16)uh_line;

- (UInt16)oneElementSize;
- (UChar)initSelectedPattern;

- (void)initDraw:(struct s_stats_trans_draw*)ps_draw
	    from:(struct s_stats_trans_base*)ps_infos;

@end

#endif	/* __STATSTRANSSCROLLLIST_H__ */
