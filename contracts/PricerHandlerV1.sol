// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "@violinio/violin-vaults-contracts/contracts/interfaces/IVaultChef.sol";

import "./libraries/SimplePairPricer.sol";
import "./Pricer.sol";

import "./interfaces/IBalancerV2Pool.sol";
import "./interfaces/IBalancerV2Vault.sol";

contract PricerHandlerV1 is IPricer, AccessControlEnumerableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    /// @dev Used to load in pair.getAmountOut method.
    using SimplePairPricer for IUniswapV2Pair;

    /// @dev Simple identifier for internal parties. We reserve the right to make breaking changes without upgrading the VERSION.
    uint256 public constant VERSION = 1;

    /// @dev Information about a stablecoin, all main assets should either be a stablecoin or have an overriden pair to a stablecoin.
    struct StableCoinInfo {
        bool set;
        uint8 decimals;
    }

    /// @dev An enumerable list of all registered factories.
    EnumerableSet.AddressSet factories;

    /// @dev An enumerable list of all registered factories.
    EnumerableSet.AddressSet mainAssets;

    /// @dev Forces usage of the specified pair for calculating the first step of the value calculation.
    mapping(address => IUniswapV2Pair) public overridenPairForToken;

    /// @dev Information about a coin being a stablecoin. Everything is eventually routed to a stablecoin.
    mapping(address => StableCoinInfo) public stablecoins;

    /// @dev Management roles
    bytes32 public constant SET_FACTORY_ROLE = keccak256("SET_FACTORY_ROLE");
    bytes32 public constant SET_ASSET_ROLE = keccak256("SET_ASSET_ROLE");

    /// @dev Utility contract that throws if the provided address is not a pair, used because simple try-catch is insufficient due to it still reverting on wrong return data (and I'm too lazy for a low-level call).
    PairChecker public pairChecker;

    function initialize(address _owner) external initializer {
        __AccessControlEnumerable_init();

        /// @dev Make msg.sender the default admin
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(SET_FACTORY_ROLE, _owner);
        _setupRole(SET_ASSET_ROLE, _owner);

        pairChecker = new PairChecker();
    }

    function setPairChecker(PairChecker _pairChecker)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pairChecker = _pairChecker;
        emit PairCheckerSet(_pairChecker);
    }

    /// @notice Returns the dollar value of the `amount` of `asset` at the current spot price. Returned value is in 1e18.
    /// @param metadata Can contain metadata about non ERC20 assets, like the token id of erc1155.
    function getValue(
        address asset,
        uint256 amount,
        bytes calldata metadata
    ) public view override returns (uint256) {
        // First we check if the asset is the vaultchef by assuming that any metadata set would be the token id. We simply overwrite the parameters to the underlying parameters.
        if (metadata.length > 0) {
            uint256 tokenId = abi.decode(metadata, (uint256));
            uint256 totalUnderlying = IVaultChef(asset).totalUnderlying(
                tokenId
            );
            uint256 totalSupply = IVaultChef(asset).totalSupply(tokenId);
            IVaultChefCore.Vault memory vault = IVaultChef(asset).vaultInfo(
                tokenId
            );
            asset = address(vault.underlyingToken);
            amount = (amount * totalUnderlying) / totalSupply;
        }

        // Then we check if the asset is a pair
        try pairChecker.isPair(asset) {
            address token0 = IUniswapV2Pair(asset).token0();
            address token1 = IUniswapV2Pair(asset).token1();
            (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(asset)
                .getReserves();
            uint256 totalSupply = IUniswapV2Pair(asset).totalSupply();
            if (totalSupply == 0) return 0;
            uint256 amount0 = (amount * reserve0) / totalSupply;
            uint256 amount1 = (amount * reserve1) / totalSupply;
            return
                getTokenValue(token0, amount0) + getTokenValue(token1, amount1);
        } catch {}

        try pairChecker.isBalancerPool(asset) returns (
            address vault,
            bytes32 poolId
        ) {
            (
                address[] memory tokens,
                uint256[] memory balances,

            ) = IBalancerV2Vault(vault).getPoolTokens(poolId);
            uint256 totalValue = 0;
            uint256 totalSupply = IBalancerV2Pool(asset).totalSupply();
            for (uint256 i = 0; i < tokens.length; i++) {
                totalValue += getTokenValue(
                    tokens[i],
                    (amount * balances[i]) / totalSupply
                );
            }
            return totalValue;
        } catch {}

        // Finally handle the asset as if its a token
        return getTokenValue(asset, amount);
    }

    function getTokenValue(address token, uint256 amount)
        internal
        view
        returns (uint256)
    {
        // Finish once we've reached a stablecoin.
        StableCoinInfo memory stableCoinInfo = stablecoins[token];
        if (stableCoinInfo.set) {
            return
                stableCoinInfo.decimals == 18
                    ? amount
                    : (amount * 1e18) / (10**stableCoinInfo.decimals);
        }

        // Take a shortcut if we have manually set the first pair for this token.
        IUniswapV2Pair overridenPair = overridenPairForToken[token];
        if (address(overridenPair) != address(0)) {
            (address outToken, , uint256 outAmountNoSlippage) = overridenPair
                .getOutTokenAndAmount(token, amount);
            return getTokenValue(outToken, outAmountNoSlippage);
        }

        // Get discovery based token value
        return getDiscoveredTokenValue(token, amount);
    }

    /// @dev Get pairs, weight by token amount, stop after $1000 is aggregated.
    function getDiscoveredTokenValue(address token, uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint256 totalTVLIn = 0;
        uint256 totalUSD = 0;
        uint256 weightedOut = 0;
        for (uint256 i = 0; i < factories.length(); i++) {
            IUniswapV2Factory factory = IUniswapV2Factory(factories.at(i));
            for (uint256 j = 0; j < mainAssets.length(); j++) {
                address mainAsset = mainAssets.at(j);
                if (address(token) == mainAsset) {
                    continue;
                }

                IUniswapV2Pair pair = IUniswapV2Pair(
                    factory.getPair(token, mainAsset)
                );
                if (address(pair) == address(0)) {
                    continue;
                }

                (
                    uint256 reserveIn,
                    address outToken,
                    uint256 outAmount,
                    uint256 outAmountNoSlippage
                ) = pair.getReserveInOutTokenAndAmount(token, amount);

                uint256 usdValue = getTokenValue(outToken, outAmount);
                uint256 usdValueNoSlippage = getTokenValue(
                    outToken,
                    outAmountNoSlippage
                );
                weightedOut += usdValueNoSlippage * reserveIn; // without slippage
                totalUSD += usdValue; // with slippage
                totalTVLIn += reserveIn;

                // Return early if we've iterated over 10x the input amount or we've iterated over an output amount over $10,000.
                if (totalTVLIn >= amount * 10 || totalUSD >= 10000 * 1e18) {
                    return weightedOut / totalTVLIn;
                }
            }
        }

        return (totalTVLIn != 0) ? weightedOut / totalTVLIn : 0;
    }

    /// @notice calls getValue for all provided assets. Input parameters must be equal length.
    function getValues(
        address[] calldata assets,
        uint256[] calldata amounts,
        bytes[] calldata metadata
    ) external view override returns (uint256[] memory) {
        uint256[] memory values = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            values[i] = getValue(assets[i], amounts[i], metadata[i]);
        }
        return values;
    }

    /// @notice Returns the dollar value of the `amount` of one full unit (10**decimals) of `asset` at the current spot price. Returned value is in 1e18.
    function getPrice(address asset, bytes calldata metadata)
        public
        view
        override
        returns (uint256)
    {
        uint256 decimals = IERC20Metadata(asset).decimals();
        return getValue(asset, 10**decimals, metadata);
    }

    /// @notice Calls getPrice for all provided assets. Input parameters must be equal length.
    function getPrices(address[] calldata assets, bytes[] calldata metadata)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory values = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 decimals = IERC20Metadata(assets[i]).decimals();
            values[i] = getValue(assets[i], 10**decimals, metadata[i]);
        }
        return values;
    }

    ///** UTILITY FUNCTIONS *///

    ///** GOVERNANCE FUNCTIONS **///

    ///** Factories *///
    function addFactory(address _factory) external onlyRole(SET_FACTORY_ROLE) {
        require(!factories.contains(_factory), "!already added");
        factories.add(_factory);

        emit FactoryAdded(_factory);
    }

    function removeFactory(address _factory)
        external
        onlyRole(SET_FACTORY_ROLE)
    {
        require(factories.contains(_factory), "!exists");
        factories.remove(_factory);

        emit FactoryRemoved(_factory);
    }

    ///** Main assets *///
    function addMainAsset(address _mainAsset)
        external
        onlyRole(SET_ASSET_ROLE)
    {
        require(!mainAssets.contains(_mainAsset), "!already added");
        require(
            stablecoins[_mainAsset].set ||
                address(overridenPairForToken[_mainAsset]) != address(0),
            "!Add as stablecoin or set pair with stablecoin first."
        );
        mainAssets.add(_mainAsset);

        emit MainAssetAdded(_mainAsset);
    }

    function removeMainAsset(address _mainAsset)
        external
        onlyRole(SET_ASSET_ROLE)
    {
        require(factories.contains(_mainAsset), "!exists");
        factories.remove(_mainAsset);

        emit MainAssetRemoved(_mainAsset);
    }

    function setOverridenPair(address asset, IUniswapV2Pair pair)
        external
        onlyRole(SET_ASSET_ROLE)
    {
        overridenPairForToken[asset] = pair;
        emit OverridenPairSet(asset, pair);
    }

    function setStablecoin(address stablecoin, bool set)
        external
        onlyRole(SET_ASSET_ROLE)
    {
        stablecoins[stablecoin] = StableCoinInfo({
            set: set,
            decimals: IERC20Metadata(stablecoin).decimals()
        });

        emit StableCoinSet(stablecoin, set);
    }

    //** VIEW FUNCTIONS **//

    function factoryAt(uint256 index) external view returns (address) {
        return factories.at(index);
    }

    function factoryLength() external view returns (uint256) {
        return factories.length();
    }

    function mainAssetAt(uint256 index) external view returns (address) {
        return mainAssets.at(index);
    }

    function mainAssetLength() external view returns (uint256) {
        return mainAssets.length();
    }

    //** EVENTS *//

    event FactoryAdded(address indexed factory);
    event FactoryRemoved(address indexed factory);
    event MainAssetAdded(address indexed mainAsset);
    event MainAssetRemoved(address indexed mainAsset);
    event OverridenPairSet(address indexed asset, IUniswapV2Pair indexed pair);
    event StableCoinSet(address indexed stablecoin, bool indexed set);
    event PairCheckerSet(PairChecker indexed newPairChecker);
}

contract PairChecker {
    // Fallback-safe pair checker, needs to be called using try-catch.
    function isPair(address token) external view {
        IUniswapV2Pair(token).getReserves();
    }

    function isBalancerPool(address token)
        external
        view
        returns (address vault, bytes32 poolId)
    {
        return (
            IBalancerV2Pool(token).getVault(),
            IBalancerV2Pool(token).getPoolId()
        );
    }
}
