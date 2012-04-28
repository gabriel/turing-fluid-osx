//
//  TFAppDelegate.h
//  TuringFluid
//
//  Created by Gabriel Handford on 2/14/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "TFGLView.h"

@interface TFAppDelegate : NSObject <NSApplicationDelegate> {
  BOOL _fullScreenEnabled;
  NSWindow *_fullScreenWindow;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet TFGLView *GLView;

- (IBAction)toggleFullScreen:(id)sender;

@end
