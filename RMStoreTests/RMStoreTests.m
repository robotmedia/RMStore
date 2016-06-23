//
//  RMStoreTests.m
//  RMStoreTests
//
//  Created by Hermes Pique on 7/30/13.
//  Copyright (c) 2013 Robot Media SL (http://www.robotmedia.net)
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

#import <XCTest/XCTest.h>
#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>
#import <OCMock/OCMock.h>
#import "RMStore.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles" // To use ST macros in blocks

@interface RMStoreTests : XCTestCase<RMStoreObserver>

@end

@interface RMStoreContentDownloaderSuccess : NSObject<RMStoreContentDownloader>
@end

@interface RMStoreContentDownloaderProgress : NSObject<RMStoreContentDownloader>

@property (nonatomic, assign) float progress;

@end

@interface RMStoreContentDownloaderFailure : NSObject<RMStoreContentDownloader>

@property (nonatomic, strong) NSError *error;

@end

@interface RMStoreReceiptVerifierSuccess : NSObject<RMStoreReceiptVerifier>
@end

@interface RMStoreReceiptVerifierFailure : NSObject<RMStoreReceiptVerifier>
@end

@interface RMStoreReceiptVerifierUnableToComplete : NSObject<RMStoreReceiptVerifier>
@end

@interface RMStore(Private)

@property (nonatomic, readonly) NSMutableDictionary *products;

@end

@implementation RMStore(Private)

- (NSMutableDictionary*)products
{
    Ivar productsIvar = class_getInstanceVariable(self.class, "_products");
    return object_getIvar(self, productsIvar);
}

@end

@implementation RMStoreTests {
    RMStore *_store;
    id _observer;
}

- (void)setUp
{
    [super setUp];
    _store = [RMStore new];
    _observer = [OCMockObject mockForProtocol:@protocol(RMStoreObserver)];
}

- (void)tearDown
{
    [_store removeStoreObserver:_observer];
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(_store, @"");
    XCTAssertNil(_store.receiptVerifier, @"");
    XCTAssertNil(_store.transactionPersistor, @"");
}

- (void)testDealloc
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    @autoreleasepool { [[RMStore alloc] init]; }
#pragma clang diagnostic pop
}

- (void)testDefaultStore
{
    RMStore *store1 = [RMStore defaultStore];
    RMStore *store2 = [RMStore defaultStore];
    XCTAssertEqualObjects(store1, store2, @"");
}

#pragma mark StoreKit Wrapper

- (void)testCanMakePayments
{
    BOOL expected = [SKPaymentQueue canMakePayments];
    BOOL result = [RMStore canMakePayments];
    XCTAssertEqual(result, expected);
}

- (void)testAddPayment_UnknownProduct
{
    [_store addPayment:@"test"];
}

- (void)testAddPayment_KnownProduct
{
    
    static NSString *productIdentifier = @"test";
    id product = [OCMockObject mockForClass:[SKProduct class]];
    [[[product stub] andReturn:productIdentifier] productIdentifier];
    (_store.products)[productIdentifier] = product;
    [_store addPayment:productIdentifier];
}

- (void)testAddPayment_UnknownProduct_Nil_Nil
{
    [_store addPayment:@"test" success:nil failure:nil];
}

- (void)testAddPayment_UnknownProduct_Block_Block
{
    __block BOOL failureBlockCalled;
    [_store addPayment:@"test" success:^(SKPaymentTransaction *transaction) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warc-retain-cycles"
        XCTFail(@"Success block");
#pragma GCC diagnostic pop
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        failureBlockCalled = YES;
        XCTAssertNil(transaction, @"");
        XCTAssertEqual(error.code, RMStoreErrorCodeUnknownProductIdentifier, @"");
    }];
    XCTAssertTrue(failureBlockCalled, @"");
}

- (void)testAddPaymentUser
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    [_store addPayment:@"test" user:@"test" success:nil failure:nil];
}

- (void)testRequestProducts_One
{
    [_store requestProducts:[NSSet setWithObject:@"test"]];
}

- (void)testRequestProducts_One_Nil_Nil
{
    [_store requestProducts:[NSSet setWithObject:@"test"] success:nil failure:nil];
}

- (void)testRequestProducts_One_Block_Block
{
    [_store requestProducts:[NSSet setWithObject:@"test"] success:^(NSArray *products, NSArray *invalidProductIdentifiers) {
    } failure:^(NSError *error) {
    }];
}

- (void)testRestoreTransactions
{
    [_store restoreTransactions];
}

- (void)testRestoreTransactions_Nil_Nil
{
    [_store restoreTransactionsOnSuccess:nil failure:nil];
}

- (void)testRestoreTransactions_Block_Block
{
    [_store restoreTransactionsOnSuccess:^(NSArray *transactions){
    } failure:^(NSError *error) {
    }];
}

- (void)testRestoreTransactionsOfUser
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    
    [_store restoreTransactionsOfUser:@"test" onSuccess:nil failure:nil];
}

#pragma mark Receipt

- (void)testReceiptURL
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    
    NSURL *result = [RMStore receiptURL];
    NSURL *expected = [NSBundle mainBundle].appStoreReceiptURL;
    XCTAssertEqualObjects(result, expected, @"");
}

- (void)testRefreshReceipt
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    [_store refreshReceipt];
}

- (void)testRefreshReceipt_Nil_Nil
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    [_store refreshReceiptOnSuccess:nil failure:nil];
}

