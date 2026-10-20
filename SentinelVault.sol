// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title SentinelVault — on-chain spending wall for an AI wallet agent
/// @notice The agent (session key) can spend only within per-tx and daily caps,
///         and only to allowlisted addresses. The owner sets policy, approves
///         elevated (T3) actions, and can pause everything. Testnet use only.
contract SentinelVault {
    address public owner;
    address public agent;          // session key used by the off-chain Executor
    uint256 public perTxCap;       // wei
    uint256 public dailyCap;       // wei, rolling 24h window
    uint256 public windowStart;
    uint256 public spentInWindow;
    bool public paused;
    mapping(address => bool) public allowed;

    event Executed(address indexed to, uint256 amount, bool byOwner);
    event PolicyChanged(uint256 perTxCap, uint256 dailyCap);
    event AllowlistChanged(address indexed who, bool allowed);
    event AgentChanged(address indexed agent);
    event Paused(bool paused);

    error NotOwner();
    error NotAgent();
    error IsPaused();
    error NotAllowlisted();
    error OverPerTxCap();
    error OverDailyCap();
    error TransferFailed();

    modifier onlyOwner() { if (msg.sender != owner) revert NotOwner(); _; }

    constructor(address _agent, uint256 _perTxCap, uint256 _dailyCap) {
        owner = msg.sender;
        agent = _agent;
        perTxCap = _perTxCap;
        dailyCap = _dailyCap;
        windowStart = block.timestamp;
    }

    receive() external payable {}

    /// @notice T2: autonomous agent spend, enforced on-chain.
    function execute(address payable to, uint256 amount) external {
        if (msg.sender != agent) revert NotAgent();
        if (paused) revert IsPaused();
        if (!allowed[to]) revert NotAllowlisted();
        if (amount > perTxCap) revert OverPerTxCap();
        if (block.timestamp >= windowStart + 1 days) {
            windowStart = block.timestamp;
            spentInWindow = 0;
        }
        if (spentInWindow + amount > dailyCap) revert OverDailyCap();
        spentInWindow += amount;
        _send(to, amount);
        emit Executed(to, amount, false);
    }

    /// @notice T3: owner-approved action outside agent limits.
    function executeWithOwner(address payable to, uint256 amount) external onlyOwner {
        if (paused) revert IsPaused();
        _send(to, amount);
        emit Executed(to, amount, true);
    }

    // T4: policy changes are owner-only and never reachable by the agent.
    function setAllowed(address who, bool ok) external onlyOwner { allowed[who] = ok; emit AllowlistChanged(who, ok); }
    function setCaps(uint256 _perTx, uint256 _daily) external onlyOwner { perTxCap = _perTx; dailyCap = _daily; emit PolicyChanged(_perTx, _daily); }
    function setAgent(address _agent) external onlyOwner { agent = _agent; emit AgentChanged(_agent); }
    function setPaused(bool p) external onlyOwner { paused = p; emit Paused(p); }

    function _send(address payable to, uint256 amount) private {
        (bool ok, ) = to.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }
}
