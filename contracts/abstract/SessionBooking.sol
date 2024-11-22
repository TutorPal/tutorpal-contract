// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ISessionBooking} from "../interfaces/ISessionBooking.sol";

interface ITutorParmarket {
    function ValidInstructor(address _user) external view;

    function ValidStudent(address _user) external view;
}

contract SessionBooking is ISessionBooking {
    mapping(uint256 => SessionOffer) public offers;

    mapping(uint256 => SessionListing) public listings;
    uint256 public listingCounter;
    uint256 public offerCounter;
    ITutorParmarket tutorParmarket;

    constructor(address _tutorParmarket) {
        tutorParmarket = ITutorParmarket(_tutorParmarket);
    }

    function validateSessionReview(address user, uint256 offerId, address instructor) external view {
        require(offers[offerId].student == user, SessionReview__InvalidReviewer());
        require(offers[offerId].isCompleted == true, SessionReview__SessionNotCompleted());
        require(offers[offerId].instructor == instructor, SessionReview__InvalidInstructorAddress());
    }
    /// @notice Allows an instructor to create a new session listing that students can view and make offers on.
    /// @param amount The amount of ETH that the instructor is requesting for the session.
    /// @param duration The proposed duration of the session in seconds.
    /// @param title A short title for the session listing.
    /// @param content Additional details about the session.
    /// @return The ID of the created session listing.
    /// @notice Allows an instructor to list session there can take

    function createSessionListing(uint256 amount, uint32 duration, string memory title, string memory content)
        external
        returns (uint256)
    {
        tutorParmarket.ValidInstructor(msg.sender);
        require(duration >= 10 minutes, SessionBooking__LessThanTenMintues());
        require(bytes(title).length > 0, SessionBooking__TitleCannotBeEmpty());
        require(bytes(content).length > 0, SessionBooking__ContentCannotBeEmpty());

        uint256 listingId = listingCounter;

        listings[listingId] = SessionListing({
            listingId: listingId,
            instructor: msg.sender,
            amount: amount,
            duration: duration,
            isActive: true,
            timestamp: block.timestamp,
            title: title,
            content: content
        });
        listingCounter++;

        emit SessionListed(listingId, msg.sender, amount, duration, title, content);
        return listingId;
    }

    /// @notice Allows a student to make a session offer to an instructor
    /// @param instructor The address of the instructor
    /// @param amount The amount of ETH offered for the session
    /// @param duration The proposed duration of the session in seconds
    /// @return The ID of the created offer
    function makeSessionOffer(address instructor, uint256 amount, uint256 duration)
        external
        payable
        returns (uint256)
    {
        tutorParmarket.ValidStudent(msg.sender);
        tutorParmarket.ValidInstructor(instructor);
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
    function acceptSessionOffer(uint256 offerId) external override {
        tutorParmarket.ValidInstructor(msg.sender);
        SessionOffer storage offer = offers[offerId];
        require(offer.instructor == msg.sender, SessionBooking__NotExceptedInstructor());
        require(!offer.isCanceled, SessionBooking__OfferCanceled());
        require(!offer.isAccepted, SessionBooking__OfferAccepted());

        offer.isAccepted = true;
        emit SessionAccepted(offerId, msg.sender, offer.amount);
    }

    /// @notice Allows a student to confirm session completion and release payment
    /// @param offerId The ID of the completed session offer
    function confirmSessionCompletion(uint256 offerId) external override {
        tutorParmarket.ValidStudent(msg.sender);
        SessionOffer storage offer = offers[offerId];
        address student = offer.student;
        address instructor = offer.instructor;
        uint256 amount = offer.amount;
        require(student == msg.sender, SessionBooking__NotExceptedStudent());
        require(offer.isAccepted, SessionBooking__NotOfferAccepted());
        require(!offer.isCompleted, SessionBooking__SessionAlreadyCompleted());

        offer.isCompleted = true;
        (bool success,) = payable(instructor).call{value: amount}("");
        require(success, SessionBooking__PaymentFailed());

        emit PaymentReleased(offerId, instructor, amount);
    }

    /// @notice Allows a student to cancel their session offer and receive a refund
    /// @param offerId The ID of the offer to cancel
    function cancelSessionOffer(uint256 offerId) external override {
        tutorParmarket.ValidStudent(msg.sender);
        SessionOffer storage offer = offers[offerId];
        address student = offer.student;
        uint256 amount = offer.amount;
        require(student == msg.sender, SessionBooking__NotExceptedStudent());
        require(!offer.isAccepted, SessionBooking__OfferAccepted());

        offer.isCanceled = true;

        (bool success,) = payable(student).call{value: amount}("");
        require(success, SessionBooking__PaymentFailed());

        emit PaymentRefunded(offerId, student, amount);
    }

    /// @notice Allows an instructor to reject a session offer
    /// @param offerId The ID of the offer to reject
    function rejectOffer(uint256 offerId) external {
        tutorParmarket.ValidInstructor(msg.sender);
        SessionOffer storage offer = offers[offerId];
        require(offer.instructor == msg.sender, SessionBooking__NotExceptedInstructor());
        require(!offer.isCanceled, SessionBooking__OfferCanceled());
        require(!offer.isAccepted, SessionBooking__OfferAccepted());
        offer.isCanceled = true;
        (bool success,) = payable(offer.student).call{value: offer.amount}("");
        require(success, SessionBooking__PaymentFailed());
        emit SessionRejected(offerId, msg.sender, offer.amount);
    }

    // redunctant code
    function getSessionOffer(uint256 offerId) external view returns (SessionOffer memory) {
        return offers[offerId];
    }
}
