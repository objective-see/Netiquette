//
//  event.m
//  Netiquette
//
//  Created by Patrick Wardle on 7/6/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//


#import "Event.h"
#import "utilities.h"

@implementation Event

//init with event
// process raw event, adding process info, etc
-(id)init:(NSDictionary*)event
{
    //flag
    BOOL resolveName = NO;
    
    //interface name
    char interfaceName[IF_NAMESIZE+1] = {0};
    
    //super
    self = [super init];
    if(self != nil)
    {
        //set flag
        resolveName = [[[NSProcessInfo processInfo] arguments] containsObject:@"-names"];
        
        //init process
        self.process = [[Process alloc] init:[event[(__bridge NSString *)kNStatSrcKeyPID] intValue]];
        
        //generate code signing info
        [self.process generateSigningInfo:kSecCSDefaultFlags];
        
        //extract provider
        self.provider = event[(__bridge NSString *)kNStatSrcKeyProvider];
        
        //extract state
        // note: nil, unless provider is TCP
        self.tcpState = event[(__bridge NSString *)kNStatSrcKeyTCPState];
        
        //convert local address
        self.localAddress = [self parseAddress:event[(__bridge NSString *)kNStatSrcKeyLocal] resolveName:NO];
        
        //convert remote address
        // and resolve remote name if necessary
        self.remoteAddress = [self parseAddress:event[(__bridge NSString *)kNStatSrcKeyRemote] resolveName:resolveName];
    
        //extract and convert interface (number) to name
        if(NULL != if_indextoname([event[(__bridge NSString *)kNStatSrcKeyInterface] intValue], (char*)&interfaceName))
        {
            //save/convert
            self.interface = [NSString stringWithUTF8String:interfaceName];
        }
    }
 
    return self;
}

//parse/extract addr, port, etc...
-(NSMutableDictionary*)parseAddress:(NSData*)data resolveName:(BOOL)resolveName
{
    //address
    NSMutableDictionary* address = nil;
    
    //ipv4 struct
    struct sockaddr_in *ipv4 = NULL;
    
    //ipv6 struct
    struct sockaddr_in6 *ipv6 = NULL;
    
    //host name
    NSString* hostName = nil;
    
    //init
    address = [NSMutableDictionary dictionary];
    
    //parse
    // for now, only support IPv4 and IPv6
    switch(((struct sockaddr *)[data bytes])->sa_family)
    {
        //IPv4
        case AF_INET:
            
            //typecast
            ipv4 = (struct sockaddr_in *)[data bytes];
            
            //add family
            address[KEY_FAMILY] = [NSNumber numberWithInt:AF_INET];
            
            //add port
            address[KEY_PORT] = [NSNumber numberWithUnsignedShort:ntohs(ipv4->sin_port)];
            
            //format/add address
            address[KEY_ADDRRESS] = convertIPAddr((unsigned char*)&ipv4->sin_addr, AF_INET);
            
            //resolve name?
            if(YES == resolveName)
            {
                //resolve host name
                if(nil != (hostName = [self resolveName:(struct sockaddr *)[data bytes]]))
                {
                    //add host
                    address[KEY_HOST_NAME] = hostName;
                }
            }
            //set default
            else
            {
                //add host
                address[KEY_HOST_NAME] = @"n/a";
            }
            
            break;
            
        //IPv6
        case AF_INET6:
        {
            //typecast
            ipv6 = (struct sockaddr_in6 *)[data bytes];
            
            //add family
            address[KEY_FAMILY] = [NSNumber numberWithInt:AF_INET6];
            
            //add port
            address[KEY_PORT] = [NSNumber numberWithUnsignedShort:ntohs(ipv6->sin6_port)];
            
            //format/add address
            address[KEY_ADDRRESS] = convertIPAddr((unsigned char*)&ipv6->sin6_addr, AF_INET6);
            
            //resolve name?
            if(YES == resolveName)
            {
                //resolve host name
                if(nil != (hostName = [self resolveName:(struct sockaddr *)[data bytes]]))
                {
                    //add host
                    address[KEY_HOST_NAME] = hostName;
                }
            }
            //set default
            else
            {
                //add host
                address[KEY_HOST_NAME] = @"n/a";
            }
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
    
    //description
    //NSString* discription = nil;
    
    //convert event to string
    //discription = [NSString stringWithFormat:@"%@ %d %@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\"},", PROCESS_PID, self.process.pid, PROCESS_PATH, self.process.binary.path, INTERFACE, self.interface, PROTOCOL, self.provider, LOCAL_ADDRESS, self.localAddress[KEY_ADDRRESS], LOCAL_PORT, self.localAddress[KEY_PORT], REMOTE_ADDRESS, self.remoteAddress[KEY_ADDRRESS], REMOTE_PORT, self.remoteAddress[KEY_PORT], REMOTE_HOST, self.remoteAddress[KEY_HOST_NAME], CONNECTION_STATE, self.tcpState];
    
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
    
bail:
    
    return matches;
}

//resolve name via (reverse) dns    
-(NSString*)resolveName:(struct sockaddr *)sockAddr
{
    //name
    NSString* resolvedName = nil;

    //host
    char host[NI_MAXHOST+1] = {0};
    
    //resolve name
    if(0 == getnameinfo(sockAddr, sockAddr->sa_len, host, NI_MAXHOST, NULL, 0, 0))
    {
        //convert
        resolvedName = [NSString stringWithUTF8String:host];
    }
    
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
    
    return [NSString stringWithFormat:@"{\"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\"}", INTERFACE, interface, PROTOCOL, self.provider, LOCAL_ADDRESS, self.localAddress[KEY_ADDRRESS], LOCAL_PORT, self.localAddress[KEY_PORT], REMOTE_ADDRESS, self.remoteAddress[KEY_ADDRRESS], REMOTE_PORT, self.remoteAddress[KEY_PORT], REMOTE_HOST, self.remoteAddress[KEY_HOST_NAME], CONNECTION_STATE, state];
}

@end
