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

#import <UIKit/UIKit.h>

// A class to prompt the user to review your application.
// To use, create an instance and call -shouldAskForReviewAtLaunch: or 
// -shouldAskForReview:. The former is suggested as it will make sure the user
// has launched the app several times first. The iTunes URL must be specified
// as this is what will be opened in iTunes. All other properties can be
// overridden and the string properties should be overridden for localization.
// See the following links for information about generating your iTunes URL.

// http://creativealgorithms.com/blog/content/review-app-links-sorted-out
// http://bjango.com/articles/ituneslinks/
// sample review link:
//   @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/"
//       "viewContentsUserReviews?type=Purple+Software&id=327466677";

enum ReviewRequestButtonIndex {
  reviewRequestCancelButtonIndex = 0,
  reviewRequestRateNowButtonIndex = 1,
  reviewRequestRemindLaterButtonIndex = 2,
};

// This protocol defines a function that informs the delegate of the user's
// response to the review request prompt.
@protocol ReviewRequestDelegate<NSObject>
 @optional
- (void)userResponseReceived:(NSInteger)buttonIndex;
@end

@interface ReviewRequest : NSObject <UIAlertViewDelegate> {
 @private
  UIAlertView *alert_;
  NSUInteger minLaunchCount_;
  NSUInteger minWaitTimeSeconds_;

  NSURL *iTunesReviewLink_;
  NSString *reviewDialogAskLater_;
  NSString *reviewDialogDontAskAgain_;
  NSString *reviewDialogMessage_;
  NSString *reviewDialogOk_;
  NSString *reviewDialogTitle_;
  id<ReviewRequestDelegate> reviewRequestDelegate_;
  BOOL showAskLaterButton_;
}

// How many times must the application be launched before prompting the user?
// Set to 0 to not require a minimum number of launches.
@property(nonatomic, assign) NSUInteger minLaunchCount;

// How much time after the user says to remind them later should pass before
// asking again? This time will also be used when the application is installed.
@property(nonatomic, assign) NSUInteger minWaitTimeSeconds;

// The link to the application review page on iTunes.
@property(nonatomic, copy) NSURL *iTunesReviewLink;

// The text for the 'remind me later' button.
@property(nonatomic, copy) NSString *reviewDialogAskLater;

// The text for the 'don't ask me again' button.
@property(nonatomic, copy) NSString *reviewDialogDontAskAgain;

// The dialog text.
@property(nonatomic, copy) NSString *reviewDialogMessage;

// The text for the 'rate now' button.
@property(nonatomic, copy) NSString *reviewDialogOk;

// The dialog title.
@property(nonatomic, copy) NSString *reviewDialogTitle;

// Show the 'remind me later' button. Default is YES.
@property(nonatomic, assign) BOOL showAskLaterButton;

// The delegate to send user's response to.
@property(nonatomic, assign) id<ReviewRequestDelegate> reviewRequestDelegate;

// The initializer. iTunes URL must be specified as it is the only property for
// which no default exists.
- (id)initWithItunesUrl:(NSURL *)url;

// Can the user be propted for a review? They haven't already reviewed this
// version, they haven't opted out, the application has been launched the
// minimum number of times and the minimum wait time has passed since they
// installed, upgraded or said to remind them later.
- (void)askForReviewIfNeeded;

#if DEBUG
// Method to display the dialog regardless of any other condition. Useful for
// debugging links and UI.
- (void)debugShowDialogNow;
#endif

@end
