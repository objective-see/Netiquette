//
//  event.m
//  Netiquette
//
//  Created by Patrick Wardle on 7/6/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#import "Event.h"
#import "Monitor.h"
#import "utilities.h"

@implementation Event

//init with event
// process raw event, adding process info, etc
-(id)init:(NSDictionary*)event process:(Process*)process
{
    //flag
    BOOL resolveName = NO;
    
    //interface name
    char interfaceName[IF_NAMESIZE+1] = {0};
    
    //super
    self = [super init];
    if(self != nil)
    {
        //terminal exec
        // should resolve flags?
        if(YES == [NSProcessInfo.processInfo.arguments containsObject:@"-list"])
        {
            //set
            resolveName = [NSProcessInfo.processInfo.arguments containsObject:@"-names"];
        }
        //non-terminal exec
        // should resolve flags?
        else
        {
            //set
            resolveName = [NSUserDefaults.standardUserDefaults boolForKey:PREFS_RESOLVE_NAMES];
        }
        
        //monitor provided cache'd process?
        if( (nil != process) &&
            (process.pid == [event[kNStatSrcKeyPID] intValue]) )
        {
            //use
            self.process = process;
        }
        //generate (new) process
        else
        {
            //generate
            self.process = [[Process alloc] init:[event[kNStatSrcKeyPID] intValue]];
            
            //generate code signing info
            [self.process generateSigningInfo:kSecCSDefaultFlags];
        }
        
        //extract provider
        self.provider = event[kNStatSrcKeyProvider];
        
        //extract state
        // note: nil, unless provider is TCP
        self.tcpState = event[kNStatSrcKeyTCPState];
        
        //convert local address
        self.localAddress = [self parseAddress:event[kNStatSrcKeyLocal]];
        
        //convert remote address
        // and resolve remote name if necessary
        self.remoteAddress = [self parseAddress:event[kNStatSrcKeyRemote]];
        
        //in background
        // resolve host name
        if(YES == resolveName)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
                //local name
                NSString* localName = nil;
    
                //remote name
                NSString* remoteName = nil;
                
                //resolve /save local
                localName = [self resolveName:(struct sockaddr *)[(NSData*)(event[kNStatSrcKeyLocal]) bytes]];
                if(0 != localName.length)
                {
                    self.localAddress[KEY_HOST_NAME] = localName;
                }
                
                //resolve / save remove
                remoteName = [self resolveName:(struct sockaddr *)[(NSData*)(event[kNStatSrcKeyRemote]) bytes]];
                if(0 != remoteName.length)
                {
                    self.remoteAddress[KEY_HOST_NAME] = remoteName;
                }
            });
        }
        
        //extract and convert interface (number) to name
        if(NULL != if_indextoname([event[kNStatSrcKeyInterface] intValue], (char*)&interfaceName))
        {
            //save/convert
            self.interface = [NSString stringWithUTF8String:interfaceName];
        }
        
        //extract bytes up
        self.bytesUp = [event[kNStatSrcKeyTxBytes] unsignedLongValue];
        
        //extract bytes down
        self.bytesDown = [event[kNStatSrcKeyRxBytes] unsignedLongValue];
        
    }
 
    return self;
}

//parse/extract addr, port, etc...
-(NSMutableDictionary*)parseAddress:(NSData*)data
{
    //address
    NSMutableDictionary* address = nil;
    
    //ipv4 struct
    struct sockaddr_in *ipv4 = NULL;
    
    //ipv6 struct
    struct sockaddr_in6 *ipv6 = NULL;
    
    //init
    address = [NSMutableDictionary dictionary];
    
    //parse
    // for now, only support IPv4 and IPv6
    switch(((struct sockaddr *)data.bytes)->sa_family)
    {
        //IPv4
        case AF_INET:
            
            //typecast
            ipv4 = (struct sockaddr_in *)data.bytes;
            
            //add family
            address[KEY_FAMILY] = [NSNumber numberWithInt:AF_INET];
            
            //add port
            address[KEY_PORT] = [NSNumber numberWithUnsignedShort:ntohs(ipv4->sin_port)];
            
            //format/add address
            address[KEY_ADDRRESS] = convertIPAddr((unsigned char*)&ipv4->sin_addr, AF_INET);
            
            break;
            
        //IPv6
        case AF_INET6:
        {
            //typecast
            ipv6 = (struct sockaddr_in6 *)data.bytes;
            
            //add family
            address[KEY_FAMILY] = [NSNumber numberWithInt:AF_INET6];
            
            //add port
            address[KEY_PORT] = [NSNumber numberWithUnsignedShort:ntohs(ipv6->sin6_port)];
            
            //format/add address
            address[KEY_ADDRRESS] = convertIPAddr((unsigned char*)&ipv6->sin6_addr, AF_INET6);
            
        }
    }
    
    return address;
}

