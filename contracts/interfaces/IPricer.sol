// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice The Pricer allows contracts and frontends to efficiently fetch asset prices. Initially it is only meant to fetch ERC-20 prices but over time the metadata parameter could be used to allow for different types of assets like ERC-1155.
interface IPricer {
    /// @notice Returns the dollar value of the `amount` of `asset` at the current spot price. Returned value is in 1e18.
    /// @param metadata Can contain metadata about non ERC20 assets, like the token id of erc1155.
    function getValue(
        address asset,
        uint256 amount,
        bytes calldata metadata
    ) external view returns (uint256);

    /// @notice calls getValue for all provided assets. Input parameters must be equal length.
    function getValues(
        address[] calldata assets,
        uint256[] calldata amounts,
        bytes[] calldata metadata
    ) external view returns (uint256[] memory);

    /// @notice Returns the dollar value of the `amount` of one full unit (10^decimals) of `asset` at the current spot price. Returned value is in 1e18.
    function getPrice(address asset, bytes calldata metadata)
        external
        view
        returns (uint256);

    /// @notice Calls getPrice for all provided assets. Input parameters must be equal length.
    function getPrices(address[] calldata assets, bytes[] calldata metadata)
        external
        view
        returns (uint256[] memory);
}
