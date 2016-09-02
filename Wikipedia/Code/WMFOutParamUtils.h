#ifndef Wikipedia_WMFOutParamUtils_h
#define Wikipedia_WMFOutParamUtils_h

/**
 * Safely assign a value to an outParam (or any other double pointer).
 *
 * For example:
   @code
   - (BOOL)myMethod:(NSError**)outErr {
       NSError* error = [self somethingDangerous];
       if (error) {
         WMFSafeAssign(outErr, error);
         return NO;
       }
       return YES;
   }
   @endcode
 *
 * @note This needs to be a macro due to problems casting between ObjC & C indirect pointers.
 */
#define WMFSafeAssign(outParam, value) \
    do {                               \
        if (outParam != NULL) {        \
            *(outParam) = (value);     \
        }                              \
    } while (0)

#endif
