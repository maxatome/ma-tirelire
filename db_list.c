/* 
 * db_list.c -- 
 * 
 * Author          : Maxime Soulé
 * Created On      : Wed Jun 30 22:12:36 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb  1 17:02:31 2008
 * Update Count    : 11
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: db_list.c,v $
 * Revision 1.5  2008/02/01 17:07:34  max
 * s/WinPrintf/alert_error_str/g
 *
 * Revision 1.4  2006/04/25 08:46:15  max
 * Switch to NEW_PTR/HANDLE() for memory allocations.
 *
 * Revision 1.3  2005/05/08 12:13:11  max
 * Implement optional sub-menus in DBases popup list.
 * Use generic name sorting.
 *
 * Revision 1.2  2005/03/02 19:02:51  max
 * Indentation corrections.
 *
 * Revision 1.1  2005/02/09 22:57:23  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_DB_LIST
#include "db_list.h"

#include "misc.h"
#include "ids.h"
#include "objRsc.h"		// Pour alertMemErrNotEnoughSpace


//
// SysCreateDataBaseList can generate a list of database.
//
// typedef struct 
// {
//   Char            name[dmDBNameLength];
//   UInt32          creator;
//   UInt32          type;
//   UInt16          version;
//   LocalID         dbID;
//   UInt16          cardNo;
//   BitmapPtr       iconP;
// } SysDBListItemType;
//

Char *db_list_visible_name(Char *pa_db_name)
{
  if (StrNCompare(pa_db_name, MaTiAcntPrefix, MaTiAcntPrefixLen) == 0)
    pa_db_name += MaTiAcntPrefixLen;

  return pa_db_name;
}


// uh_last_entryN == index de la chaîne à utiliser comme dernière
// entrée de la liste. 0 si aucune.
MemHandle db_list_new(UInt32 ul_creator, UInt32 ul_type, UInt16 *puh_num,
		      UInt16 *puh_largest,
		      UInt16 uh_last_entry1, UInt16 uh_last_entry2,
		      Boolean b_db_sub_menus)
{
  MemHandle hdl_dbs;

  UInt16 uh_num = 0;
  UInt16 uh_largest = 0;

  if (SysCreateDataBaseList(ul_type, ul_creator, &uh_num, &hdl_dbs, false)
      && uh_num > 0)
  {
    UInt16 uh_size = MemHandleSize(hdl_dbs);
    UInt16 uh_addon_size = 0;

    // Il va falloir rajouter un '>' à la fin de chaque nom de base
    if (b_db_sub_menus)
      uh_size += uh_num;

    // Il y a au moins une dernière entrée (taille pour un pointeur + chaîne)
    if (uh_last_entry1 > 0)
    {
      uh_addon_size = sizeof(Char*) + DB_LIST_LAST_ENTRY_MAXLEN;

      // Il y a 2 entrées en dernier
      if (uh_last_entry2 > 0)
	uh_addon_size *= 2;
    }

    if (MemHandleResize(hdl_dbs,
			uh_size + uh_num * sizeof(Char*) + uh_addon_size) == 0)
    {
      SysDBListItemType *ps_dbids;
      Char **ppa_ret, **ppa_cur, *pa_beg;
      UInt16 index, uh_width, uh_sub_menu_width;

      // S'il y a des sous-menus, il faut rajouter la flèche en fin de ligne
      uh_sub_menu_width = b_db_sub_menus ? FntCharWidth('>') : 0;

      ppa_ret = ppa_cur = MemHandleLock(hdl_dbs);

      ps_dbids = (SysDBListItemType*)((Char*)&ppa_ret[uh_num] + uh_addon_size);

      // On va se mettre en tête
      MemMove(ps_dbids, ppa_cur, uh_size);

      // Sort the list alphabeticaly
      SysInsertionSort(ps_dbids, uh_num, sizeof(*ps_dbids),
		       (CmpFuncPtr)sort_string_compare, 0);

      for (index = 0; index < uh_num; index++, ps_dbids++, ppa_cur++)
      {
	// Si le nom commence par "MaTi=" on ignore ce préfixe...
	pa_beg = db_list_visible_name(ps_dbids->name);

	// Si on a un sous-menu, on rajoute la flèche en fin de
	// ligne. Si ça déborde de ra_name, ça va empiéter sur creator
	// et c'est pas grave puisqu'on ne s'en servira pas.
	if (b_db_sub_menus)
	  StrCat(pa_beg, ">");

	uh_width = FntCharsWidth(pa_beg, StrLen(pa_beg)) + uh_sub_menu_width;
	if (uh_width > uh_largest)
	  uh_largest = uh_width;

	*ppa_cur = pa_beg;
      }

      // Il y a au moins une dernière entrée
      if (uh_last_entry1 > 0)
      {
	pa_beg = (Char*)ppa_cur + sizeof(Char*);
 
	if (uh_last_entry2 > 0) // S'il y a 2 entrées en fin, il faut la place
	  pa_beg += sizeof(Char*);
 
	*pa_beg = '^';  /* Séparateur en haut */
	load_and_fit(uh_last_entry1, pa_beg + 1, &uh_largest);
	*ppa_cur++ = pa_beg;
 
	uh_num++;
 
	// La vraie dernière entrée
	if (uh_last_entry2 > 0)
	{
	  pa_beg += DB_LIST_LAST_ENTRY_MAXLEN;
	  load_and_fit(uh_last_entry2, pa_beg, &uh_largest);
	  *ppa_cur = pa_beg;
 
	  uh_num++;
	}
      }

      MemHandleUnlock(hdl_dbs);
    }
    else
    {
      alert_error_str("Can't resize DB list : %d + %d * 4", uh_size, uh_num);
      MemHandleFree(hdl_dbs);
      hdl_dbs = NULL;
      uh_num = 0;
    }
  }
  else
    hdl_dbs = NULL;		/* Pour les OS <= 3.1 */

  if (uh_num == 0)
    hdl_dbs = NULL;

  *puh_num = uh_num;

  if (puh_largest != NULL)
    *puh_largest = uh_largest;

  return hdl_dbs;
}


