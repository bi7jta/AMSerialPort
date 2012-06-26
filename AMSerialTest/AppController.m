//
//  AppController.m
//  AMSerialTest
//
//		2009-09-09		Andreas Mayer
//		- fixed memory leak in -serialPortReadData:


#import "AppController.h"
#import "AMSerialPortList.h"
#import "AMSerialPortAdditions.h"

@interface AppController ()
- (void)connect:(id)sender;
@end

@implementation AppController


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[inputTextField setStringValue: @"ati"]; // will ask for modem type
    
	// register for port add/remove notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddPorts:) name:AMSerialPortListDidAddPortsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemovePorts:) name:AMSerialPortListDidRemovePortsNotification object:nil];
	[AMSerialPortList sharedPortList]; // initialize port list to arm notifications
    
    [self listDevices:nil];
}

- (AMSerialPort *)port
{
    return port;
}

- (void)setPort:(AMSerialPort *)newPort
{
    id old = nil;

    if (newPort != port) {
        old = port;
        port = [newPort retain];
        [old release];
    }
}


- (void)initPort
{
	[port close];
    
    // register as self as delegate for port
    [port setReadDelegate:self];
    [port setWriteDelegate:self];
    
    [outputTextView insertText:@"attempting to open port\r"];
    [outputTextView setNeedsDisplay:YES];
    [outputTextView displayIfNeeded];
    
    // open port - may take a few seconds ...
    if ([port open]) {
        
        [outputTextView insertText:@"port opened\r"];
        [outputTextView insertText:[NSString stringWithFormat:@"port type: %@", [port type]]];
        [outputTextView setNeedsDisplay:YES];
        [outputTextView displayIfNeeded];
        
        // listen for data in a separate thread
        [port readDataInBackground];
        
    } else { // an error occured while creating port
        [outputTextView insertText:@"couldn't open port for device "];
        [outputTextView insertText:[port name]];
        [outputTextView insertText:@"\r"];
        [outputTextView setNeedsDisplay:YES];
        [outputTextView displayIfNeeded];
        [self setPort:nil];
    }

}

- (void)serialPortReadData:(NSDictionary *)dataDictionary
{
	// this method is called if data arrives 
	// @"data" is the actual data, @"serialPort" is the sending port
	AMSerialPort *sendPort = [dataDictionary objectForKey:@"serialPort"];
	NSData *data = [dataDictionary objectForKey:@"data"];
	if ([data length] > 0) {
		NSString *text = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		[outputTextView insertText:text];
		[text release];
		// continue listening
		[sendPort readDataInBackground];
	} else { // port closed
		[outputTextView insertText:@"port closed\r"];
	}
	[outputTextView setNeedsDisplay:YES];
	[outputTextView displayIfNeeded];
}


- (void)didAddPorts:(NSNotification *)theNotification
{
	[outputTextView insertText:@"didAddPorts:"];
	[outputTextView insertText:@"\r"];
	[outputTextView insertText:[[theNotification userInfo] description]];
	[outputTextView insertText:@"\r"];
	[outputTextView setNeedsDisplay:YES];
}

- (void)didRemovePorts:(NSNotification *)theNotification
{
	[outputTextView insertText:@"didRemovePorts:"];
	[outputTextView insertText:@"\r"];
	[outputTextView insertText:[[theNotification userInfo] description]];
	[outputTextView insertText:@"\r"];
	[outputTextView setNeedsDisplay:YES];
}

- (void)connect:(id)sender
{

}

- (IBAction)listDevices:(id)sender
{
    // Clean PopUp
    [portsPopUp removeAllItems];

    NSMenu *menu = [[NSMenu alloc] init];
    NSArray *ports = [[AMSerialPortList sharedPortList] serialPorts];
    
    for (AMSerialPort *aPort in ports) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[aPort name] action:@selector(chooseDevice:) keyEquivalent:@""];
        [item setRepresentedObject:aPort];
        [menu addItem:item];
        [item release];
        
        // print port name
		[outputTextView insertText:[aPort name]];
		[outputTextView insertText:@":"];
		[outputTextView insertText:[aPort bsdPath]];
		[outputTextView insertText:@"\r"];
        [outputTextView setNeedsDisplay:YES];
    }
    
    [portsPopUp setMenu:menu];
    [menu release];
}

- (IBAction)chooseDevice:(id)sender
{
    [sender setEnabled:NO];
    AMSerialPort *aPort = [(NSMenuItem *)sender representedObject];
    [self setPort:aPort];
    [deviceTextField setStringValue:[aPort bsdPath]];
    // new device selected
	[self initPort];
    [sender setEnabled:YES];
}

- (IBAction)send:(id)sender
{
	NSString *sendString = [[inputTextField stringValue] stringByAppendingString:@"\r"];

	if(!port) {
		// open a new port if we don't already have one
		[self initPort];
	}

	if([port isOpen]) { // in case an error occured while opening the port
		[port writeString:sendString usingEncoding:NSUTF8StringEncoding error:NULL];
	}
}

#pragma mark AMSerialPortReadDelegate
- (void)serialPort:(AMSerialPort *)port didReadData:(NSData *)data
{
    
}

#pragma mark AMSerialPortWriteDelegate
// apparently the delegate only gets messaged on longer writes
- (void)serialPort:(AMSerialPort *)port didMakeWriteProgress:(NSUInteger)progress total:(NSUInteger)total
{
    
}

@end
