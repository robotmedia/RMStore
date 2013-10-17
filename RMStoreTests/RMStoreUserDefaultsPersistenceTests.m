//
//  RMStoreUserDefaultsPersistenceTests.m
//  RMStore
//
//  Created by Hermes on 10/16/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "RMStoreUserDefaultsPersistence.h"
#import "RMStoreTransaction.h"
#import <OCMock/OCMock.h>

@interface RMStoreUserDefaultsPersistenceTests : SenTestCase

@end

@implementation RMStoreUserDefaultsPersistenceTests {
    RMStoreUserDefaultsPersistence *_persistor;
}

- (void)setUp
{
    [super setUp];
    _persistor = [[RMStoreUserDefaultsPersistence alloc] init];
}

- (void)tearDown
{
    [_persistor removeTransactions];
}

- (void)testAddTransaction
{
    STAssertTrue([_persistor transactionsForProductOfIdentifier:@"test"].count == 0, @"");
    
    [self addPurchaseForProductIdentifier:@"test"];
    
    STAssertTrue([_persistor isPurchasedProductOfIdentifier:@"test"], @"");
    STAssertEquals([_persistor countProductOfdentifier:@"test"], 1, @"");
    NSArray *transactions = [_persistor transactionsForProductOfIdentifier:@"test"];
    STAssertTrue(transactions.count == 1, @"");
    RMStoreTransaction *transaction = [transactions objectAtIndex:0];
    STAssertEqualObjects(transaction.productIdentifier, @"test", @"");
}

- (void)testClearPurchases
{
    [self addPurchaseForProductIdentifier:@"test"];
    STAssertTrue([_persistor isPurchasedProductOfIdentifier:@"test"], @"");
    STAssertTrue([_persistor transactionsForProductOfIdentifier:@"test"].count == 1, @"");
    
    [_persistor removeTransactions];
    STAssertFalse([_persistor isPurchasedProductOfIdentifier:@"test"], @"");
    STAssertTrue([_persistor transactionsForProductOfIdentifier:@"test"].count == 0, @"");
}

- (void)testConsumeProductForIdentifierYES
{
    [self addPurchaseForProductIdentifier:@"test"];
    STAssertEquals([_persistor countProductOfdentifier:@"test"], 1, @"");
    {
        NSArray *transactions = [_persistor transactionsForProductOfIdentifier:@"test"];
        RMStoreTransaction *transaction = [transactions objectAtIndex:0];
        STAssertFalse(transaction.consumed, @"");
    }
    
    BOOL result = [_persistor consumeProductOfIdentifier:@"test"];
    
    STAssertTrue(result, @"");
    STAssertEquals([_persistor countProductOfdentifier:@"test"], 0, @"");
    {
        NSArray *transactions = [_persistor transactionsForProductOfIdentifier:@"test"];
        STAssertTrue(transactions.count == 1, @"");
        RMStoreTransaction *transaction = [transactions objectAtIndex:0];
        STAssertTrue(transaction.consumed, @"");
    }
}

- (void)testConsumeProductForIdentifierNO
{
    STAssertEquals([_persistor countProductOfdentifier:@"test"], 0, @"");
    
    BOOL result = [_persistor consumeProductOfIdentifier:@"test"];
    STAssertFalse(result, @"");
    STAssertEquals([_persistor countProductOfdentifier:@"test"], 0, @"");
}

- (void)testCountPurchasesForIdentifierZero
{
    STAssertEquals([_persistor countProductOfdentifier:@"test"], 0, @"");
}

- (void)testCountPurchasesForIdentifierOne
{
    [self addPurchaseForProductIdentifier:@"test"];
    STAssertEquals([_persistor countProductOfdentifier:@"test"], 1, @"");
}

- (void)testCountPurchasesForIdentifierMany
{
    [self addPurchaseForProductIdentifier:@"test"];
    [self addPurchaseForProductIdentifier:@"test"];
    [self addPurchaseForProductIdentifier:@"test"];
    STAssertEquals([_persistor countProductOfdentifier:@"test"], 3, @"");
}

- (void)isPurchasedForIdentifierYES
{
    [self addPurchaseForProductIdentifier:@"test"];
    
    BOOL result = [_persistor isPurchasedProductOfIdentifier:@"test"];
    STAssertTrue(result, @"");
}

- (void)isPurchasedForIdentifierNO
{
    BOOL result = [_persistor isPurchasedProductOfIdentifier:@"test"];
    STAssertFalse(result, @"");
}

- (void)testPurchasedProductIdentifiersEmpty
{
    NSArray *result = [_persistor purchasedProductIdentifiers];
    STAssertTrue(result.count == 0, @"");
}

- (void)testPurchasedProductIdentifiersOne
{
    [self addPurchaseForProductIdentifier:@"test"];
    NSArray *result = [_persistor purchasedProductIdentifiers];
    STAssertTrue(result.count == 1, @"");
    STAssertEqualObjects([result lastObject], @"test", nil);
}

- (void)testPurchasedProductIdentifiersNoRepeats
{
    [self addPurchaseForProductIdentifier:@"test"];
    [self addPurchaseForProductIdentifier:@"test"];
    NSArray *result = [_persistor purchasedProductIdentifiers];
    STAssertTrue(result.count == 1, @"");
}

- (void)testPurchasedProductIdentifiersMany
{
    [self addPurchaseForProductIdentifier:@"test1"];
    [self addPurchaseForProductIdentifier:@"test2"];
    NSArray *result = [_persistor purchasedProductIdentifiers];
    STAssertTrue(result.count == 2, @"");
}

- (void)testTransactionsForProductIdentifierZero
{
    NSArray *transactions = [_persistor transactionsForProductOfIdentifier:@"test"];
    STAssertTrue(transactions.count == 0, @"");
}

- (void)testTransactionsForProductIdentifierOne
{
    [self addPurchaseForProductIdentifier:@"test"];
    NSArray *transactions = [_persistor transactionsForProductOfIdentifier:@"test"];
    STAssertTrue(transactions.count == 1, @"");
}

- (void)testTransactionsForProductIdentifierMany
{
    [self addPurchaseForProductIdentifier:@"test1"];
    [self addPurchaseForProductIdentifier:@"test1"];
    [self addPurchaseForProductIdentifier:@"test1"];
    [self addPurchaseForProductIdentifier:@"test2"];
    NSArray *transactions = [_persistor transactionsForProductOfIdentifier:@"test1"];
    STAssertTrue(transactions.count == 3, @"");
}

- (void)addPurchaseForProductIdentifier:(NSString*)productIdentifier
{
    id transaction = [OCMockObject mockForClass:[SKPaymentTransaction class]];
    [[[transaction stub] andReturn:[NSDate date]] transactionDate];
    [[[transaction stub] andReturn:@"transaction"] transactionIdentifier];
    [[[transaction stub] andReturn:[NSData data]] transactionReceipt];
    id payment = [OCMockObject mockForClass:[SKPayment class]];
    [[[payment stub] andReturn:productIdentifier] productIdentifier];
    [[[transaction stub] andReturn:payment] payment];
    [_persistor persistTransaction:transaction];
}

@end
