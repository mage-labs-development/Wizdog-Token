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

    function initialize() internal {
        initialized = true;
        isDirect = false;
    }
}

contract WizdogDataLayout is LibraryLock {
    address public owner;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    mapping(address => bool) public _isExcludedFromFees;
    address public allowlistedBurner;
    address public allowlistedMinter;
    uint256 public i_maxSupply;

    bool public swapping;

    address payable public devWallet;
    uint256 public buyTax;
    uint256 public sellTax;
    uint256 public swapTokensAtAmount; // Minimum tokens required for swap
    uint256 public maxTransfer; // Maximum transfer limit
}

contract Wizdog is ERC20, Proxiable, WizdogDataLayout {

    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier _onlyBurner() {
        require(msg.sender == allowlistedBurner);
        _;
    }

    modifier _onlyMinter() {
        require(msg.sender == allowlistedMinter);
        _;
    }

    /// @dev Modifier that checks the receiver address is not 0.
    /// @param _receiver The receiver address.
    modifier validateReceiver(address _receiver) {
        if (_receiver == address(0)) revert InvalidReceiverAddress();
        _;
    }

    /// @dev Modifier to allow only the contract itself to execute a function.
    /// Throws an exception if called by any account other than the contract itself.
    modifier onlySelf() {
        if (msg.sender != address(this)) revert OnlySelf();
        _;
    }

    modifier validAddress(address recipient) virtual {
        if (recipient == address(this)) revert();
        _;
    }

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetOwner(address newOwner);
    event UpdateCode(address newAddress);
    event SetUniswapV2Router(address newRouter);
    event SetDevWallet(address newWallet);
    event SetSwapAtAmount(uint256 amount);

    //CCIP Events
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance to cover the fees.
    error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error FailedToWithdrawEth(address owner, address target, uint256 value); // Used when the withdrawal of Ether fails.
    error DestinationChainNotAllowlisted(uint64 destinationChainSelector); // Used when the destination chain has not been allowlisted by the contract owner.
    error InvalidReceiverAddress(); // Used when the receiver address is 0.
    error SourceChainNotAllowed(uint64 sourceChainSelector); // Used when the source chain has not been allowlisted by the contract owner.
    error SenderNotAllowed(address sender); // Used when the sender has not been allowlisted by the contract owner.
    error OnlySelf(); // Used when a function is called outside of the contract itself.
    error ErrorCase(); // Used when simulating a revert during message processing.
    error MessageNotFailed(bytes32 messageId);
    event TokensTransferredCCIP(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        address token, // The token address that was transferred.
        uint256 tokenAmount, // The token amount that was transferred.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the message.
    );
    error MaxSupplyExceeded(uint256 supplyAfterMint);

    enum ErrorCode {
        // RESOLVED is first so that the default value is resolved.
        RESOLVED,
        // Could have any number of error codes here.
        FAILED
    }

    struct FailedMessage {
        bytes32 messageId;
        ErrorCode errorCode;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        initialize();
    }

    function WizdogConstructor(address _router) public {
        require(!initialized);
        ERCConstructor("Magelabs", "WIZDOG");
        owner = msg.sender;
        devWallet = payable(msg.sender);
        _mint(msg.sender, 1000000000 * 10 ** 18);
        i_maxSupply = totalSupply();
        buyTax = 5;
        sellTax = 5;
        swapTokensAtAmount = 100000 * 10 ** decimals(); // Minimum tokens required for swap
        maxTransfer = 50000000 * 10 ** decimals(); // Maximum transfer limit

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner, true);
        excludeFromFees(address(this), true);
        initialize();
    }

    receive() external payable {}

    /** @notice Sets contract owner.
     * @param _owner  Address of the new owner.
     */
    function setOwner(address _owner) public _onlyOwner {
        owner = _owner;
        emit SetOwner(_owner);
    }

    /** @notice Allows the owner to immediately update the contract logic.
     * @param newCode Address of the new logic contract.
     */
    function updateCode(address newCode) public _onlyOwner {
        updateCodeAddress(newCode);
        emit UpdateCode(newCode);
    }

    function setUniswapV2Router(address _router) external _onlyOwner {
        uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        emit SetUniswapV2Router(_router);
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
        emit SetDevWallet(wallet);
    }

    function setSwapAtAmount(uint256 value) external _onlyOwner {
        swapTokensAtAmount = value;
        emit SetSwapAtAmount(value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function setAllowedCCIPBurner(address _burner) external _onlyOwner {
        allowlistedBurner = _burner;
    }

    function setAllowedCCIPMinter(address _minter) external _onlyOwner {
        allowlistedMinter = _minter;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
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

        (bool success, ) = devWallet.call{value: newBalance}("");
        require(success, "Fee transfer failed");
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

    /// @dev Disallows minting to address(0)
    /// @dev Increases the total supply.
    function mint(
        address account,
        uint256 amount
    ) external _onlyMinter validAddress(account) {
        if (i_maxSupply != 0 && totalSupply() + amount > i_maxSupply)
            revert MaxSupplyExceeded(totalSupply() + amount);
        if (account == address(0))
            revert InvalidReceiverAddress();
        _mint(account, amount);
    }

    /// @dev Decreases the total supply.
    function burn(uint256 amount) public _onlyBurner {
        if (msg.sender == address(0))
            revert InvalidReceiverAddress();
        _burn(msg.sender, amount);
    }

    
}
