#RMStore
<!--- [![Build Status](https://travis-ci.org/robotmedia/RMStore.png)](https://travis-ci.org/robotmedia/RMStore) -->


A lightweight iOS library for In-App Purchases.

RMStore adds [blocks](https://github.com/robotmedia/RMStore/blob/master/README.md#storekit-with-blocks) and [notifications](https://github.com/robotmedia/RMStore/blob/master/README.md#notifications) to StoreKit, plus [receipt verification](https://github.com/robotmedia/RMStore/blob/master/README.md#receipt-verification) and [purchase management](https://github.com/robotmedia/RMStore/blob/master/README.md#purchase-management). All in one class without external dependencies. Purchasing a product is as simple as:

```objective-c
[[RMStore defaultStore] addPayment:productID success:^(SKPaymentTransaction *transaction) {
    NSLog(@"Purchased!");
} failure:^(SKPaymentTransaction *transaction, NSError *error) {
    NSLog(@"Something went wrong");
}];
```

##Add RMStore to your project

1. Add [`RMStore.h`](https://github.com/robotmedia/RMStore/blob/master/RMStore/RMStore.h) and [`RMStore.m`](https://github.com/robotmedia/RMStore/blob/master/RMStore/RMStore.m)
2. Link `StoreKit.framework`
3. Profit!

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

Call `successBlock` if the receipt passes verification, and `failureBlock` in any other case.

You will also need to set the `receiptVerificator` delegate at startup, as indicated above.

##Purchase management

RMStore stores transactions in `NSUserDefaults` with weak obfuscation and allows you to implement your own. It also offers various methods to query and manage purchases.

Below are the most common use cases related to purchases.

###Working with non-consumables

Non-consumables can only be purchased once. To know if a non-consumable has been purchased:

```objective-c
BOOL purchased = [[RMStore defaultStore] isPurchasedForIdentifier:@"fabulousIdol"];
```
###Working with consumables

Consumables can be purchased more than once and tipically will be consumed at most once per purchase. Here is how you would normally operate with a non-consumable:

```objective-c
NSInteger purchaseCount = [[RMStore defaultStore] countPurchasesForIdentifier:@"banana"];
if (purchaseCount > 0)
{
    BOOL success = [[RMStore defaultStore] consumeProductForIdentifier:@"banana"];
}
```

###Managing purchases manually

In some cases you might want to bypass payment with StoreKit and mark a product as purchased manually (e.g., for promotional purposes). You can do this with:

```objective-c
[[RMStore defaultStore] addPurchaseForProductIdentifier:@"breathMints"];
````

###Obfuscation

By default RMStore stores transactions in `NSUserDefaults` as objects using `NSCoding`, as a form of weak obfuscation. It is recommended to provide your own custom obfuscation by implementing the `RMStoreTransactionObfuscator` protocol and setting the `transactionObfuscator` delegate at startup.

You will be obfuscating `RMStoreTransaction` instances, an analogue of `SKPaymentTransaction` which supports `NSCopying`, unlike the original.

##Requirements

RMStore requires iOS 5.0 or above and ARC.

If you are using RMStore in your non-ARC project, you will need to set a `-fobjc-arc` compiler flag on all of the RMStore source files.

###For iOS 5.x

There is a known vulnerability in iOS 5.1 or lower related to app-side receipt verification. RMStore does not address this vulnerability. If you are using `RMStoreLocalReceiptVerificator` in iOS 5.x, please read this [technical note](https://developer.apple.com/library/ios/releasenotes/StoreKit/IAP_ReceiptValidation/index.html#//apple_ref/doc/uid/TP40012484
). 

##Roadmap

RMStore is in early stage and currently supports consumables and non-consumables only. Future enhancements will include:

* Content download support
* Subcriptions support
* OS X support

If you are looking for something more mature, check out [CargoBay](https://github.com/mattt/CargoBay) or [MKStoreKit](https://github.com/MugunthKumar/MKStoreKit).

##License

 Copyright 2013 [Robot Media SL](http://www.robotmedia.net)
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