- (void)testRefreshReceipt_Block_Block
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    [_store refreshReceiptOnSuccess:^{} failure:^(NSError *error) {}];
}

#pragma mark Product management

- (void)testProductForIdentifierNil
{
    SKProduct *product = [_store productForIdentifier:@"test"];
    XCTAssertNil(product, @"");
}

- (void)testLocalizedPriceOfProduct
{
    id product = [OCMockObject mockForClass:[SKProduct class]];
    NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithString:@"1"];
    [[[product stub] andReturn:price] price];
    NSLocale *locale = [NSLocale currentLocale];
    [[[product stub] andReturn:locale] priceLocale];
    NSString *result = [RMStore localizedPriceOfProduct:product];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
	numberFormatter.locale = locale;
	NSString *expected = [numberFormatter stringFromNumber:price];
    
    XCTAssertEqualObjects(result, expected, @"");
}

#pragma mark Notifications

- (void)testAddStoreObserver
{
    [_store addStoreObserver:self];
}

- (void)testRemoveStoreObserver
{
    [_store addStoreObserver:self];
    [_store removeStoreObserver:self];
}

#pragma mark SKPaymentTransactionObserver

- (void)testPaymentQueueUpdatedDownloads_Empty
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_5_1)
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [_store paymentQueue:queue updatedDownloads:@[]];
}

- (void)testPaymentQueueUpdatedDownloads_Active
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_5_1)
    id download = [self mockDownloadWithState:SKDownloadStateActive];
    const float progress = 0.5f;
    [(SKDownload *)[[download stub] andReturnValue:OCMOCK_VALUE(progress)] progress];
    
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased downloads:@[download]];
    NSString *productID = [transaction payment].productIdentifier;
    
    [[_observer expect] storeDownloadUpdated:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        SKDownload *returnedDownload = notification.rm_storeDownload;
        SKPaymentTransaction *returnedTransaction = notification.rm_transaction;
        NSString *returnedProductID = notification.rm_productIdentifier;
        float downloadProgress = notification.rm_downloadProgress;
        XCTAssertEqualObjects(download, returnedDownload);
        XCTAssertEqualObjects(transaction, returnedTransaction);
        XCTAssertTrue([productID isEqualToString:returnedProductID]);
        XCTAssertEqual(downloadProgress, progress);
        return YES;
    }]];
    [_store addStoreObserver:_observer];
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    
    [_store paymentQueue:queue updatedDownloads:@[download]];
    
    [_observer verify];
}

- (void)testPaymentQueueUpdatedDownloads_Canceled__PurchasedTransaction_SingleDownload
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_5_1)
    id download = [self mockDownloadWithState:SKDownloadStateCancelled];
    
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased downloads:@[download]];
    NSString *productID = [transaction payment].productIdentifier;
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [[queue expect] finishTransaction:transaction];
    
    [self observer:_observer expectStoreDownloadCanceledWithDownload:download];
    [[_observer expect] storePaymentTransactionFailed:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        SKPaymentTransaction *returnedTransaction = notification.rm_transaction;
        NSString *returnedProductID = notification.rm_productIdentifier;
        NSError *error = notification.rm_storeError;
        XCTAssertNil(notification.rm_storeDownload);
        XCTAssertEqualObjects(transaction, returnedTransaction);
        XCTAssertTrue([productID isEqualToString:returnedProductID]);
        XCTAssertTrue([error.domain isEqualToString:RMStoreErrorDomain]);
        XCTAssertEqual(error.code, RMStoreErrorCodeDownloadCanceled);
        return YES;
    }]];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedDownloads:@[download]];
    
    [queue verify];
    [_observer verify];
}

- (void)testPaymentQueueUpdatedDownloads_Canceled__PurchasedTransaction_MultipleFinishedDownloads
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_5_1)
    id download = [self mockDownloadWithState:SKDownloadStateCancelled];
    id anotherDownload = [self mockDownloadWithState:SKDownloadStateFinished];
    
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased downloads:@[download, anotherDownload]];
    NSString *productID = [transaction payment].productIdentifier;
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [[queue expect] finishTransaction:transaction];
    
    [self observer:_observer expectStoreDownloadCanceledWithDownload:download];
    [[_observer expect] storePaymentTransactionFailed:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        SKPaymentTransaction *returnedTransaction = notification.rm_transaction;
        NSString *returnedProductID = notification.rm_productIdentifier;
        NSError *error = notification.rm_storeError;
        XCTAssertNil(notification.rm_storeDownload);
        XCTAssertEqualObjects(transaction, returnedTransaction);
        XCTAssertTrue([productID isEqualToString:returnedProductID]);
        XCTAssertTrue([error.domain isEqualToString:RMStoreErrorDomain]);
        XCTAssertEqual(error.code, RMStoreErrorCodeDownloadCanceled);
        return YES;
    }]];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedDownloads:@[download]];
    
    [queue verify];
    [_observer verify];
}

- (void)testPaymentQueueUpdatedDownloads_Canceled__PurchasedTransaction_PendingDownloads
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_5_1)
    id download = [self mockDownloadWithState:SKDownloadStateCancelled];
    id anotherDownload = [self mockDownloadWithState:SKDownloadStateWaiting];
    
    [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased downloads:@[download, anotherDownload]];
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    
    [self observer:_observer expectStoreDownloadCanceledWithDownload:download];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedDownloads:@[download]];
    
    [queue verify];
    [_observer verify];
}

