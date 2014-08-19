//
//  NSNotification+RMStoreTests.m
//  RMStore
//
//  Created by Hermes on 9/8/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RMStore.h"

@interface NSNotification_RMStoreTests : XCTestCase

@end

@implementation NSNotification_RMStoreTests {
    NSNotification *_notification;
}

- (void)setUp
{
    _notification = [NSNotification notificationWithName:@"test" object:nil];
}

- (void)testInvalidProductIdentifiers
{
    NSArray *result = _notification.rm_invalidProductIdentifiers;
    XCTAssertNil(result, @"");
}

- (void)testProductIdentifier
{
    NSString *result = _notification.rm_productIdentifier;
    XCTAssertNil(result, @"");
}

- (void)testProducts
{
    NSArray *result = _notification.rm_products;
    XCTAssertNil(result, @"");
}

- (void)testStoreError
{
    NSError *result = _notification.rm_storeError;
    XCTAssertNil(result, @"");
}

- (void)testTransaction
{
    SKPaymentTransaction *result = _notification.rm_transaction;
    XCTAssertNil(result, @"");
}

@end
