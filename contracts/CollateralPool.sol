pragma solidity 0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorInterface.sol";
import "./RToken.sol";
import "./Ratio.sol";


contract CollateralPool is Ownable  {
	using SafeMath for uint;

	mapping(address => uint) public assets;
	mapping(address => uint) public rates;
	mapping(address => uint) public fees;
	mapping(address => mapping(address => uint)) public claimed;
    mapping (address => AggregatorInterface) public feeds;

    uint private _feeRate = 1000;
	uint private _constRate = 10 ** 18;

	Ratio private _ratio;

    event Collaterize(address account, address asset, uint amount, uint ratioAmt);
    event Reedem(address account, address asset, uint amount);
    event Claim(address account, address asset, uint amount);
    event SetRatio(address ratioAddress);

	constructor(address ratioAddress) public {
		_ratio = Ratio(ratioAddress);
	}

	modifier isApproved(address asset) {
		require(rates[asset] != 0);
		_;
	}

	modifier hasFeed(address asset) {
		require(feeds[asset].latestAnswer() != 0);
		_;
	}

	function getRatioPrice() public view returns (int) {
		return feeds[address(_ratio)].latestAnswer();
	}

	function getAssetPrice(address asset) public view returns (int) {
		return feeds[asset].latestAnswer();
	}

	function registerAsset(address asset) public onlyOwner {
		assets[asset] = RToken(asset).totalSupply();
		rates[asset] = _constRate;
	}

	function registerFeed(address asset, address feed) public onlyOwner isApproved(asset) {
		feeds[asset] = AggregatorInterface(feed);
	}

	function setRatio(address ratioAddress) public onlyOwner {
		_ratio = Ratio(ratioAddress);
		emit SetRatio(ratioAddress);
	}

	function collaterize(address asset, uint amount, uint ratioAmt) public isApproved(asset) hasFeed(asset) {
		uint rate = rates[asset];
		uint fee = amount.div(_feeRate);
		fees[asset] += fee;
		uint afterFee = amount.sub(fee);
		if (rate == _constRate) {
			RToken(asset).mint(msg.sender, afterFee);
			IERC20(asset).transferFrom(msg.sender, address(this), amount);
		} else {
			if (amount > 0) {			
				uint minted = amount.mul(_constRate).div(rate);
				uint left = minted.sub(amount);
				RToken(asset).mint(msg.sender, afterFee);
				RToken(asset).mint(address(this), minted);
				IERC20(asset).transferFrom(msg.sender, address(this), amount);
			}
			if (ratioAmt > 0) {
				int ratioPriceInt = getRatioPrice();
				require(ratioPriceInt >= 0);
				uint ratioPrice = uint(ratioPriceInt);
				int assetPriceInt = getAssetPrice(asset);
				require(assetPriceInt >= 0);
				uint assetPrice = uint(assetPriceInt);
				uint burned = amount.mul(ratioPrice).div(assetPrice);
				_ratio.burn(msg.sender, burned);
				RToken(asset).transferFrom(address(this), msg.sender, afterFee);
			}
		}
		emit Collaterize(msg.sender, asset, amount, ratioAmt);
	}

	function reedem(address asset, uint amount) public onlyOwner isApproved(asset) hasFeed(asset) {
		uint rate = rates[asset];
		RToken(asset).burn(msg.sender, amount);
		if (rate == _constRate) {
			uint fee = amount.div(_feeRate);
			IERC20(asset).transferFrom(address(this), msg.sender, amount.sub(fee));
		} else {
			int ratioPrice = getRatioPrice();
			require(ratioPrice >= 0);
			uint price = uint(ratioPrice);
			int assetPrice = getAssetPrice(asset);
			require(assetPrice >= 0);
			uint minted = amount.mul(price).div(uint(assetPrice)).mul(_constRate.sub(rate)).div(_constRate);
			uint assetAmt = amount.mul(rate).div(_constRate);
			fees[asset] += assetAmt.div(_feeRate);
			_ratio.mint(msg.sender, minted);
			IERC20(asset).transferFrom(address(this), msg.sender, assetAmt.mul(_feeRate.sub(1)).div(_feeRate));
		}
		emit Reedem(msg.sender, asset, amount);
	}

	function claim(address asset) public isApproved(asset) {
		require(fees[asset] > claimed[asset][msg.sender]);
		uint toClaim = fees[asset].sub(claimed[asset][msg.sender]);
		uint share = toClaim.mul(_ratio.balanceOf(msg.sender)).div(_ratio.totalSupply());
		claimed[asset][msg.sender] = fees[asset];
		IERC20(asset).transferFrom(address(this), msg.sender, toClaim);
		emit Claim(msg.sender, asset, toClaim);
	}
}