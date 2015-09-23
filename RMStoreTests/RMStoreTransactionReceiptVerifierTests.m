//
//  RMStoreTransactionReceiptVerifierTests.m
//  RMStore
//
//  Created by Hermes on 9/12/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RMStoreTransactionReceiptVerifier.h"
#import <OCMock/OCMock.h>

@interface RMStoreTransactionReceiptVerifierTests : XCTestCase

@end

@implementation RMStoreTransactionReceiptVerifierTests {
    RMStoreTransactionReceiptVerifier *_verifier;
}

- (void)setUp
{
    _verifier = [[RMStoreTransactionReceiptVerifier alloc] init];
}

- (void)testVerifyTransaction_NoReceipt_Nil_Nil
{
    id transaction = [self mockPaymentTransactionWithReceipt:nil];
    [_verifier verifyTransaction:transaction success:nil failure:nil];
}

- (void)testVerifyTransaction_NoReceipt
{
    id transaction = [self mockPaymentTransactionWithReceipt:nil];
    [_verifier verifyTransaction:transaction success:^{
        XCTFail(@"");
    } failure:^(NSError *error) {
        XCTAssertNotNil(error, @"");
    }];
}

- (void)testVerifyTransaction_Receipt
{
    NSData *receipt = [@"receipt" dataUsingEncoding:NSUTF8StringEncoding];
    id transaction = [self mockPaymentTransactionWithReceipt:receipt];
    [_verifier verifyTransaction:transaction success:^{
        XCTFail(@"");
    } failure:^(NSError *error) {
    }];
}

- (void)testVerifyTransaction_Receipt_Nil_Nil
{
    NSData *receipt = [@"receipt" dataUsingEncoding:NSUTF8StringEncoding];
    id transaction = [self mockPaymentTransactionWithReceipt:receipt];
    [_verifier verifyTransaction:transaction success:nil failure:nil];
}

- (id)mockPaymentTransactionWithReceipt:(NSData*)receipt
{
    id transaction = [OCMockObject mockForClass:[SKPaymentTransaction class]];
    [[[transaction stub] andReturn:receipt] transactionReceipt];
    return transaction;
}

@end
