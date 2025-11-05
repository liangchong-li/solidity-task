// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "./NFTAuction.sol";

// 合约工厂
// 工厂合约负责创建和管理拍卖合约实例。
contract NFTAutionFactory {
    address[] public _auctions;
    mapping (uint256 tokenId => NFTAuction) public _auctionMap;

    // uint256 duration, uint256 startingPrice, uint256 bidIncrement, 
    function createAuction(uint256 tokenId) external returns (address) {
        NFTAuction auction = new NFTAuction();
        auction.initialize();
        // auction.initialize(duration, startingPrice, bidIncrement, tokenId);
        _auctions.push(address(auction));
        _auctionMap[tokenId] = auction;
        return address(auction);
    }

    function getAuctions() public view returns (address[] memory) {
        return _auctions;
    }

    function getAuction(uint256 tokenId) public view returns (address) {
        return _auctions[tokenId];
    }
}