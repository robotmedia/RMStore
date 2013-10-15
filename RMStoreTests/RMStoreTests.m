//
//  RMStoreTests.m
//  RMStoreTests
//
//  Created by Hermes Pique on 7/30/13.
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

#import <SenTestingKit/SenTestingKit.h>
#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>
#import <OCMock/OCMock.h>
#import "RMStore.h"

#define IOS7_OR_HIGHER_ONLY if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) return;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles" // To use ST macros in blocks

extern NSString* const RMSKRefreshReceiptFailed;
extern NSString* const RMSKRefreshReceiptFinished;
extern NSString* const RMSKRestoreTransactionsFailed;
extern NSString* const RMSKRestoreTransactionsFinished;

extern NSString* const RMStoreNotificationStoreError;

@interface RMStoreTests : SenTestCase<RMStoreObserver>

@end

@interface RMStoreReceiptVerificatorSuccess : NSObject<RMStoreReceiptVerificator>
@end

@interface RMStoreReceiptVerificatorFailure : NSObject<RMStoreReceiptVerificator>
@end

@interface RMStore(Private)

@property (nonatomic, readonly) NSMutableDictionary *products;

@end

@implementation RMStore(Private)

- (NSMutableDictionary*)products
{
    Ivar productsIvar = class_getInstanceVariable(self.class, "_products");
    return object_getIvar(self, productsIvar);
}

@end

@implementation RMStoreTests {
    RMStore *_store;
}

- (void) setUp
{
    _store = [[RMStore alloc] init];
}

- (void) tearDown
{
    [_store clearPurchases];
}

- (void)testInit
{
    STAssertNotNil(_store, @"");
    STAssertNil(_store.receiptVerificator, @"");
    STAssertNotNil(_store.transactionObfuscator, @"");
}

- (void)testDealloc
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    @autoreleasepool { [[RMStore alloc] init]; }
#pragma clang diagnostic pop
}

- (void)testDefaultStore
{
    RMStore *store1 = [RMStore defaultStore];
    RMStore *store2 = [RMStore defaultStore];
    STAssertEqualObjects(store1, store2, @"");
}

#pragma mark StoreKit Wrapper

- (void)testCanMakePayments
{
    BOOL expected = [SKPaymentQueue canMakePayments];
    BOOL result = [RMStore canMakePayments];
    STAssertEquals(result, expected, @"");
}

- (void)testAddPayment_UnknownProduct
{
    [_store addPayment:@"test"];
}

- (void)testAddPayment_KnownProduct
{
    
    static NSString *productIdentifier = @"test";
    id product = [OCMockObject mockForClass:[SKProduct class]];
    [[[product stub] andReturn:productIdentifier] productIdentifier];
    [_store.products setObject:product forKey:productIdentifier];
    [_store addPayment:productIdentifier];
}

- (void)testAddPayment_UnknownProduct_Nil_Nil
{
    [_store addPayment:@"test" success:nil failure:nil];
}

- (void)testAddPayment_UnknownProduct_Block_Block
{
    __block BOOL failureBlockCalled;
    [_store addPayment:@"test" success:^(SKPaymentTransaction *transaction) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warc-retain-cycles"
        STFail(@"Success block");
#pragma GCC diagnostic pop
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        failureBlockCalled = YES;
        STAssertNil(transaction, @"");
        STAssertEquals(error.code, RMStoreErrorCodeUnknownProductIdentifier, @"");
    }];
    STAssertTrue(failureBlockCalled, @"");
}

- (void)testAddPaymentUser
{ IOS7_OR_HIGHER_ONLY
    [_store addPayment:@"test" user:@"test" success:nil failure:nil];
}

- (void)testRequestProducts_One
{
    [_store requestProducts:[NSSet setWithObject:@"test"]];
}

- (void)testRequestProducts_One_Nil_Nil
{
    [_store requestProducts:[NSSet setWithObject:@"test"] success:nil failure:nil];
}

- (void)testRequestProducts_One_Block_Block
{
    [_store requestProducts:[NSSet setWithObject:@"test"] success:^(NSArray *products, NSArray *invalidProductIdentifiers) {
    } failure:^(NSError *error) {
    }];
}

- (void)testRestoreTransactions
{
    [_store restoreTransactions];
}

- (void)testRestoreTransactions_Nil_Nil
{
    [_store restoreTransactionsOnSuccess:nil failure:nil];
}

- (void)testRestoreTransactions_Block_Block
{
    [_store restoreTransactionsOnSuccess:^{
    } failure:^(NSError *error) {
    }];
}

