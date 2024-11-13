//SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {DecentralizedProfiles} from "./abstract/DecentralizedProfiles.sol";
import {Course} from "./Course.sol";

contract TutorPal is DecentralizedProfiles {
    error TutorPal__InvalidCourseId(uint256 courseId);

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
        Course course;
        uint256 timestamp;
    }

    uint256 public createCourseCount;
    // instructors =>  InstructorcreatedCourses
    mapping(address instructors => InstructorcreatedCourses) internal instructors;
    mapping(uint256 id => CourseStruct course) public courseStructs;
    address[] public allCourses; // Array to keep track of all course addresses

    function createCourse(
        string memory _title,
        string memory _symbol,
        string memory _metadataURI,
        uint256 _maxSupply,
        uint256 _price,
        uint8 _royalty
    ) public ValidInstructor returns (Course newCourse) {
        uint256 currentId = createCourseCount;
        require(_maxSupply > 0, "Max supply must be greater than 0");
        require(_price > 0, "Price must be greater than 0");
        require(_royalty <= 2500, "");
        require(_royalty > 0, "Royalties must be greater than 0");
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_symbol).length > 0, "Symbol cannot be empty");
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty");

        newCourse = new Course(_title, _symbol, msg.sender, _metadataURI, _maxSupply, _price, _royalty);

        courseStructs[currentId] = CourseStruct(
            _title, _symbol, _metadataURI, msg.sender, _royalty, _maxSupply, _price, 0, newCourse, block.timestamp
        );
        instructors[msg.sender].courses.push(address(newCourse));
        instructors[msg.sender].courseIds.push(currentId);
        allCourses.push(address(newCourse)); // Add course to the list of all courses
        ++createCourseCount;

        emit CourseListed(
            address(newCourse), currentId, msg.sender, _title, _maxSupply, _price, _royalty, block.timestamp
        );
    }

    function buyCourse(uint256 _courseId) public payable {
        require(_courseId < createCourseCount, TutorPal__InvalidCourseId(_courseId));
        CourseStruct memory courseStruct = courseStructs[_courseId];
        Course course = Course(payable(address(courseStruct.course)));
        require(msg.value >= courseStruct.price, "Insufficient payment");
        require(courseStruct.maxSupply < courseStruct.maxSupply, "Course sold out");

        uint256 tokenId = course.mintCourseNFT{value: msg.value}();
        courseStructs[_courseId].maxSupply++;

        emit NFTPurchased(address(course), tokenId, msg.sender, courseStruct.price);
    }

    function getInstructorCourses(address _instructor) public view returns (address[] memory) {
        return instructors[_instructor].courses;
    }

    function getInstructorCourseIds(address _instructor) public view returns (uint256[] memory) {
        return instructors[_instructor].courseIds;
    }

    function getAllCourses() public view returns (address[] memory) {
        return allCourses; // Return all courses for students to view
    }

    function getCoursebyId(uint256 _courseId) public view returns (CourseStruct memory) {
        require(_courseId < createCourseCount, TutorPal__InvalidCourseId(_courseId));
        return courseStructs[_courseId];
    }
}
// contract instructorpalMarket is DecentralizedProfiles {
//     mapping(address => Course) public courses;

// event CourseListed(
//         address indexed courseAddress,
//         string title,
//         address indexed instructor,
//         uint256 maxSupply,
//         uint256 price,
//         uint256 royalties
//     );
//     event NFTPurchased(address indexed courseAddress, uint256 indexed tokenId, address indexed buyer, uint256 price);
//    struct Course {
//         string title; // Title of the course
//         address instructor; // Address of the instructor who created the course
//         uint256 maxSupply; // Maximum number of NFTs available for this course
//         uint256 price; // Price per NFT
//         uint256 royalties; // Royalties percentage for secondary sales (e.g., 5 for 5%)
//     }

//     function createCourseCollection(string calldata title, uint256 price, uint256 royalties, uint256 maxSupply)
//         external
//         returns (address courseAddress){}

// // Purchase an NFT from a course collection
//     function purchaseNFT(address courseAddress) external payable{}

//     function getCourseDetails(address courseAddress)
//         external
//         view
//         returns (string memory title, address instructor, uint256 price, uint256 royalties, uint256 maxSupply){}

// }
