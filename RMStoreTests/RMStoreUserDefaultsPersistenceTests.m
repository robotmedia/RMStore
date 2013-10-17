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
    [super tearDown];
}

- (void)testInitialState
{
    STAssertTrue([_persistor purchasedProductIdentifiers].count == 0, @"");
}

- (void)testPersistTransaction
{
    SKPaymentTransaction *paymentTransaction = [self persistMockTransactionOfProductIdentifer:@"test"];
    
    NSArray *transactions = [_persistor transactionsForProductOfIdentifier:@"test"];
    RMStoreTransaction *transaction = [transactions firstObject];
    SKPayment *payment = paymentTransaction.payment;
    STAssertNotNil(transaction, @"");
    STAssertEqualObjects(transaction.productIdentifier, payment.productIdentifier, @"");
}

- (void)testRemoveTransactions
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    
    [_persistor removeTransactions];

    STAssertFalse([_persistor isPurchasedProductOfIdentifier:@"test"], @"");
}

- (void)testConsumeProductOfIdentifier_YES
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    
    BOOL result = [_persistor consumeProductOfIdentifier:@"test"];
    
    STAssertTrue(result, @"");
}

- (void)testConsumeProductOfIdentifier_NO_inexistingProduct
{
    BOOL result = [_persistor consumeProductOfIdentifier:@"test"];
    STAssertFalse(result, @"");
}

- (void)testConsumeProductOfIdentifier_NO_alreadyConsumedProduct
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    [_persistor consumeProductOfIdentifier:@"test"];

    BOOL result = [_persistor consumeProductOfIdentifier:@"test"];
    STAssertFalse(result, @"");
}

- (void)testcountProductOfdentifier_zero
{
    STAssertEquals([_persistor countProductOfdentifier:@"test"], 0, @"");
}

- (void)testcountProductOfdentifier_one
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    STAssertEquals([_persistor countProductOfdentifier:@"test"], 1, @"");
}

- (void)testcountProductOfdentifier_many
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    [self persistMockTransactionOfProductIdentifer:@"test"];
    [self persistMockTransactionOfProductIdentifer:@"test"];
    STAssertEquals([_persistor countProductOfdentifier:@"test"], 3, @"");
}

- (void)testIsPurchasedProductOfIdentifier_YES
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    
    BOOL result = [_persistor isPurchasedProductOfIdentifier:@"test"];
    STAssertTrue(result, @"");
}

- (void)testIsPurchasedProductOfIdentifier_NO
{
    BOOL result = [_persistor isPurchasedProductOfIdentifier:@"test"];
    STAssertFalse(result, @"");
}

- (void)testPurchasedProductIdentifiers_empty
{
    NSArray *result = [_persistor purchasedProductIdentifiers];
    STAssertTrue(result.count == 0, @"");
}

- (void)testPurchasedProductIdentifiers_one
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    NSArray *result = [_persistor purchasedProductIdentifiers];
    STAssertTrue(result.count == 1, @"");
    STAssertEqualObjects([result lastObject], @"test", nil);
}

- (void)testPurchasedProductIdentifiers_many
{
    [self persistMockTransactionOfProductIdentifer:@"test1"];
    [self persistMockTransactionOfProductIdentifer:@"test2"];
    NSArray *result = [_persistor purchasedProductIdentifiers];
    STAssertTrue(result.count == 2, @"");
}

- (void)testTransactionsForProductIdentifier_zero
{
    NSArray *transactions = [_persistor transactionsForProductOfIdentifier:@"test"];
    STAssertTrue(transactions.count == 0, @"");
}

- (void)testTransactionsForProductIdentifier_one
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    NSArray *transactions = [_persistor transactionsForProductOfIdentifier:@"test"];
    STAssertTrue(transactions.count == 1, @"");
}

- (void)testTransactionsForProductIdentifier_many
{
    [self persistMockTransactionOfProductIdentifer:@"test1"];
    [self persistMockTransactionOfProductIdentifer:@"test1"];
    [self persistMockTransactionOfProductIdentifer:@"test1"];
    [self persistMockTransactionOfProductIdentifer:@"test2"];
    NSArray *transactions = [_persistor transactionsForProductOfIdentifier:@"test1"];
    STAssertTrue(transactions.count == 3, @"");
}

- (SKPaymentTransaction*)persistMockTransactionOfProductIdentifer:(NSString*)productIdentifier
{
    id transaction = [OCMockObject mockForClass:[SKPaymentTransaction class]];
    [[[transaction stub] andReturn:[NSDate date]] transactionDate];
    [[[transaction stub] andReturn:@"transaction"] transactionIdentifier];
    [[[transaction stub] andReturn:[NSData data]] transactionReceipt];
    id payment = [OCMockObject mockForClass:[SKPayment class]];
    [[[payment stub] andReturn:productIdentifier] productIdentifier];
    [[[transaction stub] andReturn:payment] payment];
    [_persistor persistTransaction:transaction];
    return transaction;
}

@end
