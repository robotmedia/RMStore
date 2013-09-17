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

#import "RMStore.h"

NSString *const RMStoreErrorDomain = @"net.robotmedia.store";
NSInteger const RMStoreErrorCodeUnknownProductIdentifier = 100;

NSString* const RMSKPaymentTransactionFailed = @"RMSKPaymentTransactionFailed";
NSString* const RMSKPaymentTransactionFinished = @"RMSKPaymentTransactionFinished";
NSString* const RMSKProductsRequestFailed = @"RMSKProductsRequestFailed";
NSString* const RMSKProductsRequestFinished = @"RMSKProductsRequestFinished";
NSString* const RMSKRestoreTransactionsFailed = @"RMSKRestoreTransactionsFailed";
NSString* const RMSKRestoreTransactionsFinished = @"RMSKRestoreTransactionsFinished";

NSString* const RMStoreNotificationInvalidProductIdentifiers = @"invalidProductIdentifiers";
NSString* const RMStoreNotificationProductIdentifier = @"productIdentifier";
NSString* const RMStoreNotificationProducts = @"products";
NSString* const RMStoreNotificationStoreError = @"storeError";
NSString* const RMStoreNotificationTransaction = @"transaction";

NSString* const RMStoreUserDefaultsKey = @"purchases";

NSString* const RMStoreCoderConsumedKey = @"consumed";
NSString* const RMStoreCoderProductIdentifierKey = @"productIdentifier";
NSString* const RMStoreCoderTransactionDateKey = @"transactionDate";
NSString* const RMStoreCoderTransactionIdentifierKey = @"transactionIdentifier";
NSString* const RMStoreCoderTransactionReceiptKey = @"transactionReceipt";

#ifdef DEBUG
#define RMStoreLog(...) NSLog(@"RMStore: %@", [NSString stringWithFormat:__VA_ARGS__]);
#else
#define RMStoreLog(...)
#endif

typedef void (^RMSKPaymentTransactionFailureBlock)(SKPaymentTransaction *transaction, NSError *error);
typedef void (^RMSKPaymentTransactionSuccessBlock)(SKPaymentTransaction *transaction);
typedef void (^RMSKProductsRequestFailureBlock)(NSError *error);
typedef void (^RMSKProductsRequestSuccessBlock)(NSArray *products, NSArray *invalidIdentifiers);
typedef void (^RMSKRestoreTransactionsFailureBlock)(NSError *error);
typedef void (^RMSKRestoreTransactionsSuccessBlock)();

@implementation RMStoreTransaction

- (id)initWithPaymentTransaction:(SKPaymentTransaction*)paymentTransaction
{
    if (self = [super init])
    {
        _productIdentifier = paymentTransaction.payment.productIdentifier;
        _transactionDate = paymentTransaction.transactionDate;
        _transactionIdentifier = paymentTransaction.transactionIdentifier;
        _transactionReceipt = paymentTransaction.transactionReceipt;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init])
    {
        _consumed = [decoder decodeBoolForKey:RMStoreCoderConsumedKey];
        _productIdentifier = [decoder decodeObjectForKey:RMStoreCoderProductIdentifierKey];
        _transactionDate = [decoder decodeObjectForKey:RMStoreCoderTransactionDateKey];
        _transactionIdentifier = [decoder decodeObjectForKey:RMStoreCoderTransactionIdentifierKey];
        _transactionReceipt = [decoder decodeObjectForKey:RMStoreCoderTransactionReceiptKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeBool:self.consumed forKey:RMStoreCoderConsumedKey];
    [coder encodeObject:self.productIdentifier forKey:RMStoreCoderProductIdentifierKey];
    [coder encodeObject:self.transactionDate forKey:RMStoreCoderTransactionDateKey];
    if (self.transactionIdentifier != nil) { [coder encodeObject:self.transactionIdentifier forKey:RMStoreCoderTransactionIdentifierKey]; }
    if (self.transactionReceipt != nil) { [coder encodeObject:self.transactionReceipt forKey:RMStoreCoderTransactionReceiptKey]; }
}

@end

@interface RMStoreDefaultTransactionObfuscator : NSObject<RMStoreTransactionObfuscator>
@end

@implementation RMStoreDefaultTransactionObfuscator

- (NSData*)dataWithTransaction:(RMStoreTransaction*)transaction
{
    RMStoreLog(@"WARNING: using default weak obfuscation. Provide your own obfuscator if piracy is a concern.");
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:transaction];
    [archiver finishEncoding];
    return data;
}

