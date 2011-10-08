/* 
 * misc.c -- 
 * 
 * Author          : Max Root
 * Created On      : Sun Jan  5 17:09:36 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Feb  1 18:27:32 2008
 * Update Count    : 15
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: misc.c,v $
 * Revision 1.11  2008/02/01 17:28:59  max
 * Correct crash in winprintf() and __alert_error_str().
 *
 * Revision 1.10  2008/02/01 17:07:06  max
 * Add winprintf() & __alert_error_str().
 * alert_error() function becomes __alert_error().
 * Add chrNumericSpace in is_empty().
 *
 * Revision 1.9  2008/01/14 12:55:13  max
 * New function is_empty().
 *
 * Revision 1.8  2006/04/25 08:48:27  max
 * Add not_enough_space_alert() function used in NEW_PTR/HANDLE() macros.
 *
 * Revision 1.7  2005/10/06 19:48:22  max
 * match() and __internal_match() now have a b_exact argument.
 * Not exact wildcards can be made exact with a '^' at the beginning.
 *
 * Revision 1.6  2005/08/28 10:02:42  max
 * Comment added.
 *
 * Revision 1.5  2005/08/20 13:07:21  max
 * Add DrawFrame() from ScrollList.m
 * -drawFrameAtPos:forLines:fontHeight:coord:color:.
 * Correct bug in truncate_name() when the string fits but can be shortened.
 *
 * Revision 1.4  2005/05/08 12:13:13  max
 * Add sort_string_compare() for generic name sorting.
 *
 * Revision 1.3  2005/03/27 15:38:32  max
 * String truncating is now multi-bytes chars compliant.
 * alert_error() imported from DBasePropForm.m and make it application wide.
 *
 * Revision 1.2  2005/03/02 19:02:56  max
 * Add OS4 dfMDYWithDashes short date format.
 *
 * Revision 1.1  2005/02/09 22:57:23  max
 * First import.
 *
 * ==================== RCS ==================== */

#include <PalmOSGlue/TxtGlue.h>

#define EXTERN_MISC
#include "misc.h"

#include "float.h"
#include "objRsc.h"		/* XXX */

#include "ids.h"


void *FormObjectPtr(FormPtr pt_frm, UInt16 uh_obj_id)
{
  return FrmGetObjectPtr(pt_frm, FrmGetObjectIndex(pt_frm, uh_obj_id));
}


//
// À utiliser seulement sur les OS >= 3.5
void WinInvertRectangleColor(RectangleType *ps_rect)
{
  IndexedColorType e_FieldBackground, e_ObjectSelectedFill, e_ObjectForeground;

  e_FieldBackground = UIColorGetTableEntryIndex(UIFieldBackground);
  e_ObjectSelectedFill = UIColorGetTableEntryIndex(UIObjectSelectedFill);
  e_ObjectForeground = UIColorGetTableEntryIndex(UIObjectForeground);

  WinPushDrawState();

  WinSetDrawMode(winSwap);
  WinSetPatternType(blackPattern);

  WinSetBackColor(e_FieldBackground);
  WinSetForeColor(e_ObjectSelectedFill);

  WinPaintRectangle(ps_rect, 0);

  // Deuxième passe
  WinSetBackColor(e_ObjectSelectedFill != e_ObjectForeground
		  ? e_ObjectForeground
		  : e_FieldBackground);
  WinSetForeColor(UIColorGetTableEntryIndex(UIObjectSelectedForeground));

  WinPaintRectangle(ps_rect, 0);

  WinPopDrawState();
}


//
// h_width >= 0, largeur de la chaîne y compris le futur '...'
// h_width < 0, idem WinDrawChars
void WinDrawTruncatedChars(const Char *pa_str, Int16 h_len,
			   Coord x, Coord y, Int16 h_width)
{
  WinDrawChars(pa_str, h_len, x, y);

  if (h_width >= 0)
  {
    UInt16 uh_ell_width;
    Char a_ell = ellipsis(&uh_ell_width);
    WinDrawChars(&a_ell, 1, x + h_width - uh_ell_width, y);
  }
}


