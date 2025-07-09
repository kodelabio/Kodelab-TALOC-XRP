// SPDX-License-Identifier: Proprietary
//
// © 2024 Kodelab. All rights reserved.
// This smart contract code is developed and owned by Kodelab and provided to Taloc for deployment and use under the terms agreed upon with Kodelab.
// Unauthorized use, reproduction, modification, or distribution of this code by parties other than Taloc is strictly prohibited.
// Kodelab assumes no liability for any misuse, unintended outcomes, or errors arising from alterations made by third parties.
// For inquiries or further information, visit Kodelab at https://kodelab.io.

import {Vault , IVault} from "./vault-proxy/Vault.sol";


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Minimal ERC721 interface for this use case
interface IERC721 {
    function mint(address to) external returns (uint256);
    function transferFrom(address from, address to, uint256 id) external;
    function setApprovalForAll(address operator, bool approved) external;
}

/// @notice Minimal ERC20 interface for this use case
interface IERC20 {
    function balanceOf(address user) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @notice Simple Initializable base contract
abstract contract Initializable {
    bool internal initialized;

    modifier initializer() {
        require(!initialized, "Initializable: contract is already initialized");
        _;
        initialized = true;
    }
}

/// @notice Pool contract to hold eTokens and allow owner withdrawal
contract Pool is Ownable {
    constructor(address eToken, address talocClient) Ownable(msg.sender) {
        IERC20(eToken).approve(talocClient, type(uint256).max);
    }

    function withdraw(address token, uint256 amount) public onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }
}