- (RMStoreTransaction*)transactionWithData:(NSData*)data
{
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    RMStoreTransaction *transaction = [unarchiver decodeObject];
    [unarchiver finishDecoding];
    return transaction;
}

@end

@implementation NSNotification(RMStore)

- (NSArray*)invalidProductIdentifiers
{
    return [self.userInfo objectForKey:RMStoreNotificationInvalidProductIdentifiers];
}

- (NSString*)productIdentifier
{
    return [self.userInfo objectForKey:RMStoreNotificationProductIdentifier];
}

- (NSArray*)products
{
    return [self.userInfo objectForKey:RMStoreNotificationProducts];
}

- (NSError*)storeError
{
    return [self.userInfo objectForKey:RMStoreNotificationStoreError];
}

- (SKPaymentTransaction*)transaction
{
    return [self.userInfo objectForKey:RMStoreNotificationTransaction];
}

@end

@interface RMProductsRequestDelegate : NSObject<SKProductsRequestDelegate>

@property (nonatomic, strong) RMSKProductsRequestSuccessBlock successBlock;
@property (nonatomic, strong) RMSKProductsRequestFailureBlock failureBlock;
@property (nonatomic, weak) RMStore *store;

@end

@interface RMAddPaymentParameters : NSObject

@property (nonatomic, strong) RMSKPaymentTransactionSuccessBlock successBlock;
@property (nonatomic, strong) RMSKPaymentTransactionFailureBlock failureBlock;

@end

@implementation RMAddPaymentParameters

@end

@implementation RMStore {
    NSMutableDictionary *_addPaymentParameters; // HACK: We use a dictionary of product identifiers because the returned SKPayment is different from the one we add to the queue. Bad Apple.
    NSMutableDictionary *_products;
    NSMutableSet *_productsRequestDelegates;
    RMStoreDefaultTransactionObfuscator *_defaultTransactionObfuscator;
    
    NSInteger _pendingRestoredTransactionsCount;
    BOOL _restoredCompletedTransactionsFinished;
    void (^_restoreTransactionsSuccessBlock)();
    void (^_restoreTransactionsFailureBlock)(NSError* error);
}

- (id) init
{
    if (self = [super init])
    {
        _addPaymentParameters = [NSMutableDictionary dictionary];
        _products = [NSMutableDictionary dictionary];
        _productsRequestDelegates = [NSMutableSet set];
        _defaultTransactionObfuscator = [[RMStoreDefaultTransactionObfuscator alloc] init];
        _transactionObfuscator = _defaultTransactionObfuscator;
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

+ (RMStore *)defaultStore
{
    static RMStore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

#pragma mark StoreKit wrapper

+ (BOOL)canMakePayments
{
    return [SKPaymentQueue canMakePayments];
}

- (void)addPayment:(NSString*)productIdentifier
{
    [self addPayment:productIdentifier success:nil failure:nil];
}

- (void)addPayment:(NSString*)productIdentifier
           success:(RMSKPaymentTransactionSuccessBlock)successBlock
           failure:(RMSKPaymentTransactionFailureBlock)failureBlock
{
    SKProduct *product = [self productForIdentifier:productIdentifier];
    if (product == nil)
    {
        RMStoreLog(@"unknown product id %@", productIdentifier)
        if (failureBlock != nil)
        {
            NSError *error = [NSError errorWithDomain:RMStoreErrorDomain code:RMStoreErrorCodeUnknownProductIdentifier userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unknown product identifier", "Error description")}];
            failureBlock(nil, error);
        }
        return;
    }
    SKPayment *payment = [SKPayment paymentWithProduct:product];
      
    RMAddPaymentParameters *parameters = [[RMAddPaymentParameters alloc] init];
    parameters.successBlock = successBlock;
    parameters.failureBlock = failureBlock;
    [_addPaymentParameters setObject:parameters forKey:productIdentifier];
    
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)requestProducts:(NSSet*)identifiers
{
    [self requestProducts:identifiers success:nil failure:nil];
}

- (void)requestProducts:(NSSet*)identifiers
                success:(RMSKProductsRequestSuccessBlock)successBlock
                failure:(RMSKProductsRequestFailureBlock)failureBlock
{
    RMProductsRequestDelegate *delegate = [[RMProductsRequestDelegate alloc] init];
    delegate.store = self;
    delegate.successBlock = successBlock;
    delegate.failureBlock = failureBlock;
    [_productsRequestDelegates addObject:delegate];
 
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:identifiers];
	productsRequest.delegate = delegate;
    
    [productsRequest start];
}

- (void)restoreTransactions
{
    [self restoreTransactionsOnSuccess:nil failure:nil];
}

- (void)restoreTransactionsOnSuccess:(RMSKRestoreTransactionsSuccessBlock)successBlock
                             failure:(RMSKRestoreTransactionsFailureBlock)failureBlock
{
    _pendingRestoredTransactionsCount = 0;
    _restoreTransactionsSuccessBlock = successBlock;
    _restoreTransactionsFailureBlock = failureBlock;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark Product management

- (SKProduct*)productForIdentifier:(NSString*)productIdentifier
{
    return [_products objectForKey:productIdentifier];
}

+ (NSString*)localizedPriceOfProduct:(SKProduct*)product
{
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
	numberFormatter.locale = product.priceLocale;
	NSString *formattedString = [numberFormatter stringFromNumber:product.price];
	return formattedString;
}

#pragma mark Purchase management

- (void)addPurchaseForProductIdentifier:(NSString*)productIdentifier
{
    [self addPurchaseForProductIdentifier:productIdentifier paymentTransaction:nil];
}

- (void)clearPurchases
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:RMStoreUserDefaultsKey];
    [defaults synchronize];
}

- (BOOL)consumeProductForIdentifier:(NSString*)productIdentifier
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *purchases = [defaults objectForKey:RMStoreUserDefaultsKey] ? : [NSDictionary dictionary];
    NSArray *transactions = [purchases objectForKey:productIdentifier] ? : @[];
    for (NSData *data in transactions)
    {
        RMStoreTransaction *transaction = [self.transactionObfuscator transactionWithData:data];
        if (!transaction.consumed)
        {
            transaction.consumed = YES;
            NSData *updatedData = [self.transactionObfuscator dataWithTransaction:transaction];
            NSMutableArray *updatedTransactions = [NSMutableArray arrayWithArray:transactions];
            NSInteger index = [updatedTransactions indexOfObject:data];
            [updatedTransactions replaceObjectAtIndex:index withObject:updatedData];
            [self setTransactions:updatedTransactions forProductIdentifier:productIdentifier];
            return YES;
        }
    }
    return NO;
}

- (NSInteger)countPurchasesForIdentifier:(NSString*)productIdentifier
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *purchases = [defaults objectForKey:RMStoreUserDefaultsKey];
    NSArray *transactions = [purchases objectForKey:productIdentifier];
    NSInteger count = 0;
    for (NSData *data in transactions)
    {
        RMStoreTransaction *transaction = [self.transactionObfuscator transactionWithData:data];
        if (!transaction.consumed) { count++; }
    }
    return count;
}

