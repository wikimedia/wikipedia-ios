//  Created by Monte Hurd on 2/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@interface NSHTTPCookieStorage (CloneCookie)

// Pass it 2 cookie names. If they're both found, it will discard cookieToRecreate and
// recreate it using templateCookie as a template. All of templateCookie's properties
// will be used, except "Name", "Value" and "Created", which will come from the original
// cookieToRecreate.
- (void)recreateCookie:(NSString*)cookieToRecreate usingCookieAsTemplate:(NSString*)templateCookie;

@end
