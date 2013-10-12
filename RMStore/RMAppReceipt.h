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
@property (nonatomic, strong, readonly) NSString *originalAppVersion;
@property (nonatomic, strong, readonly) NSDate *expirationDate;

- (id)initWithURL:(NSURL*)URL;

+ (RMAppReceipt*)bundleReceipt;

@end
