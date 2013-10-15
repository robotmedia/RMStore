//
//  RMAppReceipt.h
//  RMStore
//
//  Created by Hermes on 10/12/13.
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

#import <Foundation/Foundation.h>

@interface RMAppReceipt : NSObject

@property (nonatomic, strong, readonly) NSString *bundleIdentifier;
@property (nonatomic, strong, readonly) NSString *appVersion;
@property (nonatomic, strong, readonly) NSData *opaqueValue;
@property (nonatomic, strong, readonly) NSData *hash;
@property (nonatomic, strong, readonly) NSArray *inAppPurchases;
@property (nonatomic, strong, readonly) NSString *originalAppVersion;
@property (nonatomic, strong, readonly) NSDate *expirationDate;

- (id)initWithASN1Data:(NSData*)asn1Data;

- (BOOL)containsInAppPurchaseOfProductIdentifier:(NSString*)productIdentifier;

+ (RMAppReceipt*)bundleReceipt;

@end

@interface RMAppReceiptIAP : NSObject

@property (nonatomic, readonly) NSInteger quantity;
@property (nonatomic, strong, readonly) NSString *productIdentifier;
@property (nonatomic, strong, readonly) NSString *transactionIdentifier;
@property (nonatomic, strong, readonly) NSString *originalTransactionIdentifier;
@property (nonatomic, strong, readonly) NSDate *purchaseDate;
@property (nonatomic, strong, readonly) NSDate *originalPurchaseDate;
@property (nonatomic, strong, readonly) NSDate *subscriptionExpirationDate;
@property (nonatomic, strong, readonly) NSDate *cancellationDate;
@property (nonatomic, readonly) NSInteger webOrderLineItemID;

- (id)initWithASN1Data:(NSData*)asn1Data;

@end
