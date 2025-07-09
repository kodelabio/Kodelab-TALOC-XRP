
// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.20;

library InterestMath {
    function accrue(uint256 principal, uint256 rate, uint256 delta) internal pure returns (uint256) {
        return principal * rate * delta / 365 days / 1e5;
    }
}