//
// En couleur fait un WinPushDrawState(), ne pas oublier de faire un
// WinPopDrawState() au retour si le WinHandle est != NULL
WinHandle DrawFrame(PointType *ppoint_win,
		    UInt16 *puh_lines,
		    UInt16 uh_hfont,
		    RectangleType *prec_win,
		    Boolean b_colored)
{
  WinHandle win_handle;

  UInt16 uh_height;

  // Absisse et largeur du cadre
  prec_win->topLeft.x = 0;
  WinGetWindowExtent(&prec_win->extent.x, &uh_height);

  // Hauteur du cadre
  // N lignes + 4 == bordures du popup
  prec_win->extent.y = uh_hfont * *puh_lines + 4;
  if (prec_win->extent.y > uh_height) // Trop de lignes
  {
    // On réduit le nombre de lignes à afficher
    *puh_lines = (uh_height - 4) / uh_hfont;
    prec_win->extent.y = uh_hfont * *puh_lines + 4;
  }

  // Calcul de l'ordonnée en fonction de la hauteur et du point courant
  prec_win->topLeft.y = ppoint_win->y - (prec_win->extent.y >> 1);

  if ((Int16)prec_win->topLeft.y < 0)
    prec_win->topLeft.y = 0;
  else if (prec_win->topLeft.y + prec_win->extent.y > uh_height)
    prec_win->topLeft.y = uh_height - prec_win->extent.y;

  // On sauve le dessous du cadre
  win_handle = WinSaveBits(prec_win, &uh_height);
  if (win_handle != NULL)
  {
    if (b_colored)
    {
      WinPushDrawState();
      
      WinSetForeColor(UIColorGetTableEntryIndex(UIObjectFrame));
      WinSetBackColor(UIColorGetTableEntryIndex(UIObjectFill));
      WinSetTextColor(UIColorGetTableEntryIndex(UIObjectForeground));
    }

    // Le coin supérieur gauche
    *ppoint_win = prec_win->topLeft;

    // Dessin du rectangle
    WinEraseRectangle(prec_win, 0);
    prec_win->topLeft.x++;
    prec_win->topLeft.y++;
    prec_win->extent.x -= 3;
    prec_win->extent.y -= 3;
    WinDrawRectangleFrame(popupFrame, prec_win);

    // Coordonnées du texte
    prec_win->topLeft.x += 2;
  }

  return win_handle;
}


static Boolean __internal_match(Char *pa_wildcard, Char *pa_string,
				Boolean b_exact)
{
  UInt32 ui_size;
  WChar wa_chr, wa_chr_string;

  for (;;)
  {
    pa_wildcard += TxtGlueGetNextChar(pa_wildcard, 0, &wa_chr);

    switch (wa_chr)
    {
    case '\0':
    case '|':
      TxtGlueGetNextChar(pa_string, 0, &wa_chr_string);
      return b_exact == false || wa_chr_string == '\0';

    case '*':
      // On rassemble les '*' en une seule...
      for (;;)
      {
	ui_size = TxtGlueGetNextChar(pa_wildcard, 0, &wa_chr);

	if (wa_chr == '*')
	{
	  pa_wildcard += ui_size;
	  continue;
	}

	// On matche tout le reste => donc OK
	if (wa_chr == '\0' || wa_chr == '|')
	  return true;

	break;
      }

      do
      {
	if (__internal_match(pa_wildcard, pa_string, b_exact))
	  return true;

	pa_string += TxtGlueGetNextChar(pa_string, 0, &wa_chr_string);
      }
      while (wa_chr_string != '\0');

      return false;

    case '?':
      pa_string += TxtGlueGetNextChar(pa_string, 0, &wa_chr_string);
      if (wa_chr_string == '\0')
	return false;
      break;

      // Caractère d'échappement
    case '\\':
      pa_wildcard += TxtGlueGetNextChar(pa_wildcard, 0, &wa_chr);

      // Si le '\' est en dernier, alors c'est un caractère normal...
      if (wa_chr == '\0')
      {
	TxtGlueGetNextChar(pa_string, 0, &wa_chr_string);
	return wa_chr_string == '\\';
      }

      // Continue sur default...

    default:
      pa_string += TxtGlueGetNextChar(pa_string, 0, &wa_chr_string);
      if (wa_chr_string != wa_chr)
	return false;
      break;
    }
  }

  // Never reached
}


