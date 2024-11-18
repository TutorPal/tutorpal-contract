// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDecentralizedProfiles.sol";

contract Escrow {
    IDecentralizedProfiles public decentralizedProfiles;

    enum EscrowStatus {
        NotStarted,
        InProgress,
        Completed,
        Cancelled
    }

    struct EscrowAgreement {
        address student;
        address tutor;
        uint256 amount;
        EscrowStatus status;
    }

    mapping(uint256 => EscrowAgreement) public agreements;
    uint256 public agreementCount;

    event EscrowCreated(uint256 indexed agreementId, address indexed student, address indexed tutor, uint256 amount);
    event EscrowCompleted(uint256 indexed agreementId, address indexed tutor);
    event EscrowCancelled(uint256 indexed agreementId, address indexed student);

    error OnlyStudent();
    error OnlyTutor();
    error InvalidRole();
    error InvalidStatus(EscrowStatus currentStatus);

    constructor(address _decentralizedProfiles) {
        decentralizedProfiles = IDecentralizedProfiles(_decentralizedProfiles);
    }

    modifier onlyStudent() {
        (, IDecentralizedProfiles.RoleType roleType, ) = decentralizedProfiles.getUserProfile(msg.sender);
        if (roleType != IDecentralizedProfiles.RoleType.Student) revert OnlyStudent();
        _;
    }

    modifier onlyTutor() {
        (, IDecentralizedProfiles.RoleType roleType, ) = decentralizedProfiles.getUserProfile(msg.sender);
        if (roleType != IDecentralizedProfiles.RoleType.Instructor) revert OnlyTutor();
        _;
    }

    /// @notice Create a new escrow agreement
    /// @param _tutor The address of the tutor
    function createEscrow(address _tutor) external payable onlyStudent {
        require(msg.value > 0, "Amount must be greater than zero");

        // Validate that the tutor is a registered instructor
        (, IDecentralizedProfiles.RoleType roleType, ) = decentralizedProfiles.getUserProfile(_tutor);
        if (roleType != IDecentralizedProfiles.RoleType.Instructor) revert InvalidRole();

        // Create the escrow agreement
        agreements[agreementCount] = EscrowAgreement({
            student: msg.sender,
            tutor: _tutor,
            amount: msg.value,
            status: EscrowStatus.InProgress
        });

        emit EscrowCreated(agreementCount, msg.sender, _tutor, msg.value);
        agreementCount++;
    }

    /// @notice Complete the escrow agreement and release funds to the tutor
    /// @param agreementId The ID of the escrow agreement
    function completeEscrow(uint256 agreementId) external onlyStudent {
        EscrowAgreement storage agreement = agreements[agreementId];

        if (agreement.status != EscrowStatus.InProgress) {
            revert InvalidStatus(agreement.status);
        }
        if (agreement.student != msg.sender) {
            revert OnlyStudent();
        }

        agreement.status = EscrowStatus.Completed;

        // Transfer funds to the tutor
        payable(agreement.tutor).transfer(agreement.amount);

        emit EscrowCompleted(agreementId, agreement.tutor);
    }

    /// @notice Cancel the escrow agreement and refund the student
    /// @param agreementId The ID of the escrow agreement
    function cancelEscrow(uint256 agreementId) external onlyStudent {
        EscrowAgreement storage agreement = agreements[agreementId];

        if (agreement.status != EscrowStatus.InProgress) {
            revert InvalidStatus(agreement.status);
        }
        if (agreement.student != msg.sender) {
            revert OnlyStudent();
        }

        agreement.status = EscrowStatus.Cancelled;

        // Refund the student
        payable(agreement.student).transfer(agreement.amount);

        emit EscrowCancelled(agreementId, agreement.student);
    }
}
