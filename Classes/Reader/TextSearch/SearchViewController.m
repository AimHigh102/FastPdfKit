    //
//  MFSearchViewController.m
//  FastPdfKit
//
//  Created by Nicolò Tosi on 10/21/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "SearchViewController.h"
#import "MFTextItem.h"
#import "MFDocumentManager.h"
#import "DocumentViewController.h"
#import "ReaderViewController.h"
#import "TextSearchOperation.h"
#import "SearchManager.h"
#import "SearchResultCellView.h"
#import "SearchResultView.h"

/* This parameter set the zoom level that will be performed when you choose the next result, there's another one in the MiniSearchView.m */
#define ZOOM_LEVEL 4.0

@interface SearchViewController()

-(void)stopSearch;
-(void)startSearchWithTerm:(NSString *)term;

@end

@implementation SearchViewController

@synthesize searchBar, searchTableView;
@synthesize switchToMiniBarButtonItem, activityIndicatorView;
@synthesize delegate;
@synthesize searchManager;
@synthesize toolbar;

#pragma mark - Notification listeners

-(void)handleSearchResultsAvailableNotification:(NSNotification *)notification {
 
    NSDictionary * userInfo = [[notification userInfo]retain];
    
    NSArray * searchResult = [userInfo objectForKey:kNotificationSearchInfoResults];
    
    if([searchResult count] > 0) {
        
        [searchTableView reloadData];
    }
    
    [userInfo release];
}

-(void)handleSearchDidStopNotification:(NSNotification *)notification {
    
    NSString *title = NSLocalizedString(@"SEARCH_CANCEL_BTN_TITLE", @"Cancel");
    if ([title isEqualToString:@"SEARCH_CANCEL_BTN_TITLE"]){
        title = @"Cancel";
    }
    
    [cancelStopBarButtonItem setTitle:title];
	[activityIndicatorView stopAnimating];
}

-(void)handleSearchDidStartNotification:(NSNotification *)notification {
    
    // Clean up if there are old search results.
    
    [searchTableView reloadData];
		
	// Set up the view status accordingly.
	
    NSString *title = NSLocalizedString(@"SEARCH_STOP_BTN_TITLE", @"Cancel");
    if ([title isEqualToString:@"SEARCH_STOP_BTN_TITLE"]){
        title = @"Stop";
    }
    
	[cancelStopBarButtonItem setTitle:title];
	[activityIndicatorView startAnimating];
	[cancelStopBarButtonItem setEnabled:YES];
	[switchToMiniBarButtonItem setEnabled:YES];
}

-(void)handleSearchGotCancelledNotification:(NSNotification *)notification {
    // Setup the view accordingly.
	
	[searchBar setText:@""];
	[activityIndicatorView stopAnimating];
	[cancelStopBarButtonItem setEnabled:NO];
	[switchToMiniBarButtonItem setEnabled:NO];
//	[searchTableView reloadData];
	
	[[self delegate]dismissSearchViewController:self];
}

#pragma mark -
#pragma mark Start and Stop

-(void)stopSearch {
	
	// Tell the manager to stop the search and let the delegate's methods to refresh this view.
    if(self.searchManager) {
        [searchManager stopSearch];
    }
}

-(void)startSearchWithTerm:(NSString *)aSearchTerm {
	
	// Tell the manager to start the search  and let the delegate's methods to refresh this view.
    // Create a new search manager with the search term
    SearchManager * searchManager = [SearchManager new];
    self.searchManager = searchManager;
    
    self.searchManager.searchTerm = aSearchTerm;
    self.searchManager.startingPage = [self.delegate pageForSearchViewController:self];
    self.searchManager.document = [self.delegate documentForSearchViewController:self];
    self.searchManager.ignoreCase = ignoreCase;
    self.searchManager.exactMatch = exactMatch;
    
    // Start the search
    [self.searchManager startSearch];
    
    // Inform the delegate of the search in progress
    [self.delegate searchViewController:self addSearch:self.searchManager];

}

-(void)cancelSearch {
	
    // Tell the manager to cancel the search and let the delegate's  methods to refresh this view.
    if(self.searchManager) {
        [self.searchManager stopSearch];
        [self.delegate searchViewController:self removeSearch:self.searchManager];
        self.searchManager = nil;
        [self.searchTableView reloadData];
    }
}

