// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {DecentralizedProfiles} from "./abstract/DecentralizedProfiles.sol";
import {SessionBooking} from "./abstract/SessionBooking.sol";
import {RatingAndReview} from "./abstract/RatingAndReview.sol";
import {Course} from "./Course.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TutorPal is DecentralizedProfiles {
    error TutorPal__InvalidCourseId(uint256 courseId);
    error TutorPal__PaymentFailed();
    error TutorPal__InvalidSalePrice();
    error TutorPal__NFTNotOwned();
    error TutorPal__ListingNotFound();
    error TutorPal__NoRewards();
    error TutorPal__RoyaltyPaymentFailed();
    error TutorPal__SalePaymentFailed();

    struct Sale {
        address instructor;
        uint256 price;
    }

    struct InstructorcreatedCourses {
        address[] courses;
        uint256[] courseIds;
    }

    struct CourseStruct {
        string title;
        string symbol;
        string metadataURI;
        address instructor;
        uint16 royalties;
        uint256 maxSupply;
        uint256 price;
        uint256 totalMinted;
        uint256 timestamp;
        Course course;
        uint8 rating;
    }

    uint256 public createCourseCount;
    mapping(address instructors => InstructorcreatedCourses) internal instructors;
    mapping(uint256 id => CourseStruct course) public courseStructs;
    mapping(address course => mapping(uint256 tokenId => Sale)) public listings;
    mapping(address student => uint256 engagementPoints) public studentEngagement;
    mapping(address student => uint256 rewards) public studentRewards;

    address[] public allCourses;

    // Events
    event NFTListed(address indexed course, uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTPurchased(
        address indexed course,
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price,
        uint256 royalty
    );
    event RewardClaimed(address indexed student, uint256 amount);

    // Secondary Market Functions
    function listCourse(address _course, uint256 _tokenId, uint256 _price) external {
        ValidInstructor(msg.sender);
        IERC721 nft = IERC721(_course);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not the owner");
        require(_price > 0, TutorPal__InvalidSalePrice());

        listings[_course][_tokenId] = Sale(msg.sender, _price);
        emit NFTListed(_course, _tokenId, msg.sender, _price);
    }

    function buyListedCourse(address _course, uint256 _tokenId) external payable {

        ValidStudent(msg.sender);
        Sale memory sale = listings[_course][_tokenId];
        require(sale.instructor != address(0), TutorPal__ListingNotFound());
        require(msg.value >= sale.price, "Insufficient payment");

        CourseStruct memory courseStruct = courseStructs[uint256(uint160(_course))];
        uint256 royalty = (sale.price * courseStruct.royalties) / 10000;
        uint256 sellerAmount = sale.price - royalty;

        // Transfer royalty to the instructor
        (bool royaltySent,) = payable(courseStruct.instructor).call{value: royalty}("");
        require(royaltySent, TutorPal__RoyaltyPaymentFailed());

        // Transfer sale amount to the seller
        (bool sellerPaid,) = payable(sale.instructor).call{value: sellerAmount}("");
        require(sellerPaid, TutorPal__SalePaymentFailed());

        // Transfer NFT to buyer
        IERC721(_course).transferFrom(sale.instructor, msg.sender, _tokenId);
        delete listings[_course][_tokenId];

        emit NFTPurchased(_course, _tokenId, msg.sender, sale.price, royalty);

        // Reward student engagement
        rewardEngagement(msg.sender, 10);
    }

    // Loyalty Rewards
    function rewardEngagement(address _student, uint256 points) internal {
        ValidStudent(msg.sender);
        studentEngagement[_student] += points;
        studentRewards[_student] += points * 1e15; // Convert points to reward tokens (example: 0.001 ETH per point)
    }

    function claimRewards() external {
        ValidStudent(msg.sender);
        uint256 reward = studentRewards[msg.sender];
        require(reward > 0, TutorPal__NoRewards());
        studentRewards[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: reward}("");
        require(success, TutorPal__PaymentFailed());

        emit RewardClaimed(msg.sender, reward);
    }
}
