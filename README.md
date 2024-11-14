
# TutorPal - A Decentralized Tutoring Marketplace

TutorPal is a decentralized platform that enables instructors to create and sell course NFTs, and students to book tutoring sessions and provide reviews.

## Key Features

1. **Course Creation**: Instructors can create and list new courses as NFTs, specifying the title, symbol, metadata URI, maximum supply, price, and royalties.
2. **Course Purchase**: Students can purchase course NFTs using the `buyCourse` function.
3. **Session Booking**: Students can book tutoring sessions with instructors using the `makeSessionOffer` function. Instructors can accept these offers, and students can confirm completion of the session.
4. **Rating and Review**: Students can submit reviews for both courses and tutoring sessions, rating them on a scale of 1-5. The platform tracks and displays the average ratings for courses and instructors.

## Contracts

The TutorPal platform consists of the following contracts:

1. **DecentralizedProfiles**: Handles user registration and role management (student, instructor).
2. **SessionBooking**: Manages the booking and completion of tutoring sessions.
3. **RatingAndReview**: Allows students to submit reviews and ratings for courses and sessions.
4. **TutorPal**: The main contract that integrates the other contracts and provides the high-level platform functionality.
5. **Course**: The contract representing a course NFT, with minting and metadata functionality.


## Conclusion

TutorPal is a decentralized platform that aims to provide a secure and transparent marketplace for online tutoring services. By leveraging blockchain technology and NFTs, the platform offers instructors and students a new way to engage in educational services and build trusted relationships.