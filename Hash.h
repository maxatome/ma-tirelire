/* -*- objc -*-
 * Hash.h -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Fri Dec 21 14:25:19 2007
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Jan 10 19:15:44 2008
 * Update Count    : 20
 * Status          : Unknown, Use with caution!
 */

#ifndef	__HASH_H__
#define	__HASH_H__

#include "Object.h"

#ifndef EXTERN_HASH
# define EXTERN_HASH extern
#endif

@interface Hash : Object
{
  MemHandle pv_array;

  Int32 i_max_line;		// last element of pv_array
  UInt32 ui_nb_elem;		// how many elements in the hash

  // Iterator
  Int32 i_iter_root;
  struct s_hash_key *ps_iter_cur;

  Boolean b_lazy_delete;
}

+ (Hash*)new;
- (Hash*)init;

- (MemHandle)fetchKey:(Char*)pa_key len:(Int16)i_len;
- (MemHandle)store:(MemHandle)pv_elem atKey:(Char*)pa_key len:(Int16)i_len;
- (MemHandle)deleteKey:(Char*)pa_key len:(Int16)i_len;

- (UInt32)iterInit;
- (Boolean)iterNextKey:(Char**)ppa_key len:(UInt16*)pui_len
		 value:(MemHandle*)ppv_elem;

- (UInt32)size;

- (struct s_hash_key*)fetchCommonKey:(Char*)pa_key len:(Int16)h_len
				hash:(UInt32)ui_hash
			       value:(MemHandle*)ppv_elem;
- (void)_increaseArray;

@end

#endif	/* __HASH_H__ */
