// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import { FeedRegistryInterface } from "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import { Denominations } from "@chainlink/contracts/src/v0.8/Denominations.sol";
import { IWETH } from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import { IUniswapV2Router02 as IUniswapV2Router } from
    "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract D4ARoyaltySplitter is Initializable, OwnableUpgradeable, AutomationCompatibleInterface {
    address public protocolFeePool;
    address public daoFeePool;
    uint256 public protocolShare;
    uint256 public daoShare;

    uint256 public threshold;
    IUniswapV2Router public router;
    FeedRegistryInterface public oracleRegistry;

    address public immutable WETH;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address WETH_) {
        WETH = WETH_;
        _disableInitializers();
    }

    function getPrice(address base, address quote) public view returns (uint256) {
        (
            // uint80 roundID
            ,
            int256 price,
            // uint startedAt
            ,
            // uint timeStamp
            ,
            // uint80 answeredInRound
        ) = oracleRegistry.latestRoundData(base, quote);
        return uint256(price);
    }

    function initialize(
        address protocolFeePool_,
        uint256 protocolShare_,
        address daoFeePool_,
        uint256 daoShare_,
        address router_,
        address oracleRegistry_
    )
        public
        initializer
    {
        __Ownable_init();
        protocolFeePool = protocolFeePool_;
        protocolShare = protocolShare_;
        daoFeePool = daoFeePool_;
        daoShare = daoShare_;

        router = IUniswapV2Router(router_);
        oracleRegistry = FeedRegistryInterface(oracleRegistry_);

        threshold = 5 ether;
    }

    function setShare(uint256 protocolShare_, uint256 daoShare_) public onlyOwner {
        protocolShare = protocolShare_;
        daoShare = daoShare_;
    }

    function setThreshold(uint256 newThreshold) public onlyOwner {
        threshold = newThreshold;
    }

    function setRouter(address newRouter) public onlyOwner {
        router = IUniswapV2Router(newRouter);
    }

    function setOracleRegistry(address newOracleRegistry) public onlyOwner {
        oracleRegistry = FeedRegistryInterface(newOracleRegistry);
    }

    function claimERC20(address token) external {
        uint256 protocolShare_ = protocolShare;
        uint256 daoShare_ = daoShare;
        address protocolFeePool_ = protocolFeePool;
        address daoFeePool_ = daoFeePool;

        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 protocolFee = (balance * protocolShare_) / (protocolShare_ + daoShare_);
        uint256 daoFee = balance - protocolFee;

        if (protocolFee > 0) SafeTransferLib.safeTransfer(token, protocolFeePool_, protocolFee);
        if (daoFee > 0) SafeTransferLib.safeTransfer(token, daoFeePool_, daoFee);
    }

    event ETHTransfered(address indexed to, uint256 amount);

    function _fallback() internal {
        uint256 protocolShare_ = protocolShare;
        uint256 daoShare_ = daoShare;
        address protocolFeePool_ = protocolFeePool;
        address daoFeePool_ = daoFeePool;

        uint256 protocolFee = (address(this).balance * protocolShare_) / (protocolShare_ + daoShare_);
        uint256 daoFee = address(this).balance - protocolFee;

        if (protocolFee > 0) {
            SafeTransferLib.safeTransferETH(protocolFeePool_, protocolFee);
            emit ETHTransfered(protocolFeePool_, protocolFee);
        }
        if (daoFee > 0) {
            SafeTransferLib.safeTransferETH(daoFeePool_, daoFee);
            emit ETHTransfered(daoFeePool_, daoFee);
        }
    }

    fallback() external payable {
        if (gasleft() <= 2300) return;
        _fallback();
    }

    receive() external payable {
        if (gasleft() <= 2300) return;
        _fallback();
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 withdrawAmount;
        {
            uint256 balance = IERC20(WETH).balanceOf(address(this));
            if (balance > threshold) {
                withdrawAmount = balance;
                upkeepNeeded = true;
            }
        }
        address[] memory tokens = abi.decode(checkData, (address[]));
        uint256 length = tokens.length;
        address[] memory params = new address[](length);
        uint256 counter;

        address[] memory paths = new address[](2);
        paths[1] = WETH;
        for (uint256 i; i < length; ++i) {
            paths[0] = tokens[i];
            uint256 balance = IERC20(tokens[i]).balanceOf(address(this));
            if (balance > 0 && router.getAmountsOut(balance, paths)[1] > threshold) {
                params[counter++] = tokens[i];
                upkeepNeeded = true;
            }
        }
        /// @solidity memory-safe-assembly
        assembly {
            mstore(params, counter)
        }

        performData = abi.encode(withdrawAmount, params);
    }

    function performUpkeep(bytes calldata performData) external {
        (uint256 withdrawAmount, address[] memory tokens) = abi.decode(performData, (uint256, address[]));

        if (withdrawAmount > 0) IWETH(WETH).withdraw(withdrawAmount);

        uint256 length = tokens.length;
        address[] memory paths = new address[](2);
        paths[1] = WETH;
        for (uint256 i; i < length;) {
            uint256 balance = IERC20(tokens[i]).balanceOf(address(this));
            paths[0] = tokens[i];
            IERC20(tokens[i]).approve(address(router), balance);
            uint256 amountOutMin = balance * getPrice(tokens[i], Denominations.ETH) * 995 / 1000 // 995 for 0.3% fee and
                // more than 0.1% splippage
                / 10 ** oracleRegistry.decimals(tokens[i], Denominations.ETH);
            router.swapExactTokensForETH(balance, amountOutMin, paths, address(this), block.timestamp + 1 days);
            unchecked {
                ++i;
            }
        }
    }
}