- (void)testRestoreTransactionsOfUser
{ IOS7_OR_HIGHER_ONLY
    
    [_store restoreTransactionsOfUser:@"test" onSuccess:nil failure:nil];
}

#pragma mark Receipt

- (void)testReceiptURL
{ IOS7_OR_HIGHER_ONLY
    
    NSURL *result = [RMStore receiptURL];
    NSURL *expected = [[NSBundle mainBundle] appStoreReceiptURL];
    STAssertEqualObjects(result, expected, @"");
}

- (void)testRefreshReceipt
{ IOS7_OR_HIGHER_ONLY
    [_store refreshReceipt];
}

- (void)testRefreshReceipt_Nil_Nil
{ IOS7_OR_HIGHER_ONLY
    [_store refreshReceiptOnSuccess:nil failure:nil];
}

- (void)testRefreshReceipt_Block_Block
{ IOS7_OR_HIGHER_ONLY
    [_store refreshReceiptOnSuccess:^{} failure:^(NSError *error) {}];
}

#pragma mark Product management

- (void)testProductForIdentifierNil
{
    SKProduct *product = [_store productForIdentifier:@"test"];
    STAssertNil(product, @"");
}

- (void)testLocalizedPriceOfProduct
{
    id product = [OCMockObject mockForClass:[SKProduct class]];
    NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithString:@"1"];
    [[[product stub] andReturn:price] price];
    NSLocale *locale = [NSLocale currentLocale];
    [[[product stub] andReturn:locale] priceLocale];
    NSString *result = [RMStore localizedPriceOfProduct:product];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
	numberFormatter.locale = locale;
	NSString *expected = [numberFormatter stringFromNumber:price];
    
    STAssertEqualObjects(result, expected, @"");
}

#pragma mark Notifications

- (void)testAddStoreObserver
{
    [_store addStoreObserver:self];
}

- (void)testRemoveStoreObserver
{
    [_store addStoreObserver:self];
    [_store removeStoreObserver:self];
}

#pragma mark Purchase management

- (void)testAddPurchaseForProductIdentifier
{
    STAssertTrue([_store transactionsForProductIdentifier:@"test"].count == 0, @"");

    [_store addPurchaseForProductIdentifier:@"test"];
    
    STAssertTrue([_store isPurchasedForIdentifier:@"test"], @"");
    STAssertEquals([_store countPurchasesForIdentifier:@"test"], 1, @"");
    NSArray *transactions = [_store transactionsForProductIdentifier:@"test"];
    STAssertTrue(transactions.count == 1, @"");
    RMStoreTransaction *transaction = [transactions objectAtIndex:0];
    STAssertEqualObjects(transaction.productIdentifier, @"test", @"");
    STAssertNotNil(transaction.transactionDate, @"");
    STAssertNil(transaction.transactionIdentifier, @"");
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    STAssertNil(transaction.transactionReceipt, @"");
#endif
    STAssertFalse(transaction.consumed, @"");
}

- (void)testClearPurchases
{
    [_store addPurchaseForProductIdentifier:@"test"];
    STAssertTrue([_store isPurchasedForIdentifier:@"test"], @"");
    STAssertTrue([_store transactionsForProductIdentifier:@"test"].count == 1, @"");

    [_store clearPurchases];
    STAssertFalse([_store isPurchasedForIdentifier:@"test"], @"");
    STAssertTrue([_store transactionsForProductIdentifier:@"test"].count == 0, @"");
}

- (void)testConsumeProductForIdentifierYES
{
    [_store addPurchaseForProductIdentifier:@"test"];
    STAssertEquals([_store countPurchasesForIdentifier:@"test"], 1, @"");
    {
        NSArray *transactions = [_store transactionsForProductIdentifier:@"test"];
        RMStoreTransaction *transaction = [transactions objectAtIndex:0];
        STAssertFalse(transaction.consumed, @"");
    }
    
    BOOL result = [_store consumeProductForIdentifier:@"test"];

    STAssertTrue(result, @"");
    STAssertEquals([_store countPurchasesForIdentifier:@"test"], 0, @"");
    {
        NSArray *transactions = [_store transactionsForProductIdentifier:@"test"];
        STAssertTrue(transactions.count == 1, @"");
        RMStoreTransaction *transaction = [transactions objectAtIndex:0];
        STAssertTrue(transaction.consumed, @"");
    }
}

