/* -*- objc -*-
 * ExportForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sam oct  8 13:49:55 2005
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__EXPORTFORM_H__
#define	__EXPORTFORM_H__

#include "MaTiForm.h"

#include "SumScrollList.h"

#ifndef EXTERN_EXPORTFORM
# define EXTERN_EXPORTFORM extern
#endif

@interface ExportForm : MaTiForm
{
  SumScrollList *oSumScrollList;

  Char ra_format[16];		// 15 colonnes au maximum
  Char ra_title[24];		// Titre de chaque memo

  DmOpenRef db;

  MemHandle pv_memo;
  Char *pa_memo;

  UInt32 ul_memo_offset;
  UInt16 uh_memo_index;
  UInt16 uh_memo_index_first;
  UInt16 uh_memo_part;

  UInt16 uh_nb_parts_offset;
  UInt16 uh_title_len;
  UInt16 uh_headers_id;

  DateFormatType e_date_format;
  TimeFormatType e_time_format;

  Boolean b_dont_split;
}

- (void)exportLine:(Char*)pa_format, ...;
- (void)_export;

- (void)_memoStart:(UInt16)uh_add;
- (void)_memoEnd;

@end

#endif	/* __EXPORTFORM_H__ */
