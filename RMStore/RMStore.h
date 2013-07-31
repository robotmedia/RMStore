//
//  RMStore.h
//  RMStore
//
//  Created by Hermes Pique on 12/6/09.
//  Copyright (c) 2013 Robot Media SL (http://www.robotmedia.net)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface NSNotification(RMStore)

@property (nonatomic, readonly) NSString *productIdentifier;
@property (nonatomic, readonly) NSError *storeError;
@property (nonatomic, readonly) SKPaymentTransaction *transaction;

@end

@protocol RMStoreReceiptVerificator;

@protocol RMStoreObserver;

@interface RMStore : NSObject<SKPaymentTransactionObserver, SKProductsRequestDelegate>

@property (nonatomic, weak) id<RMStoreReceiptVerificator> receiptVerificator;

+ (RMStore*)defaultStore;

#pragma mark - StoreKit wrapper

+ (BOOL)canMakePayments;

- (void)addPayment:(NSString*)productIdentifier;

// Only one pair of blocks is allowed per product identifier.
- (void)addPayment:(NSString*)productIdentifier
           success:(void (^)(SKPaymentTransaction *transaction))successBlock
           failure:(void (^)(SKPaymentTransaction *transaction, NSError *error))failureBlock;

- (void)requestProducts:(NSSet*)identifiers;

- (void)requestProducts:(NSSet*)identifiers
                success:(void (^)())successBlock
                failure:(void (^)(NSError *error))failureBlock;

- (void)restoreTransactions;

- (void)restoreTransactionsOnSuccess:(void (^)())successBlock
                             failure:(void (^)(NSError *error))failureBlock;

#pragma mark - Purchase management

- (void)addPurchaseForIdentifier:(NSString*)productIdentifier;

- (void)clearPurchases;

- (BOOL)consumeProductForIdentifier:(NSString*)productIdentifier;

- (NSInteger)countPurchasesForIdentifier:(NSString*)productIdentifier;

- (BOOL)isPurchasedForIdentifier:(NSString*)productIdentifier;

- (SKProduct*)productForIdentifier:(NSString*)productIdentifier;

- (NSArray*)purchasedIdentifiers;

#pragma mark - Notifications

- (void)addStoreObserver:(id<RMStoreObserver>)observer;

- (void)removeStoreObserver:(id<RMStoreObserver>)observer;

#pragma mark - Utils

+ (NSString*)localizedPriceOfProduct:(SKProduct*)product;

@end

@protocol RMStoreObserver<NSObject>
@optional

- (void)storeProductsRequestFailed:(NSNotification*)notification;
- (void)storeProductsRequestFinished:(NSNotification*)notification;
- (void)storePaymentTransactionFailed:(NSNotification*)notification;
- (void)storePaymentTransactionFinished:(NSNotification*)notification;
- (void)storeRestoreTransactionsFailed:(NSNotification*)notification;
- (void)storeRestoreTransactionsFinished:(NSNotification*)notification;

@end

@protocol RMStoreReceiptVerificator <NSObject>

- (void)verifyReceiptOfTransaction:(SKPaymentTransaction*)transaction
                           success:(void (^)())successBlock
                           failure:(void (^)(NSError *error))failureBlock;

@end
