//    //
//  ICVideoViewController.m
//  ImageCanvas1
//
//  Created by Nayan Chauhan on 06/02/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

//TODO: getImage at center

#import "ICVideoViewController.h"
#import "ICCustomImageView.h"
#import "CustomImageView.h"
#import "ICDataManager.h"
#import "ICConstants.h"
#import "CustomGestureRecognizer.h"
#import "ImageCanvas1AppDelegate.h"
#import "UIImage+ImageFromView.h"
#import "ICCustomTableViewCell.h"

#define kSizeOfImage 130

@implementation ICVideoViewController

#pragma mark -
#pragma mark  Synthesize variables


@synthesize moviePlayerController = mMoviePlayerController;
@synthesize videoTopView = mVideoTopView;
@synthesize tutorialView = mTutorialView;

@synthesize editButton = mEditButton;
@synthesize playButton = mPlayButton;
@synthesize tutorialButton = mTutorialButton;

@synthesize videoView = mVideoView;
@synthesize targetImage = mTargetImage;
@synthesize settingPopover = mSettingPopover;
@synthesize audioUrl = mAudioUrl;
@synthesize player = mPlayer;
@synthesize imageArray = mImageArray;
@synthesize temp = mTemp;
@synthesize theNewCopy = mTheNewCopy;
@synthesize sideImageList = mSideImageList;
@synthesize transitionEffect = mTransitionEffect;
@synthesize transitionSmoothness = mTranstionSmoothness;
@synthesize videoAlert = mVideoAlert;
@synthesize currentVideo = mCurrentVideo;

@synthesize isNew = mIsNew;
@synthesize isPreview = mIsPreview;
@synthesize shouldRefreshView = mShouldRefreshView;
@synthesize shouldSave = mShouldSave;
@synthesize progressView = mProgressView;
@synthesize tableView = mTableView;
@synthesize buffer = mBuffer;

@synthesize fadeInTime = mFadeInTime;
@synthesize fadeOutTime = mFadeOutTime;
@synthesize videoGenerator = mVideoGenerator;
@synthesize isAudio = mIsAudio;
@synthesize tab = mTab;
@synthesize fromTab = mFromTab;

@synthesize item = mItem;
@synthesize saveAlert = mSaveAlert;

@synthesize selectedImageTag = mSelectedImageTag;
@synthesize settings = mSettings;

@synthesize lastScale = mLastScale;
@synthesize lastRotation = mLastRotation;

@synthesize tabToSelectNext = mTabToSelectNext;
@synthesize shouldPlayVideo = mShouldPlayVideo;
//====================================================================================
#pragma mark -
#pragma mark dealloc
- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

-(void)releaseAllSubviews
{
    [mVideoTopView release];
    [mVideoView release];
    [mPlayer release];
    [mTableView release];
}

-(void)releaseAllObjects
{
    [mAudioUrl release];
    [mImageArray release];
    [mTemp release];
    [mTheNewCopy release];
    [mSideImageList release];
    [mCurrentVideo release];
    [mVideoGenerator release];
}

- (void)releaseAllViews
{
    [mMoviePlayerController release];
    [mSettingPopover release];
    [mVideoAlert release];
    [mProgressView release];
}

//====================================================================================
#pragma mark -
#pragma mark Initializing methods

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    ImageCanvas1AppDelegate *appDelegate = (ImageCanvas1AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.mainAlert != nil)
    {
        [appDelegate.mainAlert dismissWithClickedButtonIndex:0 animated:YES];
    }
    self.fromTab = NO;
    
    if([self.currentVideo.imageArray count]== 0)
	{
		self.tutorialView.hidden = NO;
		[self.view bringSubviewToFront:self.tutorialView];
		self.videoTopView.alpha=0.6;
        //self.view.alpha=0.6;
        self.tableView.alpha=0.6;
        self.videoView.alpha=0.6;
        self.editButton.alpha = 0.6;
        self.tutorialButton.alpha = 0.6;
        self.playButton.alpha =0.6;
		self.navigationItem.leftBarButtonItem.enabled = NO;
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
	else
	{
		self.navigationItem.leftBarButtonItem.enabled = YES;
		self.navigationItem.rightBarButtonItem.enabled = YES;
		self.videoTopView.alpha=1;
        //self.view.alpha=1;
        self.tableView.alpha=1;
        self.videoView.alpha=1;
        self.editButton.alpha = 1;
        self.tutorialButton.alpha =1;
        self.playButton.alpha =1;
		self.tutorialView.hidden = YES;
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Video settting's
    self.transitionEffect = eDissolve;
    self.transitionSmoothness = low;
    self.fadeInTime = 5;
    self.fadeOutTime = 5;
    

    NSMutableArray *tempList = [[NSMutableArray alloc] init];
    self.sideImageList = tempList;
    [tempList release];
    
	UIColor *tintColor = [[UIColor alloc] initWithRed:30.0 / 255 green:50.0 / 255 blue:120.0 / 255 alpha:1.0];
    self.navigationController.navigationBar.tintColor = tintColor;
    [tintColor release];
	
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Preview" 
                                                                      style:UIBarButtonItemStyleBordered 
                                                                     target:self 
                                                                     action:@selector(previewVideo:)];
	self.navigationItem.leftBarButtonItem = leftBarButton;
    [leftBarButton release];
	
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" 
                                                                       style:UIBarButtonItemStyleBordered 
                                                                      target:self 
                                                                      action:@selector(showSettings:)];
	self.navigationItem.rightBarButtonItem = rightBarButton;
    [rightBarButton release];
	
	/*  send notifications whenever the orientation changes*/
	[[NSNotificationCenter defaultCenter] addObserver:self.videoTopView selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
	
	//Loads the tableView view with library images at first launch
	[self.videoTopView setHighlightedButton:self.videoTopView.libraryButton];
	[self.videoTopView buttonAction:self.videoTopView.libraryButton];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    
    UIImageView *newImage = [[UIImageView alloc] init];
    newImage.frame = CGRectMake(5, 10, 
                                167, 
                                kSizeOfImage-5);
    newImage.layer.borderColor = [UIColor yellowColor].CGColor;
    newImage.layer.borderWidth = 2;
    newImage.layer.backgroundColor = [UIColor blackColor].CGColor;
    [newImage setContentMode:UIViewContentModeScaleAspectFit];
    newImage.userInteractionEnabled = YES;
    [self.sideImageList addObject:newImage];
    [newImage release]; //NEW LEAK FIXED
    
    NSString* music = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"mp3"];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:music];
    self.audioUrl = url;
    
    [url release];
    self.isAudio = YES;
    ICImageToVideo* tempImgToVideoVC = [[ICImageToVideo alloc] init];
    self.videoGenerator = tempImgToVideoVC;
    
    [tempImgToVideoVC release]; // [NEW LEAK FIXED]
    //self.videoGenerator = [[ICImageToVideo alloc] init];
    self.videoGenerator.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(playbackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(playbackStateChanged) 
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    
    
    self.videoView.userInteractionEnabled = YES;
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editImage:)];
    
    [doubleTap setNumberOfTapsRequired:2];
    [self.videoView addGestureRecognizer:doubleTap];
    [doubleTap release];
    self.isPreview = NO;
}

- (void) playbackStateChanged 
{
    if (self.moviePlayerController.moviePlayer.playbackState == MPMoviePlaybackStatePaused)
    {
        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    }
}

- (void)playbackDidFinish:(id)sender
{
    self.moviePlayerController.moviePlayer.view.alpha = 0;
    self.moviePlayerController.moviePlayer.view.userInteractionEnabled = NO;
    [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
    {
        cell = [[[UITableViewCell alloc] 
                 initWithStyle:UITableViewCellStyleDefault
                 reuseIdentifier:CellIdentifier] autorelease];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *view in cell.contentView.subviews)
    {
        [view removeFromSuperview];
    }
    
    [cell.contentView addSubview:[self.sideImageList objectAtIndex:indexPath.row]];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sideImageList count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [self.sideImageList count]-1)
    {
        return kSizeOfImage + 30;
    }
    return kSizeOfImage;
}