#pragma mark -
#pragma mark Actions

-(IBAction)actionCancelStop:(id)sender {
    
    if(!self.searchManager) {
        return; // Nothing to do here
    }
    
    // If the search is running, stop it. Otherwise, cancel the
    // search entirely.
    
    if(self.searchManager.running) {
        
        [self stopSearch];
        
    } else {
        
        [self cancelSearch];
    }
}


-(IBAction)actionBack:(id)sender {
	
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)actionMinimize:(id)sender {
	
    // We are going to use the first item to initialize the mini view.
    
    NSIndexPath * visibleIndexPath = nil;
    
    MFTextItem * firstItem = nil;
    
    NSArray * results = [self.searchManager allSearchResults];
    
    if(results.count > 0) {
        
        visibleIndexPath = [[self.searchTableView indexPathsForVisibleRows]objectAtIndex:0];
        firstItem = [[results objectAtIndex:visibleIndexPath.section] objectAtIndex:visibleIndexPath.row];
        
        if(firstItem!=nil) {
            
            [self.delegate searchViewController:self switchToMiniSearchView:firstItem];
        }
    }
}
		
#pragma mark -
#pragma mark UISearchBarDelegate methods

-(BOOL)searchBarShouldEndEditing:(UISearchBar *)sBar {
	
	[sBar resignFirstResponder];
	
	return YES;
}

-(void) searchBarCancelButtonClicked:(UISearchBar *)sBar {
	
	// Dismiss the keyboard and cancel the search.
	
	[sBar resignFirstResponder];
	[self cancelSearch];
}

-(void) searchBarSearchButtonClicked:(UISearchBar *)sBar {

	// Let the startSearch helper function handle the spawning of the operation.

	[sBar resignFirstResponder];
	
    NSString * searchTerm = searchBar.text;
    [self startSearchWithTerm:searchTerm];
}

-(BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    [self cancelSearch];
    
    return YES;
}
		 
#pragma mark -
#pragma mark UITableViewDelegate and DataSource methods

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    NSArray *searchResult = self.searchManager.sequentialSearchResults[indexPath.section];
    MFTextItem * item = [searchResult objectAtIndex:indexPath.row];
    
    // Dismiss this viewcontroller and tell the DocumentViewController to move to the selected page after
    // displaying the mini search view.
    
    [self.delegate searchViewController:self switchToMiniSearchView:item];
    
    [self.delegate searchViewController:self setPage:[item page] withZoomOfLevel:ZOOM_LEVEL onRect:CGPathGetBoundingBox([item highlightPath])];
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *cellId = @"searchResultCellId";
	
	// Just costumize the cell with the content of the MFSearchItem for the right row in the right section.
	
    NSArray *searchResult = self.searchManager.sequentialSearchResults[indexPath.section];
	MFTextItem *searchItem = [searchResult objectAtIndex:indexPath.row];
    
	// This is a custom view cell that display an MFTextItem directly.
    
	SearchResultCellView *cell = (SearchResultCellView *)[tableView dequeueReusableCellWithIdentifier:cellId];
	
	if(nil == cell) {
	
		// Simple initialization.
        
		cell = [[[SearchResultCellView alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId]autorelease];
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	}
    
    [cell.searchResultView setSnippet:searchItem.text boldRange:searchItem.searchTermRange];
    cell.searchResultView.pageNumberLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)[searchItem page]];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {

    // Let's get the MFTextItem from its container array.
	
    NSArray *searchResult = self.searchManager.sequentialSearchResults[indexPath.section];
	MFTextItem * item = [searchResult objectAtIndex:indexPath.row];
	
	// Dismiss this viewcontroller and tell the DocumentViewController to move to the selected page after
	// displaying the mini search view.
	
	[delegate switchToMiniSearchView:item];
	
	[delegate setPage:[item page] withZoomOfLevel:ZOOM_LEVEL onRect:CGPathGetBoundingBox([item highlightPath])];

}

-(NSInteger) tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	
	// Nothing special here.
    NSArray *searchResult = self.searchManager.sequentialSearchResults[section];
    
    return searchResult.count;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	
	// Nothing special here.
    return self.searchManager.sequentialSearchResults.count;
}

