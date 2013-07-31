RMStore
=======

An iOS framework for In-App Purchases.

RMStore adds blocks and notifications to StoreKit, plus receipt verification and purchase management. Purchasing a product is as simple as:

    [[RMStore defaultStore] addPayment:productID success:^(SKPaymentTransaction *transaction) {
        NSLog(@"Purchased!", @"");
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        NSLog(@"Something went wrong", @"");
    }];

Add RMStore to your project
---------------------------

1. Add [`RMStore.h`](https://github.com/robotmedia/RMStore/blob/master/RMStore/RMStore.h) and [`RMStore.m`](https://github.com/robotmedia/RMStore/blob/master/RMStore/RMStore.m)
2. Link `StoreKit.framework`
3. Profit!

Requirements
------------

RMStore requires iOS 5.0 or above and ARC.

If you are using RMStore in your non-ARC project, you will need to set a `-fobjc-arc` compiler flag on all of the RMStore source files.

Roadmap
-------

RMStore currently supports consumables and non-consumables only. Future enhancements will include:

* Content download support
* Subcriptions support
* OS X support

License
-------

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
