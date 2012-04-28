//
//  TFAppDelegate.m
//  TuringFluid
//
//  Created by Gabriel Handford on 2/14/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "TFAppDelegate.h"

@implementation TFAppDelegate

@synthesize window=_window, GLView=_GLView;

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillCloseNotification:) name:NSWindowWillCloseNotification object:nil];
  [_GLView start];
  [self toggleFullScreen:nil];
}

- (IBAction)toggleFullScreen:(id)sender {
  if (_fullScreenEnabled) {
    [_fullScreenWindow close];
    [_window setAcceptsMouseMovedEvents:YES];
    [_window setContentView:_GLView];
    [_window makeKeyAndOrderFront:_GLView];
    [_window makeFirstResponder:_GLView];
    _fullScreenEnabled = NO;
  } else {
    NSRect frame = [[NSScreen mainScreen] frame];
    // Instantiate new borderless window
    _fullScreenWindow = [[NSWindow alloc] initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
    [_window setAcceptsMouseMovedEvents:NO];
    if (_fullScreenWindow) {
      // Set the options for our new fullscreen window
      [_fullScreenWindow setTitle:@"Full Screen"];            
      [_fullScreenWindow setReleasedWhenClosed: YES];
      [_fullScreenWindow setAcceptsMouseMovedEvents:YES];
      [_fullScreenWindow setContentView:_GLView];
      [_fullScreenWindow makeKeyAndOrderFront:_GLView];
      // By setting the window level to just beneath the screensaver,
      // only this window will be visible (no menu bar or dock)
      [_fullScreenWindow setLevel:NSScreenSaverWindowLevel-1];
      [_fullScreenWindow makeFirstResponder:_GLView];
      [_fullScreenWindow setOpaque:YES];
      [_fullScreenWindow setHidesOnDeactivate:YES];
      _fullScreenEnabled = YES;
    } else {
      NSLog(@"Error: could not create fullscreen window!");
    }
  }
}

- (void)windowWillCloseNotification:(NSNotification *)notification {
  if (!_fullScreenEnabled) {
    [_GLView stop];
    [NSApp terminate:nil];
  }
}

@end
