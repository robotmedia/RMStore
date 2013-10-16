//
//  RMStoreUserDefaultsTransactionPersistor.m
//  RMStore
//
//  Created by Hermes on 10/16/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import "RMStoreUserDefaultsTransactionPersistor.h"

NSString* const RMStoreUserDefaultsKey = @"purchases";

@implementation RMStoreUserDefaultsTransactionPersistor

- (void)addTransaction:(SKPaymentTransaction*)paymentTransaction
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *purchases = [defaults objectForKey:RMStoreUserDefaultsKey] ? : [NSDictionary dictionary];
    
    SKPayment *payment = paymentTransaction.payment;
    NSString *productIdentifier = payment.productIdentifier;

    NSArray *transactions = [purchases objectForKey:productIdentifier] ? : @[];
    NSMutableArray *updatedTransactions = [NSMutableArray arrayWithArray:transactions];
    
    RMStoreTransaction *transaction = [[RMStoreTransaction alloc] initWithPaymentTransaction:paymentTransaction];
    NSData *data = [self dataWithTransaction:transaction];
    [updatedTransactions addObject:data];
    [self setTransactions:updatedTransactions forProductIdentifier:productIdentifier];
}

- (void)clearPurchases
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:RMStoreUserDefaultsKey];
    [defaults synchronize];
}

- (BOOL)consumeProductForIdentifier:(NSString*)productIdentifier
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *purchases = [defaults objectForKey:RMStoreUserDefaultsKey] ? : [NSDictionary dictionary];
    NSArray *transactions = [purchases objectForKey:productIdentifier] ? : @[];
    for (NSData *data in transactions)
    {
        RMStoreTransaction *transaction = [self transactionWithData:data];
        if (!transaction.consumed)
        {
            transaction.consumed = YES;
            NSData *updatedData = [self dataWithTransaction:transaction];
            NSMutableArray *updatedTransactions = [NSMutableArray arrayWithArray:transactions];
            NSInteger index = [updatedTransactions indexOfObject:data];
            [updatedTransactions replaceObjectAtIndex:index withObject:updatedData];
            [self setTransactions:updatedTransactions forProductIdentifier:productIdentifier];
            return YES;
        }
    }
    return NO;
}

- (NSInteger)countPurchasesForIdentifier:(NSString*)productIdentifier
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *purchases = [defaults objectForKey:RMStoreUserDefaultsKey];
    NSArray *transactions = [purchases objectForKey:productIdentifier];
    NSInteger count = 0;
    for (NSData *data in transactions)
    {
        RMStoreTransaction *transaction = [self transactionWithData:data];
        if (!transaction.consumed) { count++; }
    }
    return count;
}

- (BOOL)isPurchasedForIdentifier:(NSString*)productIdentifier
{
    return [self countPurchasesForIdentifier:productIdentifier] > 0;
}

- (NSArray*)purchasedProductIdentifiers
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *purchases = [defaults objectForKey:RMStoreUserDefaultsKey];
    return [purchases allKeys];
}

- (NSArray*)transactionsForProductIdentifier:(NSString*)productIdentifier
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *purchases = [defaults objectForKey:RMStoreUserDefaultsKey];
    NSArray *obfuscatedTransactions = [purchases objectForKey:productIdentifier] ? : @[];
    NSMutableArray *transactions = [NSMutableArray arrayWithCapacity:obfuscatedTransactions.count];
    for (NSData *data in obfuscatedTransactions)
    {
        RMStoreTransaction *transaction = [self transactionWithData:data];
        [transactions addObject:transaction];
    }
    return transactions;
}

#pragma mark - Private

- (NSData*)dataWithTransaction:(RMStoreTransaction*)transaction
{
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:transaction];
    [archiver finishEncoding];
    return data;
}

- (void)setTransactions:(NSArray*)transactions forProductIdentifier:(NSString*)productIdentifier
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *purchases = [defaults objectForKey:RMStoreUserDefaultsKey] ? : [NSDictionary dictionary];
    NSMutableDictionary *updatedPurchases = [NSMutableDictionary dictionaryWithDictionary:purchases];
    [updatedPurchases setObject:transactions forKey:productIdentifier];
    [defaults setObject:updatedPurchases forKey:RMStoreUserDefaultsKey];
    [defaults synchronize];
}

- (RMStoreTransaction*)transactionWithData:(NSData*)data
{
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    RMStoreTransaction *transaction = [unarchiver decodeObject];
    [unarchiver finishDecoding];
    return transaction;
}

@end
