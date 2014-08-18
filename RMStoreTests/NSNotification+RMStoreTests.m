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
    NSArray *result = _notification.invalidProductIdentifiers;
    XCTAssertNil(result, @"");
}

- (void)testProductIdentifier
{
    NSString *result = _notification.productIdentifier;
    XCTAssertNil(result, @"");
}

- (void)testProducts
{
    NSArray *result = _notification.products;
    XCTAssertNil(result, @"");
}

- (void)testStoreError
{
    NSError *result = _notification.storeError;
    XCTAssertNil(result, @"");
}

- (void)testTransaction
{
    SKPaymentTransaction *result = _notification.transaction;
    XCTAssertNil(result, @"");
}

@end
