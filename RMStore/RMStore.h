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

@protocol RMStoreTransactionPersistor<NSObject>
    
- (void)persistTransaction:(SKPaymentTransaction*)transaction;
    
/** Remove all persisted transactions from the keychain.
*/
- (void)removeTransactions;
    
/** Consume the given product if available. Intended for consumable products.
@param productIdentifier Identifier of the product to be consumed.
@return YES if the product was consumed, NO otherwise.
*/
- (BOOL)consumeProductOfIdentifier:(NSString*)productIdentifier;
    
/** Returns the number of persisted transactions for the given product that have not been consumed. Intended for consumable products.
@param productIdentifier Identifier of the product to be counted.
@return The number of persisted transactions for the given product that have not been consumed.
*/
- (NSInteger)countProductOfdentifier:(NSString*)productIdentifier;
    
/**
Indicates wheter the given product has been purchased. Intended for non-consumables.
@param productIdentifier Identifier of the product.
@return YES if there is at least one transaction for the given product, NO otherwise. Note that if the product is consumable this method will still return YES even if all transactions have been consumed.
*/
- (BOOL)isPurchasedProductOfIdentifier:(NSString*)productIdentifier;
    
/** Returns the product identifiers of all products whose transactions have been persisted.
*/
- (NSSet*)purchasedProductIdentifiers;

    
@end

@protocol RMStoreReceiptVerificator <NSObject>
    
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

@protocol RMStoreReceiptVerificator;
@protocol RMStoreTransactionPersistor;
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
@property (nonatomic, strong) id<RMStoreReceiptVerificator> receiptVerificator;

/** The transaction persistor. It is recommended to provide your own obfuscator if piracy is a concern. The store will use weak obfuscation via `NSKeyedArchiver` by default.
 */
@property (nonatomic, strong) id<RMStoreTransactionPersistor> transactionPersistor;

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
