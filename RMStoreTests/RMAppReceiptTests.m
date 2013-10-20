//
//  RMAppReceiptTests.m
//  RMStore
//
//  Created by Hermes on 10/15/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "RMAppReceipt.h"

@interface RMAppReceiptTests : SenTestCase

@end

@implementation RMAppReceiptTests {
    RMAppReceipt *_receipt;
}

- (void)testInitWithASN1Data_invalid
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    NSData *data = [NSData data];
    _receipt = [[RMAppReceipt alloc] initWithASN1Data:data];
    STAssertNotNil(_receipt, @"");
    STAssertNil(_receipt.bundleIdentifier, @"");
    STAssertNil(_receipt.bundleIdentifierData, @"");
    STAssertNil(_receipt.appVersion, @"");
    STAssertNil(_receipt.opaqueValue, @"");
    STAssertNil(_receipt.hash, @"");
    STAssertTrue(_receipt.inAppPurchases.count == 0, @"");
    STAssertNil(_receipt.originalAppVersion, @"");
    STAssertNil(_receipt.expirationDate, @"");
}

- (void)testContainsInAppPurchaseOfProductIdentifier_NO
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    NSData *data = [NSData data];
    _receipt = [[RMAppReceipt alloc] initWithASN1Data:data];
    BOOL result = [_receipt containsInAppPurchaseOfProductIdentifier:@"test"];
    STAssertFalse(result, @"");
}

- (void)testBundleReceipt_nil
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    RMAppReceipt *receipt = [RMAppReceipt bundleReceipt];
    STAssertNil(receipt, @"");
}

- (void)testVerifyReceiptHash_NO
{
    _receipt = [[RMAppReceipt alloc] initWithASN1Data:[NSData data]];
    BOOL result = [_receipt verifyReceiptHash];
    STAssertFalse(result, @"");
}

@end
