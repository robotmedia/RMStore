//
//  RMStoreKeychainPersistence.m
//  RMStore
//
//  Created by Hermes on 10/19/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RMStoreKeychainPersistence.h"
#import <Security/Security.h>

NSString* const RMStoreTransactionsKeychainKey = @"RMStoreTransactions";

#pragma mark - Keychain

NSMutableDictionary* RMKeychainGetSearchDictionary(NSString *key)
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    NSData *encodedIdentifier = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    [dictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
    [dictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];
    
    NSString *serviceName = [NSBundle mainBundle].bundleIdentifier;
    [dictionary setObject:serviceName forKey:(__bridge id)kSecAttrService];
    
    return dictionary;
}

void RMKeychainSetValue(NSData *value, NSString *key)
{
    NSMutableDictionary *searchDictionary = RMKeychainGetSearchDictionary(key);
    OSStatus status;
    CFTypeRef ignore;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &ignore) == errSecSuccess)
    { // Update
        if (!value)
        {
            status = SecItemDelete((__bridge CFDictionaryRef)searchDictionary);
        } else {
            NSMutableDictionary *updateDictionary = [NSMutableDictionary dictionary];
            [updateDictionary setObject:value forKey:(__bridge id)kSecValueData];
            status = SecItemUpdate((__bridge CFDictionaryRef)searchDictionary, (__bridge CFDictionaryRef)updateDictionary);
        }
        NSCAssert(status == errSecSuccess, @"failed to update key %@ with error %ld.", key, status);
    }
    else if (value)
    { // Add
        [searchDictionary setObject:value forKey:(__bridge id)kSecValueData];
        status = SecItemAdd((__bridge CFDictionaryRef)searchDictionary, NULL);
        
        NSCAssert(status == errSecSuccess, @"failed to add key %@ with error %ld.", key, status);
    }
}

NSData* RMKeychainGetValue(NSString *key)
{
    NSMutableDictionary *searchDictionary = RMKeychainGetSearchDictionary(key);
    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    [searchDictionary setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    
    CFDataRef value = nil;
#if defined(NS_BLOCK_ASSERTIONS)
    SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, (CFTypeRef *)&value);
#else
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, (CFTypeRef *)&value);
    NSCAssert(status == errSecSuccess || status == errSecItemNotFound, @"failed to add key %@ with error %ld.", key, status);
#endif
    
    return (__bridge NSData*)value;
}

@implementation RMStoreKeychainPersistence {
    NSDictionary *_transactionsDictionary;
}

#pragma mark - RMStoreTransactionPersistor

- (void)persistTransaction:(SKPaymentTransaction*)paymentTransaction
{
    SKPayment *payment = paymentTransaction.payment;
    NSString *productIdentifier = payment.productIdentifier;
    NSDictionary *transactions = [self transactionsDictionary];
    NSInteger count = [[transactions objectForKey:productIdentifier] integerValue];
    count++;
    NSMutableDictionary *updatedTransactions = [NSMutableDictionary dictionaryWithDictionary:transactions];
    [updatedTransactions setObject:@(count) forKey:productIdentifier];
    [self setTransactionsDictionary:updatedTransactions];
}

#pragma mark - Public

- (void)removeTransactions
{
    [self setTransactionsDictionary:nil];
}

- (BOOL)consumeProductOfIdentifier:(NSString*)productIdentifier
{
    NSDictionary *transactions = [self transactionsDictionary];
    NSInteger count = [[transactions objectForKey:productIdentifier] integerValue];
    if (count > 0)
    {
        count--;
        NSMutableDictionary *updatedTransactions = [NSMutableDictionary dictionaryWithDictionary:transactions];
        [updatedTransactions setObject:@(count) forKey:productIdentifier];
        [self setTransactionsDictionary:updatedTransactions];
        return YES;
    } else {
        return NO;
    }
}

- (NSInteger)countProductOfdentifier:(NSString*)productIdentifier
{
    NSDictionary *transactions = [self transactionsDictionary];
    NSInteger count = [[transactions objectForKey:productIdentifier] integerValue];
    return count;
}

- (BOOL)isPurchasedProductOfIdentifier:(NSString*)productIdentifier
{
    NSDictionary *transactions = [self transactionsDictionary];
    return [transactions objectForKey:productIdentifier] != nil;
}

- (NSSet*)purchasedProductIdentifiers
{
    NSDictionary *transactions = [self transactionsDictionary];
    NSArray *productIdentifiers = [transactions allKeys];
    return [NSSet setWithArray:productIdentifiers];
}

#pragma mark - Private

- (NSDictionary*)transactionsDictionary
{
    if (_transactionsDictionary)
    { // Reading the keychain is slow so we cache its values in memory
        NSData *data = RMKeychainGetValue(RMStoreTransactionsKeychainKey);
        NSDictionary *transactions;
        if (data)
        {
            NSError *error;
            transactions = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            NSAssert(!error, [error localizedDescription]);
        } else {
            transactions = [NSDictionary dictionary];
        }
        _transactionsDictionary = transactions;
    }
    return _transactionsDictionary;
    
}

- (void)setTransactionsDictionary:(NSDictionary*)dictionary
{
    _transactionsDictionary = dictionary;
    NSData *data = nil;
    if (dictionary)
    {
        NSError *error;
        data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
        NSAssert(!error, [error localizedDescription]);
    }
    RMKeychainSetValue(data, RMStoreTransactionsKeychainKey);
}

@end
