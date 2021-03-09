pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract ERC721Tradable is ERC721Full, Ownable {
    using Strings for string;

    address proxyRegistryAddress;
    uint256 private _currentTokenId = 0;
    mapping(uint256 => string) public _idToUrl;
    mapping(string => uint256) public _urlToId;


    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) public ERC721Full(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _imageUrl imageUrl of the image for this token if it doesn't already exist
     * @param _to address of the future owner of the token
     */
    function mintTo(string memory _imageUrl, address _to) public {
        require(_urlToId[_imageUrl] == 0, "imageUrl exists");
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
        // map the id to it's URL so we can look it up later.
        // this is done so we can periodically check if any URLs have been minted but are missing
        // their corresponding metadata.
        _idToUrl[newTokenId] = _imageUrl;
        // mark this URL as minted so we can check against it's uniqueness above.
        _urlToId[_imageUrl] = newTokenId;
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function baseTokenURI() public pure returns (string memory) {
        return "";
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return Strings.strConcat(baseTokenURI(), Strings.uint2str(_tokenId));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}
