//  Created by Monte Hurd on 10/24/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIWebView (LoadAssetsHtml)

// Loads contents of fileName. Assumes the file is in the "assets" folder.
-(void)loadHTMLFromAssetsFile:(NSString *)fileName;

// Loads html passed to it injected into html from fileName.
// Warning! Probably don't call this directly! Call the method of the same
// name on the CommunicationBridge object for reasons documented there.
-(void)loadHTML:(NSString *)string withAssetsFile:(NSString *)fileName;

@end
