
// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.20;

import "../lib/ds-auth/TalocAuth.sol";
import "../lib/ds-chief/TalocRoles.sol";
import "../lib/InterestMath.sol";
import "../utils/Uint256SetUtil.sol";
import "./TalocStorage.sol";
import "../vault-proxy/Vault.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC721 {
    function transferFrom(address from, address to, uint256 id) external;
}

contract TalocClient is TalocStorage, TalocAuth {
    using EnumerableSet for EnumerableSet.UintSet;
    using Uint256SetUtil for EnumerableSet.UintSet;

    enum PayKind { Interest, Part, Full }

    event VaultRegistered(uint256 indexed id, address user, uint256 value, address token, uint256 tokenId);
    event Borrowed(uint256 indexed id, address user, uint256 amount);
    event Repaid(uint256 indexed id, address user, uint256 amount, PayKind ptype);
    event Closed(uint256 indexed id);

    constructor(address admin) TalocAuth(admin) {}

    modifier notPaused(uint256 id) { require(!vaultInfo[id].paused, "paused"); _; }

    function initialize(address _e, address _pool, address _registry, uint256 _rate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        eToken   = IERC20(_e);
        pool     = Pool(_pool);
        registry = TalocRegistry(_registry);
        rate     = _rate;
    }

    function _charge(uint256 id) internal {
        VaultData storage v = vaultInfo[id];
        if (v.debt > 0) v.interest += InterestMath.accrue(v.debt, rate, block.timestamp - v.last);
        v.last = block.timestamp;
    }

    function _createVault(address token, uint256 tokenId, address owner_, uint256 avail) internal returns (uint256 id) {
        vaultCtr++;
        id = vaultCtr;
        Vault v = new Vault();
        IERC721(token).transferFrom(msg.sender, address(v), tokenId);
        vaultAddr[id] = address(v);
        vaultInfo[id] = VaultData(token, avail, 0, 0, 0, tokenId, true, owner_, false);
        _ownerVaults[owner_].add(id);
    }

    function registerVault(address user, uint256 avail, address token, uint256 tokenId) external onlyRegister {
        uint256 id = _createVault(token, tokenId, user, avail);
        emit VaultRegistered(id, user, avail, token, tokenId);
    }

    function borrow(uint256 id, uint256 amt) external notPaused(id) {
        VaultData storage v = vaultInfo[id];
        require(msg.sender == v.owner && v.active && v.avail >= amt);
        _charge(id);
        IVault(vaultAddr[id]).withdrawERC20(address(eToken), msg.sender, amt);
        v.debt  += amt;
        v.avail -= amt;
        emit Borrowed(id, msg.sender, amt);
    }

    function repay(uint256 id, uint256 amt) external {
        VaultData storage v = vaultInfo[id];
        require(msg.sender == v.owner && v.active);
        _charge(id);

        uint256 intPay;
        uint256 prinPay;
        PayKind kind;

        if (amt <= v.interest) { intPay = amt; v.interest -= amt; kind = PayKind.Interest; }
        else if (amt < v.interest + v.debt) {
            intPay = v.interest;
            prinPay = amt - v.interest;
            v.interest = 0;
            v.debt -= prinPay;
            v.avail += prinPay;
            kind = PayKind.Part;
        } else {
            intPay = v.interest;
            prinPay = v.debt;
            v.interest = 0;
            v.debt = 0;
            v.avail += prinPay;
            v.last = 0;
            kind = PayKind.Full;
        }

        if (intPay > 0)  eToken.transferFrom(msg.sender, address(pool), intPay);
        if (prinPay > 0) eToken.transferFrom(msg.sender, vaultAddr[id], prinPay);

        emit Repaid(id, msg.sender, amt, kind);
    }

    function close(uint256 id) external notPaused(id) {
        VaultData storage v = vaultInfo[id];
        require((msg.sender == v.owner || hasRole(TalocRoles.REGISTER_ROLE, msg.sender)) && v.active && v.debt == 0 && v.interest == 0);
        IVault(vaultAddr[id]).withdrawERC721(v.token, v.owner, v.id);
        uint256 bal = eToken.balanceOf(vaultAddr[id]);
        if (bal > 0) IVault(vaultAddr[id]).withdrawERC20(address(eToken), address(pool), bal);
        v.active = false;
        emit Closed(id);
    }

    function pauseVault(uint256 id) external onlyRegister { vaultInfo[id].paused = true; }
    function unpauseVault(uint256 id) external onlyRegister { vaultInfo[id].paused = false; }

    function userVaults(address u) external view returns (uint256[] memory) { return _ownerVaults[u].toArray(); }
    function details(uint256 id) external view returns (VaultData memory) { return vaultInfo[id]; }
}
