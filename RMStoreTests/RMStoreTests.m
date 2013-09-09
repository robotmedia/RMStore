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

@interface RMStoreTests : SenTestCase<RMStoreObserver>

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
    _store = [RMStore defaultStore];
}

- (void) tearDown
{
    [_store removeStoreObserver:self];
    [_store clearPurchases];

    [_store.products removeAllObjects];
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
    RMStore *store = [RMStore defaultStore];
    STAssertEqualObjects(_store, store, @"");
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
    [_store restoreTransactions];
}

- (void)testRestoreTransactions_Block_Block
{
    [_store restoreTransactionsOnSuccess:^{
    } failure:^(NSError *error) {
    }];
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
    STAssertNil(transaction.transactionReceipt, @"");
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

- (void)testPaymentQueueUpdatedTransactions_Purchased
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[queue stub] finishTransaction:[OCMArg any]];

    [_store paymentQueue:queue updatedTransactions:@[transaction]];
}

- (void)testPaymentQueueUpdatedTransactions_Restored
{
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

- (void)testPaymentQueueRestoreCompletedTransactionsFinished
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [_store paymentQueueRestoreCompletedTransactionsFinished:queue];
    // TODO: test notification
}

- (void)testPaymentQueueRestoreCompletedTransactionsFailedWithError_Nil
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [_store paymentQueue:queue restoreCompletedTransactionsFailedWithError:nil];
    // TODO: test notification
}

- (void)testPaymentQueueRestoreCompletedTransactionsFailedWithError_Error
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    NSError *error = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    [_store paymentQueue:queue restoreCompletedTransactionsFailedWithError:error];
    // TODO: test notification
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

#pragma mark RMStoreObserver

- (void)storeProductsRequestFailed:(NSNotification*)notification {}
- (void)storeProductsRequestFinished:(NSNotification*)notification {}
- (void)storePaymentTransactionFailed:(NSNotification*)notification {}
- (void)storePaymentTransactionFinished:(NSNotification*)notification {}
- (void)storeRestoreTransactionsFailed:(NSNotification*)notification {}
- (void)storeRestoreTransactionsFinished:(NSNotification*)notification {}

@end
