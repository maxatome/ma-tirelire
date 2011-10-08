/* 
 * DBItem.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sun Aug 24 21:43:07 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb  1 17:09:34 2008
 * Update Count    : 26
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: DBItem.m,v $
 * Revision 1.11  2008/02/01 17:11:47  max
 * s/WinPrintf/alert_error_str/g
 *
 * Revision 1.10  2008/01/14 17:09:32  max
 * Switch to new mcc.
 *
 * Revision 1.9  2006/11/04 23:48:02  max
 * Use hexa to display Get/ResizeRecord error code.
 *
 * Revision 1.8  2006/06/19 12:23:47  max
 * In -save:size:asId:asNew: asNew changes type from Boolean to UInt16.
 *
 * Revision 1.7  2006/04/25 08:46:14  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.6  2005/08/20 13:06:47  max
 * Add -getCategoriesNamesForMask:retLen:retNum: method.
 *
 * Revision 1.5  2005/05/08 12:12:53  max
 * Add -getName: and -getCardNo:andID: methods.
 * Code cleaning.
 *
 * Revision 1.4  2005/03/27 15:38:19  max
 * Add the ability to clone databases
 *
 * Revision 1.3  2005/03/20 22:28:18  max
 * s/-initWithID:/-initWithCardNo:withID:/
 *
 * Revision 1.2  2005/03/02 19:02:34  max
 * -deleteId: can now Remove or Delete on demand, not only via Ma
 * Tirelire preferences.
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_DBITEM
#include "DBItem.h"

#include "MaTirelire.h"

// Pour la barre de progression du clonage
#include "ProgressBar.h"
#include "objRsc.h"

#include "ids.h"
#include "db_list.h"


@implementation DBItem

+ (DBItem*)new
{
  DBItem *oDB = [self alloc];

  if ([oDB init] != nil)
    return oDB;

  return [oDB free];
}


- (DBItem*)init
{
  return [self subclassResponsibility];
}


- (DBItem*)initDBType:(UInt32)ui_db_type nameSTR:(Char*)pa_db_name
{
  self->db = DmOpenDatabaseByTypeCreator(ui_db_type, MaTiCreatorID,
					 dmModeReadWrite);
  if (self->db == NULL)
  {
    Err error;

    // Si on ne nous a fourni aucun nom, on quitte de suite
    if (pa_db_name == NULL)
      return nil;

    // Create the db
    error = DmCreateDatabase(0, pa_db_name, MaTiCreatorID, ui_db_type, false);
    if (error)
    {
      // XXX
      return nil;
    }

    // Re-open the db
    self->db = DmOpenDatabaseByTypeCreator(ui_db_type, MaTiCreatorID,
					   dmModeReadWrite);

    if (self->db == NULL)
    {
      // XXX
      return nil;
    }

    // Set the backup bit
    [self setBackupBit];
  }

  return self;
}


- (DBItem*)initWithCardNo:(UInt16)uh_cardno withID:(LocalID)ul_id
{
  self->db = DmOpenDatabase(uh_cardno, ul_id, dmModeReadWrite);
  if (self->db == NULL)
    return nil;

  return self;
}


- (void)setBackupBit
{
  LocalID ui_lid;
  UInt16 uh_card_no, uh_attributes;

  [self getCardNo:&uh_card_no andID:&ui_lid];
  DmDatabaseInfo(uh_card_no, ui_lid, NULL, &uh_attributes, NULL, NULL,
		 NULL, NULL, NULL, NULL, NULL, NULL, NULL);
  uh_attributes |= dmHdrAttrBackup;
  DmSetDatabaseInfo(uh_card_no, ui_lid, NULL, &uh_attributes, NULL, NULL,
		    NULL, NULL, NULL, NULL, NULL, NULL, NULL);
}


- (DBItem*)free
{
  if (self->db != NULL)
    DmCloseDatabase(self->db);

  return [super free];
}


- (Char*)getName:(Char*)pa_name
{
  LocalID ui_lid;
  UInt16 uh_card_no;

  [self getCardNo:&uh_card_no andID:&ui_lid];
  DmDatabaseInfo(uh_card_no, ui_lid, pa_name,
		 NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

  return pa_name;
}


////////////////////////////////////////////////////////////////////////
//
// DB Record methods
//
////////////////////////////////////////////////////////////////////////

- (void*)recordNewAtId:(UInt16*)puh_index size:(UInt16)uh_size
{
  // XXX
  if (self->s_record_infos.vh_data != NULL)
    alert_error_str("(%u, %u) but idx %u not yet released",
		    uh_size, *puh_index, self->s_record_infos.uh_index);

  self->s_record_infos.vh_data = DmNewRecord(self->db, puh_index, uh_size);
  if (self->s_record_infos.vh_data == NULL)
    return NULL;

  // Save the index for -recordRelease:
  self->s_record_infos.uh_index = *puh_index;

  return MemHandleLock(self->s_record_infos.vh_data);
}


- (void*)recordGetAtId:(UInt16)uh_index
{
  // XXX
  if (self->s_record_infos.vh_data != NULL)
    alert_error_str("(%u) but idx %u not yet released",
		    uh_index, self->s_record_infos.uh_index);

  self->s_record_infos.vh_data = DmGetRecord(self->db, uh_index);
  if (self->s_record_infos.vh_data == NULL)
    return NULL;

  // Save the index for -recordRelease:
  self->s_record_infos.uh_index = uh_index;

  return MemHandleLock(self->s_record_infos.vh_data);
}


- (void*)recordResizeId:(UInt16)uh_index newSize:(UInt16)uh_size
{
  // XXX
  if (self->s_record_infos.vh_data != NULL)
    alert_error_str("(%u) but idx %u not yet released",
		    uh_index, self->s_record_infos.uh_index);

  self->s_record_infos.vh_data = DmResizeRecord(self->db, uh_index, uh_size);
  if (self->s_record_infos.vh_data == NULL)
    return NULL;

  // Save the index for -recordRelease:
  self->s_record_infos.uh_index = uh_index;

  return MemHandleLock(self->s_record_infos.vh_data);
}


- (void)recordRelease:(Boolean)b_modified
{
  // XXX
  if (self->s_record_infos.vh_data == NULL)
  {
    alert_error_str("(%u) but no record got!", (UInt16)b_modified);
    return;
  }

  MemHandleUnlock(self->s_record_infos.vh_data);
  DmReleaseRecord(self->db, self->s_record_infos.uh_index, b_modified);
  self->s_record_infos.vh_data = NULL;
}


////////////////////////////////////////////////////////////////////////
//
// Loading item
//
////////////////////////////////////////////////////////////////////////

- (void*)getId:(UInt16)uh_index
{
  VoidHand vh_item;

  vh_item = DmQueryRecord(self->db, uh_index);
  if (vh_item == NULL)
    // Item deleted but not yet synced...
    return NULL;

  return MemHandleLock(vh_item);
}


//
// Function called after a -getId:
- (void)getFree:(void*)ps_item
{
  MemPtrUnlock(ps_item);
}


////////////////////////////////////////////////////////////////////////
//
// Saving item
//
////////////////////////////////////////////////////////////////////////

- (Boolean)save:(void*)ps_item size:(UInt16)uh_size asId:(UInt16*)puh_index
	  asNew:(UInt16)uh_new
{
  void *ps_item_rec;

  // New record
  if (uh_new)
    ps_item_rec = [self recordNewAtId:puh_index size:uh_size];
  // Record modification
  else
    ps_item_rec = [self recordResizeId:*puh_index newSize:uh_size];

  if (ps_item_rec == NULL)
  {
    alert_error(DmGetLastErr());
    return false;
  }

  DmWrite(ps_item_rec, 0, ps_item, uh_size);

  [self recordRelease:true];

  return true;
}


- (Boolean)moveId:(UInt16)uh_index direction:(WinDirectionType)dir
{
  UInt16 uh_other, uh_last;
  Int16 h_inc;
  VoidHand pv_mode;

  if (dir == winUp)
  {
    uh_last = 0;
    h_inc = -1;
  }
  else
  {
    h_inc = 1;
    uh_last = DmNumRecords(self->db);

    if (uh_last <= 1)		// 0 or 1 record: nothing to do
      return false;

    uh_last--;
  }

  // At end, we are the first/last record
  for (uh_other = uh_index; uh_other != uh_last;)
  {
    // Prev/next one
    uh_other += h_inc;

    pv_mode = DmQueryRecord(self->db, uh_other);
    if (pv_mode != NULL)
    {
      // After this record if winDown
      DmMoveRecord(self->db, uh_index, uh_other + (dir != winUp));

      // OK
      return true;
    }
  }

  return false;
}


- (void)setCategory:(UInt16)uh_category forId:(UInt16)uh_index
{
  UInt16 uh_attr;

  DmRecordInfo(self->db, uh_index, &uh_attr, NULL, NULL);

  uh_attr &= ~dmRecAttrCategoryMask;
  uh_attr |= uh_category;

  DmSetRecordInfo(self->db, uh_index, &uh_attr, NULL);
}


////////////////////////////////////////////////////////////////////////
//
// Deleting item
//
////////////////////////////////////////////////////////////////////////

- (Int16)deleteId:(UInt32)ui_index
{
  UInt16 uh_index = ui_index & 0xffff;

#ifdef DM_REMOVE_RECORD
  // Mode auto
  if ((ui_index & (DBITEM_DEL_REMOVE|DBITEM_DEL_DELETE)) == 0)
  {
    if ([oMaTirelire getPrefs]->ul_remove_type != DM_REMOVE_RECORD)
      ui_index |= DBITEM_DEL_DELETE;
  }
#endif

  if (ui_index & DBITEM_DEL_DELETE)
  {
    if (DmDeleteRecord(self->db, uh_index) != 0)
      return -1;

    return 0;	       // 0 for record Deleted (leave the record entry)
  }

  if (DmRemoveRecord(self->db, uh_index) != 0)
    return -1;

  return 1;	      // 1 for record Removed (really remove the record)
}


////////////////////////////////////////////////////////////////////////
//
// AppInfoBlock management
//
////////////////////////////////////////////////////////////////////////

// Si le AppInfoBlock n'existe pas encore, il est créé automatiquement.
// Si il existe déjà, on suppose qu'il a déjà la bonne taille.
// uh_size ne comprend pas une éventuelle taille des catégories. Par
// contre si des catégories sont présentes il faut l'indiquer à l'aide
// du flag DBITEM_CATEGORY_INFOS.
// Lors de la création du AppInfoBlock, on peut passer la catégorie
// par défaut à l'aide de la macro DBITEM_DEFCAT_SET(cat, size) qui
// positionne par la même toute seule le flag DBITEM_CATEGORY_INFOS.
- (Err)appInfoBlockSave:(void*)pv_zone size:(UInt16)uh_size
{
  LocalID ui_lid;
  UInt16  uh_card_no;
  Int16 h_def_category = -1;

  [self getCardNo:&uh_card_no andID:&ui_lid];

  if (uh_size & DBITEM_CATEGORY_INFOS)
  {
    h_def_category = DBITEM_DEFCAT_GET(uh_size);
    uh_size &= DBITEM_SIZE_MASK;
  }

  return db_app_info_block_save(self->db, uh_card_no, ui_lid,
				pv_zone, uh_size, h_def_category);
}


//
// Charge le AppInfoBlock (sans les catégories) de la base
//
// puh_size :
// - Si NULL => charge tout le AppInfoBlock, sans retour de la taille
// - Si *puh_size=0 => charge tout le AppInfoBlock et renvoie sa taille
// - Sinon => charge *puh_size octets au maximum.
//
// ppv_zone ne peut être NULL :
// - Si *ppv_zone=NULL, alloue un MemHandle de *puh_size et le renvoie
// - Sinon utilise *ppv_zone comme zone de retour
//
// uh_flags => voir doc de db_app_info_block_load
- (Err)appInfoBlockLoad:(void**)ppv_zone size:(UInt16*)puh_size
		  flags:(UInt16)uh_flags
{
  LocalID ui_lid;
  UInt16  uh_card_no;

  [self getCardNo:&uh_card_no andID:&ui_lid];

  return db_app_info_block_load(uh_card_no, ui_lid,
				ppv_zone, puh_size, uh_flags);
}


////////////////////////////////////////////////////////////////////////
//
// SortInfoBlock management
//
////////////////////////////////////////////////////////////////////////

// Si le SortInfoBlock n'existe pas encore, il est créé automatiquement.
// Si il existe déjà, on suppose qu'il a déjà la bonne taille.
- (Err)sortInfoBlockSave:(void*)pv_zone size:(UInt16)uh_size
{
  LocalID ui_lid;
  UInt16  uh_card_no;

  [self getCardNo:&uh_card_no andID:&ui_lid];

  return db_sort_info_block_save(self->db, uh_card_no, ui_lid,
				 pv_zone, uh_size);
}


//
// Charge le SortInfoBlock de la base
//
// puh_size :
// - Si NULL => charge tout le SortInfoBlock, sans retour de la taille
// - Si *puh_size=0 => charge tout le SortInfoBlock et renvoie sa taille
// - Sinon => charge *puh_size octets au maximum.
//
// ppv_zone ne peut être NULL :
// - Si *ppv_zone=NULL, alloue un MemHandle de *puh_size et le renvoie
// - Sinon utilise *ppv_zone comme zone de retour
//
// uh_flags => voir doc de db_sort_info_block_load
- (Err)sortInfoBlockLoad:(void**)ppv_zone size:(UInt16*)puh_size
		   flags:(UInt16)uh_flags
{
  LocalID ui_lid;
  UInt16  uh_card_no;

  [self getCardNo:&uh_card_no andID:&ui_lid];

  return db_sort_info_block_load(uh_card_no, ui_lid,
				 ppv_zone, puh_size, uh_flags);
}


////////////////////////////////////////////////////////////////////////
//
// Popup management
//
////////////////////////////////////////////////////////////////////////

- (Char**)listBuildInfos:(void*)pv_infos num:(UInt16*)puh_num
		 largest:(UInt16*)puh_largest
{
  return [self subclassResponsibility];
}


- (void)listFree:(Char**)ppa_list
{
  if (ppa_list != NULL)
    MemPtrFree(ppa_list);
}


- (ListDrawDataFuncPtr)listDrawFunction
{
  return [self subclassResponsibility];
}


- (UInt16)dbMaxEntries
{
  return [self subclassResponsibility];
}


//
// Renvoie true si présence de flèches de scroll dans la marge de
// droite.
// Si h_sel_item < 0, la sélection n'est pas initialisée dans la liste
- (Boolean)rightMarginList:(ListType*)pt_list
		       num:(UInt16)uh_num
			in:(struct __s_list_dbitem_buf*)ps_buf
		   selItem:(Int16)h_sel_item
{
  LstSetListChoices(pt_list, (Char**)ps_buf, uh_num);

  if (uh_num > 0)
  {
    if (h_sel_item >= 0)
    {
      LstSetSelection(pt_list, h_sel_item);
      LstMakeItemVisible(pt_list, h_sel_item);
    }

    if (LstGetVisibleItems(pt_list) != uh_num)
    {
      // Quel que soit l'OS, on garde en tête qu'il y a une flèche de
      // scroll pour gérer les taps dans les sous-menus (si nécessaire)
      ps_buf->uh_is_scroll_list = 1;

      // Si on est sur un OS < 4, il faudra retirer la largeur de la
      // marge de droite (flèche de scroll) lors du dessin de chaque
      // ligne. Sur les OS suivants, la zone fournie tient compte de
      // la présence de la flèche de scroll sur la ligne ou non.
      if (oMaTirelire->ul_rom_version < 0x04000000)
	ps_buf->uh_is_right_margin = 1;

      // Pour tout le monde : il y a une marge supplémentaire à droite
      // pour la flèche de scroll dont il faut tenir compte pour la
      // largeur de la liste.
      return true;
    }
  }

  return false;
}


- (DmOpenRef)db
{
  return self->db;
}


- (DBItem*)clone:(Char*)pa_clone_name
{
  DBItem *oDB;
  Char ra_name[dmDBNameLength];
  MemHandle pv_rec;
  void *pv_src, *pv_dest;
  LocalID ui_lid, ui_appinfo_id;
  UInt32 ui_mod_num, ui_db_type, ui_creator_id, ui_unique_id;
  PROGRESSBAR_DECL;
  UInt16 uh_card_no;
  UInt16 uh_src_db_attributes, uh_dst_db_attributes, uh_version;
  UInt16 index, uh_num_records, uh_new, uh_size, uh_src_attr, uh_dst_attr;
  Err error;

  [self getCardNo:&uh_card_no andID:&ui_lid];

  DmDatabaseInfo(uh_card_no, ui_lid, ra_name, &uh_src_db_attributes,
		 &uh_version, NULL, NULL, NULL,
		 &ui_mod_num, &ui_appinfo_id, NULL,
		 &ui_db_type, &ui_creator_id);

  // Create the db
  error = DmCreateDatabase(uh_card_no, pa_clone_name,
			   ui_creator_id, ui_db_type, false);
  if (error)
  {
    alert_error(error);
    return nil;
  }

  //
  // Open the new database
  ui_lid = DmFindDatabase(uh_card_no, pa_clone_name);
  if (ui_lid == 0)
    return nil;

  oDB = [self->oIsa alloc];

  if ([oDB initWithCardNo:uh_card_no withID:ui_lid] == nil)
    return [oDB free];

  //
  // Copy all records...
  uh_num_records = DmNumRecords(self->db);

  PROGRESSBAR_BEGIN(uh_num_records, strProgressBarDBItemCloning);

  for (index = 0; index < uh_num_records; index++)
  {
    pv_rec = DmQueryRecord(self->db, index);
    if (pv_rec != NULL)
    {
      uh_size = MemHandleSize(pv_rec);

      pv_src = MemHandleLock(pv_rec);

      // Création et copie
      uh_new = dmMaxRecordIndex;
      pv_dest = [oDB recordNewAtId:&uh_new size:uh_size];
      if (pv_dest != NULL)
      {
	DmWrite(pv_dest, 0, pv_src, uh_size);

	[oDB recordRelease:true];

	MemHandleUnlock(pv_rec);

	// Mise à jour des attributs, de la catégorie et du unique ID
	DmRecordInfo(self->db, index, &uh_src_attr, &ui_unique_id, NULL);
	uh_src_attr &= ~dmSysOnlyRecAttrs; // On ne copie pas les flags système

	DmRecordInfo(oDB->db, uh_new, &uh_dst_attr, NULL, NULL);
	uh_dst_attr &= dmSysOnlyRecAttrs;
	uh_dst_attr |= uh_src_attr;
	DmSetRecordInfo(oDB->db, uh_new, &uh_dst_attr, &ui_unique_id);
      }
      else
      {
	// XXX
	MemHandleUnlock(pv_rec);
      }
    }

    PROGRESSBAR_INLOOP(index, 25);
  }

  PROGRESSBAR_END;

  //
  // Copy the application info block...
  pv_src = MemLocalIDToLockedPtr(ui_appinfo_id, uh_card_no);

  if ([oDB appInfoBlockSave:pv_src size:MemPtrSize(pv_src)] != errNone)
  {
    // XXX
  }

  MemPtrUnlock(pv_src);

  //
  // Mise à jour des attributs de la base
  uh_src_db_attributes &= ~dmSysOnlyHdrAttrs;

  DmDatabaseInfo(uh_card_no, ui_lid, NULL, &uh_dst_db_attributes,
		 NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
  uh_dst_db_attributes &= dmSysOnlyHdrAttrs;
  uh_dst_db_attributes |= uh_src_db_attributes;
  DmSetDatabaseInfo(uh_card_no, ui_lid, NULL, &uh_dst_db_attributes,
		    &uh_version, NULL, NULL, NULL, &ui_mod_num,
		    NULL, NULL, NULL, NULL);

  return oDB;
}


- (void)getCardNo:(UInt16*)puh_card_no andID:(LocalID*)pul_id
{
  DmOpenDatabaseInfo(self->db, pul_id, NULL, NULL, puh_card_no,NULL);
}


- (Char*)getCategoriesNamesForMask:(UInt16)uh_accounts_mask
			    retLen:(UInt16*)puh_len
			    retNum:(UInt16*)puh_num
{
  struct
  {
    Char ra_name[dmCategoryLength];
    UInt16 uh_len;
  } rs_categories[dmRecNumCategories], *ps_category;
  Char *pa_ret, *pa_cur;
  UInt16 index;

  *puh_num = 0;
  *puh_len = 0;

  ps_category = rs_categories;
  for (index = 0; index < dmRecNumCategories; index++)
    if (uh_accounts_mask & (1 << index))
    {
      CategoryGetName(self->db, index, ps_category->ra_name);
      ps_category->uh_len = StrLen(ps_category->ra_name);

      (*puh_num)++;
      *puh_len += ps_category->uh_len + 2; // 2 == ', ' ou '.\0'

      ps_category++;
    }

  if (*puh_len == 0)
    return NULL;

  // On trie les catégories dans l'ordre alphabétique
  if (*puh_num > 1)
    SysInsertionSort(rs_categories, *puh_num,
		     sizeof(rs_categories[0]),
		     (CmpFuncPtr)sort_string_compare, 0);

  NEW_PTR(pa_ret, *puh_len, return NULL);

  // On recopie les noms de catégorie...
  pa_cur = pa_ret;
  ps_category = rs_categories;
  for (index = 0; index < *puh_num; index++)
  {
    MemMove(pa_cur, ps_category->ra_name, ps_category->uh_len);
    pa_cur += ps_category->uh_len;

    *pa_cur++ = ',';
    *pa_cur++ = ' ';

    ps_category++;
  }

  pa_cur[-2] = '.';
  pa_cur[-1] = '\0';

  return pa_ret;
}


#if 0
- XXXX(Boolean)foreachDo:(t_trans_foreach)pf_func
		from:(UInt16)index to:(UInt16)uh_to
	  inCategory:(UInt16)uh_category
		with:(void*)pv_param
{
  MemHandle vh_item;

  if (uh_category == dmAllCategories)
  {
    UInt16 uh_max = DmNumRecords(self->db);

    if (uh_to >= uh_max)
      uh_to = uh_max - 1;

    for (; index <= uh_to; index++)
    {
      vh_item = DmQueryRecord(self->db, index);

      if (vh_item != NULL)
      {
	if (pf_func(MemHandleLock(vh_item), pv_param))
	{
	  MemHandleUnlock(vh_item);
	  return true;
	}

	MemHandleUnlock(vh_item);
      }
    }
  }
  else
  {
    while ((vh_item = DmQueryNextInCategory(self->db, // PG XXX
					    &index, uh_category)) != NULL)
    {
      if (index++ > uh_to)
	break;

      if (pf_func(MemHandleLock(vh_item), pv_param))
      {
	MemHandleUnlock(vh_item);
	return true;
      }

      MemHandleUnlock(vh_item);

      // Évite le dernier appel à DmQueryNextInCategory, à voir XXX
      //if (index > uh_to)
      //  break;
    }
  }

  return false;
}
#endif

@end
