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
@protocol RMStoreTransactionObfuscator;
@protocol RMStoreObserver;

extern NSString *const RMStoreErrorDomain;
extern NSInteger const RMStoreErrorCodeUnknownProductIdentifier;

/** A StoreKit wrapper that adds blocks and notifications, plus optional receipt verification and purchase management.
 */
@interface RMStore : NSObject<SKPaymentTransactionObserver>

///---------------------------------------------
/// @name Getting the Store
///---------------------------------------------

/** Returns the singleton store instance.
 */
+ (RMStore*)defaultStore;

#pragma mark StoreKit Wrapper
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
 @param failureBlock The block to be called if the payment fails or there isn't any product with the given identifier. Can be `nil`.
 */
- (void)addPayment:(NSString*)productIdentifier
           success:(void (^)(SKPaymentTransaction *transaction))successBlock
           failure:(void (^)(SKPaymentTransaction *transaction, NSError *error))failureBlock;

/** Request localized information about a set of products from the Apple App Store.
 @param identifiers The set of product identifiers for the products you wish to retrieve information of.
 */
- (void)requestProducts:(NSSet*)identifiers;

/** Request localized information about a set of products from the Apple App Store. `successBlock` will be called if the products request is successful, `failureBlock` if it isn't.
 @param identifiers The set of product identifiers for the products you wish to retrieve information of.
 @param successBlock The block to be called if the products request is sucessful. Can be `nil`. It takes two parameters: `products`, an array of SKProducts, one product for each valid product identifier provided in the original request, and `invalidProductIdentifiers`, an array of product identifiers that were not recognized by the App Store. 
 @param failureBlock The block to be called if the products request fails. Can be `nil`.
 */
- (void)requestProducts:(NSSet*)identifiers
                success:(void (^)(NSArray *products, NSArray *invalidProductIdentifiers))successBlock
                failure:(void (^)(NSError *error))failureBlock;

/** Request to restore previously completed purchases.
 */
- (void)restoreTransactions;

/** Request to restore previously completed purchases. `successBlock` will be called if the restore transactions request is successful, `failureBlock` if it isn't.
 @param successBlock The block to be called if the restore transactions request is sucessful. Can be `nil`.
 @param failureBlock The block to be called if the restore transactions request fails. Can be `nil`.
 */
- (void)restoreTransactionsOnSuccess:(void (^)())successBlock
                             failure:(void (^)(NSError *error))failureBlock;


///---------------------------------------------
/// @name Setting Delegates
///---------------------------------------------

/** The receipt verificator. It is recommended to implement your own server-side verification if piracy is a concern. Alternatively, app-side verification is provided in `RMStoreLocalReceiptVerificator`.
 */
@property (nonatomic, weak) id<RMStoreReceiptVerificator> receiptVerificator;

/** The transaction obfuscator. It is recommended to provide your own obfuscator if piracy is a concern. The store will use weak obfuscation via `NSKeyedArchiver` by default.
 */
@property (nonatomic, weak) id<RMStoreTransactionObfuscator> transactionObfuscator;

#pragma mark Product management
///---------------------------------------------
/// @name Managing Products
///---------------------------------------------

- (SKProduct*)productForIdentifier:(NSString*)productIdentifier;

+ (NSString*)localizedPriceOfProduct:(SKProduct*)product;

#pragma mark Purchase management
///---------------------------------------------
/// @name Managing Purchases
///---------------------------------------------

- (void)addPurchaseForProductIdentifier:(NSString*)productIdentifier;

- (void)clearPurchases;

- (BOOL)consumeProductForIdentifier:(NSString*)productIdentifier;

- (NSInteger)countPurchasesForIdentifier:(NSString*)productIdentifier;

- (BOOL)isPurchasedForIdentifier:(NSString*)productIdentifier;

- (NSArray*)purchasedProductIdentifiers;

- (NSArray*)transactionsForProductIdentifier:(NSString*)productIdentifier;

#pragma mark Notifications
///---------------------------------------------
/// @name Managing Observers
///---------------------------------------------

/** Adds an observer to the store.
 Unlike `SKPaymentQueue`, it is not necessary to set an observer.
 @param observer The observer to add.
 */
- (void)addStoreObserver:(id<RMStoreObserver>)observer;

/** Removes an observer from the store.
 @param observer The observer to remove.
 */
- (void)removeStoreObserver:(id<RMStoreObserver>)observer;

@end

@interface RMStoreTransaction : NSObject<NSCoding>

@property(nonatomic, assign) BOOL consumed;
@property(nonatomic, copy) NSString *productIdentifier;
@property(nonatomic, copy) NSDate *transactionDate;
@property(nonatomic, copy) NSString *transactionIdentifier;
@property(nonatomic, strong) NSData *transactionReceipt;

@end

@protocol RMStoreTransactionObfuscator<NSObject>

- (NSData*)dataWithTransaction:(RMStoreTransaction*)transaction;
- (RMStoreTransaction*)transactionWithData:(NSData*)data;

@end

@protocol RMStoreReceiptVerificator <NSObject>

- (void)verifyReceiptOfTransaction:(SKPaymentTransaction*)transaction
                           success:(void (^)())successBlock
                           failure:(void (^)(NSError *error))failureBlock;

@end

@protocol RMStoreObserver<NSObject>
@optional

- (void)storePaymentTransactionFailed:(NSNotification*)notification;
- (void)storePaymentTransactionFinished:(NSNotification*)notification;
- (void)storeProductsRequestFailed:(NSNotification*)notification;
- (void)storeProductsRequestFinished:(NSNotification*)notification;
- (void)storeRestoreTransactionsFailed:(NSNotification*)notification;
- (void)storeRestoreTransactionsFinished:(NSNotification*)notification;

@end

/**
 Category on NSNotification to recover store data from userInfo without requiring to know the keys.
 */
@interface NSNotification(RMStore)

/** Array of product identifiers that were not recognized by the App Store. Used in `storeProductsRequestFinished:`.
 */
@property (nonatomic, readonly) NSArray *invalidProductIdentifiers;

/** Used in `storePaymentTransactionFinished` and `storePaymentTransactionFailed`.
 */
@property (nonatomic, readonly) NSString *productIdentifier;

/** Array of SKProducts, one product for each valid product identifier provided in the corresponding request. Used in `storeProductsRequestFinished:`.
 */
@property (nonatomic, readonly) NSArray *products;

/** Used in `storePaymentTransactionFailed`, `storeProductsRequestFailed` and `storeRestoreTransactionsFailed`.
 */
@property (nonatomic, readonly) NSError *storeError;

/** Used in `storePaymentTransactionFinished` and in `storePaymentTransactionFailed`.
 */
@property (nonatomic, readonly) SKPaymentTransaction *transaction;

@end
