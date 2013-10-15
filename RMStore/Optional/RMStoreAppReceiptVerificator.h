//
//  RMStoreAppReceiptVerificator.h
//  RMStore
//
//  Created by Hermes on 10/15/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMStore.h"

@interface RMStoreAppReceiptVerificator : NSObject<RMStoreReceiptVerificator>

@property (nonatomic, strong) NSString *bundleIdentifier;
@property (nonatomic, strong) NSString *bundleVersion;

- (BOOL)verifyAppReceipt;

@end
