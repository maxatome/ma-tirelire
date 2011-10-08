/* 
 * float.c -- 
 * 
 * Author          : Charlie Root
 * Created On      : Tue Aug 26 22:51:56 2003
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Jan  7 14:09:21 2008
 * Update Count    : 1
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: float.c,v $
 * Revision 1.3  2008/01/14 13:08:30  max
 * double to string conversion didn't handle correctly X.000X
 * numbers. Corrected.
 *
 * Revision 1.2  2005/08/20 13:07:19  max
 * Add StrUInt64ToA() (not yet tested).
 *
 * Revision 1.1  2005/02/09 22:57:23  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_FLOAT
#include "float.h"

#include "types.h"


Char *StrUInt32ToA(UInt8 *pua_str, UInt32 ui_num, UInt16 *puh_len)
{
  UInt8 *pua_cur = pua_str;

  if (ui_num < 10)
  {
 level_10:
    *pua_cur++ = '0' + ui_num;
    *pua_cur = '\0';

    if (puh_len != NULL)
      *puh_len = pua_cur - pua_str;

    return pua_str;
  }

#define __level(next_level) \
  *pua_cur++ = '0' + ui_num / next_level; \
  ui_num %= next_level; \
  goto level_ ## next_level

#define __level_if(next_level) \
  if (ui_num < next_level * 10UL) \
  { \
 level_ ## next_level ## 0: \
    __level(next_level); \
  }

  __level_if(10)		/* < 	        100 */
  __level_if(100)		/* < 	      1 000 */
  __level_if(1000)		/* < 	     10 000 */
  __level_if(10000)		/* <        100 000 */
  __level_if(100000)		/* <      1 000 000 */
  __level_if(1000000)		/* <     10 000 000 */
  __level_if(10000000)		/* <    100 000 000 */
  __level_if(100000000)		/* <  1 000 000 000 */

  __level   (1000000000);	/* >= 1 000 000 000 */

  // Jamais atteint...
}


