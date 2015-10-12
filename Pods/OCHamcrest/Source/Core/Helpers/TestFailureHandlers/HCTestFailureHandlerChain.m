//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import "HCTestFailureHandlerChain.h"

#import "HCTestFailureReporterChain.h"


HCTestFailureHandler *HC_testFailureHandlerChain(void)
{
    return [HCTestFailureReporterChain reporterChain];
}
