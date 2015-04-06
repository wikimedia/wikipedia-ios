//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

int main(int argc, char* argv[]) {
    // disable app when unit testing to allow tests to run in isolation (w/o side effects)
    BOOL const isUnitTesting = NSClassFromString(@"XCTestCase") != nil;
    @autoreleasepool {
        return UIApplicationMain(argc,
                                 argv,
                                 nil,
                                 isUnitTesting ? nil : NSStringFromClass([AppDelegate class]));
    }
}
