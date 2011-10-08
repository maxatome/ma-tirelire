/* 
 * ExportForm.m -- 
 * 
 * Author          : Charlie Root
 * Created On      : Sam oct  8 13:49:55 2005
 * Last Modified By: Maxime Soule
 * Last Modified On: Tue Oct 31 16:54:49 2006
 * Update Count    : 2
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: ExportForm.m,v $
 * Revision 1.3  2006/11/04 23:48:06  max
 * Now call -exportInit instead of exportNumLines when export begins, and
 * -exportEnd when it ends.
 *
 * Revision 1.2  2006/06/23 13:24:43  max
 * Now call -focusObject: instead of FrmSetFocus() to set focus to a field.
 *
 * Revision 1.1  2005/10/11 18:58:04  max
 * First import.
 *
 * ==================== RCS ==================== */

#include <Unix/unix_stdarg.h>

#define EXTERN_EXPORTFORM
#include "ExportForm.h"

#include "MaTirelire.h"
#include "SumListForm.h"

#include "ProgressBar.h"

#include "MaTirelireDefs.h"
#include "objRsc.h"		// XXX

#include "float.h"


#define MEMO_PREFIX	"MT2 - "

#define SEP_CHAR	';'
#define SEP_STR		";"


@implementation ExportForm

- (Boolean)open
{
  [super open];

  // On place le focus sur le premier champ de la boîte
  [self focusObject:ExportName];

  return true;
}


- (Boolean)ctlSelect:(struct ctlSelect *)ps_select
{
  switch (ps_select->controlID)
  {
  case ExportExport:
    if ([self checkField:ExportName flags:FLD_CHECK_VOID
            resultIn:self->ra_title fieldName:strExportName] == false)
      break;

    self->uh_title_len = StrLen(self->ra_title);

    self->oSumScrollList
      = (SumScrollList*)((SumListForm*)self->oPrevForm)->oList;

    self->uh_headers_id = [self->oSumScrollList exportFormat:self->ra_format];

    self->e_date_format = (DateFormatType)PrefGetPreference(prefDateFormat);
    self->e_time_format = (TimeFormatType)PrefGetPreference(prefTimeFormat);

    self->b_dont_split = CtlGetValue([self objectPtrId:ExportDontSplit]);

    [self _export];

    // Et on quitte...

  case ExportCancel:
    [self returnToLastForm];
    break;

  default:
    return false;
  }

  return true;
}


//
// Si ne contient ni ';', ni '"' renvoie StrLen
// Si ';' ou '"', ajout de '"' en début et en fin et tous les '"' sont
// doublés dans la chaîne
static UInt32 export_get_str_size(Char *pa_str, Boolean *pb_is_enclosed)
{
  Boolean b_is_enclosed = false;
  UInt32 ul_size = 0;

  for (; *pa_str; pa_str++)
  {
    switch (*pa_str)
    {
    case '"':
      ul_size++;		/* Les '"' sont doublés */

      /* On continue sur '\n' et ';' */

    case '\n':
    case SEP_CHAR:
      if (b_is_enclosed == false) /* '"' ou ';' il faut entourer de '"' */
      {
	b_is_enclosed = true;
	ul_size += 2;
      }
      break;
    }

    ul_size++;
  }

  if (pb_is_enclosed != NULL)
    *pb_is_enclosed = b_is_enclosed;

  return ul_size;
}


static void export_save_str(Char *pa_memo, UInt32 *pul_offset, Char *pa_str)
{
  Boolean b_is_enclosed;
  UInt32 ul_size = export_get_str_size(pa_str, &b_is_enclosed);

  if (ul_size > 0)
  {
    Char ra_tmp[ul_size], *pa_tmp;

    pa_tmp = ra_tmp;

    // Entre '"'
    if (b_is_enclosed)
      *pa_tmp++ = '"';

    for (; *pa_str; pa_str++)
    {
      // On double les '"'
      if (*pa_str == '"')
	*pa_tmp++ = '"';

      *pa_tmp++ = *pa_str;
    }

    // Entre '"'
    if (b_is_enclosed)
      *pa_tmp = '"';

    // Sauvegarde
    DmWrite(pa_memo, *pul_offset, ra_tmp, ul_size);
    *pul_offset += ul_size;
  }
}


