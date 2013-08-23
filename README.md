#RMStore

An iOS framework for In-App Purchases.

RMStore adds blocks and notifications to StoreKit, plus receipt verification and purchase management. Purchasing a product is as simple as:

```objective-c
[[RMStore defaultStore] addPayment:productID success:^(SKPaymentTransaction *transaction) {
    NSLog(@"Purchased!", @"");
} failure:^(SKPaymentTransaction *transaction, NSError *error) {
    NSLog(@"Something went wrong", @"");
}];
```

##Add RMStore to your project

1. Add [`RMStore.h`](https://github.com/robotmedia/RMStore/blob/master/RMStore/RMStore.h) and [`RMStore.m`](https://github.com/robotmedia/RMStore/blob/master/RMStore/RMStore.m)
2. Link `StoreKit.framework`
3. Profit!

##Receipt verification

While RMStore doesn't perform receipt verification by default, you can provide your own custom verification or use the app-side verification provided by the framework.

###App-side verification

RMStore provides optional app-side receipt verification via `RMStoreLocalReceiptVerificator`. To use it, add [RMStoreLocalReceiptVerificator.h](https://github.com/robotmedia/RMStore/blob/master/RMStore/RMStoreLocalReceiptVerificator.h) and [RMStoreLocalReceiptVerificator.m](https://github.com/robotmedia/RMStore/blob/master/RMStore/RMStoreLocalReceiptVerificator.m) to your project and set the verification delegate (`receiptVerificator`) at startup. For example:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _receiptVerificator = [[RMStoreLocalReceiptVerificator alloc] init]; // Keep a reference to the verificator as the below property is weak
    [RMStore defaultStore].receiptVerificator = _receiptVerificator;
    // Your code
    return YES;
}
```

###Custom verification

Apple strongly recommends to use your own server-side verification. To do this, implement the `RMStoreReceiptVerificator` protocol:

```objective-c
- (void)verifyReceiptOfTransaction:(SKPaymentTransaction*)transaction
                           success:(void (^)())successBlock
                           failure:(void (^)(NSError *error))failureBlock;
```

In most cases you will call a web service that performs the same logic than `RMStoreLocalReceiptVerificator`, but on your server. Call `successBlock` if the receipt passes verification, and `failureBlock` in any other case.

You will also need to set the `receiptVerificator` delegate at startup, as indicated above.

##Requirements

RMStore requires iOS 5.0 or above and ARC.

If you are using RMStore in your non-ARC project, you will need to set a `-fobjc-arc` compiler flag on all of the RMStore source files.

##Roadmap

RMStore currently supports consumables and non-consumables only. Future enhancements will include:

* Content download support
* Subcriptions support
* OS X support

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
