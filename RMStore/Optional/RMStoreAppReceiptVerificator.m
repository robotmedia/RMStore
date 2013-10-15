//
//  RMStoreAppReceiptVerificator.m
//  RMStore
//
//  Created by Hermes on 10/15/13.
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

#import "RMStoreAppReceiptVerificator.h"
#import "RMAppReceipt.h"

static NSString *RMErroDomainStoreAppReceiptVerificator = @"RMStoreAppReceiptVerificator";

@implementation RMStoreAppReceiptVerificator

- (void)verifyReceiptOfTransaction:(SKPaymentTransaction*)transaction
                           success:(void (^)())successBlock
                           failure:(void (^)(NSError *error))failureBlock
{
    RMAppReceipt *receipt = [RMAppReceipt bundleReceipt];
    if (!receipt)
    {
        [[RMStore defaultStore] refreshReceiptOnSuccess:^{
            RMAppReceipt *receipt = [RMAppReceipt bundleReceipt];
            if (receipt)
            {
                [self verifyTransaction:transaction inReceipt:receipt success:successBlock failure:failureBlock];
            } else {
                NSError *error = [NSError errorWithDomain:RMErroDomainStoreAppReceiptVerificator code:0 userInfo:nil]; // TODO: Error message
                [self failWithBlock:failureBlock error:error];
            }
        } failure:^(NSError *error) {
            [self failWithBlock:failureBlock error:error];
        }];
    }
    [self verifyTransaction:transaction inReceipt:receipt success:successBlock failure:failureBlock];
}

- (BOOL)verifyAppReceipt
{
    RMAppReceipt *receipt = [RMAppReceipt bundleReceipt];
    return [self verifyAppReceipt:receipt];
}

#pragma mark - Properties

- (NSString*)bundleIdentifier
{
    if (!_bundleIdentifier)
    {
        return [[NSBundle mainBundle] bundleIdentifier];
    }
    return _bundleIdentifier;
}

- (NSString*)bundleVersion
{
    if (!_bundleVersion)
    {
        return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    }
    return _bundleVersion;
}

#pragma mark - Private

- (BOOL)verifyAppReceipt:(RMAppReceipt*)receipt
{
    if (!receipt)
    {
        return NO;
    }
    if (![receipt.bundleIdentifier isEqualToString:self.bundleIdentifier])
    {
        return NO;
    }
    if (![receipt.appVersion isEqualToString:self.bundleVersion])
    {
        return NO;
    }
    return YES;
}

- (void)verifyTransaction:(SKPaymentTransaction*)transaction
                inReceipt:(RMAppReceipt*)receipt
                           success:(void (^)())successBlock
                           failure:(void (^)(NSError *error))failureBlock
{
    const BOOL receiptVerified = [self verifyAppReceipt:receipt];
    if (!receiptVerified)
    {
        NSError *error = [NSError errorWithDomain:RMErroDomainStoreAppReceiptVerificator code:0 userInfo:nil]; // TODO: Error message
        [self failWithBlock:failureBlock error:error];
        return;
    }
    SKPayment *payment = transaction.payment;
    const BOOL transactionVerified = [receipt containsInAppPurchaseOfProductIdentifier:payment.productIdentifier];
    if (!transactionVerified)
    {
        NSError *error = [NSError errorWithDomain:RMErroDomainStoreAppReceiptVerificator code:0 userInfo:nil]; // TODO: Error message
        [self failWithBlock:failureBlock error:error];
    }
    if (successBlock)
    {
        successBlock();
    }
}

- (void)failWithBlock:(void (^)(NSError *error))failureBlock error:(NSError*)error
{
    if (failureBlock)
    {
        failureBlock(error);
    }
}

@end
