//
//  RMStoreUserDefaultsTransactionPersistor.h
//  RMStore
//
//  Created by Hermes on 10/16/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMStore.h"
@class RMStoreTransaction;

@interface RMStoreUserDefaultsTransactionPersistor : NSObject<RMStoreTransactionPersistor>

- (void)removeTransactions;

- (BOOL)consumeProductOfIdentifier:(NSString*)productIdentifier;

- (NSInteger)countProductOfdentifier:(NSString*)productIdentifier;

- (BOOL)isPurchasedProductOfIdentifier:(NSString*)productIdentifier;

- (NSArray*)purchasedProductIdentifiers;

- (NSArray*)transactionsForProductOfIdentifier:(NSString*)productIdentifier;

@end

@interface RMStoreUserDefaultsTransactionPersistor(Obfuscation)

- (NSData*)dataWithTransaction:(RMStoreTransaction*)transaction;

- (RMStoreTransaction*)transactionWithData:(NSData*)data;

@end