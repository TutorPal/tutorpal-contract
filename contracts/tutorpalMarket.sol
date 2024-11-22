/// @title TutorPal - A decentralized tutoring marketplace
/// @notice This contract enables instructors to create and sell course NFTs, and students to book tutoring sessions
/// @dev Inherits from DecentralizedProfiles for user management and SessionBooking for tutoring session functionality
/// @author Iam0TI
//SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {DecentralizedProfiles} from "./abstract/DecentralizedProfiles.sol";
import {SessionBooking} from "./abstract/SessionBooking.sol";
import {RatingAndReview} from "./abstract/RatingAndReview.sol";
import {Course} from "./Course.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TutorPal is DecentralizedProfiles {
    error TutorPal__InvalidCourseId(uint256 courseId);
    error TutorPal__PaymentFailed();
    error CourseReview_NotOwned();
    error TutorPal__InvalidMaxSupply();
    error TutorPal__InvalidPrice();
    error TutorPal__InvalidRoyalty();
    error TutorPal__EmptyTitle();
    error TutorPal__EmptySymbol();
    error TutorPal__EmptyMetadataURI();
    error TutorPal__InsufficientPayment();
    error TutorPal__CourseSoldOut();
    error TutorPal__InvalidRating();
    error TutorPal__InvalidInstructor();

    event CourseListed(
        address indexed courseAddress,
        uint256 indexed courseId,
        address indexed instructor,
        string title,
        uint256 maxSupply,
        uint256 price,
        uint256 royalties,
        uint256 timestamp
    );
    event NFTPurchased(address indexed courseAddress, uint256 indexed tokenId, address indexed buyer, uint256 price);

    struct InstructorcreatedCourses {
        address[] courses;
        uint256[] courseIds;
    }

    struct CourseStruct {
        string title; // Title of the course
        string symbol;
        string metadataURI; // URI for the course metadata
        address instructor; // Address of the instructor who created the course
        uint16 royalties; // Royalties percentage for secondary sales (e.g., 500 for 5%)
        uint256 maxSupply; // Maximum number of NFTs available for this course
        uint256 price; // Price per NFT in wei
        uint256 totalMinted; // Total number of NFTs minted for this course
        uint256 timestamp;
        Course course;
        uint8 rating;
    }

    uint256 public createCourseCount;
    // instructors =>  InstructorcreatedCourses
    mapping(address instructors => InstructorcreatedCourses) internal instructors;
    mapping(uint256 id => CourseStruct course) public courseStructs;
    address[] public allCourses; // Array to keep track of all course addresses

    function validateCourseReview(uint256 courseId, address user) external view {
        require(IERC721(courseStructs[courseId].course).balanceOf(user) > 0, CourseReview_NotOwned());
    }

    /// @notice Creates a new course NFT collection
    /// @param _title The title of the course
    /// @param _symbol The symbol for the course NFT
    /// @param _metadataURI The URI pointing to the course metadata
    /// @param _maxSupply Maximum number of NFTs that can be minted for this course
    /// @param _price Price per NFT in wei
    /// @param _royalty Royalty percentage for secondary sales (in basis points, e.g., 500 for 5%)
    /// @return newCourse The address of the newly created Course contract
    function createCourse(
        string memory _title,
        string memory _symbol,
        string memory _metadataURI,
        uint256 _maxSupply,
        uint256 _price,
        uint16 _royalty
    ) external returns (Course newCourse, uint256 currentId) {
        ValidInstructor(msg.sender);

        currentId = createCourseCount;
        require(_maxSupply > 0, TutorPal__InvalidMaxSupply());
        require(_price > 0, TutorPal__InvalidPrice());
        require(_royalty <= 2500, TutorPal__InvalidRoyalty());
        require(_royalty > 0, TutorPal__InvalidRoyalty());
        require(bytes(_title).length > 0, TutorPal__EmptyTitle());
        require(bytes(_symbol).length > 0, TutorPal__EmptySymbol());
        require(bytes(_metadataURI).length > 0, TutorPal__EmptyMetadataURI());

        newCourse = new Course(address(this), _title, _symbol, msg.sender, _metadataURI, _maxSupply, _price, _royalty);

        courseStructs[currentId] = CourseStruct(
            _title, _symbol, _metadataURI, msg.sender, _royalty, _maxSupply, _price, 0, block.timestamp, newCourse, 0
        );
        instructors[msg.sender].courses.push(address(newCourse));
        instructors[msg.sender].courseIds.push(currentId);
        allCourses.push(address(newCourse)); // Add course to the list of all courses
        createCourseCount = createCourseCount + 1;

        emit CourseListed(
            address(newCourse), currentId, msg.sender, _title, _maxSupply, _price, _royalty, block.timestamp
        );
    }

    /// @notice Allows a student to purchase a course NFT
    /// @param _courseId The ID of the course to purchase
    function buyCourse(uint256 _courseId) external payable {
        ValidStudent(msg.sender);
        require(_courseId < createCourseCount, TutorPal__InvalidCourseId(_courseId));
        CourseStruct memory courseStruct = courseStructs[_courseId];
        Course course = Course(payable(address(courseStruct.course)));
        require(msg.value >= courseStruct.price, TutorPal__InsufficientPayment());
        require(courseStruct.totalMinted < courseStruct.maxSupply, TutorPal__CourseSoldOut());
        courseStructs[_courseId].maxSupply++;
        uint256 tokenId = course.mintCourseNFT(msg.sender);

        (bool success,) = payable(courseStruct.instructor).call{value: courseStruct.price}("");
        require(success, TutorPal__PaymentFailed());

        emit NFTPurchased(address(course), tokenId, msg.sender, courseStruct.price);
    }

    /// @notice Retrieves all courses created by a specific instructor
    /// @param _instructor The address of the instructor
    /// @return An array of course addresses created by the instructor
    function getInstructorCourses(address _instructor) external view returns (address[] memory) {
        return instructors[_instructor].courses;
    }

    /// @notice Retrieves all course IDs created by a specific instructor
    /// @param _instructor The address of the instructor
    /// @return An array of course IDs created by the instructor
    function getInstructorCourseIds(address _instructor) external view returns (uint256[] memory) {
        return instructors[_instructor].courseIds;
    }

    /// @notice Retrieves all courses available on the platform
    /// @return An array of all course addresses
    function getAllCourses() external view returns (address[] memory) {
        return allCourses;
    }

    /// @notice Retrieves detailed information about a specific course
    /// @param _courseId The ID of the course
    /// @return The CourseStruct containing all course details
    function getCoursebyId(uint256 _courseId) external view returns (CourseStruct memory) {
        require(_courseId < createCourseCount, TutorPal__InvalidCourseId(_courseId));
        return courseStructs[_courseId];
    }
}