- (void)viewDidAppear:(BOOL)animated //gets called everytime the tab is opened
{
    [super viewDidAppear:animated]; 
    
    ImageCanvas1AppDelegate *appDelegate = (ImageCanvas1AppDelegate *)[[UIApplication sharedApplication] delegate];

    [[(ImageCanvas1AppDelegate *)[[UIApplication sharedApplication] delegate] tabBarController] setDelegate:self];
	NSLog(@"In ViewDidAppear of Video VC");
	
    ICDataManager* dataManager = [ICDataManager sharedDataManager];
	NSInteger no_of_videos = [dataManager getNumberOfVideos];
	NSLog(@"NO of videos is %d", no_of_videos);
	if (no_of_videos == 0) {
        NSLog(@"HANDLING ZERO BUG");
		self.currentVideo = nil;
		[self addNewVideo];
        self.shouldRefreshView = YES;
	}
    
	if (self.currentVideo == nil) {
		[NSThread detachNewThreadSelector:@selector(addNewVideo) toTarget:self withObject:nil];
	}
	 
	NSLog(@"current Video is %@", self.currentVideo);
	NSLog(@"Video ID is %d", self.currentVideo.mediaId);
	
	if (self.shouldRefreshView) {
		NSLog(@"Calling A Function To Refresh View");
		
		[self refreshView];
	}
	else {
		NSLog(@"NOT refreshing the view");
	}
    if (appDelegate.mainAlert != nil)
    {
        //[appDelegate.mainAlert dismissWithClickedButtonIndex:0 animated:YES];
    }
        
    //self.shouldPlayVideo = YES;


}

- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:YES];
    //self.tabBarController.delegate = (ImageCanvas1AppDelegate*)[[UIApplication sharedApplication] delegate];
	self.tabBarController.delegate = self;
	self.shouldRefreshView = NO;
	
}
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex 
{
	//self.tabBarController.selectedIndex = 2;
    NSLog(@"Alert Dismissed");
    /*
    if (buttonIndex == 0) {
        NSLog(@"Save & GENERATE video");
        NSString* videoFileName = [NSString stringWithFormat:@"%d.%@", self.currentVideo.mediaId, @"mov"];
        self.shouldPlayVideo = NO;
        
        [self showAlert];
        [self performSelectorOnMainThread:@selector(prepareVideo:) withObject:videoFileName waitUntilDone:YES];
        
        [NSThread detachNewThreadSelector:@selector(performSaveOperationWithTabChangeToIndex:) toTarget:self withObject:[NSNumber numberWithInt:self.tabToSelectNext]];
        
        NSLog(@"Make the video!!");
    }
    else{
        self.tabBarController.selectedIndex = self.tabToSelectNext;
    }
     */
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // Release any cached data, images, etc that aren't in use.
    
    [super didReceiveMemoryWarning];
    
    NSLog(@"D-R-M-W VIDEO VC");
    
    if (![self isViewLoaded]) {
        /* release your custom data which will be rebuilt in loadView or viewDidLoad */
        NSLog(@"M-W in VIDEO VC");
        
        //remove NON-CRITICAL data
        //all data objects are critical here, hence they are not released.
    } 
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    NSLog(@"ViewDidUnload VIDEO VC");
    
    
    //release all IBOutlets
    [mTableView release], mTableView = nil;
    [mVideoView release], mVideoView = nil;
    [mVideoTopView release], mVideoTopView = nil;
    
    self.shouldRefreshView = YES;
}

//====================================================================================
#pragma mark -
#pragma mark Orientation methods

//- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
//{
//	/*  send notifications whenever the orientation changes*/
//	[[NSNotificationCenter defaultCenter] postNotificationName:@"MyNotification" object:nil ];
//}

//// Override to allow orientations other than the default portrait orientation.
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//    // Return YES for supported orientations.
//    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
//	//return YES;
//	return UIInterfaceOrientationIsPortrait(interfaceOrientation);
//    [mImageArray release];
//	
//	[mVideoTopView release];
//	[mVideoView release];
//	[mSettingPopover release];
//}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    //return YES;
    //return UIInterfaceOrientationIsPortrait(interfaceOrientation);
	return interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown ;
}

//====================================================================================
#pragma mark -
#pragma mark preview and settings

-(void)previewVideo:(id)sender
{
    self.isPreview = YES;
    if ([self.sideImageList count] > 2)
    {
        NSString* videoFileName = [NSString stringWithFormat:@"%d.%@", self.currentVideo.mediaId, @"mov"];
        NSLog(@"Video File Name is %@", videoFileName);
        NSFileManager* fileManager = [NSFileManager defaultManager];
        
        NSString* docDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        NSString*  videoDir = [docDir stringByAppendingPathComponent:@"Video"];
        NSString* finalPath = [NSString stringWithFormat:@"%@/%@",videoDir, videoFileName];
        
        if (self.shouldSave == NO) {
            if (![fileManager fileExistsAtPath:finalPath]) {
                self.shouldSave = YES;
            }
        }
        
        
        if (self.shouldSave) { //        if (self.shouldSave && self.shouldRefreshView) {
            NSLog(@"We should call imageToVideo method");
            [self performSelectorOnMainThread:@selector(showAlert) withObject:nil waitUntilDone:YES];
            [self performSelectorInBackground:@selector(prepareVideo:) withObject:videoFileName];
            
        }
        else {
            NSLog(@"We should just play the video");
            BOOL fileIsThere = [fileManager fileExistsAtPath:finalPath];
            if (fileIsThere) {
                [self playVideoWithFileName:finalPath];
            }
            
        }
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Enough Images Selected" 
                                                        message:@"Please add atleast 2 images before making Video"
                                                       delegate:self 
                                              cancelButtonTitle:@"Ok" 
                                              otherButtonTitles:nil, nil] ;
        [alert show];
        [alert release];
    }
}

- (void)prepareVideo:(NSString *)fileName
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [self.videoGenerator prepareVideo:fileName
                           withImages:self.sideImageList
                             andAudio:self.audioUrl];
    [pool release];
}

-(void)showSettings:(id)sender
{
	NSLog(@"settings....");
	if (self.settingPopover == nil) 
	{
		ICSettingViewController *set = [[ICSettingViewController alloc]init];
        

        
        set.delegate = self;
        self.settings = set;
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:set]; 
        popover.delegate = self;
        [set release];
		
        self.settingPopover = popover;
        [popover release];
        self.settingPopover.popoverContentSize = kSettingPopooverSize;
    }
    self.settings.effectField.text = [self stringForEnum:self.currentVideo.transitionEffect];
    self.settings.audioField.text = self.currentVideo.audioPath;
    self.settings.repeatSwitch.on = self.currentVideo.shouldAudioRepeat;
    self.settings.audioSwitch.on = self.currentVideo.audioEnabled;
    self.settings.fadeIn.value = self.currentVideo.audioFadeInValue;
    self.settings.fadeOut.value = self.currentVideo.audioFadeOutValue;
    self.settings.timeField.text = [NSString stringWithFormat:@"%.0f", self.currentVideo.timePerImage];
    self.settings.animationTimeField = [NSString stringWithFormat:@"%.0f", self.currentVideo.animationDuration];
    
    self.settings.smoothSegment.selectedSegmentIndex = self.currentVideo.transitionSmoothness; 
    
	self.item = sender;
    [self.settingPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES]; 
}

