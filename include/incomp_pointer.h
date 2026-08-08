/*
 *  $Id$
 *
 *  incomp_pointer.h
 *
 *  Suppress warning if a function pointer is cast to an incompatible function pointer
 *  for GCC >= 8.1.x (MinGW64 )
 *
 */

#ifndef _INCOMP_POINTER_WARNING
   #define _INCOMP_POINTER_WARNING

   #if defined(__GNUC__) && !defined(__INTEL_COMPILER) && !defined(__clang__)

      /* Suppress warnings for GCC >= 8.1.x (MinGW64) */
      #if (__GNUC__ > 8) || ((__GNUC__ == 8 ) && (__GNUC_MINOR__ >= 1 ))
         #pragma GCC diagnostic ignored "-Wcast-function-type"
         #pragma GCC diagnostic ignored "-Wint-to-pointer-cast"
         #pragma GCC diagnostic ignored "-Wunused-parameter"
         #pragma GCC diagnostic ignored "-Wpointer-to-int-cast"
         #pragma GCC diagnostic ignored "-Wabsolute-value"
      #endif

      /*
       *         GLOBAL LINUX/GTK BLINDAGE
       *         Suppresses internal Harfbuzz/GTK macro conflicts and deprecations
       */
      #if !defined(__WIN32__)
         #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
         #pragma GCC diagnostic ignored "-Wattributes"

         #ifdef HB_DEPRECATED
            #undef HB_DEPRECATED
         #endif
      #endif /* !defined(__WIN32__) */

   #endif /* __GNUC__ */

#endif /* _INCOMP_POINTER_WARNING */

/* ============================= EOF of incomp_pointer.h ============================= */
