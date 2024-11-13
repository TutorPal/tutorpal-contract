// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRatingAndReview} from "../interfaces/IRatingReview.sol";

abstract contract RatingAndReview is IRatingAndReview {
    mapping(uint256 sessionId => SessionReview) public sessionReviews;
    mapping(uint256 courseId => CourseReview) public courseReviews;
    mapping(address instructor => InstructorRating) public instructorRatings;
    mapping(uint256 courseId => CourseRating) public courseRatings;

    // Submit a session review
    /**
     * Submits a review for a instructoring session.
     *
     * @param sessionId The ID of the instructoring session being reviewed.
     * @param instructor The address of the instructor for the session.
     * @param rating The rating for the session, between 1 and 5.
     * @param reviewText The text of the review.
     */
    function submitSessionReview(uint256 sessionId, address instructor, uint8 rating, string calldata reviewText)
        external
        virtual;

    // Submit a course review
    function submitCourseReview(uint256 courseId, uint8 rating, string calldata reviewText) external virtual;

    /**
     * @notice Updates the instructor's rating when a new review is submitted
     * @dev Rating is scaled by a factor of 10 for better precision in calculations
     * @param _instructor The address of the instructor being rated
     * @param _rating The rating value (1-5) which will be multiplied by 10
     */
    function _updateInstructorRating(address _instructor, uint8 _rating) internal returns (uint8 ratings) {
        InstructorRating storage instructorRating = instructorRatings[_instructor];
        instructorRating.totalRating = instructorRating.totalRating + (_rating * 10);
        instructorRating.totalReviewer = instructorRating.totalReviewer + 1;
        instructorRating.rating = uint8(instructorRating.totalRating / instructorRating.totalReviewer);
        return instructorRating.rating;
    }

    /**
     * @notice Updates the course's rating when a new review is submitted
     * @dev Rating is scaled by a factor of 10 for better precision in calculations
     * @param _courseId The ID of the course being rated
     * @param _rating The rating value (1-5) which will be multiplied by 10
     */
    function _updateCourseRating(uint256 _courseId, uint8 _rating) internal {
        CourseRating storage courseRating = courseRatings[_courseId];
        courseRating.totalRating = courseRating.totalRating + (_rating * 10);
        courseRating.totalReviewer = courseRating.totalReviewer + 1;
        courseRating.rating = uint8(courseRating.totalRating / courseRating.totalReviewer);
    }

    /**
     * @notice Retrieves the average rating for a instructor
     * @dev The returned rating is scaled by a factor of 10
     * @param instructor The address of the instructor
     * @return uint8 The instructor's average rating (multiplied by 10)
     */
    function getinstructorRating(address instructor) external view returns (uint8) {
        return instructorRatings[instructor].rating;
    }

    /**
     * @notice Retrieves the average rating for a course
     * @dev The returned rating is scaled by a factor of 10
     * @param courseId The ID of the course
     * @return uint8 The course's average rating (multiplied by 10)
     */
    function getCourseRating(uint256 courseId) external view returns (uint8) {
        return courseRatings[courseId].rating;
    }
}