- (void)testPaymentQueueUpdatedDownloads_Failed__PurchasedTransaction_SingleDownload
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_5_1)
    id download = [self mockDownloadWithState:SKDownloadStateFailed];
    NSError *error = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    [[[download stub] andReturn:error] error];
    
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased downloads:@[download]];
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [[queue expect] finishTransaction:transaction];
    
    [self observer:_observer expectStoreDownloadFailedWithDownload:download];
    [self observer:_observer expectStorePaymentTransactionFailedWithTransaction:transaction error:error];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedDownloads:@[download]];
    
    [queue verify];
    [_observer verify];
}

- (void)testPaymentQueueUpdatedDownloads_Failed__PurchasedTransaction_MutipleFinishedDownload
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_5_1)
    id download = [self mockDownloadWithState:SKDownloadStateFailed];
    NSError *error = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    [[[download stub] andReturn:error] error];
    
    id anotherDownload = [self mockDownloadWithState:SKDownloadStateFinished];
    
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased downloads:@[download, anotherDownload]];
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [[queue expect] finishTransaction:transaction];
    
    [self observer:_observer expectStoreDownloadFailedWithDownload:download];
    [self observer:_observer expectStorePaymentTransactionFailedWithTransaction:transaction error:error];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedDownloads:@[download]];
    
    [queue verify];
    [_observer verify];
}

- (void)testPaymentQueueUpdatedDownloads_Failed__PurchasedTransaction_PendingDownloads
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_5_1)
    id download = [self mockDownloadWithState:SKDownloadStateFailed];
    NSError *error = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    [[[download stub] andReturn:error] error];
    
    id anotherDownload = [self mockDownloadWithState:SKDownloadStateWaiting];
    
    [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased downloads:@[download, anotherDownload]];
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    
    [self observer:_observer expectStoreDownloadFailedWithDownload:download];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedDownloads:@[download]];
    
    [queue verify];
    [_observer verify];
}

- (void)testPaymentQueueUpdatedDownloads_Finished__PurchasedTransaction_SingleDownload
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_5_1)
    id download = [self mockDownloadWithState:SKDownloadStateFinished];
    
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased downloads:@[download]];

    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [[queue expect] finishTransaction:transaction];
    
    [self observer:_observer expectStoreDownloadFinishedWithDownload:download];
    [self observer:_observer expectStorePaymentTransactionFinishedWithTransaction:transaction];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedDownloads:@[download]];

    [queue verify];
    [_observer verify];
}

- (void)testPaymentQueueUpdatedDownloads_Finished__RestoredTransaction_SingleDownload
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_5_1)
    id download = [self mockDownloadWithState:SKDownloadStateFinished];
    
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStateRestored downloads:@[download]];
    id originalTransaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[[transaction stub] andReturn:originalTransaction] originalTransaction];
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [[queue stub] startDownloads:OCMOCK_ANY];
    [[queue expect] finishTransaction:transaction];
    
    [self observer:_observer expectStoreDownloadFinishedWithDownload:download];
    [self observer:_observer expectStorePaymentTransactionFinishedWithTransaction:transaction];
    [_store addStoreObserver:_observer];
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [_store paymentQueue:queue updatedDownloads:@[download]];
    
    [queue verify];
    [_observer verify];
}

- (void)testPaymentQueueUpdatedDownloads_Finished__RestoredTransaction_SingleDownload_RestoreCompletedTransactionsFinished
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_5_1)
    id download = [self mockDownloadWithState:SKDownloadStateFinished];
    
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStateRestored downloads:@[download]];
    id originalTransaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[[transaction stub] andReturn:originalTransaction] originalTransaction];
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [[queue stub] startDownloads:OCMOCK_ANY];
    [[queue expect] finishTransaction:transaction];
    
    [self observer:_observer expectStoreDownloadFinishedWithDownload:download];
    [self observer:_observer expectStorePaymentTransactionFinishedWithTransaction:transaction];
    [[_observer expect] storeRestoreTransactionsFinished:OCMOCK_ANY];
    [_store addStoreObserver:_observer];
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    [_store paymentQueueRestoreCompletedTransactionsFinished:queue];
    
    [_store paymentQueue:queue updatedDownloads:@[download]];
    
    [queue verify];
    [_observer verify];
}


- (void)testPaymentQueueUpdatedDownloads_Finished__PurchasedTransaction_MultipleFinishedDownloads
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_5_1)
    id download = [self mockDownloadWithState:SKDownloadStateFinished];
    id anotherDownload = [self mockDownloadWithState:SKDownloadStateFinished];
    
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased downloads:@[download, anotherDownload]];
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [[queue expect] finishTransaction:transaction];
    
    [self observer:_observer expectStoreDownloadFinishedWithDownload:download];
    [self observer:_observer expectStorePaymentTransactionFinishedWithTransaction:transaction];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedDownloads:@[download]];
    
    [queue verify];
    [_observer verify];
}

- (void)testPaymentQueueUpdatedDownloads_Finished__PurchasedTransaction_PendingDownloads
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_5_1)
    id download = [self mockDownloadWithState:SKDownloadStateFinished];
    id anotherDownload = [self mockDownloadWithState:SKDownloadStateWaiting];
    
    [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased downloads:@[download, anotherDownload]];
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    
    [self observer:_observer expectStoreDownloadFinishedWithDownload:download];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedDownloads:@[download]];
    
    [queue verify];
    [_observer verify];
}

