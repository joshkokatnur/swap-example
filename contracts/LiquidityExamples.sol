// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol';

contract LiquidityExamples is IERC721Receiver {
    
    // rinkeby addresses
    address public constant fDAI = 0x15F0Ca26781C3852f8166eD2ebce5D18265cceb7;
    address public constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

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
        uint256 amount0ToMint = 1000;
        uint256 amount1ToMint = 1000;

        // Approve the position manager
        TransferHelper.safeApprove(fDAI, address(nonfungiblePositionManager), amount0ToMint);
        TransferHelper.safeApprove(WETH, address(nonfungiblePositionManager), amount1ToMint);

        // Get pool
        IUniswapV3Pool pool = IUniswapV3Pool(IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984).getPool(fDAI, WETH, poolFee));
        (, int24 tick, , , , , ) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();

        int24 lower = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
        int24 upper = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;

        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: fDAI,
                token1: WETH,
                fee: poolFee,
                tickLower: lower,
                tickUpper: upper,
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