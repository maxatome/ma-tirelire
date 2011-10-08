/* 
 * winprintf.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Tue Mar 23 23:58:09 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jan 11 13:42:29 2008
 * Update Count    : 9
 * Status          : Unknown, Use with caution!
 */

#ifndef	__WINPRINTF_H__
#define	__WINPRINTF_H__

#ifdef WITHOUT_WINPRINTF
# define WinPrintf(formatStr, args...)
# define ClipPrintf(formatStr, args...)
# define DrawPrintf(formatStr, args...)
#else
# define XXXPrintf(add, func, formatStr, args...)	\
	({ \
	  Char *pa_buf = MemPtrNew(200); \
	  Char *pa_plus __attribute__ ((unused)) = pa_buf + 200; \
	  StrPrintF(pa_buf, formatStr , ## args); \
	  func; \
	  MemPtrFree(pa_buf); \
	  add; \
	})

# define WinPrintf(formatStr, args...) \
	XXXPrintf(, FrmCustomAlert(5, pa_buf, "", ""), formatStr , ## args)

# define ClipPrintf(formatStr, args...) \
	XXXPrintf(, ClipboardAppendItem(clipboardText, pa_buf, StrLen(pa_buf)),\
		  formatStr , ## args)

# define DrawPrintf(formatStr, args...) \
	XXXPrintf(SysTaskDelay(SysTicksPerSecond() * 10), \
		  WinDrawChars(pa_buf, StrLen(pa_buf), 20, 0),		\
		  formatStr , ## args)
#endif

// A utiliser uniquement dans les WinPrintf
#define double2str(d_num)						\
  (pa_plus = StrDoubleToA(pa_plus - DOUBLE_STR_SIZE, d_num, NULL, '.', 9))

#define seconds2str(ui_seconds)						\
  ({									\
    Char *pa_str;							\
    DateTimeType s_last_update_date;					\
    TimSecondsToDateTime(ui_seconds, &s_last_update_date);		\
    pa_plus -= dateStringLength + timeStringLength;			\
    DateToAscii(s_last_update_date.month, s_last_update_date.day,	\
		s_last_update_date.year,				\
		(DateFormatType)PrefGetPreference(prefDateFormat), pa_plus); \
    pa_str = pa_plus + StrLen(pa_plus);					\
    *pa_str++ = ' ';							\
    TimeToAscii(s_last_update_date.hour, s_last_update_date.minute,	\
		(TimeFormatType)PrefGetPreference(prefTimeFormat), pa_str); \
    pa_plus;								\
  })

#endif	/* __WINPRINTF_H__ */