// Returns true when pa_string match pa_wildcard
//
// pa_wilcard can begin by a '!' to negate the whole result
//
// Each wildcard can contains '*' and '?' anywhere in them and are
// joined with the '|' char
Boolean match(Char *pa_wildcard, Char *pa_string, Boolean b_exact)
{
  UInt32 ui_size;
  Char *pa_base_wildcard;
  void *pv_again;
  WChar wa_chr;
  Boolean b_negate = false, b_match;

  ui_size = TxtGlueGetNextChar(pa_wildcard, 0, &wa_chr);
  switch (wa_chr)
  {
    // Negate the whole match (so it becomes exact)
  case '!':
    b_negate = true;

    // Continue

    // Make the match exact
  case '^':
    b_exact = true;
    pa_wildcard += ui_size;	/* ??????? C'est pas toujours 1 ???????? */
    break;
  }

  pa_base_wildcard = pa_wildcard;
  pv_again = &&again;

  for (;;)
  {
    for (;;)
    {
  next:
      TxtGlueGetNextChar(pa_wildcard, 0, &wa_chr);
      switch (wa_chr)
      {
	// Empty wildcard: always true (unless negate)
      case '\0':
      case '|':
	return b_negate == false;
      }

      b_match = b_negate ^ __internal_match(pa_wildcard, pa_string, b_exact);
      if (b_match)
	return true;

      // On passe au wildcard suivant
      for (;;)
      {
	pa_wildcard += TxtGlueGetNextChar(pa_wildcard, 0, &wa_chr);

	switch (wa_chr)
	{
	  // Fin du wildcard, pas de suivant
	case '\0':
	  if (b_negate)
	    return true;
	  goto *pv_again;

	  // Caractère d'échappement
	case '\\':
	  pa_wildcard += TxtGlueGetNextChar(pa_wildcard, 0, &wa_chr);

	  if (wa_chr == '\0')
	  {
	    if (b_negate)
	      return true;
	    goto *pv_again;
	  }
	  break;

	  // On vient de trouver un nouveau wildcard
	case '|':
	  goto next;
	}
      }
    }

 again:
    if (b_exact)
      return false;
    pv_again = &&again2;

 again2:
    // On passe au caractère suivant dans la chaîne dans laquelle on
    // effectue la recherche
    pa_string += TxtGlueGetNextChar(pa_string, 0, &wa_chr);

    // C'était la fin de la chaîne
    if (wa_chr == '\0')
      return false;

    // On réarme le wildcard
    pa_wildcard = pa_base_wildcard;
  }
}


/*
 * Renvoie pa_orig s'il n'y a pas eu de recopie dans pa_copy
 *         pa_copy si pa_orig a du être recopiée dans pa_copy
 * *puh_len contient la longueur de la chaîne renvoyée
 * pa_copy peut être égal à pa_orig, et peut être NULL s'il s'agit
 * juste d'obtenir puh_len. Si la chaîne doit être tronquée NULL est
 * alors renvoyé.
 */
