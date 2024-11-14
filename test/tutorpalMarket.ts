import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { TutorPal, Course } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("TutorPal", function () {
    // Fixture that deploys TutorPal and sets up initial state
    async function deployTutorPalFixture() {
        const [owner, instructor1, instructor2, student1, student2] = await ethers.getSigners();

        const TutorPal = await ethers.getContractFactory("TutorPal");
        const tutorPal = await TutorPal.deploy();

        return { tutorPal, owner, instructor1, instructor2, student1, student2 };
    }

    describe("User Registration", function () {
        it("Should allow users to register as instructor", async function () {
            const { tutorPal, instructor1 } = await loadFixture(deployTutorPalFixture);

            await tutorPal.connect(instructor1).registerUser("John Doe", 2);
            const userProfile = await tutorPal.getUserProfile(instructor1.address);
            expect(userProfile.displayName).to.equal("John Doe");
            expect(userProfile.roleType).to.equal(2);
            expect(userProfile.isRegistered).to.be.true;
        });

        it("Should allow users to register as student", async function () {
            const { tutorPal, student1 } = await loadFixture(deployTutorPalFixture);

            await tutorPal.connect(student1).registerUser("Jane Smith", 1);
            const userProfile = await tutorPal.getUserProfile(student1.address);
            expect(userProfile.displayName).to.equal("Jane Smith");
            expect(userProfile.roleType).to.equal(1);
            expect(userProfile.isRegistered).to.be.true;
        });

        it("Should prevent duplicate registration", async function () {
            const { tutorPal, student1 } = await loadFixture(deployTutorPalFixture);

            await tutorPal.connect(student1).registerUser("Jane Smith", 1);
            await expect(tutorPal.connect(student1).registerUser("Jane Smith", 1))
                .to.be.revertedWithCustomError(tutorPal, "NotANewUser");
        });
    });

    describe("Course Creation", function () {


        it("Should allow instructor to create a course", async function () {
            const { tutorPal, instructor1 } = await loadFixture(deployTutorPalFixture);
            await tutorPal.connect(instructor1).registerUser("John Doe", 2);
            const courseData = {
                title: "Blockchain 101",
                symbol: "BLC",
                metadataURI: "ipfs://QmExample",
                maxSupply: 100n,
                price: ethers.parseEther("0.1"),
                royalty: 500n // 5%
            };

            await expect(tutorPal.connect(instructor1).createCourse(
                courseData.title,
                courseData.symbol,
                courseData.metadataURI,
                courseData.maxSupply,
                courseData.price,
                courseData.royalty
            )).to.emit(tutorPal, "CourseListed");

            const courseId = 0; // First course created
            const courseStruct = await tutorPal.getCoursebyId(courseId);

            expect(courseStruct.title).to.equal(courseData.title);
            expect(courseStruct.maxSupply).to.equal(courseData.maxSupply);
            expect(courseStruct.price).to.equal(courseData.price);
            expect(courseStruct.royalties).to.equal(courseData.royalty);
        });

        it("Should prevent non-instructors from creating courses", async function () {
            const { tutorPal, student1 } = await loadFixture(deployTutorPalFixture);
            await tutorPal.connect(student1).registerUser("Student", 0);

            await expect(tutorPal.connect(student1).createCourse(
                "Test Course",
                "TST",
                "ipfs://test",
                100n,
                ethers.parseEther("0.1"),
                500n
            )).to.be.reverted;
        });
    });

    describe("Course Purchase", function () {


        it("Should allow student to purchase a course", async function () {
            let courseId: number;
            let coursePrice: bigint;


            const { tutorPal, instructor1, student1 } = await loadFixture(deployTutorPalFixture);

            // Register users
            await tutorPal.connect(instructor1).registerUser("Instructor", 2);
            await tutorPal.connect(student1).registerUser("Student", 1);

            // Create course
            coursePrice = ethers.parseEther("0.1");
            await tutorPal.connect(instructor1).createCourse(
                "Test Course",
                "TST",
                "ipfs://test",
                100n,
                coursePrice,
                500n
            );

            courseId = 0;

            // const { tutorPal, student1, instructor1 } = await loadFixture(deployTutorPalFixture);

            const initialInstructorBalance = await ethers.provider.getBalance(instructor1.address);

            await expect(tutorPal.connect(student1).buyCourse(courseId, { value: coursePrice }))
                .to.emit(tutorPal, "NFTPurchased");

            // Check instructor received payment
            const finalInstructorBalance = await ethers.provider.getBalance(instructor1.address);
            expect(finalInstructorBalance - initialInstructorBalance).to.equal(coursePrice);
        });

        it("Should prevent purchase with insufficient payment", async function () {
            //const { tutorPal, student1 } = await loadFixture(deployTutorPalFixture);
            let courseId: number;
            let coursePrice: bigint;


            const { tutorPal, instructor1, student1 } = await loadFixture(deployTutorPalFixture);

            // Register users
            await tutorPal.connect(instructor1).registerUser("Instructor", 2);
            await tutorPal.connect(student1).registerUser("Student", 1);

            // Create course
            coursePrice = ethers.parseEther("0.1");
            await tutorPal.connect(instructor1).createCourse(
                "Test Course",
                "TST",
                "ipfs://test",
                100n,
                coursePrice,
                500n
            );

            courseId = 0;

            await expect(tutorPal.connect(student1).buyCourse(courseId, {
                value: coursePrice / 2n
            })).to.be.revertedWithCustomError(tutorPal, "TutorPal__InsufficientPayment");
        });
    });

});