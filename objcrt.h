/* 
 * objcrt.h -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Mon Jul  2 11:28:38 2007
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Jul  2 11:35:41 2007
 * Update Count    : 2
 * Status          : Unknown, Use with caution!
 */

#ifndef	__OBJCRT_H__
#define	__OBJCRT_H__

#ifndef EXTERN_OBJCRT
# define EXTERN_OBJCRT extern
#endif

struct s_objc_class
{
  struct s_objc_class *oNextClass; /* Class hash info */

  struct s_objc_class *oIsa;
  struct s_objc_class *oSuper;
  const char *pa_name;
  uint16 uh_size;
};

#endif	/* __OBJCRT_H__ */
