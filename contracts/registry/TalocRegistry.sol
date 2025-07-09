
// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.20;

import "../lib/ds-auth/TalocAuth.sol";
import "../lib/ds-auth/TalocRoles.sol";

contract TalocRegistry is TalocAuth {
    mapping(address => mapping(uint256 => bool)) public assetOk;
    mapping(address => address) public assetOracle;

    constructor(address admin) TalocAuth(admin) {}

    function whitelist(address token, uint256 id) external onlyRegister {
        assetOk[token][id] = true;
    }

    function blacklist(address token, uint256 id) external onlyRegister {
        assetOk[token][id] = false;
    }

    function linkOracle(address token, address oracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        assetOracle[token] = oracle;
    }
}
