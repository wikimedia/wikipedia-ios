#ifndef WMFDeprecationMacros_h
#define WMFDeprecationMacros_h

///
/// @name Tech Debt Deprecation
///

#ifndef WMF_SHOW_TECH_DEBT_WARNINGS
#define WMF_SHOW_TECH_DEBT_WARNINGS 0
#endif

#define DO_PRAGMA(x) _Pragma(#x)

#if WMF_SHOW_TECH_DEBT_WARNINGS

/**
 *  @function WMF_TECH_DEBT_DEPRECATED
 *
 *  Mark method as deprecated if tech debt warnings are enabled.
 */
#define WMF_TECH_DEBT_DEPRECATED __deprecated

/**
 *  @function WMF_TECH_DEBT_DEPRECATED_MSG
 *
 *  Mark method as deprecated if tech debt warnings are enabled.
 *
 *  @param ... Arguments passed to __deprecate_msg
 */
#define WMF_TECH_DEBT_DEPRECATED_MSG(...) __deprecated_msg(__VA_ARGS__)

#define WMF_TECH_DEBT_TODO(t) WMF_TECH_DEBT_WARN(TODO \
                                                 : t)

/**
 *  @function WMF_TECH_DEBUG_WARN
 *
 *  Emit a compiler warning if tech debt warnings are enabled.
 *
 *  @param ... Arguments passed to <code>#warning</code>.
 */
#define WMF_TECH_DEBT_WARN(w) DO_PRAGMA(message(#w))

#else

#define WMF_TECH_DEBT_DEPRECATED

#define WMF_TECH_DEBT_DEPRECATED_MSG(...)

#define WMF_TECH_DEBT_WARN(w)

#define WMF_TECH_DEBT_TODO(t)

#endif

///
/// @name Deployment-Target-Based Deprecation
///

#ifndef WMF_DEPRECATE_BELOW_DEPLOY_TARGET
#define WMF_DEPRECATE_BELOW_DEPLOY_TARGET 0
#endif

#if WMF_DEPRECATE_BELOW_DEPLOY_TARGET && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_9_0
#define WMF_DEPRECATED_WHEN_DEPLOY_AT_LEAST_9 __deprecated_msg("This API was only necessary when deployment target was < 9. Please remove any code being executed when OS is less than 9.")
#else
#define WMF_DEPRECATED_WHEN_DEPLOY_AT_LEAST_9
#endif

#endif /* WMFDeprecationMacros_h */
