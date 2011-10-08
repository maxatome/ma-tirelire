/* -*- objc -*-
 * ExternalCurrencyCur4.h -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Thu Oct 26 17:30:17 2006
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Dec 13 11:32:34 2007
 * Update Count    : 7
 * Status          : Unknown, Use with caution!
 */

#ifndef	__EXTERNALCURRENCYCUR4_H__
#define	__EXTERNALCURRENCYCUR4_H__

#include "ExternalCurrency.h"

#ifndef EXTERN_EXTERNALCURRENCYCUR4
# define EXTERN_EXTERNALCURRENCYCUR4 extern
#endif

@interface ExternalCurrencyCur4 : ExternalCurrency
{
  // true si la base a été modifiée par Currency4
  Boolean b_after_cur4;
}

@end

#endif	/* __EXTERNALCURRENCYCUR4_H__ */
