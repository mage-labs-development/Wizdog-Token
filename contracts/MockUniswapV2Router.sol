// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockUniswapV2Router {
    address public WETH;
    address public factory;

    constructor() {
        WETH = address(this);
        factory = address(this);
    }

    function createPair(address tokenA, address tokenB) external pure returns (address pair) {
        // This is a mock function, so we're just returning a dummy address
        pair = address(uint160(uint256(keccak256(abi.encodePacked(tokenA, tokenB)))));
    }
}