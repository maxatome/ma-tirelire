/* 
 * Hash.m -- 
 * 
 * Author          : Maxime Soule
 * Created On      : Fri Dec 21 14:25:15 2007
 * Last Modified By: Maxime Soule
 * Last Modified On: Thu Jan 10 19:15:39 2008
 * Update Count    : 41
 * Status          : Unknown, Use with caution!
 *
 *
 * ==================== RCS ====================
 * $Author: max $
 * $Log: Hash.m,v $
 * Revision 1.1  2008/01/16 17:22:22  max
 * First import.
 *
 * ==================== RCS ==================== */

#define EXTERN_HASH
#include "Hash.h"

#include "misc.h"


struct s_hash_key
{
  struct s_hash_key *ps_next;

  // Value
  MemHandle pv_value;

  // Key
  UInt32 ui_hash;
  UInt16 uh_len;
  Char   ra_key[0];		// key always \0 terminated
};


#define free_key(ps_entry)	MemPtrFree(ps_entry)

static struct s_hash_key *new_key(Char *pa_key, UInt16 uh_len, UInt32 ui_hash)
{
  struct s_hash_key *ps_entry;

  NEW_PTR(ps_entry, sizeof(struct s_hash_key) + uh_len + 1, return NULL);

  MemMove(ps_entry->ra_key, pa_key, uh_len);
  ps_entry->ra_key[uh_len] = '\0';

  ps_entry->ui_hash = ui_hash;
  ps_entry->uh_len = uh_len;

  return ps_entry;
}


// Use perl 5.8.8 hash algorithm
static UInt32 hash(Char *pa_str, UInt16 uh_len)
{
  register const UChar *pua_cur = (const UChar*)pa_str;
  UInt32 ui_hash = 0;

  while (uh_len--)
  {
    ui_hash += *pua_cur++;
    ui_hash += (ui_hash << 10);
    ui_hash ^= (ui_hash >> 6);
  }

  ui_hash += (ui_hash << 3);
  ui_hash ^= (ui_hash >> 11);

  return ui_hash + (ui_hash << 15);
}


@implementation Hash

+ (Hash*)new
{
  return [[self alloc] init];
}


- (Hash*)init
{
  self->i_max_line = 7;

  [self iterInit];

  return self;
}


- (Hash*)free
{
  if (self->pv_array != NULL)
  {
    struct s_hash_key *ps_entry, *ps_next_entry, **pps_entries;
    Int32 index;

    pps_entries = MemHandleLock(self->pv_array);

    for (index = self->i_max_line; index >= 0; index--)
    {
      ps_entry = pps_entries[index];
      while (ps_entry != NULL)
      {
	ps_next_entry = ps_entry->ps_next;

	free_key(ps_entry);

	ps_entry = ps_next_entry;
      }
    }

    MemHandleUnlock(self->pv_array);

    MemHandleFree(self->pv_array);
  }

  return [super free];
}


- (MemHandle)fetchKey:(Char*)pa_key len:(Int16)h_len
{
  struct s_hash_key *ps_entry;

  ps_entry = [self fetchCommonKey:pa_key len:h_len hash:0 value:NULL];
  if (ps_entry == NULL)
    return NULL;

  return ps_entry->pv_value;
}


- (MemHandle)store:(MemHandle)pv_elem atKey:(Char*)pa_key len:(Int16)h_len
{
  [self fetchCommonKey:pa_key len:h_len hash:0 value:&pv_elem];

  return pv_elem;
}


- (MemHandle)deleteKey:(Char*)pa_key len:(Int16)h_len
{
  struct s_hash_key *ps_entry, **pps_entries, **pps_base_entry;
  MemHandle pv_ret = NULL;
  UInt32 ui_hash;

  if (self->pv_array == NULL)
    return NULL;

  ui_hash = hash(pa_key, h_len);

  pps_entries = MemHandleLock(self->pv_array);

  pps_base_entry = &pps_entries[ui_hash & self->i_max_line];
  ps_entry = *pps_base_entry;

  for (; ps_entry != NULL;
       pps_base_entry = &ps_entry->ps_next, ps_entry = *pps_base_entry)
  {
    if (ps_entry->ui_hash == ui_hash
	&& ps_entry->uh_len == h_len
	&& (pa_key == ps_entry->ra_key
	    || MemCmp(ps_entry->ra_key, pa_key, h_len) == 0))
    {
      pv_ret = ps_entry->pv_value;

      *pps_base_entry = ps_entry->ps_next;

      if (ps_entry == self->ps_iter_cur)
	self->b_lazy_delete = true;
      else
	free_key(ps_entry);

      self->ui_nb_elem--;

      break;
    }
  }

  MemHandleUnlock(self->pv_array);

  return pv_ret;
}


- (UInt32)iterInit
{
  struct s_hash_key *ps_entry;

  ps_entry = self->ps_iter_cur;
  if (ps_entry && self->b_lazy_delete)
  {
    self->b_lazy_delete = false;
    free_key(ps_entry);
  }

  self->i_iter_root = -1;
  self->ps_iter_cur = NULL;

  return self->ui_nb_elem;
}