- (NSString *)stringForEnum:(eTransitionEffect)effect
{
    NSString *returnString;
    if (effect == eShrink)
    {
        returnString = [NSString stringWithString:@"Shrink"];
    }
    else if (effect == eWipe)
    {
        returnString = [NSString stringWithString:@"Wipe"];
    }
    else if (effect == eDissolve)
    {
        returnString = [NSString stringWithString:@"Dissole"];
    }
    else if (effect == eCrush)
    {
        returnString = [NSString stringWithString:@"Crush"];
    }
    else if (effect == eNone)
    {
        returnString = [NSString stringWithString:@"None"];
    }
    else
    {
        returnString = @"UNDEFINED";
    }
    return returnString;
}

- (void)didFinshPickingAudio:(NSURL *)audio
{
    self.audioUrl = audio;
    self.videoGenerator.audioUrl = audio;
}

//====================================================================================
#pragma mark -
#pragma mark Image drag
- (void)dragImage:(UIPanGestureRecognizer *)sender
{
    [self.view bringSubviewToFront:[sender view]];

	if ([sender state] == UIGestureRecognizerStateBegan) 
	{
        NSLog(@"Gesture began");
        UIView *temp;
        
        
        UIImageView *tempView = [[UIImageView alloc] init];
        if ([[sender view] isKindOfClass:[ICCustomImageView class]])
        {
            if ([[self.videoTopView.currentSelection currentTitle] isEqualToString:@"Library"]) 
            {
                tempView.image = [[(CustomImageView *)[sender view] imageView] image];
                
                NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
                NSString *tagString = [NSString stringWithFormat:@"%d",[(CustomImageView *)[sender view] imageView].tag - 1000];
                [tempDictionary setValue:tempView forKey:tagString];
                [self performSelectorInBackground:@selector(loadDragImage:) withObject:[tempDictionary autorelease]];
                //tempView = [[UIImageView alloc] initWithImage:[[(CustomImageView *)[sender view] imageView] image]];
            }
            else
            {
                tempView.image = [[(CustomImageView*)[sender view] imageView] image];
                //tempView = [[UIImageView alloc] initWithImage:[[(CustomImageView *)[sender view] imageView] image]];
            }
        }
        else if ([[sender view] isKindOfClass:[UIImageView class]])
        {
            tempView.image = [(UIImageView *)[sender view] image];
        }
        CGPoint superPoint  = [sender.view.superview convertPoint:sender.view.frame.origin toView:nil];		 
        CGRect properSize;
        
        //self.temp is the temperory invisible view within which the image is being dragged
        if (self.temp == nil)
        {
            temp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            self.temp = temp;
            
            [temp release];
        }
        
        else 
        {
            for (UIView *view in self.temp.subviews)
            {
                [view removeFromSuperview];
                  //I HAVE NO IDEA WHY I PUT THIS HERE :O
//                sender.state = UIGestureRecognizerStateFailed;
//                tempView.image = nil;
            }
        }

        
        if ([tempView image].size.width < kMaxImageSize &&
            [tempView image].size.height < kMaxImageSize)
        {
            properSize = CGRectMake([sender locationInView:nil].x, 
                                    [sender locationInView:nil].y - 65, 
                                    kMaxImageSize, 
                                    kMaxImageSize);
        }
        else
        {
            properSize = CGRectMake(superPoint.x, 
                                    superPoint.y - 65, 
                                    kMaxImageSize,
                                    kMaxImageSize);
        }
        
        
        
        tempView.frame = properSize;
        
        tempView.center = CGPointMake([sender locationInView:nil].x, 
                                      [sender locationInView:nil].y-65);
        
        //Code to handle dragging of images in potraitUpsideDown orientation
        UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
        if(currentOrientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            tempView.center = CGPointMake(self.view.frame.size.width- [sender locationInView:nil].x, 
                                          self.view.frame.size.height-[sender locationInView:nil].y+45);
            
        }
        
        tempView.contentMode = UIViewContentModeScaleAspectFit;
        [tempView setUserInteractionEnabled:YES];
        [self.view addSubview:self.temp];
        
        [self.temp addSubview:tempView];        
        [self setTheNewCopy:tempView];
        [tempView release];
        
	}
    
    
    CGPoint translation = [sender translationInView:self.view];
    [self.theNewCopy setCenter:CGPointMake([self.theNewCopy center].x+translation.x, 
                                           [self.theNewCopy center].y+translation.y)];
    
    
    [sender setTranslation:CGPointZero inView:self.view];
   
    CGRect targetRect = [[[self.sideImageList objectAtIndex:self.sideImageList.count - 1]superview]
                         convertRect:[[self.sideImageList objectAtIndex:self.sideImageList.count - 1] frame]
                         toView:nil];
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if(currentOrientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        targetRect = CGRectMake(self.view.frame.size.width-targetRect.origin.x,self.view.frame.size.height-targetRect.origin.y, targetRect.size.width, targetRect.size.height);
        
    }

    if ([sender state] == UIGestureRecognizerStateEnded)
    {
        NSLog(@"Gesture Ended");
        if (![[sender view] isKindOfClass:[ICCustomImageView class]])
        {
            int i;
            [(UIImageView *)[sender view] setImage:nil];
            for (i = 0; i < [self.sideImageList count]; i++)
            {
                if ([sender.view isEqual:[self.sideImageList objectAtIndex:i]])
                {
                    break;
                }
                NSLog(@"Loop : %d",i);
            }
            NSLog(@"%d",i);
            CGRect viewFrame = [(UIView *)[sender view] frame];
            CGRect tempFrame;
            for (int j = i + 1;j < [self.sideImageList count]; j++)
            {
                tempFrame = viewFrame;
                viewFrame = [(UIView *)[self.sideImageList objectAtIndex:j] frame];
                [[self.sideImageList objectAtIndex:j] 
                 setFrame:tempFrame];
            }
            [[sender view] removeFromSuperview];
            
            [self.sideImageList removeObjectAtIndex:i];
        }
        else if (CGRectIntersectsRect(targetRect, 
                                 CGRectMake(self.theNewCopy.frame.origin.x,
                                            self.theNewCopy.frame.origin.y + 65,
                                            self.theNewCopy.frame.size.width,
                                            self.theNewCopy.frame.size.height)))
        {
            //setting the newImage properties
            UIImageView *newImage = [[UIImageView alloc] init];
			self.shouldSave = YES;
			self.shouldRefreshView = YES;
			//DATA MANAGER, work in progress
			ICDataManager* dataManager = [ICDataManager sharedDataManager];
			ICCustomImageView* thisView = (ICCustomImageView*) [sender view];
			NSInteger imgID = [dataManager addImage:thisView withArrayObject:self.currentVideo.imageArray];
			
			newImage.tag = imgID; //SAME TAG
			
            newImage.frame = CGRectMake(5, 10, 
                                        167, 
                                        117);
            newImage.layer.borderColor = [UIColor yellowColor].CGColor;
            newImage.layer.borderWidth = 2;
            newImage.image = self.theNewCopy.image;
            newImage.layer.backgroundColor = [UIColor blackColor].CGColor;
            [newImage setContentMode:UIViewContentModeScaleAspectFit];
            newImage.userInteractionEnabled = YES;
            //newImage.tag = [sender view].tag;
            
            UIImageView *closeButton = [[UIImageView alloc] 
                                        initWithFrame:CGRectMake(2, 2, 30, 30)];
            closeButton.image = [UIImage imageNamed:@"Close.png"];
			closeButton.tag = imgID; //VERY IMPORTANT!
            [closeButton setUserInteractionEnabled:YES];
            [newImage addSubview:closeButton];
            [closeButton release];
			
            UITapGestureRecognizer *selectImage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectImage:)];
            [newImage addGestureRecognizer:selectImage];

            
            
            //**********************************Pan gesture to delete Image***************************************//
//            UIPanGestureRecognizer *panImage = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragImage:)];
//            [newImage addGestureRecognizer:panImage];
//            [panImage release];
            
            UITapGestureRecognizer *deleteTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deleteImage:)];
            [closeButton addGestureRecognizer:deleteTap];
            [deleteTap release];
            
            
            [self.sideImageList addObject:newImage];
            [self.sideImageList addObject:[self.sideImageList objectAtIndex:self.sideImageList.count-2]];
            [self.sideImageList removeObjectAtIndex:[self.sideImageList count]-3];
            
            self.editButton.enabled = YES;
            NSLog(@"New values added!");
            
            [self selectImage:selectImage];
            [selectImage release];
            
			//changed
			[newImage release];
        }
        
        [self.temp removeFromSuperview];
        [self.tableView reloadData];
        if ([self.sideImageList count] > 5)
        {
            CGPoint bottomOffset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.bounds.size.height);
            [self.tableView setContentOffset:bottomOffset animated:YES];
        }
    }
	NSLog(@"Dragging Image inside : %@",self.temp);
}

