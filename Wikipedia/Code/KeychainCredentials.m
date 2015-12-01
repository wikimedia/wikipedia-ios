//  Created by Monte Hurd on 2/9/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "KeychainCredentials.h"

@implementation KeychainCredentials

- (void)setUserName:(NSString*)userName {
    [self setKeychainValue:userName forEntry:@"org.wikimedia.wikipedia.username"];
}

- (NSString*)userName {
    return [self getKeychainValueForEntry:@"org.wikimedia.wikipedia.username"];
}

- (void)setPassword:(NSString*)password {
    [self setKeychainValue:password forEntry:@"org.wikimedia.wikipedia.password"];
}

- (NSString*)password {
    return [self getKeychainValueForEntry:@"org.wikimedia.wikipedia.password"];
}

- (void)setEditTokens:(NSDictionary*)editTokens {
    if (!editTokens) {
        [self setKeychainValue:nil forEntry:@"org.wikimedia.wikipedia.edittokens"];
        return;
    }

    NSError* error            = nil;
    NSData* tokenDictJsonData = [NSJSONSerialization dataWithJSONObject:editTokens
                                                                options:NSJSONWritingPrettyPrinted
                                                                  error:&error];
    if (!error) {
        NSString* tokenDictJsonString = [[NSString alloc] initWithData:tokenDictJsonData
                                                              encoding:NSUTF8StringEncoding];
        [self setKeychainValue:tokenDictJsonString forEntry:@"org.wikimedia.wikipedia.edittokens"];
    }
}

- (NSMutableDictionary*)editTokens {
    NSString* tokenDictJsonString = [self getKeychainValueForEntry:@"org.wikimedia.wikipedia.edittokens"];
    if (!tokenDictJsonString) {
        return [@{} mutableCopy];
    }

    NSError* error          = nil;
    NSDictionary* tokenDict = [NSJSONSerialization JSONObjectWithData:[tokenDictJsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                              options:kNilOptions
                                                                error:&error];
    return (!error) ? [tokenDict mutableCopy] : [@{} mutableCopy];
}

- (BOOL)setKeychainValue:(NSString*)value forEntry:(NSString*)entry {
    if (!value) {
        // Makes setting the value to nil cause the item to be removed from the keychain.
        [self deleteItemFromKeychainWithIdentifier:entry];
        return YES;
    }

    NSData* encodedName = [entry dataUsingEncoding:NSUTF8StringEncoding];
    NSData* valueData   = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* dict  = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"],
        (__bridge id)kSecAttrGeneric: encodedName,
        (__bridge id)kSecAttrAccount: encodedName,
        (__bridge id)kSecValueData: valueData,
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenUnlocked,
    };

    // Create the keychain item, if it doesn't yet exist...
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dict, NULL);
    if (status == errSecSuccess) {
        return YES;
    } else if (status == errSecDuplicateItem) {
        // Exists! Pass through to update.
        return [self updateKeychainValue:value forEntry:entry];
    } else {
        NSLog(@"Keychain: Something exploded; SecItemAdd returned %i", (int)status);
        return NO;
    }
}

- (BOOL)updateKeychainValue:(NSString*)value forEntry:(NSString*)entry {
    NSData* encodedName = [entry dataUsingEncoding:NSUTF8StringEncoding];
    NSData* valueData   = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* dict  = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"],
        (__bridge id)kSecAttrGeneric: encodedName,
        (__bridge id)kSecAttrAccount: encodedName
    };
    NSDictionary* dataDict = @{
        (__bridge id)kSecValueData: valueData
    };

    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)dict, (__bridge CFDictionaryRef)dataDict);
    if (status == errSecSuccess) {
        return YES;
    } else {
        //NSLog(@"Keychain: SecItemUpdate returned %i", (int)status);
        return NO;
    }
}

- (NSString*)getKeychainValueForEntry:(NSString*)entry {
    NSData* encodedName = [entry dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* dict  = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"],
        (__bridge id)kSecAttrGeneric: encodedName,
        (__bridge id)kSecAttrAccount: encodedName,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
        (__bridge id)kSecReturnData: (__bridge id)kCFBooleanTrue
    };

    // Fetch username and password from keychain
    CFTypeRef found = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dict, &found);
    if (status == noErr) {
        NSData* result = (__bridge_transfer NSData*)found;
        return [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    } else {
        //NSLog(@"Keychain: SecItemCopyMatching returned %i", (int)status);
        return nil;
    }
}

// From: http://www.raywenderlich.com/6475/basic-security-in-ios-5-tutorial-part-1
- (void)deleteItemFromKeychainWithIdentifier:(NSString*)identifier {
    NSMutableDictionary* searchDictionary = [self setupSearchDirectoryForIdentifier:identifier];
    CFDictionaryRef dictionary            = (__bridge CFDictionaryRef)searchDictionary;

    //Delete.
    SecItemDelete(dictionary);
}

// From: http://www.raywenderlich.com/6475/basic-security-in-ios-5-tutorial-part-1
- (NSMutableDictionary*)setupSearchDirectoryForIdentifier:(NSString*)identifier {
    // Setup dictionary to access keychain.
    NSMutableDictionary* searchDictionary = [[NSMutableDictionary alloc] init];
    // Specify we are using a password (rather than a certificate, internet password, etc).
    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    // Uniquely identify this keychain accessor.
    [searchDictionary setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"] forKey:(__bridge id)kSecAttrService];

    // Uniquely identify the account who will be accessing the keychain.
    NSData* encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];

    return searchDictionary;
}

@end
