// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./LinearVRGDA.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";

contract CantoNameService is ERC721("Canto Name Service", "CNS"), LinearVRGDA, Ownable, ReentrancyGuard {

    /*//////////////////////////////////////////////////////////////
                EVENTS
    //////////////////////////////////////////////////////////////*/

    // Announce contract withdrawals
    event Withdraw(address indexed recipient, uint256 indexed value);

    /*//////////////////////////////////////////////////////////////
                LIBRARY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // Converts string name to uint256 tokenId
    function nameToID(string memory _name) public pure returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(_name))));
    }

    // Return string length, properly counts all Unicode characters
    function stringLength(string memory _string) public pure returns (uint256) {
        uint256 charCount; // Number of characters in _string regardless of char byte length
        uint256 charByteCount = 0; // Number of bytes in char (a = 1, € = 3)
        uint256 byteLength = bytes(_string).length; // Total length of string in raw bytes

        // Determine how many bytes each character in string has
        for (charCount = 0; charByteCount < byteLength; charCount++) {
            bytes1 b = bytes(_string)[charByteCount]; // if tree uses first byte to determine length
            if (b < 0x80) {
                charByteCount += 1;
            } else if (b < 0xE0) {
                charByteCount += 2;
            } else if (b < 0xF0) {
                charByteCount += 3;
            } else if (b < 0xF8) {
                charByteCount += 4;
            } else if (b < 0xFC) {
                charByteCount += 5;
            } else {
                charByteCount += 6;
            }
        }
        return charCount;
    }

    // Returns proper VRGDA price for name based off string length
    // _length parameter directly calls corresponding VRGDA via getVRGDAPrice()
    function priceName(uint256 _length) public view returns (uint256) {
        uint256 price;
        if (_length == 1) {
            price = _getVRGDAPrice(_length, vrgdaCounts.one);
        } else if (_length == 2) {
            price = _getVRGDAPrice(_length, vrgdaCounts.two);
        } else if (_length == 3) {
            price = _getVRGDAPrice(_length, vrgdaCounts.three);
        } else if (_length == 4) {
            price = _getVRGDAPrice(_length, vrgdaCounts.four);
        } else if (_length == 5) {
            price = _getVRGDAPrice(_length, vrgdaCounts.five);
        } else {
            price = 1 ether;
        }
        return price;
    }

    // Increments the proper counters based on string length
    function _incrementCounts(uint256 _length) internal {
        if (_length == 1) {
            vrgdaCounts._one++;
            vrgdaCounts.one++;
        } else if (_length == 2) {
            vrgdaCounts._two++;
            vrgdaCounts.two++;
        } else if (_length == 3) {
            vrgdaCounts._three++;
            vrgdaCounts.three++;
        } else if (_length == 4) {
            vrgdaCounts._four++;
            vrgdaCounts.four++;
        } else if (_length == 5) {
            vrgdaCounts._five++;
            vrgdaCounts.five++;
        } else if (_length >= 6) {
            vrgdaCounts._extra++;
        } else {
            revert("ZERO_CHARACTERS");
        }
    }

    // Return total number of names sold
    function totalNamesSold() public view returns (uint256) {
        return (
            vrgdaCounts._one + vrgdaCounts._two + vrgdaCounts._three + 
                vrgdaCounts._four + vrgdaCounts._five + vrgdaCounts._extra
        );
    }

    /*//////////////////////////////////////////////////////////////
                PRIMARY NAME SERVICE LOGIC
    //////////////////////////////////////////////////////////////*/

    // Set primary name
    // Allow owner to call only if undelegated
    function setPrimary(uint256 tokenId) public {
        // Only owner or valid delegate can call
        require((msg.sender == ERC721.ownerOf(tokenId) &&
                nameRegistry[tokenId].delegationExpiry < block.timestamp) || 
            (msg.sender == nameRegistry[tokenId].delegate && 
                nameRegistry[tokenId].delegationExpiry > block.timestamp));

        // Set primary name data
        primaryName[msg.sender] = tokenId;
        currentPrimary[tokenId] = msg.sender;
    }

    // Return address' primary name
    function getPrimary(address _target) public view returns (string memory) {
        uint256 tokenId = primaryName[_target];
        return nameRegistry[tokenId].name;
    }

    // Return name owner address
    function getOwner(string memory _name) public view returns (address) {
        uint256 tokenId = nameToID(_name);
        return ownerOf(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                PAYMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // Payment handling functions if we need them
    // ***************** Currently allows withdrawal to anyone ***********************
    function withdraw() public {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success);
        emit Withdraw(msg.sender, address(this).balance);
    }

    receive() external payable {}
    fallback() external payable {}
}