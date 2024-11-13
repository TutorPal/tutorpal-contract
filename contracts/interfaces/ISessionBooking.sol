// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISessionBooking {
    struct SessionOffer {
        uint256 offerId;
        address student;
        bool isAccepted; //  if the offer was accepted
        bool isCompleted; //  if the offer was completed
        address instructor;
        bool isCanceled; //  if the offer was canceled
        uint256 amount; // in wei
        uint256 duration; // Duration of the session in seconds
        uint256 timestamp; // Timestamp when the offer was created
            //uint256 deadline ; // Timestamp when the offer will expire    ???   you can just cancle it actually
    }

    error SessionBooking__IncorrectAmount();
    error SessionBooking__InvalidInstructorAdderess();
    error SessionBooking__LessThanTenMintues();
    error SessionBooking__NotExceptedInstructor();
    error SessionBooking__NotExceptedStudent();
    error SessionBooking__OfferCanceled();
    error SessionBooking__OfferAccepted();
    error SessionBooking__NotOfferAccepted();
    error SessionBooking__SessionAlreadyCompleted();
    error SessionReview__InvalidReviewer();
    error SessionReview__SessionNotCompleted();
    error SessionReview__InvalidInstructorAddress();

    // Events for session offers, acceptance, payment release, and refund

    event SessionOffered(
        uint256 indexed offerId, address indexed student, address indexed instructor, uint256 amount, uint256 duration
    );
    event SessionAccepted(uint256 indexed offerId, address indexed instructor, uint256 amount);
    event PaymentReleased(uint256 indexed offerId, address indexed instructor, uint256 amount);
    event PaymentRefunded(uint256 indexed offerId, address indexed student, uint256 amount);

    // Function for a student to make an offer for a instructoring session
    function makeSessionOffer(address instructor, uint256 amount, uint256 duration)
        external
        payable
        returns (uint256 offerId);

    // Function for the instructor to accept an offer, confirming the session booking
    function acceptSessionOffer(uint256 offerId) external;

    // Function to confirm completion of a session and release payment to the instructor
    function confirmSessionCompletion(uint256 offerId) external;

    // Function to cancel an offer and refund the payment to the student
    function cancelSessionOffer(uint256 offerId) external;

    // Function to get details of a session offer
    function getSessionOffer(uint256 offerId) external view returns (SessionOffer memory);
}
