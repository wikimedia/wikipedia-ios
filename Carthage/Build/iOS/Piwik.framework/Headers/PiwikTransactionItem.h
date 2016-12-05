//
//  PiwikTransactionItem.h
//  PiwikTracker
//
//  Created by Mattias Levin on 19/01/14.
//  Copyright (c) 2014 Mattias Levin. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 An item added to a transaction.
 @see PiwikTransaction
 */
@interface PiwikTransactionItem : NSObject

/**
 The unique SKU of the item. Mandatory.
 */
@property (nonatomic, readonly) NSString *sku;

/**
 The name of the item. Optional.
 */
@property (nonatomic, readonly) NSString *name;

/**
 Item category. Optional.
 */
@property (nonatomic, readonly) NSString *category;

/**
 Item price. Optional.
 */
@property (nonatomic, readonly) NSNumber *price;

/**
 Item quantity. Optional.
 */
@property (nonatomic, readonly) NSNumber *quantity;


/**
 Create an item to be added to a transaction.
 
 @param sku The unique SKU of the item
 @param name The name of the item
 @param category The category of the added item
 @param price The price
 @param quantity The quantity of the product in the transaction
 @return A transaction item
 @see PiwikTransactionBuilder
 @see PiwikTransaction
 */
+ (instancetype)itemWithSku:(NSString*)sku
                       name:(NSString*)name
                   category:(NSString*)category
                      price:(float)price
                   quantity:(NSUInteger)quantity;


/**
 Create an item to be added to a transaction with a minimum set of mandatory parameters.
 @param sku The unique SKU of the item
 @return A transaction item
 */
+ (instancetype)itemWithSKU:(NSString*)sku;

/**
 Return YES if all mandatory properties has been set.
 */
- (BOOL)isValid;


@end
