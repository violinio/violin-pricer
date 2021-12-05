// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./dependencies/Ownable.sol";
import "./interfaces/IPricer.sol";

/// @notice The Pricer allows contracts and frontends to efficiently fetch asset prices.
/// @notice Initially it is only meant to fetch ERC-20 prices but over time the metadata parameter could be used to allow for different types of assets like ERC-1155.
/// @dev It forwards all requests blindly to the implementation, this allows the implementation to change over time.
contract Pricer is IPricer, Ownable {
    using SafeERC20 for IERC20;

    /// @dev The implementation that actually executes the pricing requests.
    IPricer public implementation;

    event ImplementationChanged(
        IPricer indexed oldImplementation,
        IPricer indexed newImplementation
    );

    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    /// @notice Returns the dollar value of the `amount` of `asset` at the current spot price. Returned value is in 1e18.
    /// @param metadata Can contain metadata about non ERC20 assets, like the token id of erc1155.
    function getValue(
        address asset,
        uint256 amount,
        bytes calldata metadata
    ) external view override returns (uint256) {
        return implementation.getValue(asset, amount, metadata);
    }

    /// @notice calls getValue for all provided assets. Input parameters must be equal length.
    function getValues(
        address[] calldata assets,
        uint256[] calldata amounts,
        bytes[] calldata metadata
    ) external view override returns (uint256[] memory) {
        return implementation.getValues(assets, amounts, metadata);
    }

    /// @notice Returns the dollar value of the `amount` of one full unit (10^decimals) of `asset` at the current spot price. Returned value is in 1e18.
    function getPrice(address asset, bytes calldata metadata)
        external
        view
        override
        returns (uint256)
    {
        return implementation.getPrice(asset, metadata);
    }

    /// @notice Calls getPrice for all provided assets. Input parameters must be equal length.
    function getPrices(address[] calldata assets, bytes[] calldata metadata)
        external
        view
        override
        returns (uint256[] memory)
    {
        return implementation.getPrices(assets, metadata);
    }

    /**
     * @notice Sets the underlying implementation that fulfills the swap orders.
     * @dev Can only be called by the contract owner.
     * @param _implementation The new implementation.
     */
    function setImplementation(IPricer _implementation) external onlyOwner {
        IPricer oldImplementation = implementation;
        implementation = _implementation;

        emit ImplementationChanged(oldImplementation, _implementation);
    }
}
