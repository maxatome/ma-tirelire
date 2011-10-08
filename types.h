/* 
 * types.h -- 
 * 
 * Author          : Max Root
 * Created On      : Sat Jul  6 15:14:01 2002
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Jul 16 14:22:36 2007
 * Update Count    : 4
 * Status          : Unknown, Use with caution!
 */

#ifndef	__TYPES_H__
#define	__TYPES_H__

#ifndef EXTERN_TYPES
#define EXTERN_TYPES extern
#endif

#ifdef __FreeBSD__
typedef unsigned char	uint8;
typedef		 char	int8;
typedef unsigned short	uint16;
typedef		 short	int16;
typedef unsigned int	uint32;
typedef		 int	int32;
# include <string.h>
# include <stdlib.h>
# define Malloc		malloc
# define Free		free
# define StrCompare	strcmp
# define MemCmp		bcmp
# define MemMove	memcpy
# define Realloc	realloc
# define MemSet(p,l,c)	memset(p,c,l)
# define StrAToI(s)	strtod(s, NULL);
# define StrLen		strlen
typedef unsigned int	Boolean;
# define true		1
# define false		0
#else
# include <PalmCompatibility.h>
typedef UChar		uint8;
typedef	Char		int8;
typedef Word		uint16;
typedef	SWord		int16;
typedef DWord		uint32;
typedef	SDWord		int32;
EXTERN_TYPES void *MemPtrRealloc(void *pv_buffer, uint32 ui_size);
# define Malloc		MemPtrNew
# define Free		MemPtrFree
# define Realloc	MemPtrRealloc
#endif

typedef unsigned long long UInt64;
typedef		 long long Int64;

typedef Int32	        t_amount;

#define INT16_MAX	0x7fff
#define INT16_MIN	(-0x7fff - 1)
#define UINT16_MAX	0xffff
#define INT32_MAX	0x7fffffff
#define INT32_MIN	(-0x7fffffff - 1)
#define UINT32_MAX	0xffffffffU

#ifndef NULL
# define NULL	((void*)0)
#endif

#define nil	((void*)0)

#endif	/* __TYPES_H__ */
