/* 
 * ProgressBar.m -- 
 * 
 * Author          : Maxime Soulé
 * Created On      : Fri Oct 15 20:45:24 2004
 * Last Modified By: Maxime Soule
 * Last Modified On: Fri Jul  6 14:45:03 2007
 * Update Count    : 5
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: ProgressBar.m,v $
 * Revision 1.4  2008/01/14 16:34:26  max
 * Switch to new mcc
 *
 * Revision 1.3  2005/10/14 22:37:28  max
 * Correct progress bar apparition condition.
 *
 * Revision 1.2  2005/03/02 19:02:42  max
 * The progress bar now only appear after 1/4 second of activity.
 * Constructor change from MaxValue to NumValues.
 * Add methods -label* to manage label formats with resource strings.
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_PROGRESSBAR
#include "ProgressBar.h"

#include "MaTirelire.h"


#define FRAME_WIDTH		2
#define LABEL_HEIGHT		13
#define TOP_MARGIN_WIDTH	2
#define MARGIN_WIDTH		4
#define BETWEEN_WIDTH		0

#define BAR_HEIGHT	10
#define BAR_WIDTH	130

#define PROGRESS_WIDTH	(FRAME_WIDTH \
			   + MARGIN_WIDTH \
			     + BAR_WIDTH \
			   + MARGIN_WIDTH \
			 + FRAME_WIDTH)

#define PROGRESS_HEIGHT	(FRAME_WIDTH \
			   + TOP_MARGIN_WIDTH \
			     + LABEL_HEIGHT \
			     + BETWEEN_WIDTH \
			     + BAR_HEIGHT \
			   + MARGIN_WIDTH \
			 + FRAME_WIDTH)

// Exemple d'utilisation :
// -----------------------
// {
//   Char ra_label[32];
//   ProgressBar *oProg;
//   UInt16 index, uh_label = testAlaCon;
// 
//   SysCopyStringResource(ra_label, uh_label);
//   oProg = [ProgressBar newMaxValue:9 label:ra_label];
// 
//   for (index = 1; index < 10; index++)
//   {
//     if (index > 4)
//     {
// 	if (index < 8)
// 	  uh_label = testAlaCon2;
// 	else
// 	  uh_label = testAlaCon3;
//     }
// 
//     SysCopyStringResource(ra_label, uh_label);
// 
//     switch (index)
//     {
//     case 3:
//     case 6:
// 	[oProg suspend];
// 	SysTaskDelay(SysTicksPerSecond() * 200);
// 	[oProg restart];
// 	SysTaskDelay(SysTicksPerSecond() * 50);
// 	continue;
//     }
// 
//     [oProg updateValue:index label:ra_label];
//     SysTaskDelay(SysTicksPerSecond() * 50);
//   }
// 
//   SysTaskDelay(SysTicksPerSecond() * 200);
// 
//   [oProg free];
// }


@implementation ProgressBar

+ (ProgressBar*)newNumValues:(UInt32)ui_num label:(UInt16)uh_str_id, ...
{
  ProgressBar *oProgressBar;
  va_list ap;

  va_start(ap, uh_str_id);

  oProgressBar = [[self alloc] initNumValues:ui_num label:uh_str_id va:ap];

  va_end(ap);

  return oProgressBar;
}


- (ProgressBar*)initNumValues:(UInt32)ui_num label:(UInt16)uh_str_id
			   va:(va_list)ap
{
  self->ui_max_value = ui_num - 1;

  self->ui_init_ticks = TimGetTicks();
  self->uh_ticks_per_sec = SysTicksPerSecond();

  // On prépare le label
  [self label:uh_str_id va:ap];

  return self;
}


- (void)restart
{
  RectangleType s_rect;
  UInt16 uh_error, uh_width, uh_height;

  WinGetWindowExtent(&uh_width, &uh_height);

  s_rect.topLeft.x = (uh_width - PROGRESS_WIDTH) / 2;
  s_rect.topLeft.y = (uh_height - PROGRESS_HEIGHT) / 2;
  s_rect.extent.x = PROGRESS_WIDTH;
  s_rect.extent.y = PROGRESS_HEIGHT;

  self->win_handle = WinSaveBits(&s_rect, &uh_error);
  if (self->win_handle)
  {
    self->point_win = s_rect.topLeft;

    if (oMaTirelire->uh_color_enabled)
    {
      WinPushDrawState();

      WinSetForeColor(UIColorGetTableEntryIndex(UIDialogFrame));
      WinSetBackColor(UIColorGetTableEntryIndex(UIDialogFill));
    }

    WinEraseRectangle(&s_rect, 8);
    s_rect.topLeft.x += FRAME_WIDTH;
    s_rect.topLeft.y += FRAME_WIDTH;
    s_rect.extent.x -= FRAME_WIDTH * 2;
    s_rect.extent.y -= FRAME_WIDTH * 2;
    WinDrawRectangleFrame(boldRoundFrame, &s_rect);

    s_rect.topLeft.x += MARGIN_WIDTH + 1;
    s_rect.topLeft.y += TOP_MARGIN_WIDTH + LABEL_HEIGHT + BETWEEN_WIDTH + 1;
    s_rect.extent.x = BAR_WIDTH - 2;
    s_rect.extent.y = BAR_HEIGHT - 2;

    if (oMaTirelire->uh_color_enabled)
    {
      WinSetBackColor(UIColorGetTableEntryIndex(UIObjectFill));

      // Arrière plan de la barre de progression
      WinEraseRectangle(&s_rect, 0);

      WinSetForeColor(UIColorGetTableEntryIndex(UIObjectFrame));
      WinSetBackColor(UIColorGetTableEntryIndex(UIDialogFill));
      WinSetTextColor(UIColorGetTableEntryIndex(UIObjectForeground));
    }

    WinDrawRectangleFrame(simpleFrame, &s_rect);

    self->uh_save_font = FntSetFont(stdFont);

    // On reprend où on en était avec un refresh...
    [self labelRedraw:true];
    [self updateValue:-1];
  }
}


- (void)suspend
{
  if (self->win_handle != NULL)
  {
    if (oMaTirelire->uh_color_enabled)
      WinPopDrawState();
    else
      FntSetFont(self->uh_save_font);

    WinRestoreBits(self->win_handle, self->point_win.x, self->point_win.y);

    self->win_handle = NULL;
  }
}


//
// Si pa_label == NULL, le label ne change pas...
// Si i_value < 0, fait un refresh sur la valeur courante...
- (void)updateValue:(Int32)i_value
{
  if (self->win_handle == NULL)
  {
    UInt32 ui_cur_ticks = TimGetTicks();

    // Rien à rafraichir
    if (i_value < 0)
      return;

    // Nombre de 1/8 de seconde depuis le départ >= 2
    if (((ui_cur_ticks - self->ui_init_ticks) << 3) / self->uh_ticks_per_sec
	>= 2 // ==> 2 * 1/8s == 250ms
	// ET qu'on est à plus de 10% de la fin...
	&& (100 * i_value) / self->ui_max_value < 90)
      [self restart];
  }
  else
  {
    RectangleType s_rect;

    // On reprend en cours de route...
    if (i_value < 0)
      i_value = self->h_last_percent;
    else
    {
      i_value = (i_value * (BAR_WIDTH - 2) + (self->ui_max_value >> 1))
	/ self->ui_max_value;

      // La valeur n'a pas changé...
      if (i_value == self->h_last_percent)
	return;
    }

    // On dessine la barre
    s_rect.topLeft.x = self->point_win.x + FRAME_WIDTH + MARGIN_WIDTH + 1;
    s_rect.topLeft.y = (self->point_win.y + FRAME_WIDTH + TOP_MARGIN_WIDTH
			+ LABEL_HEIGHT + BETWEEN_WIDTH + 1);
    s_rect.extent.x = i_value;
    s_rect.extent.y = BAR_HEIGHT - 2;
    WinDrawRectangle(&s_rect, 0);

    self->h_last_percent = i_value;
  }
}


- (void)labelRedraw:(Boolean)b_first
{
  RectangleType s_rect;
  UInt16 uh_width, uh_len;

  // On efface la zone du label (ssi pas première fois)
  if (b_first == false)
  {
    s_rect.topLeft.x = self->point_win.x + FRAME_WIDTH + MARGIN_WIDTH;
    s_rect.extent.x = PROGRESS_WIDTH - 2 * (FRAME_WIDTH + MARGIN_WIDTH);
    s_rect.extent.y = LABEL_HEIGHT;
    WinEraseRectangle(&s_rect, 0);
  }

  uh_len = StrLen(self->ra_label);

  uh_width = FntCharsWidth(self->ra_label, uh_len);

  s_rect.topLeft.y = self->point_win.y + FRAME_WIDTH + TOP_MARGIN_WIDTH;

  // le nouveau label
  WinDrawChars(self->ra_label, uh_len,
	       self->point_win.x + PROGRESS_WIDTH / 2 - (uh_width >> 1),
	       s_rect.topLeft.y);
}


- (void)label:(UInt16)uh_str_id va:(va_list)ap
{
  Char ra_format[64];

  if (uh_str_id == 0)
    self->ra_label[0] = '\0';
  else
  {
    SysCopyStringResource(ra_format, uh_str_id);
    StrVPrintF(self->ra_label, ra_format, ap);
  }

  if (self->win_handle != NULL)
    [self labelRedraw:false];
}


- (void)label:(UInt16)uh_str_id, ...
{
  va_list ap;

  va_start(ap, uh_str_id);

  [self label:uh_str_id va:ap];

  va_end(ap);
}


- (ProgressBar*)free
{
  [self suspend];

  return [super free];
}

@end