- (Boolean)iterNextKey:(Char**)ppa_key len:(UInt16*)puh_len
		 value:(MemHandle*)ppv_elem
{
  struct s_hash_key *ps_entry, *ps_old_entry, **pps_entries;

  if (self->pv_array == NULL)
    return false;

  ps_old_entry = ps_entry = self->ps_iter_cur;

  if (ps_entry != NULL)
    ps_entry = ps_entry->ps_next;

  pps_entries = MemHandleLock(self->pv_array);

  while (ps_entry == NULL)
  {
    if (++self->i_iter_root > self->i_max_line)
    {
      self->i_iter_root = -1;
      ps_entry = NULL;
      break;
    }

    ps_entry = pps_entries[self->i_iter_root];
  }

  MemHandleUnlock(self->pv_array);

  if (ps_old_entry && self->b_lazy_delete)
  {
    self->b_lazy_delete = false;
    free_key(ps_entry);
  }

  self->ps_iter_cur = ps_entry;

  if (ps_entry != NULL)
  {
    if (ppa_key != NULL)
      *ppa_key = ps_entry->ra_key;

    if (puh_len != NULL)
      *puh_len = ps_entry->uh_len;

    if (ppv_elem != NULL)
      *ppv_elem = ps_entry->pv_value;

    return true;
  }

  return false;
}


- (UInt32)size
{
  return self->ui_nb_elem;
}


- (struct s_hash_key*)fetchCommonKey:(Char*)pa_key len:(Int16)h_len
				hash:(UInt32)ui_hash
			       value:(MemHandle*)ppv_elem
{
  struct s_hash_key *ps_entry, **pps_entries = NULL, **pps_base_entry;

  if (self->pv_array == NULL)
  {
    struct s_hash_key **pps_entries;
    UInt32 ui_alloc;

    if (ppv_elem == NULL)
      return NULL;

    ui_alloc = (self->i_max_line + 1) * sizeof(struct s_hash_key*);

    NEW_HANDLE(self->pv_array, ui_alloc, return NULL);

    pps_entries = MemHandleLock(self->pv_array);
    MemSet(pps_entries, ui_alloc, '\0');
  }
  else
    pps_entries = MemHandleLock(self->pv_array);

  if (h_len < 0)
    h_len = StrLen(pa_key);

  if (ui_hash == 0)
    ui_hash = hash(pa_key, h_len);

  for (ps_entry = pps_entries[ui_hash & self->i_max_line];
       ps_entry != NULL;
       ps_entry = ps_entry->ps_next)
  {
    if (ps_entry->ui_hash == ui_hash
	&& ps_entry->uh_len == h_len
	&& (pa_key == ps_entry->ra_key
	    || MemCmp(ps_entry->ra_key, pa_key, h_len)) == 0)
    {
      if (ppv_elem != NULL)
      {
	MemHandle pv_old_value;

	pv_old_value = ps_entry->pv_value;
	ps_entry->pv_value = *ppv_elem;
	*ppv_elem = pv_old_value;
      }

      MemHandleUnlock(self->pv_array);

      return ps_entry;
    }
  }

  // Key not found

  // Nothing to store
  if (ppv_elem == NULL)
  {
    MemHandleUnlock(self->pv_array);
    return NULL;
  }

  pps_base_entry = &pps_entries[ui_hash & self->i_max_line];

  ps_entry = new_key(pa_key, h_len, ui_hash);
  if (ps_entry == NULL)
    // XXX
    ;
  ps_entry->pv_value = *ppv_elem;
  ps_entry->ps_next = *pps_base_entry;

  *pps_base_entry = ps_entry;

  MemHandleUnlock(self->pv_array);

  self->ui_nb_elem++;

  // Use an already used line AND new elems # too high
  if (ps_entry->ps_next != NULL && self->ui_nb_elem > self->i_max_line)
    [self _increaseArray];

  *ppv_elem = NULL;

  return ps_entry;
}


- (void)_increaseArray
{
  struct s_hash_key *ps_entry, **pps_entries;
  struct s_hash_key **pps_cur, **pps_dest, **pps_base_entry;
  UInt32 ui_old_size = self->i_max_line + 1;
  UInt32 ui_new_size = ui_old_size * 2;
  Int32 index;

  if (MemHandleResize(self->pv_array, ui_new_size) != 0)
    return;

  pps_entries = MemHandleLock(self->pv_array);

  MemSet(&pps_entries[ui_old_size], ui_old_size * sizeof(ps_entry), '\0');

  self->i_max_line = --ui_new_size;

  for (index = ui_old_size, pps_cur = &pps_entries[index]; index-- > 0; )
  {
    if (*--pps_cur == NULL)
      continue;

    pps_dest = pps_cur + ui_old_size;

    for (pps_base_entry = pps_cur, ps_entry = *pps_cur; ps_entry != NULL;
	 ps_entry = *pps_base_entry)
    {
      if ((ps_entry->ui_hash & ui_new_size) != index)
      {
	*pps_base_entry = ps_entry->ps_next;
	ps_entry->ps_next = *pps_dest;
	*pps_dest = ps_entry;

	continue;
      }

      pps_base_entry = &ps_entry->ps_next;
    }
  }

  MemHandleUnlock(self->pv_array);
}

@end