- (void)loadDragImage:(id)data
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSMutableDictionary *dataDictionary = (NSMutableDictionary *)data;
    UIImageView *targetView = [[dataDictionary allValues] objectAtIndex:0];
    int index = [[[dataDictionary allKeys] objectAtIndex:0] intValue];
    if (self.videoTopView.currentSelection == self.videoTopView.libraryButton)
    {
        CGImageRef imageRef = [[[self.videoTopView.contentArray objectAtIndex:index] 
                            defaultRepresentation] 
                           fullResolutionImage];
        targetView.image = [UIImage imageWithCGImage:imageRef];
    }
    else if (self.videoTopView.currentSelection == self.videoTopView.stickersButton)
    {
        [self.videoTopView.contentArray objectAtIndex:index];
    }
    [pool drain];
}

- (void)getImageAtCenter:(UITapGestureRecognizer *)sender
{
    self.editButton.enabled = YES;
    //setting the newImage properties
    UIImageView *newImage = [[UIImageView alloc] init];
    self.theNewCopy = [(ICCustomImageView *)[sender view] imageView];
	self.shouldRefreshView = YES;
	self.shouldSave = YES;
    //DATA MANAGER, work in progress
    ICDataManager* dataManager = [ICDataManager sharedDataManager];
    ICCustomImageView* thisView = (ICCustomImageView*) [sender view];
    NSInteger imgID = [dataManager addImage:thisView withArrayObject:self.currentVideo.imageArray];
    
    newImage.tag = imgID; //SAME TAG
    
    newImage.frame = [(UIImageView *)[self.sideImageList objectAtIndex:0] frame];
    newImage.layer.borderColor = [UIColor yellowColor].CGColor;
    newImage.layer.borderWidth = 2;
    newImage.image = self.theNewCopy.image;
    
    NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
    NSString *tagString = [NSString stringWithFormat:@"%d",[(CustomImageView *)[sender view] imageView].tag - 1000];
    [tempDictionary setValue:newImage forKey:tagString];
    [self performSelector:@selector(loadDragImage:) 
               withObject:[tempDictionary autorelease]];
    
    newImage.layer.backgroundColor = [UIColor blackColor].CGColor;
    [newImage setContentMode:UIViewContentModeScaleAspectFit];
    newImage.userInteractionEnabled = YES;
    //newImage.tag = [sender view].tag;
    
    UIImageView *closeButton = [[UIImageView alloc] 
                                initWithFrame:CGRectMake(2, 2, 30, 30)];
    closeButton.image = [UIImage imageNamed:@"Close.png"];
    closeButton.tag = imgID; //VERY IMPORTANT!
    [closeButton setUserInteractionEnabled:YES];
    [newImage addSubview:closeButton];
    [closeButton release];
    
    UITapGestureRecognizer *selectImage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectImage:)];
    [newImage addGestureRecognizer:selectImage];

    
    
    UITapGestureRecognizer *deleteTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deleteImage:)];
    [closeButton addGestureRecognizer:deleteTap];
    [deleteTap release];
    
    [self.sideImageList addObject:newImage];
    [self.sideImageList addObject:[self.sideImageList objectAtIndex:self.sideImageList.count-2]];
    [self.sideImageList removeObjectAtIndex:[self.sideImageList count]-3];
    NSLog(@"New values added!");
    
    [self.tableView reloadData];
    
    [newImage release];
    
    
    if ([self.sideImageList count] > 5)
    {
        CGPoint bottomOffset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.bounds.size.height);
        [self.tableView setContentOffset:bottomOffset animated:YES];
    }
    
    [self selectImage:selectImage];
    [selectImage release];
    //changed
}

