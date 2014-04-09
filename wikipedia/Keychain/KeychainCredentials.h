//  Created by Monte Hurd on 2/9/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@interface KeychainCredentials : NSObject

@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *password;

// Edit tokens are stored in the editTokens dictionary with language code
// keys mapping to token string values.
@property (strong, nonatomic) NSMutableDictionary *editTokens;

@end
