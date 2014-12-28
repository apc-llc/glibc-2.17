/* Miscellaneous support functions for dynamic linker
   Copyright (C) 1997-2004, 2006, 2009, 2011 Free Software Foundation, Inc.
   Copyright (C) 2014 Juraj Kardos, University of Lugano
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <http://www.gnu.org/licenses/>.  */

#include <sys/types.h>
#include <sys/mman.h>
#include <errno.h>

static int inside_mmap = 0;

extern void *__real_mmap (void *__addr, size_t __len, int __prot,
		   int __flags, int __fd, __off_t __offset);

void *__mmap (void *__addr, size_t __len, int __prot,
		   int __flags, int __fd, __off_t __offset)
{
  if (inside_mmap)
    return __real_mmap(__addr, __len, __prot, __flags, __fd, __offset);

  inside_mmap = 1;

  //_mmap_debug_printf("mmap(%p, %zu, %d, %d, %d, %zu);\n",
  //  __addr, __len, __prot, __flags, __fd, __offset);

  void* result = __real_mmap(__addr, __len, __prot, __flags, __fd, __offset);
  
  inside_mmap = 0;
  
  return result;
}

weak_alias (__mmap, mmap)

static int inside_mmap64 = 0;

extern void *__real_mmap64 (void *__addr, size_t __len, int __prot,
		   int __flags, int __fd, __off_t __offset);

void *__mmap64 (void *__addr, size_t __len, int __prot,
		   int __flags, int __fd, __off_t __offset)
{
  if (inside_mmap64)
    return __real_mmap64(__addr, __len, __prot, __flags, __fd, __offset);

  inside_mmap64 = 1;

  //_mmap_debug_printf("mmap64(%p, %zu, %d, %d, %d, %zu);\n",
  //  __addr, __len, __prot, __flags, __fd, __offset);

  void* result = __real_mmap64(__addr, __len, __prot, __flags, __fd, __offset);
  
  inside_mmap64 = 0;
  
  return result;
}

weak_alias (__mmap64, mmap64)

