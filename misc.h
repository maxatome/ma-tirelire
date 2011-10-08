/* 
 * misc.h -- 
 * 
 * Author          : Max Root
 * Created On      : Sun Jan  5 17:10:46 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb  1 17:37:03 2008
 * Update Count    : 17
 * Status          : Unknown, Use with caution!
 */

#ifndef	__MISC_H__
#define	__MISC_H__

#include <Unix/unix_stdarg.h>
#include <PalmOS.h>

#ifndef EXTERN_MISC
# define EXTERN_MISC extern
#endif

#define STRINGIFY2(x) #x
#define STRINGIFY(x) STRINGIFY2(x)

struct s_misc_infos
{
  DateType s_today;
  UInt16   uh_daymonth:1;	// 1 si DD/MM, 0 si MM/DD
  UInt16   uh_date_width:6;
  UInt16   uh_amount_width:8;
  UInt16   uh_max_amount_width:8; // Dans la liste des comptes et stats
  Char	   a_date_separator;
  Char	   a_dec_separator;	// Decimal separator
};



EXTERN_MISC void *FormObjectPtr(FormPtr pt_frm, UInt16 uh_obj_id);

EXTERN_MISC void WinInvertColors(void);
EXTERN_MISC void WinInvertRectangleColor(RectangleType *ps_rect);

EXTERN_MISC void WinDrawTruncatedChars(const Char *pa_str, Int16 h_len,
				       Coord x, Coord y, Int16 h_width);

EXTERN_MISC WinHandle DrawFrame(PointType *ppoint_win,
				UInt16 *puh_lines,
				UInt16 uh_hfont,
				RectangleType *prec_win,
				Boolean b_colored);

EXTERN_MISC Boolean match(Char *pa_wildcard, Char *pa_string, Boolean b_exact);

EXTERN_MISC Char *truncate_name(Char *pa_orig, UInt16 *puh_len,
				UInt16 uh_max_width, Char *pa_copy);

EXTERN_MISC Int16 prepare_truncating(Char *pa_str, UInt16 *puh_len,
				     UInt16 uh_max_width);

EXTERN_MISC void load_and_fit(UInt16 uh_id, Char *pa_buf, UInt16 *puh_largest);

EXTERN_MISC Char ellipsis(UInt16 *puh_width);

EXTERN_MISC void init_misc_infos(struct s_misc_infos *ps_infos,
				 FontID uh_std_font, FontID uh_bold_font);

EXTERN_MISC void infos_short_date(struct s_misc_infos *ps_infos,
				  DateType s_date, Char *pa_buf);

EXTERN_MISC void __alert_error(Char *pa_text, Err error);

#define alert_error(error)					\
  __alert_error(__FILE__ ":" STRINGIFY(__LINE__), error)

EXTERN_MISC void __alert_error_str(Char *pa_fmt, ...);

#define alert_error_str(pa_fmt, args...)				\
  __alert_error_str(__FILE__ ":" STRINGIFY(__LINE__) " " pa_fmt , ## args)

#define alert_error_str_if(cond, pa_fmt, args...)	\
  do { if (cond) alert_error_str(pa_fmt , ## args); } while (0)

EXTERN_MISC void winprintf(Char *pa_fmt, ...);

EXTERN_MISC Boolean is_empty(Char *pa_str);

#define offsetof(type, field) ((UInt32)(&((type *)0)->field))

EXTERN_MISC Int16 sort_string_compare(Char *pa_str1, Char *pa_str2, Int32);

#define ABS(l_amount) (((l_amount) ^ ((l_amount) >> (sizeof(l_amount) * 8 - 1)))\
		       - ((l_amount) >> (sizeof(l_amount) * 8 - 1)))
#define SWAP(a, b)    (((a) ^= (b)), ((b) ^= (a)), ((a) ^= (b)))


//
// Manipulation de bits (from BSD selct.h)
#define NBBY    8UL			/* number of bits in a byte */

#define NBITS (sizeof(UInt32) * NBBY)	/* bits per mask */

#define DWORDFORBITS(bits) (((UInt32)(bits) + (NBITS - 1)) / NBITS)
#define BYTESFORBITS(bits) (DWORDFORBITS(bits) * sizeof(UInt32))

#define _bit_mask(n)  ((UInt32)1 << ((UInt32)(n) % NBITS))

#define BIT_SET(n, pul_state)	 (pul_state[(n)/NBITS] |= _bit_mask(n))
#define BIT_CLR(n, pul_state)	 (pul_state[(n)/NBITS] &= ~_bit_mask(n))
#define BIT_ISSET(n, pul_state)	 (pul_state[(n)/NBITS] & _bit_mask(n))

// Inverse le bit et renvoie la nouvelle valeur 0 ou != 0
// XXX visiblement provoque des problèmes de pile XXX
#if 0
# define BIT_INV(n, pul_state) \
	({ \
	    UInt32 *pul_select = &pul_state[(n)/NBITS]; \
	    UInt32 ui_mask = _bit_mask(n); \
	    *pul_select ^= ui_mask; /* Inversion */ \
	    *pul_select & ui_mask;  /* Retour */ \
	})
#endif

EXTERN_MISC void not_enough_space_alert(UInt32 ui_size,
					Char *pa_file,
					UInt16 uh_line);

#define NEW_ERROR(ui_size, failure_inst) \
	({ \
	   not_enough_space_alert(ui_size, __FILE__, __LINE__); \
	   failure_inst; \
	})

#define NEW_GENERIC(pf_alloc, pv_ptr, ui_size, failure_inst) \
	({ \
	   UInt32 __ui_size = ui_size; \
	   pv_ptr = pf_alloc(__ui_size); \
	   if (pv_ptr == NULL) \
	     NEW_ERROR(__ui_size, failure_inst); \
	})


#define NEW_HANDLE(pv_ptr, ui_size, failure_inst) \
	NEW_GENERIC(MemHandleNew, pv_ptr, ui_size, failure_inst)

#define NEW_PTR(pv_ptr, ui_size, failure_inst) \
	NEW_GENERIC(MemPtrNew, pv_ptr, ui_size, failure_inst)

#endif	/* __MISC_H__ */
