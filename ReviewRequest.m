// Portions Copyright (c) 2012 Google Inc
// Copyright (c) 2010 Games from Within
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "ReviewRequest.h"

#import <UIKit/UIKit.h>

#define KeyReviewed @"com.google.lib.review_request.reviewed_for_version"
#define KeySeen @"com.google.lib.review_request.seen_version"
#define KeyNumVersions @"com.google.lib.review_request.num_of_versions"
#define KeyDontAsk @"com.google.lib.review_request.dont_ask"
#define KeyNextTimeToAsk @"com.google.lib.review_request.next_time_to_ask"
#define KeySessionCountSinceLastAsked @"com.google.lib.review_request.session_count_since_last_asked"

@interface ReviewRequest ()

@property(nonatomic, strong) UIAlertView *alert;

// Show the dialog that prompts the user to review the application.
- (void)askForReview;

@end

@implementation ReviewRequest

#pragma mark - Initialization and destruction

- (id)init {
  NSAssert(NO, @"This class must be instantiated via -initWithItunesUrl:");
  return nil;
}

- (id)initWithItunesUrl:(NSURL *)url {
  self = [super init];
  if (self) {
    self.iTunesReviewLink = url;

    // set default values
    self.minLaunchCount = 12;
    self.minWaitTimeSeconds = 60 * 60 * 23; // 23 hours
    self.numberOfVersionsToSkip = 0;
    self.reviewDialogAskLater = @"Remind me later";
    self.reviewDialogDontAskAgain = @"Don't ask again";
    self.reviewDialogMessage = @"so we can keep the updates coming.";
    self.reviewDialogOk = @"Yes, rate it!";
    self.reviewDialogTitle = @"Please rate";
    self.showAskLaterButton = YES;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(didEnterBackground:)
               name:UIApplicationDidEnterBackgroundNotification
             object:nil];
  }
  return self;
}

- (void)dealloc {
  self.iTunesReviewLink = nil;
  self.reviewDialogAskLater = nil;
  self.reviewDialogDontAskAgain = nil;
  self.reviewDialogMessage = nil;
  self.reviewDialogOk = nil;
  self.reviewDialogTitle = nil;
  self.alert = nil;

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self
                name:UIApplicationDidEnterBackgroundNotification
              object:nil];
  [super dealloc];
}

#pragma mark - Delegate

- (void)alertView:(UIAlertView *)alertView
    didDismissWithButtonIndex:(NSInteger)buttonIndex {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  switch (buttonIndex) {
    case reviewRequestRemindLaterButtonIndex: {
      // remind me later
      NSAssert(self.showAskLaterButton,
          @"The 'remind me later' button was pressed, but it is not enabled.");
      const double nextTime =
          CFAbsoluteTimeGetCurrent() + self.minWaitTimeSeconds;
      [defaults setDouble:nextTime forKey:KeyNextTimeToAsk];
      break;
    }

    case reviewRequestRateNowButtonIndex: {
      // rate it now
      NSString *version =
          [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
      [defaults setValue:version forKey:KeyReviewed];
      [[UIApplication sharedApplication] openURL:self.iTunesReviewLink];
      break;
    }

    case reviewRequestCancelButtonIndex:
      // don't ask again
      [defaults setBool:YES forKey:KeyDontAsk];
      break;

    default:
      NSAssert(NO, @"Unexpected ButtonIndex received in "
          "-alertView:didDismissWithButtonIndex");
      break;
  }

  [self.reviewRequestDelegate userResponseReceived:buttonIndex];

  [defaults setInteger:0 forKey:KeySessionCountSinceLastAsked];
  self.alert = nil;
  // See -askForReview: for info about this release.
  [self release];
}

#pragma mark - Public methods

- (void)askForReviewIfNeeded {
  if ([[UIApplication sharedApplication] applicationState] ==
      UIApplicationStateBackground) {
    // Skip review request if the app is running in the background.
    return;
  }

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *version =
      [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
  NSString *seenVersion = [defaults stringForKey:KeySeen];
  NSUInteger numVersions = [defaults integerForKey:KeyNumVersions];

  if (![seenVersion isEqualToString:version]) {
    // After an app update, reset persistent data.
    [defaults removeObjectForKey:KeyDontAsk];
    [defaults removeObjectForKey:KeyNextTimeToAsk];
    [defaults removeObjectForKey:KeyReviewed];
    [defaults removeObjectForKey:KeySessionCountSinceLastAsked];
    [defaults setValue:version forKey:KeySeen];
    if (numVersions > self.numberOfVersionsToSkip) {
      [defaults setInteger:1 forKey:KeyNumVersions];
    } else {
      [defaults setInteger:numVersions+1 forKey:KeyNumVersions];
    }
  }

  numVersions = [defaults integerForKey:KeyNumVersions];
  if (self.numberOfVersionsToSkip > 0 &&
      numVersions <= self.numberOfVersionsToSkip) {
    return;
  }

  if ([defaults boolForKey:KeyDontAsk]) {
    return;
  }

  NSString *reviewedVersion = [defaults stringForKey:KeyReviewed];
  if ([reviewedVersion isEqualToString:version]) {
    return;
  }

  const NSUInteger count =
      [defaults integerForKey:KeySessionCountSinceLastAsked];
  [defaults setInteger:count+1 forKey:KeySessionCountSinceLastAsked];

  const double currentTime = CFAbsoluteTimeGetCurrent();
  if ([defaults objectForKey:KeyNextTimeToAsk] == nil) {
    const double nextTime = currentTime + self.minWaitTimeSeconds;
    [defaults setDouble:nextTime forKey:KeyNextTimeToAsk];
    return;
  }

  const double nextTime = [defaults doubleForKey:KeyNextTimeToAsk];
  if (currentTime < nextTime) {
    return;
  }

  if (count >= self.minLaunchCount) {
    [self askForReview];
  }
}

#if DEBUG
- (void)debugShowDialogNow {
  [self askForReview];
}
#endif

#pragma mark - Private methods

- (void)askForReview {
  NSAssert(self.alert == nil, @"ReviewRequest dialog already visible.");
  if (self.showAskLaterButton) {
    self.alert =
        [[[UIAlertView alloc] initWithTitle:self.reviewDialogTitle
                                    message:self.reviewDialogMessage
                                   delegate:self
                          cancelButtonTitle:self.reviewDialogDontAskAgain
                          otherButtonTitles:self.reviewDialogOk,
            self.reviewDialogAskLater, nil] autorelease];
  } else {
    self.alert =
        [[[UIAlertView alloc] initWithTitle:self.reviewDialogTitle
                                    message:self.reviewDialogMessage
                                   delegate:self
                          cancelButtonTitle:self.reviewDialogDontAskAgain
                          otherButtonTitles:self.reviewDialogOk,
            nil] autorelease];
  }

  // Need to ensure that the current object will be retained until the delegate
  // is invoked.  There is a matching release in the delegate.
  [self retain];
  [self.alert show];
}

#pragma mark - NSNotification observer

- (void)didEnterBackground:(NSNotification *)notification {
  [self.alert dismissWithClickedButtonIndex:reviewRequestRemindLaterButtonIndex
                                   animated:NO];
}

@end
