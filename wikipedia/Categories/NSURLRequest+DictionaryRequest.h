//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@interface NSURLRequest (DictionaryRequest)

+ (NSURLRequest *)postRequestWithURL:(NSURL *)url
                          parameters:(NSDictionary *)parameters;
+ (NSURLRequest *)getRequestWithURL:(NSURL *)url
                          parameters:(NSDictionary *)parameters;
@end
