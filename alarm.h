/* -*- objc -*-
 * alarm.h -- 
 * 
 * Author          : Charlie Root
 * Created On      : Lun mar  7 22:06:04 2005
 * Last Modified By: 
 * Last Modified On: 
 * Update Count    : 0
 * Status          : Unknown, Use with caution!
 */

#ifndef	__ALARMFORM_H__
#define	__ALARMFORM_H__

#include <PalmOS.h>

#ifndef EXTERN_ALARMFORM
# define EXTERN_ALARMFORM extern
#endif

EXTERN_ALARMFORM void alarm_triggered(SysAlarmTriggeredParamType *cmdPBP);
EXTERN_ALARMFORM void alarm_display(SysDisplayAlarmParamType *cmdPBP);

EXTERN_ALARMFORM void alarm_schedule_all(void);
EXTERN_ALARMFORM Boolean alarm_schedule_transaction(DmOpenRef db,
						    UInt16 uh_rec, Boolean);

#endif	/* __ALARMFORM_H__ */