- (BOOL)isPurchasedForIdentifier:(NSString*)productIdentifier
{
    return [self countPurchasesForIdentifier:productIdentifier] > 0;
}

- (NSArray*)purchasedProductIdentifiers
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *purchases = [defaults objectForKey:RMStoreUserDefaultsKey];
    return [purchases allKeys];
}

- (NSArray*)transactionsForProductIdentifier:(NSString*)productIdentifier
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *purchases = [defaults objectForKey:RMStoreUserDefaultsKey];
    NSArray *obfuscatedTransactions = [purchases objectForKey:productIdentifier] ? : @[];
    NSMutableArray *transactions = [NSMutableArray arrayWithCapacity:obfuscatedTransactions.count];
    for (NSData *data in obfuscatedTransactions)
    {
        RMStoreTransaction *transaction = [self.transactionObfuscator transactionWithData:data];
        [transactions addObject:transaction];
    }
    return transactions;
}

// Private

- (void)addPurchaseForProductIdentifier:(NSString*)productIdentifier paymentTransaction:(SKPaymentTransaction*)paymentTransaction
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *purchases = [defaults objectForKey:RMStoreUserDefaultsKey] ? : [NSDictionary dictionary];
    NSArray *transactions = [purchases objectForKey:productIdentifier] ? : @[];
    NSMutableArray *updatedTransactions = [NSMutableArray arrayWithArray:transactions];

    RMStoreTransaction *transaction;
    if (paymentTransaction != nil)
    {
        transaction = [[RMStoreTransaction alloc] initWithPaymentTransaction:paymentTransaction];
    } else {
        transaction = [[RMStoreTransaction alloc] init];
        transaction.productIdentifier = productIdentifier;
        transaction.transactionDate = [NSDate date];
    }
    NSData *data = [self.transactionObfuscator dataWithTransaction:transaction];
    [updatedTransactions addObject:data];
    [self setTransactions:updatedTransactions forProductIdentifier:productIdentifier];
}

