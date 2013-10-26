//
//  RMAppReceiptIAPTests.m
//  RMStore
//
//  Created by Hermes on 10/15/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "RMAppReceipt.h"

@interface RMAppReceiptIAPTests : SenTestCase

@end

@implementation RMAppReceiptIAPTests {
    RMAppReceiptIAP *_purchase;
}

- (void)testInitWithASN1Data_invalid
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    NSData *data = [NSData data];
    _purchase = [[RMAppReceiptIAP alloc] initWithASN1Data:data];
    STAssertNotNil(_purchase, @"");
    STAssertTrue(_purchase.quantity == 0, @"");
    STAssertNil(_purchase.productIdentifier, @"");
    STAssertNil(_purchase.transactionIdentifier, @"");
    STAssertNil(_purchase.originalTransactionIdentifier, @"");
    STAssertNil(_purchase.purchaseDate, @"");
    STAssertNil(_purchase.originalPurchaseDate, @"");
    STAssertNil(_purchase.subscriptionExpirationDate, @"");
    STAssertNil(_purchase.cancellationDate, @"");
    STAssertTrue(_purchase.webOrderLineItemID == 0, @"");
}

- (void)testIsActiveAutoRenewableSubscriptionForDate_throws
{
    _purchase = [[RMAppReceiptIAP alloc] initWithASN1Data:[NSData data]];
#if !defined(NS_BLOCK_ASSERTIONS)
    STAssertThrowsSpecificNamed([_purchase isActiveAutoRenewableSubscriptionForDate:[NSDate date]], NSException, NSInternalInconsistencyException, @"");
#endif
}

@end
