/* 
 * float.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Tue Aug 26 22:52:07 2003
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__FLOAT_H__
#define	__FLOAT_H__

#include <PalmOS.h>

#ifndef EXTERN_FLOAT
#define EXTERN_FLOAT extern
#endif

#define DOUBLE_STR_SIZE	(1+10+1+10+1)

EXTERN_FLOAT Boolean isStrAToInt32(UInt8 *pua_str, Int32 *pi_num);
EXTERN_FLOAT Char *StrUInt32ToA(UInt8 *pua_str, UInt32 ui_num, UInt16*puh_len);

EXTERN_FLOAT Boolean isStrAToDouble(UInt8 *pua_str, double *pd_float);
EXTERN_FLOAT Char *StrDoubleToA(UInt8 *pua_str, double d_num, UInt16 *puh_len,
				Char a_dec_separator, UInt16 uh_dec_len);

EXTERN_FLOAT Boolean isStrATo100F(Char *ptr, Int32 *pl_float);
EXTERN_FLOAT Char *Str100FToA(UInt8 *pua_str, Int32 num, UInt16 *puh_len,
			      Char a_dec_separator);

EXTERN_FLOAT Char float_dec_separator(void);

#endif	/* __FLOAT_H__ */
