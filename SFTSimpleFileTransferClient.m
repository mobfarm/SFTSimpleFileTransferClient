//
//  SFTSimpleFileTransferClient.m
//  SimpleFileTransfer
//
//  Created by Nicolò Tosi on 9/9/13.
//  Copyright (c) 2013 MobFarm. All rights reserved.
//

#import "SFTSimpleFileTransferClient.h"
#import <netinet/in.h>

#define SFT_TIMEOUT 10.0
static void randomizeHexByteArray(char * bytes, size_t length);

@interface SFTSimpleFileTransferClient()
{
    dispatch_queue_t queue;
}

+(NSData *)dataWithByte:(unsigned char)byte;
+(NSData *)dataWithNetworkOrderShort:(short)shortNumber;
+(NSData *)dataWithNetworkOrderInteger:(int)longNumber;

@property (strong, nonatomic) GCDAsyncSocket * socket;

@end

@implementation SFTSimpleFileTransferClient
@synthesize socket;

+(dispatch_queue_t)dispatchQueue
{
    static dispatch_queue_t queue = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(!queue)
        {
            char randomId [16];
            
            randomizeHexByteArray(randomId, 16);
            
            queue = dispatch_queue_create(randomId, NULL);
        }
    });
    
    return queue;
}

#pragma mark - Socket delegate

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host 
         port:(uint16_t)port
{

}

-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{

}

-(void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength 
          tag:(long)tag
{

}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if(err)
    {
        MFLogError(@"SimpleFileTransferClient disconnected with error %@", err);
        [self.delegate clientDidCompleteTransfer:self success:NO];
    }
    else
    {
        [self.delegate clientDidCompleteTransfer:self success:YES];
    }
}

#pragma mark -

-(void)sendData:(NSData *)data fileName:(NSString *)fileName
{
    NSMutableDictionary * info = [[NSMutableDictionary alloc]init];
    
    // 1. Length (required)
    NSUInteger dataLength = data.length;
    NSNumber * length = [NSNumber numberWithUnsignedInteger:dataLength];
    [info setValue:length forKey:@"length"];
    
    // 2. Filename (optional)
    if(fileName.length > 0)
        [info setValue:fileName forKey:@"filename"];
    
    NSError * __autoreleasing error = nil;
    
    NSData * infoData = [NSJSONSerialization dataWithJSONObject:info options:0 error:&error];
    
    if(infoData)
    {
        NSInteger infoLength = infoData.length;
        
        [self.socket writeData:[SFTSimpleFileTransferClient dataWithByte:0] withTimeout:SFT_TIMEOUT tag:0];
        
        NSData * infoLengthData = [SFTSimpleFileTransferClient dataWithNetworkOrderShort:infoLength];
        [self.socket writeData:infoLengthData withTimeout:SFT_TIMEOUT tag:1];
        [self.socket writeData:infoData withTimeout:SFT_TIMEOUT tag:2];
        [self.socket writeData:data withTimeout:SFT_TIMEOUT tag:3];
    }
    
    [self.socket disconnectAfterWriting];
}


-(void)sendData:(NSData *)data
{
    [self sendData:data fileName:nil];
}

-(void)connectToAddress:(NSString *)address port:(int)port
{
    if([self.socket isConnected])
    {
        [self.socket disconnect];
        self.socket = nil;
    }
    
    GCDAsyncSocket * sock = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue() socketQueue:[SFTSimpleFileTransferClient dispatchQueue]];
    
    NSError * __autoreleasing error = nil;
    if(![sock connectToHost:address onPort:port error:&error])
    {
        MFLogError(@"Error connecting to upload server %@", error);
        
        [self.delegate client:self couldNotConnectToAddress:address port:port];
    }

    self.socket = sock;
}

#pragma mark -

#pragma mark -

-(id)init
{
    self = [super init];
    if(self)
    {
        
        char randomID [16];
        
        randomizeHexByteArray(randomID, 16);
        
        queue = dispatch_queue_create(randomID, NULL);
    }
    return self;
}

+(NSData *)dataWithByte:(unsigned char)byte
{
    return [NSData dataWithBytes:&byte length:1];
}

+(NSData *)dataWithNetworkOrderShort:(short)shortNumber
{
    short nos = htons(shortNumber);
    return [NSData dataWithBytes:&nos length:sizeof(nos)];
}

+(NSData *)dataWithNetworkOrderInteger:(int)longNumber
{
    int noi = htonl(longNumber);
    return [NSData dataWithBytes:&noi length:sizeof(noi)];
}

static void randomizeHexByteArray(char * bytes, size_t length)
{
    int i;
    for (i = 0; i < length; i++)
    {
        unsigned char random = arc4random()%16;
        /** 
         * Hex values 0 - 9  are 48 to 57 ASCII, hex a - f are 97 to 102.
         * Thus 5 + 48 = 53, ASCII '5', while 10 + 87 = 97, ASCII 'a'.
         */
        random = random < 10 ? random + 48 : random + 87;
        bytes[i] = random; 
    }
}

@end
