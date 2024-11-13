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

contract TutorPal is DecentralizedProfiles, SessionBooking, RatingAndReview {
    error TutorPal__InvalidCourseId(uint256 courseId);
    error TutorPal__PaymentFailed();
    error CourseReview_NotOwned();

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

    modifier validateCourseReview(uint256 courseId) {
        require(IERC721(courseStructs[courseId].course).balanceOf(msg.sender) > 0, CourseReview_NotOwned());

        _;
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
            _title, _symbol, _metadataURI, msg.sender, _royalty, _maxSupply, _price, 0, block.timestamp, newCourse, 0
        );
        instructors[msg.sender].courses.push(address(newCourse));
        instructors[msg.sender].courseIds.push(currentId);
        allCourses.push(address(newCourse)); // Add course to the list of all courses
        ++createCourseCount;

        emit CourseListed(
            address(newCourse), currentId, msg.sender, _title, _maxSupply, _price, _royalty, block.timestamp
        );
    }

    /// @notice Allows a student to purchase a course NFT
    /// @param _courseId The ID of the course to purchase
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

    /// @notice Allows a student to make a session offer to an instructor
    /// @param instructor The address of the instructor
    /// @param amount The amount of ETH offered for the session
    /// @param duration The proposed duration of the session in seconds
    /// @return The ID of the created offer
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

    /// @notice Allows an instructor to accept a session offer
    /// @param offerId The ID of the offer to accept
    function acceptSessionOffer(uint256 offerId) external override ValidInstructor {
        SessionOffer storage offer = offers[offerId];
        require(offer.instructor == msg.sender, SessionBooking__NotExceptedInstructor());
        require(!offer.isCanceled, SessionBooking__OfferCanceled());
        require(!offer.isAccepted, SessionBooking__OfferAccepted());

        offer.isAccepted = true;
        emit SessionAccepted(offerId, msg.sender, offer.amount);
    }

    /// @notice Allows a student to confirm session completion and release payment
    /// @param offerId The ID of the completed session offer
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

    /// @notice Allows a student to cancel their session offer and receive a refund
    /// @param offerId The ID of the offer to cancel
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

    // TODO  add more check for the Reviews and  do somestate update
    // Submit a course review
    function submitCourseReview(uint256 courseId, uint8 rating, string calldata reviewText)
        external
        override
        ValidStudent
        validateCourseReview(courseId)
    {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");

        courseReviews[courseId] = CourseReview({
            courseId: courseId,
            student: msg.sender,
            rating: rating,
            reviewText: reviewText,
            timestamp: block.timestamp
        });

        _updateCourseRating(courseId, rating);

        emit CourseReviewSubmitted(courseId, msg.sender, rating, reviewText);
    }

    // Submit a course review
    function submitSessionReview(uint256 sessionId, address tutor, uint8 rating, string calldata reviewText)
        external
        override
        ValidStudent
        validateSessionReview(sessionId, tutor)
    {
        require(rating >= 1 && rating <= 5, SessionReview__InvalidRating(rating));

        sessionReviews[sessionId] = SessionReview({
            sessionId: sessionId,
            student: msg.sender,
            rating: rating,
            reviewText: reviewText,
            timestamp: block.timestamp
        });

        _updateInstructorRating(tutor, rating);

        emit SessionReviewSubmitted(sessionId, msg.sender, rating, reviewText);
    }

    //   function getSessionReviews(
    //     uint256 sessionId
    //   ) external view override returns (SessionReview[] memory) {}

    //   function getCourseReviews(
    //     uint256 courseId
    //   ) external view override returns (CourseReview[] memory) {}

    function submitSessionReview(uint256 sessionId, address instructor, uint256 rating, string calldata reviewText)
        external
        override
    {}

    function submitCourseReview(uint256 courseId, uint256 rating, string calldata reviewText) external override {}

    function getInstructorRating(address instructor) external view override returns (uint8) {}
}
