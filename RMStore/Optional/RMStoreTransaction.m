//
//  RMStoreTransaction.m
//  RMStore
//
//  Created by Hermes on 10/16/13.
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

#import "RMStoreTransaction.h"

NSString* const RMStoreCoderConsumedKey = @"consumed";
NSString* const RMStoreCoderProductIdentifierKey = @"productIdentifier";
NSString* const RMStoreCoderTransactionDateKey = @"transactionDate";
NSString* const RMStoreCoderTransactionIdentifierKey = @"transactionIdentifier";

@implementation RMStoreTransaction

- (instancetype)initWithPaymentTransaction:(SKPaymentTransaction*)paymentTransaction
{
    if (self = [super init])
    {
        _productIdentifier = paymentTransaction.payment.productIdentifier;
        _transactionDate = paymentTransaction.transactionDate;
        _transactionIdentifier = paymentTransaction.transactionIdentifier;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init])
    {
        _consumed = [decoder decodeBoolForKey:RMStoreCoderConsumedKey];
        _productIdentifier = [decoder decodeObjectForKey:RMStoreCoderProductIdentifierKey];
        _transactionDate = [decoder decodeObjectForKey:RMStoreCoderTransactionDateKey];
        _transactionIdentifier = [decoder decodeObjectForKey:RMStoreCoderTransactionIdentifierKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeBool:self.consumed forKey:RMStoreCoderConsumedKey];
    [coder encodeObject:self.productIdentifier forKey:RMStoreCoderProductIdentifierKey];
    [coder encodeObject:self.transactionDate forKey:RMStoreCoderTransactionDateKey];
    if (self.transactionIdentifier != nil) {
        [coder encodeObject:self.transactionIdentifier forKey:RMStoreCoderTransactionIdentifierKey];
    }
}

@end
