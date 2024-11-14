import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";


describe("RatingAndReview", function () {
    async function deployRatingAndReviewFixture() {
        const [owner, student, instructor, pesron] = await ethers.getSigners();

        const TutorParmarketFactory = await ethers.getContractFactory("TutorPal");
        const tutorParmarket = await TutorParmarketFactory.deploy();
        // Register users
        await tutorParmarket.connect(instructor).registerUser("John Doe", 2); // Instructor
        await tutorParmarket.connect(student).registerUser("Bob Student", 1); // Student

        const SessionBookingFactory = await ethers.getContractFactory("SessionBooking");
        const sessionBooking = await SessionBookingFactory.deploy(tutorParmarket.target);

        const RatingAndReviewFactory = await ethers.getContractFactory("RatingAndReview");
        const ratingAndReview = await RatingAndReviewFactory.deploy(
            tutorParmarket.target,
            sessionBooking.target
        );

        return { owner, student, instructor, tutorParmarket, sessionBooking, ratingAndReview, pesron };
    }

    describe("submitSessionReview", function () {
        it("should allow a student to submit a session review", async function () {
            const { student, instructor, sessionBooking, ratingAndReview } = await loadFixture(
                deployRatingAndReviewFixture
            );
            const sessionId = 1;
            const amount = ethers.parseEther("1");
            const duration = 3600; // 1 hour
            await sessionBooking.connect(student).makeSessionOffer(instructor.address, amount, duration, { value: amount });
            await sessionBooking.connect(instructor).acceptSessionOffer(sessionId);
            await sessionBooking.connect(student).confirmSessionCompletion(sessionId);


            const rating = 4;
            const reviewText = "Great session!";


            await ratingAndReview
                .connect(student)
                .submitSessionReview(sessionId, instructor.address, rating, reviewText);

            const sessionReview = await ratingAndReview.sessionReviews(sessionId);
            expect(sessionReview.student).to.equal(student.address);
            expect(sessionReview.rating).to.equal(rating);
            expect(sessionReview.reviewText).to.equal(reviewText);
        });

        it("should revert if the rating is invalid", async function () {
            const { student, instructor, sessionBooking, ratingAndReview } = await loadFixture(
                deployRatingAndReviewFixture
            );

            const sessionId = 1;
            const amount = ethers.parseEther("1");
            const duration = 3600; // 1 hour
            await sessionBooking.connect(student).makeSessionOffer(instructor.address, amount, duration, { value: amount });
            await sessionBooking.connect(instructor).acceptSessionOffer(sessionId);
            await sessionBooking.connect(student).confirmSessionCompletion(sessionId);



            const invalidRating = 6n;
            const reviewText = "Great session!";


            await expect(
                ratingAndReview
                    .connect(student)
                    .submitSessionReview(sessionId, instructor.address, invalidRating, reviewText)
            ).to.be.reverted;
        });

        it("should revert if the user is not a student", async function () {
            const { pesron, student, instructor, sessionBooking, ratingAndReview, tutorParmarket } = await loadFixture(
                deployRatingAndReviewFixture
            );
            const sessionId = 1;
            const amount = ethers.parseEther("1");
            const duration = 3600; // 1 hour
            await sessionBooking.connect(student).makeSessionOffer(instructor.address, amount, duration, { value: amount });
            await sessionBooking.connect(instructor).acceptSessionOffer(sessionId);
            await sessionBooking.connect(student).confirmSessionCompletion(sessionId);


            const rating = 4;
            const reviewText = "Great session!";


            await expect(
                ratingAndReview.connect(pesron).submitSessionReview(sessionId, instructor.address, rating, reviewText)
            ).to.be.revertedWithCustomError(tutorParmarket, "NotStudent()");
        });
    });

    describe("submitCourseReview", function () {
        it("should allow a student to submit a course review", async function () {
            const { student, tutorParmarket, ratingAndReview, instructor } = await loadFixture(
                deployRatingAndReviewFixture
            );
            const courseTitle = "Test Course";
            const courseSymbol = "TC";
            const courseMetadataURI = "ipfs://test-metadata";
            const courseMaxSupply = 100;
            const coursePrice = ethers.parseEther("1");
            const courseRoyalty = 500;

            await tutorParmarket.connect(instructor).createCourse(
                courseTitle,
                courseSymbol,
                courseMetadataURI,
                courseMaxSupply,
                coursePrice,
                courseRoyalty
            );

            // Purchase the course
            const courseId = 0;
            await tutorParmarket.connect(student).buyCourse(courseId, { value: coursePrice });


            const rating = 5;
            const reviewText = "Excellent course!";


            await ratingAndReview.connect(student).submitCourseReview(courseId, rating, reviewText);

            const courseReview = await ratingAndReview.courseReviews(courseId);
            expect(courseReview.student).to.equal(student.address);
            expect(courseReview.rating).to.equal(rating);
            expect(courseReview.reviewText).to.equal(reviewText);
        });

        it("should revert if the rating is invalid", async function () {
            const { instructor, student, tutorParmarket, ratingAndReview } = await loadFixture(
                deployRatingAndReviewFixture
            );

            const courseTitle = "Test Course";
            const courseSymbol = "TC";
            const courseMetadataURI = "ipfs://test-metadata";
            const courseMaxSupply = 100;
            const coursePrice = ethers.parseEther("1");
            const courseRoyalty = 500;

            await tutorParmarket.connect(instructor).createCourse(
                courseTitle,
                courseSymbol,
                courseMetadataURI,
                courseMaxSupply,
                coursePrice,
                courseRoyalty
            );

            // Purchase the course
            const courseId = 0;
            await tutorParmarket.connect(student).buyCourse(courseId, { value: coursePrice });


            const invalidRating = 6n;
            const reviewText = "Excellent course!";


            await expect(
                ratingAndReview.connect(student).submitCourseReview(courseId, invalidRating, reviewText)
            ).to.be.reverted;
        });

        it("should revert if the user is not a student", async function () {
            const { pesron, tutorParmarket, ratingAndReview, student, instructor } = await loadFixture(
                deployRatingAndReviewFixture
            );


            const courseTitle = "Test Course";
            const courseSymbol = "TC";
            const courseMetadataURI = "ipfs://test-metadata";
            const courseMaxSupply = 100;
            const coursePrice = ethers.parseEther("1");
            const courseRoyalty = 500;

            await tutorParmarket.connect(instructor).createCourse(
                courseTitle,
                courseSymbol,
                courseMetadataURI,
                courseMaxSupply,
                coursePrice,
                courseRoyalty
            );

            // Purchase the course
            const courseId = 0;
            await tutorParmarket.connect(student).buyCourse(courseId, { value: coursePrice });

            const rating = 5;
            const reviewText = "Excellent course!";


            await expect(
                ratingAndReview.connect(pesron).submitCourseReview(courseId, rating, reviewText)
            ).to.be.revertedWithCustomError(tutorParmarket, "NotStudent()");
        });
    });

});