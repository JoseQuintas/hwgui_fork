/*
  $Id$
  
  incomp_pointer.h
  
  Suppress common warnings 
  for GCC 
  
*/

#ifndef _COMMON_GCC_WARNINGS
#define _COMMON_GCC_WARNINGS



#if defined(__GNUC__) && !defined(__INTEL_COMPILER) && !defined(__clang__)
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif

#endif /* _COMMON_GCC_WARNINGS */

/* ============================= EOF of warnings.h ====================== */