//
// Charge le AppInfoBlock (sans les catégories) de la base
// uh_cardno/ui_lid
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
// uh_flags :
// - INFOBLK_CATEGORIES    il y a des catégories en tête du AppInfoBlock
// - INFOBLK_DIRECTZONE    ppv_zone est LA zone de retour
// - INFOBLK_PTRNEW	   l'allocation doit être faite via MemPtrNew
Err db_app_info_block_load(UInt16 uh_cardno, LocalID ui_lid,
			   void **ppv_zone, UInt16 *puh_size,
			   UInt16 uh_flags)
{
  LocalID ui_appinfo;
  MemHandle vh_zone = NULL;
  void *pv_infos, *pv_ret_zone;
  UInt16 uh_categories_size = 0, uh_chunk_size, uh_return_size;
  Err uh_err;

  uh_err = DmDatabaseInfo(uh_cardno, ui_lid, NULL, NULL, NULL, NULL, NULL,
			  NULL, NULL, &ui_appinfo, NULL, NULL, NULL);
  if (uh_err != errNone)
    return uh_err;

  // Pas de AppInfoBlock
  if (ui_appinfo == 0)
    return dmErrNotValidRecord;

  // DB infos include categories
  if (uh_flags & INFOBLK_CATEGORIES)
    uh_categories_size = sizeof(AppInfoType);

  pv_infos = MemLocalIDToLockedPtr(ui_appinfo, uh_cardno);

  uh_chunk_size = MemPtrSize(pv_infos);

  //
  // La taille de la zone en retour
  uh_return_size = uh_chunk_size - uh_categories_size;

  // Pas de taille de retour spécifiée, on renvoie le block sans les
  // catégories...
  if (puh_size != NULL)
  {
    // Il faut retourner la taille du block sans les catégories...
    if (*puh_size == 0)
      *puh_size = uh_return_size;
    // La taille est transmise : on se base dessus
    else
      uh_return_size = *puh_size;
  }

  //
  // La zone en retour
  if (uh_flags & INFOBLK_DIRECTZONE)
    pv_ret_zone = ppv_zone;
  else
  {
    pv_ret_zone = *ppv_zone;

    // La zone transmise n'est pas allouée, il faut le faire
    if (pv_ret_zone == NULL)
    {
      // On veut un buffer à accès direct
      if (uh_flags & INFOBLK_PTRNEW)
      {
	NEW_PTR(pv_ret_zone, uh_return_size,
		({ MemPtrUnlock(pv_infos); return memErrNotEnoughSpace; }));

	*ppv_zone = pv_ret_zone;
      }
      // On veut un MemHandle
      else
      {
	NEW_HANDLE(vh_zone, uh_return_size,
		   ({ MemPtrUnlock(pv_infos); return memErrNotEnoughSpace; }));

	pv_ret_zone = MemHandleLock(vh_zone);

	*ppv_zone = vh_zone;
      }
    }
  }

  // Le block de la base est plus grand que prévu : pas de souci
  if (uh_chunk_size >= uh_categories_size + uh_return_size)
    // Read only user infos
    MemMove(pv_ret_zone, pv_infos + uh_categories_size, uh_return_size);
  // Le block est plus petit que requis...
  else
  {
    UInt16 uh_read_size = 0;

    // On peut quand même en lire un peu après les catégories
    if (uh_chunk_size > uh_categories_size)
    {
      uh_read_size = uh_chunk_size - uh_categories_size;

      MemMove(pv_ret_zone, pv_infos + uh_categories_size, uh_read_size);
    }

    // Le reste est initialisé à 0
    MemSet(pv_ret_zone + uh_read_size, uh_return_size - uh_read_size, '\0');
  }

  if (vh_zone != NULL)
    MemHandleUnlock(vh_zone);

  MemPtrUnlock(pv_infos);

  return errNone;
}


