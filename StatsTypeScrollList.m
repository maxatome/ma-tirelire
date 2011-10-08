/* 
 * StatsTypeScrollList.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Jeu aoû  4 23:38:14 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Jan 22 12:01:21 2008
 * Update Count    : 63
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: StatsTypeScrollList.m,v $
 * Revision 1.12  2008/02/01 17:21:51  max
 * Cosmetic changes.
 * Null amounts handled differently.
 *
 * Revision 1.11  2008/01/14 16:07:36  max
 * Switch to new mcc.
 * Change -buildTree: prototype.
 * When we ignore null amounts, reset all for each change.
 *
 * Revision 1.10  2006/11/04 23:48:18  max
 * Change type size for splits counters.
 * Use FOREACH_SPLIT* macros.
 * Do some micro-optimisations.
 *
 * Revision 1.9  2006/10/05 19:09:01  max
 * Search totally reworked using CustomScrollList genericity.
 * Take into account transaction splits.
 *
 * Revision 1.8  2006/06/28 09:41:41  max
 * s/pt_frm/oForm/g attribute.
 *
 * Revision 1.7  2006/05/02 15:36:31  max
 * Crash when no type defined. Corrected.
 *
 * Revision 1.6  2006/04/25 08:46:15  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.5  2005/10/11 19:12:01  max
 * Export feature added.
 *
 * Revision 1.4  2005/08/31 19:43:10  max
 * Does not take account properties into account anymore.
 * Empty screen caused a crash. Corrected.
 *
 * Revision 1.3  2005/08/31 19:38:53  max
 * *** empty log message ***
 *
 * Revision 1.2  2005/08/28 10:02:37  max
 * Handle types list in search criterias.
 * Add -updateFolded, -buildTree:force: and -refreshList methods.
 * Totally reworked to make possible to fold/unfold types.
 * Many more infos available for each type.
 * Correct long clic display bug.
 * When short clic on a type with is no transaction behind, display the
 * long clic message.
 *
 * Revision 1.1  2005/08/20 13:06:35  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_STATSTYPESCROLLLIST
#include "StatsTypeScrollList.h"

#include "MaTirelire.h"

#include "StatsPeriodScrollList.h"
#include "ProgressBar.h"
#include "ExportForm.h"

#include "float.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX


static void __statstype_draw(void *pv_table, Int16 h_row, Int16 h_col,
			     RectangleType *prec_bounds)
{
  StatsTypeScrollList *oTypeScrollList = ScrollListGetPtr(pv_table);
  Type *oTypes;
  struct s_type *ps_type;
  struct s_stats_type *ps_type_info;
  struct __s_one_type *ps_one_type;
  UChar *pua_cache;
  RectangleType s_bounds;
  t_amount l_sum;
  Int16 h_depth;
  UInt16 uh_glyphs_width, uh_x, uh_y, uh_flags;

  ps_one_type = ((struct __s_edit_list_type_buf*)
		 MemHandleLock(oTypeScrollList->vh_tree))->rs_list2id;
  ps_one_type += TblGetRowID((TableType*)pv_table, h_row);

  ps_type_info = MemHandleLock(oTypeScrollList->vh_infos);

  // On se sert de notre cache pour retrouver le type à partir de son ID
  pua_cache = MemHandleLock(oTypeScrollList->vh_cache);
  ps_type_info += pua_cache[ps_one_type->ui_id];
  MemHandleUnlock(oTypeScrollList->vh_cache);

  MemMove(&s_bounds, prec_bounds, sizeof(s_bounds));

  // Place prise par le dessin de l'arborescence (5 pixels par élément)
  h_depth = ps_one_type->ui_depth;
  uh_glyphs_width = h_depth * GLYPH_WIDTH;

  // Dessin de l'arborescence juste avant le nom...
  uh_x = s_bounds.topLeft.x;
  uh_y = s_bounds.topLeft.y;

  h_depth--;
  h_depth *= 2;

  if (oMaTirelire->uh_color_enabled)
  {
    WinPushDrawState();

    WinSetBackColor(UIColorGetTableEntryIndex(UIFieldBackground));
    WinSetForeColor(UIColorGetTableEntryIndex(UIObjectForeground));
  }

  oTypes = [oMaTirelire type];

  ps_type = [oTypes getId:ps_one_type->ui_id];

  do
  {
    list_draw_glyph(uh_x, uh_y, s_bounds.extent.y,
		    ((ps_one_type->ui_depth_glyphs >> h_depth)
		     & DEPTH_GLYPH_MASK)
		    // Type replié
		    | (ps_type->ui_folded << 15)
		    // Type avec fils
		    | ((ps_type->ui_child_id != TYPE_UNFILED) << 14));

    h_depth -= 2;
    uh_x += GLYPH_WIDTH;
  }
  while (h_depth >= 0);

  if (oMaTirelire->uh_color_enabled)
    WinPopDrawState();

  uh_x++;		// Jonction avec le texte

  s_bounds.extent.x -= uh_x - s_bounds.topLeft.x;
  s_bounds.topLeft.x = uh_x;

  uh_flags = 0;
  if (ps_type_info->uh_selected)
    uh_flags |= DRAW_SUM_SELECTED;

  // La somme change selon que le type est replié ou non
  l_sum = ps_type_info->uh_folded
    ? ps_type_info->l_sum_with_children : ps_type_info->l_sum;

  // Si on doit ignorer les montants nuls, mais qu'on en a un quand
  // même (type avec des sous-types non nuls), on n'affiche pas la
  // somme
  if (l_sum == 0 && oTypeScrollList->b_ignore_nulls)
    uh_flags = DRAW_SUM_NO_AMOUNT;

  draw_sum_line(ps_type->ra_name, l_sum, &s_bounds, uh_flags);

  [oTypes getFree:ps_type];

  MemHandleUnlock(oTypeScrollList->vh_infos);
  MemHandleUnlock(oTypeScrollList->vh_tree);
}


@implementation StatsTypeScrollList


- (StatsTypeScrollList*)free
{
  if (self->vh_tree != NULL)
    MemHandleFree(self->vh_tree);

  if (self->vh_cache != NULL)
    MemHandleFree(self->vh_cache);

  return [super free];
}


//
// Les types n'ont pas changé, mais un type vient d'être déplié ou replié
- (void)refreshList
{
  // Initialise self->uh_num_items (+ force la reconstruction de l'arbo)
  [self buildTree:true];

  // Dans le cas où des éléments pris en compte dans la somme ont été
  // cachés, on la recalcule
  if (self->uh_sum_filter != CLIST_SUM_ALL)
    [self computeSum];

  [self computeMaxRootItem];

  [self loadRecords];

  [self redrawList];
}


- (void)updateFolded
{
  if (self->vh_infos != NULL)
  {
    Type *oTypes;
    struct s_type *ps_type;
    struct s_stats_type *ps_type_infos;
    UInt16 index;

    oTypes = [oMaTirelire type];

    ps_type_infos = MemHandleLock(self->vh_infos);

    for (index = self->uh_num_types; index-- > 0; ps_type_infos++)
    {
      ps_type = [oTypes getId:ps_type_infos->uh_id];

      ps_type_infos->uh_folded = ps_type->ui_folded;

      [oTypes getFree:ps_type];
    }

    MemHandleUnlock(self->vh_infos);
  }
}


- (void)buildTree:(Boolean)b_force
{
  UInt16 uh_new_num;

  // Mise à jour de l'info de repli pour chaque type
  [self updateFolded];

  if (self->vh_tree != NULL)
  {
    if (b_force == false)
      return;

    MemHandleFree(self->vh_tree);
  }

  self->vh_tree = (MemHandle)[[oMaTirelire type] listBuildInfos:(void*)-1
						 num:&self->uh_num_items
						 largest:NULL];
  if (self->vh_tree == NULL)
    self->uh_num_items = 0;

  uh_new_num = self->uh_num_items;

  // Il faut ignorer les montants NULL
  // ET au moins une entrée (c'est le cas s'il n'y a pas eu d'erreur
  // d'allocation de mémoire puisqu'on a toujours le type "Unfiled")
  if (self->b_ignore_nulls && uh_new_num > 0)
  {
    struct s_stats_type *ps_type_infos, *ps_base_type_infos;
    struct __s_one_type *ps_base_tree, *ps_end_tree, *ps_tree_type, *ps_tmp;
    UChar *pua_id2list;
    UInt16 uh_glyph_shift;

    ps_base_tree = ((struct __s_edit_list_type_buf*)
		    MemHandleLock(self->vh_tree))->rs_list2id;

    ps_base_type_infos = MemHandleLock(self->vh_infos);
    pua_id2list = MemHandleLock(self->vh_cache);

    ps_end_tree = ps_base_tree + uh_new_num - 1;

    for (ps_tree_type = ps_end_tree;
	 ps_tree_type >= ps_base_tree; ps_tree_type--)
    {
      ps_type_infos = &ps_base_type_infos[pua_id2list[ps_tree_type->ui_id]];

      // Montant nul
      if ((ps_type_infos->uh_folded
	   ? ps_type_infos->l_sum_with_children : ps_type_infos->l_sum) == 0
	  // ET dernier de la liste
	  && (ps_tree_type == ps_end_tree
	      // OU BIEN sans fils le suivant...
	      || ps_tree_type->ui_depth >=  ps_tree_type[1].ui_depth))
      {
	// Si notre dernier "glyph" nous dis que nous sommes le dernier frère
	if ((ps_tree_type->ui_depth_glyphs & DEPTH_GLYPH_MASK)
	    == DEPTH_GLYPH_L)
	{
	  ps_tmp = ps_tree_type;

	  // Tant qu'il y a un type qui nous précède
	  while (ps_tmp-- != ps_base_tree
		 // AVEC au moins la même profondeur
		 && ps_tmp->ui_depth
		 >= ps_tree_type->ui_depth)
	  {
	    // Nombre de bits à décaler pour avoir le "glyph"
	    // correspondant à notre niveau
	    uh_glyph_shift = (ps_tmp->ui_depth - ps_tree_type->ui_depth) *2;

	    switch ((ps_tmp->ui_depth_glyphs >> uh_glyph_shift)
		    & DEPTH_GLYPH_MASK)
	    {
	    case DEPTH_GLYPH_I: // Supprimer et continuer à remonter
	      // On efface
	      ps_tmp->ui_depth_glyphs &= ~(DEPTH_GLYPH_MASK
					   << uh_glyph_shift);
	      break;

	    case DEPTH_GLYPH_T: // Remplacer par L et finir
	      // On remplace par L (qui en fait a tous ses bits à 1,
	      // donc pas besoin d'effacer avant)
	      ps_tmp->ui_depth_glyphs |= (DEPTH_GLYPH_L << uh_glyph_shift);
	      // Et on finit...
	    default:		// Finir...
	      goto glyph_ok;
	    }
	  }
      glyph_ok:
	  ;
	}

	// Il faut supprimer cette entrée
	if (ps_tree_type != ps_end_tree)
	  MemMove(ps_tree_type, ps_tree_type + 1,
		  (Char*)ps_end_tree - (Char*)ps_tree_type);

	uh_new_num--;
	ps_end_tree--;
      }
    }

    MemHandleUnlock(self->vh_cache);
    MemHandleUnlock(self->vh_infos);
    MemHandleUnlock(self->vh_tree);

    // On peut réduire la taille du buffer. On se met après le
    // MemHandleUnlock, ça permet de libérer la zone si on est à 0
    if (uh_new_num < self->uh_num_items)
    {
      // Plus rien, on libère...
      if (uh_new_num == 0)
      {
	MemHandleFree(self->vh_tree);
	self->vh_tree = NULL;
      }
      else
	MemHandleResize(self->vh_tree,
			MemHandleSize(self->vh_tree)
			- ((self->uh_num_items - uh_new_num)
			   * sizeof(struct __s_one_type)));

      self->uh_num_items = uh_new_num;

      // Au moins un item a été supprimé
      self->b_deleted_items = true;
    }
  }
}


// Méthode à appeler lorsque le nombre d'entrées dans la liste a changé
// Alloue le buffer contenant les infos sur les types
// Pour chaque type :
// - initialisation de uh_id
// - initialisation de uh_selected
- (void)initRecordsCount
{
  Type *oTypes;
  struct s_stats_type *ps_type_infos;
  UChar *pua_cache;
  UInt16 uh_id, uh_num_allocated, uh_num_records;  

  if (self->vh_infos != NULL)
  {
    MemHandleFree(self->vh_infos);
    MemHandleFree(self->vh_cache);
  }

  if (self->vh_tree != NULL)
  {
    MemHandleFree(self->vh_tree);
    self->vh_tree = NULL;	// Pour qu'il soit réalloué automatiquement
  }

  oTypes = [oMaTirelire type];

  uh_num_records = DmNumRecords(oTypes->db);

  uh_num_allocated = uh_num_records + 1;
  if (uh_num_allocated > NUM_TYPES)
    uh_num_allocated = NUM_TYPES;

  NEW_HANDLE(self->vh_infos, uh_num_allocated * sizeof(struct s_stats_type),
	     ({
	       self->vh_cache = NULL;
	       self->uh_num_items = self->uh_num_types = 0;
	       return;
	     }));

  NEW_HANDLE(self->vh_cache, NUM_TYPES * sizeof(UChar),
	     ({
	       MemHandleFree(self->vh_infos);
	       self->vh_infos = NULL;
	       self->uh_num_items = self->uh_num_types = 0;
	       return;
	     }));

  pua_cache = MemHandleLock(self->vh_cache);
  MemSet(pua_cache, NUM_TYPES * sizeof(UChar), '\0');

  ps_type_infos = MemHandleLock(self->vh_infos);

  // Inutile d'initialiser la zone, ça sera fait dans
  // -computeEachEntryConvertSum

  // Parcours de tous les types, dans l'ordre de l'arborescence
  self->uh_num_types = 0;
  if (oTypes->uh_first_id != TYPE_UNFILED)
  {
    struct s_type *ps_type;

    ps_type = [oTypes getId:oTypes->uh_first_id];

    for (;;)
    {
      pua_cache[ps_type->ui_id] = self->uh_num_types++;

      ps_type_infos->uh_id = ps_type->ui_id;
      ps_type_infos->uh_selected = 0;

      ps_type_infos++;

      // Si on a un fils
      uh_id = ps_type->ui_child_id;
      if (uh_id != TYPE_UNFILED)
      {
    load_and_continue:
	[oTypes getFree:ps_type];
	ps_type = [oTypes getId:uh_id];

	continue;
      }

      // Sinon, si on a un frère
  brother:
      uh_id = ps_type->ui_brother_id;
      if (uh_id != TYPE_UNFILED)
	goto load_and_continue;

      // Sinon, si on a un père => on passe à son frère OU à son père...
      uh_id = ps_type->ui_parent_id;
      if (uh_id != TYPE_UNFILED)
      {
	[oTypes getFree:ps_type];
	ps_type = [oTypes getId:uh_id];

	goto brother;
      }

      // Sinon c'est fini...
      [oTypes getFree:ps_type];

      break;
    }
  }

  // Et le type "Unfiled"
  pua_cache[TYPE_UNFILED] = self->uh_num_types++;

  ps_type_infos->uh_id = TYPE_UNFILED;
  ps_type_infos->uh_selected = 0;

  MemHandleUnlock(self->vh_infos);
  MemHandleUnlock(self->vh_cache);

  if (self->uh_num_types < uh_num_allocated)
    MemHandleResize(self->vh_infos,
		    self->uh_num_types * sizeof(struct s_stats_type));

  // On passe à papa qui va calculer les sommes de chaque type
  [super initRecordsCount];
}


// -computeEachEntrySum appelle -computeEachEntryConvertSum dans la
// classe SumScrollList... On laisse faire.

//
// Pour chaque type :
// - initialisation l_sum
// - initialisation l_sum_with_children
// - initialisation uh_num_op
// - initialisation uh_num_op_with_children
// - initialisation ui_num_split_op
// - initialisation ui_num_split_op_with_children
// - initialisation uh_accounts
// - initialisation uh_accounts_with_children
// - initialisation uh_num_children
- (void)computeEachEntryConvertSum
{
  struct s_stats_type *ps_type_infos;
  struct s_private_search_type s_search_infos;
  UInt16 index;

  if (self->vh_infos == NULL)
    return;

  // Pour chaque type
  ps_type_infos = s_search_infos.ps_base_type_infos
    = MemHandleLock(self->vh_infos);

  for (index = self->uh_num_types; index-- > 0; ps_type_infos++)
  {
    ps_type_infos->l_sum = 0;
    ps_type_infos->l_sum_with_children = 0;

    ps_type_infos->uh_num_op = 0;
    ps_type_infos->uh_num_op_with_children = 0;

    ps_type_infos->ui_num_split_op = 0;
    ps_type_infos->ui_num_split_op_with_children = 0;

    ps_type_infos->uh_accounts = 0;
    ps_type_infos->uh_accounts_with_children = 0;

    ps_type_infos->uh_num_children = 0;

    // Ce champ ne sert que dans -searchMatch:
    ps_type_infos->uh_add_to_num_op = 0;
  }

  s_search_infos.pua_id2list = MemHandleLock(self->vh_cache);

  // Pour notre/nos méthodes appelées durant -search
  self->ps_search_type_infos = &s_search_infos;

  // On fait la recherche et dès qu'au moins un type matche dans une
  // sous-opération on valide le test de type sans se préoccuper de la
  // somme totale, tout ça sera calculé plus bas dans -searchMatch:
  self->b_ignore_nulls = [self searchFrom:0 amount:true];

  // On calcule les sommes des fils pour chaque type
  {
    Type *oTypes = [oMaTirelire type];
    struct s_type *ps_type;

    // On parcourt à l'envers, et pour chaque type on additionne sa
    // propre somme à celle des fils de son père
    for (ps_type_infos =&s_search_infos.ps_base_type_infos[self->uh_num_types];
	 ps_type_infos-- > s_search_infos.ps_base_type_infos; )
    {
      ps_type = [oTypes getId:ps_type_infos->uh_id];

      // On ajoute la propre somme du type à celle de ces fils
      ps_type_infos->l_sum_with_children += ps_type_infos->l_sum;
      ps_type_infos->uh_num_op_with_children += ps_type_infos->uh_num_op;
      ps_type_infos->ui_num_split_op_with_children
	+= ps_type_infos->ui_num_split_op;
      ps_type_infos->uh_accounts_with_children |= ps_type_infos->uh_accounts;

      // S'il y a un parent, on additionne notre somme à celle de ses fils
      if (ps_type->ui_parent_id != TYPE_UNFILED)
      {
	struct s_stats_type *ps_parent_infos;

	ps_parent_infos = &s_search_infos.ps_base_type_infos
	  [s_search_infos.pua_id2list[ps_type->ui_parent_id]];

	ps_parent_infos->l_sum_with_children
	  += ps_type_infos->l_sum_with_children;

	ps_parent_infos->uh_num_op_with_children
	  += ps_type_infos->uh_num_op_with_children;

	ps_parent_infos->ui_num_split_op_with_children
	  += ps_type_infos->ui_num_split_op_with_children;

	ps_parent_infos->uh_accounts_with_children
	  |= ps_type_infos->uh_accounts_with_children;

	// + 1 pour type lui-même
	ps_parent_infos->uh_num_children += ps_type_infos->uh_num_children + 1;
      }

      [oTypes getFree:ps_type];
    }
  }

  MemHandleUnlock(self->vh_cache);
  MemHandleUnlock(self->vh_infos);

  // On construit l'arborescence (seulement si besoin)
  [self buildTree:false];

  // On passe à papa qui va convertir les sommes de chaque type dans
  // la monnaie demandée...
  [super computeEachEntryConvertSum];
}


// Appelé par -searchFrom:amount:
//
// ps_infos->l_amount est le montant de l'opération, dans la monnaie
// de l'opération. Le montant complet, pas une somme de
// sous-opérations, puisque dans cette classe on appelle
// -searchFrom:amount: avec true comme argument pour ne justement pas
// gérer cette somme...
- (Boolean)searchMatch:(struct s_search_infos*)ps_infos
{
  struct s_stats_type *ps_type_infos, *ps_base_type_infos;

  // Ici l'opération a matché

  ps_base_type_infos = self->ps_search_type_infos->ps_base_type_infos;

  // S'il y a une ventilation
  if (ps_infos->ps_tr->ui_rec_splits)
  {
    t_amount l_splits_sum = 0, l_remain_amount, l_orig_amount;
    FOREACH_SPLIT_DECL; // __uh_num et ps_cur_split
    Boolean b_neg = ps_infos->l_amount < 0; // Juste le signe nous interresse
    Boolean b_all_types = false;

    // Les options n'ont peut-être pas été calculées
    if (ps_infos->s_options.pa_note == NULL)
      options_extract((struct s_transaction*)ps_infos->ps_tr,
		      &ps_infos->s_options);

    // On parcourt toutes les sous-opérations, en gérant le critère de
    // recherche sur le type s'il existe

    l_orig_amount = ps_infos->l_amount;

    //
    // Critères pour plusieurs types
    if (ps_infos->s_search_criteria.pul_types != NULL
	// OU BIEN n'importe quel type
	|| (b_all_types = (ps_infos->s_search_criteria.h_one_type < 0)))
    {
      // Pour chaque sous-opération
      FOREACH_SPLIT(&ps_infos->s_options)
      {
	// Le type correspond
	if (b_all_types || BIT_ISSET(ps_cur_split->ui_type,
				     ps_infos->s_search_criteria.pul_types))
	{
	  ps_type_infos = &ps_base_type_infos
	    [self->ps_search_type_infos->pua_id2list[ps_cur_split->ui_type]];

	  ps_type_infos->ui_num_split_op++;
	  // Pour mettre à jour uh_num_op à la fin...
	  ps_type_infos->uh_add_to_num_op = 1;

	  // Il faut convertir dans la monnaie du formulaire
	  ps_infos->l_amount
	    = b_neg ? - ps_cur_split->l_amount : ps_cur_split->l_amount;
	  [super searchMatch:ps_infos];
	  ps_type_infos->l_sum += ps_infos->l_amount;
	}

	l_splits_sum += ps_cur_split->l_amount;
      }

      // Reste
      l_remain_amount = ABS(l_orig_amount) - l_splits_sum;

      //
      // S'il y a une ventilation avec un reste nul, le type de l'opération
      // n'est pris en compte que si le type n'est pas "Unfiled"
      // Donc s'il n'y a pas de reste ET que le type est "Unfiled", on
      // ignore.
      // À noter que le reste est forcément toujours positif !!!
      // l'inverse étant interdit !!!
      if ((ps_infos->ps_tr->ui_rec_type != TYPE_UNFILED || l_remain_amount > 0)
	  // ET que le type de l'opération correspond...
	  && (b_all_types || BIT_ISSET(ps_infos->ps_tr->ui_rec_type,
				       ps_infos->s_search_criteria.pul_types)))
      {
	ps_type_infos = &ps_base_type_infos
	  [self->ps_search_type_infos
	       ->pua_id2list[ps_infos->ps_tr->ui_rec_type]];

	// On considère le reste comme une sous-opération...
	ps_type_infos->ui_num_split_op++;
	// Pour mettre à jour uh_num_op à la fin...
	ps_type_infos->uh_add_to_num_op = 1;

	// Il faut convertir dans la monnaie du formulaire
	ps_infos->l_amount = b_neg ? - l_remain_amount : l_remain_amount;
	[super searchMatch:ps_infos];
	ps_type_infos->l_sum += ps_infos->l_amount;
      }

      // Pour bien comptabiliser uh_num_op pour chaque type, on refait
      // une passe. Ceci pour gérer le cas où une opération aurait
      // plusieurs sous-opération avec le même type
      ps_type_infos = ps_base_type_infos;
      {
	UInt16 uh_account_mask = (1 << ps_infos->uh_account);
	UInt16 index;

	for (index = self->uh_num_types; index-- > 0; ps_type_infos++)
	  if (ps_type_infos->uh_add_to_num_op)
	  {
	    ps_type_infos->uh_num_op++;
	    ps_type_infos->uh_add_to_num_op = 0;
	    ps_type_infos->uh_accounts |= uh_account_mask;
	  }
      }
    }
    //
    // Critère pour un seul type : on n'accepte que ce type
    else
    {
      UInt16 uh_type = ps_infos->s_search_criteria.h_one_type;

      // Ça sera toujours les mêmes infos, on ne les charge qu'une fois
      ps_type_infos
	= &ps_base_type_infos[self->ps_search_type_infos->pua_id2list[uh_type]];

      // Pour chaque sous-opération
      FOREACH_SPLIT(&ps_infos->s_options)
      {
	// Le type correspond
	if (ps_cur_split->ui_type == uh_type)
	{
	  ps_type_infos->ui_num_split_op++;

	  // Il faut convertir dans la monnaie du formulaire
	  ps_infos->l_amount
	    = b_neg ? - ps_cur_split->l_amount : ps_cur_split->l_amount;
	  [super searchMatch:ps_infos];
	  ps_type_infos->l_sum += ps_infos->l_amount;
	}

	l_splits_sum += ps_cur_split->l_amount;
      }

      // Le type de l'opération correspond, on regarde s'il y a un reste
      if (ps_infos->ps_tr->ui_rec_type == uh_type)
      {
	// Reste
	l_remain_amount = ABS(l_orig_amount) - l_splits_sum;

	//
	// S'il y a une ventilation avec un reste nul, le type de l'opération
	// n'est pris en compte que si le type n'est pas "Unfiled"
	// Donc s'il n'y a pas de reste ET que le type est "Unfiled", on
	// ignore.
	// À noter que le reste est forcément toujours positif !!!
	// l'inverse étant interdit !!!
	if (ps_infos->ps_tr->ui_rec_type != TYPE_UNFILED || l_remain_amount > 0)
	{
	  // On considère le reste comme une sous-opération...
	  ps_type_infos->ui_num_split_op++;

	  // Il faut convertir dans la monnaie du formulaire
	  ps_infos->l_amount = b_neg ? - l_remain_amount : l_remain_amount;
	  [super searchMatch:ps_infos];
	  ps_type_infos->l_sum += ps_infos->l_amount;
	}
      }

      ps_type_infos->uh_num_op++;
      ps_type_infos->uh_accounts |= (1 << ps_infos->uh_account);
    }
  }
  // Il n'y a pas de ventilation
  else
  {
    // Ici ps_infos->l_amount est correct, il faut juste le convertir
    // dans la monnaie du formulaire
    [super searchMatch:ps_infos];

    ps_type_infos
      = &ps_base_type_infos[self->ps_search_type_infos->pua_id2list[ps_infos->ps_tr->ui_rec_type]];

    ps_type_infos->l_sum += ps_infos->l_amount;
    ps_type_infos->uh_num_op++;
    ps_type_infos->uh_accounts |= (1 << ps_infos->uh_account);
  }

  return false;
}


//
// - initialise self->l_sum
- (void)computeSum
{
  t_amount l_sum = 0;

  if (self->vh_infos != NULL && self->vh_tree != NULL)
  {
    struct s_stats_type *ps_type_infos, *ps_base_infos;
    struct __s_one_type *ps_one_type;
    UChar *pua_cache;
    UInt16 uh_index, uh_comp;

    ps_one_type =
      ((struct __s_edit_list_type_buf*)MemHandleLock(self->vh_tree))
      ->rs_list2id;

    ps_base_infos = MemHandleLock(self->vh_infos);
    pua_cache = MemHandleLock(self->vh_cache);

    // Si sum_type == ALL (0)        => -1 ==> 0xffff (XOR 1 != 0 / XOR 0 != 0)
    // Si sum_type == SELECT (1)     => 0
    // Si sum_type == NON_SELECT (2) => 1
    uh_comp = self->uh_sum_filter - 1;

    for (uh_index = self->uh_num_items; uh_index-- > 0; ps_one_type++)
    {
      ps_type_infos = &ps_base_infos[pua_cache[ps_one_type->ui_id]];

      if (uh_comp ^ ps_type_infos->uh_selected)
      {
	if (ps_type_infos->uh_folded)
	  l_sum += ps_type_infos->l_sum_with_children;
	else
	  l_sum += ps_type_infos->l_sum;
      }
    }

    MemHandleUnlock(self->vh_cache);
    MemHandleUnlock(self->vh_infos);
    MemHandleUnlock(self->vh_tree);
  }

  self->l_sum = l_sum;
}


- (void)initColumns
{
  self->pf_line_draw = __statstype_draw;

  self->uh_flags = SCROLLLIST_BOTTOP | SCROLLLIST_FULL;

  [super initColumns];
}


//
// Un clic long vient d'être détecté sur la ligne uh_row
// Pas d'action par défaut => mais pas d'erreur...
// Renvoie le WinHandle correspondant à la zone à restaurer.
// - uh_row est la ligne de la table qui a subit le clic long ;
// - pp_top_left est l'adresse à laquelle le coin supérieur gauche de
//   la zone sauvée doit être stocké (le champ y est initialisé à
//   l'ordonnée du stylet pressé à l'appel) ;
- (WinHandle)longClicOnRow:(UInt16)uh_row topLeftIn:(PointType*)pp_win
{
  Type *oTypes;
  struct s_stats_type *ps_type_infos;
  struct __s_one_type *ps_one_type;
  UChar *pua_cache;
  Char *pa_fullname, *pa_accounts, *pa_accounts_wc, *pa_cur;
  WinHandle win_handle = NULL;
  RectangleType rec_win;
  UInt16 uh_save_font, uh_hfont, uh_lines, uh_req_lines, uh_dummy;
  UInt16 uh_type_lines, uh_type_len;
  UInt16 uh_accounts_lines, uh_accounts_wc_lines, uh_len;

  ps_one_type =
    ((struct __s_edit_list_type_buf*)MemHandleLock(self->vh_tree))
    ->rs_list2id;

  ps_one_type += TblGetRowID(self->pt_table, uh_row);

  ps_type_infos = MemHandleLock(self->vh_infos);

  // On se sert de notre cache pour retrouver le type à partir de son ID
  pua_cache = MemHandleLock(self->vh_cache);
  ps_type_infos += pua_cache[ps_one_type->ui_id];
  MemHandleUnlock(self->vh_cache);

  oTypes = [oMaTirelire type];
  pa_fullname = [oTypes fullNameOfId:ps_one_type->ui_id	len:&uh_type_len];
  if (pa_fullname == NULL)
  {
    // XXX
    goto end2;
  }

  WinGetWindowExtent(&rec_win.extent.x, &uh_dummy);

  uh_save_font = FntSetFont(stdFont);

  pa_accounts = NULL;
  uh_accounts_lines = 0;
  if (ps_type_infos->uh_accounts != 0)
  {
    pa_accounts = [[oMaTirelire transaction]
		    getCategoriesNamesForMask:ps_type_infos->uh_accounts
		    retLen:&uh_len retNum:&uh_dummy];
    if (pa_accounts == NULL)
    {
      // XXX
      goto end1;
    }

    uh_accounts_lines = FldCalcFieldHeight(pa_accounts,
					   rec_win.extent.x - 3 - 2);
  }

  pa_accounts_wc = NULL;
  uh_accounts_wc_lines = 0;
  if (ps_type_infos->uh_num_children > 0)
  {
    // Comptes pour les fils
    if (ps_type_infos->uh_accounts == ps_type_infos->uh_accounts_with_children)
    {
      pa_accounts_wc = pa_accounts;
      uh_accounts_wc_lines = uh_accounts_lines;
    }
    else
    {
      // Pas la peine de comparer uh_accounts_with_children à 0,
      // puisqu'il contient au moins uh_accounts

      pa_accounts_wc = [[oMaTirelire transaction]
			 getCategoriesNamesForMask:
			   ps_type_infos->uh_accounts_with_children
			 retLen:&uh_len retNum:&uh_dummy];
      if (pa_accounts_wc == NULL)
      {
	// XXX
	goto end0;
      }

      uh_accounts_wc_lines = FldCalcFieldHeight(pa_accounts_wc,
						rec_win.extent.x - 3 - 2);
    }
  }

  FntSetFont(boldFont);

  uh_type_lines = FldCalcFieldHeight(pa_fullname, rec_win.extent.x - 3 - 2);

  uh_hfont = FntLineHeight();

  uh_lines = (uh_type_lines	// Le nom complet du type
	      + 1		// La somme avec la devise du formulaire
	      + 1		// Nombre d'opérations
	      + (ps_type_infos->ui_num_split_op > 0) // Nombre sous-opérations
	      + uh_accounts_lines); // Le nom des comptes concernés

  // Si le type a au moins un fils
  if (ps_type_infos->uh_num_children > 0)
    uh_lines += (1		// Nombre de sous-types
		 + 1		// La somme avec la devise du formulaire
		 + 1		// Nombre d'opérations
		 + (ps_type_infos->ui_num_split_op_with_children > 0) // ss-op.
		 + uh_accounts_wc_lines); // Le nom des comptes concernés

  uh_req_lines = uh_lines;

  win_handle = DrawFrame(pp_win, &uh_lines, uh_hfont, &rec_win,
			 oMaTirelire->uh_color_enabled);
  if (win_handle != NULL)
  {
    Char ra_tmp[32];
    UInt16 uh_y, uh_len;

    // Pas assez de place pour toutes les lignes
    if (uh_lines < uh_req_lines)
    {
      MemPtrFree(pa_fullname);

      pa_fullname = [oTypes fullNameOfId:ps_one_type->ui_id
			    len:&uh_type_len
			    truncatedTo:rec_win.extent.x - 3 - 2];

      uh_req_lines -= uh_type_lines + 1;
      uh_type_lines = 1;

      // Il manque toujours de la place
      if (uh_lines < uh_req_lines)
      {
	uh_req_lines -= uh_lines;

	// XXX réduction de uh_accounts_lines ET de
	// uh_accounts_wc_lines à faire XXX
      }
    }

    uh_y = rec_win.topLeft.y;

    // On affiche le type
    pa_cur = pa_fullname;
    while (uh_type_lines-- > 0)
    {
      uh_len = FldWordWrap(pa_cur, rec_win.extent.x - 3 - 2);
      if (uh_len > 0)
      {
	WinDrawChars(pa_cur, uh_len - (pa_cur[uh_len - 1] == '\n'),
		     rec_win.topLeft.x, uh_y);
	pa_cur += uh_len;
      }
      uh_y += uh_hfont;
    }

    FntSetFont(stdFont);

    // On affiche la somme avec la devise
    {
      UInt16 uh_x = rec_win.topLeft.x;

      // La somme
      Str100FToA(ra_tmp, ps_type_infos->l_sum, &uh_len,
		 oMaTirelire->s_misc_infos.a_dec_separator);
      WinDrawChars(ra_tmp, uh_len, uh_x, uh_y);
      uh_x += FntCharsWidth(ra_tmp, uh_len);

      // La devise
      pa_cur = [[oMaTirelire currency]
		 fullNameOfId:((CustomListForm*)self->oForm)->uh_currency
		 len:&uh_len];
      if (pa_cur != NULL)
      {
	WinDrawChars(pa_cur, uh_len, uh_x, uh_y);
	MemPtrFree(pa_cur);
      }

      uh_y += uh_hfont;
    }

    // On affiche le nombre d'opérations du type
    if (ps_type_infos->uh_num_op > 1)
    {
      Char ra_format[32];

      SysCopyStringResource(ra_format, strClistAccountsManyOp);
      StrPrintF(ra_tmp, ra_format, ps_type_infos->uh_num_op);
    }
    else
      SysCopyStringResource(ra_tmp, ps_type_infos->uh_num_op
                            ? strClistAccountsOneOp : strClistAccountsZeroOp);

    WinDrawChars(ra_tmp, StrLen(ra_tmp), rec_win.topLeft.x, uh_y);

    // On affiche les comptes
    if (pa_accounts)
    {
      pa_cur = pa_accounts;
      while (uh_accounts_lines-- > 0)
      {
	uh_y += uh_hfont;
	uh_len = FldWordWrap(pa_cur, rec_win.extent.x - 3 - 2);
	if (uh_len > 0)
	{
	  WinDrawChars(pa_cur, uh_len - (pa_cur[uh_len - 1] == '\n'),
		       rec_win.topLeft.x, uh_y);
	  pa_cur += uh_len;
	}
      }
    }

    // On affiche le nombre de sous-opérations du type
    if (ps_type_infos->ui_num_split_op > 0)
    {
      uh_y += uh_hfont;

      if (ps_type_infos->ui_num_split_op > 1)
      {
	Char ra_format[32];

	SysCopyStringResource(ra_format, strClistTypeManySplitOp);
	StrPrintF(ra_tmp, ra_format, ps_type_infos->ui_num_split_op);
      }
      else
	SysCopyStringResource(ra_tmp, strClistTypeOneSplitOp);

      WinDrawChars(ra_tmp, StrLen(ra_tmp), rec_win.topLeft.x, uh_y);
    }

    //
    // S'il y a au moins un fils
    if (ps_type_infos->uh_num_children > 0)
    {
      uh_y += uh_hfont;

      FntSetFont(boldFont);

      // Le nombre de fils
      if (ps_type_infos->uh_num_children > 1)
      {
	Char ra_format[32];

	SysCopyStringResource(ra_format, strClistTypesNSubTypes);
	StrPrintF(ra_tmp, ra_format, ps_type_infos->uh_num_children);
      }
      else
	SysCopyStringResource(ra_tmp, strClistTypesOneSubType);

      WinDrawChars(ra_tmp, StrLen(ra_tmp), rec_win.topLeft.x, uh_y);

      FntSetFont(stdFont);

      //
      // XXX recopie pas propre XXX
      //
      uh_y += uh_hfont;

      // On affiche la somme avec la devise
      {
	UInt16 uh_x = rec_win.topLeft.x;

	// La somme
	Str100FToA(ra_tmp, ps_type_infos->l_sum_with_children, &uh_len,
		   oMaTirelire->s_misc_infos.a_dec_separator);
	WinDrawChars(ra_tmp, uh_len, uh_x, uh_y);
	uh_x += FntCharsWidth(ra_tmp, uh_len);

	// La devise
	pa_cur = [[oMaTirelire currency]
		   fullNameOfId:((CustomListForm*)self->oForm)->uh_currency
		   len:&uh_len];
	if (pa_cur != NULL)
	{
	  WinDrawChars(pa_cur, uh_len, uh_x, uh_y);
	  MemPtrFree(pa_cur);
	}

	uh_y += uh_hfont;
      }

      // On affiche le nombre d'opérations du type
      if (ps_type_infos->uh_num_op_with_children > 1)
      {
	Char ra_format[32];

	SysCopyStringResource(ra_format, strClistAccountsManyOp);
	StrPrintF(ra_tmp, ra_format, ps_type_infos->uh_num_op_with_children);
      }
      else
	SysCopyStringResource(ra_tmp, ps_type_infos->uh_num_op_with_children
			      ? strClistAccountsOneOp :strClistAccountsZeroOp);

      WinDrawChars(ra_tmp, StrLen(ra_tmp), rec_win.topLeft.x, uh_y);

      // On affiche les comptes
      if (pa_accounts_wc)
      {
	pa_cur = pa_accounts_wc;
	while (uh_accounts_wc_lines-- > 0)
	{
	  uh_y += uh_hfont;
	  uh_len = FldWordWrap(pa_cur, rec_win.extent.x - 3 - 2);
	  if (uh_len > 0)
	  {
	    WinDrawChars(pa_cur, uh_len - (pa_cur[uh_len - 1] == '\n'),
			 rec_win.topLeft.x, uh_y);
	    pa_cur += uh_len;
	  }
	}
      }

      // On affiche le nombre de sous-opérations du type
      if (ps_type_infos->ui_num_split_op_with_children > 0)
      {
	uh_y += uh_hfont;

	if (ps_type_infos->ui_num_split_op_with_children > 1)
	{
	  Char ra_format[32];

	  SysCopyStringResource(ra_format, strClistTypeManySplitOp);
	  StrPrintF(ra_tmp, ra_format,
		    ps_type_infos->ui_num_split_op_with_children);
	}
	else
	  SysCopyStringResource(ra_tmp, strClistTypeOneSplitOp);

	WinDrawChars(ra_tmp, StrLen(ra_tmp), rec_win.topLeft.x, uh_y);
      }
    }

    // Sauvé par DrawFrame()
    if (oMaTirelire->uh_color_enabled)
      WinPopDrawState();
  }

  if (pa_accounts_wc && pa_accounts_wc != pa_accounts)
    MemPtrFree(pa_accounts_wc);

 end0:
  if (pa_accounts)
    MemPtrFree(pa_accounts);

 end1:
  FntSetFont(uh_save_font);

  MemPtrFree(pa_fullname);

 end2:
  MemHandleUnlock(self->vh_infos);
  MemHandleUnlock(self->vh_tree);

  return win_handle;
}


- (Boolean)shortClicOnLabelOfRow:(UInt16)uh_row xPos:(UInt16)uh_x
{
  Type *oTypes;
  struct s_stats_type *ps_type_infos;
  struct __s_one_type *ps_one_type;
  UChar *pua_cache;
  RectangleType s_bounds;
  UInt16 uh_depth_x;

  ps_one_type =
    ((struct __s_edit_list_type_buf*)MemHandleLock(self->vh_tree))
    ->rs_list2id;

  ps_one_type += TblGetRowID(self->pt_table, uh_row);

  oTypes = [oMaTirelire type];

  //
  // On regarde si le clic n'a pas eu lieu à l'endroit du dépliement
  FrmGetObjectBounds(self->oForm->pt_frm,
		     FrmGetObjectIndex(self->oForm->pt_frm, self->uh_table),
		     &s_bounds);

  uh_depth_x = s_bounds.topLeft.x + ps_one_type->ui_depth * GLYPH_WIDTH;

  if (uh_x < uh_depth_x && uh_x >= uh_depth_x - 7
      && [oTypes foldId:ps_one_type->ui_id])
  {
    MemHandleUnlock(self->vh_tree);

    [self refreshList];

    return true;
  }

  ps_type_infos = MemHandleLock(self->vh_infos);

  // On se sert de notre cache pour retrouver le type à partir de son ID
  pua_cache = MemHandleLock(self->vh_cache);
  ps_type_infos += pua_cache[ps_one_type->ui_id];
  MemHandleUnlock(self->vh_cache);

  //
  // Pour que StatsTransScrollList puisse savoir sur quel type se baser
  if (ps_type_infos->uh_folded)
  {
    if (ps_type_infos->uh_num_op_with_children == 0)
      goto nothing_to_view;

    // Tous les fils du type à mettre à 1 dans rul_types
    if ([oTypes setBitFamily:self->rul_types forType:ps_one_type->ui_id] == 1)
      self->h_type = ps_one_type->ui_id;
    else
      self->h_type = -1;
  }
  else
  {
    if (ps_type_infos->uh_num_op == 0)
    {
  nothing_to_view:
      MemHandleUnlock(self->vh_infos);
      MemHandleUnlock(self->vh_tree);

      // Les infos du clic long
      [self displayLongClicInfoWithTimeoutForRow:uh_row timeout:0];

      return true;
    }

    self->h_type = ps_one_type->ui_id;
  }

  MemHandleUnlock(self->vh_infos);
  MemHandleUnlock(self->vh_tree);

  FrmPopupForm(CustomListFormIdx | CLIST_SUBFORM_TRANS_STATS);

  return true;
}


//
// Renvoie -1 si rien n'a bougé
// Renvoie 1 si la somme a été sélectionnée (passage de 0 à 1)
// Renvoie 3 si pareil mais qu'il faut redessiner la somme complètement
// Renvoie 0 si la somme a été désélectionnée (passage de 1 à 0)
- (Int16)shortClicOnSumOfRow:(UInt16)uh_row xPos:(UInt16)uh_x
		      amount:(t_amount*)pl_amount
{
  struct s_stats_type *ps_type_infos;
  struct __s_one_type *ps_one_type;
  UChar *pua_cache;
  Boolean b_new_select_state;

  ps_one_type =
    ((struct __s_edit_list_type_buf*)MemHandleLock(self->vh_tree))
    ->rs_list2id;

  ps_one_type += TblGetRowID(self->pt_table, uh_row);

  ps_type_infos = MemHandleLock(self->vh_infos);

  // On se sert de notre cache pour retrouver le type à partir de son ID
  pua_cache = MemHandleLock(self->vh_cache);
  ps_type_infos += pua_cache[ps_one_type->ui_id];
  MemHandleUnlock(self->vh_cache);

  // Type replié
  if (ps_type_infos->uh_folded)
  {
    if (ps_type_infos->l_sum_with_children == 0
	&& [oMaTirelire transaction]->ps_prefs->rs_stats[0].ui_ignore_nulls)
    {
  short_clic_on_label:
      MemHandleUnlock(self->vh_infos);
      MemHandleUnlock(self->vh_tree);

      [self shortClicOnLabelOfRow:uh_row xPos:uh_x];

      return -1;
    }

    *pl_amount = ps_type_infos->l_sum_with_children;
  }
  // Type déplié
  else
  {
    if (ps_type_infos->l_sum == 0
	&& [oMaTirelire transaction]->ps_prefs->rs_stats[0].ui_ignore_nulls)
      goto short_clic_on_label;

    *pl_amount = ps_type_infos->l_sum;
  }

  b_new_select_state = (ps_type_infos->uh_selected ^= 1);

  MemHandleUnlock(self->vh_infos);
  MemHandleUnlock(self->vh_tree);

  return b_new_select_state;
}


- (void)selectChange:(Int16)h_action
{
  struct s_stats_type *ps_type_infos;
  UInt16 index;

  if (self->vh_infos == NULL)
    return;

  ps_type_infos = MemHandleLock(self->vh_infos);

  // Invert
  if (h_action < 0)
    for (index = self->uh_num_types; index-- > 0; ps_type_infos++)
      ps_type_infos->uh_selected ^= 1;
  // UnsetAll OR SetAll
  else
    for (index = self->uh_num_types; index-- > 0; ps_type_infos++)
      ps_type_infos->uh_selected = h_action;

  MemHandleUnlock(self->vh_infos);

  [super selectChange:h_action];
}


- (UInt16)exportFormat:(Char*)pa_format
{
  if (pa_format != NULL)
    StrCopy(pa_format, "sfb");

  return strExportHeadersStatsTypes;
}


- (void)exportLine:(UInt16)uh_line with:(id)oExportForm
{
  Type *oTypes;
  struct s_type *ps_type;
  struct s_stats_type *ps_type_info;
  struct __s_one_type *ps_one_type;
  UChar *pua_cache;
  t_amount l_sum;
  Char *pa_fullname;

  ps_one_type = ((struct __s_edit_list_type_buf*)
		 MemHandleLock(self->vh_tree))->rs_list2id;
  ps_one_type += uh_line;

  ps_type_info = MemHandleLock(self->vh_infos);

  // On se sert de notre cache pour retrouver le type à partir de son ID
  pua_cache = MemHandleLock(self->vh_cache);
  ps_type_info += pua_cache[ps_one_type->ui_id];
  MemHandleUnlock(self->vh_cache);

  oTypes = [oMaTirelire type];

  ps_type = [oTypes getId:ps_one_type->ui_id];

  // La somme change selon que le type est replié ou non
  l_sum = ps_type_info->uh_folded
    ? ps_type_info->l_sum_with_children : ps_type_info->l_sum;

  pa_fullname = [oTypes fullNameOfId:ps_one_type->ui_id	len:NULL];

  [(ExportForm*)oExportForm exportLine:NULL,
		pa_fullname, l_sum, (UInt32)ps_type_info->uh_selected];

  MemPtrFree(pa_fullname);

  [oTypes getFree:ps_type];

  MemHandleUnlock(self->vh_infos);
  MemHandleUnlock(self->vh_tree);
}

@end
