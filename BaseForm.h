/* -*- objc -*-
 * BaseForm.h -- 
 * 
 * Author          : Max Root
 * Created On      : Thu Nov 21 22:44:15 2002
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Jan 10 14:26:19 2008
 * Update Count    : 10
 * Status          : Unknown, Use with caution!
 */

#ifndef	__BASEFORM_H__
#define	__BASEFORM_H__

#include "Object.h"

#ifndef EXTERN_BASEFORM
# define EXTERN_BASEFORM extern
#endif

#define TAB_BITS_PER_TAB	8

#define TAB_ID_FIRST_TAB	(1 << TAB_BITS_PER_TAB)
#define TAB_ID_MASK		(TAB_ID_FIRST_TAB - 1)
#define TAB_ID_AFTER_LINE	(TAB_ID_FIRST_TAB - 1) // = baseTabAfterLine
#define TAB_NUM_TO_ID(num)	(num << TAB_BITS_PER_TAB)
#define TAB_ID_TO_NUM(idx)	(idx >> TAB_BITS_PER_TAB)

#define TAB_GADGET_MAGIC	((void*)-3)

// cf pilrc AUTOID numbering...
#define AUTOID_BASE		9000

struct s_scrollbar_hiding
{
  UInt16 uh_index;		// Scrollbar index
  UInt16 uh_max_val;		// Current max value for this scrollbar
  UInt16 uh_cur_val;		// Current value for this scrollbar
};


//
// Pour les mises à jour entre les formulaires
struct frmCallerUpdate
{
  UInt16 formID;
  UInt32 updateCode;
};
#define frmCallerUpdateEvent	(firstUserEvent + 1)


@interface BaseForm : Object
{
  FormPtr pt_frm;
  FormEventHandlerPtr pf_form_handler;

  BaseForm *oPrevForm;

  UInt16 uh_tabs_num:4;		// Nombre d'onglets
  UInt16 uh_tabs_current:4;	// Index de l'onglet courant
  UInt16 uh_tabs_space:3;	// Espace en pixel entre la ligne et le bouton
  UInt16 uh_form_drawn:1;	// FrmDrawForm() passée...
  UInt16 uh_display_changed:1;	// winDisplayChangedEvent received
				// (used in next frmUpdateFormEvent)

  UInt16 uh_subclasses_flags:2;	// Reserved for subclasses use...
  UInt16 uh_visibility:1;	// 1 if we can draw, 0 if not

  UInt16 uh_form_flags;		// Param received by -load:

  // Bidouille pour cacher les scrollbars sur les OS < à 3.2
  struct s_scrollbar_hiding *ps_scrollbars;

  UInt32 ui_infos;		// Renvoyé par -getInfos
}

+ (BaseForm*)new:(UInt16)uh_id;

+ (BaseForm*)setCurForm:(BaseForm*)oCurForm;

- (BaseForm*)init;

- (Boolean)open;
- (Boolean)close;
- (BaseForm*)load:(UInt16)uh_id;
- (Boolean)update:(struct frmUpdate *)ps_update;
- (Boolean)goto:(struct frmGoto *)ps_goto;

- (Boolean)callerUpdate:(struct frmCallerUpdate *)ps_update;
- (void)sendCallerUpdate:(UInt32)ul_code;

- (Boolean)menu:(UInt16)uh_id;
- (Boolean)ctlEnter:(struct ctlEnter *)ps_enter;
- (Boolean)ctlSelect:(struct ctlSelect *)ps_select;
- (Boolean)keyDown:(struct _KeyDownEventType *)ps_key;
- (Boolean)sclRepeat:(struct sclRepeat *)ps_repeat;
- (Boolean)ctlRepeat:(struct ctlRepeat *)ps_repeat;
- (Boolean)tblEnter:(EventType*)e;
- (Boolean)fldChanged:(struct fldChanged *)ps_fld_changed;
- (Boolean)fldEnter:(struct fldEnter*)ps_fld_enter;
- (Boolean)lstSelect:(struct lstSelect *)ps_lst_select;
- (Boolean)penDown:(EventType*)e;
- (Boolean)winDisplayChanged;
- (Boolean)frmObjectFocusTake:(struct frmObjectFocusTake*)ps_take;
- (Boolean)frmObjectFocusLost:(struct frmObjectFocusLost*)ps_lost;

// Méthodes diverses

- (BaseForm*)findPrevForm:(id)oFormClass;
- (void)redrawForm;

#define REPLACE_FIELD_EXT	0x8000 // Dans uh_field
// Dans h_len
#define REPL_FIELD_DWORD		0x8000 // pa_new est un UInt32
#define REPL_FIELD_FDWORD		0x4000 // pa_new est un UInt32 en 100F
#define REPL_FIELD_DOUBLE		0x2000 // pa_new pointe sur un double
#define REPL_FIELD_INT64		0x1000 // pa_new pointe sur un Int64
#define REPL_FIELD_FINT64		0x0800 // pa_new -> sur Int64 en 100F
#define REPL_FIELD_KEEP_SIGN		0x0400 // Le signe '-' doit apparaître
#define REPL_FIELD_SELTRIGGER_SIGN	0x0200 // Le signe est placé dans le
					       // SELECTORTRIGGER (uh_field-1)
					       // "+" ou "-"