- (void)testPaymentQueueUpdatedDownloads_Paused
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_5_1)
    id download = [self mockDownloadWithState:SKDownloadStatePaused];
    
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased downloads:@[download]];
    NSString *productID = [transaction payment].productIdentifier;
    
    [[_observer expect] storeDownloadPaused:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        SKDownload *returnedDownload = notification.rm_storeDownload;
        SKPaymentTransaction *returnedTransaction = notification.rm_transaction;
        NSString *returnedProductID = notification.rm_productIdentifier;
        XCTAssertEqualObjects(download, returnedDownload);
        XCTAssertEqualObjects(transaction, returnedTransaction);
        XCTAssertTrue([productID isEqualToString:returnedProductID]);
        return YES;
    }]];
    [_store addStoreObserver:_observer];

    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    
    [_store paymentQueue:queue updatedDownloads:@[download]];
    
    [_observer verify];
}

- (void)testPaymentQueueUpdatedDownloads_Waiting
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_5_1)
    id download = [self mockDownloadWithState:SKDownloadStateWaiting];
    [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased downloads:@[download]];
    
    [_store addStoreObserver:_observer];

    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    
    [_store paymentQueue:queue updatedDownloads:@[download]];
}

- (void)testPaymentQueueUpdatedTransactions_Empty
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [_store paymentQueue:queue updatedTransactions:@[]];
}

- (void)testPaymentQueueUpdatedTransactions_Purchased__NoVerifier_NoDownloader
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[queue expect] finishTransaction:transaction];

    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [queue verify];
}

- (void)testPaymentQueueUpdatedTransactions_Purchased__NoVerifier_DownloaderSuccess
{
    id downloader = [RMStoreContentDownloaderSuccess new];
    _store.contentDownloader = downloader;
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[queue expect] finishTransaction:transaction];

    [_store addStoreObserver:_observer];
    [self observer:_observer expectStoreDownloadFinishedWithTransaction:transaction];
    [self observer:_observer expectStorePaymentTransactionFinishedWithTransaction:transaction];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [queue verify];
    [_observer verify];
}

- (void)testPaymentQueueUpdatedTransactions_Purchased__NoVerifier_DownloaderProgress
{
    RMStoreContentDownloaderProgress *downloader = [RMStoreContentDownloaderProgress new];
    downloader.progress = 0.5;
    _store.contentDownloader = downloader;
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    NSString *productID = [transaction payment].productIdentifier;

    [[_observer expect] storeDownloadUpdated:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        SKPaymentTransaction *returnedTransaction = notification.rm_transaction;
        NSString *returnedProductID = notification.rm_productIdentifier;
        float downloadProgress = notification.rm_downloadProgress;
        XCTAssertEqualObjects(transaction, returnedTransaction);
        XCTAssertTrue([productID isEqualToString:returnedProductID]);
        XCTAssertTrue(downloader.progress == downloadProgress);
        return YES;
    }]];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [_observer verify];
}

- (void)testPaymentQueueUpdatedTransactions_Purchased__NoVerifier_DownloaderFailure
{
    RMStoreContentDownloaderFailure *downloader = [RMStoreContentDownloaderFailure new];
    downloader.error = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    _store.contentDownloader = downloader;
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[queue expect] finishTransaction:transaction];
    
    [_store addStoreObserver:_observer];
    [self observer:_observer expectStoreDownloadFailedWithTransaction:transaction error:downloader.error];
    [self observer:_observer expectStorePaymentTransactionFailedWithTransaction:transaction error:downloader.error];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [_observer verify];
}

- (void)testPaymentQueueUpdatedTransactions_PurchasedWithDownloads
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id download = [self mockDownloadWithState:SKDownloadStateWaiting];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased downloads:@[download]];
    [[queue expect] startDownloads:[OCMArg checkWithBlock:^BOOL(NSArray *returnedDownloads) {
        return [returnedDownloads containsObject:download];
    }]];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [queue verify];
}

- (void)testPaymentQueueUpdatedTransactions_Purchased__NoVerifier_Blocks
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id originalTransaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[queue stub] finishTransaction:[OCMArg any]];

    id product = [OCMockObject mockForClass:[SKProduct class]];
    [[[product stub] andReturn:@"test"] productIdentifier];
    (_store.products)[@"test"] = product;
    [_store addPayment:@"test" success:^(SKPaymentTransaction *transaction) {
       XCTAssertEqualObjects(transaction, originalTransaction, @"");
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        XCTFail(@"");
    }];
    
    [_store paymentQueue:queue updatedTransactions:@[originalTransaction]];
}

- (void)testPaymentQueueUpdatedTransactions_Purchased__VerifierSuccess
{
    id verifier = [RMStoreReceiptVerifierSuccess new];
    _store.receiptVerifier = verifier;
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[queue expect] finishTransaction:transaction];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [queue verify];
}

- (void)testPaymentQueueUpdatedTransactions_Purchased__VerifierFailure
{
    id verifier = [RMStoreReceiptVerifierFailure new];
    _store.receiptVerifier = verifier;
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[queue expect] finishTransaction:transaction];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [queue verify];
}

- (void)testPaymentQueueUpdatedTransactions_Purchased__VerifierUnableToComplete
{
    id verifier = [[RMStoreReceiptVerifierUnableToComplete alloc] init];
    _store.receiptVerifier = verifier;
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
}