- (void)exportLine:(Char*)pa_base_format, ...
{
  Char ra_num[1 + 10 + 1 + 1], *pa_format;
  va_list ap;
  UInt16 uh_size, uh_len;

  va_start(ap, pa_base_format);

  // pas de format particulier pour cette ligne, on utilise le format
  // par défaut
  if (pa_base_format == NULL)
    pa_base_format = self->ra_format;

  // On regarde d'abord la taille
  uh_size = 0;
  pa_format = pa_base_format;
  for (;;)
  {
    switch (*pa_format++)
    {
    case '\0':
      goto end1;

    case 's':
      uh_size += export_get_str_size(va_arg(ap, Char*), NULL);
      break;

    case 'u':
      StrUInt32ToA(ra_num, va_arg(ap, UInt32), &uh_len);
      uh_size += uh_len;
      break;

    case 'f':
      Str100FToA(ra_num, va_arg(ap, Int32), &uh_len,
		 oMaTirelire->s_misc_infos.a_dec_separator);
      uh_size += uh_len;
      break;

    case 'd':
    {
      DateType s_date;
      DateToInt(s_date) = va_arg(ap, UInt32);
      DateToAscii(s_date.month, s_date.day, s_date.year + firstYear,
		  self->e_date_format, ra_num);
      uh_size += StrLen(ra_num);
    }
    break;

    case 't':
    {
      TimeType s_time;
      TimeToInt(s_time) = va_arg(ap, UInt32);
      TimeToAscii(s_time.hours, s_time.minutes, self->e_time_format, ra_num);
      uh_size += StrLen(ra_num);
    }
    break;

    case 'b':
      uh_size++;
      break;

    default:			// 'e' => skip
      (void)va_arg(ap, void*);
      break;
    }

    uh_size++;			// Séparateur ou fin de ligne
  }

 end1:
  if (self->b_dont_split == false && self->ul_memo_offset + uh_size > 4000)
    // On ferme le mémo courant
    [self _memoEnd];

  if (self->pv_memo == NULL)
    // On entame un nouveau mémo
    [self _memoStart:uh_size];
  else
  {
    MemHandleUnlock(self->pv_memo);

    self->pv_memo = DmResizeRecord(self->db, self->uh_memo_index,
				   self->ul_memo_offset + uh_size + 1);	// \0
    self->pa_memo = MemHandleLock(self->pv_memo);
  }

  // On écrit les arguments
  va_start(ap, pa_base_format);

  pa_format = pa_base_format;
  for (;;)
  {
    switch (*pa_format++)
    {
    case '\0':
      goto end2;

    case 's':
      export_save_str(self->pa_memo, &self->ul_memo_offset, va_arg(ap, Char*));
      break;

    case 'u':
      StrUInt32ToA(ra_num, va_arg(ap, UInt32), &uh_len);
  write_buf:
      DmWrite(self->pa_memo, self->ul_memo_offset, ra_num, uh_len);
      self->ul_memo_offset += uh_len;
      break;

    case 'f':
      Str100FToA(ra_num, va_arg(ap, Int32), &uh_len,
		 oMaTirelire->s_misc_infos.a_dec_separator);
      goto write_buf;
      break;

    case 'd':
    {
      DateType s_date;
      DateToInt(s_date) = va_arg(ap, UInt32);
      DateToAscii(s_date.month, s_date.day, s_date.year + firstYear,
		  self->e_date_format, ra_num);
      uh_len = StrLen(ra_num);
    }
    goto write_buf;

    case 't':
    {
      TimeType s_time;
      TimeToInt(s_time) = va_arg(ap, UInt32);
      TimeToAscii(s_time.hours, s_time.minutes, self->e_time_format, ra_num);
      uh_len = StrLen(ra_num);
    }
    goto write_buf;

    case 'b':
      ra_num[0] = va_arg(ap, UInt32) ? '1' : '0';
      uh_len = 1;
      goto write_buf;

    default:			// 'e' => skip
      (void)va_arg(ap, void*);
      break;
    }

    DmWrite(self->pa_memo, self->ul_memo_offset,
	    *pa_format ? SEP_STR : "\n", 1);
    self->ul_memo_offset++;
  }

 end2:

  va_end(ap);
}


