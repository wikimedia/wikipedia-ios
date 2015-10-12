//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCTestFailureHandler.h>

/*!
 * @brief Returns chain of test failure handlers.
 * @deprecated Version 4.2.0. Use <code>[HCTestFailureReporterChain chain]</code> instead.
 * @see HCTestFailureReporterChain
 */
FOUNDATION_EXPORT HCTestFailureHandler *HC_testFailureHandlerChain(void) __attribute__((deprecated));
