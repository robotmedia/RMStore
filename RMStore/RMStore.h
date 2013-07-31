//
//  RMStore.h
//  RMStore
//
//  Created by Hermes Pique on 12/6/09.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface NSNotification(RMStore)

@property (nonatomic, readonly) NSString *productIdentifier;
@property (nonatomic, readonly) NSError *storeError;
@property (nonatomic, readonly) SKPaymentTransaction *transaction;

@end

@protocol RMStoreObserver;

@interface RMStore : NSObject<SKPaymentTransactionObserver, SKProductsRequestDelegate>

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