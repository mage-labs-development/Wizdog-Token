// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(
                0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7
            ) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {
            // solium-disable-line
            sstore(
                0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7,
                newAddress
            )
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return
            0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

contract LibraryLockDataLayout {
    bool public initialized;
    bool public isDirect;
}

contract LibraryLock is LibraryLockDataLayout {
    // Ensures no one can manipulate the Logic Contract once it is deployed.
    // PARITY WALLET HACK PREVENTION

    modifier delegatedOnly() {
        require(
            initialized,
            "The library is locked. No direct 'call' is allowed"
        );
        require(isDirect, "Direct calls only");
        _;
    }
    function initialize() internal {
        initialized = true;
        isDirect = false;
    }
}

contract LABSDataLayout is LibraryLock {
    address public owner;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
}

contract LABS is ERC20, Proxiable, LABSDataLayout {

    bool private swapping;

    address payable public devWallet;
    uint256 public buyTax = 5;
    uint256 public sellTax = 5;
    uint256 public swapTokensAtAmount = 100000 * 10 ** decimals(); // Minimum tokens required for swap
    uint256 public maxTransfer = 50000000 * 10 ** decimals(); // Maximum transfer limit

    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    mapping(address => bool) private _isExcludedFromFees;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    constructor() ERC20("LABS", "LABS") {
        
    }

    function LABSConstructor() public {
        require(!initialized);
        constructor1("LABS", "LABS");
        owner = msg.sender;
        devWallet = payable(msg.sender);
        _mint(msg.sender, 1000000000 * 10 ** 18);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner, true);
        excludeFromFees(address(this), true);
        initialize();
    }

    receive() external payable {}

    /** @notice Sets contract owner.
     * @param _owner  Address of the new owner.
     */
    function setOwner(address _owner) public _onlyOwner delegatedOnly {
        owner = _owner;
    }

    /** @notice Allows the owner to immediately update the contract logic.
     * @param newCode Address of the new logic contract.
     */
    function updateCode(address newCode) public _onlyOwner delegatedOnly {
        updateCodeAddress(newCode);
    }

    function setUniswapV2Router(address _router) external _onlyOwner {
        uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
    }

    function excludeFromFees(address account, bool excluded) public _onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "PAN: Account is already excluded"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public _onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setDevWallet(address payable wallet) external _onlyOwner {
        devWallet = wallet;
    }

    function setSwapAtAmount(uint256 value) external _onlyOwner {
        swapTokensAtAmount = value;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap && !swapping && from != owner && to != owner) {
            swapping = true;

            uint256 tokensToSwap = swapTokensAtAmount;
            swapAndSendToFee(tokensToSwap);

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            require(
                amount <= maxTransfer,
                "Transfer amount exceeds the maximum limit"
            );

            uint256 taxAmount;

            if (from == uniswapV2Pair) {
                taxAmount = (amount * buyTax) / 100;
            } else if (to == uniswapV2Pair) {
                taxAmount = (amount * sellTax) / 100;
            } else {
                taxAmount = 0;
            }

            uint256 transferAmount = amount - taxAmount;

            super._transfer(from, address(this), taxAmount);
            super._transfer(from, to, transferAmount);
        } else {
            super._transfer(from, to, amount);
        }
    }


    function setBuyTaxFee(uint256 _taxFee) public _onlyOwner {
        buyTax = _taxFee;
    }

    function setSellFee(uint256 _taxFee) public _onlyOwner {
        sellTax = _taxFee;
    }

    function setMaxTransfer(uint256 _maxTransfer) public _onlyOwner {
        maxTransfer = _maxTransfer;
    }

    function swapAndSendToFee(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(tokens);
        uint256 newBalance = address(this).balance - initialBalance;

        devWallet.transfer(newBalance);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}
