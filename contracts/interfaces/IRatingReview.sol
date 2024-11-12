// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRatingAndReview {
    struct SessionReview {
        uint256 sessionId;
        address student;
        uint256 rating; // Rating from 1 to 5
        string reviewText; // Written review for session
        uint256 timestamp; // Time when review was left
    }

    struct CourseReview {
        uint256 courseId;
        address student;
        uint256 rating; // Rating from 1 to 5
        string reviewText; // Written review for course
        uint256 timestamp; // Time when review was left
    }

    // Events for session and course reviews
    event SessionReviewSubmitted(uint256 indexed sessionId, address indexed student, uint256 rating, string reviewText);
    event CourseReviewSubmitted(uint256 indexed courseId, address indexed student, uint256 rating, string reviewText);

    // Submit a review for a specific session
    function submitSessionReview(uint256 sessionId, address tutor, uint256 rating, string calldata reviewText)
        external;

    // Submit a review for a specific course
    function submitCourseReview(uint256 courseId, uint256 rating, string calldata reviewText) external;

    // Retrieve all reviews for a specific session
    function getSessionReviews(uint256 sessionId) external view returns (SessionReview[] memory);

    // Retrieve all reviews for a specific course
    function getCourseReviews(uint256 courseId) external view returns (CourseReview[] memory);

    // Retrieve the average rating for a specific tutor based on session reviews
    function getTutorRating(address tutor) external view returns (uint256);

    // Retrieve the average rating for a specific course
    function getCourseRating(uint256 courseId) external view returns (uint256);
}