- (void)testConsumeProductForIdentifierNO
{
    STAssertEquals([_store countPurchasesForIdentifier:@"test"], 0, @"");
    
    BOOL result = [_store consumeProductForIdentifier:@"test"];
    STAssertFalse(result, @"");
    STAssertEquals([_store countPurchasesForIdentifier:@"test"], 0, @"");
}

- (void)testCountPurchasesForIdentifierZero
{
    STAssertEquals([_store countPurchasesForIdentifier:@"test"], 0, @"");
}

- (void)testCountPurchasesForIdentifierOne
{
    [_store addPurchaseForProductIdentifier:@"test"];
    STAssertEquals([_store countPurchasesForIdentifier:@"test"], 1, @"");
}

- (void)testCountPurchasesForIdentifierMany
{
    [_store addPurchaseForProductIdentifier:@"test"];
    [_store addPurchaseForProductIdentifier:@"test"];
    [_store addPurchaseForProductIdentifier:@"test"];
    STAssertEquals([_store countPurchasesForIdentifier:@"test"], 3, @"");
}

- (void)isPurchasedForIdentifierYES
{
    [_store addPurchaseForProductIdentifier:@"test"];
    
    BOOL result = [_store isPurchasedForIdentifier:@"test"];
    STAssertTrue(result, @"");
}

- (void)isPurchasedForIdentifierNO
{
    BOOL result = [_store isPurchasedForIdentifier:@"test"];
    STAssertFalse(result, @"");
}

- (void)testPurchasedProductIdentifiersEmpty
{
    NSArray *result = [_store purchasedProductIdentifiers];
    STAssertTrue(result.count == 0, @"");
}

- (void)testPurchasedProductIdentifiersOne
{
    [_store addPurchaseForProductIdentifier:@"test"];
    NSArray *result = [_store purchasedProductIdentifiers];
    STAssertTrue(result.count == 1, @"");
    STAssertEqualObjects([result lastObject], @"test", nil);
}

- (void)testPurchasedProductIdentifiersNoRepeats
{
    [_store addPurchaseForProductIdentifier:@"test"];
    [_store addPurchaseForProductIdentifier:@"test"];
    NSArray *result = [_store purchasedProductIdentifiers];
    STAssertTrue(result.count == 1, @"");
}

- (void)testPurchasedProductIdentifiersMany
{
    [_store addPurchaseForProductIdentifier:@"test1"];
    [_store addPurchaseForProductIdentifier:@"test2"];
    NSArray *result = [_store purchasedProductIdentifiers];
    STAssertTrue(result.count == 2, @"");
}

- (void)testTransactionsForProductIdentifierZero
{
    NSArray *transactions = [_store transactionsForProductIdentifier:@"test"];
    STAssertTrue(transactions.count == 0, @"");
}

- (void)testTransactionsForProductIdentifierOne
{
    [_store addPurchaseForProductIdentifier:@"test"];
    NSArray *transactions = [_store transactionsForProductIdentifier:@"test"];
    STAssertTrue(transactions.count == 1, @"");
}

- (void)testTransactionsForProductIdentifierMany
{
    [_store addPurchaseForProductIdentifier:@"test1"];
    [_store addPurchaseForProductIdentifier:@"test1"];
    [_store addPurchaseForProductIdentifier:@"test1"];
    [_store addPurchaseForProductIdentifier:@"test2"];
    NSArray *transactions = [_store transactionsForProductIdentifier:@"test1"];
    STAssertTrue(transactions.count == 3, @"");
}

#pragma mark SKPaymentTransactionObserver

- (void)testPaymentQueueUpdatedTransactions_Empty
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [_store paymentQueue:queue updatedTransactions:@[]];
}

- (void)testPaymentQueueUpdatedTransactions_Purchased__NoVerificator
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[queue stub] finishTransaction:[OCMArg any]];

    [_store paymentQueue:queue updatedTransactions:@[transaction]];
}

- (void)testPaymentQueueUpdatedTransactions_Purchased__NoVerificator_Blocks
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id originalTransaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[queue stub] finishTransaction:[OCMArg any]];

    id product = [OCMockObject mockForClass:[SKProduct class]];
    [[[product stub] andReturn:@"test"] productIdentifier];
    [_store.products setObject:product forKey:@"test"];
    [_store addPayment:@"test" success:^(SKPaymentTransaction *transaction) {
        STAssertEqualObjects(transaction, originalTransaction, @"");
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        STFail(@"");
    }];
    
    [_store paymentQueue:queue updatedTransactions:@[originalTransaction]];
}

