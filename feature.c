/* 
 * feature.c -- 
 * 
 * Author          : Maxime Soulé
 * Created On      : Sun Mar 27 17:22:46 2005
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author$
 * $Log$
 * ==================== RCS ==================== */

#define EXTERN_FEATURE
#include "feature.h"

#if 0
EXTERN_MISC void *feature_mem_new(UInt16 uh_feature, UInt16 uh_size);
EXTERN_MISC void feature_mem_free(UInt16 uh_feature, void *pv_ptr);
EXTERN_MISC void *feature_mem_get(UInt16 uh_feature);
#define feature_mem_unlock(pv_ptr)	MemPtrUnlock(pv_ptr)

    if (0)
    {
      Char ra_test[] = "Test pour voir";
      Char *pa_mesg;

      pa_mesg = feature_mem_get(0xA1a7);
      if (pa_mesg != NULL)
      {
	// On affiche
	WinPrintf("Contenu = '%s'", pa_mesg);

	DmWrite(pa_mesg, 0, &pa_mesg[1], sizeof(ra_test) - 1);
	//feature_mem_free(0xA1a7, pa_mesg);
      }
      else
      {
	pa_mesg = feature_mem_new(0xA1a7, sizeof(ra_test));
	if (pa_mesg == NULL)
	  WinPrintf("NULL");
	else
	{
	  DmWrite(pa_mesg, 0, ra_test, sizeof(ra_test));

	  feature_mem_unlock(pa_mesg);

	  WinPrintf("Création OK");
	}
      }
    }
#endif

void *feature_mem_new(UInt16 uh_feature, UInt16 uh_size)
{
  MemHandle pv_mem;
  void *pv_ptr = NULL;
  DmOpenRef db;
  LocalID ui_lid;
  UInt16 uh_cardno;

  // La feature existe déjà, on la redimensionne
  if (FtrGet(MaTiCreatorID, uh_feature, (UInt32*)&pv_mem) == 0)
  {
    if (MemHandleSize(pv_mem) != uh_size)
      MemHandleResize(pv_mem, uh_size);

    goto end_ok;
  }

  // Handle sur la même carte que notre application
  SysCurAppDatabase(&uh_cardno, &ui_lid);

  db = DmOpenDatabase(uh_cardno, ui_lid, dmModeReadOnly);
  pv_mem = DmNewHandle(db, uh_size);
  DmCloseDatabase(db);

  if (pv_mem != NULL)
  {
    // Mise en place de la feature
    if (FtrSet(MaTiCreatorID, uh_feature, (UInt32)pv_mem) != 0)
      MemHandleFree(pv_mem);
    else
    {
  end_ok:
      pv_ptr = MemHandleLock(pv_mem);
    }
  }

  return pv_ptr;
}


// feature_mem_unlock() doit être appelée lorsque le chunk ne sert plus
void *feature_mem_get(UInt16 uh_feature)
{
  MemHandle pv_mem;

  if (FtrGet(MaTiCreatorID, uh_feature, (UInt32*)&pv_mem) != 0)
    return NULL;

  return MemHandleLock(pv_mem);
}


void feature_mem_free(UInt16 uh_feature, void *pv_ptr)
{
  FtrUnregister(MaTiCreatorID, uh_feature);

  if (pv_ptr != NULL)
  {
    MemHandle pv_mem = MemPtrRecoverHandle(pv_ptr);

    MemHandleUnlock(pv_mem);
    MemHandleFree(pv_mem);
  }
}