-(void)panImageFromText:(UIPanGestureRecognizer *)sender
{
	[self.view bringSubviewToFront:[sender view]];
    if (![self.videoTopView.finalText.text  isEqualToString:@"Touch to type                               Drag after typing"])
    {
        UIImageView *tempView;
        if ([sender state] == UIGestureRecognizerStateBegan) 
        {
            UIView *temp;
            temp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            
            self.temp = temp;
            [temp release];
            
            tempView = [[UIImageView alloc] init];
            
            [self.videoTopView.finalText setBackgroundColor:[UIColor clearColor]];
            CGRect tempFrame = self.videoTopView.finalText.frame;
            
            [self.videoTopView.finalText sizeToFit];
            tempView.image = [ICTopView imageWithView:self.videoTopView.finalText];
            [self.videoTopView.finalText setBackgroundColor:[UIColor whiteColor]];
            self.videoTopView.finalText.frame = tempFrame;
            CGPoint superPoint  = [sender.view.superview convertPoint:sender.view.frame.origin toView:nil];
            CGRect properSize;
            
            if ([tempView image].size.width < 703 &&
                [tempView image].size.height < 800)
            {
                properSize = CGRectMake([sender locationInView:nil].x, 
                                        [sender locationInView:nil].y - 65, 
                                        [tempView image].size.width, 
                                        [tempView image].size.height);
            }
            else
            {
                properSize = CGRectMake(superPoint.x, 
                                        superPoint.y - 65, 
                                        [tempView image].size.width/2,
                                        [tempView image].size.height/2);
            }
            
            tempView.frame = properSize;
            tempView.center = CGPointMake([sender locationInView:nil].x, 
                                          [sender locationInView:nil].y-65);
			//Code to handle dragging of images in potraitUpsideDown orientation
			UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
            if(currentOrientation == UIInterfaceOrientationPortraitUpsideDown)
			{
				tempView.center = CGPointMake(self.view.frame.size.width- [sender locationInView:nil].x, self.view.frame.size.height-[sender locationInView:nil].y+45);
			}
            tempView.contentMode = UIViewContentModeScaleAspectFit;
            [tempView setUserInteractionEnabled:YES];
            [self.view addSubview:self.temp];
            
            [self.temp addSubview:tempView];        
            [self setTheNewCopy:tempView];
            [tempView release];
        }
        
        tempView = self.theNewCopy;
        
        CGPoint translation = [sender translationInView:nil];
        [tempView setCenter:CGPointMake([tempView center].x+translation.x, 
                                        [tempView center].y+translation.y)];
        [sender setTranslation:CGPointZero inView:self.view];
        if ([sender state] == UIGestureRecognizerStateEnded) 
        {
            NSLog(@"Drag iMage");
            
            NSLog(@"%d", [[sender view] tag]);
            //CGPoint pt = CGPointMake(tempView.frame.origin.x + tempView.frame.size.width , tempView.frame.origin.y + tempView.frame.size.height);
            
            CGRect windowView = [self.videoView.superview convertRect:self.videoView.frame toView:nil];
            UIImageView *temp2 = tempView;
            temp2.center = CGPointMake(temp2.center.x - windowView.origin.x, 
                                       temp2.center.y - windowView.origin.y + 65);
            [tempView removeFromSuperview];
            [self.temp removeFromSuperview];
			
            
            UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] 
                                               initWithTarget:self action:@selector(handlePinchEvent:)];
            [pinch setDelegate:self];
            [temp2 addGestureRecognizer:pinch];
            
            UIRotationGestureRecognizer *rotate = [[UIRotationGestureRecognizer alloc] 
                                                   initWithTarget:self action:@selector(handleRotateEvent:)];
            [rotate setDelegate:self];
            [temp2 addGestureRecognizer:rotate];
            
            UIPanGestureRecognizer *lpgr = [[UIPanGestureRecognizer alloc] 
                                            initWithTarget:self action:@selector(handlePanGesture:)];
            [lpgr setDelegate:self];
            [temp2 addGestureRecognizer:lpgr];
            
            [self.videoView addSubview:temp2];
            [self setTheNewCopy:nil];
        }
    }

}
- (void)handlePinchEvent:(UIPinchGestureRecognizer *)sender
{
	[self.view bringSubviewToFront:[(UIPinchGestureRecognizer*)sender view]];
	
	if([(UIPinchGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) 
	{
		self.lastScale = 1.0;

		return;
	}
	
	CGFloat scale = 1.0 - (self.lastScale - [(UIPinchGestureRecognizer*)sender scale]);
	
	NSLog(@"\nscale : %f\nlastScale: %f",scale,self.lastScale);
	CGAffineTransform currentTransform = [(UIPinchGestureRecognizer*)sender view].transform;
	CGAffineTransform newTransform = CGAffineTransformScale(currentTransform, scale, scale);
	
	[[(UIPinchGestureRecognizer*)sender view] setTransform:newTransform];
	
	self.lastScale = [(UIPinchGestureRecognizer*)sender scale];
    
	//tracking SAVE
	self.shouldSave = YES;
	self.shouldRefreshView = YES;	
}

- (void)handleRotateEvent:(UIRotationGestureRecognizer *)sender
{
	[self.view bringSubviewToFront:[(UIRotationGestureRecognizer*)sender view]];
	
	if([(UIRotationGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) 
	{		
		self.lastRotation = 0.0;
		return;
	}
	CGFloat rotation = 0.0 - (self.lastRotation - [(UIRotationGestureRecognizer*)sender rotation]);
	
	CGAffineTransform currentTransform = [(UIPinchGestureRecognizer*)sender view].transform;
	CGAffineTransform newTransform = CGAffineTransformRotate(currentTransform,rotation);
	
	[[(UIRotationGestureRecognizer*)sender view] setTransform:newTransform];
	
	self.lastRotation = [(UIRotationGestureRecognizer*)sender rotation];

	if ([sender state] == UIGestureRecognizerStateEnded) {
//		NSLog(@"From ROTATE gesture method");
//		
//		ICDataManager* dataManager = [ICDataManager sharedDataManager];
//		ICCustomImageView* thisView = (ICCustomImageView*) [sender view];
//		[dataManager rotateTheImage:thisView withArrayObject:self.currentCollage.imageArray];
	}
	
	//tracking SAVE
	self.shouldSave = YES;
	self.shouldRefreshView = YES;	
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)selectImage:(id)sender
{
    if ([sender isKindOfClass:[UIImageView class]])
    {
        self.targetImage = (UIImageView *)sender;
        self.selectedImageTag = [sender tag];
    }
    else if ([sender isKindOfClass:[UITapGestureRecognizer class]])
    {
        self.targetImage = (UIImageView *)[sender view];
        self.selectedImageTag = [[sender view] tag];
    }
    for (UIView *view in self.sideImageList)
    {
        view.layer.borderWidth = 2;
    }
    
    
    if ([self.sideImageList count] < 2)
    {
        self.targetImage.layer.borderWidth = 2;
        return;
    }
    else if (self.targetImage == [self.sideImageList lastObject])
    {
        int index = [self.sideImageList indexOfObject:self.targetImage];
        
        self.targetImage = [self.sideImageList objectAtIndex:index - 1];
        self.videoView.image = self.targetImage.image;
        self.targetImage.layer.borderWidth = 8;
    }
    self.videoView.image = self.targetImage.image;
    self.targetImage.layer.borderWidth = 8;
    if (self.moviePlayerController.moviePlayer.playbackState == MPMoviePlaybackStatePaused ||
        self.moviePlayerController.moviePlayer.playbackState == MPMoviePlaybackStateStopped)
    {
        [self.moviePlayerController.moviePlayer stop];
        [self playbackDidFinish:nil];
    }
}

//====================================================================================
#pragma mark -
#pragma mark Loading Methods
- (void)loadVideoWithId:(NSInteger)videoId
{
	NSLog(@"in load method \n video id ----> %d",videoId);

	ICDataManager *dataManager = [ICDataManager sharedDataManager];
	ICVideo* video = [[dataManager openVideoWithId:videoId] retain];
	NSLog(@"The video object loaded is %@", video);
	 
	self.currentVideo = video;
    NSLog(@"adfasfa");
	[video release];
	
	NSLog(@"The video object of CollageVC is %@", self.currentVideo);
}

//====================================================================================
#pragma mark -
#pragma mark Save Operation
-(void) performSaveOperation
{
	NSAutoreleasePool* localPool = [[NSAutoreleasePool alloc]init];
    if ([self.currentVideo.imageArray count] < 2) {
        NSLog(@"Less Images. NOT SAVING, EXITING");
        
        [localPool drain];
        return;
    }
	ICDataManager* dataManager = [ICDataManager sharedDataManager];
	//RANDOM image ID
	ICImage* image = [self.currentVideo.imageArray objectAtIndex:0];
	UIImage* videoThumb = [dataManager generateThumbnailForVideoWithId:self.currentVideo.mediaId withRandomImageId:image.imageID];

	[dataManager saveVideoWithId:self.currentVideo.mediaId withVideoObject:self.currentVideo];
	
	self.shouldRefreshView = NO;
	self.shouldSave = NO;
	
	[dataManager removeNullValuesFromDatabase];
	NSLog(@"The video thumbnail is %@", videoThumb);
	[localPool drain];
}
-(void) performSaveOperationWithTabChangeToIndex:(NSNumber*)inIndex
{
    NSAutoreleasePool* localPool = [[NSAutoreleasePool alloc] init];
    [self performSaveOperation];
    /*if (self.fromTab) {
        [self performSelectorOnMainThread:@selector(dismissAlert) 
                               withObject:nil 
                            waitUntilDone:YES];
    }*/
    [self.saveAlert dismissWithClickedButtonIndex:0 animated:YES];        
    NSInteger index = [inIndex integerValue];
	self.tabBarController.selectedIndex = index;

    [self.saveAlert dismissWithClickedButtonIndex:0 animated:YES];
    [localPool drain];
}
//====================================================================================
#pragma mark -
#pragma mark Recreating Video
-(void)	refreshView
{
	NSLog(@"Clear the views");
	
	[self.sideImageList removeAllObjects];
	//self.videoView.image = nil;
	
	[self placeImagesFromArray:self.currentVideo.imageArray];
}
-(void) placeImagesFromArray:(NSMutableArray*)inImageArray
{
	NSLog(@"Placing images from Array");
	NSLog(@"%d images have to be placed", [inImageArray count]);
	
	/*
	if ([inImageArray count] == 0) {
		NSLog(@"No images to be placed!");
		return;
	}
	*/ 
	 
	/*
	 Recreate:
	 1. sideImageList (NSMutableArray)	DONE
	 2. sideScroller (UIScrollView)		NA
	 3. selectImage (gesture)			DONE
	 4. deleteTap (gesture)				DONE
	 5. newImage (UIImageView)			DONE
	 6. closeButton (UIImageView)		DONE
	 */	

	for (ICImage *image in inImageArray)
    {
        UIImage *displayImage = [UIImage imageWithContentsOfFile:image.path];
        
        UIImageView *newImage = [[UIImageView alloc] init];
        newImage.frame = CGRectMake(5, 10, 
                                    167, 
                                    117);
        newImage.layer.borderColor = [UIColor yellowColor].CGColor;
        newImage.layer.borderWidth = 2;
        newImage.image = displayImage;
        newImage.layer.backgroundColor = [UIColor blackColor].CGColor;
        [newImage setContentMode:UIViewContentModeScaleAspectFit];
        newImage.userInteractionEnabled = YES;
        
        newImage.tag = image.imageID; //SAME TAG
        
        UIImageView *closeButton = [[UIImageView alloc] 
                                    initWithFrame:CGRectMake(2, 2, 30, 30)];
        closeButton.image = [UIImage imageNamed:@"Close.png"];

        closeButton.tag = image.imageID; //VERY IMPORTANT!

        [closeButton setUserInteractionEnabled:YES];
        [newImage addSubview:closeButton];
        [closeButton release];
        
        UITapGestureRecognizer *selectImage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectImage:)];
        [newImage addGestureRecognizer:selectImage];
        [selectImage release];
        
        UITapGestureRecognizer *deleteTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deleteImage:)];
        [closeButton addGestureRecognizer:deleteTap];
        [deleteTap release];

        [self.sideImageList addObject:newImage];
		[newImage release];
    }
	
	UIImageView *blankImage = [[UIImageView alloc] init];
	blankImage.frame = CGRectMake(5, 10, 
								  167, 
								  kSizeOfImage-5);
	blankImage.layer.borderColor = [UIColor yellowColor].CGColor;
	blankImage.layer.borderWidth = 2;
	blankImage.layer.backgroundColor = [UIColor blackColor].CGColor;
	[blankImage setContentMode:UIViewContentModeScaleAspectFit];
	blankImage.userInteractionEnabled = YES;
	
    if (self.sideImageList.count > 1)
    {
        [self selectImage:[self.sideImageList objectAtIndex:0]];
    }
    else
    {
        self.videoView.image = nil;
        self.editButton.enabled = NO;
    }
	[self.sideImageList addObject:blankImage];
	[blankImage release];
	[self.tableView reloadData];
	
	self.shouldSave = NO;
	self.shouldRefreshView = NO;
    
    if (self.moviePlayerController != nil)
    {
        self.moviePlayerController.moviePlayer.view.alpha = 0;
        self.moviePlayerController.moviePlayer.view.userInteractionEnabled = NO;
    }
    //CALL method to set other video properties
    [self setVideoProperties];
    [self.tableView reloadData];
}

