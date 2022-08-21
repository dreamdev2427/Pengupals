// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PalToken is ERC20 {

    constructor (address to, uint256 totalsupp) ERC20("Pal token", "PAL") 
    {
        _mint(to, totalsupp * (10 ** 18));
    }
}