- (void)testPaymentQueueUpdatedTransactions_Restored__NoVerifier_NoDownloader
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockRestoredPaymentTransaction];
    [[queue stub] finishTransaction:[OCMArg any]];
    [[_observer expect] storePaymentTransactionFinished:[OCMArg isNotNil]];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [_observer verify];
}

- (void)testPaymentQueueUpdatedTransactions_Restored__NoVerifier_DownloaderSuccess
{
    id downloader = [RMStoreContentDownloaderSuccess new];
    _store.contentDownloader = downloader;
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStateRestored];
    id originalTransaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[[transaction stub] andReturn:originalTransaction] originalTransaction];
    [[queue expect] finishTransaction:transaction];
    
    [_store addStoreObserver:_observer];
    [self observer:_observer expectStoreDownloadFinishedWithTransaction:transaction];
    [self observer:_observer expectStorePaymentTransactionFinishedWithTransaction:transaction];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [queue verify];
    [_observer verify];
}

- (void)testPaymentQueueUpdatedTransactions_Restored__NoVerifier_DownloaderProgress
{
    RMStoreContentDownloaderProgress *downloader = [RMStoreContentDownloaderProgress new];
    downloader.progress = 0.5;
    _store.contentDownloader = downloader;
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStateRestored];
    id originalTransaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[[transaction stub] andReturn:originalTransaction] originalTransaction];
    NSString *productID = [transaction payment].productIdentifier;
    
    [[_observer expect] storeDownloadUpdated:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        SKPaymentTransaction *returnedTransaction = notification.rm_transaction;
        NSString *returnedProductID = notification.rm_productIdentifier;
        float downloadProgress = notification.rm_downloadProgress;
        XCTAssertEqualObjects(transaction, returnedTransaction);
        XCTAssertTrue([productID isEqualToString:returnedProductID]);
        XCTAssertTrue(downloader.progress == downloadProgress);
        return YES;
    }]];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [_observer verify];
}

- (void)testPaymentQueueUpdatedTransactions_Restored__NoVerifier_DownloaderFailure
{
    RMStoreContentDownloaderFailure *downloader = [RMStoreContentDownloaderFailure new];
    downloader.error = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    _store.contentDownloader = downloader;
    
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockRestoredPaymentTransaction];
    [[queue expect] finishTransaction:transaction];
    
    [_store addStoreObserver:_observer];
    [self observer:_observer expectStoreDownloadFailedWithTransaction:transaction error:downloader.error];
    [self observer:_observer expectStorePaymentTransactionFailedWithTransaction:transaction error:downloader.error];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [_observer verify];
}

- (void)testPaymentQueueUpdatedTransactions_RestoredWithDownloads
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id download = [self mockDownloadWithState:SKDownloadStateWaiting];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStateRestored downloads:@[download]];
    id originalTransaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[[transaction stub] andReturn:originalTransaction] originalTransaction];
    [[queue expect] startDownloads:[OCMArg checkWithBlock:^BOOL(NSArray *returnedDownloads) {
        return [returnedDownloads containsObject:download];
    }]];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [queue verify];
}

- (void)testPaymentQueueUpdatedTransactions_Restored__storeRestoreTransactionsFinished
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockRestoredPaymentTransaction];
    [[queue stub] finishTransaction:[OCMArg any]];
    [_store paymentQueueRestoreCompletedTransactionsFinished:queue];
    [[_observer expect] storePaymentTransactionFinished:[OCMArg isNotNil]];
    [[_observer expect] storeRestoreTransactionsFinished:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertEqualObjects(notification.rm_transactions, @[transaction]);
        return YES;
    }]];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];

    [_observer verify];
}

- (void)testPaymentQueueUpdatedTransactions_Restored__Twice
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockRestoredPaymentTransaction];
    [[queue stub] finishTransaction:[OCMArg any]];
    [_store restoreTransactions];
    [_store paymentQueueRestoreCompletedTransactionsFinished:queue];
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    [_store restoreTransactions];
    [[_observer expect] storePaymentTransactionFinished:[OCMArg isNotNil]];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [_observer verify];
}

- (void)testPaymentQueueUpdatedTransactions_Restored__VerifierSuccess
{
    id verifier = [[RMStoreReceiptVerifierSuccess alloc] init];
    _store.receiptVerifier = verifier;
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockRestoredPaymentTransaction];
    [[queue stub] finishTransaction:[OCMArg any]];
    [[_observer expect] storePaymentTransactionFinished:[OCMArg isNotNil]];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [_observer verify];
}

- (void)testPaymentQueueUpdatedTransactions_Restored__VerifierFailure
{
    id verifier = [[RMStoreReceiptVerifierFailure alloc] init];
    _store.receiptVerifier = verifier;
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockRestoredPaymentTransaction];
    [[queue stub] finishTransaction:[OCMArg any]];
    [[_observer expect] storePaymentTransactionFailed:[OCMArg isNotNil]];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];

    [_observer verify];
}

- (void)testPaymentQueueUpdatedTransactions_Failed
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [[queue stub] finishTransaction:[OCMArg any]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStateFailed];
    [[[transaction stub] andReturn:[NSError errorWithDomain:@"test" code:0 userInfo:nil]] error];
    [[_observer expect] storePaymentTransactionFailed:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertNotNil(notification.rm_storeError, @"");
        return YES;
    }]];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [_observer verify];
}

