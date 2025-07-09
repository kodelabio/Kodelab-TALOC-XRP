
// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.20;

library TalocRoles {
    bytes32 internal constant REGISTER_ROLE = keccak256("REGISTER_ROLE");
    bytes32 internal constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 internal constant ORACLE_ROLE   = keccak256("ORACLE_ROLE");
}
