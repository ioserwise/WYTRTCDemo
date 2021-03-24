//
//  LiveViewController.m
//  WYTRTCDemo
//
//  Created by Weep Yan on 2021/3/16.
//

#import "LiveViewController.h"
#import "WYTRTCDemo-Swift.h"// 引用默认Swift头文件调用swift代码
#import "LivePushViewController.h"
#import "LivePlayViewController.h"

@interface LiveViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *liveRoomTableView;
@property (nonatomic, strong) NSMutableArray<LiveRoomItem *> *liveRoomList;
@property (nonatomic, strong) LiveRoomManager *roomManager;

@end

@implementation LiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.roomManager = [LiveRoomManager sharedInstancee];
    _liveRoomList = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    
    NSLog(@"viewWillAppear");
    
    __weak typeof(self) wself = self;
    [_roomManager queryLiveRoomListWithSuccess:^(NSArray<LiveRoomItem *> * _Nonnull roomList) {
        [wself.liveRoomList removeAllObjects];
        [wself.liveRoomList addObjectsFromArray:roomList];
        [wself.liveRoomTableView reloadData];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSLog(@"viewDidAppear");
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *segueId = segue.identifier;
    if (!segueId) {
        return;
    }
    if ([@"beginLivePush" isEqualToString: segueId]) {
        LivePushViewController *liveVC = [segue destinationViewController];
        liveVC.roomId = (UInt32)((CACurrentMediaTime() * 1000));
        liveVC.userId = [NSString stringWithFormat:@"%d", liveVC.roomId];
    }
}

#pragma - UITableViewDelegate, UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _liveRoomList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LiveRoomCellId"];
    if (indexPath.section < _liveRoomList.count) {
        NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:@"直播间ID：" attributes: @{
            NSForegroundColorAttributeName : [UIColor lightGrayColor]}];
        [attrText appendAttributedString:[[NSAttributedString alloc] initWithString:[_liveRoomList[indexPath.section] roomId] attributes:@{
            NSForegroundColorAttributeName : [UIColor lightGrayColor]}]];
        cell.textLabel.attributedText = attrText;
        cell.tag = [[_liveRoomList[indexPath.section] roomId] intValue] ?: 0;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Live" bundle:nil];
    LivePlayViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"LivePlayViewControllerId"];
    if (vc) {
        NSInteger roomId = [[tableView cellForRowAtIndexPath:indexPath] tag];
        if (roomId) {
            vc.roomId = (unsigned int)roomId;
            vc.userId = [NSString stringWithFormat:@"%d", (UInt32)((CACurrentMediaTime() * 1000))];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

@end
