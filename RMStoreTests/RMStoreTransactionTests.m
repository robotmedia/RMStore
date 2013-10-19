//
//  RMStoreTransactionTests.m
//  RMStore
//
//  Created by Hermes on 10/17/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "RMStoreTransaction.h"
#import <OCMock/OCMock.h>

@interface RMStoreTransactionTests : SenTestCase

@end

@implementation RMStoreTransactionTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)testInitWithPaymentTransaction
{
    SKPaymentTransaction *paymentTransaction = [self mockPaymentTransactionOfProductIdentifer:@"test"];

    RMStoreTransaction *transaction = [[RMStoreTransaction alloc] initWithPaymentTransaction:paymentTransaction];

    SKPayment *payment = paymentTransaction.payment;
    STAssertNotNil(transaction, @"");
    STAssertEqualObjects(transaction.productIdentifier, payment.productIdentifier, @"");
    STAssertEqualObjects(transaction.transactionDate, paymentTransaction.transactionDate, @"");
    STAssertEqualObjects(transaction.transactionIdentifier, paymentTransaction.transactionIdentifier, @"");
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    STAssertEqualObjects(transaction.transactionReceipt, paymentTransaction.transactionReceipt, @"");
#endif
    STAssertFalse(transaction.consumed, @"");
}

#pragma mark - NSCoding

- (void)testCoding
{
    RMStoreTransaction *transaction = [[RMStoreTransaction alloc] init];
    transaction.productIdentifier = @"test";
    transaction.transactionDate = [NSDate date];
    transaction.transactionIdentifier = @"transaction";
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    transaction.transactionReceipt = [NSData data];
#endif
    transaction.consumed = YES;

    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:transaction];
    [archiver finishEncoding];
    
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    RMStoreTransaction *decodedTransaction = [unarchiver decodeObject];
    
    STAssertNotNil(decodedTransaction, @"");
    STAssertEqualObjects(decodedTransaction.productIdentifier, transaction.productIdentifier, @"");
    STAssertEqualObjects(decodedTransaction.transactionDate, transaction.transactionDate, @"");
    STAssertEqualObjects(decodedTransaction.transactionIdentifier, transaction.transactionIdentifier, @"");
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    STAssertEqualObjects(decodedTransaction.transactionReceipt, transaction.transactionReceipt, @"");
#endif
    STAssertEquals(decodedTransaction.consumed, transaction.consumed, @"");
}

#pragma mark - Private

- (SKPaymentTransaction*)mockPaymentTransactionOfProductIdentifer:(NSString*)productIdentifier
{
    id transaction = [OCMockObject mockForClass:[SKPaymentTransaction class]];
    [[[transaction stub] andReturn:[NSDate date]] transactionDate];
    [[[transaction stub] andReturn:@"transaction"] transactionIdentifier];
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    [[[transaction stub] andReturn:[NSData data]] transactionReceipt];
#endif
    id payment = [OCMockObject mockForClass:[SKPayment class]];
    [[[payment stub] andReturn:productIdentifier] productIdentifier];
    [[[transaction stub] andReturn:payment] payment];
    return transaction;
}

@end