- (void)testPaymentQueueUpdatedTransactions_Failed__Blocks
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id originalTransaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStateFailed];
    NSError *originalError = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    [[[originalTransaction stub] andReturn:originalError] error];
    [[queue stub] finishTransaction:[OCMArg any]];

    id product = [OCMockObject mockForClass:[SKProduct class]];
    [[[product stub] andReturn:@"test"] productIdentifier];
    (_store.products)[@"test"] = product;
    [_store addPayment:@"test" success:^(SKPaymentTransaction *transaction) {
        XCTFail(@"");
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        XCTAssertEqualObjects(transaction, originalTransaction, @"");
        XCTAssertEqualObjects(error, originalError, @"");
    }];
    
    [_store paymentQueue:queue updatedTransactions:@[originalTransaction]];
}

- (void)testPaymentQueueUpdatedTransactions_Deferred
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_7_1)
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStateDeferred];
    [[_observer expect] storePaymentTransactionDeferred:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertEqualObjects(notification.rm_productIdentifier, [[transaction payment] productIdentifier], @"");
        XCTAssertEqualObjects(notification.rm_transaction, transaction, @"");
        return YES;
    }]];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueue:queue updatedTransactions:@[transaction]];
    
    [_observer verify];
}

- (void)testPaymentQueueRestoreCompletedTransactionsFinished
{
    [[_observer expect] storeRestoreTransactionsFinished:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertEqualObjects(notification.rm_transactions, @[]);
        return YES;
    }]];
    [_store addStoreObserver:_observer];
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];

    [_store paymentQueueRestoreCompletedTransactionsFinished:queue];

    [_observer verify];
}

- (void)testPaymentQueueRestoreCompletedTransactionsFinished_Queue__Blocks
{
    [[_observer expect] storeRestoreTransactionsFinished:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertEqualObjects(notification.rm_transactions, @[]);
        return YES;
    }]];
    [_store addStoreObserver:_observer];
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    __block BOOL didSucceed = NO;
    [_store restoreTransactionsOnSuccess:^(NSArray* transactions) {
        didSucceed = YES;
        XCTAssertEqualObjects(transactions, @[], @"");
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    [_store paymentQueueRestoreCompletedTransactionsFinished:queue];
    
    [_observer verify];
    XCTAssertTrue(didSucceed, @"");
}

- (void)testPaymentQueueRestoreCompletedTransactionsFinished_Queue__TwoTransactions_storeRestoreTransactionsFinished
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [[queue stub] finishTransaction:[OCMArg any]];
    id transaction1 = [self mockRestoredPaymentTransaction];
    id transaction2 = [self mockRestoredPaymentTransaction];
    NSArray *updatedTransactions = @[transaction1, transaction2];
    [_store paymentQueue:queue updatedTransactions:updatedTransactions];
    [[_observer expect] storeRestoreTransactionsFinished:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertEqualObjects(notification.rm_transactions, updatedTransactions, @"");
        return YES;
    }]];
    [_store addStoreObserver:_observer];
    
    [_store paymentQueueRestoreCompletedTransactionsFinished:queue];
    
    [_observer verify];
}

- (void)testPaymentQueueRestoreCompletedTransactionsFinished_Queue__TwoTransactions_restoreTransactionsOnSuccess_SuccessBlock
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [[queue stub] finishTransaction:[OCMArg any]];
    id transaction1 = [self mockRestoredPaymentTransaction];
    id transaction2 = [self mockRestoredPaymentTransaction];
    NSArray *updatedTransactions = @[transaction1, transaction2];
    [_store restoreTransactionsOnSuccess:^(NSArray* transactions) {
        XCTAssertEqualObjects(transactions, updatedTransactions, @"");
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    [_store paymentQueue:queue updatedTransactions:@[transaction1, transaction2]];
    
    [_store paymentQueueRestoreCompletedTransactionsFinished:queue];
}

- (void)testPaymentQueueRestoreCompletedTransactionsFinished_Queue__TwoTransactions_restoreTransactionsOfUser_SuccessBlock
{
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [[queue stub] finishTransaction:[OCMArg any]];
    id transaction1 = [self mockRestoredPaymentTransaction];
    id transaction2 = [self mockRestoredPaymentTransaction];
    NSArray *updatedTransactions = @[transaction1, transaction2];
    [_store restoreTransactionsOfUser:self.name onSuccess:^(NSArray* transactions) {
        XCTAssertEqualObjects(transactions, updatedTransactions, @"");
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    [_store paymentQueue:queue updatedTransactions:@[transaction1, transaction2]];
    
    [_store paymentQueueRestoreCompletedTransactionsFinished:queue];
}

- (void)testPaymentQueueRestoreCompletedTransactionsFailedWithError_Queue_Error
{
    NSError *originalError = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    [[_observer expect] storeRestoreTransactionsFailed:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertEqualObjects(notification.rm_storeError, originalError, @"");
        return YES;
    }]];
    [_store addStoreObserver:_observer];
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];

    [_store paymentQueue:queue restoreCompletedTransactionsFailedWithError:originalError];

    [_observer verify];
}

