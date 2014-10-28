//  Created by Monte Hurd on 10/24/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIWebView (LoadAssetsHtml)

// Loads contents of fileName. Assumes the file is in the "assets" folder.
-(void)loadHTMLFromAssetsFile:(NSString *)fileName;

@end
