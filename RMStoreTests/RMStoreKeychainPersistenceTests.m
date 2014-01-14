//
//  RMStoreKeychainPersistenceTests.m
//  RMStore
//
//  Created by Hermes on 10/19/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "RMStoreKeychainPersistence.h"
#import <OCMock/OCMock.h>
#import <objc/runtime.h>

@interface NSBundle(bundleIdentifier)

@end

extern void RMKeychainSetValue(NSData *value, NSString *key);
extern NSString* const RMStoreTransactionsKeychainKey;

/**
 [NSBundle bundleIdentifier] returns nil during unit tests. Since RMStoreKeychainPersistence uses it as the keychain service value we have to swizzle it to return a value.
 */
@implementation NSBundle(bundleIdentifier)

- (NSString*)swizzled_bundleIdentifier
{
    return @"test";
}

+(void)load
{
    Method original = class_getInstanceMethod(self, @selector(bundleIdentifier));
    Method swizzle = class_getInstanceMethod(self, @selector(swizzled_bundleIdentifier));
    method_exchangeImplementations(original, swizzle);
}

@end

@interface RMStoreKeychainPersistenceTests : SenTestCase

@end

@implementation RMStoreKeychainPersistenceTests {
    RMStoreKeychainPersistence *_persistor;
}

- (void)setUp
{
    [super setUp];
    _persistor = [[RMStoreKeychainPersistence alloc] init];
}

- (void)tearDown
{
    [_persistor removeTransactions];
    [super tearDown];
}

- (void)testInitialState
{
    STAssertTrue([_persistor purchasedProductIdentifiers].count == 0, @"");
}

- (void)testPersistTransaction
{
    SKPaymentTransaction *transaction = [self mockTransactionOfProductIdentifer:@"test"];

    [_persistor persistTransaction:transaction];
    
    STAssertTrue([_persistor isPurchasedProductOfIdentifier:@"test"], @"");
}

- (void)testRemoveTransactions
{
    SKPaymentTransaction *transaction = [self mockTransactionOfProductIdentifer:@"test"];
    [self keychainPersistTransaction:transaction];
    
    [_persistor removeTransactions];
    
    STAssertFalse([_persistor isPurchasedProductOfIdentifier:@"test"], @"");
}

- (void)testConsumeProductOfIdentifier_YES
{
    SKPaymentTransaction *transaction = [self mockTransactionOfProductIdentifer:@"test"];
    [self keychainPersistTransaction:transaction];
    
    BOOL result = [_persistor consumeProductOfIdentifier:@"test"];
    
    STAssertTrue(result, @"");
}

- (void)testConsumeProductOfIdentifier_NO_inexistingProduct
{
    BOOL result = [_persistor consumeProductOfIdentifier:@"test"];
    STAssertFalse(result, @"");
}

- (void)testConsumeProductOfIdentifier_NO_alreadyConsumedProduct
{
    SKPaymentTransaction *transaction = [self mockTransactionOfProductIdentifer:@"test"];
    [self keychainPersistTransaction:transaction];
    
    [_persistor consumeProductOfIdentifier:@"test"];
    
    BOOL result = [_persistor consumeProductOfIdentifier:@"test"];
    STAssertFalse(result, @"");
}

- (void)testcountProductOfdentifier_zero
{
    STAssertTrue([_persistor countProductOfdentifier:@"test"] == 0, @"");
}

- (void)testcountProductOfdentifier_one
{
    SKPaymentTransaction *transaction = [self mockTransactionOfProductIdentifer:@"test"];
    [self keychainPersistTransaction:transaction];
    
    STAssertTrue([_persistor countProductOfdentifier:@"test"] == 1, @"");
}

- (void)testcountProductOfdentifier_many
{
    SKPaymentTransaction *transaction = [self mockTransactionOfProductIdentifer:@"test"];
    [_persistor persistTransaction:transaction];
    [_persistor persistTransaction:transaction];
    [_persistor persistTransaction:transaction];
    
    STAssertTrue([_persistor countProductOfdentifier:@"test"] == 3, @"");
}

- (void)testIsPurchasedProductOfIdentifier_YES
{
    SKPaymentTransaction *transaction = [self mockTransactionOfProductIdentifer:@"test"];
    [self keychainPersistTransaction:transaction];
    
    BOOL result = [_persistor isPurchasedProductOfIdentifier:@"test"];
    STAssertTrue(result, @"");
}

- (void)testIsPurchasedProductOfIdentifier_NO
{
    BOOL result = [_persistor isPurchasedProductOfIdentifier:@"test"];
    STAssertFalse(result, @"");
}

- (void)testPurchasedProductIdentifiers_empty
{
    NSSet *result = [_persistor purchasedProductIdentifiers];
    STAssertTrue(result.count == 0, @"");
}

- (void)testPurchasedProductIdentifiers_one
{
    SKPaymentTransaction *transaction = [self mockTransactionOfProductIdentifer:@"test"];
    [self keychainPersistTransaction:transaction];
    
    NSSet *result = [_persistor purchasedProductIdentifiers];
    STAssertTrue(result.count == 1, @"");
    STAssertEqualObjects([result anyObject], @"test", nil);
}

- (void)testPurchasedProductIdentifiers_many
{
    SKPaymentTransaction *transaction1 = [self mockTransactionOfProductIdentifer:@"test1"];
    [_persistor persistTransaction:transaction1];
    SKPaymentTransaction *transaction2 = [self mockTransactionOfProductIdentifer:@"test2"];
    [_persistor persistTransaction:transaction2];

    NSSet *result = [_persistor purchasedProductIdentifiers];

    STAssertTrue(result.count == 2, @"");
}

#pragma mark - Private

- (void)keychainPersistTransaction:(SKPaymentTransaction*)transaction
{
    NSDictionary *dictionary = @{transaction.payment.productIdentifier : @1};
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    RMKeychainSetValue(data, RMStoreTransactionsKeychainKey);
}

- (SKPaymentTransaction*)mockTransactionOfProductIdentifer:(NSString*)productIdentifier
{
    id transaction = [OCMockObject mockForClass:[SKPaymentTransaction class]];
    id payment = [OCMockObject mockForClass:[SKPayment class]];
    [[[payment stub] andReturn:productIdentifier] productIdentifier];
    [[[transaction stub] andReturn:payment] payment];

    return transaction;
}

@end