- (void)testPaymentQueueRestoreCompletedTransactionsFailedWithError_Queue_Error__Blocks
{
    NSError *originalError = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    [[_observer expect] storeRestoreTransactionsFailed:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertEqualObjects(notification.rm_storeError, originalError, @"");
        return YES;
    }]];
    [_store addStoreObserver:_observer];
    id queue = [OCMockObject mockForClass:[SKPaymentQueue class]];
    [_store restoreTransactionsOnSuccess:^(NSArray* transactions){
        XCTFail(@"");
    } failure:^(NSError *error) {
        XCTAssertEqualObjects(error, originalError, @"");
    }];
    
    [_store paymentQueue:queue restoreCompletedTransactionsFailedWithError:originalError];

    [_observer verify];
}

#pragma mark SKRequestDelegate

- (void)testRequestDidFinish_noBlocks
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    [[_observer expect] storeRefreshReceiptFinished:[OCMArg isNotNil]];
    [_store addStoreObserver:_observer];
    
    id store = _store;
    id requestMock = [OCMockObject mockForClass:[SKRequest class]];
    [store requestDidFinish:requestMock];
    
    [_observer verify];
}

- (void)testRequestDidFailWithError_noBlocks
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    NSError *originalError = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    [[_observer expect] storeRefreshReceiptFailed:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertEqualObjects(notification.rm_storeError, originalError, @"");
        return YES;
    }]];
    [_store addStoreObserver:_observer];

    id store = _store;
    id requestMock = [OCMockObject mockForClass:[SKRequest class]];

    [store request:requestMock didFailWithError:originalError];
    
    [_observer verify];
}

- (void)testRequestDidFinish_withBlocks
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    [[_observer expect] storeRefreshReceiptFinished:[OCMArg isNotNil]];
    [_store addStoreObserver:_observer];
    __block BOOL executed = NO;
    [_store refreshReceiptOnSuccess:^{
        executed = YES;
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];

    id store = _store;
    id requestMock = [OCMockObject mockForClass:[SKRequest class]];
    [store requestDidFinish:requestMock];
    
    [_observer verify];
    XCTAssertTrue(executed, @"");
}

- (void)testRequestDidFailWithError_withBlocks
{ SKIP_IF_VERSION(NSFoundationVersionNumber_iOS_6_1)
    NSError *originalError = [NSError errorWithDomain:@"test" code:0 userInfo:nil];
    [[_observer expect] storeRefreshReceiptFailed:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertEqualObjects(notification.rm_storeError, originalError, @"");
        return YES;
    }]];
    [_store addStoreObserver:_observer];
    __block BOOL executed = NO;
    [_store refreshReceiptOnSuccess:^{
        XCTFail(@"");
    } failure:^(NSError *error) {
        executed = YES;
        XCTAssertEqualObjects(error, originalError, @"");
    }];

    
    id store = _store;
    id requestMock = [OCMockObject mockForClass:[SKRequest class]];
    
    [store request:requestMock didFailWithError:originalError];
    
    [_observer verify];
    XCTAssertTrue(executed, @"");
}

#pragma mark Private

- (void)observer:(id)observer expectStoreDownloadFailedWithDownload:(SKDownload*)download
{
    NSError *error = download.error;
    SKPaymentTransaction *transaction = download.transaction;
    NSString *productID = transaction.payment.productIdentifier;
    [[observer expect] storeDownloadFailed:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertEqualObjects(download, notification.rm_storeDownload);
        XCTAssertEqualObjects(transaction, notification.rm_transaction);
        XCTAssertTrue([productID isEqualToString:notification.rm_productIdentifier]);
        XCTAssertEqualObjects(error, notification.rm_storeError);
        return YES;
    }]];
}

- (void)observer:(id)observer expectStoreDownloadFailedWithTransaction:(SKPaymentTransaction*)transaction error:(NSError*)error
{
    NSString *productID = transaction.payment.productIdentifier;
    [[observer expect] storeDownloadFailed:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertNil(notification.rm_storeDownload);
        XCTAssertEqualObjects(transaction, notification.rm_transaction);
        XCTAssertTrue([productID isEqualToString:notification.rm_productIdentifier]);
        XCTAssertEqualObjects(error, notification.rm_storeError);
        return YES;
    }]];
}

- (void)observer:(id)observer expectStoreDownloadFinishedWithDownload:(SKDownload*)download
{
    SKPaymentTransaction *transaction = download.transaction;
    NSString *productID = transaction.payment.productIdentifier;
    [[observer expect] storeDownloadFinished:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertEqualObjects(download, notification.rm_storeDownload);
        XCTAssertEqualObjects(transaction, notification.rm_transaction);
        XCTAssertTrue([productID isEqualToString:notification.rm_productIdentifier]);
        XCTAssertNil(notification.rm_storeError);
        return YES;
    }]];
}

- (void)observer:(id)observer expectStoreDownloadFinishedWithTransaction:(SKPaymentTransaction*)transaction
{
    NSString *productID = transaction.payment.productIdentifier;
    [[observer expect] storeDownloadFinished:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertNil(notification.rm_storeDownload);
        XCTAssertEqualObjects(transaction, notification.rm_transaction);
        XCTAssertTrue([productID isEqualToString:notification.rm_productIdentifier]);
        XCTAssertNil(notification.rm_storeError);
        return YES;
    }]];
}


- (void)observer:(id)observer expectStoreDownloadCanceledWithDownload:(SKDownload*)download
{
    SKPaymentTransaction *transaction = download.transaction;
    NSString *productID = transaction.payment.productIdentifier;
    [[observer expect] storeDownloadCanceled:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertEqualObjects(download, notification.rm_storeDownload);
        XCTAssertEqualObjects(transaction, notification.rm_transaction);
        XCTAssertTrue([productID isEqualToString:notification.rm_productIdentifier]);
        XCTAssertNil(notification.rm_storeError);
        return YES;
    }]];
}