- (void)_export
{
  PROGRESSBAR_DECL;
  Char ra_nb_parts[4 + 1];
  UInt16 index, uh_size, uh_nb_len;

  self->db = DmOpenDatabaseByTypeCreator((UInt32)'DATA', (UInt32)'memo',
					 dmModeWrite);

  [self _memoStart:0];

  uh_size = [self->oSumScrollList exportInit];

  PROGRESSBAR_BEGIN(uh_size, strProgressBarExport);

  for (index = 0; index < uh_size; index++)
  {
    [self->oSumScrollList exportLine:index with:self];

    PROGRESSBAR_INLOOP(index, 25);
  }

  [self->oSumScrollList exportEnd];

  [self _memoEnd];

  PROGRESSBAR_END;

  // On re-parcourt tous les mémos créés pour ajouter le nombre de parties
  uh_nb_len = StrPrintF(ra_nb_parts, "%u", self->uh_memo_part);
  for (index = self->uh_memo_index_first;
       index < self->uh_memo_index_first + self->uh_memo_part; index++)
  {
    MemHandle vh_memo;
    Char *pa_memo;

    uh_size = MemHandleSize(DmQueryRecord(self->db, index));

    vh_memo = DmResizeRecord(self->db, index, uh_size + uh_nb_len);
    if (vh_memo != NULL)
    {
      pa_memo = MemHandleLock(vh_memo);

      DmWrite(pa_memo, self->uh_nb_parts_offset + uh_nb_len,
	      pa_memo + self->uh_nb_parts_offset,
	      uh_size - self->uh_nb_parts_offset);

      DmWrite(pa_memo, self->uh_nb_parts_offset, ra_nb_parts, uh_nb_len);

      MemHandleUnlock(vh_memo);

      DmReleaseRecord(self->db, index, true);
    }
  }

  DmCloseDatabase(self->db);
}


- (void)_memoStart:(UInt16)uh_add
{
  Char ra_tmp[64];
  UInt16 uh_len, uh_headers_size, index, uh_num_cols;

  self->uh_memo_part++;

  // La taille des en-têtes
  uh_num_cols = StrLen(self->ra_format);
  uh_headers_size = 0;
  for (index = 0; index < uh_num_cols; index++)
  {
    SysStringByIndex(self->uh_headers_id, index, ra_tmp, sizeof(ra_tmp));
    uh_headers_size += export_get_str_size(ra_tmp, NULL) + 1;
  }

  // Les espaces sont pour mettre le nombre de parties à la fin...
  uh_len = StrPrintF(ra_tmp, " - %u/\n", self->uh_memo_part);

  self->uh_memo_index = dmMaxRecordIndex;
  self->pv_memo = DmNewRecord(self->db, &self->uh_memo_index,
			      sizeof(MEMO_PREFIX) // dont \0 de fin de mémo
			      + self->uh_title_len
			      + uh_len + uh_headers_size + uh_add);

  // On sauvegarde l'index du premier mémo créé et la position de du
  // nombre de parties dans le memo
  if (self->uh_memo_part == 1)
  {
    self->uh_memo_index_first = self->uh_memo_index;
    self->uh_nb_parts_offset
      = sizeof(MEMO_PREFIX) - 1 + self->uh_title_len + uh_len - 1;
  }

  self->pa_memo = MemHandleLock(self->pv_memo);

  DmWrite(self->pa_memo, 0, MEMO_PREFIX, sizeof(MEMO_PREFIX) - 1);

  DmWrite(self->pa_memo, sizeof(MEMO_PREFIX) - 1,
	  self->ra_title, self->uh_title_len);
  self->ul_memo_offset = sizeof(MEMO_PREFIX) - 1 + self->uh_title_len;

  DmWrite(self->pa_memo, self->ul_memo_offset, ra_tmp, uh_len);
  self->ul_memo_offset += uh_len;

  // Les en-têtes
  for (index = 0; index < uh_num_cols; index++)
  {
    SysStringByIndex(self->uh_headers_id, index, ra_tmp, sizeof(ra_tmp));

    export_save_str(self->pa_memo, &self->ul_memo_offset, ra_tmp);

    DmWrite(self->pa_memo, self->ul_memo_offset,
	    index < uh_num_cols - 1 ? SEP_STR : "\n", 1);
    self->ul_memo_offset++;
  }
}


- (void)_memoEnd
{
  // La fin de chaîne : '\0'
  DmWrite(self->pa_memo, self->ul_memo_offset, "", 1);

  MemHandleUnlock(self->pv_memo);
  DmReleaseRecord(self->db, self->uh_memo_index, true);

  self->pv_memo = NULL;
  self->ul_memo_offset = 0;
}

@end