-(void) setVideoProperties
{
    NSLog(@"SET VIDEO PROPERTIES");
    
    self.videoGenerator.repeat = self.currentVideo.shouldAudioRepeat;
    self.videoGenerator.isAudio = self.currentVideo.audioEnabled;
    self.videoGenerator.fadeInTime = self.currentVideo.audioFadeInValue;
    self.videoGenerator.fadeOutTime = self.currentVideo.audioFadeOutValue;
    self.videoGenerator.timePerImage = self.currentVideo.timePerImage;
    self.videoGenerator.animationDuration = self.currentVideo.animationDuration;
    self.videoGenerator.transitionEffect = self.currentVideo.transitionEffect;
    self.videoGenerator.transitionSmoothness = self.currentVideo.transitionSmoothness;
    
}
//====================================================================================
#pragma mark -
#pragma mark Tab Bar Method
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController 
{
	NSLog(@"Changing tabs from Video VC");
    NSLog(@"Should Select VC %@", viewController);
	//NSLog(@"objectAtIndex 0  %@", [tabBarController.viewControllers objectAtIndex:0]);
    
    if ( viewController == [tabBarController.viewControllers objectAtIndex:0] || viewController == [tabBarController.viewControllers objectAtIndex:1])
    {
        if ( viewController == [tabBarController.viewControllers objectAtIndex:0])
        {
            self.tab = 0;
        }
        else if (viewController == [tabBarController.viewControllers objectAtIndex:1])
        {
            self.tab = 1;
        }
        if (self.moviePlayerController.moviePlayer.playbackState == MPMoviePlaybackStatePlaying) 
        {
            [self.moviePlayerController.moviePlayer pause];
        }
        if (self.shouldSave) 
        {
            UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:@"Video Not Saved" 
                                                                message:@"Do you wish to save the video ?" 
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Save",nil];
            [tempAlert show];
            [tempAlert setDelegate:self];
            self.saveAlert = tempAlert;
            [tempAlert release];
             
            return NO;
        }
        else
        {
            if (viewController == [self.tabBarController.viewControllers objectAtIndex:1])
            {
                UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:@"Loading data" 
                                                                    message:@"Please wait while we load the data" 
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:nil];
                UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]; //17.4.12
                // Adjust the indicator so it is up a few pixels from the bottom of the alert
                indicator.center = CGPointMake(140 ,100);
                [indicator startAnimating];
                [tempAlert addSubview:indicator];
                [indicator release];
                [(ImageCanvas1AppDelegate*)[[UIApplication sharedApplication] delegate] setMainAlert:tempAlert];
                [tempAlert show];
                [tempAlert release];
                
                NSNumber* tabIndex = nil;
                if (viewController == [tabBarController.viewControllers objectAtIndex:0])
                {
                    tabIndex = [NSNumber numberWithInt:0];
                }
                else 
                {
                    tabIndex = [NSNumber numberWithInt:1];
                }
                
                [NSThread detachNewThreadSelector:@selector(performSaveOperationWithTabChangeToIndex:) toTarget:self withObject:tabIndex];
                
                return NO;
            }
        }
        //return NO;
    }
    else if(viewController == [tabBarController.viewControllers objectAtIndex:2])
    {
        return NO;
    }
    
    return YES;
}

//====================================================================================
#pragma mark -
#pragma mark Add New Video
-(void)	addNewVideo
{
	NSAutoreleasePool* localPool = [[NSAutoreleasePool alloc] init];
	ICDataManager* dataManager = [ICDataManager sharedDataManager];
	NSInteger newVideoID = [dataManager getNewVideoID];
	ICVideo* newVideo = [[dataManager openVideoWithId:newVideoID] retain];
	self.currentVideo = newVideo;
	[newVideo release];
	
	NSLog(@"New Video created %@", newVideo);
	NSLog(@"The video ID is %d", self.currentVideo.mediaId);
	NSMutableArray* tempArray = [[NSMutableArray alloc] init];
	self.currentVideo.imageArray = tempArray;
	[tempArray release];
	self.videoView.image = nil;
	self.isNew = YES;
	self.shouldSave = NO;
	self.shouldRefreshView = NO;
    self.videoView.image = nil;
	
	[localPool drain];	
}


//====================================================================================
#pragma mark -
#pragma mark moviePlayer

