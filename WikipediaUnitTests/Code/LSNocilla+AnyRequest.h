//
//  LSNocilla+AnyRequest.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/19/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Nocilla/Nocilla.h>
#import <Foundation/Foundation.h>

static inline LSStubRequestDSL *stubAnyRequest() {
    NSError *regexError;
    NSRegularExpression *anyRequestRegex =
        [NSRegularExpression regularExpressionWithPattern:@".*"
                                                  options:0
                                                    error:&regexError];
    NSCParameterAssert(!regexError);
    return stubRequest(@"GET", anyRequestRegex);
}
