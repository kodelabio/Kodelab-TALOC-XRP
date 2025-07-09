
// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../pool/Pool.sol";
import "../registry/TalocRegistry.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract TalocStorage {
    struct VaultData {
        address token;
        uint256 avail;
        uint256 debt;
        uint256 interest;
        uint256 last;
        uint256 id;
        bool    active;
        address owner;
        bool    paused;
    }

    IERC20 public eToken;
    Pool   public pool;
    TalocRegistry public registry;
    uint256 public rate;
    uint256 public vaultCtr;

    mapping(uint256 => address) public vaultAddr;
    mapping(uint256 => VaultData) public vaultInfo;
    mapping(address => EnumerableSet.UintSet) internal _ownerVaults;
}
