//SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {DecentralizedProfiles} from "./abstract/DecentralizedProfiles.sol";
import {SessionBooking} from "./abstract/SessionBooking.sol";
import {Course} from "./Course.sol";

contract TutorPal is DecentralizedProfiles, SessionBooking {
    error TutorPal__InvalidCourseId(uint256 courseId);
    error TutorPal__PaymentFailed();

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
    ) external ValidInstructor returns (Course newCourse) {
        uint256 currentId = createCourseCount;
        require(_maxSupply > 0, "Max supply must be greater than 0");
        require(_price > 0, "Price must be greater than 0");
        require(_royalty <= 2500, "");
        require(_royalty > 0, "Royalties must be greater than 0");
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_symbol).length > 0, "Symbol cannot be empty");
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty");

        newCourse = new Course(address(this), _title, _symbol, msg.sender, _metadataURI, _maxSupply, _price, _royalty);

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

    function buyCourse(uint256 _courseId) external payable {
        require(_courseId < createCourseCount, TutorPal__InvalidCourseId(_courseId));
        CourseStruct memory courseStruct = courseStructs[_courseId];
        Course course = Course(payable(address(courseStruct.course)));
        require(msg.value >= courseStruct.price, "Insufficient payment");
        require(courseStruct.maxSupply < courseStruct.maxSupply, "Course sold out");

        uint256 tokenId = course.mintCourseNFT(msg.sender);
        courseStructs[_courseId].maxSupply++;
        (bool success,) = payable(courseStruct.instructor).call{value: courseStruct.price}("");
        require(success, TutorPal__PaymentFailed());

        emit NFTPurchased(address(course), tokenId, msg.sender, courseStruct.price);
    }

    function getInstructorCourses(address _instructor) external view returns (address[] memory) {
        return instructors[_instructor].courses;
    }

    function getInstructorCourseIds(address _instructor) external view returns (uint256[] memory) {
        return instructors[_instructor].courseIds;
    }

    function getAllCourses() external view returns (address[] memory) {
        return allCourses; // Return all courses for students to view
    }

    function getCoursebyId(uint256 _courseId) external view returns (CourseStruct memory) {
        require(_courseId < createCourseCount, TutorPal__InvalidCourseId(_courseId));
        return courseStructs[_courseId];
    }

    function makeSessionOffer(address instructor, uint256 amount, uint256 duration)
        external
        payable
        override
        ValidStudent
        returns (uint256)
    {
        require(users[instructor].roleType == RoleType.Instructor);
        require(msg.value == amount, SessionBooking__IncorrectAmount());
        require(duration >= 10 minutes, SessionBooking__LessThanTenMintues());

        offerCounter++;
        uint256 offerId = offerCounter;

        offers[offerId] = SessionOffer({
            offerId: offerId,
            student: msg.sender,
            instructor: instructor,
            amount: amount,
            duration: duration,
            isAccepted: false,
            isCompleted: false,
            isCanceled: false,
            timestamp: block.timestamp
        });

        emit SessionOffered(offerId, msg.sender, instructor, amount, duration);
        return offerId;
    }

    // instructor accepts a session offer
    function acceptSessionOffer(uint256 offerId) external override ValidInstructor {
        SessionOffer storage offer = offers[offerId];
        require(offer.instructor == msg.sender, SessionBooking__NotExceptedInstructor());
        require(!offer.isCanceled, SessionBooking__OfferCanceled());
        require(!offer.isAccepted, SessionBooking__OfferAccepted());

        offer.isAccepted = true;
        emit SessionAccepted(offerId, msg.sender, offer.amount);
    }

    // Student confirms session completion, releasing payment to the instructor
    function confirmSessionCompletion(uint256 offerId) external override ValidStudent {
        SessionOffer storage offer = offers[offerId];
        address student = offer.student;
        address instructor = offer.instructor;
        uint256 amount = offer.amount;
        require(student == msg.sender, SessionBooking__NotExceptedStudent());
        require(offer.isAccepted, SessionBooking__NotOfferAccepted());
        require(!offer.isCompleted, SessionBooking__SessionAlreadyCompleted());

        offer.isCompleted = true;
        (bool success,) = payable(instructor).call{value: amount}("");
        require(success, TutorPal__PaymentFailed());

        emit PaymentReleased(offerId, instructor, amount);
    }

    // Cancel an offer and refund the payment
    function cancelSessionOffer(uint256 offerId) external override ValidStudent {
        SessionOffer storage offer = offers[offerId];
        address student = offer.student;
        uint256 amount = offer.amount;
        require(student == msg.sender, SessionBooking__NotExceptedStudent());
        require(!offer.isAccepted, SessionBooking__OfferAccepted());

        offer.isCanceled = true;

        (bool success,) = payable(student).call{value: amount}("");
        require(success, TutorPal__PaymentFailed());

        emit PaymentRefunded(offerId, student, amount);
    }
}
