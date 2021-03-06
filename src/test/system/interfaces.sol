// Copyright (C) 2020 Centrifuge

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.15 <0.6.0;

contract Hevm {
    function warp(uint256) public;
}

contract TitleLike {
    function issue(address) public returns (uint);
    function close(uint) public;
    function ownerOf (uint) public returns (address);
}

contract TokenLike{
    function totalSupply() public returns (uint);
    function balanceOf(address) public returns (uint);
    function transferFrom(address,address,uint) public;
    function approve(address, uint) public;
    function mint(address, uint) public;
    function burn(address, uint) public;
}

contract NFTFeedLike {
    function update(bytes32 nftID, uint value) public;
    function update(bytes32 nftID, uint value, uint risk) public;
    function ceiling(uint loan) public view returns(uint);
    function values(uint) public view returns(uint);
    function ceilingRatio(uint) public view returns(uint);
    function thresholdRatio(uint) public view returns(uint);
    function threshold(uint) public view returns (uint);
    // function file(bytes32 what, uint loan, uint currencyAmount) public;
    function borrow(uint loan, uint currencyAmount) public;
    function repay(uint loan, uint currencyAmount) public;
    function file(bytes32 what, bytes32 nftID_, uint maturityDate_) public;
}

contract PileLike {
    function debt(uint loan) public returns(uint);
    function file(bytes32 what, uint rate, uint speed) public;
    function setRate(uint loan, uint rate) public;
}

contract TDistributorLike {
    function balance() public;
    function file(bytes32 what, bool flag) public;
}

contract ShelfLike {
    function lock(uint loan) public;
    function unlock(uint loan) public;
    function issue(address registry, uint token) public returns (uint loan);
    function close(uint loan) public;
    function borrow(uint loan, uint wad) public;
    function withdraw(uint loan, uint wad, address usr) public;
    function repay(uint loan, uint wad) public;
    function shelf(uint loan) public returns(address registry,uint256 tokenId,uint price,uint principal, uint initial);
    function file(bytes32 what, uint loan, address registry, uint nft) public;
}

contract ERC20Like {
    function transferFrom(address, address, uint) public;
    function mint(address, uint) public;
    function approve(address usr, uint wad) public returns (bool);
    function totalSupply() public returns (uint256);
    function balanceOf(address usr) public returns (uint);
}

contract TrancheLike {
    function balance() public returns(uint);
    function tokenSupply() public returns(uint);
}

contract CollectorLike {
    function collect(uint loan) public;
    function collect(uint loan, address buyer) public;
    function file(bytes32 what, uint loan, address buyer, uint price) public;
    function relyCollector(address user) public;
}

contract ThresholdLike {
    function set(uint, uint) public;
}

contract MemberlistLike {
    function updateMember(address usr, uint validUntil) public;
    function removeMember(address usr, uint validUntil) public;
}
