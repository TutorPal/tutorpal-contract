// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Course is ERC721URIStorage {
    using Strings for uint256;

    address public instructor;
    string public metadataURI;
    uint256 public maxSupply;
    uint256 public price;
    uint256 public royalty;
    uint256 public totalMinted;
    address public TutorPal;

    mapping(address => bool) public students; // Tracks students who have purchased the course

    constructor(
        address _TutorPal,
        string memory _name,
        string memory _symbol,
        address _instructor,
        string memory _metadataURI,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _royalty
    ) ERC721(_name, _symbol) {
        TutorPal = _TutorPal;
        instructor = _instructor;
        metadataURI = _metadataURI;
        maxSupply = _maxSupply;
        price = _price;
        royalty = _royalty;
    }

    function mintCourseNFT(address _user) public returns (uint256) {
        require(msg.sender == TutorPal, "Only TutorPal contract can mint");
        require(totalMinted < maxSupply, "Max supply reached");

        require(!students[_user], "Already enrolled in this course"); // Ensure student can't enroll twice

        students[_user] = true; // Record the student's enrollment
        totalMinted++;
        _safeMint(_user, totalMinted);
        _setTokenURI(totalMinted, string(abi.encodePacked(metadataURI, totalMinted.toString())));
        return totalMinted;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(metadataURI, tokenId.toString()));
    }

    function isStudentEnrolled(address _student) public view returns (bool) {
        return students[_student]; // Check if a student is enrolled in this course
    }
}