#pragma mark UIViewController methods


 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
		switchToMiniBarButtonItem.enabled = NO;
        ignoreCase = YES;
        exactMatch = NO;
        
        NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(handleSearchDidStartNotification:) name:kNotificationSearchDidStart object:nil];
        [notificationCenter addObserver:self selector:@selector(handleSearchDidStopNotification:) name:kNotificationSearchDidStop object:nil];
        [notificationCenter addObserver:self selector:@selector(handleSearchResultsAvailableNotification:) name:kNotificationSearchResultAvailable object:nil];
	}
    return self;
}

-(void)viewWillAppear:(BOOL)animated 
{
	// Different setup if search is running or not.
	[super viewWillAppear:animated];
    
    self.searchManager = [self.delegate searchForSearchViewController:self]; // Retrieve the searh currently displayed
    
	if(self.searchManager.running) {
		
		[self.activityIndicatorView startAnimating];
        NSString *title = NSLocalizedString(@"SEARCH_STOP_BTN_TITLE", @"Cancel");
        if ([title isEqualToString:@"SEARCH_STOP_BTN_TITLE"]){
            title = @"Stop";
        }

		[self.cancelStopBarButtonItem setTitle:title];
		
	} else {
	    NSString *title = NSLocalizedString(@"SEARCH_CANCEL_BTN_TITLE", @"Cancel");
        if ([title isEqualToString:@"SEARCH_CANCEL_BTN_TITLE"]){
            title = @"Cancel";
        }
        
		[self.cancelStopBarButtonItem setTitle:title];
	} 
	
	// Common setup.
	
	[self.searchBar setText:[searchManager searchTerm]];
	
	[self.searchTableView reloadData];
    
    if(self.searchManager.sequentialSearchResults.count == 0) {
		[searchBar becomeFirstResponder];
    }
}

-(IBAction)actionToggleIgnoreCase:(id)sender
{
    ignoreCase=!ignoreCase;
}

-(IBAction)actionToggleExactMatch:(id)sender
{
    exactMatch=!exactMatch;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{	
    [super viewDidLoad];
    
    /* Setup bottom toolbar with label and switches */
    
    // Ignore case label and switch.
    
    UILabel * ignoreCaseLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 25)];
    ignoreCaseLabel.text = @"Ignore case";
    ignoreCaseLabel.textColor = [UIColor lightTextColor];
    ignoreCaseLabel.backgroundColor = [UIColor clearColor];
    UIBarButtonItem * ignoreCaseLabelBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:ignoreCaseLabel];
    [ignoreCaseLabel release];
    
    UISwitch * ignoreCaseSwitch = [[UISwitch alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
    ignoreCaseSwitch.on = ignoreCase;
    [ignoreCaseSwitch addTarget:self action:@selector(actionToggleIgnoreCase:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem * ignoreCaseSwitchBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:ignoreCaseSwitch];
    [ignoreCaseSwitch release];
    
    // Exact match label and switch.
    
    UILabel * exactMatchLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 25)];
    exactMatchLabel.text = @"Exact phrase";
    exactMatchLabel.textColor = [UIColor lightTextColor];
    exactMatchLabel.backgroundColor = [UIColor clearColor];
    UIBarButtonItem * exactMatchLabelBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:exactMatchLabel];
    [exactMatchLabel release];
    
    UISwitch * exactMatchSwitch = [[UISwitch alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
    exactMatchSwitch.on = exactMatch;
    [exactMatchSwitch addTarget:self action:@selector(actionToggleExactMatch:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem * exactMatchSwitchBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:exactMatchSwitch];
    [exactMatchSwitch release];
    
    // Toolbar.
    [self.toolbar setItems: [NSArray arrayWithObjects:ignoreCaseLabelBarButtonItem,ignoreCaseSwitchBarButtonItem,exactMatchLabelBarButtonItem, exactMatchSwitchBarButtonItem, nil] animated:YES];
    
    [exactMatchLabelBarButtonItem release];
    [exactMatchSwitchBarButtonItem release];
    [ignoreCaseSwitchBarButtonItem release];
    [ignoreCaseLabelBarButtonItem release];
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    return YES;
}

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
	searchManager = nil;
	
    [switchToMiniBarButtonItem release];
    [cancelStopBarButtonItem release];
	
    [searchBar release];
    [searchTableView release];
    [activityIndicatorView release];
    [toolbar release];
    
    [super dealloc];
}


@end