- (void)setTransactions:(NSArray*)transactions forProductIdentifier:(NSString*)productIdentifier
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *purchases = [defaults objectForKey:RMStoreUserDefaultsKey] ? : [NSDictionary dictionary];
    NSMutableDictionary *updatedPurchases = [NSMutableDictionary dictionaryWithDictionary:purchases];
    [updatedPurchases setObject:transactions forKey:productIdentifier];
    [defaults setObject:updatedPurchases forKey:RMStoreUserDefaultsKey];
    [defaults synchronize];
}

#pragma mark Observers

- (void)addStoreObserver:(id<RMStoreObserver>)observer
{
    [self addStoreObserver:observer selector:@selector(storeProductsRequestFailed:) notificationName:RMSKProductsRequestFailed];
    [self addStoreObserver:observer selector:@selector(storeProductsRequestFinished:) notificationName:RMSKProductsRequestFinished];
    [self addStoreObserver:observer selector:@selector(storePaymentTransactionFailed:) notificationName:RMSKPaymentTransactionFailed];
    [self addStoreObserver:observer selector:@selector(storePaymentTransactionFinished:) notificationName:RMSKPaymentTransactionFinished];
    [self addStoreObserver:observer selector:@selector(storeRestoreTransactionsFailed:) notificationName:RMSKRestoreTransactionsFailed];
    [self addStoreObserver:observer selector:@selector(storeRestoreTransactionsFinished:) notificationName:RMSKRestoreTransactionsFinished];
}

- (void)removeStoreObserver:(id<RMStoreObserver>)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKProductsRequestFailed object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKProductsRequestFinished object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKPaymentTransactionFailed object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKPaymentTransactionFinished object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKRestoreTransactionsFailed object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKRestoreTransactionsFinished object:self];
}

// Private

- (void)addStoreObserver:(id<RMStoreObserver>)observer selector:(SEL)aSelector notificationName:(NSString*)notificationName
{
    if ([observer respondsToSelector:aSelector])
    {
        [[NSNotificationCenter defaultCenter] addObserver:observer selector:aSelector name:notificationName object:self];
    }
}

#pragma mark SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self paymentQueue:queue completedTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self paymentQueue:queue failedTransaction:transaction error:transaction.error];
                break;
            case SKPaymentTransactionStateRestored:
                [self paymentQueue:queue restoredTransaction:transaction];
            default:
                break;
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    RMStoreLog(@"restore transactions finished");
    _restoredCompletedTransactionsFinished = YES;
    
    [self notifyRestoreTransactionFinishedIfApplicableAfterTransaction:nil];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    RMStoreLog(@"restored transactions failed with error %@", error.debugDescription);
    if (_restoreTransactionsFailureBlock != nil)
    {
        _restoreTransactionsFailureBlock(error);
        _restoreTransactionsFailureBlock = nil;
    }
    NSDictionary *userInfo = nil;
    if (error)
    { // error might be nil (e.g., on airplane mode)
        userInfo = @{RMStoreNotificationStoreError: error};
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKRestoreTransactionsFailed object:self userInfo:userInfo];
}

- (void)paymentQueue:(SKPaymentQueue*)queue completedTransaction:(SKPaymentTransaction *)transaction
{
    RMStoreLog(@"transaction purchased with product %@", transaction.payment.productIdentifier);
    
    if (self.receiptVerificator != nil)
    {
        [self.receiptVerificator verifyReceiptOfTransaction:transaction success:^{
            [self paymentQueue:queue verifiedTransaction:transaction];
        } failure:^(NSError *error) {
            [self paymentQueue:queue failedTransaction:transaction error:error];
        }];
    }
    else
    {
        RMStoreLog(@"WARNING: no receipt verification");
        [self paymentQueue:queue verifiedTransaction:transaction];
    }
}

- (void)paymentQueue:(SKPaymentQueue*)queue verifiedTransaction:(SKPaymentTransaction *)transaction
{
    SKPayment *payment = transaction.payment;
	NSString* productIdentifier = payment.productIdentifier;
    [queue finishTransaction:transaction];
    [self addPurchaseForProductIdentifier:productIdentifier paymentTransaction:transaction];
    
    RMAddPaymentParameters *wrapper = [self popAddPaymentParametersForIdentifier:productIdentifier];
    if (wrapper.successBlock != nil)
    {
        wrapper.successBlock(transaction);
    }
    
    NSDictionary *userInfo = @{RMStoreNotificationTransaction: transaction, RMStoreNotificationProductIdentifier: productIdentifier};
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKPaymentTransactionFinished object:self userInfo:userInfo];
}

