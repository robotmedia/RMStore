//
//  RMStoreAppReceiptVerifierTests.m
//  RMStore
//
//  Created by Hermes on 10/15/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RMStoreAppReceiptVerifier.h"
#import <OCMock/OCMock.h>

@interface RMStoreAppReceiptVerifierTests : XCTestCase

@end

@implementation RMStoreAppReceiptVerifierTests {
    RMStoreAppReceiptVerifier *_verifier;
}

- (void)setUp
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    [super setUp];
    _verifier = [[RMStoreAppReceiptVerifier alloc] init];
}

- (void)testVerifyTransaction_transaction_nil_nil
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    id transaction = [OCMockObject mockForClass:[SKPaymentTransaction class]];
    [_verifier verifyTransaction:transaction success:nil failure:nil];
}

- (void)testVerifyTransaction_transaction_block_block_fail
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    id transaction = [OCMockObject mockForClass:[SKPaymentTransaction class]];
    [_verifier verifyTransaction:transaction success:^{
        XCTFail(@"");
    } failure:^(NSError *error) {
        XCTAssertNotNil(error, @"");
    }];
}

- (void)testVerifyAppReceipt_NO
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    BOOL result = [_verifier verifyAppReceipt];
    XCTAssertFalse(result, @"");
}

- (void)testBundleIdentifier_default
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    NSString *expected = [NSBundle mainBundle].bundleIdentifier;
    NSString *result = _verifier.bundleIdentifier;
    XCTAssertEqualObjects(expected, result, @"");
}

- (void)testBundleIdentifier_set
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    NSString *expected = @"test";
    _verifier.bundleIdentifier = expected;
    NSString *result = _verifier.bundleIdentifier;
    XCTAssertEqualObjects(expected, result, @"");
}

- (void)testBundleVersion_default
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    NSString *expected = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *result = _verifier.bundleVersion;
    XCTAssertEqualObjects(expected, result, @"");
}

- (void)testBundleVersion_set
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    NSString *expected = @"2.0";
    _verifier.bundleVersion = expected;
    NSString *result = _verifier.bundleVersion;
    XCTAssertEqualObjects(expected, result, @"");
}

@end
