@interface NSUserDefaults (WMFReset)

/**
 *  Resets the receiver to its default values.
 *
 *  Removes all values in the persistent application domain (based on the main bundle). Once performed, the values will
 *  equal the defaults registered in the application domain.
 *
 *  @note <code>+[NSUserDefaults resetStandardDefaults]</code> (despite the name) is not the same as this method.
 *
 *  @see -[NSUserDefaults registerDefaults]
 */
- (void)wmf_resetToDefaultValues;

@end