//given a search string
// check if path, pid, ips, etc match?
-(BOOL)matches:(NSString*)search
{
    //flag
    BOOL matches = NO;
    
    //name match
    if(YES == [self.process.binary.name localizedCaseInsensitiveContainsString:search])
    {
        //match
        matches = YES;
        
        //bail
        goto bail;
    }
    
    //pid match?
    if(YES == [[NSString stringWithFormat:@"%d", self.process.pid] containsString:search])
    {
        //match
        matches = YES;
        
        //bail
        goto bail;
    }

    //path match?
    if(YES == [self.process.path localizedCaseInsensitiveContainsString:search])
    {
        //match
        matches = YES;
        
        //bail
        goto bail;
    }
    

    //local ip match?
    if(YES == [self.localAddress[KEY_ADDRRESS] containsString:search])
    {
        //match
        matches = YES;
        
        //bail
        goto bail;
    }
    
    //local host name match?
    if( (0 != [self.localAddress[KEY_HOST_NAME] length]) &&
        (YES == [self.localAddress[KEY_HOST_NAME] localizedCaseInsensitiveContainsString:search]) )
    {
        //match
        matches = YES;
        
        //bail
        goto bail;
    }
    
    //local port match?
    if(YES == [[self.localAddress[KEY_PORT] stringValue] containsString:search])
    {
        //match
        matches = YES;
        
        //bail
        goto bail;
    }
    
    //remote ip match?
    if(YES == [self.remoteAddress[KEY_ADDRRESS] containsString:search])
    {
        //match
        matches = YES;
        
        //bail
        goto bail;
    }
    
    //remote host name match?
    if( (0 != [self.remoteAddress[KEY_HOST_NAME] length]) &&
        (YES == [self.remoteAddress[KEY_HOST_NAME] localizedCaseInsensitiveContainsString:search]) )
    {
        //match
        matches = YES;
        
        //bail
        goto bail;
    }
    
    //remote port match?
    if(YES == [[self.remoteAddress[KEY_PORT] stringValue] containsString:search])
    {
        //match
        matches = YES;
        
        //bail
        goto bail;
    }
    
    //protocol match?
    if(YES == [self.provider localizedCaseInsensitiveContainsString:search])
    {
        //match
        matches = YES;
        
        //bail
        goto bail;
    }
    
    //interface match?
    if(YES == [self.interface localizedCaseInsensitiveContainsString:search])
    {
        //match
        matches = YES;
        
        //bail
        goto bail;
    }
    
    //state
    if( (0 != self.tcpState.length) &&
        (YES == [self.tcpState localizedCaseInsensitiveContainsString:search]) )
    {
        //match
        matches = YES;
        
        //bail
        goto bail;
    }
    
    //bytes up
    if(YES == [[NSByteCountFormatter stringFromByteCount:self.bytesUp countStyle:NSByteCountFormatterCountStyleFile] containsString:search])
    {
        //match
        matches = YES;
        
        //bail
        goto bail;
    }
    
    //bytes down
    if(YES == [[NSByteCountFormatter stringFromByteCount:self.bytesDown countStyle:NSByteCountFormatterCountStyleFile] containsString:search])
    {
        //match
        matches = YES;
        
        //bail
        goto bail;
    }
    
bail:
    
    return matches;
}

//resolve name via (reverse) dns
// though it checks a cache first...
-(NSString*)resolveName:(struct sockaddr *)sockAddr
{
    //name
    NSString* resolvedName = nil;

    //host
    char host[NI_MAXHOST+1] = {0};
    
    //cache
    static NSCache* cache = nil;
    
    //once
    static dispatch_once_t once = 0;
    
    //key
    NSData* key = nil;
    
    //init cache
    dispatch_once (&once, ^{
        
        //init cache
        cache = [[NSCache alloc] init];
        
        //set cache limit
        cache.countLimit = 2048;

    });

    //init ipv4 cache key
    if(AF_INET == sockAddr->sa_family)
    {
        //key
        key = [NSData dataWithBytes:(unsigned char*)&((struct sockaddr_in *)sockAddr)->sin_addr length:INET_ADDRSTRLEN];
    }
    //init ipv6 cache key
    else if(AF_INET6 == sockAddr->sa_family)
    {
        key = [NSData dataWithBytes:(unsigned char*)&((struct sockaddr_in6 *)sockAddr)->sin6_addr length:INET6_ADDRSTRLEN];
    }
    
    //in cache?
    resolvedName = [cache objectForKey:key];
    if(0 != resolvedName.length)
    {
        //done
        goto bail;
    }
    
    //resolve name
    if(0 == getnameinfo(sockAddr, sockAddr->sa_len, host, NI_MAXHOST, NULL, 0, 0))
    {
        //convert
        resolvedName = [NSString stringWithUTF8String:host];
        
        //save to cache
        if(0 != resolvedName.length)
        {
            //cache
            [cache setObject:resolvedName forKey:key];
        }
    }
    
bail:
    
    return resolvedName;
}

//convert to JSON
-(NSString*)toJSON
{
    //state
    NSString* state = @"n/a";
    
    //interface
    NSString* interface = @"";
    
    //tcp state
    if(0 != self.tcpState.length)
    {
        //set
        state = self.tcpState;
    }
    
    //set interface
    if(0 != self.interface.length)
    {
        //set
        interface = self.interface;
    }
    
    return [NSString stringWithFormat:@"{\"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%lu\", \"%@\": \"%lu\"}", INTERFACE, interface, PROTOCOL, self.provider, LOCAL_ADDRESS, self.localAddress[KEY_ADDRRESS], LOCAL_PORT, self.localAddress[KEY_PORT], REMOTE_ADDRESS, self.remoteAddress[KEY_ADDRRESS], REMOTE_PORT, self.remoteAddress[KEY_PORT], REMOTE_HOST, self.remoteAddress[KEY_HOST_NAME], CONNECTION_STATE, state, BYTES_UP, self.bytesUp, BYTES_DOWN, self.bytesDown];
}

@end