#define REPL_FIELD_EMPTY_IF_NULL	0x0100 // Champ vide si nombre == 0
- (Boolean)replaceField:(UInt16)uh_field
		withSTR:(Char*)pa_new len:(Int16)h_len;

/* Verifications a effectuer sur un champ (fonction check_field) */
#define FLD_CHECK_NONE		0x0000 /* Aucun test, recopie simple */
#define FLD_CHECK_NULL          0x0001 /* non nul  */
#define FLD_CHECK_VOID          0x0002 /* non vide */
#define FLD_CHECK_NOALERT	0x0004 /* Pas de boîte d'alerte si erreur */

/* Type de donnee a remplir */
#define FLD_TYPE_NEG		0x8000 // Négatif
#define FLD_SELTRIGGER_SIGN	0x4000 // Le signe est contenu dans le
				       // SELECTORTRIGGER (uh_field - 1)
				       // "+" ou "-"
#define FLD_TYPE_WORD           0x2000 // 16 bits
#define FLD_TYPE_DWORD          0x1000 // 32 bits
#define FLD_TYPE_FWORD          0x0800 // 16 bits en 100F
#define FLD_TYPE_FDWORD         0x0400 // 32 bits en 100F
#define FLD_TYPE_DOUBLE		0x0200 // double
#define FLD_TYPE_INT64		0x0100 // Int64 (64 bits)
#define FLD_TYPE_FINT64		0x0080 // Int64 (64 bits) en 100F

#define FLD_NO_NAME		0

- (Boolean)checkField:(UInt16)uh_field flags:(UInt16)uh_flags
	     resultIn:(void*)pv_data
	    fieldName:(UInt16)uh_label;

- (void)selTriggerSignChange:(struct ctlSelect*)ps_select;

- (Boolean)dateSelect:(UInt16)uh_title date:(DateType*)ps_date;
- (Boolean)dateInc:(UInt16)uh_date_id date:(DateType*)ps_date
     pressedButton:(UInt16)uh_obj
	    format:(DateFormatType)e_format;
- (void)dateSet:(UInt16)uh_date_id date:(DateType)s_date
	 format:(DateFormatType)e_format;
- (UInt16)dateIsBound:(UInt16)uh_date_id date:(DateType**)pps_date;

- (Boolean)timeSelect:(UInt16)uh_title time:(TimeType*)ps_time
	      dialog3:(Boolean)b_dialog3;
- (void)timeSet:(UInt16)uh_time_id time:(TimeType)s_time
	 format:(TimeFormatType)e_format;

#define KEY_FILTER_INT		0x80000000UL
#define KEY_FILTER_FLOAT	0x40000000UL
#define KEY_FILTER_DOUBLE	0x20000000UL
#define KEY_FILTER_NEG		0x10000000UL
#define KEY_SELTRIGGER_SIGN	0x08000000UL
#define KEY_FILTER_IDX		0x0000ffffUL
- (Boolean)keyFilter:(UInt32)ui_fld_idx for:(struct _KeyDownEventType*)ps_key;

- (void)returnToLastForm;

- (void*)objectPtrId:(UInt16)uh_obj_id;

- (void)hideId:(UInt16)uh_obj_id;
- (void)showId:(UInt16)uh_obj_id;

#define SET_SHOW(id, cond)	(((id) << 1) | (cond))
- (void)showHideIds:(UInt16*)puh_obj_ids;

- (void)hideIndex:(UInt16)uh_index;
- (void)showIndex:(UInt16)uh_index;

- (UInt16)focusGetObject;
- (Boolean)focusObjectIndex:(UInt16)uh_index;
- (Boolean)focusObject:(UInt16)uh_id;
- (Boolean)focusNextObject;
- (Boolean)focusPrevObject;

- (UInt32)getInfos;

- (void)fillLabel:(UInt16)uh_obj withSTR:(Char*)pa_label;

// Gestion des champs scrollables
- (void)fieldScrollBar:(UInt16)uh_scrollbar
	 linesToScroll:(Int16)h_lines_to_scrol
		update:(Boolean)b_update;

- (void)fieldUpdateScrollBar:(UInt16)uh_scrollbar
		    fieldPtr:(FieldType*)pt_field
		   setScroll:(Boolean)b_set_scroll;

- (void)swapLeft:(UInt16)uh_left_obj rightOnes:(UInt16)uh_right_one, ...;

- (Int16)contextPopupList:(UInt16)uh_list x:(Int16)h_x y:(Int16)h_y
		 selEntry:(UInt16)uh_sel;

// Gestion des onglets :
- (Boolean)clicOnTab:(UInt16)uh_tab;
- (void)tabsDraw:(UInt16)uh_cur_tab drawLines:(Boolean)b_lines;
- (void)tabsHide:(UInt16)uh_cur_tab;
- (void)tabsShow:(UInt16)uh_cur_tab;
- (UInt16)tabsGetTabForId:(UInt16)uh_obj;

@end

// Formulaire courant
EXTERN_BASEFORM BaseForm *oFrm;

EXTERN_BASEFORM void list_line_draw(Int16 h_line, RectangleType *prec_bounds,
				    Char **ppa_lines);
EXTERN_BASEFORM void list_line_draw_line(RectangleType *prec_bounds,
					 Int16 h_upperline);

#define PENDING_EVENT_UPDATE		0x8000
EXTERN_BASEFORM UInt16 guh_pending_events;

#endif	/* __BASEFORM_H__ */
