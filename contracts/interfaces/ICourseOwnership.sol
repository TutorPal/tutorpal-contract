// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICourseNFTFactory {
    struct Course {
        string title; // Title of the course
        address tutor; // Address of the tutor who created the course
        uint256 maxSupply; // Maximum number of NFTs available for this course
        uint256 price; // Price per NFT
        uint256 royalties; // Royalties percentage for secondary sales (e.g., 5 for 5%)
    }

    // Events
    event CourseListed(
        address indexed courseAddress,
        string title,
        address indexed tutor,
        uint256 maxSupply,
        uint256 price,
        uint256 royalties
    );
    event NFTPurchased(address indexed courseAddress, uint256 indexed tokenId, address indexed buyer, uint256 price);
    //event NFTResold(address indexed courseAddress, uint256 indexed tokenId, address indexed seller, address buyer, uint256 resalePrice, uint256 royaltyPaid);

    // Deploy a new ERC-721 contract for a course
    function createCourseCollection(string calldata title, uint256 price, uint256 royalties, uint256 maxSupply)
        external
        returns (address courseAddress);

    // Purchase an NFT from a course collection
    function purchaseNFT(address courseAddress) external payable;

    // // Resell an NFT in the secondary market with royalties
    // function resellNFT(address courseAddress, uint256 tokenId, uint256 resalePrice) external;

    // Get details of a specific course by its contract address
    function getCourseDetails(address courseAddress)
        external
        view
        returns (string memory title, address tutor, uint256 price, uint256 royalties, uint256 maxSupply);
}