- (void)testPaymentQueueUpdatedTransactions_Purchased__VerificatorSuccess
{
    id verificator = [[RMStoreReceiptVerificatorSuccess alloc] init];
    _store.receiptVerificator = verificator;
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[queue stub] finishTransaction:[OCMArg any]];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
}

- (void)testPaymentQueueUpdatedTransactions_Purchased__VerificatorFailure
{
    id verificator = [[RMStoreReceiptVerificatorFailure alloc] init];
    _store.receiptVerificator = verificator;
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[queue stub] finishTransaction:[OCMArg any]];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
}

- (void)testPaymentQueueUpdatedTransactions_Restored__NoVerificator
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStateRestored];
    id originalTransaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[[transaction stub] andReturn:originalTransaction] originalTransaction];
    [[queue stub] finishTransaction:[OCMArg any]];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
}

- (void)testPaymentQueueUpdatedTransactions_Restored__VerificatorSuccess
{
    id verificator = [[RMStoreReceiptVerificatorSuccess alloc] init];
    _store.receiptVerificator = verificator;
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStateRestored];
    id originalTransaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[[transaction stub] andReturn:originalTransaction] originalTransaction];
    [[queue stub] finishTransaction:[OCMArg any]];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
}

- (void)testPaymentQueueUpdatedTransactions_Restored__VerificatorFailure
{
    id verificator = [[RMStoreReceiptVerificatorFailure alloc] init];
    _store.receiptVerificator = verificator;
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStateRestored];
    id originalTransaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[[transaction stub] andReturn:originalTransaction] originalTransaction];
    [[queue stub] finishTransaction:[OCMArg any]];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
}

- (void)testPaymentQueueUpdatedTransactions_Failed
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStateFailed];
    [[[transaction stub] andReturn:[NSError errorWithDomain:@"test" code:0 userInfo:nil]] error];
    [[queue stub] finishTransaction:[OCMArg any]];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
}

- (void)testPaymentQueueUpdatedTransactions_Failed__Blocks
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id originalTransaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStateFailed];
    NSError *originalError = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    [[[originalTransaction stub] andReturn:originalError] error];
    [[queue stub] finishTransaction:[OCMArg any]];

    id product = [OCMockObject mockForClass:[SKProduct class]];
    [[[product stub] andReturn:@"test"] productIdentifier];
    [_store.products setObject:product forKey:@"test"];
    [_store addPayment:@"test" success:^(SKPaymentTransaction *transaction) {
        STFail(@"");
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        STAssertEqualObjects(transaction, originalTransaction, @"");
        STAssertEqualObjects(error, originalError, @"");
    }];
    
    [_store paymentQueue:queue updatedTransactions:@[originalTransaction]];
}

- (void)testPaymentQueueRestoreCompletedTransactionsFinished
{
    id observerMock = [self observerMockForNotification:RMSKRestoreTransactionsFinished];
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];

    [_store paymentQueueRestoreCompletedTransactionsFinished:queue];

    [observerMock verify];
    [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
}

