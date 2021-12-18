// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Canonical token support swap with per-bridge token
 */
contract SwapCanonicalToken is ERC20, Ownable {
    mapping(address => uint256) public swapCap; // each bridge token -> swap cap

    uint8 private immutable _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    // update existing bridge token swap cap or add a new bridge token with swap cap
    // set cap to 0 will disable swapBridgeForCanonical, but swapCanonicalToBridge will still work
    function setBridgeTokenSwapCap(address bridgeToken, uint256 swapCap_) external onlyOwner {
        swapCap[bridgeToken] = swapCap_;
    }

    // msg.sender has bridge_token and want to get canonical token
    function swapBridgeForCanonical(address bridgeToken, uint256 amount) external {
        // move bridge token from msg.sender to canonical token address
        IERC20(bridgeToken).transferFrom(msg.sender, address(this), amount);
        require(IERC20(bridgeToken).balanceOf(address(this)) < swapCap[bridgeToken], "exceed swap cap");
        _mint(msg.sender, amount);
    }

    // msg.sender has canonical and want to get bridge token (eg. for cross chain burn)
    function swapCanonicalForBridge(address bridgeToken, uint256 amount) external {
        _burn(msg.sender, amount);
        IERC20(bridgeToken).transfer(msg.sender, amount);
    }

    // to make compatible with BEP20
    function getOwner() external view returns (address) {
        return owner();
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