- (void)paymentQueue:(SKPaymentQueue *)queue failedTransaction:(SKPaymentTransaction *)transaction error:(NSError*)error
{
    SKPayment *payment = transaction.payment;
	NSString* productIdentifier = payment.productIdentifier;
    RMStoreLog(@"transaction failed with product %@ and error %@", productIdentifier, error.debugDescription);
    
    [queue finishTransaction:transaction];

    RMAddPaymentParameters *parameters = [self popAddPaymentParametersForIdentifier:productIdentifier];
    if (parameters.failureBlock != nil)
    {
        parameters.failureBlock(transaction, error);
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:transaction forKey:RMStoreNotificationTransaction];
    [userInfo setObject:productIdentifier forKey:RMStoreNotificationProductIdentifier];
    if (error)
    {
        [userInfo setObject:error forKey:RMStoreNotificationStoreError];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKPaymentTransactionFailed object:self userInfo:userInfo];
}

- (void)paymentQueue:(SKPaymentQueue*)queue restoredTransaction:(SKPaymentTransaction *)transaction
{
    RMStoreLog(@"transaction restored with product %@", transaction.originalTransaction.payment.productIdentifier);
    
    _pendingRestoredTransactionsCount++;
    if (self.receiptVerificator != nil)
    {
        [self.receiptVerificator verifyReceiptOfTransaction:transaction success:^{
            [self paymentQueue:queue verifiedTransaction:transaction];
            [self notifyRestoreTransactionFinishedIfApplicableAfterTransaction:transaction];
        } failure:^(NSError *error) {
            [self paymentQueue:queue failedTransaction:transaction error:error];
            [self notifyRestoreTransactionFinishedIfApplicableAfterTransaction:transaction];
        }];
    }
    else
    {
        RMStoreLog(@"WARNING: no receipt verification");
        [self paymentQueue:queue verifiedTransaction:transaction];
        [self notifyRestoreTransactionFinishedIfApplicableAfterTransaction:transaction];
    }
}

- (void)notifyRestoreTransactionFinishedIfApplicableAfterTransaction:(SKPaymentTransaction*)transaction
{
    if (transaction != nil && transaction.transactionState == SKPaymentTransactionStateRestored)
    {
        _pendingRestoredTransactionsCount--;
    }
    if (_restoredCompletedTransactionsFinished && _pendingRestoredTransactionsCount == 0)
    { // Wait until all restored transations have been verified
        if (_restoreTransactionsSuccessBlock != nil)
        {
            _restoreTransactionsSuccessBlock();
            _restoreTransactionsSuccessBlock = nil;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:RMSKRestoreTransactionsFinished object:self];
    }
}

- (RMAddPaymentParameters*)popAddPaymentParametersForIdentifier:(NSString*)identifier
{
    RMAddPaymentParameters *parameters = [_addPaymentParameters objectForKey:identifier];
    [_addPaymentParameters removeObjectForKey:identifier];
    return parameters;
}

#pragma mark - Private

- (void)addProduct:(SKProduct*)product
{
    [_products setObject:product forKey:product.productIdentifier];    
}

- (void)removeProductsRequestDelegate:(RMProductsRequestDelegate*)delegate
{
    [_productsRequestDelegates removeObject:delegate];
}

@end

@implementation RMProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    RMStoreLog(@"products request received response");
    NSArray *products = [NSArray arrayWithArray:response.products];
    NSArray *invalidProductIdentifiers = [NSArray arrayWithArray:response.invalidProductIdentifiers];
    
    for (SKProduct *product in products)
    {
        RMStoreLog(@"received product with id %@", product.productIdentifier);
        [self.store addProduct:product];
    }
    
    for (NSString *invalid in invalidProductIdentifiers)
    {
        RMStoreLog(@"invalid product with id %@", invalid);
    }
    
    if (self.successBlock)
    {
        self.successBlock(products, invalidProductIdentifiers);
    }
    NSDictionary *userInfo = @{RMStoreNotificationProducts: products, RMStoreNotificationInvalidProductIdentifiers: invalidProductIdentifiers};
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKProductsRequestFinished object:self userInfo:userInfo];
}

- (void)requestDidFinish:(SKRequest *)request
{
    [self.store removeProductsRequestDelegate:self];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    RMStoreLog(@"products request failed with error %@", error.debugDescription);
    if (self.failureBlock)
    {
        self.failureBlock(error);
    }
    NSDictionary *userInfo = nil;
    if (error)
    { // error might be nil (e.g., on airplane mode)
        userInfo = @{RMStoreNotificationStoreError: error};
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKProductsRequestFailed object:self userInfo:userInfo];
    [self.store removeProductsRequestDelegate:self];
}

@end
