/* -*- objc -*-
 * object.h -- 
 * 
 * Author          : Max Root
 * Created On      : Sat Jul  6 14:26:47 2002
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Jan 14 17:39:00 2008
 * Update Count    : 18
 * Status          : Unknown, Use with caution!
 */

#ifndef	__OBJECT_H__
#define	__OBJECT_H__

#ifdef __palmos__
# include <PalmOS.h>
#endif

#include "types.h"
#include "classes.h"

#ifndef EXTERN_OBJECT
# define EXTERN_OBJECT extern
#endif

@interface Object
{
}

+ (void)initialize:(Boolean)b_globals;
+ (void)deinitialize:(Boolean)b_globals;

+ (Object*)alloc;
+ (Object_c*)superClass;
+ (Boolean)isSubclassOf:(id)oOther;
+ (Object_c*)findClass:(char*)pa_class_name;

- (Object*)free;
- (Object*)freeContents;
- (const char *)className;
- (Object*)copy;
- (Object*)deepCopy;
- (Boolean)isKindOf:(id)oClass;
- (Boolean)isMemberOf:(id)oClass;
- (Object_c*)class;
- (Boolean)isEqual:(Object*)oOther;

@end

#ifdef __palmos__
EXTERN_OBJECT void ObjcLoadClasses(Boolean b_globals);
EXTERN_OBJECT void ObjcUnloadClasses(Boolean b_globals);
# ifdef FEATURE_CLASSES
EXTERN_OBJECT Object_c **ObjcGetClasses(void);
# else
EXTERN_OBJECT void special_pointer_set(void *pv_ptr);
EXTERN_OBJECT void *special_pointer_get(void);
#  define ObjcGetClasses()	((Object_c **)special_pointer_get())
# endif
#endif

EXTERN_OBJECT void free_all_classes(void);
EXTERN_OBJECT void free_object(void *pv_object);

#endif	/* __OBJECT_H__ */
