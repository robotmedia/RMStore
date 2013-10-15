//
//  RMStoreTransactionReceiptVerificatorTests.m
//  RMStore
//
//  Created by Hermes on 9/12/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "RMStoreTransactionReceiptVerificator.h"
#import <OCMock/OCMock.h>

@interface RMStoreTransactionReceiptVerificatorTests : SenTestCase

@end

@implementation RMStoreTransactionReceiptVerificatorTests {
    RMStoreTransactionReceiptVerificator *_verificator;
}

- (void)setUp
{
    _verificator = [[RMStoreTransactionReceiptVerificator alloc] init];
}

- (void)testverifyReceiptOfTransaction_NoReceipt_Nil_Nil
{
    id transaction = [self mockPaymentTransactionWithReceipt:nil];
    [_verificator verifyReceiptOfTransaction:transaction success:nil failure:nil];
}

- (void)testverifyReceiptOfTransaction_NoReceipt
{
    id transaction = [self mockPaymentTransactionWithReceipt:nil];
    [_verificator verifyReceiptOfTransaction:transaction success:^{
        STFail(@"");
    } failure:^(NSError *error) {
        STAssertNotNil(error, @"");
    }];
}

- (void)testverifyReceiptOfTransaction_Receipt
{
    NSData *receipt = [@"receipt" dataUsingEncoding:NSUTF8StringEncoding];
    id transaction = [self mockPaymentTransactionWithReceipt:receipt];
    [_verificator verifyReceiptOfTransaction:transaction success:^{
        STFail(@"");
    } failure:^(NSError *error) {
    }];
}

- (void)testverifyReceiptOfTransaction_Receipt_Nil_Nil
{
    NSData *receipt = [@"receipt" dataUsingEncoding:NSUTF8StringEncoding];
    id transaction = [self mockPaymentTransactionWithReceipt:receipt];
    [_verificator verifyReceiptOfTransaction:transaction success:nil failure:nil];
}

- (id)mockPaymentTransactionWithReceipt:(NSData*)receipt
{
    id transaction = [OCMockObject mockForClass:[SKPaymentTransaction class]];
    [[[transaction stub] andReturn:receipt] transactionReceipt];
    return transaction;
}

@end
