//
//  RMAppReceipt.m
//  RMStore
//
//  Created by Hermes on 10/12/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import "RMAppReceipt.h"
#import "RMStore.h"
#include <openssl/pkcs7.h>
#include <openssl/objects.h>

// From https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html#//apple_ref/doc/uid/TP40010573-CH106-SW1
NSInteger const RMAppReceiptASN1TypeBundleIdentifier = 2;
NSInteger const RMAppReceiptASN1TypeAppVersion = 3;
NSInteger const RMAppReceiptASN1TypeOpaqueValue = 4;
NSInteger const RMAppReceiptASN1TypeHash = 5;
NSInteger const RMAppReceiptASN1TypeInAppPurchaseReceipt = 17;
NSInteger const RMAppReceiptASN1TypeOriginalAppVersion = 19;
NSInteger const RMAppReceiptASN1TypeExpirationDate = 21;

NSInteger const RMAppReceiptASN1TypeQuantity = 1701;
NSInteger const RMAppReceiptASN1TypeProductIdentifier = 1702;
NSInteger const RMAppReceiptASN1TypeTransactionIdentifier = 1703;
NSInteger const RMAppReceiptASN1TypePurchaseDate = 1704;
NSInteger const RMAppReceiptASN1TypeOriginalTransactionIdentifier = 1705;
NSInteger const RMAppReceiptASN1TypeOriginalPurchaseDate = 1706;
NSInteger const RMAppReceiptASN1TypeSubscriptionExpirationDate = 1708;
NSInteger const RMAppReceiptASN1TypeWebOrderLineItemID = 1711;
NSInteger const RMAppReceiptASN1TypeCancellationDate = 1712;

@interface RMAppReceipt()<RMStoreObserver>

@end

@implementation RMAppReceipt

static RMAppReceipt *_bundleReceipt = nil;

int RMASN1ReadInteger(const unsigned char **pp, long omax)
{
    int tag, class;
    long length;
    int value = 0;
    ASN1_get_object(pp, &length, &tag, &class, omax);
    if (tag == V_ASN1_INTEGER)
    {
        for (int i = 0, mask = 1; i < length; i++, mask = mask<<2)
        {
            value += *pp[i] * mask;
        }
    }
    *pp += length;
    return value;
}

NSData* RMASN1ReadOctectString(const unsigned char **pp, long omax)
{
    int tag, class;
    long length;
    NSData *data = nil;
    ASN1_get_object(pp, &length, &tag, &class, omax);
    if (tag == V_ASN1_OCTET_STRING)
    {
        data = [NSData dataWithBytes:*pp length:length];
    }
    *pp += length;
    return data;
}

NSString* RMASN1ReadString(const unsigned char **pp, long omax, int expectedTag, NSStringEncoding encoding)
{
    int tag, class;
    long length;
    NSString *value = nil;
    ASN1_get_object(pp, &length, &tag, &class, omax);
    if (tag == expectedTag)
    {
        value = [[NSString alloc] initWithBytes:*pp length:length encoding:encoding];
    }
    *pp += length;
    return value;
}

NSString* RMASN1ReadUTF8String(const unsigned char **pp, long omax)
{
    return RMASN1ReadString(pp, omax, V_ASN1_UTF8STRING, NSUTF8StringEncoding);
}

NSString* RMASN1ReadIA5SString(const unsigned char **pp, long omax)
{
    return RMASN1ReadString(pp, omax, V_ASN1_IA5STRING, NSASCIIStringEncoding);
}

- (id)initWithURL:(NSURL *)URL
{
    if (self = [super init])
    {      
        [self loadFromPath:URL.path];
    }
    return self;
}

/*
 Based in https://github.com/rmaddy/VerifyStoreReceiptiOS
 */
- (void)loadFromPath:(NSString*)path
{
    const char *cpath = [[path stringByStandardizingPath] fileSystemRepresentation];
    FILE *fp = fopen(cpath, "rb");
    if (!fp) return;
    
    PKCS7 *p7 = d2i_PKCS7_fp(fp, NULL);
    fclose(fp);
    
    if (!p7) return;
    
    ASN1_OCTET_STRING *octets = p7->d.sign->contents->d.data;
    [RMAppReceipt enumerateASN1Attributes:octets->data length:octets->length usingBlock:^(NSData *data, int type, long omax) {
        const unsigned char *s = data.bytes;
        switch (type)
        {
            case RMAppReceiptASN1TypeBundleIdentifier:
                _bundleIdentifier = RMASN1ReadUTF8String(&s, omax);
                break;
            case RMAppReceiptASN1TypeAppVersion:
                _appVersion = RMASN1ReadUTF8String(&s, omax);
                break;
            case RMAppReceiptASN1TypeOpaqueValue:
                _opaqueValue = data;
                break;
            case RMAppReceiptASN1TypeHash:
                _hash = data;
                break;
            case RMAppReceiptASN1TypeInAppPurchaseReceipt:
                _inAppPurchases = [RMAppReceipt inAppPurchasesFromReceipt:data];
                break;
            case RMAppReceiptASN1TypeOriginalAppVersion:
                _originalAppVersion = RMASN1ReadUTF8String(&s, omax);
                break;
            case RMAppReceiptASN1TypeExpirationDate:
            {
                NSString *string = RMASN1ReadIA5SString(&s, omax);
                _expirationDate = [RMAppReceipt formatRFC3339String:string];
                break;
            }
        }
    }];
    
    PKCS7_free(p7);
}


+ (void)enumerateASN1Attributes:(const unsigned char*)p length:(long)tlength usingBlock:(void (^)(NSData *data, int type, long omax))block
{
    int type, tag;
    long length;
    
    const unsigned char *end = p + tlength;
    
    ASN1_get_object(&p, &length, &type, &tag, end - p);
    if (type != V_ASN1_SET) return;
    
    while (p < end)
    {
        ASN1_get_object(&p, &length, &type, &tag, end - p);
        if (type != V_ASN1_SEQUENCE) break;
        
        const uint8_t *sequenceEnd = p + length;
        
        int attributeType = RMASN1ReadInteger(&p, sequenceEnd - p);
        RMASN1ReadInteger(&p, sequenceEnd - p); // Consume attribute version
        
        NSData *data = RMASN1ReadOctectString(&p, sequenceEnd - p);
        if (!data) continue;
        
        const unsigned char *s = data.bytes;
        long omax = sequenceEnd - s;
        block(data, attributeType, omax);
        
        while (p < sequenceEnd)
        { // Skip remaining fields
            ASN1_get_object(&p, &length, &type, &tag, sequenceEnd - p);
            p += length;
        }
    }
}

+ (NSDate*)formatRFC3339String:(NSString*)string
{
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    });
    return [formatter dateFromString:string];
}

+ (NSArray*)inAppPurchasesFromReceipt:(NSData*)receipt
{
    NSMutableArray *purchases = [NSMutableArray array];
    return purchases;
}

+ (RMAppReceipt*)bundleReceipt
{
    if (!_bundleReceipt)
    {
        NSURL *URL = [RMStore receiptURL];
        NSString *path = URL.path;
        const BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil];
        if (exists)
        {
            _bundleReceipt = [[RMAppReceipt alloc] initWithURL:URL];
            [[RMStore defaultStore] addStoreObserver:_bundleReceipt];
        }
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

@implementation RMAppReceiptIAP


@end
