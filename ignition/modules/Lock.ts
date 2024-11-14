// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const TutorPalMarketModule = buildModule("TutorPalMarketModule", (m) => {

  // Deploy main TutorPalMarket contract with all dependencies

  const tutorPal = m.contract("TutorPal", []);


  // Deploy SessionBooking contract with rating and review dependencies
  const sessionBooking = m.contract("SessionBooking", [tutorPal]);

  // Deploy Rating contract
  const ratingAndReview = m.contract("RatingAndReview", [tutorPal, sessionBooking]);

  return {
    tutorPal,
    ratingAndReview,
    sessionBooking

  };
});

export default TutorPalMarketModule;
