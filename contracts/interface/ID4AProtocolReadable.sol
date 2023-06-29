// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ID4AProtocolReadable {
    function getDaoMintCap(bytes32 daoId) external view returns (uint32);

    function getUserMintInfo(
        bytes32 daoId,
        address account
    )
        external
        view
        returns (uint32 minted, uint32 userMintCap);

    function getProjectCanvasAt(bytes32 daoId, uint256 index) external view returns (bytes32);

    function getProjectInfo(bytes32 daoId)
        external
        view
        returns (
            uint256 startRound,
            uint256 mintableRound,
            uint256 maxNftAmount,
            address daoFeePool,
            uint96 royaltyFeeInBps,
            uint256 index,
            string memory daoUri,
            uint256 erc20TotalSupply
        );

    function getProjectFloorPrice(bytes32 daoId) external view returns (uint256);

    function getProjectTokens(bytes32 daoId) external view returns (address token, address nft);

    function getCanvasNFTCount(bytes32 canvasId) external view returns (uint256);

    function getTokenIDAt(bytes32 canvasId, uint256 index) external view returns (uint256);

    function getCanvasProject(bytes32 canvasId) external view returns (bytes32);

    function getCanvasIndex(bytes32 canvasId) external view returns (uint256);

    function getCanvasURI(bytes32 canvasId) external view returns (string memory);

    function getCanvasLastPrice(bytes32 canvasId) external view returns (uint256 round, uint256 price);

    function getCanvasNextPrice(bytes32 canvasId) external view returns (uint256);

    function getCanvasCreatorERC20Ratio(bytes32 daoId) external view returns (uint256);

    function getNftMinterERC20Ratio(bytes32 daoId) external view returns (uint256);

    function getDaoFeePoolETHRatio(bytes32 daoId) external view returns (uint256);

    function getDaoFeePoolETHRatioFlatPrice(bytes32 daoId) external view returns (uint256);
}