//
// Sauve le AppInfoBlock de la base uh_cardno/ui_lid
//
// Si le AppInfoBlock n'existe pas encore, utilise db pour le
// créer. Si db est NULL, ouvre automatiquement la base le temps de
// l'attachement et la referme à la fin de la fonction.
//
// Écrit le buffer pointé par pv_zone et de taille uh_size juste après
// les éventuelles catégories.
//
// h_def_category :
// - Si < 0, pas de catégorie en tête du AppInfoBlock
// - Si == 0, le AppInfoBlock est initialisé à 0 si création
// - Sinon, catégories en tête du AppInfoBlock => h_def_category est
//   l'ID du CATEGORIES à utiliser pour initiliser des catégories en cas
//   de création du AppInfoBlock.
Err db_app_info_block_save(DmOpenRef db, UInt16 uh_cardno, LocalID ui_lid,
			   void *pv_zone, UInt16 uh_size,
			   Int16 h_def_category) /* -1 no category */
{
  AppInfoType *ps_appinfo;
  LocalID ui_appinfo;
  UInt16 uh_categories_size = 0;
  Err uh_err;
  Boolean b_create = false;
  Boolean b_db_opened = false;

  uh_err = DmDatabaseInfo(uh_cardno, ui_lid, NULL, NULL, NULL, NULL, NULL,
			  NULL, NULL, &ui_appinfo, NULL, NULL, NULL);
  if (uh_err != errNone)
    return uh_err;

  if (h_def_category >= 0)
    uh_categories_size = sizeof(AppInfoType);

  // Le block AppInfoBlock n'existe pas encore
  if (ui_appinfo == NULL)
  {
    MemHandle vh_infos;

    // La base n'est pas ouverte
    if (db == NULL)
    {
      db = DmOpenDatabase(uh_cardno, ui_lid, dmModeReadWrite);
      if (db == NULL)
	return DmGetLastErr();

      b_db_opened = true;
    }

    vh_infos = DmNewHandle(db, uh_categories_size + uh_size);
    if (vh_infos == NULL)
    {
      uh_err = dmErrMemError;
      goto end;
    }

    ui_appinfo = MemHandleToLocalID(vh_infos);
    DmSetDatabaseInfo(uh_cardno, ui_lid, NULL, NULL, NULL, NULL, NULL, NULL,
		      NULL, &ui_appinfo, NULL, NULL, NULL);
    b_create = true;
  }

  ps_appinfo = MemLocalIDToLockedPtr(ui_appinfo, uh_cardno);

  // Il faut redimensionner le bloc
  if (MemPtrSize(ps_appinfo) != uh_categories_size + uh_size)
  {
    MemHandle vh_infos;

    vh_infos = MemPtrRecoverHandle(ps_appinfo);
    MemHandleUnlock(vh_infos);

    MemHandleResize(vh_infos, uh_categories_size + uh_size);

    ps_appinfo = MemHandleLock(vh_infos);
  }

  // Initialize the info block with categories infos
  if (b_create && uh_categories_size > 0)
  {
    DmSet(ps_appinfo, 0, sizeof(AppInfoType), 0);

    // Il y a des catégories par défaut à initialiser...
    if (h_def_category > 0)
      CategoryInitialize(ps_appinfo, h_def_category);
  }

  // Initialize the info block with user infos
  DmWrite(ps_appinfo, uh_categories_size, pv_zone, uh_size);

  MemPtrUnlock(ps_appinfo);

  uh_err = errNone;

 end:
  if (b_db_opened)
    DmCloseDatabase(db);

  return uh_err;
}


