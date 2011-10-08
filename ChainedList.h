/* -*- objc -*-
 * ChainedList.h -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Tue Feb 21 11:29:47 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Feb 21 17:27:43 2006
 * Update Count    : 9
 * Status          : Unknown, Use with caution!
 */

#ifndef	__CHAINEDLIST_H__
#define	__CHAINEDLIST_H__

#include "Object.h"

#ifndef EXTERN_CHAINEDLIST
# define EXTERN_CHAINEDLIST extern
#endif

struct s_chained_list_node
{
  MemHandle *pv_next;
  MemHandle *pv_prev;
  void rv_data[0];
};

@interface ChainedList : Object
{
  MemHandle pv_first;
  MemHandle pv_last;

  MemHandle pv_current;

  UInt16 uh_nb_elements;
}

+ (ChainedList*)new;

- (void)resetToFirst;
- (void)resetToLast;

- (void*)addFirst:(UInt16)uh_size;
- (void*)addLast:(UInt16)uh_size;
- (void*)addBefore:(UInt16)uh_size;
- (void*)addAfter:(UInt16)uh_size;

- (Boolean)delFirst;
- (Boolean)delLast;
- (Boolean)del;

- (void*)get;
- (MemHandle)getHandle;
- (void*)getHandleIndex:(UInt16)uh_index;
- (void*)getIndex:(UInt16)uh_index;

- (void*)next;
- (void*)prev;

@end

#endif	/* __CHAINEDLIST_H__ */
