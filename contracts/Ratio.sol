// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Ratio is ERC20, Ownable {

	constructor() ERC20("Ratio", "RAT") public {
		uint totalSupply = 100000000 * (10 ** 18);
		_mint(msg.sender, totalSupply);
	}

	function mint(address account, uint amount) public onlyOwner {
		_mint(account, amount);
	}
	
	function burn(address account, uint amount) public onlyOwner {
		_burn(account, amount);
	}
}