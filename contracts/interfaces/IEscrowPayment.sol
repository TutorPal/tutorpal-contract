// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEscrowPayment {
    struct SessionOffer {
        uint256 offerId;
        address student;
        address tutor;
        uint256 amount; // Amount offered for the session
        uint256 duration; // Duration of the session in minutes
        bool isAccepted; //  if the offer was accepted
        bool isCanceled; //  if the offer was canceled
        uint256 timestamp; // Timestamp when the offer was created
        bool completed;
    }

    // Events for session offers, acceptance, payment release, and refund
    event SessionOffered(
        uint256 indexed offerId, address indexed student, address indexed tutor, uint256 amount, uint256 duration
    );
    event SessionAccepted(uint256 indexed offerId, address indexed tutor, uint256 amount);
    event PaymentReleased(uint256 indexed offerId, address indexed tutor, uint256 amount);
    event PaymentRefunded(uint256 indexed offerId, address indexed student, uint256 amount);

    // Function for a student to make an offer for a tutoring session
    function makeSessionOffer(address tutor, uint256 amount, uint256 duration)
        external
        payable
        returns (uint256 offerId);

    // Function for the tutor to accept an offer, confirming the session booking
    function acceptSessionOffer(uint256 offerId) external;

    // Function to confirm completion of a session and release payment to the tutor
    function confirmSessionCompletion(uint256 offerId) external;

    // Function to cancel an offer and refund the payment to the student
    function cancelSessionOffer(uint256 offerId) external;

    // Function to get details of a session offer
    function getSessionOffer(uint256 offerId) external view returns (SessionOffer memory);
}
