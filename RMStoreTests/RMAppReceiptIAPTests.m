//
//  RMAppReceiptIAPTests.m
//  RMStore
//
//  Created by Hermes on 10/15/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RMAppReceipt.h"

@interface RMAppReceiptIAPTests : XCTestCase

@end

@implementation RMAppReceiptIAPTests {
    RMAppReceiptIAP *_purchase;
}

- (void)testInitWithASN1Data_invalid
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    NSData *data = [NSData data];
    _purchase = [[RMAppReceiptIAP alloc] initWithASN1Data:data];
    XCTAssertNotNil(_purchase, @"");
    XCTAssertTrue(_purchase.quantity == 0, @"");
    XCTAssertNil(_purchase.productIdentifier, @"");
    XCTAssertNil(_purchase.transactionIdentifier, @"");
    XCTAssertNil(_purchase.originalTransactionIdentifier, @"");
    XCTAssertNil(_purchase.purchaseDate, @"");
    XCTAssertNil(_purchase.originalPurchaseDate, @"");
    XCTAssertNil(_purchase.subscriptionExpirationDate, @"");
    XCTAssertNil(_purchase.cancellationDate, @"");
    XCTAssertTrue(_purchase.webOrderLineItemID == 0, @"");
}

- (void)testIsActiveAutoRenewableSubscriptionForDate_throws
{
    _purchase = [[RMAppReceiptIAP alloc] initWithASN1Data:[NSData data]];
#if !defined(NS_BLOCK_ASSERTIONS)
    XCTAssertThrowsSpecificNamed([_purchase isActiveAutoRenewableSubscriptionForDate:[NSDate date]], NSException, NSInternalInconsistencyException, @"");
#endif
}

@end
