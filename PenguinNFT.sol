// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PenguinNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string base_uri;

    constructor() ERC721("PenguinNFT", "PENFT") {
        base_uri = "https://ipfs.infura.io/ipfs/QmU7S7urCReuuzfhcrFT9uko2ntUTQziQMbLZUbQULYjqq/";
    }

    function getBaseuri() public view returns(string memory){
        return base_uri;
    }

    function setBaseUri(string memory _newUri) external returns(string memory){
        base_uri = _newUri;
        return base_uri;
    }

    function tranferNFT(address _from, address _to, uint256 _tokenId) external payable {
        transferFrom(_from, _to, _tokenId);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return super.tokenURI(_tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        super._setTokenURI(tokenId, _tokenURI);
    }
    
    function itod(uint256 x) private pure returns (string memory) {
        if (x > 0) {
            string memory str;
            while (x > 0) {
                str = string(abi.encodePacked(uint8(x % 10 + 48), str));
                x /= 10;
            }
            return str;
        }
        return "0";
    }

    function mint(address recipient)  external  returns (uint256) {     
        require(recipient != address(0), "Invalid recipient address." );           
                 
        _tokenIds.increment();

        uint256 nftId = _tokenIds.current(); 
        _mint(recipient, nftId);
        string memory fullUri = string.concat(base_uri, itod(nftId));
        setTokenURI(nftId, fullUri);

        return nftId;
    }

    function batchMint(address recipient, uint256 _count)  external  returns (uint256[] memory) {        
        require(recipient != address(0), "Invalid recipient address." );           
        require(_count > 0, "Invalid count value." );       
        uint256 i; 
        uint256[] memory nftIds = new uint256[](_count);
        string memory fullUri;
        for(i = 0; i < _count; i++)
        {
            _tokenIds.increment();

            uint256 nftId = _tokenIds.current(); 
            _mint(recipient, nftId);
            fullUri = string.concat(base_uri, itod(nftId));
            setTokenURI(nftId, fullUri);
            nftIds[i] = nftId;
        }
        return nftIds;
    }
}