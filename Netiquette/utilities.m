//
//  utilities.m
//  Netiquette
//
//  Created by Patrick Wardle on 7/14/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

@import Sentry;

#import "Event.h"
#import "logging.h"
#import "utilities.h"

//disable std err
void disableSTDERR()
{
    //file handle
    int devNull = -1;
    
    //open /dev/null
    devNull = open("/dev/null", O_RDWR);
    
    //dup
    dup2(devNull, STDERR_FILENO);
    
    //close
    close(devNull);
    
    return;
}

//get app's version
// extracted from Info.plist
NSString* getAppVersion()
{
    //read and return 'CFBundleVersion' from bundle
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

//transform app state
OSStatus transformApp(ProcessApplicationTransformState newState)
{
    //serial number
    // init with current process
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    
    //transform and return
    return TransformProcessType(&psn, newState);
}

//check if (full) dark mode
// meaning, Mojave+ and dark mode enabled
BOOL isDarkMode()
{
    //flag
    BOOL darkMode = NO;
    
    //not mojave?
    // bail, since not true dark mode
    if(YES != [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 14, 0}])
    {
        //bail
        goto bail;
    }
    
    //not dark mode?
    if(YES != [[NSUserDefaults.standardUserDefaults stringForKey:@"AppleInterfaceStyle"] isEqualToString:@"Dark"])
    {
        //bail
        goto bail;
    }
    
    //ok, mojave dark mode it is!
    darkMode = YES;
    
bail:
    
    return darkMode;
}

//loads a framework
// note: assumes it is in 'Framework' dir
NSBundle* loadFramework(NSString* name)
{
    //handle
    NSBundle* framework = nil;
    
    //framework path
    NSString* path = nil;
    
    //init path
    path = [NSString stringWithFormat:@"%@/../Frameworks/%@", [NSProcessInfo.processInfo.arguments[0] stringByDeletingLastPathComponent], name];
    
    //standardize path
    path = [path stringByStandardizingPath];
    
    //init framework (bundle)
    framework = [NSBundle bundleWithPath:path];
    if(NULL == framework)
    {
        //bail
        goto bail;
    }
    
    //load framework
    if(YES != [framework loadAndReturnError:nil])
    {
        //bail
        goto bail;
    }
    
bail:
    
    return framework;
}

//convert IP addr to (ns)string
// from: https://stackoverflow.com/a/29147085/3854841
NSString* convertIPAddr(unsigned char* ipAddr, __uint8_t socketFamily)
{
    //string
    NSString* socketDescription = nil;
    
    //socket address
    unsigned char socketAddress[INET6_ADDRSTRLEN+1] = {0};
    
    //what family?
    switch(socketFamily)
    {
        //IPv4
        case AF_INET:
        {
            //convert
            inet_ntop(AF_INET, ipAddr, (char*)&socketAddress, INET_ADDRSTRLEN);
            
            break;
        }
            
        //IPV6
        case AF_INET6:
        {
            //convert
            inet_ntop(AF_INET6, ipAddr, (char*)&socketAddress, INET6_ADDRSTRLEN);
            
            break;
        }
            
        default:
            break;
    }
    
    //convert to obj-c string
    if(0 != strlen((const char*)socketAddress))
    {
        //convert
        socketDescription = [NSString stringWithUTF8String:(const char*)socketAddress];
    }
    
    return socketDescription;
}

//wait till window non-nil
// then make that window modal
void makeModal(NSWindowController* windowController)
{
    //window
    __block NSWindow* window = nil;
    
    //wait till non-nil
    // then make window modal
    for(int i=0; i<20; i++)
    {
        //grab window
        dispatch_sync(dispatch_get_main_queue(), ^{
         
            //grab
            window = windowController.window;
            
        });
                      
        //nil?
        // nap
        if(nil == window)
        {
            //nap
            [NSThread sleepForTimeInterval:0.05f];
            
            //next
            continue;
        }
        
        //have window?
        // make it modal
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            //modal
            [[NSApplication sharedApplication] runModalForWindow:windowController.window];
            
        });
        
        //done
        break;
    }
    
    return;
}

