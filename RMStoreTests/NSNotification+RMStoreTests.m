//
//  NSNotification+RMStoreTests.m
//  RMStore
//
//  Created by Hermes on 9/8/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "RMStore.h"

@interface NSNotification_RMStoreTests : SenTestCase

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
    STAssertNil(result, @"");
}

- (void)testProductIdentifier
{
    NSString *result = _notification.productIdentifier;
    STAssertNil(result, @"");
}

- (void)testProducts
{
    NSArray *result = _notification.products;
    STAssertNil(result, @"");
}

- (void)testStoreError
{
    NSError *result = _notification.storeError;
    STAssertNil(result, @"");
}

- (void)testTransaction
{
    SKPaymentTransaction *result = _notification.transaction;
    STAssertNil(result, @"");
}

@end
