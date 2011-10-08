/* -*- objc -*-
 * SumListForm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Jeu nov 18 21:55:19 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Nov 29 17:44:21 2004
 * Update Count    : 1
 * Status          : Unknown, Use with caution!
 */

#ifndef	__SUMLISTFORM_H__
#define	__SUMLISTFORM_H__

#include "TransForm.h"		// Au lieu de MaTiForm pour -transForm...
#include "SumScrollList.h"

#ifndef EXTERN_SUMLISTFORM
# define EXTERN_SUMLISTFORM extern
#endif

@interface SumListForm : MaTiForm
{
  SumScrollList *oList;

#define SUM_LIST_DATE_STAR	'*'
#define SUM_LIST_DATE_LEN	sizeof("00/00X")
  Char ra_at_date[SUM_LIST_DATE_LEN];

  // Dans le cas où on a un popup des devises...
  VoidHand pv_popup_currencies;
  UInt16 uh_currency;
}

// Pour l'attribut uh_subclasses_flags
#define SUMLISTFORM_HAS_CURRENCIES_POPUP	0x1

- (void)sumFieldRepos;

- (void)sumTypeWidgetChange;
- (void)sumTypeWidgetReinit:(ListType*)pt_list;

- (void)sumTypeChange;

- (void)reloadCurrenciesPopup;
- (void)updateCurrenciesList;
- (void)changeCurrency;

- (Boolean)transFormShortcut:(struct _KeyDownEventType *)ps_key
		      listID:(UInt16)uh_list
			args:(struct s_trans_form_args*)ps_args;

@end

#endif	/* __SUMLISTFORM_H__ */
