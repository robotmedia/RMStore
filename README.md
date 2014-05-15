#RMStore
[![Build Status](https://travis-ci.org/robotmedia/RMStore.png)](https://travis-ci.org/robotmedia/RMStore)


A lightweight iOS library for In-App Purchases.

RMStore adds [blocks](https://github.com/robotmedia/RMStore/blob/master/README.md#storekit-with-blocks) and [notifications](https://github.com/robotmedia/RMStore/blob/master/README.md#notifications) to StoreKit, plus [receipt verification](https://github.com/robotmedia/RMStore/blob/master/README.md#receipt-verification), [content downloads](https://github.com/robotmedia/RMStore/blob/master/README.md#downloading-content) and [transaction persistence](https://github.com/robotmedia/RMStore/blob/master/README.md#transaction-persistence). All in one class without external dependencies. Purchasing a product is as simple as:

```objective-c
[[RMStore defaultStore] addPayment:productID success:^(SKPaymentTransaction *transaction) {
    NSLog(@"Purchased!");
} failure:^(SKPaymentTransaction *transaction, NSError *error) {
    NSLog(@"Something went wrong");
}];
```

##Installation

Using [CocoaPods](http://cocoapods.org/):

```ruby
pod "RMStore", "~> 0.5"
```

Or add the files from the [RMStore](https://github.com/robotmedia/RMStore/tree/master/RMStore) directory if you're doing it manually.

Check out the [wiki](https://github.com/robotmedia/RMStore/wiki/Installation) for more options. 

##StoreKit with blocks

RMStore adds blocks to all asynchronous StoreKit operations.

###Requesting products

```objective-c
NSSet *products = [NSSet setWithArray:@[@"fabulousIdol", @"rootBeer", @"rubberChicken"]];
[[RMStore defaultStore] requestProducts:products success:^(NSArray *products, NSArray *invalidProductIdentifiers) {
    NSLog(@"Products loaded");
} failure:^(NSError *error) {
    NSLog(@"Something went wrong");
}];
```

###Add payment

```objective-c
[[RMStore defaultStore] addPayment:@"waxLips" success:^(SKPaymentTransaction *transaction) {
    NSLog(@"Product purchased");
} failure:^(SKPaymentTransaction *transaction, NSError *error) {
    NSLog(@"Something went wrong");
}];
```

###Restore transactions

```objective-c
[[RMStore defaultStore] restoreTransactionsOnSuccess:^{
    NSLog(@"Transactions restored");
} failure:^(NSError *error) {
    NSLog(@"Something went wrong");
}];
```

###Refresh receipt (iOS 7+ only)

```objective-c
[[RMStore defaultStore] refreshReceiptOnSuccess:^{
    NSLog(@"Receipt refreshed");
} failure:^(NSError *error) {
    NSLog(@"Something went wrong");
}];
```

##Notifications

RMStore sends notifications of StoreKit related events and extends `NSNotification` to provide relevant information. To receive them, implement the desired methods of the `RMStoreObserver` protocol and add the observer to `RMStore`.

###Adding and removing the observer

```objective-c
[[RMStore defaultStore] addStoreObserver:self];
...
[[RMStore defaultStore] removeStoreObserver:self];
```

###Products request notifications

```objective-c
- (void)storeProductsRequestFailed:(NSNotification*)notification
{
    NSError *error = notification.storeError;
}

- (void)storeProductsRequestFinished:(NSNotification*)notification 
{
    NSArray *products = notification.products;
    NSArray *invalidProductIdentifiers = notification.invalidProductIdentififers;
}
```

###Payment transaction notifications

Payment transaction notifications are sent after a payment has been requested or for each restored transaction.

```objective-c
- (void)storePaymentTransactionFailed:(NSNotification*)notification
{
    NSError *error = notification.storeError;
    NSString *productIdentifier = notification.productIdentifier;
    SKPaymentTransaction *transaction = notification.transaction;
}

- (void)storePaymentTransactionFinished:(NSNotification*)notification
{
    NSString *productIdentifier = notification.productIdentifier;
    SKPaymentTransaction *transaction = notification.transaction;
}
```

###Restore transactions notifications

```objective-c
- (void)storeRestoreTransactionsFailed:(NSNotification*)notification;
{
    NSError *error = notification.storeError;
}

- (void)storeRestoreTransactionsFinished:(NSNotification*)notification { }
```

###Download notifications (iOS 6+ only)

For Apple-hosted and self-hosted downloads:

```objective-c
- (void)storeDownloadFailed:(NSNotification*)notification
{
	SKDownload *download = notification.storeDownload; // Apple-hosted only
    NSString *productIdentifier = notification.productIdentifier;
    SKPaymentTransaction *transaction = notification.transaction;
    NSError *error = notification.storeError;
}

- (void)storeDownloadFinished:(NSNotification*)notification;
{
	SKDownload *download = notification.storeDownload; // Apple-hosted only
    NSString *productIdentifier = notification.productIdentifier;
    SKPaymentTransaction *transaction = notification.transaction;
}

- (void)storeDownloadUpdated:(NSNotification*)notification
{
	SKDownload *download = notification.storeDownload; // Apple-hosted only
    NSString *productIdentifier = notification.productIdentifier;
    SKPaymentTransaction *transaction = notification.transaction;
	float progress = notification.download.progress;
}
```

Only for Apple-hosted downloads:

```objective-c
- (void)storeDownloadCanceled:(NSNotification*)notification
{
	SKDownload *download = notification.storeDownload;
    NSString *productIdentifier = notification.productIdentifier;
    SKPaymentTransaction *transaction = notification.transaction;
}

- (void)storeDownloadPaused:(NSNotification*)notification
{
	SKDownload *download = notification.storeDownload;
    NSString *productIdentifier = notification.productIdentifier;
    SKPaymentTransaction *transaction = notification.transaction;
}
```

###Refresh receipt notifications (iOS 7+ only)

```objective-c
- (void)storeRefreshReceiptFailed:(NSNotification*)notification;
{
    NSError *error = notification.storeError;
}

- (void)storeRefreshReceiptFinished:(NSNotification*)notification { }
```

##Receipt verification

RMStore doesn't perform receipt verification by default but provides reference implementations. You can implement your own custom verification or use the reference verificators provided by the library.

Both options are outlined below. For more info, check out the [wiki](https://github.com/robotmedia/RMStore/wiki/Receipt-verification). 

###Reference verificators

RMStore provides receipt verification via `RMStoreAppReceiptVerificator` (for iOS 7 or higher) and `RMStoreTransactionReceiptVerificator` (for iOS 6 or lower). To use any of them, add the corresponding files from [RMStore/Optional](https://github.com/robotmedia/RMStore/tree/master/RMStore/Optional) into your project and set the verificator delegate (`receiptVerificator`) at startup. For example:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    const BOOL iOS7OrHigher = floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1;
    _receiptVerificator = iOS7OrHigher ? [[RMStoreAppReceiptVerificator alloc] init] : [[RMStoreTransactionReceiptVerificator alloc] init];
    [RMStore defaultStore].receiptVerificator = _receiptVerificator;
    // Your code
    return YES;
}
```

If security is a concern you might want to avoid using an open source verification logic, and provide your own custom verificator instead.

###Custom verificator

RMStore delegates receipt verification, enabling you to provide your own implementation using  the `RMStoreReceiptVerificator` protocol:

```objective-c
- (void)verifyTransaction:(SKPaymentTransaction*)transaction
                           success:(void (^)())successBlock
                           failure:(void (^)(NSError *error))failureBlock;
```

Call `successBlock` if the receipt passes verification, and `failureBlock` if it doesn't. If verification could not be completed (e.g., due to connection issues), then `error` must be of code `RMStoreErrorCodeUnableToCompleteVerification` to prevent RMStore to finish the transaction.

You will also need to set the `receiptVerificator` delegate at startup, as indicated above.

##Downloading content

RMStore automatically downloads Apple-hosted content and provides a delegate for a self-hosted content.

###Apple-hosted content

Downloadable content hosted by Apple (`SKDownload`) will be automatically downloaded when purchasing o restoring a product. RMStore will notify observers of the download progress by calling `storeDownloadUpdate:` and finally `storeDownloadFinished:`. Additionally, RMStore notifies when downloads are paused, cancelled or have failed.

RMStore will notify that a transaction finished or failed only after all of its downloads have been processed. If you use blocks, they will called afterwards as well. The same applies to restoring transactions.

###Self-hosted content

RMStore delegates the downloading of self-hosted content via optional the `contentDownloader` delegate. You can provide your own implementation using the `RMStoreContentDownloader` protocol:

```objective-c
- (void)downloadContentForTransaction:(SKPaymentTransaction*)transaction
                              success:(void (^)())successBlock
                             progress:(void (^)(float progress))progressBlock
                              failure:(void (^)(NSError *error))failureBlock;
```

Call `successBlock` if the download is successful, `failureBlock` if it isn't and `progressBlock` to notify the download progress. RMStore will consider that a transaction has finished or failed only after the content downloader delegate has successfully or unsuccessfully downloaded its content.

##Transaction persistence

RMStore delegates transaction persistence and provides two optional reference implementations for storing transactions in the Keychain or in `NSUserDefaults`. You can implement your transaction, use the reference implementations provided by the library or, in the case of non-consumables and auto-renewable subscriptions, get the transactions directly from the receipt.

For more info, check out the [wiki](https://github.com/robotmedia/RMStore/wiki/Transaction-persistence).


##Requirements

RMStore requires iOS 5.0 or above and ARC. Some features are only available on iOS 6.0 and iOS 7.0.

##Roadmap

RMStore is in initial development and its public API should not be considered stable. Future enhancements will include:

* [Better OS X support](https://github.com/robotmedia/RMStore/issues/4)

##License

 Copyright 2013-2014 [Robot Media SL](http://www.robotmedia.net)
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
