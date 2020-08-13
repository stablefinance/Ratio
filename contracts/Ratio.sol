pragma solidity 0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RUSD.sol";


contract Ratio is ERC20, Ownable {

	constructor() ERC20("Ratio", "RAT") public {
	}

	function mint(uint amount) public onlyOwner {
		_mint(msg.sender, amount);
	}
	
	function burn(uint amount) public onlyOwner {
		_burn(msg.sender, amount);
	}
}