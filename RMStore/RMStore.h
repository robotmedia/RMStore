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
@protocol RMStoreTransactionPersistor;
@protocol RMStoreObserver;

extern NSTimeInterval const RMStoreWatchdogMinimalAllowedTimeout;

extern NSString *const RMStoreErrorDomain;
extern NSInteger const RMStoreErrorCodeUnknownProductIdentifier;
extern NSInteger const RMStoreErrorCodeUnableToCompleteVerification;
extern NSInteger const RMStoreErrorCodeWatchdogTimerFired;

@class RMStore;

/** Provides watchdog timer functionality to StoreKit response handling classes.
 */
@interface RMStoreWatchdoggedObject : NSObject

/** Schedules watchdog timer. You must send this message manually to self when activity of watched subclass is started.
 @param store Store object that keeps instance of this class to check for useRequestProductsWatchdogTimer property against. Must not be nil.
 You must overload - (void)watchdogTimerFiredAction method in subclass and force error response there. Use [RMStoreWatchdoggedObject watchdogTimeoutError] object to pass with forced error response.
 @param timeout Timers timeout. Can't be lower then RMStoreWatchdogMinimalAllowedTimeout.
 @see useWatchdogTimers
 @see [RMStoreWatchdoggedObject watchdogTimeoutError]
 */
- (void)activateWatchdogTimerWithStore:(RMStore __weak *)store timeout:(NSTimeInterval)timeout;

/** Resets watchdog timer and processes the block if timer wasn't fired or if timer is not used by store. Good for processing response and continue StoreKit stuff. Remember to call [- disableWatchdogTimerAndComplete:] after all responses will be received.
 @param block Block to process response.
 @see disableWatchdogTimerAndComplete
 */
- (void)ifNotWatchdogTimerIsFiredResetItAndRun:(void (^)())block;

/** Resets watchdog timer.
 */
- (void)resetWatchdogTimer;

/** Disables watchdog timer and complete processing of responses in block. Afterwards watchdog timer can't be reactivated on called instance of this class.
 @param completion Block that will complete processing of responses. If timer was fired previously then block will not be executed, but will always be from within - (void)watchdogTimerFiredAction.
 Do this after all responses are came or on error reponse.
 */
- (void)disableWatchdogTimerAndComplete:(void (^)())completion;

/** Generates timeout error object that will be passed to error routines when timeout occurs.
 */
+ (NSError *)watchdogTimeoutError;

@end


/** A StoreKit wrapper that adds blocks and notifications, plus optional receipt verification and purchase management.
 */
@interface RMStore : NSObject<SKPaymentTransactionObserver>

///---------------------------------------------
/// @name Getting the Store
///---------------------------------------------

/** Returns the singleton store instance.
 */
+ (RMStore*)defaultStore;

#pragma mark Watchdog timer
///---------------------------------------------
/// @name Configuring watchdog timer for products information requests
///---------------------------------------------

/** If useRequestProductsWatchdogTimer is set to YES then watchdog timer will be scheduled for product requests. Watchdog timer allows to ask customer to retry purchase if no response has come from Store Kit in fixed time. By default is set to NO. Setting this property aeffects only consequence requests.
 Store Kit throws it's own error in case of network lag but it may appear after a long time > 13 sec. that is frustrating. Watchdog timer sets an upper bound on this.
 Watchdog timer fires if no response was in requestProductTimeout seconds. When Watchdog timer fires it intercepts control, cancels product request that it belongs to, then runs failure block if it's set and posts failure notification both with RMStoreErrorCodeWatchdogTimerFired error. If Store Kit error comes first then watchdog timer turns off automatically.
 @see requestProductTimeout
 */
@property (nonatomic, assign) BOOL useRequestProductsWatchdogTimer;

/** Watchdog timeout for every product request. By default is 10 seconds. Cant be lower then RMStoreWatchdogMinimalAllowedTimeout constant. Setting this property affects only consequence requests.
 */
@property (nonatomic, assign) NSTimeInterval requestProductTimeout;

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

/** Request payment of the product with the given product identifier. `successBlock` will be called if the payment is successful, `failureBlock` if it isn't.
 @param productIdentifier The identifier of the product whose payment will be requested.
 @param userIdentifier An opaque identifier of the user’s account, if applicable. Can be `nil`.
 @param successBlock The block to be called if the payment is sucessful. Can be `nil`.
 @param failureBlock The block to be called if the payment fails or there isn't any product with the given identifier. Can be `nil`.
 @see [SKPayment applicationUsername]
 */