Char *truncate_name(Char *pa_orig, UInt16 *puh_len, UInt16 uh_max_width,
		    Char *pa_copy)
{
  UInt16 uh_trunc_len, uh_cur_width;
  Boolean b_fit_in_str = false;

  uh_trunc_len = *puh_len;
  uh_cur_width = uh_max_width;
  FntCharsInWidth(pa_orig, &uh_cur_width, &uh_trunc_len, &b_fit_in_str);

  if (b_fit_in_str)
  {
    // uh_trunc_len peut être inférieur si pa_orig finit par au moins un espace
    if (uh_trunc_len < *puh_len)
    {
      *puh_len = uh_trunc_len;

      if (pa_orig != pa_copy)
	// Recopie du morceau de chaîne
	MemMove(pa_copy, pa_orig, uh_trunc_len);

      pa_copy[uh_trunc_len] = '\0';

      return pa_copy;
    }

    // La chaîne contient sans caractère en trop => rien à faire...
    return pa_orig;
  }
  // Il faut rajouter "..."
  else
  {
    UInt16 uh_ell_width;
    Char a_ell;

    a_ell = ellipsis(&uh_ell_width);

    // La largeur de la chaîne avec '...', va dépasser
    if (uh_cur_width + uh_ell_width > uh_max_width)
    {
      uh_cur_width = uh_max_width - uh_ell_width;
      FntCharsInWidth(pa_orig, &uh_cur_width, &uh_trunc_len, &b_fit_in_str);
    }

    // Pas de modification => juste informatif
    if (pa_copy == NULL)
      uh_trunc_len++;
    else
    {
      if (pa_orig != pa_copy)
	// Recopie du morceau de chaîne
	MemMove(pa_copy, pa_orig, uh_trunc_len);

      /* + "..." avec le '\0' */
      pa_copy[uh_trunc_len++] = a_ell;
      pa_copy[uh_trunc_len] = '\0';
    }

    *puh_len = uh_trunc_len;

    return pa_copy;
  }
}


// Renvoie -1 si rien à tronquer, la largeur maxi (y compris '...') sinon
// *puh_len contient en retour la longueur de la chaîne pa_str (sans '...')
Int16 prepare_truncating(Char *pa_str, UInt16 *puh_len, UInt16 uh_max_width)
{
  UInt16 uh_trunc_len, uh_cur_width;
  Boolean b_fit_in_str = false;

  uh_trunc_len = *puh_len;
  uh_cur_width = uh_max_width;
  FntCharsInWidth(pa_str, &uh_cur_width, &uh_trunc_len, &b_fit_in_str);

  if (b_fit_in_str)
  {
    // uh_trunc_len peut être inférieur si pa_str finit par au moins un espace
    *puh_len = uh_trunc_len;
    return -1;
  }
  // Il faut rajouter "..."
  else
  {
    UInt16 uh_ell_width;

    ellipsis(&uh_ell_width);

    uh_cur_width += uh_ell_width;

    // La largeur de la chaîne avec '...', va dépasser
    if (uh_cur_width > uh_max_width)
    {
      uh_cur_width = uh_max_width - uh_ell_width;
      FntCharsInWidth(pa_str, &uh_cur_width, &uh_trunc_len, &b_fit_in_str);

      uh_cur_width += uh_ell_width;
    }

    *puh_len = uh_trunc_len;	/* Ne comprend pas '...' */

    return uh_cur_width;	/* Y compris la largeur de '...' */
  }
}


//
// Charge la chaîne dont l'ID est uh_id dans le buffer pa_buf, en
// calcule la largeur et si cette dernière est supérieure à
// *puh_largest, modifie *puh_largest en conséquence.
void load_and_fit(UInt16 uh_id, Char *pa_buf, UInt16 *puh_largest)
{
  UInt16 uh_width;

  SysCopyStringResource(pa_buf, uh_id);
  uh_width = FntCharsWidth(pa_buf, StrLen(pa_buf));

  if (puh_largest != NULL && uh_width > *puh_largest)
    *puh_largest = uh_width;
}


