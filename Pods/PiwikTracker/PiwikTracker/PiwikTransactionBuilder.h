//
//  PiwikTransactionBuilder.h
//  PiwikTracker
//
//  Created by Mattias Levin on 19/01/14.
//  Copyright (c) 2014 Mattias Levin. All rights reserved.
//

#import <Foundation/Foundation.h>


@class PiwikTransaction;


/**
 A transaction builder for building Piwik ecommerce transactions.
 A transaction contains information about the transaction as will as the items included in the transaction.
 */
@interface PiwikTransactionBuilder : NSObject


/**
 A unique transaction identifier.
 */
@property (nonatomic, strong) NSString *identifier;

/**
 The grand total for the ecommerce order
 */
@property (nonatomic, strong) NSNumber *grandTotal;

/**
 The sub total of the transaction (excluding shipping cost).
 */
@property (nonatomic, strong) NSNumber *subTotal;

/**
 The total tax.
 */
@property (nonatomic, strong) NSNumber *tax;

/**
 The total shipping cost
 */
@property (nonatomic, strong) NSNumber *shippingCost;

/**
 The total offered discount.
 */
@property (nonatomic, strong) NSNumber *discount;

/**
 A list of items included in the transaction.
 @see PiwikTransactionItem
 */
@property (nonatomic, strong) NSMutableArray *items;


/**
 Add a transaction item.

 @param sku The unique SKU of the item
 @param name The name of the item
 @param category The category of the added item
 @param price The price
 @param quantity The quantity of the product in the transaction
 */
- (void)addItemWithSku:(NSString*)sku
                  name:(NSString*)name
              category:(NSString*)category
                 price:(float)price
              quantity:(NSUInteger)quantity;

/**
 Add a transaction item to the transaction.
 
 @param sku The unique SKU of the item
 @see addItemWithSku:name:category:price:quantity:
 */
- (void)addItemWithSku:(NSString*)sku;


/**
 Build a transaction from the builder.
 @return a new transaction
 */
- (PiwikTransaction*)build;


@end
