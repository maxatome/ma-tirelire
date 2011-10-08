/* -*- objc -*-
 * object.c -- 
 * 
 * Author          : Max Root
 * Created On      : Sat Jul  6 14:26:43 2002
 * Last Modified By: Maxime Soule
 * Last Modified On: Mon Jan 14 17:38:47 2008
 * Update Count    : 16
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: Object.m,v $
 * Revision 1.5  2008/01/14 16:41:22  max
 * Switch to new mcc.
 * Use NEW_PTR macro.
 *
 * Revision 1.4  2006/10/05 19:08:56  max
 * s/special_pointer_[sg]et2/special_pointer_[sg]et/g
 *
 * Revision 1.3  2006/04/25 08:47:07  max
 * Add comment.
 *
 * Revision 1.2  2005/03/02 19:02:41  max
 * Change -initialize and -deinitialize methods to -initialize: and
 * -deinitialize: to know whether the globals are available or not.
 *
 * Revision 1.1  2005/02/09 22:57:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_OBJECT
#include "Object.h"

#ifdef __palmos__

#include "misc.h"

extern unsigned** MultilinkSegmentJmpTables; /* common: jmptable pointers  */

/* Allow to set the auxiliary pointer */
void special_pointer_set(void *pv_ptr)
{
    void **ppv_ptr;

    asm("move.l MultilinkSegmentJmpTables@END(%%a5),%0" : "=a" (ppv_ptr));

    ppv_ptr[-1] = pv_ptr;
}

/* Allow to retrieve the auxiliary pointer */
void *special_pointer_get(void)
{
    void **ppv_ptr;

    asm("move.l MultilinkSegmentJmpTables@END(%%a5),%0" : "=a" (ppv_ptr));

    return ppv_ptr[-1];
}

# ifdef FEATURE_CLASSES
#  define CREATOR_ID	'MaT2'
#  define FEATURE_ID	0x0b1c	// Objc
# endif // FEATURE_CLASSES

void ObjcLoadClasses(Boolean b_globals)
{
  Object_c **poClasses;

  // On alloue la zone pour les N pointeurs sur les classes
  NEW_PTR(poClasses, NUM_CLASSES * sizeof(Object *),
	  ErrFatalDisplayIf(poClasses == NULL,
			    "Could not allocate memory for classes"));

  // On remplit la zone
  initClasses(poClasses, b_globals);

# ifdef FEATURE_CLASSES
  // On crée la feature
  FtrSet(CREATOR_ID, FEATURE_ID, (UInt32)poClasses);
# else
  special_pointer_set(poClasses);
# endif
}


void ObjcUnloadClasses(Boolean b_globals)
{
  Object_c **poClasses;

  poClasses = ObjcGetClasses();

# ifdef FEATURE_CLASSES
  // On désenregistre la feature
  FtrUnregister(CREATOR_ID, FEATURE_ID);
# endif

  // On libère la zone
  if (poClasses != NULL)
  {
    UInt16 index;

    for (index = NUM_CLASSES; index-- > 0; )
    {
      // On appelle la méthode deinitialize
      [poClasses[index] deinitialize:b_globals];

      // On libère l'espace pris par la classe
      MemPtrFree(poClasses[index]);
    }

    MemPtrFree(poClasses);
  }
}


# ifdef FEATURE_CLASSES
Object_c **ObjcGetClasses(void)
{
  Object_c **poClasses;

  ErrFatalDisplayIf(FtrGet(CREATOR_ID, FEATURE_ID, (UInt32 *)&poClasses) != 0
		    || poClasses == NULL,
		    "Could not find classes table");
  return poClasses;
}
# endif // FEATURE_CLASSES
#endif // __palmos__


#ifdef USE_REFERENCE_COUNTING
void free_object(void *pv_object)
{
  Object *oObj = pv_object;

  if (oObj == nil)
    return;

  if (REFCNT(oObj) == 0)
  {
    // XXX WARNING A FAIRE XXX
    // warn("Attempt to free unreferenced object");
    return;
  }

  if (--REFCNT(oObj) == 0)
    [oObj free];
}
#endif // USE_REFERENCE_COUNTING


@implementation Object

//
// Méthodes de classe

// Appelée juste après l'initialisation de la classe
// b_globals est à true si on a accès aux variables globales
+ (void)initialize:(Boolean)b_globals
{
  // *** Doit toujours être vide dans la classe de base ***
}


// Appelée juste avant la libération de la classe
// b_globals est à true si on a accès aux variables globales
+ (void)deinitialize:(Boolean)b_globals
{
  // *** Doit toujours être vide dans la classe de base ***
}


+ (Object*)alloc
{
  Object *oObject;

  oObject = Malloc(self->uh_size);
  if (oObject == nil)
  {
    // XXX
    return nil;
  }

  MemSet(oObject, self->uh_size, '\0');
  oObject->oIsa = self;

#ifdef USE_REFERENCE_COUNTING
  // Première référence
  REFCNT(oObject) = 1;
#endif

  //printf("alloc: 0x%x\n", (uint32)oObject);
  return oObject;
}


+ (Object_c*)superClass
{
  return self->oSuper;		/* nil pour Object */
}


+ (Boolean)isSubclassOf:(id)oOther
{
  Object_c *oClass = self;
  do
  {
    if (oClass == (Object_c*)oOther)
      return true;

    oClass = oClass->oSuper;
  }
  while (oClass != nil);

  return false;
}


+ (Object_c*)findClass:(char *)pa_class_name
{
  Object_c **poClasses;
  UInt16 index;

  poClasses = ObjcGetClasses();

  for (index = NUM_CLASSES; index-- > 0; )
  {
    if (StrCompare(pa_class_name, poClasses[index]->pa_name) == 0)
      return poClasses[index];
  }

  return nil;
}


//
// Méthodes d'instance
- (Object*)free
{
  self->oIsa = nil;		// Par précaution...
  Free(self);

  return nil;
}


- (Object*)freeContents
{
  return self;
}


- (const char *)className
{
  return self->oIsa->pa_name;
}


- (Object*)copy
{
  Object *oNew = Malloc(self->oIsa->uh_size);
  if (oNew == nil)
  {
    // XXX
    return nil;
  }

  MemMove(oNew, self, self->oIsa->uh_size);

#ifdef USE_REFERENCE_COUNTING
  // Première référence
  REFCNT(oNew) = 1;
#endif

  //printf("copy: 0x%x\n", (uint32)oNew);
  return oNew;
}


// À ce niveau c'est pareil de copy
- (Object*)deepCopy
{
  return [self copy];
}


- (Boolean)isKindOf:(id)oClass
{
  Object_c *oCurClass;

  oCurClass = self->oIsa;
  do
  {
    if (oCurClass == (Object_c*)oClass)
      return true;

    oCurClass = oCurClass->oSuper;
  }
  while (oCurClass != nil);

  return false;
}


- (Boolean)isMemberOf:(id)oClass
{
  return self->oIsa == (Object_c*)oClass;
}


- (Object_c*)class
{
  return self->oIsa;
}


- (Boolean)isEqual:(Object*)oOther
{
  // Même classe ?
  if (self->oIsa == oOther->oIsa)
  {
    // S'il y a plus d'attributs que les attributs de Object, on les compare
    if (self->oIsa->uh_size > sizeof(Object))
      return MemCmp((char*)self + sizeof(Object),
		    (char*)oOther + sizeof(Object),
		    self->oIsa->uh_size - sizeof(Object)) == 0;

    // Pas d'autres attributs, donc c'est bon
    return true;
  }

  // Pas la même classe
  return false;
}

@end
