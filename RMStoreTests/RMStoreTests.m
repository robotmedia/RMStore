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
#import "RMStore.h"

@interface RMStoreTests : SenTestCase<RMStoreObserver>

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
}

- (void)testCanMakePayments
{
    [RMStore canMakePayments];
}

- (void)testDefaultStore
{
    RMStore *store = [RMStore defaultStore];
    STAssertNotNil(store, @"");
    STAssertEqualObjects(_store, store, @"");
}

- (void)testLocalizedPriceOfProduct
{
    SKProduct *product = [[SKProduct alloc] init];
    [self _testLocalizedPriceOfProduct:product];
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

- (void)testAddPurchaseForIdentifier
{
    [_store addPurchaseForIdentifier:@"test"];
    STAssertTrue([_store isPurchasedForIdentifier:@"test"], @"");
    STAssertEquals([_store countPurchasesForIdentifier:@"test"], 1, @"");
}

- (void)testClearPurchases
{
    [_store addPurchaseForIdentifier:@"test"];
    STAssertTrue([_store isPurchasedForIdentifier:@"test"], @"");

    [_store clearPurchases];
    STAssertFalse([_store isPurchasedForIdentifier:@"test"], @"");
}

- (void)testConsumeProductForIdentifierYES
{
    [_store addPurchaseForIdentifier:@"test"];
    STAssertEquals([_store countPurchasesForIdentifier:@"test"], 1, @"");
    
    BOOL result = [_store consumeProductForIdentifier:@"test"];
    STAssertTrue(result, @"");
    STAssertEquals([_store countPurchasesForIdentifier:@"test"], 0, @"");
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
    [_store addPurchaseForIdentifier:@"test"];
    STAssertEquals([_store countPurchasesForIdentifier:@"test"], 1, @"");
}

- (void)testCountPurchasesForIdentifierMany
{
    [_store addPurchaseForIdentifier:@"test"];
    [_store addPurchaseForIdentifier:@"test"];
    [_store addPurchaseForIdentifier:@"test"];
    STAssertEquals([_store countPurchasesForIdentifier:@"test"], 3, @"");
}

- (void)isPurchasedForIdentifierYES
{
    [_store addPurchaseForIdentifier:@"test"];
    
    BOOL result = [_store isPurchasedForIdentifier:@"test"];
    STAssertTrue(result, @"");
}

- (void)isPurchasedForIdentifierNO
{
    BOOL result = [_store isPurchasedForIdentifier:@"test"];
    STAssertFalse(result, @"");
}

- (void)testProductForIdentifierNil
{
    SKProduct *product = [_store productForIdentifier:@"test"];
    STAssertNil(product, @"");
}

- (void)testPurchasedIdentifiersEmpty
{
    NSArray *result = [_store purchasedIdentifiers];
    STAssertTrue(result.count == 0, @"");
}

- (void)testPurchasedIdentifiersOne
{
    [_store addPurchaseForIdentifier:@"test"];
    NSArray *result = [_store purchasedIdentifiers];
    STAssertTrue(result.count == 1, @"");
    STAssertEqualObjects([result lastObject], @"test", nil);
}

- (void)testPurchasedIdentifiersNoRepeats
{
    [_store addPurchaseForIdentifier:@"test"];
    [_store addPurchaseForIdentifier:@"test"];
    NSArray *result = [_store purchasedIdentifiers];
    STAssertTrue(result.count == 1, @"");
}

- (void)testPurchasedIdentifiersMany
{
    [_store addPurchaseForIdentifier:@"test1"];
    [_store addPurchaseForIdentifier:@"test2"];
    NSArray *result = [_store purchasedIdentifiers];
    STAssertTrue(result.count == 2, @"");
}

#pragma mark Private

- (void)_testLocalizedPriceOfProduct:(SKProduct*)product
{
    // TODO: Use OCMock
}

#pragma mark RMStoreObserver

- (void)storeProductsRequestFailed:(NSNotification*)notification {}
- (void)storeProductsRequestFinished:(NSNotification*)notification {}
- (void)storePaymentTransactionFailed:(NSNotification*)notification {}
- (void)storePaymentTransactionFinished:(NSNotification*)notification {}
- (void)storeRestoreTransactionsFailed:(NSNotification*)notification {}
- (void)storeRestoreTransactionsFinished:(NSNotification*)notification {}

@end
