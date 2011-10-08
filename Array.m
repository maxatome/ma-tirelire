/* 
 * Array.m -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Wed Feb 22 10:17:57 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Dec 21 14:39:08 2007
 * Update Count    : 37
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: Array.m,v $
 * Revision 1.2  2008/01/14 17:25:45  max
 * Minor corrections.
 *
 * Revision 1.1  2006/06/19 12:23:44  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_ARRAY
#include "Array.h"

#include "misc.h"


@implementation Array

+ (Array*)new
{
  return [self alloc];
}


- (Array*)free
{
  if (self->pv_base != NULL)
    MemHandleFree(self->pv_base);

  return [super free];
}


- (Array*)freeContents
{
  if (self->pv_base != NULL)
  {
    MemHandle *ppv_cur = MemHandleLock(self->pv_base);

    while (self->uh_nb_elem-- > 0)
      MemHandleFree(*ppv_cur++);

    MemHandleUnlock(self->pv_base);

    MemHandleFree(self->pv_base);
    self->pv_base = NULL;
    self->uh_nb_elem = 0;
  }

  return self;
}


- (MemHandle*)_grow
{
  if (self->pv_base == NULL)
    NEW_HANDLE(self->pv_base, sizeof(MemHandle), return NULL);
  else
  {
    UInt32 ui_size = (UInt32)(self->uh_nb_elem + 1) * sizeof(MemHandle);

    if (MemHandleResize(self->pv_base, ui_size))
      NEW_ERROR(ui_size, return NULL);
  }

  self->uh_nb_elem++;

  return MemHandleLock(self->pv_base);
}


- (void)_shrink
{
  if (self->uh_nb_elem > 0)
    MemHandleResize(self->pv_base,
		    (UInt32)self->uh_nb_elem * sizeof(MemHandle));
  else
  {
    MemHandleFree(self->pv_base);
    self->pv_base = NULL;
  }
}


- (Boolean)push:(MemHandle)pv_elem
{
  MemHandle *ppv_cur;

  ppv_cur = [self _grow];
  if (ppv_cur == NULL)
    return false;

  ppv_cur[self->uh_nb_elem - 1] = pv_elem;

  MemHandleUnlock(self->pv_base);

  return true;
}


- (MemHandle)pop
{
  MemHandle *ppv_cur, pv_ret;

  if (self->pv_base == NULL)
    return NULL;

  ppv_cur = MemHandleLock(self->pv_base);

  pv_ret = ppv_cur[--self->uh_nb_elem];

  MemHandleUnlock(self->pv_base);

  [self _shrink];

  return pv_ret;
}


- (Boolean)unshift:(MemHandle)pv_elem
{
  MemHandle *ppv_cur;

  ppv_cur = [self _grow];
  if (ppv_cur == NULL)
    return false;

  MemMove(&ppv_cur[1], &ppv_cur[0],
	  (UInt32)(self->uh_nb_elem - 1) * sizeof(MemHandle));

  ppv_cur[0] = pv_elem;

  MemHandleUnlock(self->pv_base);

  return true;
}


- (MemHandle)shift
{
  MemHandle *ppv_cur, pv_ret;

  if (self->pv_base == NULL)
    return NULL;

  ppv_cur = MemHandleLock(self->pv_base);

  pv_ret = ppv_cur[0];

  if (--self->uh_nb_elem > 0)
  {
    UInt32 ui_new_size = (UInt32)self->uh_nb_elem * sizeof(MemHandle);

    MemMove(&ppv_cur[0], &ppv_cur[1], ui_new_size);

    MemHandleUnlock(self->pv_base);

    MemHandleResize(self->pv_base, ui_new_size);
  }
  else
  {
    MemHandleUnlock(self->pv_base);

    MemHandleFree(self->pv_base);
    self->pv_base = NULL;
  }

  return pv_ret;
}


//
// h_to est la position d'insertion
//
// 012345
// ABCDE
//
// from=1 to=4 => ACDBE
// from=4 to=1 => AEBCD
- (void)move:(Int16)h_from before:(Int16)h_to
{
  MemHandle *ppv_cur, pv_tmp;

  if (self->pv_base == NULL)
    return;

  if (h_from < 0)
  {
    h_from = self->uh_nb_elem + h_from;
    if (h_from < 0)
      return;
  }
  if (h_from >= self->uh_nb_elem)
    return;

  // On est plus souple pour h_to
  if (h_to < 0)
  {
    h_to = self->uh_nb_elem + h_to;
    if (h_to < 0)
      h_to = 0;
  }
  else if (h_to > self->uh_nb_elem)
    h_to = self->uh_nb_elem;
  else if (h_from == h_to || h_from == h_to + 1)
    return;

  ppv_cur = MemHandleLock(self->pv_base);

  pv_tmp = ppv_cur[h_from];

  if (h_to < h_from)
  {
    MemMove(&ppv_cur[h_to + 1], &ppv_cur[h_to],
	    (UInt32)(h_from - h_to) * sizeof(MemHandle));
    ppv_cur[h_to] = pv_tmp;
  }
  else
  {
    MemMove(&ppv_cur[h_from], &ppv_cur[h_from + 1],
	    (UInt32)(h_to - h_from - 1) * sizeof(MemHandle));
    ppv_cur[h_to - 1] = pv_tmp;
  }

  MemHandleUnlock(self->pv_base);
}


- (MemHandle)remove:(Int16)h_index
{
  MemHandle *ppv_cur, pv_ret;

  if (self->pv_base == NULL)
    return NULL;

  if (h_index < 0)
  {
    h_index = self->uh_nb_elem + h_index;
    if (h_index < 0)
      return NULL;
  }

  if (h_index >= self->uh_nb_elem)
    return NULL;

  ppv_cur = MemHandleLock(self->pv_base);

  pv_ret = ppv_cur[h_index];

  self->uh_nb_elem--;
  MemMove(&ppv_cur[h_index], &ppv_cur[h_index + 1],
	  (UInt32)(self->uh_nb_elem - h_index) * sizeof(MemHandle));

  MemHandleUnlock(self->pv_base);

  [self _shrink];

  return pv_ret;
}


- (MemHandle)fetch:(Int16)h_index
{
   MemHandle *ppv_cur, pv_ret;

  if (self->pv_base == NULL)
    return NULL;

  if (h_index < 0)
  {
    h_index = self->uh_nb_elem + h_index;
    if (h_index < 0)
      return NULL;
  }

  if (h_index >= self->uh_nb_elem)
    return NULL;

  ppv_cur = MemHandleLock(self->pv_base);

  pv_ret = ppv_cur[h_index];

  MemHandleUnlock(self->pv_base);

  return pv_ret;
}


- (Boolean)insert:(MemHandle)pv_elem before:(Int16)h_index
{
  MemHandle *ppv_cur;

  if (h_index < 0)
  {
    h_index = self->uh_nb_elem + h_index;
    if (h_index < 0)
      h_index = 0;
  }
  else if (h_index > self->uh_nb_elem)
    h_index = self->uh_nb_elem;

  if (self->pv_base == NULL || h_index == self->uh_nb_elem)
    return [self push:pv_elem];

  ppv_cur = [self _grow];
  if (ppv_cur == NULL)
    return false;

  MemMove(&ppv_cur[h_index + 1], &ppv_cur[h_index],
	  (UInt32)(self->uh_nb_elem - h_index - 1) * sizeof(MemHandle));

  ppv_cur[h_index] = pv_elem;

  MemHandleUnlock(self->pv_base);

  return true;
}


- (UInt16)size
{
  return self->uh_nb_elem;
}


struct s_array_sort
{
  tf_array_cmp pf_sort;
  Int32 i_param;
};

static Int16 __array_sort(MemHandle *ppv_1, MemHandle *ppv_2,
			  struct s_array_sort *ps_params)
{
  Int16 h_ret;

  h_ret = ps_params->pf_sort(MemHandleLock(*ppv_1), MemHandleLock(*ppv_2),
			     ps_params->i_param);

  MemHandleUnlock(*ppv_2);
  MemHandleUnlock(*ppv_1);

  return h_ret;
}

- (void)sortFunc:(tf_array_cmp)pf_sort param:(Int32)i_param
{
  struct s_array_sort s_infos;

  if (self->pv_base == NULL)
    return;

  s_infos.pf_sort = pf_sort;
  s_infos.i_param = i_param;

  SysInsertionSort(MemHandleLock(self->pv_base), self->uh_nb_elem,
		   sizeof(MemHandle), (CmpFuncPtr)__array_sort,
		   (Int32)&s_infos);

  MemHandleUnlock(self->pv_base);
}


- (Int16)find:(MemHandle)pv_elem
{
  MemHandle *ppv_cur;
  Int16 h_index;

  if (self->pv_base == NULL)
    return -1;

  ppv_cur = MemHandleLock(self->pv_base);

  for (h_index = self->uh_nb_elem; h_index-- > 0; )
    if (ppv_cur[h_index] == pv_elem)
      break;

  MemHandleUnlock(self->pv_base);

  return h_index;
}

@end
