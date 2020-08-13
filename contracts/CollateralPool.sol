pragma solidity 0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./RUSD.sol";
import "./Ratio.sol";


contract CollateralPool is Ownable  {
	using SafeMath for uint;

	mapping(address => uint) assets;
	RUSD rUSD;
	Ratio ratio;

	constructor() public {
	}

	function setRUSD(address RUSDAddress) public onlyOwner {
		rUSD = RUSD(RUSDAddress);
	}

	function setRatio(address RatioAddress) public onlyOwner {
		ratio = Ratio(RatioAddress);
	}

	function collaterize(address asset, uint amount) public onlyOwner {
		assets[asset] = assets[asset].add(amount);
		rUSD.mint(amount);
	}

	function withdraw(address asset, uint amount) public onlyOwner {
		assets[asset] = assets[asset].sub(amount);
		rUSD.burn(amount);
	}
}