-(IBAction)playMovie
{
    self.isPreview = NO;
    if ([self.sideImageList count] > 2)
    {
        NSString* videoFileName = [NSString stringWithFormat:@"%d.%@", self.currentVideo.mediaId, @"mov"];
        NSLog(@"Video File Name is %@", videoFileName);
        NSFileManager* fileManager = [NSFileManager defaultManager];
       
        NSString* docDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        NSString*  videoDir = [docDir stringByAppendingPathComponent:@"Video"];
        NSString* finalPath = [NSString stringWithFormat:@"%@/%@",videoDir, videoFileName];
        
        if (self.shouldSave == NO) {
            if (![fileManager fileExistsAtPath:finalPath]) {
                self.shouldSave = YES;
            }
        }

        
        if (self.shouldSave) { //        if (self.shouldSave && self.shouldRefreshView) {
            NSLog(@"We should call imageToVideo method");
            if(self.videoAlert != nil)
            {
                 [self.progressView setProgress:0.0];
                [self.videoAlert show];
            }
            else
                [self performSelectorOnMainThread:@selector(showAlert) withObject:nil waitUntilDone:YES];
            
            [self performSelectorInBackground:@selector(prepareVideo:) withObject:videoFileName];
            //[self.videoGenerator prepareVideo:videoFileName withImages:self.sideImageList andAudio:self.audioUrl];
        }
        else {
            NSLog(@"We should just play the video");
            BOOL fileIsThere = [fileManager fileExistsAtPath:finalPath];
            if (fileIsThere) {
                if (self.moviePlayerController.moviePlayer.playbackState == MPMoviePlaybackStatePlaying)
                {
                    [self.moviePlayerController.moviePlayer stop];
                }
                else
                {
                    [self playVideoInSubviewWithFileName:finalPath];
                }
            }
            
            //[self playVideoWithFileName:finalPath];
        }
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Enough Images Selected" 
                                                        message:@"Please add atleast 2 images before making Video"
                                                       delegate:self 
                                              cancelButtonTitle:@"Ok" 
                                              otherButtonTitles:nil, nil] ;
        [alert show];
        [alert release];
    }
}

- (void) moviePlayBackDidFinish:(NSNotification*)notification {
	
    MPMoviePlayerController *moviePlayer = [notification object];
	if ([moviePlayer respondsToSelector:@selector(setFullscreen:animated:)])
	{
		[moviePlayer.view removeFromSuperview];
	}
}

-(void)	playVideoWithFileName:(NSString*)inFileName
{
    NSError *setCategoryError = nil; 
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &setCategoryError]; 
    
    if (setCategoryError) 
    { 
        //handle error 
    }
    NSURL *videoUrl = [[NSURL alloc] initFileURLWithPath:inFileName isDirectory:NO];
    MPMoviePlayerViewController *videoPlayerView = [[MPMoviePlayerViewController alloc] 
                                                    initWithContentURL:videoUrl];
    
    
    [self presentMoviePlayerViewControllerAnimated:videoPlayerView];
    [videoPlayerView.moviePlayer play];
    [videoPlayerView release];
    [videoUrl release];
}

-(void)	playVideoInSubviewWithFileName:(NSString*)inFileName
{
    NSError *setCategoryError = nil; 
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &setCategoryError]; 
    
    [self.playButton setTitle:@"Stop" forState:UIControlStateNormal];
    if (setCategoryError) 
    { 
        //handle error 
    }
    NSURL *videoUrl = [[NSURL alloc] initFileURLWithPath:inFileName isDirectory:NO];
    if (self.moviePlayerController == nil)
    {
        MPMoviePlayerViewController *videoPlayerView;
        videoPlayerView = [[MPMoviePlayerViewController alloc] 
                                                        initWithContentURL:videoUrl];

        self.moviePlayerController = videoPlayerView;
        [videoPlayerView release]; //[NEW LEAK FIXED]
        self.moviePlayerController.view.frame = self.videoView.bounds;
        
        self.moviePlayerController.moviePlayer.controlStyle = MPMovieControlStyleDefault;
        [self.videoView addSubview:videoPlayerView.view];
        
        self.moviePlayerController.moviePlayer.shouldAutoplay = NO;
    }
    self.moviePlayerController.moviePlayer.contentURL = videoUrl;

    self.moviePlayerController.moviePlayer.view.userInteractionEnabled = YES;
    self.moviePlayerController.moviePlayer.view.alpha = 1.0;
    
    [self.moviePlayerController.moviePlayer prepareToPlay];
    [self.moviePlayerController.moviePlayer play];
    [videoUrl release];
}

 - (void)deleteImage:(UITapGestureRecognizer *)sender
{
	NSLog(@"Tag to be deleted %d", sender.view.tag);
	//DATA MANAGER, work in progress
	ICDataManager* dataManager = [ICDataManager sharedDataManager];
	[dataManager removeImageFromVideo:sender.view.tag withArray:self.currentVideo.imageArray];
	
    int i;
    [(UIImageView *)[sender view] setImage:nil];

    for (i = 0; i < [self.sideImageList count]; i++)
    {
        if ([sender.view.superview isEqual:[self.sideImageList objectAtIndex:i]])
        {
            break;
        }
    }
    [[sender view].superview removeFromSuperview];
    
    [self.sideImageList removeObjectAtIndex:i];
    
    UIImageView *imageView = (UIImageView *)[self.sideImageList objectAtIndex:i];
    if ([sender view].superview == self.targetImage)
    {
        [self selectImage:imageView];
    }
    [self.tableView reloadData];
	
    if (self.sideImageList.count == 1)
    {
        self.videoView.image = nil;
        self.editButton.enabled = NO;
    }
	self.shouldSave = YES;
	self.shouldRefreshView = YES;

}

#pragma -
#pragma mark Tutorial methods

-(IBAction)closeTutorial:(id)sender
{
	self.videoTopView.alpha=1;
//	self.view.alpha=1;
    self.tableView.alpha=1;
    self.videoView.alpha=1;
    self.editButton.alpha =1;
    self.tutorialButton.alpha =1;
    self.playButton.alpha =1;
	self.tutorialView.hidden = YES;
	self.navigationItem.leftBarButtonItem.enabled = YES;
	self.navigationItem.rightBarButtonItem.enabled = YES;
}

-(IBAction)showTutorial:(id)sender
{
    self.videoTopView.alpha=0.6;
//	self.view.alpha=0.6;
    self.tableView.alpha=0.6;
    self.videoView.alpha=0.6;
    self.editButton.alpha = 0.6;
    self.tutorialButton.alpha = 0.6;
    self.playButton.alpha =0.6;
	self.tutorialView.hidden = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
	self.navigationItem.rightBarButtonItem.enabled = NO;
	[self.view bringSubviewToFront:self.tutorialView];
}


#pragma mark -
#pragma mark Effect methods

-(IBAction)editImage:(id)sender
{
    if (self.targetImage.image != nil)
    {
        [self displayEditorForImage:self.targetImage.image];
    }
}

- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image
{
    // Handle the result image here
    self.targetImage.image = image;
    self.videoView.image = image;
    [self dismissModalViewControllerAnimated:YES];
     // [editor.view removeFromSuperview];
    
    // Handle the result image here
    self.shouldSave = YES;
	self.shouldRefreshView = YES;

	if (image == nil) {
		NSLog(@"No real effects added!");
		return;
	}
	
	ICDataManager* dataManager = [ICDataManager sharedDataManager];
	NSInteger imgID = self.selectedImageTag;
	[dataManager addEffectsToImage:image imageId:imgID withArray:self.currentVideo.imageArray]; //this will create a new copy of the file, so that other images dont get affected
	
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor
{
    // Handle cancelation here
    [self dismissModalViewControllerAnimated:YES];
    
   // [editor.view removeFromSuperview];
}

- (void)displayEditorForImage:(UIImage *)imageToEdit
{
    AFPhotoEditorController *editorController = [[AFPhotoEditorController alloc] initWithImage:imageToEdit];


    
    [editorController setDelegate:self];
    
    editorController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:editorController animated:YES];
    
}

//====================================================================================================================


//====================================================================================
#pragma mark -
#pragma mark ImageToVideo Delegate methods

- (void) didProgressVideoGenereation:(float)progress
{
    NSLog(@"Progress - %f",progress);
    if (self.progressView!=nil)
    {
        [self performSelectorInBackground:@selector(updateProgress:) withObject:[NSNumber numberWithFloat:(float)progress]];
    }
}

