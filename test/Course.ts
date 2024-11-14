import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { Course, TutorPal } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("Course NFT", function () {
    async function deployContractsFixture() {
        const [owner, instructor1, student1, student2] = await ethers.getSigners();

        // Deploy TutorPal first since Course needs it
        const TutorPal = await ethers.getContractFactory("TutorPal");
        const tutorPal = await TutorPal.deploy();

        // Register instructor and student
        await tutorPal.connect(instructor1).registerUser("John Doe", 2); // Instructor
        await tutorPal.connect(student1).registerUser("Bob Student", 1); // Student
        await tutorPal.connect(student2).registerUser("Alice Student", 1); // Student

        // Create a course through TutorPal
        await tutorPal.connect(instructor1).createCourse(
            "Blockchain Basics",
            "BLC101",
            "ipfs://QmTest",
            100,
            ethers.parseEther("0.1"),
            500 // 5% royalty
        );

        const courseAddress = (await tutorPal.getCoursebyId(0)).course;
        const course = await ethers.getContractAt("Course", courseAddress);

        return {
            tutorPal,
            course,
            owner,
            instructor1,
            student1,
            student2,
            coursePrice: ethers.parseEther("0.1")
        };
    }

    describe("Course NFT Deployment", function () {
        it("Should initialize course with correct parameters", async function () {
            const { course, instructor1 } = await loadFixture(deployContractsFixture);

            expect(await course.name()).to.equal("Blockchain Basics");
            expect(await course.symbol()).to.equal("BLC101");
            expect(await course.instructor()).to.equal(instructor1.address);
            expect(await course.maxSupply()).to.equal(100);
            expect(await course.price()).to.equal(ethers.parseEther("0.1"));
            expect(await course.royalty()).to.equal(500);
        });
    });

    describe("Course NFT Minting", function () {
        it("Should only allow minting through TutorPal contract", async function () {
            const { course, student1 } = await loadFixture(deployContractsFixture);

            // Direct minting should fail
            await expect(course.mintCourseNFT(student1.address))
                .to.be.revertedWith("Only TutorPal contract can mint");
        });

        it("Should track student enrollment correctly", async function () {
            const { tutorPal, course, student1, coursePrice } = await loadFixture(deployContractsFixture);

            // Purchase course through TutorPal
            await tutorPal.connect(student1).buyCourse(0, { value: coursePrice });

            expect(await course.isStudentEnrolled(student1.address)).to.be.true;
            expect(await course.balanceOf(student1.address)).to.equal(1);
        });

        it("Should prevent double enrollment", async function () {
            const { tutorPal, course, student1, coursePrice } = await loadFixture(deployContractsFixture);

            // First purchase
            await tutorPal.connect(student1).buyCourse(0, { value: coursePrice });

            // Second purchase should fail
            await expect(tutorPal.connect(student1).buyCourse(0, { value: coursePrice }))
                .to.be.revertedWith("Already enrolled in this course");
        });

        it("Should respect max supply limit", async function () {
            const { tutorPal, instructor1, student1, student2 } = await loadFixture(deployContractsFixture);

            // Create course with max supply of 1
            await tutorPal.connect(instructor1).createCourse(
                "Limited Course",
                "LMT",
                "ipfs://QmTest2",
                1, // maxSupply
                ethers.parseEther("0.1"),
                500
            );

            // First purchase should succeed
            await tutorPal.connect(student1).buyCourse(1, { value: ethers.parseEther("0.1") });

            // Second purchase should fail
            await expect(tutorPal.connect(student2).buyCourse(1, { value: ethers.parseEther("0.1") }))
                .to.be.revertedWith("Max supply reached");
        });
    });

    describe("Token URI", function () {
        it("Should return correct token URI", async function () {
            const { tutorPal, course, student1, coursePrice } = await loadFixture(deployContractsFixture);

            await tutorPal.connect(student1).buyCourse(0, { value: coursePrice });

            const tokenId = 1; // First minted token
            const expectedURI = "ipfs://QmTest1"; // Base URI + tokenId
            expect(await course.tokenURI(tokenId)).to.equal(expectedURI);
        });
    });

    describe("Course Access Control", function () {
        it("Should correctly track enrolled students", async function () {
            const { tutorPal, course, student1, student2, coursePrice } = await loadFixture(deployContractsFixture);

            // Student1 enrolls
            await tutorPal.connect(student1).buyCourse(0, { value: coursePrice });

            expect(await course.isStudentEnrolled(student1.address)).to.be.true;
            expect(await course.isStudentEnrolled(student2.address)).to.be.false;
        });
    });
});