//
// Renvoie le caractère '...' et sa largeur en pixels (si puh_width != NULL)
Char ellipsis(UInt16 *puh_width)
{
  union u_ellipsis
  {
    struct
    {
      UInt16 uh_width;
      UInt8 ua_font;
      Char a_ell;
    } s;
    UInt32 ul_feature;
  } u_ell;
  FontID uh_cur_font;

  uh_cur_font = FntGetFont();

#define ELLIPSIS_FEATURE_ID	0xe111

  if (FtrGet(MaTiCreatorID, ELLIPSIS_FEATURE_ID, &u_ell.ul_feature) != 0)
  {
    ChrHorizEllipsis(&u_ell.s.a_ell);

 compute_width:
    u_ell.s.uh_width = FntCharWidth(u_ell.s.a_ell);

    if (uh_cur_font > 0xff)
      uh_cur_font = 0xff;
    u_ell.s.ua_font = uh_cur_font;

    FtrSet(MaTiCreatorID, ELLIPSIS_FEATURE_ID, u_ell.ul_feature);
  }

  if (puh_width != NULL)
  {
    // La fonte a changé depuis la dernière fois...
    if (u_ell.s.ua_font != uh_cur_font)
      goto compute_width;

    *puh_width = u_ell.s.uh_width;
  }

  return u_ell.s.a_ell;
}


void init_misc_infos(struct s_misc_infos *ps_infos,
		     FontID uh_std_font, FontID uh_bold_font)
{
  struct
  {
    Boolean b_daymonth;
    Char    a_separator;
  } rs_conv[] =
    {
      [dfMDYWithSlashes] = { false, '/' },	// 12/31/95
      [dfDMYWithSlashes] = { true,  '/' },	// 31/12/95
      [dfDMYWithDots]    = { true,  '.' },	// 31.12.95
      [dfDMYWithDashes]  = { true,  '-' },	// 31-12-95
      [dfYMDWithSlashes] = { false, '/' },	// 95/12/31
      [dfYMDWithDots]    = { false, '.' },	// 95.12.31
      [dfYMDWithDashes]	 = { false, '-' },	// 95-12-31
      [dfMDYWithDashes]  = { false, '-' },	// 12-31-95
    };
  Char ra_date[] = "00X00";
#define FMT_NUM_1	"-99999X99"
#define FMT_NUM_2	"-999999"
#define FMT_NUM_3	"-99X99M"
  Char ra_num[] = FMT_NUM_1 "\0" FMT_NUM_2 "\0" FMT_NUM_3;
#define PTR_NUM_1	ra_num
#define PTR_NUM_2	&ra_num[sizeof(PTR_NUM_1)]
#define PTR_NUM_3	&ra_num[sizeof(PTR_NUM_1) + sizeof(PTR_NUM_2)]
#define SEP_NUM_1	ra_num[sizeof(PTR_NUM_1)-1 - 3]
#define SEP_NUM_3	ra_num[sizeof(PTR_NUM_1) + sizeof(PTR_NUM_2)-1 - 4]
#define FMT_MAX_NUM	"-99999999X99"
  Char ra_max_num[] = FMT_MAX_NUM;
#define SEP_MAX_NUM	ra_max_num[sizeof(FMT_MAX_NUM)-1 - 3]
  DateFormatType e_type = (DateFormatType)PrefGetPreference(prefDateFormat);
  UInt16 uh_width, uh_max_width;
  

  if (e_type >= sizeof(rs_conv) / sizeof(rs_conv[0]))
    e_type = dfDMYWithSlashes;

  uh_bold_font = FntSetFont(uh_bold_font);
  ps_infos->a_date_separator = rs_conv[e_type].a_separator;
  ra_date[2] = ps_infos->a_date_separator;
  ps_infos->uh_date_width = FntCharsWidth(ra_date, 5);
  ps_infos->uh_daymonth = rs_conv[e_type].b_daymonth;

  // La date d'aujourd'hui
  DateSecondsToDate(TimGetSeconds(), &ps_infos->s_today);

  // Séparateur décimal
  ps_infos->a_dec_separator = float_dec_separator();

  // Taille de la partie nombre
  SEP_NUM_1 = SEP_NUM_3 = SEP_MAX_NUM = ps_infos->a_dec_separator;

  // -100000 à -999999
  uh_max_width = FntCharsWidth(PTR_NUM_2, sizeof(FMT_NUM_2)-1);

  // > 999999 en absolu
  uh_width = FntCharsWidth(PTR_NUM_3, sizeof(FMT_NUM_3)-1);
  if (uh_width > uh_max_width)
    uh_max_width = uh_width;

  // < 100000 en absolu
  FntSetFont(uh_std_font);
  uh_width = FntCharsWidth(PTR_NUM_1, sizeof(FMT_NUM_1)-1);
  if (uh_width > uh_max_width)
    uh_max_width = uh_width;

  ps_infos->uh_amount_width = uh_max_width;

  // La plus grosse somme possible, sans réduction
  ps_infos->uh_max_amount_width = FntCharsWidth(ra_max_num,
						sizeof(FMT_MAX_NUM)-1);

  // On restaure la fonte...
  FntSetFont(uh_bold_font);
}


