/* 
 * mem.c -- 
 * 
 * Author          : Max Root
 * Created On      : Fri Jul 12 18:35:42 2002
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: mem.c,v $
 * Revision 1.1  2005/02/09 22:57:23  max
 * First import.
 *
 * ==================== RCS ==================== */

#include <PalmOS.h>

#define EXTERN_TYPES
#include "types.h"

void *MemPtrRealloc(void *pv_buffer, uint32 ui_size)
{
  Err uh_error;

  uh_error = MemPtrResize(pv_buffer, ui_size);
  if (uh_error == 0)
    return pv_buffer;

  if (uh_error == memErrNotEnoughSpace)
  {
    void *pv_new = MemPtrNew(ui_size);

    if (pv_new != NULL)
    {
      MemMove(pv_new, pv_buffer, ui_size);
      MemPtrFree(pv_buffer);
      return pv_new;
    }
  }

  return NULL;
}
