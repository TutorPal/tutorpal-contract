// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ISessionBooking} from "../interfaces/ISessionBooking.sol";

abstract contract SessionBooking is ISessionBooking {
    mapping(uint256 => SessionOffer) public offers;
    uint256 public offerCounter;

    // Function for a student to make an offer for a tutoring session
    function makeSessionOffer(address instructor, uint256 amount, uint256 duration)
        external
        payable
        virtual
        returns (uint256);

    // instructor accepts a session offer
    function acceptSessionOffer(uint256 offerId) external virtual;

    // Student confirms session completion, releasing payment to the instructor
    function confirmSessionCompletion(uint256 offerId) external virtual;

    // Cancel an offer and refund the payment
    function cancelSessionOffer(uint256 offerId) external virtual; // Retrieve details of a session offer

    function getSessionOffer(uint256 offerId) external view returns (SessionOffer memory) {
        return offers[offerId];
    }
}
