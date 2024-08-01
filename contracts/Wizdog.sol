// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import {IRouterClient} from "../.chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "../.chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {SafeERC20} from "../.chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableMap} from "../.chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/utils/structs/EnumerableMap.sol";

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
    mapping(uint64 => bool) public allowlistedDestinationChains;
    mapping(uint64 => bool) public allowlistedSourceChains;
    mapping(address => bool) public allowlistedSenders;
    address public allowlistedBurner;
    address public allowlistedMinter;
    uint256 public i_maxSupply;
    IRouterClient public s_router;
    IERC20 public s_linkToken;

    bool public swapping;

    address payable public devWallet;
    uint256 public buyTax;
    uint256 public sellTax;
    uint256 public swapTokensAtAmount; // Minimum tokens required for swap
    uint256 public maxTransfer; // Maximum transfer limit
}

contract Wizdog is ERC20, Proxiable, WizdogDataLayout {
    using SafeERC20 for IERC20;
    using EnumerableMap for EnumerableMap.Bytes32ToUintMap;

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

    /// @dev Modifier that checks if the chain with the given destinationChainSelector is allowlisted.
    /// @param _destinationChainSelector The selector of the destination chain.
    modifier onlyAllowlistedDestinationChain(uint64 _destinationChainSelector) {
        if (!allowlistedDestinationChains[_destinationChainSelector])
            revert DestinationChainNotAllowlisted(_destinationChainSelector);
        _;
    }

    /// @dev Modifier that checks if the chain with the given sourceChainSelector is allowlisted and if the sender is allowlisted.
    /// @param _sourceChainSelector The selector of the destination chain.
    /// @param _sender The address of the sender.
    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
        if (!allowlistedSourceChains[_sourceChainSelector])
            revert SourceChainNotAllowed(_sourceChainSelector);
        if (!allowlistedSenders[_sender]) revert SenderNotAllowed(_sender);
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

    function WizdogConstructor(address _router, address _link) public {
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

        s_router = IRouterClient(_router);
        s_linkToken = IERC20(_link);

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

    /// @dev Updates the allowlist status of a destination chain for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _destinationChainSelector The selector of the destination chain to be updated.
    /// @param allowed The allowlist status to be set for the destination chain.
    function allowlistDestinationChain(
        uint64 _destinationChainSelector,
        bool allowed
    ) external _onlyOwner {
        allowlistedDestinationChains[_destinationChainSelector] = allowed;
    }

    /// @dev Updates the allowlist status of a source chain
    /// @notice This function can only be called by the owner.
    /// @param _sourceChainSelector The selector of the source chain to be updated.
    /// @param allowed The allowlist status to be set for the source chain.
    function allowlistSourceChain(
        uint64 _sourceChainSelector,
        bool allowed
    ) external _onlyOwner {
        allowlistedSourceChains[_sourceChainSelector] = allowed;
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

    /// @notice Transfer tokens to receiver on the destination chain.
    /// @notice Pay in native gas such as ETH on Ethereum or MATIC on Polgon.
    /// @notice the token must be in the list of supported tokens.
    /// @notice This function can only be called by the owner.
    /// @dev Assumes your contract has sufficient native gas like ETH on Ethereum or MATIC on Polygon.
    /// @param _destinationChainSelector The identifier (aka selector) for the destination blockchain.
    /// @param _receiver The address of the recipient on the destination blockchain.
    /// @param _amount token amount.
    /// @return messageId The ID of the message that was sent.
    function transferTokensPayNative(
        uint64 _destinationChainSelector,
        address _receiver,
        uint256 _amount
    )
        external
        payable
        onlyAllowlistedDestinationChain(_destinationChainSelector)
        validateReceiver(_receiver)
        returns (bytes32 messageId)
    {
        address _token = address(this);
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        // address(0) means fees are paid in native gas
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _receiver,
            _token,
            _amount,
            address(0)
        );

        // Get the fee required to send the message
        uint256 fees = s_router.getFee(
            _destinationChainSelector,
            evm2AnyMessage
        );

        if (fees > msg.value) revert NotEnoughBalance(msg.value, fees);

        // approve the Router to spend tokens on contract's behalf. It will spend the amount of the given token
        IERC20(_token).approve(address(s_router), _amount);

        // Send the message through the router and store the returned message ID
        messageId = s_router.ccipSend{value: fees}(
            _destinationChainSelector,
            evm2AnyMessage
        );

        // Emit an event with message details
        emit TokensTransferredCCIP(
            messageId,
            _destinationChainSelector,
            _receiver,
            _token,
            _amount,
            address(0),
            fees
        );

        // Return the message ID
        return messageId;
    }

    /// @notice Construct a CCIP message.
    /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for tokens transfer.
    /// @param _receiver The address of the receiver.
    /// @param _token The token to be transferred.
    /// @param _amount The amount of the token to be transferred.
    /// @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas.
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
    function _buildCCIPMessage(
        address _receiver,
        address _token,
        uint256 _amount,
        address _feeTokenAddress
    ) private pure returns (Client.EVM2AnyMessage memory) {
        // Set the token amounts
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver), // ABI-encoded receiver address
                data: "", // No data
                tokenAmounts: tokenAmounts, // The amount and type of token being transferred
                extraArgs: Client._argsToBytes(
                    // Additional arguments, setting gas limit to 0 as we are not sending any data
                    Client.EVMExtraArgsV1({gasLimit: 0})
                ),
                // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
                feeToken: _feeTokenAddress
            });
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
