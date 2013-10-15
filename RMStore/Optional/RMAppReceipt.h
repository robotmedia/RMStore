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

/** Represents the app receipt.
 */
@interface RMAppReceipt : NSObject

/** The app’s bundle identifier. 
 
 This corresponds to the value of CFBundleIdentifier in the Info.plist file.
 */
@property (nonatomic, strong, readonly) NSString *bundleIdentifier;

/** The app’s version number. This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in OS X) in the Info.plist.
 */
@property (nonatomic, strong, readonly) NSString *appVersion;

/** An opaque value used as part of the SHA-1 hash.
 */
@property (nonatomic, strong, readonly) NSData *opaqueValue;

/** A SHA-1 hash, used to validate the receipt.
 */
@property (nonatomic, strong, readonly) NSData *hash;

/** Array of in-app purchases contained in the receipt.
 @see RMAppReceiptIAP
 */
@property (nonatomic, strong, readonly) NSArray *inAppPurchases;

/** The version of the app that was originally purchased. This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in OS X) in the Info.plist file when the purchase was originally made. In the sandbox environment, the value of this field is always “1.0”.
 */
@property (nonatomic, strong, readonly) NSString *originalAppVersion;

/** The date that the app receipt expires. Only for apps purchased through the Volume Purchase Program. If nil, the receipt does not expire. When validating a receipt, compare this date to the current date to determine whether the receipt is expired. Do not try to use this date to calculate any other information, such as the time remaining before expiration.
 */
@property (nonatomic, strong, readonly) NSDate *expirationDate;

/** Returns an initialized app receipt from the given data.
 @param asn1Data ASN1 data
 @returns An initialized app receipt from the given data.
 */
- (id)initWithASN1Data:(NSData*)asn1Data;

/** Returns whetever there is an in-app purchase in the receipt for the given product.
 @productIdentifier The identifier of the product.
 @returns YES if there is an in-app purchase for the given product, NO otherwise.
 */
- (BOOL)containsInAppPurchaseOfProductIdentifier:(NSString*)productIdentifier;

/**
 Returns the app receipt contained in the bundle, if any and valid. Extracts the receipt in ASN1 from the PKCS #7 container and then parses the ASN1 data into a RMAppReceipt instance.
 @returns The app receipt contained in the bundle, or nil if there is no receipt or if it is invalid.
 @see refreshReceipt
 */
+ (RMAppReceipt*)bundleReceipt;

@end

/** Represents an in-app purchase in the app receipt.
 */
@interface RMAppReceiptIAP : NSObject

/** The number of items purchased. This value corresponds to the quantity property of the SKPayment object stored in the transaction’s payment property.
 */
@property (nonatomic, readonly) NSInteger quantity;

/** The product identifier of the item that was purchased. This value corresponds to the productIdentifier property of the SKPayment object stored in the transaction’s payment property. 
 */
@property (nonatomic, strong, readonly) NSString *productIdentifier;

/**
 The transaction identifier of the item that was purchased. This value corresponds to the transaction’s transactionIdentifier property.
 */
@property (nonatomic, strong, readonly) NSString *transactionIdentifier;

/** For a transaction that restores a previous transaction, the transaction identifier of the original transaction. Otherwise, identical to the transaction identifier. 
 
 This value corresponds to the original transaction’s transactionIdentifier property. 
 
 All receipts in a chain of renewals for an auto-renewable subscription have the same value for this field.
 */
@property (nonatomic, strong, readonly) NSString *originalTransactionIdentifier;

/** The date and time that the item was purchased. This value corresponds to the transaction’s transactionDate property. 
 
 For a transaction that restores a previous transaction, the purchase date is the date of the restoration. Use `originalPurchaseDate` to get the date of the original transaction.
 
 In an auto-renewable subscription receipt, this is always the date when the subscription was purchased or renewed, regardles of whether the transaction has been restored
 */
@property (nonatomic, strong, readonly) NSDate *purchaseDate;

/** For a transaction that restores a previous transaction, the date of the original transaction.

 This value corresponds to the original transaction’s transactionDate property.
 
 In an auto-renewable subscription receipt, this indicates the beginning of the subscription period, even if the subscription has been renewed.
 */
@property (nonatomic, strong, readonly) NSDate *originalPurchaseDate;

/**
 The expiration date for the subscription. 
 
 Only present for auto-renewable subscription receipts.
 */
@property (nonatomic, strong, readonly) NSDate *subscriptionExpirationDate;

/** For a transaction that was canceled by Apple customer support, the date of the cancellation.
 */
@property (nonatomic, strong, readonly) NSDate *cancellationDate;

/** The primary key for identifying subscription purchases.
 */
@property (nonatomic, readonly) NSInteger webOrderLineItemID;

/** Returns an initialized in-app purchase from the given data.
 @param asn1Data ASN1 data
 @returns An initialized in-app purchase from the given data.
 */
- (id)initWithASN1Data:(NSData*)asn1Data;

@end
