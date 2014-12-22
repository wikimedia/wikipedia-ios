//
//  OldDataSchema.h
//  OldDataSchema
//
//  Created by Brion on 12/22/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>


@class OldDataSchema;

@protocol OldDataSchemaDelegate

-(void)oldDataSchema:(OldDataSchema *)schema migrateArticle:(NSDictionary *)articleDict;
-(void)oldDataSchema:(OldDataSchema *)schema migrateHistoryEntry:(NSDictionary *)historyDict;
-(void)oldDataSchema:(OldDataSchema *)schema migrateSavedEntry:(NSDictionary *)savedDict;

@end


@interface OldDataSchema : NSObject

@property (weak) id<OldDataSchemaDelegate> delegate;

-(BOOL)exists;
-(void)migrateData;

@end
