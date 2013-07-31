//
//  RMStore.h
//  RMStore
//
//  Created by Hermes Pique on 12/6/09.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import "RMStore.h"

NSString* const RMSKProductsRequestFailed = @"RMSKProductsRequestFailed";
NSString* const RMSKProductsRequestFinished = @"RMSKProductsRequestFinished";
NSString* const RMSKPaymentTransactionFailed = @"RMSKPaymentTransactionFailed";
NSString* const RMSKPaymentTransactionFinished = @"RMSKPaymentTransactionFinished";
NSString* const RMSKRestoreTransactionsFailed = @"RMSKRestoreTransactionsFailed";
NSString* const RMSKRestoreTransactionsFinished = @"RMSKRestoreTransactionsFinished";

NSString* const RMStoreNotificationProductIdentifier = @"productIdentifier";
NSString* const RMStoreNotificationStoreError = @"storeError";
NSString* const RMStoreNotificationTransaction = @"transaction";

NSString* const RMStoreUserDefaultsKey = @"purchases";

#define RMStoreLog(...) if (DEBUG) { NSLog(@"RMStore: %@", [NSString stringWithFormat:__VA_ARGS__]); }

@implementation NSNotification(RMStore)

- (NSString*) productIdentifier
{
    return [self.userInfo objectForKey:RMStoreNotificationProductIdentifier];
}

- (NSError*) storeError
{
    return [self.userInfo objectForKey:RMStoreNotificationStoreError];
}

- (SKPaymentTransaction*) transaction
{
    return [self.userInfo objectForKey:RMStoreNotificationTransaction];
}

@end

@interface RMProductsRequestWrapper : NSObject

@property (nonatomic, strong) SKProductsRequest *request;
@property (nonatomic, strong) void (^successBlock)();
@property (nonatomic, strong) void (^failureBlock)(NSError* error);

@end

@implementation RMProductsRequestWrapper

@end

@interface RMAddPaymentParameters : NSObject

@property (nonatomic, strong) void (^successBlock)(SKPaymentTransaction *transaction);
@property (nonatomic, strong) void (^failureBlock)(SKPaymentTransaction *transaction, NSError *error);

@end

@implementation RMAddPaymentParameters

@end

@implementation RMStore {
    NSMutableDictionary *_addPaymentParameters; // HACK: We use a dictionary of product identifiers because the returned SKPayment is different from the one we add to the queue. Bad Apple.
    NSMutableDictionary *_products;
    NSMutableArray *_productRequests;
    
    void (^_restoreTransactionssuccessBlock)();
    void (^_restoreTransactionsFailureBlock)(NSError* error);
}

- (id) init
{
    if (self = [super init])
    {
        _addPaymentParameters = [NSMutableDictionary dictionary];
        _products = [NSMutableDictionary dictionary];
        _productRequests = [NSMutableArray array];
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

#pragma mark - Observers

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

#pragma mark - StoreKit wrapper

+ (BOOL)canMakePayments
{
    return [SKPaymentQueue canMakePayments];
}

- (void)addPayment:(NSString*)productIdentifier
{
    [self addPayment:productIdentifier success:nil failure:nil];
}

- (void)addPayment:(NSString*)productIdentifier
           success:(void (^)(SKPaymentTransaction *transaction))successBlock
           failure:(void (^)(SKPaymentTransaction *transaction, NSError *error))failureBlock
{
    SKProduct *product = [self productForIdentifier:productIdentifier];
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
                success:(void (^)())successBlock
                failure:(void (^)(NSError* error))failureBlock
{
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:identifiers];
	productsRequest.delegate = self;

    RMProductsRequestWrapper *requestWrapper = [[RMProductsRequestWrapper alloc] init];
    requestWrapper.request = productsRequest;
    requestWrapper.successBlock = successBlock;
    requestWrapper.failureBlock = failureBlock;
    [_productRequests addObject:requestWrapper];
    
    [productsRequest start];
}

- (void)restoreTransactions
{
    [self restoreTransactionsOnSuccess:nil failure:nil];
}

- (void)restoreTransactionsOnSuccess:(void (^)())successBlock
                             failure:(void (^)(NSError *error))failureBlock
{
    _restoreTransactionssuccessBlock = successBlock;
    _restoreTransactionsFailureBlock = failureBlock;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark - Purchase management

- (void)addPurchaseForIdentifier:(NSString*)productIdentifier
{
    [self increasePurchaseCount:1 product:productIdentifier];
}

- (void)clearPurchases
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:RMStoreUserDefaultsKey];
    [defaults synchronize];
}

- (BOOL)consumeProductForIdentifier:(NSString*)productIdentifier
{
    if (![self isPurchasedForIdentifier:productIdentifier]) return NO;
    [self increasePurchaseCount:-1 product:productIdentifier];
    return YES;
}

- (NSInteger)countPurchasesForIdentifier:(NSString*)productIdentifier
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *purchases = [defaults objectForKey:RMStoreUserDefaultsKey];
    NSNumber *number = [purchases objectForKey:productIdentifier];
    return number ? number.integerValue : 0;
}

- (BOOL)isPurchasedForIdentifier:(NSString*)productIdentifier
{
    return [self countPurchasesForIdentifier:productIdentifier] > 0;
}

- (SKProduct*)productForIdentifier:(NSString*)productIdentifier
{
    return [_products objectForKey:productIdentifier];
}

- (NSArray*)purchasedIdentifiers
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *purchases = [defaults objectForKey:RMStoreUserDefaultsKey];
    return [purchases allKeys];
}

