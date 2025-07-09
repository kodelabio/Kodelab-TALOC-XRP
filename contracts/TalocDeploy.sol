
// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../registry/TalocRegistry.sol";
import "../ds-pool/Pool.sol";
import "../ds-taloc/TalocClient.sol";
import "../ds-asset/Asset.sol";
import "../wallet/MultisigWallet.sol";

contract TalocDeploy is Ownable {
    IERC20 public eToken;
    TalocRegistry public registry;
    Pool public pool;
    TalocClient public client;
    Asset public asset;
    MultisigWallet public wallet;

    event Step(string indexed tag);

    constructor(address admin) Ownable(admin) {}


    function deployRegistry() external onlyOwner {
        require(address(registry) == address(0), "step done");
        registry = new TalocRegistry(owner());
        emit Step("deployRegistry");
    }

    function deployPool(address token) external onlyOwner {
        require(address(registry) != address(0) && address(pool) == address(0), "order");
        pool = new Pool(token, address(0));
        eToken = IERC20(token);
        emit Step("deployPool");
    }

    function deployClient(uint256 rate) external onlyOwner {
        require(address(pool) != address(0) && address(client) == address(0), "order");
        client = new TalocClient(owner());
        client.initialize(address(eToken), address(pool), address(registry), rate);
        pool.approveToken(address(eToken), address(client));
        emit Step("deployClient");
    }

    function deployAsset(string calldata name, string calldata symbol) external onlyOwner {
        require(address(asset) == address(0), "asset done");
        asset = new Asset(name, symbol, owner());
        emit Step("deployAsset");
    }

    function deployWallet(address[] calldata owners, uint256 required) external onlyOwner {
        require(address(wallet) == address(0), "wallet done");
        wallet = new MultisigWallet(owners, required);
        emit Step("deployWallet");
    }


    function releaseAuth() external onlyOwner {
        address gov = address(wallet) != address(0) ? address(wallet) : owner();
        if (address(client) != address(0)) client.transferOwnership(gov);
        if (address(pool) != address(0)) pool.transferOwnership(gov);
        if (address(asset) != address(0)) asset.transferOwnership(gov);
        if (address(registry) != address(0)) registry.grantOperator(gov);
        emit Step("releaseAuth");
    }
}
