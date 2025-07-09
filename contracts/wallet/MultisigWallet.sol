
// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.20;

contract MultisigWallet {
    event Deposit(address indexed sender, uint256 value);
    event Submit(uint256 indexed txId);
    event Confirm(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);

    struct Transaction { address to; uint256 value; bytes data; bool executed; }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;

    Transaction[] public txs;
    mapping(uint256 => mapping(address => bool)) public confirmed;

    modifier onlyOwner { require(isOwner[msg.sender], "not owner"); _; }
    modifier txExists(uint256 id){ require(id < txs.length, "tx exists"); _; }
    modifier notExecuted(uint256 id){ require(!txs[id].executed, "executed"); _; }
    modifier notConfirmed(uint256 id){ require(!confirmed[id][msg.sender], "confirmed"); _; }

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0 && _required > 0 && _required <= _owners.length, "owners/required");
        for (uint256 i; i < _owners.length; i++) {
            address o = _owners[i];
            require(o != address(0) && !isOwner[o], "dup/zero");
            isOwner[o] = true;
        }
        owners = _owners;
        required = _required;
    }

    receive() external payable { emit Deposit(msg.sender, msg.value); }

    function submit(address to, uint256 value, bytes memory data) external onlyOwner returns (uint256 id) {
        id = txs.length;
        txs.push(Transaction(to, value, data, false));
        emit Submit(id);
    }

    function confirm(uint256 id) external onlyOwner txExists(id) notExecuted(id) notConfirmed(id) {
        confirmed[id][msg.sender] = true;
        emit Confirm(msg.sender, id);
        if (_count(id) >= required) execute(id);
    }

    function execute(uint256 id) public onlyOwner txExists(id) notExecuted(id) {
        require(_count(id) >= required, "quorum");
        Transaction storage t = txs[id];
        t.executed = true;
        (bool ok, ) = t.to.call{value: t.value}(t.data);
        require(ok, "call failed");
        emit Execute(id);
    }

    function _count(uint256 id) internal view returns (uint256 c) {
        for (uint256 i; i < owners.length; i++) if (confirmed[id][owners[i]]) c++;
    }
}
