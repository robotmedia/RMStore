//
//  RMStoreTransactionReceiptVerificatorTests.m
//  RMStore
//
//  Created by Hermes on 9/12/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RMStoreTransactionReceiptVerificator.h"
#import <OCMock/OCMock.h>

@interface RMStoreTransactionReceiptVerificatorTests : XCTestCase

@end

@implementation RMStoreTransactionReceiptVerificatorTests {
    RMStoreTransactionReceiptVerificator *_verificator;
}

- (void)setUp
{
    _verificator = [[RMStoreTransactionReceiptVerificator alloc] init];
}

- (void)testVerifyTransaction_NoReceipt_Nil_Nil
{
    id transaction = [self mockPaymentTransactionWithReceipt:nil];
    [_verificator verifyTransaction:transaction success:nil failure:nil];
}

- (void)testVerifyTransaction_NoReceipt
{
    id transaction = [self mockPaymentTransactionWithReceipt:nil];
    [_verificator verifyTransaction:transaction success:^{
        XCTFail(@"");
    } failure:^(NSError *error) {
        XCTAssertNotNil(error, @"");
    }];
}

- (void)testVerifyTransaction_Receipt
{
    NSData *receipt = [@"receipt" dataUsingEncoding:NSUTF8StringEncoding];
    id transaction = [self mockPaymentTransactionWithReceipt:receipt];
    [_verificator verifyTransaction:transaction success:^{
        XCTFail(@"");
    } failure:^(NSError *error) {
    }];
}

- (void)testVerifyTransaction_Receipt_Nil_Nil
{
    NSData *receipt = [@"receipt" dataUsingEncoding:NSUTF8StringEncoding];
    id transaction = [self mockPaymentTransactionWithReceipt:receipt];
    [_verificator verifyTransaction:transaction success:nil failure:nil];
}

- (id)mockPaymentTransactionWithReceipt:(NSData*)receipt
{
    id transaction = [OCMockObject mockForClass:[SKPaymentTransaction class]];
    [[[transaction stub] andReturn:receipt] transactionReceipt];
    return transaction;
}

@end
