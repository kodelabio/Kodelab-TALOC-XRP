/// Vault.sol

// SPDX-License-Identifier: Proprietary
//
// © 2024 Kodelab. All rights reserved.
// This smart contract code is developed and owned by Kodelab and provided to Taloc for deployment and use under the terms agreed upon with Kodelab.
// Unauthorized use, reproduction, modification, or distribution of this code by parties other than Taloc is strictly prohibited.
// Kodelab assumes no liability for any misuse, unintended outcomes, or errors arising from alterations made by third parties.
// For inquiries or further information, visit Kodelab at https://kodelab.io.


/// @notice Vault contract to hold assets for a single loan
contract Vault {
    address public talocClient;

    constructor() {
        talocClient = msg.sender;
    }

    modifier onlyTalocClient() {
        require(msg.sender == talocClient, "Vault: only TalocClient");
        _;
    }

    function withdrawERC20(address token, address to, uint256 amt) public onlyTalocClient {
        IERC20(token).transfer(to, amt);
    }

    function withdrawERC721(address token, address to, uint256 id) public onlyTalocClient {
        IERC721(token).transferFrom(address(this), to, id);
    }
}



interface IVault {
    function withdrawERC20(address token, address to, uint256 amt) external;
    function withdrawERC721(address token, address to, uint256 id) external;
}