Char *StrUInt64ToA(UInt8 *pua_str, UInt64 ull_num, UInt16 *puh_len)
{
  UInt8 *pua_cur = pua_str;

  if (ull_num < 10)
  {
 level_10:
    *pua_cur++ = '0' + ull_num;
    *pua_cur = '\0';

    if (puh_len != NULL)
      *puh_len = pua_cur - pua_str;

    return pua_str;
  }

#define __level64(next_level) \
  *pua_cur++ = '0' + ull_num / next_level ## ULL; \
  ull_num %= next_level ## ULL; \
  goto level_ ## next_level

#define __level64_if(next_level) \
  if (ull_num < next_level ## ULL * 10ULL) \
  { \
 level_ ## next_level ## 0: \
    __level64(next_level); \
  }

  __level64_if(10)			/* <			     100 */
  __level64_if(100)			/* <			   1 000 */
  __level64_if(1000)			/* <			  10 000 */
  __level64_if(10000)			/* <		         100 000 */
  __level64_if(100000)			/* <		       1 000 000 */
  __level64_if(1000000)			/* <		      10 000 000 */
  __level64_if(10000000)		/* <		     100 000 000 */
  __level64_if(100000000)		/* <		   1 000 000 000 */
					/*  		   4 294 967 296 */
  __level64_if(1000000000)		/* <              10 000 000 000 */
  __level64_if(10000000000)		/* <             100 000 000 000 */
  __level64_if(100000000000)		/* <           1 000 000 000 000 */
  __level64_if(1000000000000)		/* <          10 000 000 000 000 */
  __level64_if(10000000000000)		/* <         100 000 000 000 000 */
  __level64_if(100000000000000)		/* <       1 000 000 000 000 000 */
  __level64_if(1000000000000000)	/* <      10 000 000 000 000 000 */
  __level64_if(10000000000000000)	/* <     100 000 000 000 000 000 */
  __level64_if(100000000000000000)	/* <   1 000 000 000 000 000 000 */
  __level64_if(1000000000000000000)	/* <  10 000 000 000 000 000 000 */
					/*    18 446 744 073 709 551 616 */

  __level64   (10000000000000000000);	/* >= 10 000 000 000 000 000 000 */

  // Jamais atteint...
}


static UInt32 strToUInt32(UInt8 *pua_str, Char **ppa_end, Boolean *pb_is_digit)
{
  UInt32 ui_num = 0;
  Boolean b_is_digit = false;

  for (;; pua_str++)
  {
    switch (*pua_str)
    {
    case '0' ... '9':
      ui_num *= 10;
      ui_num += *pua_str - '0';
      b_is_digit = true;
      continue;

      // On ignore les espaces (0x80 est l'ancien espace numérique et
      // la quote peut être utilisée comme séparateur de milliers dans
      // les préférences du système)
    case ' ': case '\t': case 0x80: case chrNumericSpace: case '\'':
      continue;

      // Un caractère non reconnu...
    default:
      break;
    }
    break;
  }

  if (ppa_end != NULL)
    *ppa_end = pua_str;

  if (pb_is_digit != NULL)
    *pb_is_digit = b_is_digit;

  return ui_num;
}


Boolean isStrAToInt32(UInt8 *pua_str, Int32 *pi_num)
{
  Char *pa_end;
  Int32 i_val;
  Boolean b_neg = false, b_is_digit;

  // On saute les espaces du début
  while (*pua_str == ' ' || *pua_str == '\t' ||
  	 *pua_str == 0x80 || *pua_str == chrNumericSpace || *pua_str == '\'')
    pua_str++;

  // Le signe
  switch (*pua_str)
  {
  case '-':
    b_neg = true;
    // CONTINUE
  case '+':
    pua_str++;
    break;
  }

  i_val = strToUInt32(pua_str, &pa_end, &b_is_digit);

  // Pas à la fin     OU pas de chiffre      OU overflow
  if (*pa_end != '\0' || b_is_digit == false || i_val < 0)
    return false;

  if (pi_num != NULL)
    *pi_num = b_neg ? - i_val : i_val;

  return true;
}


Boolean isStrAToDouble(UInt8 *pua_str, double *pd_float)
{
  double d_int, d_dec;
  Char *pa_end;
  UInt16 uh_zeroes = 0;
  Boolean b_neg = false, b_int_is_digit, b_dec_is_digit;

  // On saute les espaces du début
  while (*pua_str == ' ' || *pua_str == '\t' ||
  	 *pua_str == 0x80 || *pua_str == chrNumericSpace || *pua_str == '\'')
    pua_str++;

  // Le signe
  switch (*pua_str)
  {
  case '-':
    b_neg = true;
    // CONTINUE
  case '+':
    pua_str++;
    break;
  }

  d_int = (double)strToUInt32(pua_str, &pa_end, &b_int_is_digit);

  b_dec_is_digit = false;
  d_dec = 0;

  switch (*pa_end)
  {
    // On continue sur la partie décimale
  case '.': case ',':
    // On saute les 0
    for (pua_str = pa_end + 1;; pua_str++)
    {
      switch (*pua_str)
      {
	// On ignore les espaces (0x80 est l'ancien espace numérique
	// et la quote peut être utilisée comme séparateur de milliers
	// dans les préférences du système)
      case ' ': case '\t': case 0x80: case chrNumericSpace: case '\'':
	continue;

	// On compte les 0 qui suivent la virgule
      case '0':
	uh_zeroes++;
	continue;

	// C'est la fin => pas de partie décimale
      case '\0':
	break;

	// La partie décimale prend forme
      case '1' ... '9':
	d_dec = (double)strToUInt32(pua_str, &pa_end, &b_dec_is_digit);
	if (*pa_end == '\0')
	  break;
	// CONTINUE

	// Y a une couille dans la partie décimale
      default:
	return false;
      }
      break;
    }
    break;

    // C'est la fin : il n'y a pas de partie décimale
  case '\0':
    break;

  default:
    // Erreur
    return false;
  }

  // Si on n'a rencontré aucun chiffre, c'est pas bon...
  if (b_int_is_digit == false && b_dec_is_digit == false)
    return false;

  if (pd_float != NULL)
  {
    while (d_dec >= 1)
      d_dec /= 10.;

    while (uh_zeroes-- > 0)
      d_dec /= 10.;

    d_int += d_dec;

    *pd_float = b_neg ? - d_int : d_int;
  }

  return true;
}


Char *StrDoubleToA(UInt8 *pua_str, double d_num, UInt16 *puh_len,
		   Char a_dec_separator, UInt16 uh_dec_len)
{
  double d_max_value;
  UInt8 *pua_cur = pua_str;
  UInt32 ui_int, ui_dec;
  UInt16 uh_dec_cur, uh_part_len, uh_num_dec_zeros;
  Boolean b_stop_zeros;

  if (d_num < 0)
  {
    *pua_cur++ = '-';
    d_num = - d_num;
  }

  ui_int = (UInt32)d_num;

  d_num -= (double)ui_int;

  d_max_value = 1.;
  uh_num_dec_zeros = 0;
  b_stop_zeros = false;
  for (uh_dec_cur = uh_dec_len; uh_dec_len-- > 0; )
  {
    d_num *= 10;
    d_max_value *= 10.;

    // Count zeros just after the decimal period
    if (b_stop_zeros == false)
    {
      if ((UInt32)d_num == 0)
	uh_num_dec_zeros++;
      else
	b_stop_zeros = true;
    }
  }

  d_num += .5;			/* Round */
  if (d_num > d_max_value)
  {
    ui_int++;
    ui_dec = 0.;
  }
  else
    ui_dec = (UInt32)d_num;

  // Integral part
  StrUInt32ToA(pua_cur, ui_int, &uh_part_len);
  pua_cur += uh_part_len;

  if (ui_dec > 0)
  {
    *pua_cur++ = a_dec_separator;

    // Add zeros just after the decimal period
    while (uh_num_dec_zeros-- > 0)
      *pua_cur++ = '0';

    // Decimal part
    StrUInt32ToA(pua_cur, ui_dec, &uh_part_len);
    pua_cur += uh_part_len;

    // On retire les 0 qui sont en fin
    while (pua_cur[-1] == '0')
      pua_cur--;
  }

  *pua_cur = '\0';

  if (puh_len != NULL)
    *puh_len = pua_cur - pua_str;

  return pua_str;
}


Boolean isStrATo100F(Char *ptr, Int32 *pl_float)
{
  Char *bis;

  for (bis = ptr; ; bis++)
  {
    switch (*bis)
    {
      // Le . décimal...
    case '.': case ',':
    {
      Boolean b_neg;

      if (bis != ptr)
      {
	Char tmp[bis - ptr + 1];

	MemMove(tmp, ptr, bis - ptr);
	tmp[bis - ptr] = '\0';

	*pl_float = StrAToI(tmp) * 100;
	b_neg = (*pl_float < 0);
	if (b_neg)
	  *pl_float = - *pl_float;
      }
      else
      {
	*pl_float = 0;
	b_neg = false;
      }

      if (*++bis >= '0' && *bis <= '9')
      {
	*pl_float += (*bis - '0') * 10;

	if (*++bis >= '0' && *bis <= '9')
	  *pl_float += (*bis++ - '0');
      }

      if (b_neg)
	*pl_float = - *pl_float;
    }
    return (*bis == '\0');

      // Un chiffre, on continue
    case '0' ... '9':
      continue;

      // Le signe, on continue si en première position
    case '-': case '+':
      if (bis == ptr)
	continue;
      break;
    }

    break;
  }

  *pl_float = StrAToI(ptr) * 100;

  return (*bis == '\0');
}


Char *Str100FToA(UInt8 *pua_str, Int32 num, UInt16 *puh_len,
		 Char a_dec_separator)
{
  UInt8 *pua_cur = pua_str;
  UInt16 uh_len;

  if (num < 0)
  {
    *pua_cur++ = '-';
    num = - num;

    // On a dépassé les bornes XXX
    if (num < 0)
    {
      *pua_cur++ = '~';
      goto end;
    }
  }

  StrUInt32ToA(pua_cur, num / 100, &uh_len);

  pua_cur += uh_len;

  *pua_cur++ = a_dec_separator;

  num %= 100;
  *pua_cur++ = '0' + num / 10;
  *pua_cur++ = '0' + num % 10;

 end:
  *pua_cur = '\0';

  if (puh_len != NULL)
    *puh_len = pua_cur - pua_str;

  return pua_str;
}


Char float_dec_separator(void)
{
  switch ((NumberFormatType)PrefGetPreference(prefNumberFormat))
  {
  case nfCommaPeriod:
  case nfApostrophePeriod:
    return '.';

    //case nfPeriodComma:
    //case nfSpaceComma:
    //case nfApostropheComma:
  default:
    return ',';
  }
}
