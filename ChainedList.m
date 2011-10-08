/* 
 * ChainedList.m -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Tue Feb 21 11:29:44 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Wed Jun 27 18:30:34 2007
 * Update Count    : 5
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author$
 * $Log$
 * ==================== RCS ==================== */

#define EXTERN_CHAINEDLIST
#include "ChainedList.h"


@implementation ChainedList

+ (ChainedList*)new
{
  return [self alloc];
}


- (ChainedList*)free
{
  if (self->pv_first != NULL)
  {
    struct s_chained_list_node *ps_cur;
    MemHandle pv_cur, pv_tmp;

    pv_cur = pv_tmp = self->pv_last;
    ps_cur = MemHandleLock(pv_cur);
    pv_cur = ps_cur->pv_prev;
    MemHandleUnlock(pv_tmp);

    while (pv_cur != NULL)
    {
    }

    MemHandleFree(XXX);
  }
}


- (void)resetToFirst
{
}


- (void)resetToLast
{
}


@end
