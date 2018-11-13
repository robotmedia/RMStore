//
//  RMStoreUserDefaultsPersistenceTests.m
//  RMStore
//
//  Created by Hermes on 10/16/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RMStoreUserDefaultsPersistence.h"
#import "RMStoreTransaction.h"
#import <OCMock/OCMock.h>

@interface RMStoreUserDefaultsPersistenceTests : XCTestCase

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
    XCTAssertTrue([_persistor purchasedProductIdentifiers].count == 0, @"");
}

- (void)testPersistTransaction
{
    SKPaymentTransaction *paymentTransaction = [self persistMockTransactionOfProductIdentifer:@"test"];
    
    NSArray *transactions = [_persistor transactionsForProductOfIdentifier:@"test"];
    RMStoreTransaction *transaction = transactions.firstObject;
    SKPayment *payment = paymentTransaction.payment;
    XCTAssertNotNil(transaction, @"");
    XCTAssertEqualObjects(transaction.productIdentifier, payment.productIdentifier, @"");
}

- (void)testRemoveTransactions
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    
    [_persistor removeTransactions];

    XCTAssertFalse([_persistor isPurchasedProductOfIdentifier:@"test"], @"");
}

- (void)testConsumeProductOfIdentifier_YES
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    
    BOOL result = [_persistor consumeProductOfIdentifier:@"test"];
    
    XCTAssertTrue(result, @"");
}

- (void)testConsumeProductOfIdentifier_NO_inexistingProduct
{
    BOOL result = [_persistor consumeProductOfIdentifier:@"test"];
    XCTAssertFalse(result, @"");
}

- (void)testConsumeProductOfIdentifier_NO_alreadyConsumedProduct
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    [_persistor consumeProductOfIdentifier:@"test"];

    BOOL result = [_persistor consumeProductOfIdentifier:@"test"];
    XCTAssertFalse(result, @"");
}

- (void)testcountProductOfdentifier_zero
{
    XCTAssertTrue([_persistor countProductOfdentifier:@"test"] == 0, @"");
}

- (void)testcountProductOfdentifier_one
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    XCTAssertTrue([_persistor countProductOfdentifier:@"test"] == 1, @"");
}

- (void)testcountProductOfdentifier_many
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    [self persistMockTransactionOfProductIdentifer:@"test"];
    [self persistMockTransactionOfProductIdentifer:@"test"];
    XCTAssertTrue([_persistor countProductOfdentifier:@"test"] == 3, @"");
}

- (void)testIsPurchasedProductOfIdentifier_YES
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    
    BOOL result = [_persistor isPurchasedProductOfIdentifier:@"test"];
    XCTAssertTrue(result, @"");
}

- (void)testIsPurchasedProductOfIdentifier_NO
{
    BOOL result = [_persistor isPurchasedProductOfIdentifier:@"test"];
    XCTAssertFalse(result, @"");
}

- (void)testPurchasedProductIdentifiers_empty
{
    NSSet *result = [_persistor purchasedProductIdentifiers];
    XCTAssertTrue(result.count == 0, @"");
}

- (void)testPurchasedProductIdentifiers_one
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    NSSet *result = [_persistor purchasedProductIdentifiers];
    XCTAssertTrue(result.count == 1, @"");
    XCTAssertEqualObjects([result anyObject], @"test");
}

- (void)testPurchasedProductIdentifiers_many
{
    [self persistMockTransactionOfProductIdentifer:@"test1"];
    [self persistMockTransactionOfProductIdentifer:@"test2"];
    NSSet *result = [_persistor purchasedProductIdentifiers];
    XCTAssertTrue(result.count == 2, @"");
}

- (void)testTransactionsForProductIdentifier_zero
{
    NSArray *transactions = [_persistor transactionsForProductOfIdentifier:@"test"];
    XCTAssertTrue(transactions.count == 0, @"");
}

- (void)testTransactionsForProductIdentifier_one
{
    [self persistMockTransactionOfProductIdentifer:@"test"];
    NSArray *transactions = [_persistor transactionsForProductOfIdentifier:@"test"];
    XCTAssertTrue(transactions.count == 1, @"");
}

- (void)testTransactionsForProductIdentifier_many
{
    [self persistMockTransactionOfProductIdentifer:@"test1"];
    [self persistMockTransactionOfProductIdentifer:@"test1"];
    [self persistMockTransactionOfProductIdentifer:@"test1"];
    [self persistMockTransactionOfProductIdentifer:@"test2"];
    NSArray *transactions = [_persistor transactionsForProductOfIdentifier:@"test1"];
    XCTAssertTrue(transactions.count == 3, @"");
}

#pragma mark - Obfuscation

- (void)testDataWithTransaction
{
    RMStoreTransaction *transaction = [self sampleTransaction];
    
    NSData *data = [_persistor dataWithTransaction:transaction];
    
    XCTAssertNotNil(data, @"");
    RMStoreTransaction *unobfuscatedTransaction = [_persistor transactionWithData:data];
    [self compareTransaction:unobfuscatedTransaction withTransaction:transaction];
}

- (void)testTransactionWithData
{
    RMStoreTransaction *transaction = [self sampleTransaction];
    NSData *data = [_persistor dataWithTransaction:transaction];
    
    RMStoreTransaction *result = [_persistor transactionWithData:data];

    XCTAssertNotNil(result, @"");
    [self compareTransaction:result withTransaction:transaction];
}

#pragma mark - Private

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

- (void)compareTransaction:(RMStoreTransaction*)transaction1 withTransaction:(RMStoreTransaction*)transaction2
{
    XCTAssertEqualObjects(transaction1.productIdentifier, transaction2.productIdentifier, @"");
    XCTAssertEqualObjects(transaction1.transactionDate, transaction2.transactionDate, @"");
    XCTAssertEqualObjects(transaction1.transactionIdentifier, transaction2.transactionIdentifier, @"");

    XCTAssertEqual(transaction1.consumed, transaction2.consumed, @"");
}


- (RMStoreTransaction*)sampleTransaction
{
    RMStoreTransaction *transaction = [[RMStoreTransaction alloc] init];
    transaction.productIdentifier = @"test";
    transaction.transactionDate = [NSDate date];
    transaction.transactionIdentifier = @"transaction";

    transaction.consumed = YES;
    return transaction;
}

@end
