//
//  RMAppReceipt.m
//  RMStore
//
//  Created by Hermes on 10/12/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import "RMAppReceipt.h"
#import "RMStore.h"

NSInteger const RMAppReceiptASN1TypeBundleIdentifier = 2;
NSInteger const RMAppReceiptASN1TypeAppVersion = 3;
NSInteger const RMAppReceiptASN1TypeOriginalAppVersion = 19;
NSInteger const RMAppReceiptASN1TypeExpirationDate = 21;

@interface RMAppReceipt()<RMStoreObserver>

@end

@implementation RMAppReceipt

static RMAppReceipt *_bundleReceipt = nil;

- (id)initWithURL:(NSURL *)URL
{
    if (self = [super init])
    {
        // TODO: Read receipt from url using OpenSSL
    }
    return self;
}

+ (RMAppReceipt*)bundleReceipt
{
    if (!_bundleReceipt)
    {
        NSURL *URL = [RMStore receiptURL];
        _bundleReceipt = [[RMAppReceipt alloc] initWithURL:URL];
        [[RMStore defaultStore] addStoreObserver:_bundleReceipt];
    }
    return _bundleReceipt;
}

#pragma mark - RMStoreObserver

- (void)storeRefreshReceiptFinished:(NSNotification *)notification
{
    [[RMStore defaultStore] removeStoreObserver:self];
    if (self == _bundleReceipt)
    {
        _bundleReceipt = nil;
    }
}

@end
