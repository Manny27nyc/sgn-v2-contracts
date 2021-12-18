// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "./MultiBridgeToken.sol";

/**
 * @title Canonical token support multi-minter swap with per-bridge token
 */
contract MintSwapCanonicalToken is MultiBridgeToken {
    // each bridge token.balanceOf(this) tracks how much that bridge has already swapped
    mapping(address => uint256) public tokenSwapCap; // each bridge token -> swap cap

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) MultiBridgeToken(name_, symbol_, decimals_) {}

    // msg.sender has bridge_token and want to get canonical token
    function swapBridgeForCanonical(address bridgeToken, uint256 amount) external {
        // move bridge token from msg.sender to canonical token address
        IERC20(bridgeToken).transferFrom(msg.sender, address(this), amount);
        require(IERC20(bridgeToken).balanceOf(address(this)) < tokenSwapCap[bridgeToken], "exceed swap cap");
        _mint(msg.sender, amount);
    }

    // msg.sender has canonical and want to get bridge token (eg. for cross chain burn)
    function swapCanonicalForBridge(address bridgeToken, uint256 amount) external {
        _burn(msg.sender, amount);
        IERC20(bridgeToken).transfer(msg.sender, amount);
    }

    // update existing bridge token swap cap or add a new bridge token with swap cap
    // set cap to 0 will disable swapBridgeForCanonical, but swapCanonicalToBridge will still work
    function setBridgeTokenSwapCap(address bridgeToken, uint256 swapCap_) external onlyOwner {
        tokenSwapCap[bridgeToken] = swapCap_;
    }
}
