// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDecentralizedProfiles {
    enum RoleType {
        NotRegistered,
        Student,
        Instructor
    }

    struct User {
        string displayName;
        RoleType roleType;
        bool isRegistered;
        uint256 registerationTime;
    }

    error NotANewUser(address user);
    error NotAdmin();
    error NotInstuctor();
    error NotStudent();

    /// @notice Emitted when a new user is registered
    /// @param user The address of the registered user
    /// @param displayName The display name of the registered user
    /// @param roleType The role type of the registered user
    event UserRegistered(address indexed user, string displayName, RoleType roleType);

    /// @notice Emitted when a new admin is added
    /// @param newAdminAddress The address of the new admin that was added
    /// @param admin The address of the admin that added the new admin
    event NewAdmin(address indexed newAdminAddress, address indexed admin);

    /// @notice Emitted when an admin is removed
    /// @param removedAdmin The address of the admin that was removed
    /// @param admin The address of the admin that removed the admin
    event RemovedAdmin(address indexed removedAdmin, address indexed admin);

    // Function to register a new user
    function registerUser(string calldata _displayName, RoleType _roleType) external;

    // Function to get user profile
    function getUserProfile(address _user)
        external
        view
        returns (string memory displayName, RoleType roleType, bool isRegistered);

    function addAdmin(address) external;
    function removeAdmin(address) external;
}