/// @notice Main TalocClient contract
contract TalocClient is Ownable, Initializable {
    // System variables
    address public eToken;
    address public pool; // eToken provider
    address public register; // register contract
    uint256 public rate; // loan rate, 5 decimals (e.g. 5000 = 5%)
    // tokenContract => tokenId => isWhitelisted
    mapping(address => mapping(uint256 => bool)) public whitelistAssets;

    constructor() Ownable(msg.sender) {}

    // Vault balance sheet
    struct VaultData {
        address tokenContract; // property token contract
        uint256 available;     // available amount
        uint256 debt;          // principal debt
        uint256 interest;      // accrued interest
        uint256 lastUpdate;    // last interest update timestamp
        uint256 tokenId;       // property tokenId
        bool active;           // true = usable, false = closed
        address owner;         // vault owner
        bool isPause;          // true = paused, false = not paused
    }

    uint256 public vaultIdCounter;
    mapping(uint256 => address) public vaults; // vaultId -> vault address
    mapping(uint256 => address) public vaultOwners; // vaultId -> owner
    mapping(uint256 => VaultData) public vaultData; // vaultId -> VaultData
    mapping(address => uint256[]) private ownerVaults; // owner -> vaultIds

    enum PaymentType {
        InterestPay,
        PartPay,
        FullPay
    }

    event Registered(
        uint256 indexed id,
        address user,
        uint256 value,
        address tokenContract,
        uint256 tokenId,
        uint256 timestamp
    );
    event Borrowed(
        uint256 indexed id,
        address user,
        uint256 amount,
        uint256 timestamp
    );
    event Repaid(
        uint256 indexed id,
        address user,
        uint256 amount,
        PaymentType paymentType,
        uint256 timestamp
    );
    event Closed(uint256 indexed id);
    event Deposited(uint256 indexed vaultId, address indexed user, uint256 amount, uint256 timestamp);

    modifier onlyRegister() {
        require(msg.sender == register, "TalocClient: only register");
        _;
    }

    modifier onlyVaultOwnerOrRegister(uint256 id) {
        require(vaultOwners[id] == msg.sender || msg.sender == register, "TalocClient: only vault owner or register");
        _;
    }

    modifier notPaused(uint256 id) {
        require(!vaultData[id].isPause, "Vault is paused");
        _;
    }

    function initialize(
        address _eToken,
        address _pool,
        address _register,
        uint256 _rate
    ) public  initializer {
        (eToken, pool, register, rate) = (_eToken, _pool, _register, _rate);
        Ownable(_register);
    }

    function file(bytes32 item, address value) public onlyOwner {
        if (item == "register") {
            register = value;
        } else if (item == "pool") {
            pool = value;
        } else if (item == "eToken") {
            eToken = value;
        } else {
            revert("TalocClient: invalid item");
        }
    }



    function calculateVaultInterest(uint256 id) public view returns (uint256) {
        VaultData memory v = vaultData[id];
        return calculateInterest(v.debt, block.timestamp - v.lastUpdate);
    }

    function calculateInterest(
        uint256 debt,
        uint256 timeElapsed
    ) public view returns (uint256) {
        return debt * timeElapsed * rate / 365 days / 1e5;
    }

    function getVaults(address user) public view returns (uint256[] memory) {
        return ownerVaults[user];
    }

    function registerVault(
        address user,
        uint256 amount,
        address tokenContract,
        uint256 tokenId
    ) public onlyRegister {
        require(user != address(0), "TalocClient: invalid address");

        vaultIdCounter++;
        Vault v = new Vault();

        // Transfer NFT to vault
        IERC721(tokenContract).transferFrom(msg.sender, address(v), tokenId);

        // Transfer eToken to vault
        IERC20(eToken).transferFrom(pool, address(v), amount);

        // Set mappings
        vaults[vaultIdCounter] = address(v);
        vaultOwners[vaultIdCounter] = user;
        ownerVaults[user].push(vaultIdCounter);
        vaultData[vaultIdCounter] = VaultData(tokenContract, amount, 0, 0, 0, tokenId, true, pool,false);

        emit Registered(vaultIdCounter, user, amount, tokenContract, tokenId, block.timestamp);
    }

    function whitelistToken(address tokenContract, uint256 tokenId) external onlyRegister {
        whitelistAssets[tokenContract][tokenId] = true;
    }

    function registerVaultByUser(
        address user,
        uint256 amount,
        address tokenContract,
        uint256 tokenId
    ) public {
        require(whitelistAssets[tokenContract][tokenId], "TalocClient: Asset not whitelisted");
        require(user != address(0), "TalocClient: invalid address");

        vaultIdCounter++;
        Vault v = new Vault();

        // Transfer NFT to vault
        IERC721(tokenContract).transferFrom(msg.sender, address(v), tokenId);


        // Set mappings
        vaults[vaultIdCounter] = address(v);
        vaultOwners[vaultIdCounter] = user;
        ownerVaults[user].push(vaultIdCounter);
        vaultData[vaultIdCounter] = VaultData(tokenContract, amount, 0, 0, 0, tokenId, true, user,false);

        emit Registered(vaultIdCounter, user, amount, tokenContract, tokenId, block.timestamp);
    }

    function depositToVault(uint256 vaultId) external onlyRegister {
        require(vaultId > 0 && vaultId <= vaultIdCounter, "Invalid vault ID");

        address vaultAddress = vaults[vaultId];
        require(vaultAddress != address(0), "Vault does not exist");

        VaultData storage v = vaultData[vaultId];
        require(v.active, "Vault is not active");

        uint256 amount = v.available;
        require(amount > 0, "No amount to deposit");

        // Transfer tokens from pool to vault
        require(IERC20(eToken).transferFrom(pool, vaultAddress, amount), "Token transfer failed");

        emit Deposited(vaultId, msg.sender, amount, block.timestamp);
    }

    function borrow(uint256 id, uint256 amount) public notPaused(id) {
        require(msg.sender == vaultOwners[id], "TalocClient: only vault owner");
        VaultData storage v = vaultData[id];
        require(v.active, "TalocClient: vault is closed");

        // Update interest
        if (v.debt > 0) {
            v.interest += calculateInterest(v.debt, block.timestamp - v.lastUpdate);
        }

        // Check available amount
        address vaultAddr = vaults[id];
        require(v.available >= amount, "TalocClient: not enough available amount");

        // Send eToken
        IVault(vaultAddr).withdrawERC20(eToken, msg.sender, amount);

        // Update balance sheet
        v.debt += amount;
        v.available -= amount;
        v.lastUpdate = block.timestamp;

        emit Borrowed(id, msg.sender, amount, block.timestamp);
    }

    function repay(uint256 id, uint256 amount) public {
        require(msg.sender == vaultOwners[id], "TalocClient: only vault owner");
        VaultData storage v = vaultData[id];
        require(v.active, "TalocClient: vault is closed");

        // Update interest
        v.interest += calculateInterest(v.debt, block.timestamp - v.lastUpdate);
        v.lastUpdate = block.timestamp;

        uint256 interestPaid;
        uint256 principalPaid;
        PaymentType paymentType;

        if (amount <= v.interest) {
            // Interest payment only
            interestPaid = amount;
            v.interest -= amount;
            paymentType = PaymentType.InterestPay;
        } else if (amount < v.debt + v.interest) {
            // Partial payment
            interestPaid = v.interest;
            principalPaid = amount - v.interest;
            v.debt -= principalPaid;
            v.available += principalPaid;
            v.interest = 0;
            paymentType = PaymentType.PartPay;
        } else {
            // Full payment
            interestPaid = v.interest;
            principalPaid = v.debt;
            v.available += v.debt;
            v.interest = 0;
            v.debt = 0;
            v.lastUpdate = 0;
            paymentType = PaymentType.FullPay;
        }

        // Payments
        if (interestPaid > 0) {
            require(IERC20(eToken).transferFrom(msg.sender, pool, interestPaid), "Interest transfer failed");
        }
        if (principalPaid > 0) {
            require(IERC20(eToken).transferFrom(msg.sender, vaults[id], principalPaid), "Principal transfer failed");
        }

        emit Repaid(id, msg.sender, amount, paymentType, block.timestamp);
    }

    function close(uint256 id) public onlyVaultOwnerOrRegister(id) notPaused(id) {
        VaultData storage v = vaultData[id];
        require(v.active, "TalocClient: vault is closed");
        require(v.debt == 0 && v.interest == 0, "TalocClient: please clear debt and interest");
        v.available = 0;

        // Release NFT
        address vaultAddr = vaults[id];
        IVault(vaultAddr).withdrawERC721(v.tokenContract, v.owner, v.tokenId);

        // Release eToken
        uint256 amt = IERC20(eToken).balanceOf(vaultAddr);
        if (amt > 0) {
            IVault(vaultAddr).withdrawERC20(eToken, pool, amt);
        }

        // Close vault
        v.active = false;
        emit Closed(id);
    }

    function updateRate(uint256 _newRate) external onlyOwner {
        require(_newRate <= 1e7, "Rate too high"); // Cap at 100%
        rate = _newRate;
    }

    function getRate() external view returns (uint256) {
        return rate;
    }

    function updateToken(address _eToken) external onlyOwner {
        eToken = _eToken;
    }

    function getToken() external view returns (address) {
        return eToken;
    }

    // Pagination: get vaults for a user, filtered by active status, with offset/limit
    function getVaults(
        address user,
        bool onlyActive,
        uint256 offset,
        uint256 limit
    ) public view returns (uint256[] memory, uint256) {
        uint256[] memory all = ownerVaults[user];
        uint256 count = 0;

        // Count matching vaults
        for (uint256 i = 0; i < all.length; i++) {
            if (vaultData[all[i]].active == onlyActive) {
                count++;
            }
        }

        // Return empty array if offset too large
        if (offset >= count) {
            return (new uint256[](0), count);
        }

        // Calculate end point of pagination
        uint256 end = offset + limit;
        if (end > count) {
            end = count;
        }

        uint256[] memory filtered = new uint256[](end - offset);
        uint256 idx = 0;
        uint256 j = 0;

        for (uint256 i = 0; i < all.length && j < end; i++) {
            if (vaultData[all[i]].active == onlyActive) {
                if (j >= offset) {
                    filtered[idx++] = all[i];
                }
                j++;
            }
        }

        return (filtered, count);
    }

    // Get all vaults for a user, filtered by active status
    function getVaults(
        address user,
        bool onlyActive
    ) public view returns (uint256[] memory) {
        uint256[] memory all = ownerVaults[user];
        uint256 count = 0;

        // Count how many match the filter
        for (uint256 i = 0; i < all.length; i++) {
            if (vaultData[all[i]].active == onlyActive) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 index = 0;

        // Collect filtered results
        for (uint256 i = 0; i < all.length; i++) {
            if (vaultData[all[i]].active == onlyActive) {
                result[index++] = all[i];
            }
        }

        return result;
    }


    function pauseVault(uint256 id) external onlyRegister {
        vaultData[id].isPause = true;
    }

    function unpauseVault(uint256 id) external onlyRegister {
        vaultData[id].isPause = false;
    }


}