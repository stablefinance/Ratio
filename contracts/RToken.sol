pragma solidity 0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract RToken is ERC20, Ownable {

	constructor(string memory name, string memory symbol) ERC20(name, symbol) public {
	}

	function mint(address account, uint amount) public onlyOwner {
		_mint(account, amount);
	}
	
	function burn(address account, uint amount) public onlyOwner {
		_burn(account, amount);
	}
}