//
// Charge le SortInfoBlock de la base uh_cardno/ui_lid
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
// uh_flags :
// - INFOBLK_DIRECTZONE    ppv_zone est LA zone de retour
// - INFOBLK_PTRNEW	   l'allocation doit être faite via MemPtrNew
Err db_sort_info_block_load(UInt16 uh_cardno, LocalID ui_lid,
			    void **ppv_zone, UInt16 *puh_size,
			    UInt16 uh_flags)
{
  LocalID ui_sortinfo;
  MemHandle vh_zone = NULL;
  void *pv_infos, *pv_ret_zone;
  UInt16 uh_chunk_size, uh_return_size;
  Err uh_err;

  uh_err = DmDatabaseInfo(uh_cardno, ui_lid, NULL, NULL, NULL, NULL, NULL,
			  NULL, NULL, NULL, &ui_sortinfo, NULL, NULL);
  if (uh_err != errNone)
    return uh_err;

  // Pas de SortInfoBlock
  if (ui_sortinfo == 0)
    return dmErrNotValidRecord;

  pv_infos = MemLocalIDToLockedPtr(ui_sortinfo, uh_cardno);

  uh_chunk_size = MemPtrSize(pv_infos);

  //
  // La taille de la zone en retour
  uh_return_size = uh_chunk_size;

  // Pas de taille de retour spécifiée, on renvoie le bloc au complet
  if (puh_size != NULL)
  {
    // Il faut retourner la taille du bloc...
    if (*puh_size == 0)
      *puh_size = uh_return_size;
    // La taille est transmise : on se base dessus
    else
      uh_return_size = *puh_size;
  }

  //
  // La zone en retour
  if (uh_flags & INFOBLK_DIRECTZONE)
    pv_ret_zone = ppv_zone;
  else
  {
    pv_ret_zone = *ppv_zone;

    // La zone transmise n'est pas allouée, il faut le faire
    if (pv_ret_zone == NULL)
    {
      // On veut un buffer à accès direct
      if (uh_flags & INFOBLK_PTRNEW)
      {
	pv_ret_zone = MemPtrNew(uh_return_size);
	if (pv_ret_zone == NULL)
	{
	  // XXX
	  MemPtrUnlock(pv_infos);
	  return memErrNotEnoughSpace;
	}

	*ppv_zone = pv_ret_zone;
      }
      // On veut un MemHandle
      else
      {
	vh_zone = MemHandleNew(uh_return_size);
	if (vh_zone == NULL)
	{
	  // XXXX
	  MemPtrUnlock(pv_infos);
	  return memErrNotEnoughSpace;
	}

	pv_ret_zone = MemHandleLock(vh_zone);

	*ppv_zone = vh_zone;
      }
    }
  }

  // Le block de la base est plus grand que prévu : pas de souci
  if (uh_chunk_size >= uh_return_size)
    // Read only user infos
    MemMove(pv_ret_zone, pv_infos, uh_return_size);
  // Le bloc est plus petit que requis...
  else
  {
    UInt16 uh_read_size = 0;

    // On peut quand même en lire un peu...
    if (uh_chunk_size > 0)
    {
      uh_read_size = uh_chunk_size;

      MemMove(pv_ret_zone, pv_infos, uh_read_size);
    }

    // Le reste est initialisé à 0
    MemSet(pv_ret_zone + uh_read_size, uh_return_size - uh_read_size, '\0');
  }

  if (vh_zone != NULL)
    MemHandleUnlock(vh_zone);

  MemPtrUnlock(pv_infos);

  return errNone;  
}


Err db_sort_info_block_save(DmOpenRef db, UInt16 uh_cardno, LocalID ui_lid,
			    void *pv_zone, UInt16 uh_size)
{
  void *pv_sortinfo;
  LocalID ui_sortinfo;
  Err uh_err;
  Boolean b_create = false;
  Boolean b_db_opened = false;

  uh_err = DmDatabaseInfo(uh_cardno, ui_lid, NULL, NULL, NULL, NULL, NULL,
			  NULL, NULL, NULL, &ui_sortinfo, NULL, NULL);
  if (uh_err != errNone)
    return uh_err;

  // Le block SortInfoBlock n'existe pas encore
  if (ui_sortinfo == NULL)
  {
    MemHandle vh_infos;

    // La base n'est pas ouverte
    if (db == NULL)
    {
      db = DmOpenDatabase(uh_cardno, ui_lid, dmModeReadWrite);
      if (db == NULL)
	return DmGetLastErr();

      b_db_opened = true;
    }

    vh_infos = DmNewHandle(db, uh_size);
    if (vh_infos == NULL)
    {
      uh_err = dmErrMemError;
      goto end;
    }

    ui_sortinfo = MemHandleToLocalID(vh_infos);
    DmSetDatabaseInfo(uh_cardno, ui_lid, NULL, NULL, NULL, NULL, NULL, NULL,
		      NULL, NULL, &ui_sortinfo, NULL, NULL);
    b_create = true;
  }

  pv_sortinfo = MemLocalIDToLockedPtr(ui_sortinfo, uh_cardno);

  // Il faut redimensionner le bloc
  if (MemPtrSize(pv_sortinfo) != uh_size)
  {
    MemHandle vh_infos;

    vh_infos = MemPtrRecoverHandle(pv_sortinfo);
    MemHandleUnlock(vh_infos);

    MemHandleResize(vh_infos, uh_size);

    pv_sortinfo = MemHandleLock(vh_infos);
  }

  // Initialize the info block with user infos
  DmWrite(pv_sortinfo, 0, pv_zone, uh_size);

  MemPtrUnlock(pv_sortinfo);

  uh_err = errNone;

 end:
  if (b_db_opened)
    DmCloseDatabase(db);

  return uh_err;
}