- (void)observer:(id)observer expectStorePaymentTransactionFailedWithTransaction:(SKPaymentTransaction *)transaction error:(NSError*)error
{
    NSString *productID = transaction.payment.productIdentifier;
    [[observer expect] storePaymentTransactionFailed:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertNil(notification.rm_storeDownload);
        XCTAssertEqualObjects(transaction, notification.rm_transaction);
        XCTAssertTrue([productID isEqualToString:notification.rm_productIdentifier]);
        XCTAssertEqualObjects(error, notification.rm_storeError);
        return YES;
    }]];
}

- (void)observer:(id)observer expectStorePaymentTransactionFinishedWithTransaction:(SKPaymentTransaction *)transaction
{
    NSString *productID = transaction.payment.productIdentifier;
    [[observer expect] storePaymentTransactionFinished:[OCMArg checkWithBlock:^BOOL(NSNotification *notification) {
        XCTAssertNil(notification.rm_storeDownload);
        XCTAssertEqualObjects(transaction, notification.rm_transaction);
        XCTAssertTrue([productID isEqualToString:notification.rm_productIdentifier]);
        XCTAssertNil(notification.rm_storeError);
        return YES;
    }]];
}

- (id)mockDownloadWithState:(SKDownloadState)state
{
    id download = [OCMockObject mockForClass:[SKDownload class]];
    [[[download stub] andReturn:@"content"] contentIdentifier];
    [[[download stub] andReturnValue:@(state)] downloadState];
    return download;
}

- (id)mockPaymentTransactionWithState:(SKPaymentTransactionState)state
{
    return [self mockPaymentTransactionWithState:state downloads:@[]];
}

- (id)mockRestoredPaymentTransaction
{
    id transaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStateRestored];
    id originalTransaction = [self mockPaymentTransactionWithState:SKPaymentTransactionStatePurchased];
    [[[transaction stub] andReturn:originalTransaction] originalTransaction];
    return transaction;
}

- (id)mockPaymentTransactionWithState:(SKPaymentTransactionState)state downloads:(NSArray*)downloads
{
    id transaction = [OCMockObject mockForClass:[SKPaymentTransaction class]];
    [[[transaction stub] andReturnValue:@(state)] transactionState];
    [[[transaction stub] andReturn:[NSDate date]] transactionDate];
    [[[transaction stub] andReturn:@"transaction"] transactionIdentifier];
    [[[transaction stub] andReturn:[NSData data]] transactionReceipt];
    id payment = [OCMockObject mockForClass:[SKPayment class]];
    [[[payment stub] andReturn:self.name] productIdentifier];
    [[[transaction stub] andReturn:payment] payment];
    [[[transaction stub] andReturn:downloads] downloads];
    for (id download in downloads)
    {
        [[[download stub] andReturn:transaction] transaction];
    }
    return transaction;
}

#pragma mark RMStoreObserver

- (void)storeProductsRequestFailed:(NSNotification*)notification {}
- (void)storeProductsRequestFinished:(NSNotification*)notification {}
- (void)storePaymentTransactionFailed:(NSNotification*)notification {}
- (void)storePaymentTransactionFinished:(NSNotification*)notification {}
- (void)storeRestoreTransactionsFailed:(NSNotification*)notification {}
- (void)storeRestoreTransactionsFinished:(NSNotification*)notification {}

@end

@implementation RMStoreContentDownloaderSuccess

- (void)downloadContentForTransaction:(SKPaymentTransaction *)transaction success:(void (^)())successBlock progress:(void (^)(float))progressBlock failure:(void (^)(NSError *))failureBlock
{
    if (successBlock) successBlock();
}

@end

@implementation RMStoreContentDownloaderProgress

- (void)downloadContentForTransaction:(SKPaymentTransaction *)transaction success:(void (^)())successBlock progress:(void (^)(float))progressBlock failure:(void (^)(NSError *))failureBlock
{
    if (progressBlock) progressBlock(self.progress);
}

@end

@implementation RMStoreContentDownloaderFailure

- (void)downloadContentForTransaction:(SKPaymentTransaction *)transaction success:(void (^)())successBlock progress:(void (^)(float))progressBlock failure:(void (^)(NSError *))failureBlock
{
    if (failureBlock) failureBlock(self.error);
}

@end

@implementation RMStoreReceiptVerifierSuccess

- (void)verifyTransaction:(SKPaymentTransaction *)transaction success:(void (^)())successBlock failure:(void (^)(NSError *))failureBlock
{
    if (successBlock) successBlock();
}

@end

@implementation RMStoreReceiptVerifierFailure

- (void)verifyTransaction:(SKPaymentTransaction *)transaction success:(void (^)())successBlock failure:(void (^)(NSError *))failureBlock
{
    if (failureBlock) failureBlock(nil);
}

@end

@implementation RMStoreReceiptVerifierUnableToComplete

- (void)verifyTransaction:(SKPaymentTransaction *)transaction success:(void (^)())successBlock failure:(void (^)(NSError *))failureBlock
{
    NSError *error = [NSError errorWithDomain:RMStoreErrorDomain code:RMStoreErrorCodeUnableToCompleteVerification userInfo:nil];
    if (failureBlock) failureBlock(error);
}

@end

#pragma clang diagnostic pop
