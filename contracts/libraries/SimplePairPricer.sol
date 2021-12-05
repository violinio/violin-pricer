import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

library SimplePairPricer {
    function getReserveInOutTokenAndAmount(IUniswapV2Pair pair, address tokenIn, uint256 amountIn) internal view returns (uint256 reserveIn, address tokenOther, uint256 amountOut, uint256 amountOutNoSlippage) {
        // force token0 to be token and token1 to be the pair token
        address token1 = pair.token1();
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        if(token1 == tokenIn) {
            token1 = pair.token0();
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        return (reserve0, token1, calculateAmountOut(amountIn, reserve0, reserve1), amountIn * reserve1 / reserve0);
    }

    function getOutTokenAndAmount(IUniswapV2Pair pair, address tokenIn, uint256 amountIn) internal view returns (address tokenOther, uint256 amountOut, uint256 amountOutNoSlippage) {
        // force token0 to be token and token1 to be the pair token
        address token1 = pair.token1();
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        if(token1 == tokenIn) {
            token1 = pair.token0();
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        return (token1, calculateAmountOut(amountIn, reserve0, reserve1), amountIn * reserve1 / reserve0);
    }


    /// @dev Simple pricer that accounts for price slippage.
    function calculateAmountOut(uint amountIn, uint reserveIn, uint reserveOut) private pure returns (uint) {
        if(reserveIn == 0)
            return 0;
        return (amountIn * reserveOut) / (reserveIn + amountIn);
    }
}