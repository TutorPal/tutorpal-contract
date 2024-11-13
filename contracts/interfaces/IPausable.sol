// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Pausable {
    error Paused();

    event MarketPaused(address user);
    event MarketUnPaused(address user);

    bool public paused = false;

    modifier notPaused() {
        if (paused) revert Paused();
        _;
    }

    function _pauseTrading() internal {
        paused = true;
        emit MarketPaused(msg.sender);
    }

    function _unpauseTrading() internal {
        paused = false;
        emit MarketUnPaused(msg.sender);
    }
}