- (void)testPaymentQueueRestoreCompletedTransactionsFinished__Blocks
{
    id observerMock = [self observerMockForNotification:RMSKRestoreTransactionsFinished];
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [_store restoreTransactionsOnSuccess:^{
    } failure:^(NSError *error) {
        STFail(@"");
    }];
    
    [_store paymentQueueRestoreCompletedTransactionsFinished:queue];
    
    [observerMock verify];
    [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
}

- (void)testPaymentQueueRestoreCompletedTransactionsFailedWithError_Queue_Nil
{
    id observerMock = [self observerMockForNotification:RMSKRestoreTransactionsFailed];
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];

    [_store paymentQueue:queue restoreCompletedTransactionsFailedWithError:nil];
    
    [observerMock verify];
    [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
}

- (void)testPaymentQueueRestoreCompletedTransactionsFailedWithError_Queue_Nil__Blocks
{
    id observerMock = [self observerMockForNotification:RMSKRestoreTransactionsFailed];
    [_store restoreTransactionsOnSuccess:^{
        STFail(@"");
    } failure:^(NSError *error) {
        STAssertNil(error, @"");
    }];
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [_store paymentQueue:queue restoreCompletedTransactionsFailedWithError:nil];

    [observerMock verify];
    [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
}

- (void)testPaymentQueueRestoreCompletedTransactionsFailedWithError_Queue_Error
{
    NSError *originalError = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    id observerMock = [self observerMockForNotification:RMSKRestoreTransactionsFailed checkUserInfoWithBlock:^BOOL(NSDictionary *userInfo) {
        NSError *error = [userInfo objectForKey:RMStoreNotificationStoreError];
        STAssertEqualObjects(error, originalError, @"");
        return YES;
    }];
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];

    [_store paymentQueue:queue restoreCompletedTransactionsFailedWithError:originalError];

    [observerMock verify];
    [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
}

- (void)testPaymentQueueRestoreCompletedTransactionsFailedWithError_Queue_Error__Blocks
{
    NSError *originalError = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    id observerMock = [self observerMockForNotification:RMSKRestoreTransactionsFailed checkUserInfoWithBlock:^BOOL(NSDictionary *userInfo) {
        NSError *error = [userInfo objectForKey:RMStoreNotificationStoreError];
        STAssertEqualObjects(error, originalError, @"");
        return YES;
    }];
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [_store restoreTransactionsOnSuccess:^{
        STFail(@"");
    } failure:^(NSError *error) {
        STAssertEqualObjects(error, originalError, @"");
    }];
    
    [_store paymentQueue:queue restoreCompletedTransactionsFailedWithError:originalError];

    [observerMock verify];
    [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
}

#pragma mark SKRequestDelegate

- (void)testRequestDidFinish
{
    id observerMock = [self observerMockForNotification:RMSKRefreshReceiptFinished];
    
    id store = _store;
    id requestMock = [OCMockObject mockForClass:[SKRequest class]];
    [store requestDidFinish:requestMock];
    
    [observerMock verify];
    [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
}

- (void)testRequestDidFailWithError
{
    NSError *originalError = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    id observerMock = [self observerMockForNotification:RMSKRefreshReceiptFailed checkUserInfoWithBlock:^BOOL(NSDictionary *userInfo) {
        NSError *error = [userInfo objectForKey:RMStoreNotificationStoreError];
        STAssertEqualObjects(error, originalError, @"");
        return YES;
    }];

    id store = _store;
    id requestMock = [OCMockObject mockForClass:[SKRequest class]];

    [store request:requestMock didFailWithError:originalError];
    
    [observerMock verify];
    [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
}

#pragma mark Private

- (id)mockPaymentTransactionWithState:(SKPaymentTransactionState)state
{
    id transaction = [OCMockObject mockForClass:[SKPaymentTransaction class]];
    [[[transaction stub] andReturnValue:@(state)] transactionState];
    [[[transaction stub] andReturn:[NSDate date]] transactionDate];
    [[[transaction stub] andReturn:@"transaction"] transactionIdentifier];
    [[[transaction stub] andReturn:[NSData data]] transactionReceipt];
    id payment = [OCMockObject mockForClass:[SKPayment class]];
    [[[payment stub] andReturn:@"test"] productIdentifier];
    [[[transaction stub] andReturn:payment] payment];
    return transaction;
}

- (id)observerMockForNotification:(NSString*)name
{
    id mock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:mock name:name object:_store];
    [[mock expect] notificationWithName:name object:_store];
    return mock;
}

- (id)observerMockForNotification:(NSString*)name checkUserInfoWithBlock:(BOOL(^)(id obj))block
{
    id mock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:mock name:name object:_store];
    [[mock expect] notificationWithName:name object:_store userInfo:[OCMArg checkWithBlock:block]];
    return mock;
}

#pragma mark RMStoreObserver

- (void)storeProductsRequestFailed:(NSNotification*)notification {}
- (void)storeProductsRequestFinished:(NSNotification*)notification {}
- (void)storePaymentTransactionFailed:(NSNotification*)notification {}
- (void)storePaymentTransactionFinished:(NSNotification*)notification {}
- (void)storeRestoreTransactionsFailed:(NSNotification*)notification {}
- (void)storeRestoreTransactionsFinished:(NSNotification*)notification {}

@end

@implementation RMStoreReceiptVerificatorSuccess

- (void)verifyReceiptOfTransaction:(SKPaymentTransaction *)transaction success:(void (^)())successBlock failure:(void (^)(NSError *))failureBlock
{
    if (successBlock) successBlock();
}

@end

@implementation RMStoreReceiptVerificatorFailure

- (void)verifyReceiptOfTransaction:(SKPaymentTransaction *)transaction success:(void (^)())successBlock failure:(void (^)(NSError *))failureBlock
{
    if (failureBlock) failureBlock(nil);
}

@end

#pragma clang diagnostic pop