- (void)addPayment:(NSString*)productIdentifier
              user:(NSString*)userIdentifier
           success:(void (^)(SKPaymentTransaction *transaction))successBlock
           failure:(void (^)(SKPaymentTransaction *transaction, NSError *error))failureBlock __attribute__((availability(ios,introduced=7.0)));

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


/** Request to restore previously completed purchases of a certain user. `successBlock` will be called if the restore transactions request is successful, `failureBlock` if it isn't.
 @param userIdentifier An opaque identifier of the user’s account.
 @param successBlock The block to be called if the restore transactions request is sucessful. Can be `nil`.
 @param failureBlock The block to be called if the restore transactions request fails. Can be `nil`.
 */
- (void)restoreTransactionsOfUser:(NSString*)userIdentifier
                        onSuccess:(void (^)())successBlock
                          failure:(void (^)(NSError *error))failureBlock __attribute__((availability(ios,introduced=7.0)));

#pragma mark Receipt
///---------------------------------------------
/// @name Getting the receipt
///---------------------------------------------

/** Returns the url of the bundle’s App Store receipt, or nil if the receipt is missing.
 If this method returns `nil` you should refresh the receipt by calling `refreshReceipt`.
 @see refreshReceipt
*/
+ (NSURL*)receiptURL __attribute__((availability(ios,introduced=7.0)));

/** Request to refresh the App Store receipt in case the receipt is invalid or missing.
 */
- (void)refreshReceipt __attribute__((availability(ios,introduced=7.0)));

/** Request to refresh the App Store receipt in case the receipt is invalid or missing. `successBlock` will be called if the refresh receipt request is successful, `failureBlock` if it isn't.
 @param successBlock The block to be called if the refresh receipt request is sucessful. Can be `nil`.
 @param failureBlock The block to be called if the refresh receipt request fails. Can be `nil`.
 */
- (void)refreshReceiptOnSuccess:(void (^)())successBlock
                        failure:(void (^)(NSError *error))failureBlock __attribute__((availability(ios,introduced=7.0)));

///---------------------------------------------
/// @name Setting Delegates
///---------------------------------------------

/** The receipt verificator. You can provide your own or use one of the reference implementations provided by the library.
 @see RMStoreAppReceiptVerificator
 @see RMStoreTransactionReceiptVerificator
 */
@property (nonatomic, weak) id<RMStoreReceiptVerificator> receiptVerificator;

/** The transaction persistor. It is recommended to provide your own obfuscator if piracy is a concern. The store will use weak obfuscation via `NSKeyedArchiver` by default.
 */
@property (nonatomic, weak) id<RMStoreTransactionPersistor> transactionPersistor;

#pragma mark Product management
///---------------------------------------------
/// @name Managing Products
///---------------------------------------------

- (SKProduct*)productForIdentifier:(NSString*)productIdentifier;

+ (NSString*)localizedPriceOfProduct:(SKProduct*)product;

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

@protocol RMStoreTransactionPersistor<NSObject>

- (void)persistTransaction:(SKPaymentTransaction*)transaction;

@end

@protocol RMStoreReceiptVerificator <NSObject>

/** Verifies the given transaction and calls the given success or failure block accordingly.
 @param transaction The transaction to be verified.
 @param successBlock Called if the transaction passed verification.
 @param failureBlock Called if the transaction failed verification. If verification could not be completed (e.g., due to connection issues), then error must be of code RMStoreErrorCodeUnableToCompleteVerification to prevent RMStore to finish the transaction.
 */
- (void)verifyTransaction:(SKPaymentTransaction*)transaction
                           success:(void (^)())successBlock
                           failure:(void (^)(NSError *error))failureBlock;

@end

@protocol RMStoreObserver<NSObject>
@optional

- (void)storePaymentTransactionFailed:(NSNotification*)notification;
- (void)storePaymentTransactionFinished:(NSNotification*)notification;
- (void)storeProductsRequestFailed:(NSNotification*)notification;
- (void)storeProductsRequestFinished:(NSNotification*)notification;
- (void)storeRefreshReceiptFailed:(NSNotification*)notification __attribute__((availability(ios,introduced=7.0)));
- (void)storeRefreshReceiptFinished:(NSNotification*)notification __attribute__((availability(ios,introduced=7.0)));
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

/** Used in `storePaymentTransactionFailed`, `storeProductsRequestFailed`, `storeRefreshReceiptFailed` and `storeRestoreTransactionsFailed`.
 */
@property (nonatomic, readonly) NSError *storeError;

/** Used in `storePaymentTransactionFinished` and in `storePaymentTransactionFailed`.
 */
@property (nonatomic, readonly) SKPaymentTransaction *transaction;

@end