- (void)didFinishPreparingVideoWithUrl:(NSString *)url
{
    /*
    if (self.shouldPlayVideo == NO) {
        ICDataManager* dataManager = [ICDataManager sharedDataManager];
        [dataManager setVideoPath:url forVideoID:self.currentVideo.mediaId];

        return;
    }
     */
    
    if (!self.fromTab)
    {
        if (self.isPreview)
        {
            [self performSelectorOnMainThread:@selector(playVideoWithFileName:) 
                                   withObject:url 
                                waitUntilDone:NO];
        }
        else
        {
            [self performSelectorOnMainThread:@selector(playVideoInSubviewWithFileName:)
                                   withObject:url 
                                waitUntilDone:NO];
        }
    }
    ICDataManager* dataManager = [ICDataManager sharedDataManager];
    [dataManager setVideoPath:url forVideoID:self.currentVideo.mediaId];

    NSLog(@"[SAVE IN A THREAD] ? %@", [NSNumber numberWithBool:self.shouldSave]);
    if (self.shouldSave) {
        self.currentVideo.mediaPath = url;
        //[NSThread detachNewThreadSelector:@selector(performSaveOperation) toTarget:self withObject:nil];			
        [self performSaveOperation];
        //[NSThread detachNewThreadSelector:@selector(performSaveOperationWithTabChangeToIndex:) toTarget:self withObject:[NSNumber numberWithInt:self.tab]];
    }
    
    [self performSelectorOnMainThread:@selector(dismissAlert) 
                           withObject:nil 
                        waitUntilDone:YES];
    
    if (self.fromTab)
    {
        [self performSelectorOnMainThread:@selector(changeTab:)
                               withObject:[NSNumber numberWithInt:self.tab]
                            waitUntilDone:YES];
    }
    self.fromTab = NO;
}

- (void)changeTab:(NSNumber *)tab
{
    self.tabBarController.selectedIndex = [tab intValue];
}

//====================================================================================
#pragma mark -
#pragma mark Video-Setting Delegate methods

- (void)didChangeRepeatToggle:(BOOL)value
{
    self.videoGenerator.repeat = value;
    self.shouldSave = YES;
    
    self.currentVideo.shouldAudioRepeat = value;
    self.shouldSave = YES; //DATA MANAGER
}

- (void)didChangeFadeInSliderValue:(float)value
{
    self.fadeInTime = value;
    self.videoGenerator.fadeInTime = value;
	self.currentVideo.audioFadeInValue = value; //DATA MANAGER
	self.shouldSave = YES;
}

- (void)didChangeFadeOutSliderValue:(float)value
{
    self.fadeOutTime = value;
    self.videoGenerator.fadeOutTime = value;
	self.currentVideo.audioFadeOutValue = value; //DATA MANAGER
	self.shouldSave = YES;
}

- (void)didChangeAudioToggle:(BOOL)toggle
{
    self.videoGenerator.isAudio = toggle;
    [self.settingPopover presentPopoverFromBarButtonItem:self.item permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO]; 
    
    self.shouldSave = YES;
    self.currentVideo.audioEnabled = toggle; //DATA MANAGER
}

- (void)didChangeTransitionEffect:(eTransitionEffect)effect
{
    self.transitionEffect = effect;
    self.videoGenerator.transitionEffect = effect;
	NSLog(@"[DM][T Effect] %d", effect);
	self.currentVideo.transitionEffect = effect; //DATA MANAGER
	self.shouldSave = YES;	
}

- (void)didChangeTransitionSmootheness:(eTransitionSmoothness)level
{
    self.transitionSmoothness = level;
    self.videoGenerator.transitionSmoothness = level;
	NSLog(@"[DM][T Smoothness] %d", level);
	self.currentVideo.transitionSmoothness = level; //DATA MANAGER
	self.shouldSave = YES;	
}

- (void)didChangeImageDuration:(float)value
{
    self.videoGenerator.timePerImage = value;
    
    self.currentVideo.timePerImage = value; //DATA MANAGER
    self.shouldSave = YES;
}

- (void)didChangeAnimationDuration:(float)value
{
    self.videoGenerator.animationDuration = value;
    
    self.currentVideo.animationDuration = value; //DATA MANAGER
    self.shouldSave = YES;
    
}

- (void)didChangeAudioSelection:(NSString *)name
{
    NSLog(@"Name = %@",name);
    
    self.currentVideo.audioPath = name;
    self.shouldSave = YES; //DATA MANAGER
}
//====================================================================================
#pragma mark -
#pragma mark Draging Image
- (void)showAlert
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Generating Video" 
                                                    message:@"Please wait!\n\n" 
                                                   delegate:self cancelButtonTitle:@"Cancel" 
                                          otherButtonTitles:nil, nil];
    
    [alert performSelectorOnMainThread:@selector(show)
                            withObject:nil
                         waitUntilDone:YES];
    [alert setDelegate:self];
    self.videoAlert = alert;
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
//    [progressView setFrame:CGRectMake(alert.bounds.size.width - progressView.bounds.size.width - 95,
//                                      alert.bounds.size.height - progressView.bounds.size.height - 80, 
//                                      progressView.bounds.size.width, 
//                                      progressView.bounds.size.height)];

    [progressView setCenter:CGPointMake(alert.bounds.size.width/2 ,  alert.bounds.size.height/2)];
    self.progressView = progressView;
    [alert addSubview:self.progressView];
    [progressView release];
    [alert release];
    [pool release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex 
{
    if ([alertView.title isEqualToString:@"Video Not Saved"])
    {
        if (buttonIndex == [alertView cancelButtonIndex]) 
        {
            /*
            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]; //17.4.12
            // Adjust the indicator so it is up a few pixels from the bottom of the alert
            indicator.center = CGPointMake(self.saveAlert.bounds.size.width / 2, self.saveAlert.bounds.size.height - 40);
            [indicator startAnimating];
            [self.saveAlert addSubview:indicator];
            [indicator release];
            [(ImageCanvas1AppDelegate*)[[UIApplication sharedApplication] delegate] setMainAlert:self.saveAlert];

            [NSThread detachNewThreadSelector:@selector(performSaveOperationWithTabChangeToIndex:) toTarget:self withObject:[NSNumber numberWithInt:self.tab]];
             */
            
            NSLog(@"Video should NOT be saved");
            /*
            ICDataManager* dataManager = [ICDataManager sharedDataManager];
            [dataManager resetVideoPathForVideoID:self.currentVideo.mediaId];
            */
            self.tabBarController.selectedIndex = self.tab;
        }
        else
        {
            [self playMovie];
            self.fromTab = YES;
        }
    }
    else
    {
        if (buttonIndex == [alertView cancelButtonIndex]) 
        {
            [self.videoGenerator cancelVideoGeneration];
            self.fromTab = NO;
        }
    }
}

- (void)updateProgress:(NSNumber*)progress
{
    if (self.progressView!=nil)
    {
        NSLog(@"NUMber - %@",progress);
        [self.progressView setProgress:[progress floatValue]];
    }
}

- (void)dismissAlert
{
    if (self.videoAlert != nil)
    {
        [self.videoAlert dismissWithClickedButtonIndex:0 animated:YES];
    }
}

- (void)playMovieWithUrl:(NSURL *)movieUrl
{
    MPMoviePlayerViewController *videoPlayerView = [[MPMoviePlayerViewController alloc] 
                                                    initWithContentURL:movieUrl];
    
    //[videoPlayerView setContentURL: [NSURL URLWithString:videopath]];
    [self presentMoviePlayerViewControllerAnimated:videoPlayerView];
    //[videoPlayerView.moviePlayer play];
    [videoPlayerView release];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[(ImageCanvas1AppDelegate *)[[UIApplication sharedApplication] delegate] tabBarController] 
     setDelegate:(ImageCanvas1AppDelegate *)[[UIApplication sharedApplication] delegate]];
}

@end
