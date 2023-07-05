// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import {
    IPermissionControl,
    D4ACreateProjectProxy,
    DeployHelper,
    TransparentUpgradeableProxy
} from "test/foundry/utils/DeployHelper.sol";

import { PriceTemplateType, RewardTemplateType } from "contracts/interface/D4AEnums.sol";
import {
    DaoMetadataParam,
    DaoMintCapParam,
    UserMintCapParam,
    DaoETHAndERC20SplitRatioParam,
    TemplateParam,
    Whitelist,
    Blacklist
} from "contracts/interface/D4AStructs.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { D4ACreateProjectProxyHarness } from "test/foundry/harness/D4ACreateProjectProxyHarness.sol";

contract D4ACreateProjectProxyTest is DeployHelper {
    using stdStorage for StdStorage;

    D4ACreateProjectProxyHarness public daoProxyHarness;

    function setUp() public {
        setUpEnv();
        D4ACreateProjectProxyHarness harness = new D4ACreateProjectProxyHarness(address(weth));
        vm.etch(address(daoProxyImpl), address(harness).code);
        daoProxyHarness = D4ACreateProjectProxyHarness(payable(address(daoProxy)));
    }

    function test_protocol() public {
        assertEq(address(daoProxy.protocol()), address(protocol));
    }

    function test_splitterFactory() public {
        assertEq(address(daoProxy.splitter_factory()), address(royaltySplitterFactory));
    }

    function test_splitterOwner() public {
        assertEq(daoProxy.splitter_owner(), royaltySplitterOwner.addr);
    }

    function test_WETH() public {
        assertEq(address(daoProxy.WETH()), address(weth));
    }

    function test_owner() public {
        assertEq(daoProxy.owner(), protocolOwner.addr);
    }

    function test_initialize() public {
        daoProxyImpl = new D4ACreateProjectProxy(address(weth));
        daoProxy = D4ACreateProjectProxy(
            payable(
                new TransparentUpgradeableProxy(
                    address(daoProxyImpl),
                    address(proxyAdmin),
                    abi.encodeWithSelector(
                        D4ACreateProjectProxy.initialize.selector,
                        address(uniswapV2Factory),
                        address(uniswapV2Router),
                        address(protocol),
                        address(royaltySplitterFactory),
                        royaltySplitterOwner
                    )
                )
            )
        );
    }

    function test_RevertIf_initialize() public {
        vm.startPrank(protocolOwner.addr);
        vm.expectRevert("Initializable: contract is already initialized");
        daoProxy.initialize(address(0), address(0), address(0), address(0));
    }

    function test_set() public {
        vm.prank(protocolOwner.addr);
        daoProxy.set(address(0), address(0), address(0), address(0));
    }

    /// forge-config: default.fuzz.runs = 2000
    function testFuzz_createProject(uint256 actionType) public {
        (, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();
        vm.assume(actionType < type(uint8).max);
        if (actionType & 0x1 == 0) {
            vm.expectCall({
                callee: address(protocol),
                msgValue: 0.1 ether,
                data: abi.encodeWithSelector(protocol.createProject.selector),
                count: 1
            });
        } else {
            vm.expectCall({
                callee: address(protocol),
                msgValue: 0.1 ether,
                data: abi.encodeWithSelector(protocol.createOwnerProject.selector),
                count: 1
            });
            hoax(operationRoleMember.addr);
        }
        if (actionType & 0x2 != 0) {
            vm.expectCall({
                callee: address(permissionControl),
                msgValue: 0,
                data: abi.encodeWithSelector(permissionControl.addPermission.selector),
                count: 1
            });
        }
        if (actionType & 0x4 != 0) {
            vm.expectCall({
                callee: address(protocol),
                msgValue: 0,
                data: abi.encodeWithSelector(ID4AProtocolSetter(address(protocol)).setMintCapAndPermission.selector),
                count: 1
            });
        }
        if (actionType & 0x8 != 0) {
            vm.expectCall({
                callee: address(uniswapV2Factory),
                msgValue: 0,
                data: abi.encodeWithSelector(uniswapV2Factory.createPair.selector),
                count: 1
            });
        }
        if (actionType & 0x10 != 0) {
            vm.expectCall({
                callee: address(protocol),
                msgValue: 0,
                data: abi.encodeWithSelector(ID4AProtocolSetter(address(protocol)).setRatio.selector),
                count: 1
            });
        }
        bytes32 daoId = daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: 0,
                mintableRounds: 30,
                floorPriceRank: 0,
                maxNftRank: 0,
                royaltyFee: 750,
                projectUri: "test project uri",
                projectIndex: 0
            }),
            whitelist,
            blacklist,
            DaoMintCapParam({ daoMintCap: 0, userMintCapParams: new UserMintCapParam[](0) }),
            DaoETHAndERC20SplitRatioParam(300, 5000, 4500, 2000, 2500),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.LINEAR_REWARD_ISSUANCE,
                rewardDecayFactor: 0,
                rewardDecayLife: 1,
                isProgressiveJackpot: false
            }),
            actionType
        );
        assertTrue(daoId != bytes32(0));
    }

    function test_RevertIf_createProject_CreateOwnerProjectNotAsOwner() public {
        (, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        vm.expectRevert("only admin can specify project index");
        daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: 0,
                mintableRounds: 30,
                floorPriceRank: 0,
                maxNftRank: 0,
                royaltyFee: 750,
                projectUri: "test project uri",
                projectIndex: 0
            }),
            whitelist,
            blacklist,
            DaoMintCapParam({ daoMintCap: 0, userMintCapParams: new UserMintCapParam[](0) }),
            DaoETHAndERC20SplitRatioParam(300, 5000, 4500, 2000, 2500),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.LINEAR_REWARD_ISSUANCE,
                rewardDecayFactor: 0,
                rewardDecayLife: 1,
                isProgressiveJackpot: false
            }),
            1
        );
    }

    function test_exposed_setMintCapAndPermission() public {
        (, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(bytes32(0), address(this));

        vm.expectCall({
            callee: address(protocol),
            msgValue: 0,
            data: abi.encodeWithSelector(ID4AProtocolSetter(address(protocol)).setMintCapAndPermission.selector),
            count: 1
        });
        daoProxyHarness.exposed_setMintCapAndPermission(
            bytes32(0), 0, new UserMintCapParam[](0), whitelist, blacklist, blacklist
        );
    }

    function test_exposed_addPermission() public {
        (, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(bytes32(0), address(this));

        vm.prank(address(this));
        vm.expectCall({
            callee: address(permissionControl),
            msgValue: 0,
            data: abi.encodeWithSelector(permissionControl.addPermission.selector),
            count: 1
        });
        daoProxyHarness.exposed_addPermission(bytes32(0), whitelist, blacklist);
    }

    function test_exposed_createSplitter() public {
        hoax(address(daoProxy), 0.1 ether);
        bytes32 daoId = protocol.createProject{ value: 0.1 ether }(0, 30, 0, 0, 750, "test project uri");

        daoProxyHarness.exposed_createSplitter(daoId);
    }

    function test_getSplitterAddress() public {
        (, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();
        bytes32 daoId = daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: 0,
                mintableRounds: 30,
                floorPriceRank: 0,
                maxNftRank: 0,
                royaltyFee: 750,
                projectUri: "test project uri",
                projectIndex: 0
            }),
            whitelist,
            blacklist,
            DaoMintCapParam({ daoMintCap: 0, userMintCapParams: new UserMintCapParam[](0) }),
            DaoETHAndERC20SplitRatioParam(300, 5000, 4500, 2000, 2500),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.LINEAR_REWARD_ISSUANCE,
                rewardDecayFactor: 0,
                rewardDecayLife: 1,
                isProgressiveJackpot: false
            }),
            0
        );
        address splitter = daoProxy.getSplitterAddress(daoId);
        assertTrue(splitter != address(0));
    }
}
