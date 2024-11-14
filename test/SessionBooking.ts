import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";


describe("SessionBooking", function () {
    async function deploySessionBookingFixture() {
        const [owner, instructor1, student1] = await ethers.getSigners();

        // First deploy TutorPal as it's needed for SessionBooking
        const TutorPal = await ethers.getContractFactory("TutorPal");
        const tutorPal = await TutorPal.deploy();

        // Register users
        await tutorPal.connect(instructor1).registerUser("John Doe", 2); // Instructor
        await tutorPal.connect(student1).registerUser("Bob Student", 1); // Student

        const SessionBooking = await ethers.getContractFactory("SessionBooking");
        const sessionBooking = await SessionBooking.deploy(tutorPal.target);

        return {
            sessionBooking,
            tutorPal,
            owner,
            instructor1,
            student1
        };
    }

    describe("Session Offers", function () {
        it("Should allow student to make session offer", async function () {
            const { sessionBooking, instructor1, student1 } = await loadFixture(deploySessionBookingFixture);

            const amount = ethers.parseEther("0.1");
            const duration = 3600; // 1 hour in seconds

            await expect(sessionBooking.connect(student1).makeSessionOffer(
                instructor1.address,
                amount,
                duration,
                { value: amount }
            )).to.emit(sessionBooking, "SessionOffered")
                .withArgs(1, student1.address, instructor1.address, amount, duration);
        });

        it("Should fail if payment doesn't match offer amount", async function () {
            const { sessionBooking, instructor1, student1 } = await loadFixture(deploySessionBookingFixture);

            const amount = ethers.parseEther("0.1");
            const duration = 3600;

            await expect(sessionBooking.connect(student1).makeSessionOffer(
                instructor1.address,
                amount,
                duration,
                { value: amount / 2n }
            )).to.be.revertedWithCustomError(sessionBooking, "SessionBooking__IncorrectAmount");
        });
    });

    describe("Session Management", function () {
        async function createSessionOfferFixture() {
            const base = await deploySessionBookingFixture();

            const amount = ethers.parseEther("0.1");
            const duration = 3600;

            await base.sessionBooking.connect(base.student1).makeSessionOffer(
                base.instructor1.address,
                amount,
                duration,
                { value: amount }
            );

            return { ...base, amount, duration };
        }

        it("Should allow instructor to accept session", async function () {
            const { sessionBooking, instructor1 } = await loadFixture(createSessionOfferFixture);

            await expect(sessionBooking.connect(instructor1).acceptSessionOffer(1))
                .to.emit(sessionBooking, "SessionAccepted");

            const offer = await sessionBooking.getSessionOffer(1);
            expect(offer.isAccepted).to.be.true;
        });

        it("Should allow student to confirm completion and release payment", async function () {
            const { sessionBooking, instructor1, student1, amount } = await loadFixture(createSessionOfferFixture);

            await sessionBooking.connect(instructor1).acceptSessionOffer(1);

            const instructorBalanceBefore = await ethers.provider.getBalance(instructor1.address);

            await expect(sessionBooking.connect(student1).confirmSessionCompletion(1))
                .to.emit(sessionBooking, "PaymentReleased");

            const instructorBalanceAfter = await ethers.provider.getBalance(instructor1.address);
            expect(instructorBalanceAfter - instructorBalanceBefore).to.equal(amount);
        });

        it("Should allow student to cancel unaccepted offer", async function () {
            const { sessionBooking, student1, amount } = await loadFixture(createSessionOfferFixture);

            const balanceBefore = await ethers.provider.getBalance(student1.address);

            await expect(sessionBooking.connect(student1).cancelSessionOffer(1))
                .to.emit(sessionBooking, "PaymentRefunded");

            const balanceAfter = await ethers.provider.getBalance(student1.address);
            expect(balanceAfter > balanceBefore).to.be.true; // Account for gas costs
        });
    });
});