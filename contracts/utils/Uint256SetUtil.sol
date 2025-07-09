
// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library Uint256SetUtil {
    using EnumerableSet for EnumerableSet.UintSet;
    function toArray(EnumerableSet.UintSet storage set) internal view returns (uint256[] memory arr) {
        uint256 len = set.length();
        arr = new uint256[](len);
        for (uint256 i; i < len; ++i) arr[i] = set.at(i);
    }
}
