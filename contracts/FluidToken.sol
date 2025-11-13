// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80);
    function decimals() external view returns (uint8);
}

/**
 * @title FluidToken ULTRA
 * @notice Gas-optimized, secure FluidToken with dynamic pricing, proportional airdrop, manual burn
 */
contract FluidToken is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // === ERRORS ===
    error InvalidAmount();
    error InsufficientBalance();
    error NotSigner();
    error SalesPaused();
    error NoPriceFeed();
    error InvalidPrice();
    error SaleCapExceeded();
    error NothingToClaim();
    error ClaimTooEarly();
    error MissedYear();
    error PriceUpdateTooSoon();

    // === IMMUTABLE CONSTANTS ===
    uint256 public immutable TOTAL_SUPPLY = 10_000_000 * 1e18;
    uint256 public immutable SALE_SUPPLY = (TOTAL_SUPPLY * 40) / 100;
    uint256 public immutable AIRDROP_SUPPLY = (TOTAL_SUPPLY * 30) / 100;
    uint256 public immutable MARKETING_LIQUIDITY_SUPPLY = (TOTAL_SUPPLY * 10) / 100;
    uint256 public immutable TEAM_SUPPLY = (TOTAL_SUPPLY * 10) / 100;
    uint256 public immutable DEV_SUPPLY = (TOTAL_SUPPLY * 10) / 100;
    uint8 public immutable AIRDROP_YEARS = 5;
    uint256 public immutable PRICE_UPDATE_COOLDOWN = 1 hours;

    // === IMMUTABLE WALLETS ===
    address public immutable marketingWallet;
    address public immutable teamWallet;
    address public immutable devWallet;

    // === PACKED STORAGE ===
    uint128 public fluidSold;
    uint256 public lastPriceUpdate;
    uint256 public basePriceUSDT6;

    // === DYNAMIC STATE ===
    address public foundationWallet;
    address public relayerWallet;
    mapping(address => AggregatorV3Interface) public priceFeeds;
    AggregatorV3Interface public nativePriceFeed;
    bool public salesPaused;

    // === AIRDROP ===
    struct AirdropInfo {
        uint128 totalAllocated;
        uint8 claimedYears;
        uint48 startTime;
        bool completed;
    }
    mapping(address => AirdropInfo) public airdrops;
    uint256 public distributedAirdrops;

    // === MULTISIG ===
    address[] public signers;
    mapping(address => bool) public isSigner;
    uint256 public requiredApprovals;

    struct Proposal {
        address token;
        address to;
        uint256 amount;
        uint256 approvals;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalApprovedBy;
    uint256 public proposalCount;

    // === STATS ===
    uint256 public totalBurned;

    // === EVENTS ===
    event PriceUpdated(uint256 newPriceUSDT6);
    event PriceFeedSet(address indexed token, address feed);
    event NativeFeedSet(address feed);
    event FoundationWalletUpdated(address newWallet);
    event SaleExecuted(address indexed buyer, address payToken, uint256 payAmount, uint256 fluidAmount);
    event AirdropAllocated(address indexed user, uint256 amount);
    event AirdropClaimed(address indexed user, uint256 amount, uint8 year);
    event TokensBurned(address indexed burner, uint256 amount);
    event ContractTokensBurned(uint256 amount);
    event SalesPaused(bool paused);
    event ProposalCreated(uint256 id, address token, address to, uint256 amount);
    event ProposalApproved(uint256 id, address approver);
    event ProposalExecuted(uint256 id, address executor);

    // === MODIFIERS ===
    modifier whenNotPaused() {
        if (salesPaused) revert SalesPaused();
        _;
    }

    modifier onlySigner() {
        if (!isSigner[msg.sender]) revert NotSigner();
        _;
    }

    // === CONSTRUCTOR ===
    constructor(
        address _foundationWallet,
        address _relayerWallet,
        address[] memory _initialSigners,
        uint256 _requiredApprovals,
        address _marketingWallet,
        address _teamWallet,
        address _devWallet
    ) ERC20("Fluid Token", "FLUID") {
        if (_foundationWallet == address(0) || _relayerWallet == address(0)) revert InvalidAmount();
        if (_initialSigners.length < _requiredApprovals || _requiredApprovals == 0) revert InvalidAmount();

        foundationWallet = _foundationWallet;
        relayerWallet = _relayerWallet;
        marketingWallet = _marketingWallet;
        teamWallet = _teamWallet;
        devWallet = _devWallet;

        basePriceUSDT6 = 1e6;
        lastPriceUpdate = block.timestamp;

        _mint(address(this), TOTAL_SUPPLY);
        _transfer(address(this), marketingWallet, MARKETING_LIQUIDITY_SUPPLY);
        _transfer(address(this), teamWallet, TEAM_SUPPLY);
        _transfer(address(this), devWallet, DEV_SUPPLY);

        for (uint i = 0; i < _initialSigners.length; i++) {
            address s = _initialSigners[i];
            if (s == address(0) || isSigner[s]) revert InvalidAmount();
            isSigner[s] = true;
            signers.push(s);
        }
        requiredApprovals = _requiredApprovals;
    }

    // === PRICE ===
    function setBasePriceUSDT6(uint256 priceUSDT6) external onlyOwner {
        if (priceUSDT6 == 0) revert InvalidAmount();
        if (block.timestamp < lastPriceUpdate + PRICE_UPDATE_COOLDOWN) revert PriceUpdateTooSoon();
        basePriceUSDT6 = priceUSDT6;
        lastPriceUpdate = block.timestamp;
        emit PriceUpdated(priceUSDT6);
    }

    function getCurrentPriceUSDT6() public view returns (uint256) {
        unchecked {
            uint256 soldPercent = (uint256(fluidSold) * 10000) / SALE_SUPPLY;
            return basePriceUSDT6 + (basePriceUSDT6 * soldPercent) / 10000;
        }
    }

    // === ADMIN ===
    function setPriceFeed(address token, address feed) external onlyOwner {
        if (token == address(0) || feed == address(0)) revert InvalidAmount();
        priceFeeds[token] = AggregatorV3Interface(feed);
        emit PriceFeedSet(token, feed);
    }

    function setNativePriceFeed(address feed) external onlyOwner {
        if (feed == address(0)) revert InvalidAmount();
        nativePriceFeed = AggregatorV3Interface(feed);
        emit NativeFeedSet(feed);
    }

    function setFoundationWallet(address newWallet) external onlyOwner {
        if (newWallet == address(0)) revert InvalidAmount();
        foundationWallet = newWallet;
        emit FoundationWalletUpdated(newWallet);
    }

    function pauseSales() external onlyOwner {
        salesPaused = true;
        emit SalesPaused(true);
    }

    function unpauseSales() external onlyOwner {
        salesPaused = false;
        emit SalesPaused(false);
    }

    // === SALES ===
    function buyWithERC20(address payToken, uint256 payAmount) external whenNotPaused nonReentrant {
        if (payAmount == 0) revert InvalidAmount();
        AggregatorV3Interface feed = priceFeeds[payToken];
        if (address(feed) == address(0)) revert NoPriceFeed();

        IERC20(payToken).safeTransferFrom(msg.sender, foundationWallet, payAmount);

        (, int256 price,, uint256 updatedAt,) = feed.latestRoundData();
        if (price <= 0 || block.timestamp > updatedAt + 1 hours) revert InvalidPrice();

        uint8 aggDecimals = feed.decimals();
        uint8 tokenDecimals = 18;
        try IERC20Metadata(payToken).decimals() returns (uint8 d) { tokenDecimals = d; } catch {}

        unchecked {
            uint256 usd18 = (payAmount * uint256(price) * 1e18) / ((10 ** tokenDecimals) * (10 ** aggDecimals));
            uint256 priceUSDT6 = getCurrentPriceUSDT6();
            uint256 fluidAmount = (usd18 * 1e6) / priceUSDT6;

            if (fluidAmount == 0) {
                IERC20(payToken).safeTransfer(msg.sender, payAmount);
                return;
            }
            if (uint256(fluidSold) + fluidAmount > SALE_SUPPLY) revert SaleCapExceeded();
        }

        uint256 contractBal = balanceOf(address(this));
        if (contractBal < fluidAmount) revert InsufficientBalance();

        _transfer(address(this), msg.sender, fluidAmount);
        fluidSold = uint128(uint256(fluidSold) + fluidAmount);

        unchecked {
            uint256 airdropAlloc = (fluidAmount * AIRDROP_SUPPLY) / SALE_SUPPLY;
            if (airdropAlloc > 0 && distributedAirdrops + airdropAlloc <= AIRDROP_SUPPLY) {
                _allocateAirdrop(msg.sender, airdropAlloc);
            }
        }

        emit SaleExecuted(msg.sender, payToken, payAmount, fluidAmount);
    }

    function buyWithNative() external payable whenNotPaused nonReentrant {
        if (msg.value == 0) revert InvalidAmount();

        (bool sent,) = payable(foundationWallet).call{value: msg.value}("");
        if (!sent) revert InvalidAmount();

        (, int256 answer,, uint256 updatedAt,) = nativePriceFeed.latestRoundData();
        if (answer <= 0 || block.timestamp > updatedAt + 1 hours) revert InvalidPrice();

        uint8 aggDecimals = nativePriceFeed.decimals();
        unchecked {
            uint256 usd18 = (msg.value * uint256(answer) * 1e18) / (1e18 * (10 ** aggDecimals));
            uint256 priceUSDT6 = getCurrentPriceUSDT6();
            uint256 fluidAmount = (usd18 * 1e6) / priceUSDT6;

            if (fluidAmount == 0) {
                (bool refund,) = payable(msg.sender).call{value: msg.value}("");
                if (!refund) revert InvalidAmount();
                return;
            }
            if (uint256(fluidSold) + fluidAmount > SALE_SUPPLY) revert SaleCapExceeded();
        }

        uint256 contractBal = balanceOf(address(this));
        if (contractBal < fluidAmount) revert InsufficientBalance();

        _transfer(address(this), msg.sender, fluidAmount);
        fluidSold = uint128(uint256(fluidSold) + fluidAmount);

        unchecked {
            uint256 airdropAlloc = (fluidAmount * AIRDROP_SUPPLY) / SALE_SUPPLY;
            if (airdropAlloc > 0 && distributedAirdrops + airdropAlloc <= AIRDROP_SUPPLY) {
                _allocateAirdrop(msg.sender, airdropAlloc);
            }
        }

        emit SaleExecuted(msg.sender, address(0), msg.value, fluidAmount);
    }

    // === AIRDROP ===
    function _allocateAirdrop(address user, uint256 amount) internal {
        if (user == address(0) || amount == 0) revert InvalidAmount();

        AirdropInfo storage info = airdrops[user];
        if (info.totalAllocated == 0) {
            info.startTime = uint48(block.timestamp);
        }
        unchecked {
            info.totalAllocated = uint128(uint256(info.totalAllocated) + amount);
            distributedAirdrops += amount;
        }
        emit AirdropAllocated(user, amount);
    }

    function claimAirdrop() external nonReentrant {
        AirdropInfo storage info = airdrops[msg.sender];
        if (info.totalAllocated == 0 || info.completed) revert NothingToClaim();

        unchecked {
            uint256 yearsSince = (block.timestamp - info.startTime) / 365 days;
            if (yearsSince == 0) revert ClaimTooEarly();
            uint8 currentYear = yearsSince > AIRDROP_YEARS ? AIRDROP_YEARS : uint8(yearsSince);
            if (info.claimedYears >= currentYear) revert MissedYear();

            uint256 perYear = uint256(info.totalAllocated) / AIRDROP_YEARS;
            info.claimedYears = currentYear;
            if (info.claimedYears == AIRDROP_YEARS) info.completed = true;

            _transfer(address(this), msg.sender, perYear);
            emit AirdropClaimed(msg.sender, perYear, currentYear);
        }
    }

    function getAirdropInfo(address user) external view returns (
        uint256 totalAllocated,
        uint8 claimedYears,
        uint256 claimableAmount,
        bool canClaim,
        uint8 currentYear
    ) {
        AirdropInfo memory info = airdrops[user];
        if (info.totalAllocated == 0) return (0, 0, 0, false, 0);

        unchecked {
            uint256 yearsSince = (block.timestamp - info.startTime) / 365 days;
            currentYear = yearsSince > AIRDROP_YEARS ? AIRDROP_YEARS : uint8(yearsSince);
            canClaim = currentYear > info.claimedYears;
            uint256 perYear = uint256(info.totalAllocated) / AIRDROP_YEARS;
            claimableAmount = canClaim ? perYear : 0;
        }

        return (uint256(info.totalAllocated), info.claimedYears, claimableAmount, canClaim, currentYear);
    }

    // === BURN ===
    function burn(uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        _burn(msg.sender, amount);
        unchecked { totalBurned += amount; }
        emit TokensBurned(msg.sender, amount);
    }

    function burnContractTokens(uint256 amount) external onlyOwner {
        if (amount == 0) revert InvalidAmount();
        if (balanceOf(address(this)) < amount) revert InsufficientBalance();
        _burn(address(this), amount);
        unchecked { totalBurned += amount; }
        emit ContractTokensBurned(amount);
    }

    // === MULTISIG ===
    function createProposal(address token, address to, uint256 amount) external onlySigner returns (uint256) {
        if (to == address(0) || amount == 0) revert InvalidAmount();
        unchecked { proposalCount++; }
        proposals[proposalCount] = Proposal(token, to, amount, 0, false);
        emit ProposalCreated(proposalCount, token, to, amount);
        return proposalCount;
    }

    function approveProposal(uint256 id) external onlySigner {
        if (id == 0 || id > proposalCount) revert InvalidAmount();
        Proposal storage p = proposals[id];
        if (proposalApprovedBy[id][msg.sender] || p.executed) revert InvalidAmount();
        unchecked { p.approvals++; }
        proposalApprovedBy[id][msg.sender] = true;
        emit ProposalApproved(id, msg.sender);
    }

    function executeProposal(uint256 id) external onlySigner {
        Proposal storage p = proposals[id];
        if (p.executed || p.approvals < requiredApprovals) revert InvalidAmount();

        if (p.token == address(0)) {
            (bool sent,) = payable(p.to).call{value: p.amount}("");
            if (!sent) revert InvalidAmount();
        } else {
            IERC20(p.token).safeTransfer(p.to, p.amount);
        }

        p.executed = true;
        emit ProposalExecuted(id, msg.sender);
    }

    receive() external payable {}
}