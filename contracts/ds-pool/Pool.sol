
// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Pool is Ownable {
    mapping(address => bool) public approved;

    constructor(address token, address spender) Ownable(msg.sender) {
        approved[token] = true;
        IERC20(token).approve(spender, type(uint256).max);
    }

    function approveToken(address token, address spender) external onlyOwner {
        approved[token] = true;
        IERC20(token).approve(spender, type(uint256).max);
    }

    function withdraw(address token, uint256 amt) external onlyOwner {
        IERC20(token).transfer(msg.sender, amt);
    }
}
