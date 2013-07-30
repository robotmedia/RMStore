//
//  RMStoreTests.m
//  RMStoreTests
//
//  Created by Hermes Pique on 7/30/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "RMStore.h"

@interface RMStoreTests : SenTestCase

@end

@implementation RMStoreTests

- (void)testCanMakePayments
{
    [RMStore canMakePayments];
}

- (void)testDefaultStore
{
    RMStore *store1 = [RMStore defaultStore];
    RMStore *store2 = [RMStore defaultStore];
    STAssertNotNil(store1, @"");
    STAssertEqualObjects(store1, store2, @"");
}

- (void)testLocalizedPriceOfProduct
{
    SKProduct *product = [[SKProduct alloc] init];
    [self _testLocalizedPriceOfProduct:product];
}

#pragma mark - Private

- (void)_testLocalizedPriceOfProduct:(SKProduct*)product
{
    // TODO: Use OCMock
}

@end
