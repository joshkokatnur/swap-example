// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol';

contract LiquidityExamples is IERC721Receiver {
    
    // rinkeby addresses
    address public constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address public constant DAI = 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735;

    // 0.3% pool fee
    uint24 public constant poolFee = 3000;

    // v3 pos manager
    INonfungiblePositionManager public immutable nonfungiblePositionManager;

    // manually assign address here
    constructor() {
        nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    }

    // recieve erc721 token upon mint
    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // mint the position
    function mintNewPosition()
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        uint256 amount0ToMint = 10000000000 * (10**18);
        uint256 amount1ToMint = 0.0000297647 * (10**18);

        // transfer tokens to contract
        //TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amount0ToMint);
        //TransferHelper.safeTransferFrom(USDC, msg.sender, address(this), amount1ToMint);

        // Approve the position manager
        TransferHelper.safeApprove(DAI, address(nonfungiblePositionManager), amount0ToMint);
        TransferHelper.safeApprove(WETH, address(nonfungiblePositionManager), amount1ToMint);

        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: DAI,
                token1: WETH,
                fee: poolFee,
                tickLower: TickMath.MIN_TICK,
                tickUpper: TickMath.MAX_TICK,
                amount0Desired: amount0ToMint,
                amount1Desired: amount1ToMint,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        // Note that the pool defined by DAI/USDC and fee tier 0.3% must already be created and initialized in order to mint
        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);
    }
}