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

@protocol RMStoreReceiptVerificator;
@protocol RMStoreObserver;

/** A StoreKit wrapper that adds blocks and notifications, plus optional receipt verification and purchase management.
 */
@interface RMStore : NSObject<SKPaymentTransactionObserver, SKProductsRequestDelegate>

@property (nonatomic, weak) id<RMStoreReceiptVerificator> receiptVerificator;

///---------------------------------------------
/// @name Getting the Store
///---------------------------------------------

/** Returns the singleton store instance.
 */
+ (RMStore*)defaultStore;

#pragma mark - StoreKit Wrapper
///---------------------------------------------
/// @name Calling StoreKit
///---------------------------------------------

/** Returns whether the user is allowed to make payments.
 */
+ (BOOL)canMakePayments;

/** Request payment of the product with the given product identifier.
 @param productIdentifier The identifier of the product whose payment will be requested. 
 */
- (void)addPayment:(NSString*)productIdentifier;

/** Request payment of the product with the given product identifier. `successBlock` will be called if the payment is successful, `failureBlock` if it isn't.
 @param productIdentifier The identifier of the product whose payment will be requested.
 @param successBlock The block to be called if the payment is sucessful. Can be `nil`.
 @param failureBlock The block to be called if the payment fails. Can be `nil`.
 */
- (void)addPayment:(NSString*)productIdentifier
           success:(void (^)(SKPaymentTransaction *transaction))successBlock
           failure:(void (^)(SKPaymentTransaction *transaction, NSError *error))failureBlock;

/** Request localized information about a set of products from the Apple App Store.
 @param identifiers The set of product identifiers for the products you wish to retrieve information of.
 */
- (void)requestProducts:(NSSet*)identifiers;

/** Request localized information about a set of products from the Apple App Store. `successBlock` will be called if the payment is successful, `failureBlock` if it isn't.
 @param identifiers The set of product identifiers for the products you wish to retrieve information of.
 @param successBlock The block to be called if the products request is sucessful. Can be `nil`.
 @param failureBlock The block to be called if the products request fails. Can be `nil`.
 */
- (void)requestProducts:(NSSet*)identifiers
                success:(void (^)())successBlock
                failure:(void (^)(NSError *error))failureBlock;

- (void)restoreTransactions;

- (void)restoreTransactionsOnSuccess:(void (^)())successBlock
                             failure:(void (^)(NSError *error))failureBlock;

#pragma mark - Purchase management
///---------------------------------------------
/// @name Managing Purchases
///---------------------------------------------

- (void)addPurchaseForIdentifier:(NSString*)productIdentifier;

- (void)clearPurchases;

- (BOOL)consumeProductForIdentifier:(NSString*)productIdentifier;

- (NSInteger)countPurchasesForIdentifier:(NSString*)productIdentifier;

- (BOOL)isPurchasedForIdentifier:(NSString*)productIdentifier;

- (SKProduct*)productForIdentifier:(NSString*)productIdentifier;

- (NSArray*)purchasedIdentifiers;

#pragma mark - Notifications
///---------------------------------------------
/// @name Managing Observers
///---------------------------------------------

- (void)addStoreObserver:(id<RMStoreObserver>)observer;

- (void)removeStoreObserver:(id<RMStoreObserver>)observer;

#pragma mark - Utils
///---------------------------------------------
/// @name Getting the Localized Price of a Product
///---------------------------------------------

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

/**
 Category on NSNotification to recover store data from userInfo without requiring to know the keys.
 */
@interface NSNotification(RMStore)

@property (nonatomic, readonly) NSString *productIdentifier;
@property (nonatomic, readonly) NSError *storeError;
@property (nonatomic, readonly) SKPaymentTransaction *transaction;

@end
