//
//  RMAppReceiptTests.m
//  RMStore
//
//  Created by Hermes on 10/15/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RMAppReceipt.h"

@interface RMAppReceiptTests : XCTestCase

@end

@implementation RMAppReceiptTests {
    RMAppReceipt *_receipt;
}

- (void)testInitWithASN1Data_invalid
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    NSData *data = [NSData data];
    _receipt = [[RMAppReceipt alloc] initWithASN1Data:data];
    XCTAssertNotNil(_receipt, @"");
    XCTAssertNil(_receipt.bundleIdentifier, @"");
    XCTAssertNil(_receipt.bundleIdentifierData, @"");
    XCTAssertNil(_receipt.appVersion, @"");
    XCTAssertNil(_receipt.opaqueValue, @"");
    XCTAssertNil(_receipt.receiptHash, @"");
    XCTAssertTrue(_receipt.inAppPurchases.count == 0, @"");
    XCTAssertNil(_receipt.originalAppVersion, @"");
    XCTAssertNil(_receipt.expirationDate, @"");
}

- (void)testContainsInAppPurchaseOfProductIdentifier_NO
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    NSData *data = [NSData data];
    _receipt = [[RMAppReceipt alloc] initWithASN1Data:data];
    BOOL result = [_receipt containsInAppPurchaseOfProductIdentifier:@"test"];
    XCTAssertFalse(result, @"");
}

- (void)testContainsActiveAutoRenewableSubscriptionOfProductIdentifierForDate_NO
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    NSData *data = [NSData data];
    _receipt = [[RMAppReceipt alloc] initWithASN1Data:data];
    BOOL result = [_receipt containsActiveAutoRenewableSubscriptionOfProductIdentifier:@"test" forDate:[NSDate date]];
    XCTAssertFalse(result, @"");
}

- (void)testBundleReceipt_nil
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    RMAppReceipt *receipt = [RMAppReceipt bundleReceipt];
    XCTAssertNil(receipt, @"");
}

- (void)testVerifyReceiptHash_NO
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    _receipt = [[RMAppReceipt alloc] initWithASN1Data:[NSData data]];
    BOOL result = [_receipt verifyReceiptHash];
    XCTAssertFalse(result, @"");
}

- (void)testSetAppleRootCertificateURL
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    [RMAppReceipt setAppleRootCertificateURL:nil];
}

@end
