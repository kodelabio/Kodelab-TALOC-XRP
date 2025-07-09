
// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./TalocRoles.sol";

abstract contract TalocAuth is AccessControlEnumerable {
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    modifier onlyRegister() {
        require(hasRole(TalocRoles.REGISTER_ROLE, msg.sender), "TalocAuth: only register");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(TalocRoles.OPERATOR_ROLE, msg.sender), "TalocAuth: only operator");
        _;
    }

    modifier onlyOracle() {
        require(hasRole(TalocRoles.ORACLE_ROLE, msg.sender), "TalocAuth: only oracle");
        _;
    }

    function grantRegister(address a) external onlyRole(DEFAULT_ADMIN_ROLE) { _grantRole(TalocRoles.REGISTER_ROLE, a); }
    function revokeRegister(address a) external onlyRole(DEFAULT_ADMIN_ROLE) { _revokeRole(TalocRoles.REGISTER_ROLE, a); }

    function grantOperator(address a) external onlyRole(DEFAULT_ADMIN_ROLE) { _grantRole(TalocRoles.OPERATOR_ROLE, a); }
    function revokeOperator(address a) external onlyRole(DEFAULT_ADMIN_ROLE) { _revokeRole(TalocRoles.OPERATOR_ROLE, a); }

    function grantOracle(address a)   external onlyRole(DEFAULT_ADMIN_ROLE) { _grantRole(TalocRoles.ORACLE_ROLE, a); }
    function revokeOracle(address a)  external onlyRole(DEFAULT_ADMIN_ROLE) { _revokeRole(TalocRoles.ORACLE_ROLE, a); }
}
