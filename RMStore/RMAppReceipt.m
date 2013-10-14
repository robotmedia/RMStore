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

NSInteger const RMAppReceiptASN1TypeBundleIdentifier = 2;
NSInteger const RMAppReceiptASN1TypeAppVersion = 3;
NSInteger const RMAppReceiptASN1TypeOriginalAppVersion = 19;
NSInteger const RMAppReceiptASN1TypeExpirationDate = 21;

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
    if (tag == V_ASN1_INTEGER && length == 1)
    {
        value = *pp[0];
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
    const uint8_t *p = octets->data;
    const uint8_t *end = p + octets->length;
    
    int type, tag;
    long length = 0;
    
    ASN1_get_object(&p, &length, &type, &tag, end - p);
    if (type != V_ASN1_SET)
    {
        PKCS7_free(p7);
        return;
    }
    
    while (p < end)
    {
        ASN1_get_object(&p, &length, &type, &tag, end - p);
        if (type != V_ASN1_SEQUENCE) break;
        
        const uint8_t *sequenceEnd = p + length;
        
        int attr_type = RMASN1ReadInteger(&p, sequenceEnd - p);
        RMASN1ReadInteger(&p, sequenceEnd - p); // Consume attribute version
        
        NSData *data = RMASN1ReadOctectString(&p, sequenceEnd - p);
        if (!data) continue;
        
        const unsigned char *s = data.bytes;
        long omax = sequenceEnd - s;
        switch (attr_type)
        {
            case RMAppReceiptASN1TypeBundleIdentifier:
                _bundleIdentifier = RMASN1ReadUTF8String(&s, omax);
                break;
            case RMAppReceiptASN1TypeAppVersion:
                _appVersion = RMASN1ReadUTF8String(&s, omax);
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
        
        while (p < sequenceEnd)
        { // Skip remaining fields
            ASN1_get_object(&p, &length, &type, &tag, sequenceEnd - p);
            p += length;
        }
    }
    
    PKCS7_free(p7);
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