//prettify JSON
NSString* prettifyJSON(NSString* output)
{
    //data
    NSData* data = nil;
    
    //object
    id object = nil;
    
    //pretty data
    NSData* prettyData = nil;
    
    //pretty string
    NSString* prettyString = nil;
    
    //convert to data
    data = [output dataUsingEncoding:NSUTF8StringEncoding];
    
    //convert to JSON
    // wrap since we are serializing JSON
    @try
    {
        //serialize
        object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        //convert to pretty data
        prettyData =  [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
    }
    //bail on exception
    @catch(NSException *exception)
    {
        ;
    }
    
    //convert to pretty string
    if(nil != prettyData)
    {
        //convert to string
        prettyString = [[NSString alloc] initWithData:prettyData encoding:NSUTF8StringEncoding];
    }
    else
    {
        //error
        prettyString = @"{\"ERROR\" : \"failed to convert output to JSON\"}";
    }
    
    return prettyString;
}

//format results
// convert to JSON
NSMutableString* formatResults(OrderedDictionary* connections, BOOL skipApple)
{
    //output
    NSMutableString* output = nil;
    
    //process
    Process* process = nil;
    
    //json data
    // for intermediate conversions
    NSData *jsonData = nil;
    
    //signing info
    NSString* signingInfo = nil;
    
    //(per process) connections
    OrderedDictionary* events = nil;
    
    //init output string
    output = [NSMutableString string];
    
    //start JSON
    [output appendString:@"["];
    
    //add each connection (per process)
    for(NSNumber* pid in connections)
    {
        //events (per process)
        events = connections[pid];
        
        //grab process from first event
        process = ((Event*)[[events allValues] firstObject]).process;
        
        //skip apple?
        if(YES == skipApple)
        {
            //skip apple signed
            if( (noErr == [process.signingInfo[KEY_SIGNATURE_STATUS] intValue]) &&
                (Apple ==  [process.signingInfo[KEY_SIGNATURE_SIGNER] intValue]) )
            {
                //skip
                continue;
            }
            
            //cups is apple,
            // but owned by root so we can't check it's signature (but it's SIP protected)
            if(YES == [process.binary.path isEqualToString:CUPS])
            {
                //skip
                continue;
            }
        }
        
        //convert process signing info to JSON
        if(nil != process.signingInfo)
        {
            //convert signing dictionary
            // wrap since we are serializing JSON
            @try
            {
                //convert
                jsonData = [NSJSONSerialization dataWithJSONObject:process.signingInfo options:kNilOptions error:NULL];
                if(nil != jsonData)
                {
                    //convert data to string
                    signingInfo = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                }
            }
            //ignore exceptions
            // ->file sigs will just be 'unknown'
            @catch(NSException *exception)
            {
                ;
            }
        }
        
        //add process info
        [output appendFormat:@"{\"process\": {\"pid\": \"%d\", \"path\": \"%@\", \"signature(s)\": %@},", process.pid, process.path, signingInfo];
        
        //add events
        [output appendFormat:@"\"connections\": ["];
        
        //add all events
        for(Event* event in events.allValues)
        {
            //add
            [output appendFormat:@"%@,", [event toJSON]];
        }
        
        //remove last ','
        if(YES == [output hasSuffix:@","])
        {
            //remove
            [output deleteCharactersInRange:NSMakeRange([output length]-1, 1)];
        }
        
        //terminate list
        [output appendString:@"]},"];
    }
    
    //remove last ','
    if(YES == [output hasSuffix:@","])
    {
        //remove
        [output deleteCharactersInRange:NSMakeRange([output length]-1, 1)];
    }
    
    //terminate list
    [output appendString:@"]"];
    
    return output;
}
