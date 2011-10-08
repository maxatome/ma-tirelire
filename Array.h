/* -*- objc -*-
 * Array.h -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Wed Feb 22 10:18:00 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Mar 20 11:16:59 2006
 * Update Count    : 17
 * Status          : Unknown, Use with caution!
 */

#ifndef	__ARRAY_H__
#define	__ARRAY_H__

#include "Object.h"

#ifndef EXTERN_ARRAY
# define EXTERN_ARRAY extern
#endif

@interface Array : Object
{
  MemHandle pv_base;

  UInt16 uh_nb_elem;
}

+ (Array*)new;

- (MemHandle*)_grow;
- (void)_shrink;

- (Boolean)push:(MemHandle)pv_elem;
- (MemHandle)pop;

- (Boolean)unshift:(MemHandle)pv_elem;
- (MemHandle)shift;

- (void)move:(Int16)h_from before:(Int16)h_to;

- (MemHandle)remove:(Int16)h_index;
- (MemHandle)fetch:(Int16)h_index;
- (Boolean)insert:(MemHandle)pv_elem before:(Int16)h_index;

- (UInt16)size;

typedef Int16 (*tf_array_cmp)(void*, void*, Int32);

- (void)sortFunc:(tf_array_cmp)pf_sort param:(Int32)i_param;

- (Int16)find:(MemHandle)pv_elem;

@end

#endif	/* __ARRAY_H__ */
