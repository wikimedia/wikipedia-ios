//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCTestFailureHandlerChain.h"

#import "HCGenericTestFailureHandler.h"
#import "HCSenTestFailureHandler.h"
#import "HCXCTestFailureHandler.h"


HCTestFailureHandler *HC_testFailureHandlerChain(void)
{
    static HCTestFailureHandler *chain = nil;
    if (!chain)
    {
        HCTestFailureHandler *genericHandler = [[HCGenericTestFailureHandler alloc] initWithSuccessor:nil];
        HCTestFailureHandler *ocunitHandler = [[HCSenTestFailureHandler alloc] initWithSuccessor:genericHandler];
        HCTestFailureHandler *xctestHandler = [[HCXCTestFailureHandler alloc] initWithSuccessor:ocunitHandler];
        chain =  xctestHandler;
    }
    return chain;
}
