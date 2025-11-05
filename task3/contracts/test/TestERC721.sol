// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TestERC721 is ERC721Enumerable, Ownable {
    string private _tokenURI;
    uint256 private _nextTokenId;

    constructor() ERC721("Troll", "Troll") Ownable(msg.sender) {}

    function mint(address to) external onlyOwner {
        _mint(to, _nextTokenId++);
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return _tokenURI;
    }

    function setTokenURI(string memory newTokenURI) external onlyOwner {
        _tokenURI = newTokenURI;
    }
}