void infos_short_date(struct s_misc_infos *ps_infos,
		      DateType s_date, Char *pa_buf)
{
  pa_buf[2] = ps_infos->a_date_separator;

  if (ps_infos->uh_daymonth)
  {
    pa_buf[0] = '0' + s_date.day / 10;
    pa_buf[1] = '0' + s_date.day % 10;
    pa_buf[3] = '0' + s_date.month / 10;
    pa_buf[4] = '0' + s_date.month % 10;
  }
  else
  {
    pa_buf[0] = '0' + s_date.month / 10;
    pa_buf[1] = '0' + s_date.month % 10;
    pa_buf[3] = '0' + s_date.day / 10;
    pa_buf[4] = '0' + s_date.day % 10;
  }

  pa_buf[5] = '\0';
}


void __alert_error(Char *pa_text, Err error)
{
  Char ra_code[6] = " ";
  UInt16 uh_alert;

  switch (error)
  {
  case dmErrInvalidDatabaseName:
    uh_alert = alertDmErrInvalidDatabaseName;
    break;

  case dmErrAlreadyExists:
    uh_alert = alertDmErrAlreadyExists;
    break;

  case memErrNotEnoughSpace:
    uh_alert = alertMemErrNotEnoughSpace;
    break;

  default:
    StrIToA(ra_code, error);
    uh_alert = alertGenericError;
    return;
  }

  FrmCustomAlert(alertGenericError, pa_text ? : " ", ra_code, " ");
}


void __alert_error_str(Char *pa_fmt, ...)
{
  Char *pa_buf;
  va_list ap;

  va_start(ap, pa_fmt);

  pa_buf = MemPtrNew(200);
  StrVPrintF(pa_buf, pa_fmt, ap);

  FrmCustomAlert(alertError, pa_buf, " ", " ");
  MemPtrFree(pa_buf);

  va_end(ap);
}


void winprintf(Char *pa_fmt, ...)
{
  Char *pa_buf;
  va_list ap;

  va_start(ap, pa_fmt);

  pa_buf = MemPtrNew(200);
  StrVPrintF(pa_buf, pa_fmt, ap);

  FrmCustomAlert(5, pa_buf, " ", " ");
  MemPtrFree(pa_buf);

  va_end(ap);
}


Int16 sort_string_compare(Char *pa_str1, Char *pa_str2, Int32 l_dummy)
{
  return StrCaselessCompare(pa_str1, pa_str2);
}


void not_enough_space_alert(UInt32 ui_size, Char *pa_file, UInt16 uh_line)
{
  Char ra_num[10 + 1], ra_line[5 + 1];

  if (ui_size == (UInt32)-1)
    StrCopy(ra_num, "push");
  else
    StrIToA(ra_num, ui_size);

  StrIToA(ra_line, uh_line);

  FrmCustomAlert(alertMemErrNotEnoughSpace, ra_num, pa_file, ra_line);
}


Boolean is_empty(Char *pa_str)
{
  for (;;)
  {
    switch (*pa_str++)
    {
    case '\0':
      return true;

      // On ne met pas l'ancien espace numérique 0x80 car maintenant
      // c'est le signe euro
    case chrNumericSpace:
    case ' ':
    case '\t':
      break;

    default:
      return false;
    }
  }
}