// Private

- (void)increasePurchaseCount:(NSInteger)delta product:(NSString*)productIdentifier
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *previousPurchases = [defaults objectForKey:RMStoreUserDefaultsKey];
    if (!previousPurchases)
    {
        previousPurchases = [NSDictionary dictionary];
    }
    NSMutableDictionary *purchases = [NSMutableDictionary dictionaryWithDictionary:previousPurchases];
    NSNumber *count = [purchases objectForKey:productIdentifier];
    if (count == nil)
    {
        count = @0;
    }
    count = @(count.integerValue + delta);
    [purchases setObject:count forKey:productIdentifier];
    [defaults setObject:purchases forKey:RMStoreUserDefaultsKey];
    [defaults synchronize];
}

#pragma mark - Utils

+ (NSString*)localizedPriceOfProduct:(SKProduct*)product
{
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
	numberFormatter.locale = product.priceLocale;
	NSString *formattedString = [numberFormatter stringFromNumber:product.price];
	return formattedString;
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    RMStoreLog(@"products request received response");
    for (SKProduct *product in response.products)
    {
        RMStoreLog(@"received product with id %@", product.productIdentifier);
        [_products setObject:product forKey:product.productIdentifier];
    }
    
    for (NSString *invalid in response.invalidProductIdentifiers)
    {
        RMStoreLog(@"invalid product with id %@", invalid);
    }

    RMProductsRequestWrapper *wrapper = [self popWrapperForRequest:request];
    if (wrapper.successBlock)
    {
        wrapper.successBlock();
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKProductsRequestFinished object:self];
}

- (void)requestDidFinish:(SKRequest *)request
{
    [self popWrapperForRequest:request]; // Can't hurt
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    RMProductsRequestWrapper *wrapper = [self popWrapperForRequest:request];
    RMStoreLog(@"products request failed with error %@", error.debugDescription);
    if (wrapper.failureBlock)
    {
        wrapper.failureBlock(error);
    }
    NSDictionary *userInfo = @{RMStoreNotificationStoreError: error};
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKProductsRequestFailed object:self userInfo:userInfo];
}

- (RMProductsRequestWrapper*)popWrapperForRequest:(SKRequest*)request
{
    NSArray *wrappers = [NSArray arrayWithArray:_productRequests];
    for (RMProductsRequestWrapper *wrapper in wrappers)
    {
        if (wrapper.request == request)
        {
            [_productRequests removeObject:wrapper];
            return wrapper;
        }
    }
    return nil;
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    RMStoreLog(@"restore transactions finished");
    if (_restoreTransactionssuccessBlock != nil)
    {
        _restoreTransactionssuccessBlock();
        _restoreTransactionssuccessBlock = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKRestoreTransactionsFinished object:self];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    RMStoreLog(@"restored transactions failed with error %@", error.debugDescription);
    if (_restoreTransactionsFailureBlock != nil)
    {
        _restoreTransactionsFailureBlock(error);
        _restoreTransactionsFailureBlock = nil;
    }
    NSDictionary *userInfo = @{RMStoreNotificationStoreError: error};
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKRestoreTransactionsFailed object:self userInfo:userInfo];
}

// Private

- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    SKPayment *payment = transaction.payment;
	NSString* productIdentifier = payment.productIdentifier;
    RMStoreLog(@"transaction purchased with product %@", productIdentifier);
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    [self addPurchaseForIdentifier:productIdentifier];
    
    RMAddPaymentParameters *wrapper = [self popAddPaymentParametersForIdentifier:productIdentifier];
    if (wrapper.successBlock != nil)
    {
        wrapper.successBlock(transaction);
    }
    
    NSDictionary *userInfo = @{RMStoreNotificationTransaction: transaction, RMStoreNotificationProductIdentifier: productIdentifier};
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKPaymentTransactionFinished object:self userInfo:userInfo];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    SKPayment *payment = transaction.payment;
	NSString* productIdentifier = payment.productIdentifier;
    NSError *error = transaction.error;
    RMStoreLog(@"transaction failed with product %@ and error %@", productIdentifier, error.debugDescription);
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

    RMAddPaymentParameters *parameters = [self popAddPaymentParametersForIdentifier:productIdentifier];
    if (parameters.failureBlock != nil)
    {
        parameters.failureBlock(transaction, error);
    }
    
    NSDictionary *userInfo = @{RMStoreNotificationTransaction: transaction, RMStoreNotificationProductIdentifier : productIdentifier, RMStoreNotificationStoreError: error};
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKPaymentTransactionFailed object:self userInfo:userInfo];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    SKPaymentTransaction *originalTransaction = transaction.originalTransaction;
    SKPayment *payment = originalTransaction.payment;
	NSString *productIdentifier = payment.productIdentifier;
    RMStoreLog(@"transaction purchased with product %@", productIdentifier);
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    [self addPurchaseForIdentifier:productIdentifier];
    
    NSDictionary *userInfo = @{RMStoreNotificationTransaction: transaction, RMStoreNotificationProductIdentifier : productIdentifier};
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKPaymentTransactionFinished object:self userInfo:userInfo];
}

- (RMAddPaymentParameters*)popAddPaymentParametersForIdentifier:(NSString*)identifier
{
    RMAddPaymentParameters *parameters = [_addPaymentParameters objectForKey:identifier];
    [_addPaymentParameters removeObjectForKey:identifier];
    return parameters;
}

@end
