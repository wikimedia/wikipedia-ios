//  Created by Monte Hurd on 10/24/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIWebView+LoadAssetsHtml.h"

@implementation UIWebView (LoadAssetsHtml)

-(void)loadHTMLFromAssetsFile:(NSString *)fileName
{
    NSArray *documentsPath = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *assetsPath = [[documentsPath firstObject] stringByAppendingPathComponent:@"assets"];
    NSString *indexHTMLFilePath = [assetsPath stringByAppendingPathComponent:fileName];
    NSString *encodedAssetsPath = [assetsPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"file:///%@/", encodedAssetsPath]];
    NSData *fileData = [[NSFileManager defaultManager] contentsAtPath: indexHTMLFilePath];
    [self loadData:fileData MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:baseURL];
}

@end
