//
//  RMAppReceipt.h
//  RMStore
//
//  Created by Hermes on 10/12/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
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

- (id)initWithURL:(NSURL*)URL;

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

@end
